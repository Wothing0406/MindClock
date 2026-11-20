class XpHistoryEntry {
  const XpHistoryEntry(
      {required this.id,
      required this.delta,
      required this.reason,
      required this.createdAt});
  final String id;
  final int delta;
  final String reason;
  final DateTime createdAt;

  factory XpHistoryEntry.fromJson(Map<String, dynamic> json) => XpHistoryEntry(
        id: json['id'] as String,
        delta: (json['delta'] as num).toInt(),
        reason: json['reason'] as String,
        // SQLite test responses can omit offset; server timestamps are always UTC.
        createdAt: DateTime.parse((json['createdAt'] as String)
                    .contains(RegExp(r'Z|[+-]\d\d:\d\d$'))
                ? json['createdAt'] as String
                : '${json['createdAt']}Z')
            .toUtc(),
      );
}

class XpHistoryPage {
  const XpHistoryPage({required this.items, this.nextOffset});
  final List<XpHistoryEntry> items;
  final int? nextOffset;
  factory XpHistoryPage.fromJson(Map<String, dynamic> json) => XpHistoryPage(
        items: List.unmodifiable((json['items'] as List<dynamic>).map(
            (item) => XpHistoryEntry.fromJson(item as Map<String, dynamic>))),
        nextOffset: (json['nextOffset'] as num?)?.toInt(),
      );
}
