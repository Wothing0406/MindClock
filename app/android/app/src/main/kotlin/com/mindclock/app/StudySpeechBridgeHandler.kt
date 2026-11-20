package com.mindclock.app

import android.app.Activity
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/** Opt-in offline Vietnamese TTS. Never captures audio or persists reply text. */
class StudySpeechBridgeHandler(
    private val activity: Activity,
    private val channel: MethodChannel,
) {
    private val main = Handler(Looper.getMainLooper())
    private val audio = activity.getSystemService(AudioManager::class.java)
    private var engine: TextToSpeech? = null
    private var ready = false
    private var foreground = false
    private var destroyed = false
    private var pending: MethodChannel.Result? = null
    private var pendingText: String? = null
    private var currentId: String? = null
    private var initTimeout: Runnable? = null
    private var focus: AudioFocusRequest? = null
    private var initGeneration = 0

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.argument<Number>("bridgeVersion")?.toInt() != 1) {
            result.error("VERSION", "Phiên bản giọng đọc không khớp.", null)
            return
        }
        when (call.method) {
            "stop" -> { stop(); result.success(null) }
            "speak" -> {
                val id = call.argument<String>("id")
                val text = call.argument<String>("text")?.trim()
                if (id.isNullOrBlank() || id.length > 80 || text.isNullOrBlank() ||
                    text.length > 2000 || destroyed || !foreground) {
                    result.error("UNAVAILABLE", "Không thể đọc câu trả lời lúc này.", null)
                    return
                }
                stop()
                currentId = id
                pending = result
                pendingText = text
                try {
                    if (ready) submit() else initialize()
                } catch (_: RuntimeException) {
                    fail("VOICE_UNAVAILABLE", "Giọng đọc chưa khả dụng trên thiết bị này.")
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun initialize() {
        if (engine != null) return // Existing init completes the latest pending request only.
        val generation = ++initGeneration
        initTimeout = Runnable {
            ++initGeneration
            fail("VOICE_TIMEOUT", "Giọng đọc chưa sẵn sàng. Bạn vẫn có thể đọc nội dung.")
            engine?.shutdown()
            engine = null
            ready = false
        }.also { main.postDelayed(it, 12000) }
        engine = TextToSpeech(activity.applicationContext) { status ->
            main.post {
                if (generation != initGeneration || destroyed) return@post
                initTimeout?.let(main::removeCallbacks)
                initTimeout = null
                if (destroyed) return@post
                val tts = engine ?: return@post
                if (status != TextToSpeech.SUCCESS) {
                    fail("VOICE_UNAVAILABLE", "Thiết bị chưa có bộ đọc tiếng Việt.")
                    tts.shutdown()
                    engine = null
                    return@post
                }
                val voice = tts.voices?.filter {
                    it.locale.language == "vi" && !it.isNetworkConnectionRequired &&
                        !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED)
                }?.sortedBy { it.name }?.firstOrNull()
                if (voice == null || tts.setLanguage(Locale.forLanguageTag("vi-VN")) < 0 ||
                    tts.setVoice(voice) != TextToSpeech.SUCCESS) {
                    fail("VI_VOICE_MISSING", "Cần cài giọng tiếng Việt ngoại tuyến trong Cài đặt chuyển văn bản thành giọng nói.")
                    tts.shutdown()
                    engine = null
                    return@post
                }
                tts.setAudioAttributes(AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
                tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(id: String?) = postState(id, "started")
                    override fun onDone(id: String?) = postState(id, "done")
                    @Deprecated("Legacy engine callback")
                    override fun onError(id: String?) = postState(id, "error")
                    override fun onError(id: String?, errorCode: Int) = postState(id, "error")
                    override fun onStop(id: String?, interrupted: Boolean) = postState(id, "stopped")
                })
                ready = true
                submit()
            }
        }
    }

    private fun submit() {
        val id = currentId ?: return
        val text = pendingText ?: return
        if (!foreground || destroyed) { stop(); return }
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
            .setOnAudioFocusChangeListener({ change ->
                if (change == AudioManager.AUDIOFOCUS_LOSS ||
                    change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT ||
                    change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) stop()
            }, main).build()
        focus = request
        if (audio.requestAudioFocus(request) != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            fail("AUDIO_FOCUS", "Thiết bị đang ưu tiên âm thanh khác.")
            return
        }
        if (engine?.speak(text, TextToSpeech.QUEUE_FLUSH, null, id) != TextToSpeech.SUCCESS) {
            fail("SPEAK_FAILED", "Không phát được giọng đọc.")
            return
        }
        pendingText = null
        pending?.success(null)
        pending = null
    }

    private fun postState(id: String?, state: String) {
        main.post {
            if (destroyed || id == null || currentId != id) return@post
            if (state == "started" && !foreground) { stop(); return@post }
            channel.invokeMethod("speechState", mapOf("id" to id, "state" to state))
            if (state != "started") {
                currentId = null
                releaseFocus()
            }
        }
    }

    private fun fail(code: String, message: String) {
        pending?.error(code, message, null)
        pending = null
        pendingText = null
        currentId?.let {
            channel.invokeMethod("speechState", mapOf("id" to it, "state" to "error", "messageVi" to message))
        }
        currentId = null
        releaseFocus()
    }

    fun stop() {
        val id = currentId
        currentId = null // Ignore late engine callbacks.
        pending?.error("CANCELLED", "Đã dừng giọng đọc.", null)
        pending = null
        pendingText = null
        engine?.stop()
        releaseFocus()
        if (id != null && !destroyed) {
            channel.invokeMethod("speechState", mapOf("id" to id, "state" to "stopped"))
        }
    }

    private fun releaseFocus() {
        focus?.let { audio.abandonAudioFocusRequest(it) }
        focus = null
    }

    fun setForeground(value: Boolean) {
        foreground = value
        if (!value) stop()
    }

    fun dispose() {
        stop()
        destroyed = true
        ++initGeneration
        initTimeout?.let(main::removeCallbacks)
        engine?.shutdown()
        engine = null
        ready = false
        channel.setMethodCallHandler(null)
    }
}
