import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../theme/mindclock_theme.dart';
import 'mindclock_icon.dart';

/// Danh mục avatar preset của MindClock (kết hợp minh họa gốc + icon vector dự phòng).
class MindClockAvatarCatalog {
  MindClockAvatarCatalog._();

  static const Map<String, String> assetPaths = <String, String>{
    'sunrise': 'assets/avatars/avatar_sunrise.png',
    'cu_meo': 'assets/avatars/avatar_cu_meo.png',
    'cu-meo': 'assets/avatars/avatar_cu_meo.png',
    'cao_giay': 'assets/avatars/avatar_cao_giay.png',
    'cao-giay': 'assets/avatars/avatar_cao_giay.png',
    'ca_chep': 'assets/avatars/avatar_ca_chep.png',
    'ca-chep': 'assets/avatars/avatar_ca_chep.png',
    'rua_xanh': 'assets/avatars/avatar_rua_xanh.png',
    'rua-xanh': 'assets/avatars/avatar_rua_xanh.png',
    'may_nho': 'assets/avatars/avatar_may_nho.png',
    'may-nho': 'assets/avatars/avatar_may_nho.png',
    'ha_nhan': 'assets/game/characters/ha-nhan/poses/idle.webp',
    'tuyet_dinh': 'assets/game/characters/tuyet-dinh/poses/idle.webp',
    'han_boi_phap': 'assets/game/characters/han-boi-phap/poses/idle.webp',
  };

  static const List<Map<String, dynamic>> presets = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'sunrise',
      'label': 'Bình minh',
      'icon': MindClockIconKind.sunrise,
      'assetPath': 'assets/avatars/avatar_sunrise.png',
    },
    <String, dynamic>{
      'id': 'cu_meo',
      'label': 'Cú mèo',
      'icon': MindClockIconKind.book,
      'assetPath': 'assets/avatars/avatar_cu_meo.png',
    },
    <String, dynamic>{
      'id': 'cao_giay',
      'label': 'Cáo giấy',
      'icon': MindClockIconKind.sunrise,
      'assetPath': 'assets/avatars/avatar_cao_giay.png',
    },
    <String, dynamic>{
      'id': 'ca_chep',
      'label': 'Cá chép',
      'icon': MindClockIconKind.book,
      'assetPath': 'assets/avatars/avatar_ca_chep.png',
    },
    <String, dynamic>{
      'id': 'rua_xanh',
      'label': 'Rùa xanh',
      'icon': MindClockIconKind.clock,
      'assetPath': 'assets/avatars/avatar_rua_xanh.png',
    },
    <String, dynamic>{
      'id': 'may_nho',
      'label': 'Mây nhỏ',
      'icon': MindClockIconKind.bell,
      'assetPath': 'assets/avatars/avatar_may_nho.png',
    },
    <String, dynamic>{
      'id': 'ha_nhan',
      'label': 'Hà Nhân',
      'icon': MindClockIconKind.user,
      'assetPath': 'assets/game/characters/ha-nhan/poses/idle.webp',
    },
    <String, dynamic>{
      'id': 'tuyet_dinh',
      'label': 'Tuyệt Đỉnh',
      'icon': MindClockIconKind.arena,
      'assetPath': 'assets/game/characters/tuyet-dinh/poses/idle.webp',
    },
    <String, dynamic>{
      'id': 'han_boi_phap',
      'label': 'Hàn Bối Pháp',
      'icon': MindClockIconKind.shield,
      'assetPath': 'assets/game/characters/han-boi-phap/poses/idle.webp',
    },
  ];

  static MindClockIconKind fallbackIconFor(String avatarId) {
    for (final Map<String, dynamic> item in presets) {
      if (item['id'] == avatarId) {
        return item['icon'] as MindClockIconKind;
      }
    }
    return MindClockIconKind.sunrise;
  }

  static String? assetPathFor(String avatarId) => assetPaths[avatarId];
}

/// Hiển thị ảnh đại diện của học sinh: ưu tiên ảnh tự tải lên từ máy -> ảnh minh họa gốc -> icon vector.
class MindClockAvatarView extends StatelessWidget {
  const MindClockAvatarView({
    super.key,
    required this.avatarId,
    this.customAvatarPath,
    this.size = 44,
    this.selected = false,
  });

  final String avatarId;
  final String? customAvatarPath;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final String? trimmedCustom = customAvatarPath?.trim();
    final File? customFile = (trimmedCustom != null && trimmedCustom.isNotEmpty)
        ? File(trimmedCustom)
        : null;
    final bool hasCustomFile = customFile != null && customFile.existsSync();
    final String? assetPath = MindClockAvatarCatalog.assetPathFor(avatarId);

    Widget content;
    if (hasCustomFile) {
      Uint8List? customBytes;
      try {
        customBytes = customFile.readAsBytesSync();
      } catch (_) {
        customBytes = null;
      }
      content = customBytes != null && customBytes.isNotEmpty
          ? Image.memory(
              customBytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackVector(mc),
            )
          : _fallbackVector(mc);
    } else if (assetPath != null) {
      content = Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackVector(mc),
      );
    } else {
      content = _fallbackVector(mc);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? mc.primarySoft : mc.paper,
        border: Border.all(
          color: selected ? mc.primary : mc.outline,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: content),
    );
  }

  Widget _fallbackVector(MindClockTheme mc) {
    return MindClockIcon(
      MindClockAvatarCatalog.fallbackIconFor(avatarId),
      color: selected ? mc.primary : mc.ink,
      size: size * 0.52,
    );
  }
}
