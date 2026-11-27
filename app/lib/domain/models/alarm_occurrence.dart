/// Máy trạng thái duy nhất cho từng lần chuông báo thức gắn với `alarmId + occurrenceDate` (`T092`).
///
/// Chuỗi chuyển trạng thái chuẩn:
/// `scheduled → ringing → question_open → submitted → completed | skipped | dismissed`
enum AlarmOccurrenceState {
  scheduled('scheduled'),
  ringing('ringing'),
  questionOpen('question_open'),
  submitted('submitted'),
  completed('completed'),
  skipped('skipped'),
  dismissed('dismissed');

  const AlarmOccurrenceState(this.wireValue);
  final String wireValue;

  bool get isTerminal =>
      this == completed || this == skipped || this == dismissed;

  bool get isWaitingQuestion => this == questionOpen || this == submitted;

  static AlarmOccurrenceState fromWire(String? raw) {
    for (final AlarmOccurrenceState value in values) {
      if (value.wireValue == raw) return value;
    }
    return AlarmOccurrenceState.scheduled;
  }
}

class AlarmOccurrenceRecord {
  const AlarmOccurrenceRecord({
    required this.alarmId,
    required this.occurrenceDate,
    required this.state,
    required this.updatedAtEpochMs,
    this.subjectCode,
    this.sessionId,
    this.questionId,
    this.hasSyncError = false,
    this.triggeredAtEpochMs,
  });

  final String alarmId;
  final String occurrenceDate;
  final AlarmOccurrenceState state;
  final int updatedAtEpochMs;
  final String? subjectCode;
  final String? sessionId;
  final String? questionId;
  final bool hasSyncError;
  final int? triggeredAtEpochMs;

  String get occurrenceKey => '${alarmId}_$occurrenceDate';

  bool get isTerminal => state.isTerminal;

  bool get isWaitingQuestion => state.isWaitingQuestion;

  /// Nhãn trạng thái hiển thị rõ trên Dashboard Hôm nay.
  String get dashboardStatusLabelVi {
    if (hasSyncError && !state.isTerminal) {
      return 'Lỗi đồng bộ';
    }
    return switch (state) {
      AlarmOccurrenceState.completed =>
        hasSyncError ? 'Đã hoàn thành hôm nay · Chờ đồng bộ' : 'Đã hoàn thành hôm nay',
      AlarmOccurrenceState.skipped => 'Đã bỏ lượt',
      AlarmOccurrenceState.dismissed => 'Đã dừng chuông',
      AlarmOccurrenceState.ringing ||
      AlarmOccurrenceState.questionOpen ||
      AlarmOccurrenceState.submitted =>
        'Đang chờ làm câu',
      AlarmOccurrenceState.scheduled => 'Đang chờ',
    };
  }

  AlarmOccurrenceRecord copyWith({
    AlarmOccurrenceState? state,
    int? updatedAtEpochMs,
    String? subjectCode,
    String? sessionId,
    String? questionId,
    bool? hasSyncError,
    int? triggeredAtEpochMs,
  }) {
    return AlarmOccurrenceRecord(
      alarmId: alarmId,
      occurrenceDate: occurrenceDate,
      state: state ?? this.state,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
      subjectCode: subjectCode ?? this.subjectCode,
      sessionId: sessionId ?? this.sessionId,
      questionId: questionId ?? this.questionId,
      hasSyncError: hasSyncError ?? this.hasSyncError,
      triggeredAtEpochMs: triggeredAtEpochMs ?? this.triggeredAtEpochMs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'alarmId': alarmId,
        'occurrenceDate': occurrenceDate,
        'state': state.wireValue,
        'updatedAtEpochMs': updatedAtEpochMs,
        if (subjectCode != null) 'subjectCode': subjectCode,
        if (sessionId != null) 'sessionId': sessionId,
        if (questionId != null) 'questionId': questionId,
        'hasSyncError': hasSyncError,
        if (triggeredAtEpochMs != null) 'triggeredAtEpochMs': triggeredAtEpochMs,
      };

  factory AlarmOccurrenceRecord.fromJson(Map<String, dynamic> json) {
    return AlarmOccurrenceRecord(
      alarmId: (json['alarmId'] ?? '').toString(),
      occurrenceDate: (json['occurrenceDate'] ?? '').toString(),
      state: AlarmOccurrenceState.fromWire(json['state'] as String?),
      updatedAtEpochMs: (json['updatedAtEpochMs'] as num?)?.toInt() ?? 0,
      subjectCode: json['subjectCode'] as String?,
      sessionId: json['sessionId'] as String?,
      questionId: json['questionId'] as String?,
      hasSyncError: json['hasSyncError'] as bool? ?? false,
      triggeredAtEpochMs: (json['triggeredAtEpochMs'] as num?)?.toInt(),
    );
  }
}
