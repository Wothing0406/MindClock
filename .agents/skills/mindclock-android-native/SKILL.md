---
name: mindclock-android-native
description: Implement or review MindClock Android platform code for local alarms, lock-screen presentation, permissions, app lifecycle, study focus, and camera/microphone boundaries. Use for Kotlin, AndroidManifest, Gradle, MethodChannel, and physical-device verification; not for ordinary Flutter widgets or backend work.
---

# MindClock Android native

Use for Flutter-to-Android system behavior. Read [docs/31](../../../docs/31-bao-thuc-thu-thach.md) for alarms, [docs/45](../../../docs/45-khong-gian-hoc-va-che-do-tap-trung.md) for study focus, [docs/09](../../../docs/09-ke-hoach-kiem-thu.md) for tests, and [AGENTS.md](../../../AGENTS.md). Before changing code/configuration, follow `tasks/README.md`.

## Workflow

1. Decide whether the behavior belongs in Dart UI, local Android code, or backend. Alarm scheduling, delivery, sound/vibration, and emergency stop need a local path independent of network, login, Gemini, and Flutter startup. Flutter passes user choices through a narrow, versioned bridge.
2. Check SDK target, manifest, permissions, OEM behavior, and official docs for the affected Android version. Show denied permissions and OS limits in Vietnamese; do not promise precise delivery when the OS cannot provide it.
3. For alarms, create a state matrix: app foreground/background/killed; screen on/locked; online/offline; exact alarm/full-screen/notification permissions allowed/denied; reboot/time-zone change; ordinary/challenge mode. `Dừng khẩn cấp` silences sound/vibration immediately on device. Challenge mode has no snooze; ordinary mode may have local snooze.
4. Make schedule/event/stop operations idempotent. Recalculate the next occurrence after relevant time or device changes. Never grant XP/streak from a receiver or client callback.
5. For study focus, lifecycle can show MindClock left foreground. It cannot establish which app was used or whether the learner was distracted. Keep interruption events local. Digital Wellbeing Focus mode is user-controlled; a personal app cannot impose kiosk lock task. Avoid Accessibility, overlay, device-admin, or VPN workarounds.
6. Camera/mic are opt-in with visible state and immediate stop. Do not start them silently from background or stream/store frames by default. Keep the text/no-camera path.
7. Verify OS behavior on a physical device as well as an emulator. Emulator/widget tests do not prove locked-screen sound/vibration, OEM battery behavior, or reboot delivery. Record device and Android version; mark any missing gate unverified.

## Delivery checks

- Task spec maps affected acceptance criteria to tests, including denied permission and offline behavior.
- Manifest declares only required permissions/components; exported status explicit. No API key in app.
- Native bridge returns typed outcomes and stable error codes.
- Emergency stop works locally when Flutter, backend, or Gemini fails.
- Physical-device evidence records screen/app/network state and outcome.

## Platform references

- [Schedule exact alarms](https://developer.android.com/develop/background-work/services/alarms/schedule)
- [Full-screen intents](https://developer.android.com/develop/ui/views/notifications/build-notification#urgent-message)
- [Foreground-service restrictions](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start)
- [Lock task mode](https://developer.android.com/work/dpc/dedicated-devices/lock-task-mode)
- [Digital Wellbeing Focus mode](https://support.google.com/android/answer/9346420)

Check current official guidance when coding; these links are starting points.
