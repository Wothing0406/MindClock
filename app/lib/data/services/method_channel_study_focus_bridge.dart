import 'package:flutter/services.dart';

import '../../domain/services/study_focus_bridge.dart';

class MethodChannelStudyFocusBridge implements StudyFocusBridge {
  const MethodChannelStudyFocusBridge({
    MethodChannel? channel,
  }) : _channel = channel ?? defaultChannel;

  static const int bridgeVersion = 1;
  static const String channelName = 'mindclock/study_focus';
  static const MethodChannel defaultChannel = MethodChannel(channelName);

  final MethodChannel _channel;

  @override
  bool get isPlatformConnected => true;

  @override
  Future<DigitalWellbeingOpenResult> openDigitalWellbeingFocusSettings() async {
    try {
      final Map<dynamic, dynamic>? raw =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'openDigitalWellbeingFocusSettings',
        const <String, dynamic>{'bridgeVersion': bridgeVersion},
      );
      if (raw == null) {
        return const DigitalWellbeingOpenResult(
          opened: false,
          target: DigitalWellbeingTarget.unavailable,
          messageVi:
              'Không mở được cài đặt Digital Wellbeing trên thiết bị này. Bạn có thể tự bật Focus mode trong Cài đặt Android nếu máy hỗ trợ.',
        );
      }

      final bool opened = raw['opened'] as bool? ?? false;
      final String targetStr = raw['target'] as String? ?? 'unavailable';
      final DigitalWellbeingTarget target;
      switch (targetStr) {
        case 'digital_wellbeing':
          target = DigitalWellbeingTarget.digitalWellbeing;
        case 'system_settings':
          target = DigitalWellbeingTarget.systemSettings;
        default:
          target = DigitalWellbeingTarget.unavailable;
      }
      final String messageVi = raw['messageVi'] as String? ??
          'MindClock không tự khóa app khác; bạn tự bật Focus mode trong Cài đặt Android.';
      return DigitalWellbeingOpenResult(
        opened: opened,
        target: target,
        messageVi: messageVi,
      );
    } on MissingPluginException {
      return const DigitalWellbeingOpenResult(
        opened: false,
        target: DigitalWellbeingTarget.unavailable,
        messageVi:
            'Thiết bị hiện chưa có cầu nối Digital Wellbeing Focus mode. MindClock không khóa app khác.',
      );
    } on PlatformException catch (error) {
      return DigitalWellbeingOpenResult(
        opened: false,
        target: DigitalWellbeingTarget.unavailable,
        messageVi: error.message ??
            'Không thể mở Digital Wellbeing Focus mode trên thiết bị này.',
      );
    }
  }

  @override
  Future<StudyNotificationPermission> getNotificationPermissionStatus() async {
    try {
      final Map<dynamic, dynamic>? raw =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'getNotificationPermissionStatus',
        const <String, dynamic>{'bridgeVersion': bridgeVersion},
      );
      return _parsePermission(raw?['status'] as String?);
    } on PlatformException {
      return StudyNotificationPermission.unknown;
    } on MissingPluginException {
      return StudyNotificationPermission.unknown;
    }
  }

  @override
  Future<StudyNotificationPermission> requestNotificationPermission() async {
    try {
      final Map<dynamic, dynamic>? raw =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'requestNotificationPermission',
        const <String, dynamic>{'bridgeVersion': bridgeVersion},
      );
      return _parsePermission(raw?['status'] as String?);
    } on PlatformException {
      return StudyNotificationPermission.denied;
    } on MissingPluginException {
      return StudyNotificationPermission.denied;
    }
  }

  @override
  Future<void> showSingleStudyReminder({
    required String sessionId,
    required String titleVi,
    required String bodyVi,
  }) async {
    try {
      await _channel.invokeMethod<dynamic>(
        'showSingleStudyReminder',
        <String, dynamic>{
          'bridgeVersion': bridgeVersion,
          'sessionId': sessionId,
          'titleVi': titleVi,
          'bodyVi': bodyVi,
        },
      );
    } on PlatformException {
      // Nhắc ngoài app là tùy chọn; không làm gián đoạn timer hoặc báo thức.
    } on MissingPluginException {
      // Bỏ qua an toàn khi chạy ngoài Android.
    }
  }

  @override
  Future<void> cancelStudyReminder() async {
    try {
      await _channel.invokeMethod<dynamic>(
        'cancelStudyReminder',
        const <String, dynamic>{'bridgeVersion': bridgeVersion},
      );
    } on PlatformException {
      // Bỏ qua an toàn.
    } on MissingPluginException {
      // Bỏ qua an toàn.
    }
  }

  @override
  Future<void> playSessionEndCue() async {
    try {
      await _channel.invokeMethod<dynamic>(
        'playSessionEndCue',
        const <String, dynamic>{'bridgeVersion': bridgeVersion},
      );
    } on PlatformException {
      // Âm cuối phiên lỗi không ảnh hưởng lưu phiên.
    } on MissingPluginException {
      // Bỏ qua an toàn.
    }
  }

  StudyNotificationPermission _parsePermission(String? status) {
    switch (status) {
      case 'granted':
        return StudyNotificationPermission.granted;
      case 'denied':
        return StudyNotificationPermission.denied;
      default:
        return StudyNotificationPermission.unknown;
    }
  }
}
