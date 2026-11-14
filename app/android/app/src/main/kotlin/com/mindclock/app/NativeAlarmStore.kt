package com.mindclock.app

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Lưu trữ cấu hình báo thức local ở tầng Android native để `BOOT_COMPLETED`,
 * `TIME_SET`, `TIMEZONE_CHANGED` và `Dừng khẩn cấp` hoạt động kể cả khi FlutterEngine chưa khởi động.
 */
class NativeAlarmStore(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun saveAlarm(record: NativeAlarmRecord) {
        val current = getAllAlarms().filterNot { it.id == record.id }.toMutableList()
        current.add(record)
        writeAlarmList(current)
    }

    fun removeAlarm(alarmId: String) {
        val filtered = getAllAlarms().filterNot { it.id == alarmId }
        writeAlarmList(filtered)
    }

    fun getAlarm(alarmId: String): NativeAlarmRecord? {
        return getAllAlarms().firstOrNull { it.id == alarmId }
    }

    fun getAllAlarms(): List<NativeAlarmRecord> {
        val raw = prefs.getString(KEY_ALARMS_JSON, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            val result = mutableListOf<NativeAlarmRecord>()
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                NativeAlarmRecord.fromJson(obj)?.let { result.add(it) }
            }
            result
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun setPendingRingLaunch(payload: RingPayloadRecord?) {
        prefs.edit().apply {
            if (payload == null) {
                remove(KEY_PENDING_RING_LAUNCH)
            } else {
                putString(KEY_PENDING_RING_LAUNCH, payload.toJson().toString())
            }
        }.apply()
    }

    fun consumePendingRingLaunch(): RingPayloadRecord? {
        val raw = prefs.getString(KEY_PENDING_RING_LAUNCH, null) ?: return null
        prefs.edit().remove(KEY_PENDING_RING_LAUNCH).apply()
        return try {
            RingPayloadRecord.fromJson(JSONObject(raw))
        } catch (_: Exception) {
            null
        }
    }

    fun setActiveRingPayload(payload: RingPayloadRecord?) {
        prefs.edit().apply {
            if (payload == null) {
                remove(KEY_ACTIVE_RING)
            } else {
                putString(KEY_ACTIVE_RING, payload.toJson().toString())
            }
        }.apply()
    }

    fun getActiveRingPayload(): RingPayloadRecord? {
        val raw = prefs.getString(KEY_ACTIVE_RING, null) ?: return null
        return try {
            RingPayloadRecord.fromJson(JSONObject(raw))
        } catch (_: Exception) {
            null
        }
    }

    fun recordLocalAlarmEvent(alarmId: String, eventType: String, timestampMillis: Long) {
        val entry = JSONObject().apply {
            put("alarmId", alarmId)
            put("event", eventType)
            put("atEpochMillis", timestampMillis)
        }
        val raw = prefs.getString(KEY_EVENT_LOG, null)
        val array = try {
            if (raw != null) JSONArray(raw) else JSONArray()
        } catch (_: Exception) {
            JSONArray()
        }
        array.put(entry)
        val trimmed = JSONArray()
        val start = (array.length() - MAX_EVENT_LOG).coerceAtLeast(0)
        for (i in start until array.length()) {
            trimmed.put(array.get(i))
        }
        prefs.edit().putString(KEY_EVENT_LOG, trimmed.toString()).apply()
    }

    private fun writeAlarmList(records: List<NativeAlarmRecord>) {
        val array = JSONArray()
        records.forEach { array.put(it.toJson()) }
        prefs.edit().putString(KEY_ALARMS_JSON, array.toString()).apply()
    }

    companion object {
        private const val PREFS_NAME = "mindclock_native_alarms"
        private const val KEY_ALARMS_JSON = "alarms_json"
        private const val KEY_PENDING_RING_LAUNCH = "pending_ring_launch"
        private const val KEY_ACTIVE_RING = "active_ring"
        private const val KEY_EVENT_LOG = "alarm_event_log"
        private const val MAX_EVENT_LOG = 30
    }
}
