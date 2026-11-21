package com.mindclock.app

import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class PetShareBridgeHandler(private val activity: MainActivity) {
    companion object {
        const val CHANNEL_NAME = "mindclock/pet_share"
        private const val MAX_BYTES = 10L * 1024L * 1024L
        private const val TTL_MILLIS = 24L * 60L * 60L * 1000L
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "sharePng") {
            result.notImplemented()
            return
        }
        val path = call.argument<String>("filePath")?.trim().orEmpty()
        val text = call.argument<String>("text")?.take(240).orEmpty()
        val source = File(path)
        if (!source.isFile || source.extension.lowercase() != "png" || source.length() !in 1..MAX_BYTES) {
            result.success(response("invalid_file", "Ảnh chia sẻ không hợp lệ."))
            return
        }
        try {
            val shareDir = File(activity.cacheDir, "pet_shares").apply { mkdirs() }
            cleanup(shareDir)
            val shared = File(shareDir, "pet_${System.currentTimeMillis()}.png")
            source.inputStream().use { input ->
                shared.outputStream().use { output -> input.copyTo(output) }
            }
            val uri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.fileprovider",
                shared,
            )
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_STREAM, uri)
                if (text.isNotBlank()) putExtra(Intent.EXTRA_TEXT, text)
                clipData = ClipData.newRawUri("MindClock pet", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            if (send.resolveActivity(activity.packageManager) == null) {
                shared.delete()
                result.success(response("no_share_target", "Thiết bị chưa có ứng dụng nhận ảnh."))
                return
            }
            activity.startActivity(Intent.createChooser(send, "Chia sẻ thẻ MindClock"))
            result.success(response("opened", "Đã mở bảng chia sẻ."))
        } catch (_: Exception) {
            result.success(response("os_failed", "Chưa mở được bảng chia sẻ."))
        }
    }

    private fun cleanup(directory: File) {
        val cutoff = System.currentTimeMillis() - TTL_MILLIS
        directory.listFiles()?.forEach { file ->
            if (file.lastModified() < cutoff) file.delete()
        }
    }

    private fun response(status: String, messageVi: String) = hashMapOf(
        "status" to status,
        "messageVi" to messageVi,
    )
}
