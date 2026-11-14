package com.mindclock.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Entrypoint FlutterActivity cho MindClock Android (không dùng Hilt/Compose).
 * Nối `MethodChannel("mindclock/alarm_scheduler")` và `MethodChannel("mindclock/camera_capture")`.
 */
class MainActivity : FlutterActivity() {
    private lateinit var schedulerBridge: AlarmSchedulerBridgeContract
    private lateinit var cameraBridge: CameraBridgeHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        schedulerBridge = AlarmSchedulerImpl(this)
        cameraBridge = CameraBridgeHandler(this)
        AlarmRingService.ensureNotificationChannel(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AlarmSchedulerBridgeContract.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CameraBridgeHandler.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            if (call.method == "captureHandwrittenPhoto") {
                cameraBridge.handleCaptureRequest(result)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (::cameraBridge.isInitialized &&
            cameraBridge.onRequestPermissionsResult(requestCode, grantResults)
        ) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (::cameraBridge.isInitialized &&
            cameraBridge.onActivityResult(requestCode, resultCode, data)
        ) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val requestedVersion = (args?.get("bridgeVersion") as? Number)?.toInt()
        if (requestedVersion != AlarmSchedulerBridgeContract.BRIDGE_VERSION) {
            result.success(
                hashMapOf(
                    "bridgeVersion" to AlarmSchedulerBridgeContract.BRIDGE_VERSION,
                    "status" to AlarmSchedulerBridgeContract.STATUS_OS_FAILED,
                    "errorCode" to AlarmSchedulerBridgeContract.ERROR_UNSUPPORTED_VERSION,
                    "messageVi" to "Phiên bản bridge Android không khớp.",
                )
            )
            return
        }

        @Suppress("UNCHECKED_CAST")
        val typedArgs = (args as? Map<String, Any>) ?: emptyMap()

        when (call.method) {
            AlarmSchedulerBridgeContract.METHOD_CHECK_CAPABILITIES ->
                result.success(schedulerBridge.checkCapabilities())

            AlarmSchedulerBridgeContract.METHOD_GET_PERMISSIONS ->
                result.success(schedulerBridge.getPermissionStatus())

            AlarmSchedulerBridgeContract.METHOD_SCHEDULE_ALARM ->
                result.success(schedulerBridge.scheduleAlarm(typedArgs))

            AlarmSchedulerBridgeContract.METHOD_CANCEL_ALARM -> {
                val alarmId = typedArgs["alarmId"] as? String ?: ""
                result.success(schedulerBridge.cancelAlarm(alarmId))
            }

            AlarmSchedulerBridgeContract.METHOD_SNOOZE_ALARM ->
                result.success(schedulerBridge.snoozeAlarm(typedArgs))

            AlarmSchedulerBridgeContract.METHOD_EMERGENCY_STOP -> {
                val alarmId = typedArgs["alarmId"] as? String
                result.success(schedulerBridge.emergencyStop(alarmId))
            }

            AlarmSchedulerBridgeContract.METHOD_OPEN_PERMISSION_SETTINGS -> {
                val action = typedArgs["action"] as? String ?: ""
                result.success(schedulerBridge.openPermissionSettings(action))
            }

            AlarmSchedulerBridgeContract.METHOD_CONSUME_PENDING_RING_LAUNCH ->
                result.success(schedulerBridge.consumePendingRingLaunch())

            else -> result.notImplemented()
        }
    }
}
