package com.mindclock.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class AlarmOccurrenceCalculatorTest {

    private fun utcMillis(year: Int, monthZeroBased: Int, day: Int, hour: Int, minute: Int): Long {
        return Calendar.getInstance(TimeZone.getTimeZone("Asia/Ho_Chi_Minh")).apply {
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, monthZeroBased)
            set(Calendar.DAY_OF_MONTH, day)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    @Test
    fun singleShotMovesToNextDayWhenTimeAlreadyPassed() {
        val tz = TimeZone.getTimeZone("Asia/Ho_Chi_Minh")
        val now = utcMillis(2026, Calendar.NOVEMBER, 14, 7, 30)
        val alarm = NativeAlarmRecord(
            id = "primary",
            hour = 6,
            minute = 0,
            repeatWeekdays = emptyList(),
            enabled = true,
            soundEnabled = true,
            soundOption = "gentle_dawn",
            vibrateEnabled = true,
            mode = NativeAlarmRecord.MODE_CHALLENGE,
            subjectCode = "TOAN",
            label = "Dậy học Toán",
        )

        val next = AlarmOccurrenceCalculator.computeNextTriggerMillis(alarm, now, tz)
        val expected = utcMillis(2026, Calendar.NOVEMBER, 15, 6, 0)
        assertEquals(expected, next)
    }

    @Test
    fun repeatingAlarmSkipsWeekendAndFindsMonday() {
        val tz = TimeZone.getTimeZone("Asia/Ho_Chi_Minh")
        // 2026-11-14 là Thứ 7 (ISO weekday 6), lúc 08:00
        val now = utcMillis(2026, Calendar.NOVEMBER, 14, 8, 0)
        val alarm = NativeAlarmRecord(
            id = "weekday_alarm",
            hour = 6,
            minute = 15,
            repeatWeekdays = listOf(1, 2, 3, 4, 5),
            enabled = true,
            soundEnabled = true,
            soundOption = "clear_bell",
            vibrateEnabled = true,
            mode = NativeAlarmRecord.MODE_NORMAL,
            subjectCode = null,
            label = "Ngày học",
        )

        val next = AlarmOccurrenceCalculator.computeNextTriggerMillis(alarm, now, tz)
        val expectedMonday = utcMillis(2026, Calendar.NOVEMBER, 16, 6, 15)
        assertEquals(expectedMonday, next)
    }

    @Test
    fun snoozeAddsExactMinutesWithinSafeBounds() {
        val base = 1_700_000_000_000L
        assertEquals(base + 5 * 60_000L, AlarmOccurrenceCalculator.computeSnoozeTriggerMillis(base, 5))
        assertTrue(AlarmOccurrenceCalculator.computeSnoozeTriggerMillis(base, 0) > base)
    }
}
