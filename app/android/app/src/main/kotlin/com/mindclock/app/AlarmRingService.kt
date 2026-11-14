package com.mindclock.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * ForegroundService (`mediaPlayback`) phát âm thanh kênh báo thức và rung cục bộ.
 * Hỗ trợ `ACTION_EMERGENCY_STOP` để dừng ngay âm/rung và đóng notification
 * mà không cần FlutterEngine hay mạng.
 */
class AlarmRingService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var currentAlarmId: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_EMERGENCY_STOP -> {
                val alarmId = intent.getStringExtra(EXTRA_ALARM_ID) ?: currentAlarmId
                handleEmergencyStop(alarmId)
                return START_NOT_STICKY
            }
            ACTION_LOWER_VOLUME -> {
                mediaPlayer?.setVolume(0.25f, 0.25f)
                return START_NOT_STICKY
            }
            ACTION_START_RING -> {
                startAlarmRinging(intent)
                return START_NOT_STICKY
            }
            else -> {
                stopPlaybackAndForeground()
                stopSelf()
                return START_NOT_STICKY
            }
        }
    }

    override fun onDestroy() {
        stopPlaybackAndForeground()
        super.onDestroy()
    }

    private fun startAlarmRinging(intent: Intent) {
        val alarmId = intent.getStringExtra(EXTRA_ALARM_ID) ?: "primary_morning"
        val formattedTime = intent.getStringExtra(EXTRA_FORMATTED_TIME) ?: "06:00"
        val mode = intent.getStringExtra(EXTRA_MODE) ?: NativeAlarmRecord.MODE_NORMAL
        val label = intent.getStringExtra(EXTRA_LABEL) ?: "Báo thức buổi sáng"
        val subjectCode = intent.getStringExtra(EXTRA_SUBJECT_CODE)
        val soundEnabled = intent.getBooleanExtra(EXTRA_SOUND_ENABLED, true)
        val vibrateEnabled = intent.getBooleanExtra(EXTRA_VIBRATE_ENABLED, true)
        val soundOption = intent.getStringExtra(EXTRA_SOUND_OPTION) ?: "gentle_dawn"

        currentAlarmId = alarmId
        val payload = RingPayloadRecord(
            alarmId = alarmId,
            formattedTime = formattedTime,
            mode = mode,
            label = label,
            subjectCode = subjectCode,
            triggeredAtEpochMillis = System.currentTimeMillis(),
        )
        NativeAlarmStore(this).setActiveRingPayload(payload)

        ensureNotificationChannel(this)
        val notification = buildAlarmNotification(
            context = this,
            payload = payload,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        if (resolveSoundTarget(soundEnabled, soundOption) != AlarmSoundTarget.SILENT) {
            startAlarmSound(soundOption)
        }
        if (vibrateEnabled) {
            startAlarmVibration()
        }

        // Thử đưa màn hình chuông báo thức lên (trên Android khóa màn hình/bị hạn chế
        // background launch thì fullScreenIntent trong notification sẽ đảm nhiệm).
        val ringUiIntent = buildRingActivityIntent(this, payload)
        try {
            startActivity(ringUiIntent)
        } catch (_: Exception) {
            // Đã có fullScreenIntent trên foreground notification làm dự phòng.
        }
    }

    private fun handleEmergencyStop(alarmId: String?) {
        val store = NativeAlarmStore(this)
        store.setActiveRingPayload(null)
        store.setPendingRingLaunch(null)
        store.recordLocalAlarmEvent(
            alarmId = alarmId ?: "unknown",
            eventType = "emergency_stop",
            timestampMillis = System.currentTimeMillis(),
        )
        stopPlaybackAndForeground()
        sendBroadcast(Intent(ACTION_RING_STATE_CHANGED).setPackage(packageName))
        stopSelf()
    }

    private fun startAlarmSound(soundOption: String) {
        stopSoundOnly()
        val target = resolveSoundTarget(soundEnabled = true, soundOption = soundOption)
        val primaryUri = resolveSoundUri(target) ?: return
        val fallbackUri = resolveSoundUri(AlarmSoundTarget.SYSTEM_DEFAULT)

        if (!startMediaPlayerLoop(primaryUri) &&
            fallbackUri != null &&
            fallbackUri != primaryUri
        ) {
            startMediaPlayerLoop(fallbackUri)
        }
    }

    private fun resolveSoundUri(target: AlarmSoundTarget): Uri? {
        return when (target) {
            AlarmSoundTarget.SILENT -> null
            AlarmSoundTarget.BUNDLED_BERMUDA ->
                Uri.parse("android.resource://$packageName/${R.raw.alarm_bermuda}")
            AlarmSoundTarget.SYSTEM_DEFAULT ->
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        }
    }

    private fun startMediaPlayerLoop(alarmUri: Uri): Boolean {
        return try {
            val player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(this@AlarmRingService, alarmUri)
                isLooping = true
                prepare()
                start()
            }
            mediaPlayer = player
            true
        } catch (_: Exception) {
            stopSoundOnly()
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun startAlarmVibration() {
        stopVibrationOnly()
        val vib = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        } ?: return

        vibrator = vib
        val pattern = longArrayOf(0L, 650L, 450L)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vib.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            vib.vibrate(pattern, 0)
        }
    }

    private fun stopPlaybackAndForeground() {
        stopSoundOnly()
        stopVibrationOnly()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.cancel(NOTIFICATION_ID)
    }

    private fun stopSoundOnly() {
        try {
            mediaPlayer?.let { player ->
                if (player.isPlaying) {
                    player.stop()
                }
                player.release()
            }
        } catch (_: Exception) {
            // Bỏ qua lỗi giải phóng player
        } finally {
            mediaPlayer = null
        }
    }

    @Suppress("DEPRECATION")
    private fun stopVibrationOnly() {
        try {
            vibrator?.cancel()
        } catch (_: Exception) {
            // Bỏ qua lỗi hủy rung
        } finally {
            vibrator = null
        }
    }

    enum class AlarmSoundTarget {
        SILENT,
        BUNDLED_BERMUDA,
        SYSTEM_DEFAULT,
    }

    companion object {
        const val SOUND_OPTION_BERMUDA = "bermuda_alarm"
        const val SOUND_OPTION_VIBRATE_ONLY = "vibrate_only"

        const val CHANNEL_ID = "mindclock_alarm_ring_channel"

        fun resolveSoundTarget(
            soundEnabled: Boolean,
            soundOption: String,
        ): AlarmSoundTarget {
            if (!soundEnabled || soundOption == SOUND_OPTION_VIBRATE_ONLY) {
                return AlarmSoundTarget.SILENT
            }
            if (soundOption == SOUND_OPTION_BERMUDA) {
                return AlarmSoundTarget.BUNDLED_BERMUDA
            }
            return AlarmSoundTarget.SYSTEM_DEFAULT
        }
        const val NOTIFICATION_ID = 4109

        const val ACTION_START_RING = "com.mindclock.app.action.START_RING"
        const val ACTION_LOWER_VOLUME = "com.mindclock.app.action.LOWER_VOLUME"
        const val ACTION_EMERGENCY_STOP = "com.mindclock.app.action.EMERGENCY_STOP"
        const val ACTION_RING_STATE_CHANGED = "com.mindclock.app.action.RING_STATE_CHANGED"

        const val EXTRA_ALARM_ID = "extra_alarm_id"
        const val EXTRA_FORMATTED_TIME = "extra_formatted_time"
        const val EXTRA_MODE = "extra_mode"
        const val EXTRA_LABEL = "extra_label"
        const val EXTRA_SUBJECT_CODE = "extra_subject_code"
        const val EXTRA_SOUND_ENABLED = "extra_sound_enabled"
        const val EXTRA_VIBRATE_ENABLED = "extra_vibrate_enabled"
        const val EXTRA_SOUND_OPTION = "extra_sound_option"

        fun ensureNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return
            val existing = manager.getNotificationChannel(CHANNEL_ID)
            if (existing != null) return

            val channel = NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.alarm_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = context.getString(R.string.alarm_channel_desc)
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }

        fun buildRingActivityIntent(context: Context, payload: RingPayloadRecord): Intent {
            return Intent(context, AlarmRingActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_ALARM_ID, payload.alarmId)
                putExtra(EXTRA_FORMATTED_TIME, payload.formattedTime)
                putExtra(EXTRA_MODE, payload.mode)
                putExtra(EXTRA_LABEL, payload.label)
                putExtra(EXTRA_SUBJECT_CODE, payload.subjectCode)
            }
        }

        fun buildAlarmNotification(context: Context, payload: RingPayloadRecord): Notification {
            ensureNotificationChannel(context)
            val fullScreenIntent = buildRingActivityIntent(context, payload)
            val fullScreenPendingIntent = PendingIntent.getActivity(
                context,
                NOTIFICATION_ID,
                fullScreenIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val stopIntent = Intent(context, AlarmRingService::class.java).apply {
                action = ACTION_EMERGENCY_STOP
                putExtra(EXTRA_ALARM_ID, payload.alarmId)
            }
            val stopPendingIntent = PendingIntent.getService(
                context,
                NOTIFICATION_ID + 1,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val modeLabel = if (payload.mode == NativeAlarmRecord.MODE_CHALLENGE) {
                "Chế độ thử thách"
            } else {
                "Chế độ thường"
            }

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }

            return builder
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle("${payload.formattedTime} • ${payload.label}")
                .setContentText(modeLabel)
                .setCategory(Notification.CATEGORY_ALARM)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .setFullScreenIntent(fullScreenPendingIntent, true)
                .setContentIntent(fullScreenPendingIntent)
                .addAction(
                    Notification.Action.Builder(
                        null,
                        context.getString(R.string.alarm_emergency_stop),
                        stopPendingIntent,
                    ).build()
                )
                .build()
        }
    }
}
