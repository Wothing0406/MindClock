package com.mindclock.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

data class WidgetRenderModel(
    val headerLabel: String,
    val dayTitle: String,
    val progressBadge: String,
    val lines: List<String>,
    val alarmFooter: String,
)

object MindClockWidgetFormatter {
    const val MAX_ITEMS = 4

    fun formatFromJson(rawJson: String?): WidgetRenderModel {
        if (rawJson.isNullOrBlank()) {
            return WidgetRenderModel(
                headerLabel = "MINDCLOCK · HÔM NAY",
                dayTitle = "Lịch trình học tập",
                progressBadge = "0 việc",
                lines = listOf("Chạm để mở MindClock và thêm lịch hôm nay"),
                alarmFooter = "Chưa bật chuông",
            )
        }
        return try {
            val obj = JSONObject(rawJson)
            val weekdayShort = obj.optString("weekdayShortVi", "HÔM NAY").ifBlank { "HÔM NAY" }
            val monthLabel = obj.optString("monthLabelVi", "").trim()
            val dayNum = obj.optString("dayNumberLabel", "").trim()
            val doneCount = obj.optInt("doneCount", 0)
            val totalCount = obj.optInt("totalCount", 0)
            val alarmFooter = obj.optString("nextAlarmLabelVi", "Chưa bật chuông")
                .ifBlank { "Chưa bật chuông" }

            val header = if (monthLabel.isNotBlank()) {
                "$weekdayShort · $monthLabel"
            } else {
                weekdayShort
            }
            val title = if (dayNum.isNotBlank()) {
                "Ngày $dayNum · Lịch hôm nay"
            } else {
                "Lịch hôm nay"
            }
            val badge = if (totalCount > 0) {
                "$doneCount/$totalCount xong"
            } else {
                "0 việc"
            }

            val itemsArr = obj.optJSONArray("items")
            val formattedLines = mutableListOf<String>()
            if (itemsArr != null) {
                val limit = minOf(itemsArr.length(), MAX_ITEMS)
                for (i in 0 until limit) {
                    val item = itemsArr.optJSONObject(i) ?: continue
                    val timeLabel = item.optString("timeLabel", "--:--").trim()
                    val rawTitle = item.optString("title", "Việc học").trim()
                    val cat = item.optString("categoryLabelVi", "").trim()
                    val isDone = item.optBoolean("isDone", false)
                    val prefix = if (isDone) "[Done]" else "•"
                    val shortTitle = if (rawTitle.length > 26) {
                        rawTitle.take(25) + "…"
                    } else {
                        rawTitle
                    }
                    val suffix = if (cat.isNotEmpty() && cat == "Học thêm") " (Thêm)" else ""
                    formattedLines.add("$prefix $timeLabel $shortTitle$suffix")
                }
            }
            if (formattedLines.isEmpty()) {
                formattedLines.add("Hôm nay chưa có sự kiện — chạm để thêm")
            }

            WidgetRenderModel(
                headerLabel = header,
                dayTitle = title,
                progressBadge = badge,
                lines = formattedLines,
                alarmFooter = alarmFooter,
            )
        } catch (_: Exception) {
            WidgetRenderModel(
                headerLabel = "MINDCLOCK · HÔM NAY",
                dayTitle = "Lịch trình học tập",
                progressBadge = "0 việc",
                lines = listOf("Chạm để mở MindClock"),
                alarmFooter = "Chưa bật chuông",
            )
        }
    }
}

class MindClockScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val rawJson = readSnapshotJson(context)
        val model = MindClockWidgetFormatter.formatFromJson(rawJson)
        for (appWidgetId in appWidgetIds) {
            updateSingleWidget(context, appWidgetManager, appWidgetId, model)
        }
    }

    companion object {
        private const val PREFS_NAME = "mindclock_widget_prefs"
        private const val KEY_SNAPSHOT_JSON = "today_schedule_snapshot_json"

        fun saveSnapshotJson(context: Context, snapshotJson: String) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_SNAPSHOT_JSON, snapshotJson)
                .apply()
            updateAllWidgets(context)
        }

        fun readSnapshotJson(context: Context): String? {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getString(KEY_SNAPSHOT_JSON, null)
        }

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, MindClockScheduleWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isEmpty()) return
            val model = MindClockWidgetFormatter.formatFromJson(readSnapshotJson(context))
            for (id in ids) {
                updateSingleWidget(context, manager, id, model)
            }
        }

        private fun updateSingleWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
            model: WidgetRenderModel,
        ) {
            val views = RemoteViews(context.packageName, R.layout.mindclock_schedule_widget)
            views.setTextViewText(R.id.widget_header_date, model.headerLabel)
            views.setTextViewText(R.id.widget_day_number, model.dayTitle)
            views.setTextViewText(R.id.widget_progress_badge, model.progressBadge)
            views.setTextViewText(R.id.widget_alarm_footer, model.alarmFooter)

            val itemViewIds = intArrayOf(
                R.id.widget_item_1,
                R.id.widget_item_2,
                R.id.widget_item_3,
                R.id.widget_item_4,
            )
            for (i in itemViewIds.indices) {
                val viewId = itemViewIds[i]
                if (i < model.lines.size) {
                    views.setViewVisibility(viewId, View.VISIBLE)
                    views.setTextViewText(viewId, model.lines[i])
                } else {
                    views.setViewVisibility(viewId, View.GONE)
                }
            }

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            manager.updateAppWidget(appWidgetId, views)
        }
    }
}
