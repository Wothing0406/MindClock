package com.mindclock.app

import org.junit.Assert.assertEquals
import org.junit.Test

class AlarmSoundResolverTest {
    @Test
    fun resolvesBundledBermudaMp3WhenEnabledAndSelected() {
        assertEquals(
            AlarmRingService.AlarmSoundTarget.BUNDLED_BERMUDA,
            AlarmRingService.resolveSoundTarget(
                soundEnabled = true,
                soundOption = "bermuda_alarm",
            ),
        )
    }

    @Test
    fun resolvesSystemDefaultForBuiltInOptions() {
        assertEquals(
            AlarmRingService.AlarmSoundTarget.SYSTEM_DEFAULT,
            AlarmRingService.resolveSoundTarget(
                soundEnabled = true,
                soundOption = "gentle_dawn",
            ),
        )
        assertEquals(
            AlarmRingService.AlarmSoundTarget.SYSTEM_DEFAULT,
            AlarmRingService.resolveSoundTarget(
                soundEnabled = true,
                soundOption = "clear_bell",
            ),
        )
    }

    @Test
    fun resolvesSilentWhenDisabledOrVibrateOnly() {
        assertEquals(
            AlarmRingService.AlarmSoundTarget.SILENT,
            AlarmRingService.resolveSoundTarget(
                soundEnabled = false,
                soundOption = "bermuda_alarm",
            ),
        )
        assertEquals(
            AlarmRingService.AlarmSoundTarget.SILENT,
            AlarmRingService.resolveSoundTarget(
                soundEnabled = true,
                soundOption = "vibrate_only",
            ),
        )
    }
}
