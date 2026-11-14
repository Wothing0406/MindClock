package com.mindclock.app

import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

/**
 * Màn hình chuông reo nền đêm native hiển thị ngay trên màn hình khóa.
 *
 * Đặc tả bắt buộc:
 * - Không phụ thuộc FlutterEngine/Hilt/Compose.
 * - `Dừng khẩn cấp` luôn hiện và dừng ngay `AlarmRingService`.
 * - `Hoãn 5 phút` CHỈ hiện ở `normal` mode, ẩn hoàn toàn ở `challenge` mode.
 */
class AlarmRingActivity : Activity() {
    private lateinit var payload: RingPayloadRecord
    private var receiverRegistered = false

    private val ringStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == AlarmRingService.ACTION_RING_STATE_CHANGED) {
                val active = NativeAlarmStore(this@AlarmRingActivity).getActiveRingPayload()
                if (active == null) {
                    finish()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyLockScreenFlags()
        setContentView(R.layout.activity_alarm_ring)

        payload = resolvePayload(intent)
        bindViews()
        registerRingReceiver()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        if (intent != null) {
            setIntent(intent)
            payload = resolvePayload(intent)
            bindViews()
        }
    }

    override fun onDestroy() {
        if (receiverRegistered) {
            try {
                unregisterReceiver(ringStateReceiver)
            } catch (_: Exception) {
                // Bỏ qua nếu đã hủy đăng ký
            }
            receiverRegistered = false
        }
        super.onDestroy()
    }

    private fun applyLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    private fun resolvePayload(sourceIntent: Intent?): RingPayloadRecord {
        val store = NativeAlarmStore(this)
        val storedActive = store.getActiveRingPayload()
        val alarmId = sourceIntent?.getStringExtra(AlarmRingService.EXTRA_ALARM_ID)
            ?: storedActive?.alarmId
            ?: "primary_morning"
        val formattedTime = sourceIntent?.getStringExtra(AlarmRingService.EXTRA_FORMATTED_TIME)
            ?: storedActive?.formattedTime
            ?: "06:00"
        val mode = sourceIntent?.getStringExtra(AlarmRingService.EXTRA_MODE)
            ?: storedActive?.mode
            ?: NativeAlarmRecord.MODE_NORMAL
        val label = sourceIntent?.getStringExtra(AlarmRingService.EXTRA_LABEL)
            ?: storedActive?.label
            ?: "Báo thức buổi sáng"
        val subjectCode = sourceIntent?.getStringExtra(AlarmRingService.EXTRA_SUBJECT_CODE)
            ?: storedActive?.subjectCode

        return RingPayloadRecord(
            alarmId = alarmId,
            formattedTime = formattedTime,
            mode = mode,
            label = label,
            subjectCode = subjectCode,
            triggeredAtEpochMillis = storedActive?.triggeredAtEpochMillis ?: System.currentTimeMillis(),
        )
    }

    private fun bindViews() {
        val txtModeBadge = findViewById<TextView>(R.id.txtModeBadge)
        val txtAlarmTime = findViewById<TextView>(R.id.txtAlarmTime)
        val txtAlarmLabel = findViewById<TextView>(R.id.txtAlarmLabel)
        val txtAlarmHint = findViewById<TextView>(R.id.txtAlarmHint)
        val btnOpenQuestion = findViewById<Button>(R.id.btnOpenQuestion)
        val btnSnooze5Min = findViewById<Button>(R.id.btnSnooze5Min)
        val btnEmergencyStop = findViewById<Button>(R.id.btnEmergencyStop)

        val isChallenge = payload.mode == NativeAlarmRecord.MODE_CHALLENGE
        txtModeBadge.text = if (isChallenge) "Chế độ thử thách" else "Chế độ thường"
        txtAlarmTime.text = payload.formattedTime
        txtAlarmLabel.text = if (!payload.subjectCode.isNullOrBlank()) {
            "${payload.label} • ${payload.subjectCode}"
        } else {
            payload.label
        }
        txtAlarmHint.text = getString(
            if (isChallenge) R.string.alarm_challenge_note else R.string.alarm_normal_note
        )

        btnSnooze5Min.visibility = if (isChallenge) View.GONE else View.VISIBLE
        btnSnooze5Min.isEnabled = !isChallenge

        btnOpenQuestion.setOnClickListener {
            openQuestionInMainApp()
        }

        btnSnooze5Min.setOnClickListener {
            if (!isChallenge) {
                triggerLocalSnooze()
            }
        }

        btnEmergencyStop.setOnClickListener {
            triggerNativeEmergencyStop()
        }
    }

    private fun openQuestionInMainApp() {
        val store = NativeAlarmStore(this)
        store.setPendingRingLaunch(payload)
        store.recordLocalAlarmEvent(
            alarmId = payload.alarmId,
            eventType = "open_question",
            timestampMillis = System.currentTimeMillis(),
        )

        // Hạ âm lượng chuông khi chuyển sang màn câu hỏi (vẫn giữ nút Dừng khẩn cấp)
        val lowerVolumeIntent = Intent(this, AlarmRingService::class.java).apply {
            action = AlarmRingService.ACTION_LOWER_VOLUME
        }
        startService(lowerVolumeIntent)

        val launchMain = {
            val mainIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_LAUNCHED_FROM_ALARM, true)
                putExtra(AlarmRingService.EXTRA_ALARM_ID, payload.alarmId)
            }
            startActivity(mainIntent)
            finish()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            if (keyguard != null && keyguard.isKeyguardLocked) {
                keyguard.requestDismissKeyguard(
                    this,
                    object : KeyguardManager.KeyguardDismissCallback() {
                        override fun onDismissSucceeded() {
                            launchMain()
                        }

                        override fun onDismissCancelled() {
                            launchMain()
                        }

                        override fun onDismissError() {
                            launchMain()
                        }
                    },
                )
                return
            }
        }

        launchMain()
    }

    private fun triggerLocalSnooze() {
        val store = NativeAlarmStore(this)
        val record = store.getAlarm(payload.alarmId) ?: NativeAlarmRecord(
            id = payload.alarmId,
            hour = payload.formattedTime.substringBefore(":").toIntOrNull() ?: 6,
            minute = payload.formattedTime.substringAfter(":").toIntOrNull() ?: 0,
            repeatWeekdays = emptyList(),
            enabled = true,
            soundEnabled = true,
            soundOption = "gentle_dawn",
            vibrateEnabled = true,
            mode = NativeAlarmRecord.MODE_NORMAL,
            subjectCode = payload.subjectCode,
            label = payload.label,
        )

        AlarmSchedulerImpl(this).scheduleSnoozeRecord(record, SNOOZE_MINUTES)
        store.recordLocalAlarmEvent(
            alarmId = payload.alarmId,
            eventType = "snooze_5m",
            timestampMillis = System.currentTimeMillis(),
        )
        triggerNativeEmergencyStop()
    }

    private fun triggerNativeEmergencyStop() {
        val stopIntent = Intent(this, AlarmRingService::class.java).apply {
            action = AlarmRingService.ACTION_EMERGENCY_STOP
            putExtra(AlarmRingService.EXTRA_ALARM_ID, payload.alarmId)
        }
        startService(stopIntent)
        finish()
    }

    private fun registerRingReceiver() {
        val filter = IntentFilter(AlarmRingService.ACTION_RING_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(ringStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(ringStateReceiver, filter)
        }
        receiverRegistered = true
    }

    companion object {
        const val SNOOZE_MINUTES = 5
        const val EXTRA_LAUNCHED_FROM_ALARM = "extra_launched_from_alarm"
    }
}
