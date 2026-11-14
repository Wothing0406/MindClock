import 'dart:typed_data';

enum CameraCaptureStatus {
  captured,
  cancelled,
  permissionDenied,
  unavailable,
  fileTooLarge,
  unsupportedMime,
}

class CameraCaptureOutcome {
  const CameraCaptureOutcome({
    required this.status,
    this.bytes,
    this.mimeType,
    this.fileName,
    this.messageVi,
  });

  final CameraCaptureStatus status;
  final Uint8List? bytes;
  final String? mimeType;
  final String? fileName;
  final String? messageVi;
}

/// Giao diện chụp ảnh bài làm trong bộ nhớ tạm (không lưu Gallery mặc định).
abstract interface class CameraCaptureGateway {
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const Set<String> allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  /// Chỉ xin quyền camera đúng lúc người dùng bấm chụp bài làm.
  Future<CameraCaptureOutcome> captureHandwrittenPhoto();
}
