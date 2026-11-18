/// Kết quả chọn tệp đa phương tiện cục bộ (ảnh đại diện hoặc nhạc báo thức/nền học).
class MediaPickResult {
  const MediaPickResult({
    required this.picked,
    this.cancelled = false,
    this.localPath,
    this.displayName,
    this.errorMessageVi,
  });

  const MediaPickResult.cancelled()
      : picked = false,
        cancelled = true,
        localPath = null,
        displayName = null,
        errorMessageVi = null;

  const MediaPickResult.error(String messageVi)
      : picked = false,
        cancelled = false,
        localPath = null,
        displayName = null,
        errorMessageVi = messageVi;

  final bool picked;
  final bool cancelled;
  final String? localPath;
  final String? displayName;
  final String? errorMessageVi;
}

/// Cổng chọn tệp từ máy và nghe thử/phát nhạc cục bộ (`mindclock/media_picker`).
///
/// Toàn bộ tệp đã chọn được sao chép vào vùng lưu trữ riêng tư của app trên thiết bị,
/// không tự tải ảnh cá nhân hoặc file nhạc lên máy chủ.
abstract interface class MediaPickerGateway {
  static const String channelName = 'mindclock/media_picker';

  Future<MediaPickResult> pickAvatarImage();

  Future<MediaPickResult> pickAlarmAudio();

  Future<bool> previewAudio({
    required String soundOption,
    String? customSoundPath,
    bool loop = false,
  });

  Future<void> stopAudioPreview();
}

/// Gateway dự phòng khi chưa nối native Android (ví dụ môi trường widget test hoặc desktop).
class UnboundMediaPickerGateway implements MediaPickerGateway {
  const UnboundMediaPickerGateway();

  @override
  Future<MediaPickResult> pickAvatarImage() async {
    return const MediaPickResult.error(
      'Thiết bị hiện tại chưa hỗ trợ trình chọn ảnh Android.',
    );
  }

  @override
  Future<MediaPickResult> pickAlarmAudio() async {
    return const MediaPickResult.error(
      'Thiết bị hiện tại chưa hỗ trợ trình chọn nhạc Android.',
    );
  }

  @override
  Future<bool> previewAudio({
    required String soundOption,
    String? customSoundPath,
    bool loop = false,
  }) async {
    return false;
  }

  @override
  Future<void> stopAudioPreview() async {}
}
