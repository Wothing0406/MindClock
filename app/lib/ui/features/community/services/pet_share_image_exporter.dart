import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

class PetShareImageExporter {
  const PetShareImageExporter();

  static const double _cardLogicalSize = 320;
  static const double _outputPixelSize = 1080;

  Future<File> export(RenderRepaintBoundary boundary) async {
    final ui.Image image = await boundary.toImage(
      pixelRatio: _outputPixelSize / _cardLogicalSize,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const FileSystemException('Không mã hóa được ảnh PNG.');
      }
      final Directory directory = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}mindclock_shares',
      );
      await directory.create(recursive: true);
      final File output = File(
        '${directory.path}${Platform.pathSeparator}'
        'pet_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await output.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return output;
    } finally {
      image.dispose();
    }
  }
}
