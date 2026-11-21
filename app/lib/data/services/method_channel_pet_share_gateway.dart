import 'package:flutter/services.dart';

import '../../domain/services/pet_share_gateway.dart';

class MethodChannelPetShareGateway implements PetShareGateway {
  const MethodChannelPetShareGateway({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'mindclock/pet_share';
  final MethodChannel _channel;

  @override
  Future<PetShareResult> sharePng({
    required String filePath,
    required String text,
  }) async {
    try {
      final Map<Object?, Object?>? raw = await _channel.invokeMapMethod(
        'sharePng',
        <String, Object>{'filePath': filePath, 'text': text},
      );
      return PetShareResult(
        status: raw?['status'] as String? ?? 'os_failed',
        messageVi: raw?['messageVi'] as String?,
      );
    } on PlatformException catch (error) {
      return PetShareResult(
        status: error.code,
        messageVi: error.message ?? 'Chưa mở được bảng chia sẻ.',
      );
    } on MissingPluginException {
      return const PetShareResult(
        status: 'unsupported',
        messageVi: 'Thiết bị này chưa hỗ trợ chia sẻ ảnh.',
      );
    }
  }
}
