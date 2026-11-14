package com.mindclock.app

/**
 * Hợp đồng chuẩn cho tầng Android native nối `AlarmManager`, `NotificationManager`
 * và `USE_FULL_SCREEN_INTENT` qua MethodChannel `mindclock/alarm_scheduler`.
 */
interface AlarmSchedulerBridgeContract {
    companion object {
        const val BRIDGE_VERSION = 1
        const val CHANNEL_NAME = "mindclock/alarm_scheduler"

        const val METHOD_CHECK_CAPABILITIES = "checkCapabilities"
        const val METHOD_GET_PERMISSIONS = "getPermissionStatus"
        const val METHOD_SCHEDULE_ALARM = "scheduleAlarm"
        const val METHOD_CANCEL_ALARM = "cancelAlarm"
        const val METHOD_SNOOZE_ALARM = "snoozeAlarm"
        const val METHOD_EMERGENCY_STOP = "emergencyStop"
        const val METHOD_OPEN_PERMISSION_SETTINGS = "openPermissionSettings"
        const val METHOD_CONSUME_PENDING_RING_LAUNCH = "consumePendingRingLaunch"

        const val ERROR_OK = "OK"
        const val ERROR_BRIDGE_UNBOUND = "BRIDGE_UNBOUND"
        const val ERROR_UNSUPPORTED_VERSION = "UNSUPPORTED_BRIDGE_VERSION"
        const val ERROR_INVALID_ARGUMENT = "INVALID_ARGUMENT"
        const val ERROR_PERMISSION_EXACT_ALARM_DENIED = "PERMISSION_EXACT_ALARM_DENIED"
        const val ERROR_PERMISSION_NOTIFICATION_DENIED = "PERMISSION_NOTIFICATION_DENIED"
        const val ERROR_PERMISSION_FULL_SCREEN_DENIED = "PERMISSION_FULL_SCREEN_DENIED"
        const val ERROR_OS_SCHEDULE_FAILED = "OS_SCHEDULE_FAILED"
        const val ERROR_UNKNOWN = "UNKNOWN_ERROR"

        const val STATUS_SCHEDULED_READY = "scheduledReady"
        const val STATUS_SAVED_CONFIG_ONLY = "savedConfigOnly"
        const val STATUS_OS_PERMISSION_MISSING = "osPermissionMissing"
        const val STATUS_OS_FAILED = "osFailed"

        const val ACTION_EXACT_ALARM = "exact_alarm"
        const val ACTION_NOTIFICATIONS = "notifications"
        const val ACTION_FULL_SCREEN_INTENT = "full_screen_intent"
        const val ACTION_BATTERY_OPTIMIZATION = "battery_optimization"
    }

    fun checkCapabilities(): Map<String, Any>
    fun getPermissionStatus(): Map<String, Any>
    fun scheduleAlarm(payload: Map<String, Any>): Map<String, Any>
    fun cancelAlarm(alarmId: String): Map<String, Any>
    fun snoozeAlarm(payload: Map<String, Any>): Map<String, Any>
    fun emergencyStop(alarmId: String?): Map<String, Any>
    fun openPermissionSettings(action: String): Map<String, Any>
    fun consumePendingRingLaunch(): Map<String, Any?>
}
