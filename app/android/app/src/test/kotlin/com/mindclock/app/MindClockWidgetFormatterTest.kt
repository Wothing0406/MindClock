package com.mindclock.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MindClockWidgetFormatterTest {
    @Test
    fun formatFromJsonHandlesEmptyOrInvalidPayloadSafely() {
        val empty = MindClockWidgetFormatter.formatFromJson(null)
        assertEquals("0 việc", empty.progressBadge)
        assertTrue(empty.lines.isNotEmpty())

        val invalid = MindClockWidgetFormatter.formatFromJson("{broken json")
        assertEquals("MINDCLOCK · HÔM NAY", invalid.headerLabel)
        assertEquals("0 việc", invalid.progressBadge)
    }

    @Test
    fun formatFromJsonFormatsHeaderProgressAndCapsAtFourItems() {
        val payload = """
            {
              "dateIso": "2026-11-19",
              "weekdayShortVi": "TH 5",
              "dayNumberLabel": "19",
              "monthLabelVi": "19/11",
              "doneCount": 1,
              "totalCount": 5,
              "nextAlarmLabelVi": "Chuông 05:55",
              "items": [
                {"timeLabel": "07:00", "title": "Toán", "categoryLabelVi": "Chính khóa", "isDone": true},
                {"timeLabel": "14:00", "title": "Vật lí nâng cao chương dao động điều hòa", "categoryLabelVi": "Học thêm", "isDone": false},
                {"timeLabel": "17:00", "title": "Ngữ văn", "categoryLabelVi": "Tự học / Bài tập", "isDone": false},
                {"timeLabel": "19:30", "title": "Tiếng Anh", "categoryLabelVi": "Học thêm", "isDone": false},
                {"timeLabel": "21:00", "title": "Ôn tập Hóa", "categoryLabelVi": "Tự học / Bài tập", "isDone": false}
              ]
            }
        """.trimIndent()

        val model = MindClockWidgetFormatter.formatFromJson(payload)
        assertEquals("TH 5 · 19/11", model.headerLabel)
        assertEquals("Ngày 19 · Lịch hôm nay", model.dayTitle)
        assertEquals("1/5 xong", model.progressBadge)
        assertEquals("Chuông 05:55", model.alarmFooter)
        assertEquals(MindClockWidgetFormatter.MAX_ITEMS, model.lines.size)
        assertTrue(model.lines[0].startsWith("[Done] 07:00 Toán"))
        assertTrue(model.lines[1].contains("(Thêm)"))
        assertTrue(model.lines[1].contains("…"))
    }
}
