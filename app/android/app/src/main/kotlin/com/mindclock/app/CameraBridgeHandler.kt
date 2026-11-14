package com.mindclock.app

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Cầu nối chụp ảnh bài làm qua `mindclock/camera_capture`.
 *
 * - Chỉ xin quyền `CAMERA` đúng lúc người dùng bấm chụp bài làm.
 * - Đọc ảnh vào bộ nhớ tạm trong RAM rồi gửi về Flutter xem lại trước upload;
 *   không ghi tệp ảnh vào thư viện ảnh (Gallery/MediaStore).
 */
class CameraBridgeHandler(private val activity: Activity) {
    private var pendingResult: MethodChannel.Result? = null

    fun handleCaptureRequest(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("CAPTURE_IN_PROGRESS", "Đang mở camera.", null)
            return
        }

        if (!activity.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)) {
            result.success(hashMapOf("status" to "unavailable"))
            return
        }

        pendingResult = result
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            activity.checkSelfPermission(Manifest.permission.CAMERA) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            activity.requestPermissions(
                arrayOf(Manifest.permission.CAMERA),
                REQUEST_CAMERA_PERMISSION,
            )
            return
        }

        launchCameraIntent()
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CAMERA_PERMISSION) return false
        val result = pendingResult ?: return true
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            pendingResult = null
            result.success(hashMapOf("status" to "permission_denied"))
            return true
        }
        launchCameraIntent()
        return true
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_IMAGE_CAPTURE) return false
        val result = pendingResult ?: return true
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(hashMapOf("status" to "cancelled"))
            return true
        }

        @Suppress("DEPRECATION")
        val bitmap = data.extras?.get("data") as? Bitmap
        if (bitmap == null) {
            result.success(hashMapOf("status" to "cancelled"))
            return true
        }

        val stream = ByteArrayOutputStream()
        try {
            bitmap.compress(Bitmap.CompressFormat.JPEG, 88, stream)
            val bytes = stream.toByteArray()
            if (bytes.size > MAX_BYTES) {
                result.success(hashMapOf("status" to "file_too_large"))
                return true
            }
            result.success(
                hashMapOf(
                    "status" to "captured",
                    "bytes" to bytes,
                    "mimeType" to "image/jpeg",
                    "fileName" to "handwritten_attempt.jpg",
                )
            )
        } finally {
            bitmap.recycle()
            stream.close()
        }
        return true
    }

    private fun launchCameraIntent() {
        val result = pendingResult ?: return
        val captureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        if (captureIntent.resolveActivity(activity.packageManager) == null) {
            pendingResult = null
            result.success(hashMapOf("status" to "unavailable"))
            return
        }
        try {
            activity.startActivityForResult(captureIntent, REQUEST_IMAGE_CAPTURE)
        } catch (_: Exception) {
            pendingResult = null
            result.success(hashMapOf("status" to "unavailable"))
        }
    }

    companion object {
        const val CHANNEL_NAME = "mindclock/camera_capture"
        private const val REQUEST_CAMERA_PERMISSION = 4201
        private const val REQUEST_IMAGE_CAPTURE = 4202
        private const val MAX_BYTES = 5 * 1024 * 1024
    }
}
