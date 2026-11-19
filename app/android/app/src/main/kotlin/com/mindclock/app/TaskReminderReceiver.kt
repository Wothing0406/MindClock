package com.mindclock.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class TaskReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "Việc học MindClock"
        val category = intent.getStringExtra(EXTRA_CATEGORY) ?: "Nhắc lịch"
        val timeLabel = intent.getStringExtra(EXTRA_TIME_LABEL) ?: ""

        ensureChannel(context)
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPending = PendingIntent.getActivity(
            context,
            taskId.hashCode(),
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = android.app.Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Đến giờ: $title")
            .setContentText(
                if (timeLabel.isNotBlank()) "$category · $timeLabel · Chạm để mở MindClock"
                else "$category · Chạm để mở MindClock",
            )
            .setAutoCancel(true)
            .setContentIntent(contentPending)

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_BASE_ID + (taskId.hashCode() and 0x7FFF), builder.build())
    }

    companion object {
        const val CHANNEL_ID = "mindclock_task_reminders"
        const val EXTRA_TASK_ID = "extra_task_id"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_CATEGORY = "extra_category"
        const val EXTRA_TIME_LABEL = "extra_time_label"
        private const val NOTIFICATION_BASE_ID = 42000

        fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val nm =
                    context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                    val ch = NotificationChannel(
                        CHANNEL_ID,
                        "Nhắc lịch học MindClock",
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply {
                        description = "Thông báo nhắc đúng giờ cho To-do và lịch học thêm trong ngày."
                    }
                    nm.createNotificationChannel(ch)
                }
            }
        }
    }
}
