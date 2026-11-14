import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../domain/services/camera_capture_gateway.dart';

/// Kết nối cầu nối Android native `mindclock/camera_capture`.
///
/// Chỉ xin quyền camera đúng lúc người dùng bấm chụp bài làm; trả bytes trong RAM,
/// không lưu ảnh vào Gallery và không tự xếp hàng tải ngầm.
class MethodChannelCameraCaptureGateway implements CameraCaptureGateway {
  const MethodChannelCameraCaptureGateway({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'mindclock/camera_capture';
  final MethodChannel _channel;

  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    try {
      final Map<dynamic, dynamic>? response =
          await _channel.invokeMapMethod<dynamic, dynamic>(
        'captureHandwrittenPhoto',
      );
      if (response == null) {
        return const CameraCaptureOutcome(
          status: CameraCaptureStatus.cancelled,
          messageVi: 'Đã hủy chụp ảnh bài làm.',
        );
      }

      final String statusWire = response['status'] as String? ?? 'cancelled';
      switch (statusWire) {
        case 'permission_denied':
          return const CameraCaptureOutcome(
            status: CameraCaptureStatus.permissionDenied,
            messageVi:
                'Bạn đã từ chối quyền Camera. Bạn vẫn có thể nhập đáp án và cách làm bằng chữ.',
          );
        case 'unavailable':
          return const CameraCaptureOutcome(
            status: CameraCaptureStatus.unavailable,
            messageVi:
                'Thiết bị không có camera khả dụng. Hãy nhập đáp án và cách làm bằng chữ.',
          );
        case 'cancelled':
          return const CameraCaptureOutcome(
            status: CameraCaptureStatus.cancelled,
            messageVi: 'Đã hủy chụp ảnh.',
          );
        case 'captured':
          final Object? rawBytes = response['bytes'];
          if (rawBytes is! Uint8List || rawBytes.isEmpty) {
            return const CameraCaptureOutcome(
              status: CameraCaptureStatus.cancelled,
              messageVi: 'Không đọc được dữ liệu ảnh vừa chụp.',
            );
          }
          if (rawBytes.lengthInBytes > CameraCaptureGateway.maxImageBytes) {
            return const CameraCaptureOutcome(
              status: CameraCaptureStatus.fileTooLarge,
              messageVi:
                  'Ảnh vừa chụp vượt quá 5 MB. Vui lòng chụp lại hoặc chuyển sang nhập chữ.',
            );
          }
          final String mime =
              (response['mimeType'] as String? ?? 'image/jpeg').toLowerCase();
          if (!CameraCaptureGateway.allowedMimeTypes.contains(mime)) {
            return const CameraCaptureOutcome(
              status: CameraCaptureStatus.unsupportedMime,
              messageVi:
                  'Định dạng ảnh chưa được hỗ trợ. Vui lòng nhập đáp án bằng chữ.',
            );
          }
          return CameraCaptureOutcome(
            status: CameraCaptureStatus.captured,
            bytes: rawBytes,
            mimeType: mime,
            fileName: response['fileName'] as String? ?? 'handwritten_attempt.jpg',
          );
        default:
          return const CameraCaptureOutcome(
            status: CameraCaptureStatus.cancelled,
          );
      }
    } on MissingPluginException {
      return const CameraCaptureOutcome(
        status: CameraCaptureStatus.unavailable,
        messageVi:
            'Kênh camera chưa sẵn sàng trên nền tảng này. Bạn hãy nhập đáp án và cách làm bằng chữ.',
      );
    } on PlatformException catch (e) {
      return CameraCaptureOutcome(
        status: CameraCaptureStatus.unavailable,
        messageVi: e.message ??
            'Không thể mở camera lúc này. Bạn vẫn có thể nhập bài bằng chữ.',
      );
    }
  }
}
