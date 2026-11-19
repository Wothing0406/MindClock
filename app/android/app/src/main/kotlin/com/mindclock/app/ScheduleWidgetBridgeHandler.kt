package com.mindclock.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class ScheduleWidgetBridgeHandler(private val context: Context) {
    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "syncWidgetSnapshot" -> {
                val snapshotJson = call.argument<String>("snapshotJson") ?: ""
                if (snapshotJson.isNotEmpty()) {
                    MindClockScheduleWidgetProvider.saveSnapshotJson(context, snapshotJson)
                }
                result.success(null)
            }
            "scheduleTaskReminder" -> {
                val taskId = call.argument<String>("id") ?: ""
                val title = call.argument<String>("title") ?: ""
                val dateIso = call.argument<String>("dateIso") ?: ""
                val startMinutes = call.argument<Int>("startMinutes") ?: 480
                val categoryId = call.argument<String>("category") ?: "self_study"
                if (taskId.isNotEmpty() && title.isNotEmpty()) {
                    scheduleReminder(taskId, title, dateIso, startMinutes, categoryId)
                }
                result.success(null)
            }
            "cancelTaskReminder" -> {
                val taskId = call.argument<String>("taskId") ?: ""
                if (taskId.isNotEmpty()) {
                    cancelReminder(taskId)
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun scheduleReminder(
        taskId: String,
        title: String,
        dateIso: String,
        startMinutes: Int,
        categoryId: String,
    ) {
        TaskReminderReceiver.ensureChannel(context)
        val parts = dateIso.split("-")
        if (parts.size != 3) return
        val year = parts[0].toIntOrNull() ?: return
        val month = parts[1].toIntOrNull() ?: return
        val day = parts[2].toIntOrNull() ?: return
        val hour = (startMinutes / 60).coerceIn(0, 23)
        val minute = (startMinutes % 60).coerceIn(0, 59)

        val cal = Calendar.getInstance().apply {
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month - 1)
            set(Calendar.DAY_OF_MONTH, day)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (cal.timeInMillis <= System.currentTimeMillis()) return

        val categoryVi = when (categoryId) {
            "extra" -> "Học thêm"
            "school" -> "Chính khóa"
            else -> "Tự học"
        }
        val timeLabel = "%02d:%02d".format(hour, minute)
        val intent = Intent(context, TaskReminderReceiver::class.java).apply {
            putExtra(TaskReminderReceiver.EXTRA_TASK_ID, taskId)
            putExtra(TaskReminderReceiver.EXTRA_TITLE, title)
            putExtra(TaskReminderReceiver.EXTRA_CATEGORY, categoryVi)
            putExtra(TaskReminderReceiver.EXTRA_TIME_LABEL, timeLabel)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            taskId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        try {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pending)
        } catch (_: SecurityException) {
            // Không chặn tạo việc nếu OS hạn chế đặt alarm nền.
        }
    }

    private fun cancelReminder(taskId: String) {
        val intent = Intent(context, TaskReminderReceiver::class.java)
        val pending = PendingIntent.getBroadcast(
            context,
            taskId.hashCode(),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (pending != null) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(pending)
            pending.cancel()
        }
    }

    companion object {
        const val CHANNEL_NAME = "mindclock/schedule_widget"
    }
}
