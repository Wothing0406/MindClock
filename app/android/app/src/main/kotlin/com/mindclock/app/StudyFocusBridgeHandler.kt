package com.mindclock.app

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.RingtoneManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Cầu nối Android native cho Không gian học (`mindclock/study_focus`).
 *
 * - Hoàn toàn tách biệt với `AlarmSchedulerImpl` và kênh thông báo của `AlarmRingService`.
 * - Không dùng Accessibility, overlay, VPN, device-admin, UsageStats hay Lock Task kiosk.
 * - Mở Digital Wellbeing Focus mode nếu thiết bị có; trả kết quả trung thực nếu không hỗ trợ.
 * - Thông báo nhắc rời app > 30 giây dùng 1 ID cố định (`NOTIFICATION_ID = 4301`) + `setOnlyAlertOnce(true)`
 *   nên không bao giờ chồng thông báo, và chỉ gửi khi người dùng đã cấp quyền `POST_NOTIFICATIONS`.
 */
class StudyFocusBridgeHandler(private val activity: Activity) {
    private val appContext: Context = activity.applicationContext
    private val notificationManager =
        appContext.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
    private var pendingPermissionResult: MethodChannel.Result? = null

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val requestedVersion = (args?.get("bridgeVersion") as? Number)?.toInt()
        if (requestedVersion != BRIDGE_VERSION) {
            result.error("UNSUPPORTED_BRIDGE_VERSION", "Phiên bản study_focus bridge không khớp.", null)
            return
        }

        when (call.method) {
            "openDigitalWellbeingFocusSettings" -> result.success(openDigitalWellbeingFocusSettings())
            "getNotificationPermissionStatus" -> result.success(getNotificationPermissionStatus())
            "requestNotificationPermission" -> handleRequestNotificationPermission(result)
            "showSingleStudyReminder" -> {
                val titleVi = (args?.get("titleVi") as? String)?.trim().takeUnless { it.isNullOrEmpty() }
                    ?: "Phiên học đang mở"
                val bodyVi = (args?.get("bodyVi") as? String)?.trim().takeUnless { it.isNullOrEmpty() }
                    ?: "Quay lại việc học đang làm trên MindClock."
                showSingleStudyReminder(titleVi, bodyVi)
                result.success(hashMapOf("shown" to true))
            }
            "cancelStudyReminder" -> {
                notificationManager?.cancel(NOTIFICATION_ID)
                result.success(hashMapOf("cancelled" to true))
            }
            "playSessionEndCue" -> {
                playSessionEndCue()
                result.success(hashMapOf("played" to true))
            }
            else -> result.notImplemented()
        }
    }

    private fun openDigitalWellbeingFocusSettings(): Map<String, Any> {
        val pm = activity.packageManager
        val candidates = listOf(
            "com.google.android.apps.wellbeing",
            "com.samsung.android.forest",
        )
        for (pkg in candidates) {
            val launchIntent = pm.getLaunchIntentForPackage(pkg) ?: continue
            if (launchIntent.resolveActivity(pm) != null) {
                try {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    activity.startActivity(launchIntent)
                    return hashMapOf(
                        "opened" to true,
                        "target" to "digital_wellbeing",
                        "messageVi" to "Đã mở Digital Wellbeing. Bạn tự chọn bật/tắt Focus mode trên máy; MindClock không khóa app khác.",
                    )
                } catch (_: Exception) {
                    // Thử tiếp ứng viên kế tiếp hoặc báo trung thực.
                }
            }
        }

        return hashMapOf(
            "opened" to false,
            "target" to "unavailable",
            "messageVi" to "Thiết bị không có Digital Wellbeing chuẩn để mở thẳng. Bạn có thể tự kiểm tra Focus mode trong Cài đặt Android; MindClock không tự khóa app khác.",
        )
    }

    private fun getNotificationPermissionStatus(): Map<String, Any> {
        val status = if (hasNotificationPermission()) "granted" else "denied"
        return hashMapOf("status" to status)
    }

    private fun handleRequestNotificationPermission(result: MethodChannel.Result) {
        if (hasNotificationPermission() || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(hashMapOf("status" to if (hasNotificationPermission()) "granted" else "denied"))
            return
        }
        if (pendingPermissionResult != null) {
            result.success(hashMapOf("status" to "denied"))
            return
        }
        pendingPermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_POST_NOTIFICATIONS,
        )
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_POST_NOTIFICATIONS) return false
        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        result.success(hashMapOf("status" to if (granted) "granted" else "denied"))
        return true
    }

    private fun showSingleStudyReminder(titleVi: String, bodyVi: String) {
        if (!hasNotificationPermission()) return
        val manager = notificationManager ?: return
        ensureNotificationChannel(manager)

        val launchIntent = Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            appContext,
            NOTIFICATION_ID,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(appContext, STUDY_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(appContext)
        }

        val notification = builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(titleVi)
            .setContentText(bodyVi)
            .setOnlyAlertOnce(true)
            .setAutoCancel(true)
            .setContentIntent(contentPendingIntent)
            .build()

        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun playSessionEndCue() {
        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION) ?: return
            val ringtone = RingtoneManager.getRingtone(appContext, uri)
            ringtone?.play()
        } catch (_: Exception) {
            // Lỗi âm cuối phiên không ảnh hưởng lưu phiên hay báo thức.
        }
    }

    private fun hasNotificationPermission(): Boolean {
        val manager = notificationManager ?: return false
        if (!manager.areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return appContext.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun ensureNotificationChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (manager.getNotificationChannel(STUDY_CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            STUDY_CHANNEL_ID,
            "Nhắc phiên học MindClock",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Một nhắc cục bộ khi rời phiên Tập trung thường quá 30 giây (không chồng thông báo)."
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val BRIDGE_VERSION = 1
        const val CHANNEL_NAME = "mindclock/study_focus"
        private const val STUDY_CHANNEL_ID = "mindclock_study_focus_channel"
        private const val NOTIFICATION_ID = 4301
        private const val REQUEST_POST_NOTIFICATIONS = 4302
    }
}
