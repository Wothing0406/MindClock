import 'package:flutter/services.dart';

import '../../domain/services/media_picker_gateway.dart';

/// Cầu nối MethodChannel cho việc chọn ảnh đại diện, file âm thanh cục bộ và nghe thử trên Android.
class MethodChannelMediaPickerGateway implements MediaPickerGateway {
  MethodChannelMediaPickerGateway({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(MediaPickerGateway.channelName);

  final MethodChannel _channel;

  @override
  Future<MediaPickResult> pickAvatarImage() =>
      _invokePicker('pickAvatarImage', fallbackErrorVi: 'Không mở được thư viện ảnh trên máy.');

  @override
  Future<MediaPickResult> pickAlarmAudio() =>
      _invokePicker('pickAlarmAudio', fallbackErrorVi: 'Không mở được tệp âm thanh trên máy.');

  Future<MediaPickResult> _invokePicker(
    String method, {
    required String fallbackErrorVi,
  }) async {
    try {
      final Map<dynamic, dynamic>? raw =
          await _channel.invokeMapMethod<dynamic, dynamic>(method);
      if (raw == null) {
        return MediaPickResult.error(fallbackErrorVi);
      }
      final bool cancelled = raw['cancelled'] as bool? ?? false;
      if (cancelled) {
        return const MediaPickResult.cancelled();
      }
      final bool picked = raw['picked'] as bool? ?? false;
      final String? path = raw['localPath'] as String?;
      if (!picked || path == null || path.trim().isEmpty) {
        return MediaPickResult.error(
          raw['errorMessageVi'] as String? ?? fallbackErrorVi,
        );
      }
      return MediaPickResult(
        picked: true,
        localPath: path.trim(),
        displayName: (raw['displayName'] as String?)?.trim(),
      );
    } on MissingPluginException {
      if (method == 'pickAvatarImage') {
        return const UnboundMediaPickerGateway().pickAvatarImage();
      }
      return const UnboundMediaPickerGateway().pickAlarmAudio();
    } on PlatformException catch (e) {
      return MediaPickResult.error(e.message ?? fallbackErrorVi);
    }
  }

  @override
  Future<bool> previewAudio({
    required String soundOption,
    String? customSoundPath,
    bool loop = false,
  }) async {
    try {
      final Map<dynamic, dynamic>? raw =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'previewAudio',
        <String, dynamic>{
          'soundOption': soundOption,
          'customSoundPath': customSoundPath,
          'loop': loop,
        },
      );
      return raw?['playing'] as bool? ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stopAudioPreview() async {
    try {
      await _channel.invokeMethod<void>('stopAudioPreview');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
