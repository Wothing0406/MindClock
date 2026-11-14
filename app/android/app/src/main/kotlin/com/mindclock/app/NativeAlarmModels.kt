package com.mindclock.app

import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

data class NativeAlarmRecord(
    val id: String,
    val hour: Int,
    val minute: Int,
    val repeatWeekdays: List<Int>,
    val enabled: Boolean,
    val soundEnabled: Boolean,
    val soundOption: String,
    val vibrateEnabled: Boolean,
    val mode: String,
    val subjectCode: String?,
    val label: String,
) {
    val isChallengeMode: Boolean
        get() = mode == MODE_CHALLENGE

    val formattedTime: String
        get() = String.format(Locale.US, "%02d:%02d", hour.coerceIn(0, 23), minute.coerceIn(0, 59))

    fun requestCode(): Int = id.hashCode() and 0x7FFFFFFF

    fun snoozeRequestCode(): Int = ("$id#snooze").hashCode() and 0x7FFFFFFF

    fun toJson(): JSONObject {
        val array = JSONArray()
        repeatWeekdays.forEach { array.put(it) }
        return JSONObject().apply {
            put("id", id)
            put("hour", hour)
            put("minute", minute)
            put("repeatWeekdays", array)
            put("enabled", enabled)
            put("soundEnabled", soundEnabled)
            put("soundOption", soundOption)
            put("vibrateEnabled", vibrateEnabled)
            put("mode", mode)
            put("subjectCode", subjectCode ?: JSONObject.NULL)
            put("label", label)
        }
    }

    companion object {
        const val MODE_NORMAL = "normal"
        const val MODE_CHALLENGE = "challenge"

        fun fromBridgeMap(map: Map<String, Any>): NativeAlarmRecord? {
            val id = (map["id"] as? String)?.trim().orEmpty()
            if (id.isEmpty()) return null
            val hour = (map["hour"] as? Number)?.toInt() ?: return null
            val minute = (map["minute"] as? Number)?.toInt() ?: return null
            if (hour !in 0..23 || minute !in 0..59) return null

            val rawDays = map["repeatWeekdays"] as? List<*> ?: emptyList<Any>()
            val weekdays = rawDays.mapNotNull { (it as? Number)?.toInt() }
                .filter { it in 1..7 }
                .distinct()
                .sorted()

            val mode = when (map["mode"] as? String) {
                MODE_CHALLENGE -> MODE_CHALLENGE
                else -> MODE_NORMAL
            }

            return NativeAlarmRecord(
                id = id,
                hour = hour,
                minute = minute,
                repeatWeekdays = weekdays,
                enabled = map["enabled"] as? Boolean ?: true,
                soundEnabled = map["soundEnabled"] as? Boolean ?: true,
                soundOption = map["soundOption"] as? String ?: "gentle_dawn",
                vibrateEnabled = map["vibrateEnabled"] as? Boolean ?: true,
                mode = mode,
                subjectCode = (map["subjectCode"] as? String)?.takeIf { it.isNotBlank() },
                label = (map["label"] as? String)?.takeIf { it.isNotBlank() } ?: "Báo thức buổi sáng",
            )
        }

        fun fromJson(json: JSONObject): NativeAlarmRecord? {
            val id = json.optString("id", "").trim()
            if (id.isEmpty()) return null
            val hour = json.optInt("hour", -1)
            val minute = json.optInt("minute", -1)
            if (hour !in 0..23 || minute !in 0..59) return null

            val arr = json.optJSONArray("repeatWeekdays")
            val weekdays = mutableListOf<Int>()
            if (arr != null) {
                for (i in 0 until arr.length()) {
                    val d = arr.optInt(i, -1)
                    if (d in 1..7 && !weekdays.contains(d)) {
                        weekdays.add(d)
                    }
                }
            }
            weekdays.sort()

            val rawSubject = if (json.isNull("subjectCode")) null else json.optString("subjectCode", "")
            val mode = if (json.optString("mode") == MODE_CHALLENGE) MODE_CHALLENGE else MODE_NORMAL

            return NativeAlarmRecord(
                id = id,
                hour = hour,
                minute = minute,
                repeatWeekdays = weekdays,
                enabled = json.optBoolean("enabled", true),
                soundEnabled = json.optBoolean("soundEnabled", true),
                soundOption = json.optString("soundOption", "gentle_dawn"),
                vibrateEnabled = json.optBoolean("vibrateEnabled", true),
                mode = mode,
                subjectCode = rawSubject?.takeIf { it.isNotBlank() },
                label = json.optString("label", "Báo thức buổi sáng").ifBlank { "Báo thức buổi sáng" },
            )
        }
    }
}

data class RingPayloadRecord(
    val alarmId: String,
    val formattedTime: String,
    val mode: String,
    val label: String,
    val subjectCode: String?,
    val triggeredAtEpochMillis: Long,
) {
    fun toBridgeMap(): Map<String, Any?> = hashMapOf(
        "alarmId" to alarmId,
        "formattedTime" to formattedTime,
        "mode" to mode,
        "label" to label,
        "subjectCode" to subjectCode,
        "triggeredAtEpochMillis" to triggeredAtEpochMillis,
    )

    fun toJson(): JSONObject = JSONObject().apply {
        put("alarmId", alarmId)
        put("formattedTime", formattedTime)
        put("mode", mode)
        put("label", label)
        put("subjectCode", subjectCode ?: JSONObject.NULL)
        put("triggeredAtEpochMillis", triggeredAtEpochMillis)
    }

    companion object {
        fun fromJson(json: JSONObject): RingPayloadRecord? {
            val alarmId = json.optString("alarmId", "").trim()
            if (alarmId.isEmpty()) return null
            val rawSubject = if (json.isNull("subjectCode")) null else json.optString("subjectCode", "")
            return RingPayloadRecord(
                alarmId = alarmId,
                formattedTime = json.optString("formattedTime", "06:00"),
                mode = if (json.optString("mode") == NativeAlarmRecord.MODE_CHALLENGE) {
                    NativeAlarmRecord.MODE_CHALLENGE
                } else {
                    NativeAlarmRecord.MODE_NORMAL
                },
                label = json.optString("label", "Báo thức buổi sáng"),
                subjectCode = rawSubject?.takeIf { it.isNotBlank() },
                triggeredAtEpochMillis = json.optLong("triggeredAtEpochMillis", 0L),
            )
        }
    }
}

/**
 * Tính thời điểm reo tiếp theo hoàn toàn cục bộ trên thiết bị,
 * hỗ trợ lặp theo thứ (ISO 1=Thứ 2..7=Chủ nhật), qua ngày, đổi giờ và đổi múi giờ.
 */
object AlarmOccurrenceCalculator {
    fun computeNextTriggerMillis(
        alarm: NativeAlarmRecord,
        nowMillis: Long,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): Long {
        val candidate = Calendar.getInstance(timeZone).apply {
            timeInMillis = nowMillis
            set(Calendar.HOUR_OF_DAY, alarm.hour.coerceIn(0, 23))
            set(Calendar.MINUTE, alarm.minute.coerceIn(0, 59))
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (alarm.repeatWeekdays.isEmpty()) {
            if (candidate.timeInMillis <= nowMillis) {
                candidate.add(Calendar.DAY_OF_YEAR, 1)
            }
            return candidate.timeInMillis
        }

        val allowed = alarm.repeatWeekdays.filter { it in 1..7 }.toSet()
        for (offsetDays in 0..7) {
            val dayCandidate = (candidate.clone() as Calendar).apply {
                add(Calendar.DAY_OF_YEAR, offsetDays)
            }
            val isoWeekday = toIsoWeekday(dayCandidate.get(Calendar.DAY_OF_WEEK))
            if (allowed.contains(isoWeekday) && dayCandidate.timeInMillis > nowMillis) {
                return dayCandidate.timeInMillis
            }
        }

        // Fallback an toàn nếu mọi ngày cùng vòng không hợp lệ
        candidate.add(Calendar.DAY_OF_YEAR, 7)
        return candidate.timeInMillis
    }

    fun computeSnoozeTriggerMillis(nowMillis: Long, snoozeMinutes: Int): Long {
        val safeMinutes = snoozeMinutes.coerceIn(1, 30)
        return nowMillis + safeMinutes * 60_000L
    }

    fun toIsoWeekday(calendarDayOfWeek: Int): Int {
        return when (calendarDayOfWeek) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            Calendar.SUNDAY -> 7
            else -> 1
        }
    }
}
