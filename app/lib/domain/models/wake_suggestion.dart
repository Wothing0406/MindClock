/// Đầu vào tính gợi ý giờ dậy cục bộ theo `docs/32 §5`.
class WakeSuggestionInput {
  const WakeSuggestionInput({
    required this.classStartMinutes,
    required this.commuteMinutes,
    required this.prepMinutes,
    required this.bufferMinutes,
    this.subjectCode,
  });

  final int classStartMinutes;
  final int commuteMinutes;
  final int prepMinutes;
  final int bufferMinutes;
  final String? subjectCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'classStartMinutes': classStartMinutes,
        'commuteMinutes': commuteMinutes,
        'prepMinutes': prepMinutes,
        'bufferMinutes': bufferMinutes,
        'subjectCode': subjectCode,
      };

  factory WakeSuggestionInput.fromJson(Map<String, dynamic> json) {
    return WakeSuggestionInput(
      classStartMinutes: (json['classStartMinutes'] as num?)?.toInt() ?? 420,
      commuteMinutes: (json['commuteMinutes'] as num?)?.toInt() ?? 25,
      prepMinutes: (json['prepMinutes'] as num?)?.toInt() ?? 30,
      bufferMinutes: (json['bufferMinutes'] as num?)?.toInt() ?? 10,
      subjectCode: json['subjectCode'] as String?,
    );
  }
}

/// Kết quả tính gợi ý giờ dậy (chỉ preview, KHÔNG tự sửa báo thức đã đặt).
class WakeSuggestionResult {
  const WakeSuggestionResult({
    required this.hour,
    required this.minute,
    required this.crossedPreviousDay,
    required this.formulaTextVi,
    required this.explanationVi,
    required this.isValidInput,
    this.validationErrorVi,
  });

  final int hour;
  final int minute;
  final bool crossedPreviousDay;
  final String formulaTextVi;
  final String explanationVi;
  final bool isValidInput;
  final String? validationErrorVi;

  String get formattedWakeTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class WakeSuggestionCalculator {
  const WakeSuggestionCalculator._();

  static const int minutesPerDay = 1440;

  static String formatMinutes(int totalMinutes) {
    final int normalized =
        ((totalMinutes % minutesPerDay) + minutesPerDay) % minutesPerDay;
    final int h = normalized ~/ 60;
    final int m = normalized % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Tính `giờ dậy muộn nhất = giờ bắt đầu − đi đường − chuẩn bị − đệm` (`docs/32 §5`).
  static WakeSuggestionResult calculate(WakeSuggestionInput input) {
    if (input.commuteMinutes < 0 ||
        input.prepMinutes < 0 ||
        input.bufferMinutes < 0) {
      return const WakeSuggestionResult(
        hour: 6,
        minute: 0,
        crossedPreviousDay: false,
        formulaTextVi: '',
        explanationVi: '',
        isValidInput: false,
        validationErrorVi: 'Số phút đi đường, chuẩn bị và đệm không được âm.',
      );
    }

    final int totalLead =
        input.commuteMinutes + input.prepMinutes + input.bufferMinutes;
    if (totalLead >= minutesPerDay) {
      return const WakeSuggestionResult(
        hour: 6,
        minute: 0,
        crossedPreviousDay: false,
        formulaTextVi: '',
        explanationVi: '',
        isValidInput: false,
        validationErrorVi:
            'Tổng thời gian chuẩn bị và đi đường phải nhỏ hơn 24 giờ.',
      );
    }

    final int rawDiff = input.classStartMinutes - totalLead;
    final bool crossed = rawDiff < 0;
    final int normalized =
        ((rawDiff % minutesPerDay) + minutesPerDay) % minutesPerDay;
    final int wakeHour = normalized ~/ 60;
    final int wakeMinute = normalized % 60;
    final String classTimeText = formatMinutes(input.classStartMinutes);
    final String wakeTimeText = formatMinutes(normalized);
    final String daySuffix = crossed ? ' (hôm trước)' : '';

    final String formula =
        '$classTimeText − ${input.commuteMinutes}p đi đường '
        '− ${input.prepMinutes}p chuẩn bị − ${input.bufferMinutes}p đệm '
        '= $wakeTimeText$daySuffix';

    final String explanation =
        'Đề xuất $wakeTimeText$daySuffix · kịp tiết $classTimeText theo thời gian bạn nhập. '
        'Đây chỉ là tính toán theo lịch trên máy, không phải khuyến nghị y khoa.';

    return WakeSuggestionResult(
      hour: wakeHour,
      minute: wakeMinute,
      crossedPreviousDay: crossed,
      formulaTextVi: formula,
      explanationVi: explanation,
      isValidInput: true,
    );
  }
}
