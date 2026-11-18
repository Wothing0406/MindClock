package com.mindclock.app

import android.app.Activity
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * Cầu nối native cho việc chọn ảnh đại diện, file nhạc báo thức/nhạc nền cục bộ
 * và nghe thử ngắn trên thiết bị Android (`mindclock/media_picker`).
 *
 * Mọi tệp được sao chép vào vùng lưu trữ riêng tư (`filesDir/avatars` hoặc `filesDir/sounds`)
 * để báo thức sáng luôn phát được kể cả offline hoặc mất quyền URI tạm thời;
 * không bao giờ tự tải tệp cá nhân lên máy chủ.
 */
class MediaPickerBridgeHandler(private val activity: Activity) {
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingRequestCode: Int = 0
    private var previewPlayer: MediaPlayer? = null

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickAvatarImage" -> launchDocumentPicker(
                requestCode = REQUEST_CODE_PICK_AVATAR,
                mimeType = "image/*",
                result = result,
            )
            "pickAlarmAudio" -> launchDocumentPicker(
                requestCode = REQUEST_CODE_PICK_AUDIO,
                mimeType = "audio/*",
                result = result,
            )
            "previewAudio" -> {
                val args = call.arguments as? Map<*, *>
                val soundOption = args?.get("soundOption") as? String ?: "gentle_dawn"
                val customPath = args?.get("customSoundPath") as? String
                val loop = args?.get("loop") as? Boolean ?: false
                val playing = startPreviewAudio(soundOption, customPath, loop)
                result.success(hashMapOf("playing" to playing))
            }
            "stopAudioPreview" -> {
                stopPreviewAudio()
                result.success(hashMapOf("stopped" to true))
            }
            else -> result.notImplemented()
        }
    }

    @Suppress("DEPRECATION")
    private fun launchDocumentPicker(
        requestCode: Int,
        mimeType: String,
        result: MethodChannel.Result,
    ) {
        if (pendingPickResult != null) {
            result.error("PICK_IN_PROGRESS", "Đang mở hộp thoại chọn tệp.", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            pendingPickResult = result
            pendingRequestCode = requestCode
            activity.startActivityForResult(intent, requestCode)
        } catch (_: Exception) {
            pendingPickResult = null
            pendingRequestCode = 0
            result.success(
                hashMapOf(
                    "picked" to false,
                    "cancelled" to false,
                    "errorMessageVi" to "Không tìm thấy trình duyệt tệp hợp lệ trên thiết bị.",
                ),
            )
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_PICK_AVATAR && requestCode != REQUEST_CODE_PICK_AUDIO) {
            return false
        }
        val callback = pendingPickResult ?: return true
        val targetFolder = if (requestCode == REQUEST_CODE_PICK_AVATAR) "avatars" else "sounds"
        val defaultExt = if (requestCode == REQUEST_CODE_PICK_AVATAR) "jpg" else "mp3"
        pendingPickResult = null
        pendingRequestCode = 0

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            callback.success(
                hashMapOf(
                    "picked" to false,
                    "cancelled" to true,
                ),
            )
            return true
        }

        val uri = data.data!!
        val copied = copyUriToPrivateDir(uri, targetFolder, defaultExt)
        if (copied == null) {
            callback.success(
                hashMapOf(
                    "picked" to false,
                    "cancelled" to false,
                    "errorMessageVi" to "Không đọc được tệp đã chọn. Vui lòng thử tệp khác.",
                ),
            )
            return true
        }

        callback.success(
            hashMapOf(
                "picked" to true,
                "cancelled" to false,
                "localPath" to copied.first.absolutePath,
                "displayName" to copied.second,
            ),
        )
        return true
    }

    private fun copyUriToPrivateDir(
        uri: Uri,
        folderName: String,
        defaultExt: String,
    ): Pair<File, String>? {
        return try {
            val resolver = activity.contentResolver
            val displayName = resolveDisplayName(uri) ?: "mindclock_${System.currentTimeMillis()}.$defaultExt"
            val ext = displayName.substringAfterLast('.', defaultExt)
                .lowercase()
                .replace(Regex("[^a-z0-9]"), "")
                .ifEmpty { defaultExt }
            val dir = File(activity.filesDir, folderName).apply { mkdirs() }
            val prefix = if (folderName == "avatars") "avatar_" else "sound_"
            val destFile = File(dir, "$prefix${System.currentTimeMillis()}.$ext")
            resolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destFile).use { output ->
                    input.copyTo(output)
                }
            } ?: return null
            if (!destFile.exists() || destFile.length() == 0L) {
                destFile.delete()
                return null
            }
            destFile to displayName
        } catch (_: Exception) {
            null
        }
    }

    private fun resolveDisplayName(uri: Uri): String? {
        return try {
            activity.contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) cursor.getString(idx) else null
                } else {
                    null
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    fun startPreviewAudio(
        soundOption: String,
        customSoundPath: String?,
        loop: Boolean,
    ): Boolean {
        stopPreviewAudio()
        if (soundOption == AlarmRingService.SOUND_OPTION_VIBRATE_ONLY) {
            return false
        }
        val uri: Uri = when {
            soundOption == AlarmRingService.SOUND_OPTION_CUSTOM_LOCAL &&
                !customSoundPath.isNullOrBlank() &&
                File(customSoundPath).isFile -> Uri.fromFile(File(customSoundPath))
            soundOption == AlarmRingService.SOUND_OPTION_BERMUDA ->
                Uri.parse("android.resource://${activity.packageName}/${R.raw.alarm_bermuda}")
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                ?: return false
        }

        return try {
            val player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                setDataSource(activity.applicationContext, uri)
                isLooping = loop
                setOnCompletionListener {
                    if (!loop) {
                        stopPreviewAudio()
                    }
                }
                prepare()
                start()
            }
            previewPlayer = player
            true
        } catch (_: Exception) {
            stopPreviewAudio()
            false
        }
    }

    fun stopPreviewAudio() {
        val player = previewPlayer ?: return
        previewPlayer = null
        try {
            if (player.isPlaying) {
                player.stop()
            }
        } catch (_: Exception) {
        }
        try {
            player.release()
        } catch (_: Exception) {
        }
    }

    companion object {
        const val CHANNEL_NAME = "mindclock/media_picker"
        private const val REQUEST_CODE_PICK_AVATAR = 4501
        private const val REQUEST_CODE_PICK_AUDIO = 4502
    }
}
