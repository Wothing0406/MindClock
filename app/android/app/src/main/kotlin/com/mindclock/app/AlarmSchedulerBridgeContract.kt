package com.mindclock.app

/**
 * Hợp đồng chuẩn bị cho giai đoạn Android native nối `AlarmManager`, `NotificationManager`
 * và `USE_FULL_SCREEN_INTENT` qua MethodChannel `mindclock/alarm_scheduler`.
 *
 * Hiện tại Dart dùng `UnboundAlarmSchedulerService` (chỉ trả trạng thái `savedConfigOnly`
 * = "Đã lưu cấu hình", không giả lập đã cấp quyền hoặc "Đã sẵn sàng").
 */
interface AlarmSchedulerBridgeContract {
    companion object {
        const val CHANNEL_NAME = "mindclock/alarm_scheduler"
        const val METHOD_CHECK_CAPABILITIES = "checkCapabilities"
        const val METHOD_GET_PERMISSIONS = "getPermissionStatus"
        const val METHOD_SCHEDULE_ALARM = "scheduleAlarm"
        const val METHOD_CANCEL_ALARM = "cancelAlarm"
    }

    fun checkCapabilities(): Map<String, Any>
    fun getPermissionStatus(): Map<String, Any>
    fun scheduleAlarm(payload: Map<String, Any>): Map<String, Any>
    fun cancelAlarm(alarmId: String): Map<String, Any>
}
