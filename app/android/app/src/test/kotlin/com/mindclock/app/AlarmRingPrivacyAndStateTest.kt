package com.mindclock.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AlarmRingPrivacyAndStateTest {

    @Test
    fun lockScreenHidesSubjectAndCustomLabelByDefaultWhenLocked() {
        val payload = RingPayloadRecord(
            alarmId = "morning_math",
            formattedTime = "06:00",
            mode = NativeAlarmRecord.MODE_CHALLENGE,
            label = "Ôn phương trình bậc hai",
            subjectCode = "TOAN",
            triggeredAtEpochMillis = 1_700_000_000_000L,
            showLockScreenDetails = false,
        )

        val lockedLabel = LockScreenPrivacyFormatter.formatRingLabel(
            payload = payload,
            isKeyguardLocked = true,
        )
        val publicTitle = LockScreenPrivacyFormatter.formatPublicNotificationTitle(payload.formattedTime)
        val publicText = LockScreenPrivacyFormatter.formatPublicNotificationText()

        assertEquals("Mở để xem kế hoạch hôm nay", lockedLabel)
        assertFalse(lockedLabel.contains("TOAN"))
        assertFalse(lockedLabel.contains("Ôn phương trình"))
        assertEquals("Báo thức 06:00", publicTitle)
        assertEquals("Mở để xem kế hoạch hôm nay", publicText)
    }

    @Test
    fun unlockedScreenOrOptInShowsFullLabelAndSubject() {
        val payload = RingPayloadRecord(
            alarmId = "morning_phys",
            formattedTime = "05:45",
            mode = NativeAlarmRecord.MODE_CHALLENGE,
            label = "Ôn định luật Ôm",
            subjectCode = "VAT_LY",
            triggeredAtEpochMillis = 1_700_000_000_000L,
            showLockScreenDetails = false,
        )

        val unlockedLabel = LockScreenPrivacyFormatter.formatRingLabel(
            payload = payload,
            isKeyguardLocked = false,
        )
        assertEquals("Ôn định luật Ôm • VAT_LY", unlockedLabel)

        val optInPayload = payload.copy(showLockScreenDetails = true)
        val optInLockedLabel = LockScreenPrivacyFormatter.formatRingLabel(
            payload = optInPayload,
            isKeyguardLocked = true,
        )
        assertEquals("Ôn định luật Ôm • VAT_LY", optInLockedLabel)
    }

    @Test
    fun openingQuestionTransitionsPayloadToSoundStoppedReviewActive() {
        val initial = RingPayloadRecord(
            alarmId = "ch_01",
            formattedTime = "06:15",
            mode = NativeAlarmRecord.MODE_CHALLENGE,
            label = "Báo thức buổi sáng",
            subjectCode = "TOAN",
            triggeredAtEpochMillis = 1_700_000_000_000L,
        )
        assertEquals(RingPayloadRecord.STATE_RINGING, initial.ringState)

        val stopped = initial.markSoundStoppedForReview()
        assertEquals(RingPayloadRecord.STATE_SOUND_STOPPED_REVIEW_ACTIVE, stopped.ringState)

        val restored = RingPayloadRecord.fromJson(stopped.toJson())
        assertNotNull(restored)
        assertEquals(RingPayloadRecord.STATE_SOUND_STOPPED_REVIEW_ACTIVE, restored?.ringState)
        assertTrue(stopped.toBridgeMap()["ringState"] == RingPayloadRecord.STATE_SOUND_STOPPED_REVIEW_ACTIVE)
    }
}
