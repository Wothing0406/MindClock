package com.mindclock.app

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Receiver nhận sự kiện đúng giờ từ `AlarmManager.setAlarmClock`.
 * Bắt đầu `AlarmRingService` (foreground `mediaPlayback`), dự phòng notification nếu OS chặn FGS,
 * và tự đặt lại lần reo tiếp theo nếu là lịch lặp theo thứ.
 */
class AlarmFireReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        val store = NativeAlarmStore(context)
        val alarmId = intent.getStringExtra(AlarmRingService.EXTRA_ALARM_ID) ?: "primary_morning"
        val isSnooze = intent.getBooleanExtra(EXTRA_IS_SNOOZE, false)
        val record = store.getAlarm(alarmId)

        val formattedTime = intent.getStringExtra(AlarmRingService.EXTRA_FORMATTED_TIME)
            ?: record?.formattedTime
            ?: "06:00"
        val mode = intent.getStringExtra(AlarmRingService.EXTRA_MODE)
            ?: record?.mode
            ?: NativeAlarmRecord.MODE_NORMAL
        val label = intent.getStringExtra(AlarmRingService.EXTRA_LABEL)
            ?: record?.label
            ?: "Báo thức buổi sáng"
        val subjectCode = intent.getStringExtra(AlarmRingService.EXTRA_SUBJECT_CODE)
            ?: record?.subjectCode
        val soundEnabled = intent.getBooleanExtra(
            AlarmRingService.EXTRA_SOUND_ENABLED,
            record?.soundEnabled ?: true,
        )
        val vibrateEnabled = intent.getBooleanExtra(
            AlarmRingService.EXTRA_VIBRATE_ENABLED,
            record?.vibrateEnabled ?: true,
        )
        val soundOption = intent.getStringExtra(AlarmRingService.EXTRA_SOUND_OPTION)
            ?: record?.soundOption
            ?: "gentle_dawn"

        val serviceIntent = Intent(context, AlarmRingService::class.java).apply {
            action = AlarmRingService.ACTION_START_RING
            putExtra(AlarmRingService.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmRingService.EXTRA_FORMATTED_TIME, formattedTime)
            putExtra(AlarmRingService.EXTRA_MODE, mode)
            putExtra(AlarmRingService.EXTRA_LABEL, label)
            putExtra(AlarmRingService.EXTRA_SUBJECT_CODE, subjectCode)
            putExtra(AlarmRingService.EXTRA_SOUND_ENABLED, soundEnabled)
            putExtra(AlarmRingService.EXTRA_VIBRATE_ENABLED, vibrateEnabled)
            putExtra(AlarmRingService.EXTRA_SOUND_OPTION, soundOption)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (_: Exception) {
            // Dự phòng an toàn nếu OS chặn startForegroundService trong hoàn cảnh bất thường
            val payload = RingPayloadRecord(
                alarmId = alarmId,
                formattedTime = formattedTime,
                mode = mode,
                label = label,
                subjectCode = subjectCode,
                triggeredAtEpochMillis = System.currentTimeMillis(),
            )
            store.setActiveRingPayload(payload)
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.notify(
                AlarmRingService.NOTIFICATION_ID,
                AlarmRingService.buildAlarmNotification(context, payload),
            )
        }

        // Đặt lại lần reo tiếp theo cho báo thức lặp định kỳ (không áp dụng cho snooze một lần)
        if (!isSnooze && record != null && record.enabled && record.repeatWeekdays.isNotEmpty()) {
            AlarmSchedulerImpl(context).scheduleAlarmRecord(record)
        }
    }

    companion object {
        const val EXTRA_IS_SNOOZE = "extra_is_snooze"
    }
}
