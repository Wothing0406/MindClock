package com.mindclock.app

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings

/**
 * Triển khai Android native cho [AlarmSchedulerBridgeContract] sử dụng
 * `AlarmManager.setAlarmClock`, kiểm tra quyền thật của OS và lưu trữ cục bộ.
 */
class AlarmSchedulerImpl(private val context: Context) : AlarmSchedulerBridgeContract {
    private val appContext = context.applicationContext
    private val alarmManager = appContext.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
    private val notificationManager =
        appContext.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
    private val store = NativeAlarmStore(appContext)

    override fun checkCapabilities(): Map<String, Any> {
        val supportsExactAlarm = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
        val supportsFullScreenIntent = Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
        return hashMapOf(
            "bridgeVersion" to AlarmSchedulerBridgeContract.BRIDGE_VERSION,
            "errorCode" to AlarmSchedulerBridgeContract.ERROR_OK,
            "isOsBridgeConnected" to true,
            "supportsExactAlarm" to supportsExactAlarm,
            "supportsFullScreenIntent" to supportsFullScreenIntent,
            "statusSummaryVi" to "Đã nối dịch vụ báo thức local Android.",
        )
    }

    override fun getPermissionStatus(): Map<String, Any> {
        val snapshot = readPermissions()
        return hashMapOf(
            "bridgeVersion" to AlarmSchedulerBridgeContract.BRIDGE_VERSION,
            "errorCode" to snapshot.firstMissingErrorCode(),
            "exactAlarm" to snapshot.exactAlarmWire,
            "notifications" to snapshot.notificationsWire,
            "fullScreenIntent" to snapshot.fullScreenIntentWire,
        )
    }

    override fun scheduleAlarm(payload: Map<String, Any>): Map<String, Any> {
        val record = NativeAlarmRecord.fromBridgeMap(payload)
            ?: return buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_OS_FAILED,
                errorCode = AlarmSchedulerBridgeContract.ERROR_INVALID_ARGUMENT,
                messageVi = "Dữ liệu cấu hình báo thức không hợp lệ.",
                permissions = readPermissions(),
            )

        store.saveAlarm(record)
        if (!record.enabled) {
            cancelPendingIntents(record.id)
            return buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_SAVED_CONFIG_ONLY,
                errorCode = AlarmSchedulerBridgeContract.ERROR_OK,
                messageVi = "Đã lưu cấu hình (báo thức đang tắt).",
                permissions = readPermissions(),
            )
        }

        val permissions = readPermissions()
        if (!permissions.allGranted) {
            return buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_OS_PERMISSION_MISSING,
                errorCode = permissions.firstMissingErrorCode(),
                messageVi = permissions.missingMessageVi(),
                permissions = permissions,
            )
        }

        return scheduleAlarmRecord(record, permissions)
    }

    override fun cancelAlarm(alarmId: String): Map<String, Any> {
        val cleanId = alarmId.trim()
        if (cleanId.isEmpty()) {
            return buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_OS_FAILED,
                errorCode = AlarmSchedulerBridgeContract.ERROR_INVALID_ARGUMENT,
                messageVi = "Thiếu mã báo thức cần hủy.",
                permissions = readPermissions(),
            )
        }
        cancelPendingIntents(cleanId)
        store.removeAlarm(cleanId)
        return buildResponse(
            status = AlarmSchedulerBridgeContract.STATUS_SAVED_CONFIG_ONLY,
            errorCode = AlarmSchedulerBridgeContract.ERROR_OK,
            messageVi = "Đã hủy lịch báo thức trên hệ thống.",
            permissions = readPermissions(),
        )
    }

    override fun snoozeAlarm(payload: Map<String, Any>): Map<String, Any> {
        val record = NativeAlarmRecord.fromBridgeMap(payload)
            ?: return buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_OS_FAILED,
                errorCode = AlarmSchedulerBridgeContract.ERROR_INVALID_ARGUMENT,
                messageVi = "Dữ liệu Hoãn báo thức không hợp lệ.",
                permissions = readPermissions(),
            )

        if (record.isChallengeMode) {
            return buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_OS_FAILED,
                errorCode = AlarmSchedulerBridgeContract.ERROR_INVALID_ARGUMENT,
                messageVi = "Chế độ thử thách không hỗ trợ Hoãn.",
                permissions = readPermissions(),
            )
        }

        val minutes = (payload["snoozeMinutes"] as? Number)?.toInt() ?: 5
        val permissions = readPermissions()
        if (!permissions.allGranted) {
            return buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_OS_PERMISSION_MISSING,
                errorCode = permissions.firstMissingErrorCode(),
                messageVi = permissions.missingMessageVi(),
                permissions = permissions,
            )
        }

        val triggerMillis = scheduleSnoozeRecord(record, minutes)
        emergencyStop(record.id)
        return buildResponse(
            status = AlarmSchedulerBridgeContract.STATUS_SCHEDULED_READY,
            errorCode = AlarmSchedulerBridgeContract.ERROR_OK,
            messageVi = "Đã đặt Hoãn $minutes phút cho chế độ thường.",
            permissions = permissions,
            scheduledNextEpochMillis = triggerMillis,
        )
    }

    override fun emergencyStop(alarmId: String?): Map<String, Any> {
        val cleanId = alarmId?.takeIf { it.isNotBlank() }
        val stopIntent = Intent(appContext, AlarmRingService::class.java).apply {
            action = AlarmRingService.ACTION_EMERGENCY_STOP
            if (cleanId != null) {
                putExtra(AlarmRingService.EXTRA_ALARM_ID, cleanId)
            }
        }
        try {
            appContext.startService(stopIntent)
        } catch (_: Exception) {
            appContext.stopService(Intent(appContext, AlarmRingService::class.java))
        }
        store.setActiveRingPayload(null)
        store.setPendingRingLaunch(null)
        notificationManager?.cancel(AlarmRingService.NOTIFICATION_ID)
        appContext.sendBroadcast(Intent(AlarmRingService.ACTION_RING_STATE_CHANGED).setPackage(appContext.packageName))

        return buildResponse(
            status = AlarmSchedulerBridgeContract.STATUS_SAVED_CONFIG_ONLY,
            errorCode = AlarmSchedulerBridgeContract.ERROR_OK,
            messageVi = "Đã dừng khẩn cấp âm thanh và rung báo thức.",
            permissions = readPermissions(),
        )
    }

    override fun openPermissionSettings(action: String): Map<String, Any> {
        val intent = when (action) {
            AlarmSchedulerBridgeContract.ACTION_EXACT_ALARM -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    Intent(
                        Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                        Uri.parse("package:${appContext.packageName}"),
                    )
                } else {
                    appDetailsIntent()
                }
            }
            AlarmSchedulerBridgeContract.ACTION_FULL_SCREEN_INTENT -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    Intent(
                        Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                        Uri.parse("package:${appContext.packageName}"),
                    )
                } else {
                    appNotificationSettingsIntent()
                }
            }
            AlarmSchedulerBridgeContract.ACTION_NOTIFICATIONS -> appNotificationSettingsIntent()
            AlarmSchedulerBridgeContract.ACTION_BATTERY_OPTIMIZATION -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                } else {
                    appDetailsIntent()
                }
            }
            else -> appDetailsIntent()
        }.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val opened = try {
            appContext.startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                appContext.startActivity(appDetailsIntent().addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                true
            } catch (_: Exception) {
                false
            }
        }

        return hashMapOf(
            "bridgeVersion" to AlarmSchedulerBridgeContract.BRIDGE_VERSION,
            "errorCode" to if (opened) AlarmSchedulerBridgeContract.ERROR_OK else AlarmSchedulerBridgeContract.ERROR_UNKNOWN,
            "opened" to opened,
        )
    }

    override fun consumePendingRingLaunch(): Map<String, Any?> {
        val pending = store.consumePendingRingLaunch() ?: store.getActiveRingPayload()
        return hashMapOf(
            "bridgeVersion" to AlarmSchedulerBridgeContract.BRIDGE_VERSION,
            "errorCode" to AlarmSchedulerBridgeContract.ERROR_OK,
            "payload" to pending?.toBridgeMap(),
        )
    }

    fun rescheduleAllEnabledAlarms() {
        val permissions = readPermissions()
        if (!permissions.exactAlarmGranted) return
        val enabledAlarms = store.getAllAlarms().filter { it.enabled }
        enabledAlarms.forEach { record ->
            scheduleAlarmRecord(record, permissions)
        }
    }

    fun scheduleAlarmRecord(
        record: NativeAlarmRecord,
        permissions: PermissionSnapshot = readPermissions(),
    ): Map<String, Any> {
        val manager = alarmManager ?: return buildResponse(
            status = AlarmSchedulerBridgeContract.STATUS_OS_FAILED,
            errorCode = AlarmSchedulerBridgeContract.ERROR_OS_SCHEDULE_FAILED,
            messageVi = "Thiết bị không cung cấp AlarmManager.",
            permissions = permissions,
        )

        val nextMillis = AlarmOccurrenceCalculator.computeNextTriggerMillis(
            alarm = record,
            nowMillis = System.currentTimeMillis(),
        )
        val firePendingIntent = buildFirePendingIntent(
            record = record,
            requestCode = record.requestCode(),
            isSnooze = false,
        )
        val showPendingIntent = buildShowPendingIntent(record)

        return try {
            val clockInfo = AlarmManager.AlarmClockInfo(nextMillis, showPendingIntent)
            manager.setAlarmClock(clockInfo, firePendingIntent)
            buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_SCHEDULED_READY,
                errorCode = AlarmSchedulerBridgeContract.ERROR_OK,
                messageVi = "Đã sẵn sàng: Android xác nhận báo thức lúc ${record.formattedTime}.",
                permissions = permissions,
                scheduledNextEpochMillis = nextMillis,
            )
        } catch (_: SecurityException) {
            buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_OS_PERMISSION_MISSING,
                errorCode = AlarmSchedulerBridgeContract.ERROR_PERMISSION_EXACT_ALARM_DENIED,
                messageVi = "Thiếu quyền Báo thức chính xác (Exact Alarm) trên Android.",
                permissions = readPermissions(),
            )
        } catch (_: Exception) {
            buildResponse(
                status = AlarmSchedulerBridgeContract.STATUS_OS_FAILED,
                errorCode = AlarmSchedulerBridgeContract.ERROR_OS_SCHEDULE_FAILED,
                messageVi = "Không thể đặt lịch với AlarmManager của thiết bị.",
                permissions = permissions,
            )
        }
    }

    fun scheduleSnoozeRecord(record: NativeAlarmRecord, minutes: Int): Long? {
        val manager = alarmManager ?: return null
        val nextMillis = AlarmOccurrenceCalculator.computeSnoozeTriggerMillis(
            nowMillis = System.currentTimeMillis(),
            snoozeMinutes = minutes,
        )
        val firePendingIntent = buildFirePendingIntent(
            record = record,
            requestCode = record.snoozeRequestCode(),
            isSnooze = true,
        )
        val showPendingIntent = buildShowPendingIntent(record)
        return try {
            val clockInfo = AlarmManager.AlarmClockInfo(nextMillis, showPendingIntent)
            manager.setAlarmClock(clockInfo, firePendingIntent)
            nextMillis
        } catch (_: Exception) {
            null
        }
    }

    private fun cancelPendingIntents(alarmId: String) {
        val manager = alarmManager ?: return
        val dummy = NativeAlarmRecord(
            id = alarmId,
            hour = 6,
            minute = 0,
            repeatWeekdays = emptyList(),
            enabled = false,
            soundEnabled = false,
            soundOption = "gentle_dawn",
            vibrateEnabled = false,
            mode = NativeAlarmRecord.MODE_NORMAL,
            subjectCode = null,
            label = "Báo thức",
        )
        val mainPi = PendingIntent.getBroadcast(
            appContext,
            dummy.requestCode(),
            Intent(appContext, AlarmFireReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (mainPi != null) {
            manager.cancel(mainPi)
            mainPi.cancel()
        }
        val snoozePi = PendingIntent.getBroadcast(
            appContext,
            dummy.snoozeRequestCode(),
            Intent(appContext, AlarmFireReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (snoozePi != null) {
            manager.cancel(snoozePi)
            snoozePi.cancel()
        }
    }

    private fun buildFirePendingIntent(
        record: NativeAlarmRecord,
        requestCode: Int,
        isSnooze: Boolean,
    ): PendingIntent {
        val intent = Intent(appContext, AlarmFireReceiver::class.java).apply {
            putExtra(AlarmRingService.EXTRA_ALARM_ID, record.id)
            putExtra(AlarmRingService.EXTRA_FORMATTED_TIME, record.formattedTime)
            putExtra(AlarmRingService.EXTRA_MODE, record.mode)
            putExtra(AlarmRingService.EXTRA_LABEL, record.label)
            putExtra(AlarmRingService.EXTRA_SUBJECT_CODE, record.subjectCode)
            putExtra(AlarmRingService.EXTRA_SOUND_ENABLED, record.soundEnabled)
            putExtra(AlarmRingService.EXTRA_VIBRATE_ENABLED, record.vibrateEnabled)
            putExtra(AlarmRingService.EXTRA_SOUND_OPTION, record.soundOption)
            putExtra(AlarmFireReceiver.EXTRA_IS_SNOOZE, isSnooze)
        }
        return PendingIntent.getBroadcast(
            appContext,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun buildShowPendingIntent(record: NativeAlarmRecord): PendingIntent {
        val intent = Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            appContext,
            record.requestCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun appNotificationSettingsIntent(): Intent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, appContext.packageName)
            }
        } else {
            appDetailsIntent()
        }
    }

    private fun appDetailsIntent(): Intent {
        return Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${appContext.packageName}"),
        )
    }

    private fun readPermissions(): PermissionSnapshot {
        val exactGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager?.canScheduleExactAlarms() == true
        } else {
            true
        }

        val notifGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            appContext.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            notificationManager?.areNotificationsEnabled() != false
        }

        val fullScreenGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            notificationManager?.canUseFullScreenIntent() == true
        } else {
            true
        }

        return PermissionSnapshot(
            exactAlarmGranted = exactGranted,
            notificationsGranted = notifGranted,
            fullScreenIntentGranted = fullScreenGranted,
        )
    }

    private fun buildResponse(
        status: String,
        errorCode: String,
        messageVi: String,
        permissions: PermissionSnapshot,
        scheduledNextEpochMillis: Long? = null,
    ): Map<String, Any> {
        val map = hashMapOf<String, Any>(
            "bridgeVersion" to AlarmSchedulerBridgeContract.BRIDGE_VERSION,
            "status" to status,
            "errorCode" to errorCode,
            "messageVi" to messageVi,
            "permissions" to hashMapOf(
                "exactAlarm" to permissions.exactAlarmWire,
                "notifications" to permissions.notificationsWire,
                "fullScreenIntent" to permissions.fullScreenIntentWire,
            ),
        )
        if (scheduledNextEpochMillis != null) {
            map["scheduledNextEpochMillis"] = scheduledNextEpochMillis
        }
        return map
    }

    data class PermissionSnapshot(
        val exactAlarmGranted: Boolean,
        val notificationsGranted: Boolean,
        val fullScreenIntentGranted: Boolean,
    ) {
        val allGranted: Boolean
            get() = exactAlarmGranted && notificationsGranted && fullScreenIntentGranted

        val exactAlarmWire: String
            get() = if (exactAlarmGranted) "granted" else "denied"

        val notificationsWire: String
            get() = if (notificationsGranted) "granted" else "denied"

        val fullScreenIntentWire: String
            get() = if (fullScreenIntentGranted) "granted" else "denied"

        fun firstMissingErrorCode(): String {
            return when {
                !exactAlarmGranted -> AlarmSchedulerBridgeContract.ERROR_PERMISSION_EXACT_ALARM_DENIED
                !notificationsGranted -> AlarmSchedulerBridgeContract.ERROR_PERMISSION_NOTIFICATION_DENIED
                !fullScreenIntentGranted -> AlarmSchedulerBridgeContract.ERROR_PERMISSION_FULL_SCREEN_DENIED
                else -> AlarmSchedulerBridgeContract.ERROR_OK
            }
        }

        fun missingMessageVi(): String {
            return when {
                !exactAlarmGranted ->
                    "Chưa sẵn sàng: cần cấp quyền Báo thức & lời nhắc (Exact Alarm) trong Cài đặt Android."
                !notificationsGranted ->
                    "Chưa sẵn sàng: cần cấp quyền Thông báo để hiển thị chuông khi đang reo."
                !fullScreenIntentGranted ->
                    "Chưa sẵn sàng: cần cấp quyền Hiển thị toàn màn hình báo thức khi khóa máy."
                else -> "Đủ quyền báo thức Android."
            }
        }
    }
}
