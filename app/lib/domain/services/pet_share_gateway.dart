class PetShareResult {
  const PetShareResult({required this.status, this.messageVi});
  final String status;
  final String? messageVi;
  bool get opened => status == 'opened';
}

abstract interface class PetShareGateway {
  Future<PetShareResult> sharePng({
    required String filePath,
    required String text,
  });
}
