package com.mindclock.app

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receiver khôi phục lịch báo thức local sau khi khởi động lại máy, cập nhật app,
 * đổi giờ/múi giờ hệ thống hoặc người dùng vừa cấp quyền Exact Alarm.
 *
 * Tuân thủ Android 14/15: chỉ lập lịch lại `AlarmManager`, tuyệt đối không gọi
 * `startForegroundService(mediaPlayback)` bên trong `BOOT_COMPLETED`.
 */
class BootAndTimeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        val supported = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED,
        )
        if (!supported.contains(action)) return

        AlarmSchedulerImpl(context).rescheduleAllEnabledAlarms()
    }
}
