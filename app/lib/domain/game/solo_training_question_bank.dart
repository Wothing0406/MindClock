import '../services/answer_normalizer.dart';
import 'solo_combat_engine.dart';

/// Một câu hỏi thuộc bộ ngân hàng đã duyệt (cache cục bộ cho G1 Luyện đơn offline).
///
/// Đáp án (`acceptedAnswers`) và `gradingRubricStepsVi` KHÔNG hiển thị trước khi nộp.
class SoloApprovedQuestion {
  const SoloApprovedQuestion({
    required this.id,
    required this.revision,
    required this.rubricRevision,
    required this.subjectCode,
    required this.gradeBand,
    required this.curriculum,
    required this.approvedBy,
    required this.prompt,
    required this.reasoningPromptVi,
    required this.acceptedAnswers,
    required this.reasoningKeywords,
    required this.oneStepHintVi,
    required this.gradingRubricStepsVi,
    required this.explanationAfterRevealVi,
  });

  final String id;
  final int revision;
  final int rubricRevision;
  final String subjectCode;
  final String gradeBand;
  final String curriculum;
  final String approvedBy;
  final String prompt;
  final String reasoningPromptVi;
  final List<String> acceptedAnswers;
  final List<String> reasoningKeywords;
  final String oneStepHintVi;
  final List<String> gradingRubricStepsVi;
  final String explanationAfterRevealVi;
}

/// Kết quả chấm bài 3 trạng thái trong Luyện đơn cục bộ (không chấm RP/XP online).
class SoloGradingFeedback {
  const SoloGradingFeedback({
    required this.status,
    required this.feedbackVi,
    this.oneStepHintVi,
    required this.canRetry,
    required this.canSwapQuestion,
    required this.canRevealRubric,
  });

  final SoloGradeStatus status;
  final String feedbackVi;
  final String? oneStepHintVi;
  final bool canRetry;
  final bool canSwapQuestion;
  final bool canRevealRubric;
}

/// Phương án thẻ bài nhanh 1 chạm cho Đấu trường (`T087`).
class SoloQuickChoice {
  const SoloQuickChoice({
    required this.label,
    required this.answerValue,
    required this.reasoningStep,
  });

  final String label;
  final String answerValue;
  final String reasoningStep;
}

/// Bộ câu hỏi đã duyệt cache sẵn trên máy cho G1 Luyện đơn (offline-safe).
///
/// Các môn chưa có bộ câu duyệt sẽ trả về danh sách rỗng để UI thông báo trung thực.
class SoloTrainingQuestionBank {
  const SoloTrainingQuestionBank._();

  /// Sinh 4 thẻ đáp án nhanh từ câu hỏi hiện tại (gồm 1 thẻ đúng + bước chuẩn và 3 thẻ nhiễu hợp lý).
  static List<SoloQuickChoice> quickChoicesFor(SoloApprovedQuestion q) {
    final String correctAns = q.acceptedAnswers.first;
    final String correctReason = q.gradingRubricStepsVi.isNotEmpty
        ? q.gradingRubricStepsVi.first
        : q.oneStepHintVi;

    final List<String> distractors = <String>[];
    final RegExpMatch? numMatch =
        RegExp(r'^(-?\d+(?:[.,]\d+)?)(.*)$').firstMatch(correctAns.trim());
    if (numMatch != null) {
      final double? parsed =
          double.tryParse((numMatch.group(1) ?? '').replaceAll(',', '.'));
      final String unit = (numMatch.group(2) ?? '').trim();
      final String suffix = unit.isEmpty ? '' : ' $unit';
      if (parsed != null) {
        final bool isInt = parsed == parsed.roundToDouble();
        for (final num d in const <num>[2, -1, 4, -3, 6]) {
          final double v = parsed + d;
          final String formatted =
              isInt ? '${v.round()}$suffix' : '${v.toStringAsFixed(1)}$suffix';
          if (!q.acceptedAnswers.any(
                (String a) => a.toLowerCase() == formatted.toLowerCase(),
              ) &&
              !distractors.contains(formatted)) {
            distractors.add(formatted);
          }
          if (distractors.length == 3) break;
        }
      }
    }
    const List<String> fallbackPool = <String>[
      'Giá trị đối dấu',
      'Thiếu điều kiện',
      'Sai đơn vị chuẩn',
      'Chưa rút gọn',
    ];
    for (final String f in fallbackPool) {
      if (distractors.length >= 3) break;
      if (!distractors.contains(f) && f != correctAns) {
        distractors.add(f);
      }
    }

    final List<SoloQuickChoice> items = <SoloQuickChoice>[
      SoloQuickChoice(
        label: correctAns,
        answerValue: correctAns,
        reasoningStep: correctReason,
      ),
      for (final String d in distractors.take(3))
        SoloQuickChoice(
          label: d,
          answerValue: d,
          reasoningStep: 'Bước 1: Thử chọn phương án $d = 0.',
        ),
    ];

    final int shift = q.id.hashCode.abs() % items.length;
    return <SoloQuickChoice>[
      for (int i = 0; i < items.length; i++) items[(i + shift) % items.length],
    ];
  }

  static const List<SoloApprovedQuestion> allCachedApprovedQuestions =
      <SoloApprovedQuestion>[
    // --- TOÁN (math) ---
    SoloApprovedQuestion(
      id: 'g1-math-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'math',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Giải phương trình bậc nhất: 2(x - 3) = 10.',
      reasoningPromptVi: 'Viết ít nhất 1 bước biến đổi tìm x.',
      acceptedAnswers: <String>['8', 'x=8', 'x = 8'],
      reasoningKeywords: <String>['chia', 'chuyển', 'x - 3', 'x-3', '2x', '= 5', '=5', '= 16', '=16'],
      oneStepHintVi: 'Thử chia cả hai vế cho 2 trước khi chuyển vế số 3.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Chia hai vế cho 2 được x - 3 = 5 (hoặc nhân phá ngoặc 2x - 6 = 10).',
        'Bước 2: Chuyển vế thu được x = 8.',
      ],
      explanationAfterRevealVi: '2(x - 3) = 10 => x - 3 = 5 => x = 8.',
    ),
    SoloApprovedQuestion(
      id: 'g1-math-002',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'math',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Tính giá trị của biểu thức A = 3/4 + 0,25.',
      reasoningPromptVi: 'Trình bày 1 bước đổi phân số hoặc số thập phân cùng dạng.',
      acceptedAnswers: <String>['1', '1.0', '4/4', 'a=1', 'a = 1'],
      reasoningKeywords: <String>['0,75', '0.75', '1/4', '3/4', 'quy đồng', 'cộng', '+'],
      oneStepHintVi: 'Đổi 3/4 = 0,75 (hoặc 0,25 = 1/4) rồi cộng hai số cùng dạng.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Đổi 3/4 = 0,75 (hoặc 0,25 = 1/4).',
        'Bước 2: Cộng 0,75 + 0,25 = 1.',
      ],
      explanationAfterRevealVi: '3/4 + 0,25 = 0,75 + 0,25 = 1.',
    ),
    SoloApprovedQuestion(
      id: 'g1-math-003',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'math',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Tìm x biết phương trình: x^2 - 9 = 0 và x > 0.',
      reasoningPromptVi: 'Nêu 1 bước phân tích hằng đẳng thức hoặc chuyển vế.',
      acceptedAnswers: <String>['3', 'x=3', 'x = 3'],
      reasoningKeywords: <String>['x^2', 'x-3', 'x+3', 'căn', 'hằng đẳng thức', 'x > 0', '= 9', '=9'],
      oneStepHintVi: 'Đưa về x^2 = 9 rồi lấy nghiệm thỏa điều kiện x > 0.',
      gradingRubricStepsVi: <String>[
        'Bước 1: x^2 = 9 suy ra x = 3 hoặc x = -3.',
        'Bước 2: Vì x > 0 nên chọn x = 3.',
      ],
      explanationAfterRevealVi: 'x^2 - 9 = 0 => (x - 3)(x + 3) = 0; do x > 0 nên x = 3.',
    ),
    SoloApprovedQuestion(
      id: 'g1-math-004',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'math',
      gradeBand: 'Lớp 11',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Tính đạo hàm y\'(x) của hàm số y = x^3 - 3x tại điểm x = 2.',
      reasoningPromptVi: 'Viết biểu thức y\'(x) trước khi thay x = 2.',
      acceptedAnswers: <String>['9', "y'(2)=9", "y'(2) = 9"],
      reasoningKeywords: <String>['3x^2', '3x2', 'đạo hàm', 'thay', '3*4', '12 - 3', '12-3'],
      oneStepHintVi: 'Tính y\'(x) = 3x^2 - 3 rồi thay x = 2 vào biểu thức vừa tìm.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Tính đạo hàm y\'(x) = 3x^2 - 3.',
        'Bước 2: Thay x = 2 => y\'(2) = 3(4) - 3 = 9.',
      ],
      explanationAfterRevealVi: "y'(x) = 3x^2 - 3 => y'(2) = 12 - 3 = 9.",
    ),
    SoloApprovedQuestion(
      id: 'g1-math-005',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'math',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Cho cấp số cộng có u1 = 2 và công sai d = 3. Tính số hạng u5.',
      reasoningPromptVi: 'Viết công thức số hạng tổng quát un và thay n = 5.',
      acceptedAnswers: <String>['14', 'u5=14', 'u5 = 14'],
      reasoningKeywords: <String>['u1', 'n-1', '4d', '4*3', '2 + 12', '2+12', 'công sai'],
      oneStepHintVi: 'Dùng công thức un = u1 + (n - 1)d với n = 5.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Áp dụng un = u1 + (n - 1)d => u5 = u1 + 4d.',
        'Bước 2: Thay số u5 = 2 + 4 × 3 = 14.',
      ],
      explanationAfterRevealVi: 'u5 = 2 + (5 - 1) × 3 = 14.',
    ),
    SoloApprovedQuestion(
      id: 'g1-math-006',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'math',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Tính diện tích tam giác vuông có hai cạnh góc vuông dài 6 cm và 8 cm.',
      reasoningPromptVi: 'Ghi công thức diện tích tam giác vuông trước khi tính.',
      acceptedAnswers: <String>['24', '24 cm2', '24cm2', 's=24'],
      reasoningKeywords: <String>['1/2', '0,5', '0.5', '6*8', '6x8', '48/2', 'chia 2', 'cạnh góc vuông'],
      oneStepHintVi: 'Diện tích tam giác vuông bằng một nửa tích hai cạnh góc vuông.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Công thức S = (1/2) × a × b.',
        'Bước 2: S = (1/2) × 6 × 8 = 24 cm².',
      ],
      explanationAfterRevealVi: 'S = 1/2 × 6 × 8 = 24 (cm²).',
    ),
    SoloApprovedQuestion(
      id: 'g1-math-007',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'math',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Tìm nghiệm của phương trình: 3x + 5 = 20.',
      reasoningPromptVi: 'Viết 1 bước chuyển vế số 5 rồi chia cho 3.',
      acceptedAnswers: <String>['5', 'x=5', 'x = 5'],
      reasoningKeywords: <String>['3x', '15', '20 - 5', '20-5', 'chia 3', 'chuyển'],
      oneStepHintVi: 'Trừ 5 ở cả hai vế để thu được 3x = 15.',
      gradingRubricStepsVi: <String>[
        'Bước 1: 3x = 20 - 5 = 15.',
        'Bước 2: x = 15 / 3 = 5.',
      ],
      explanationAfterRevealVi: '3x + 5 = 20 => 3x = 15 => x = 5.',
    ),

    // --- VẬT LÍ (physics) ---
    SoloApprovedQuestion(
      id: 'g1-phys-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'physics',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Đặt hiệu điện thế U = 12 V vào hai đầu điện trở R = 6 Ω. Tính cường độ dòng điện I (A).',
      reasoningPromptVi: 'Ghi công thức định luật Ôm bạn áp dụng.',
      acceptedAnswers: <String>['2', '2a', '2 a', 'i=2a', 'i = 2a'],
      reasoningKeywords: <String>['u/r', 'u / r', '12/6', '12 / 6', 'ôm', 'ohm'],
      oneStepHintVi: 'Nhớ hệ thức định luật Ôm: I = U / R.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Áp dụng định luật Ôm I = U / R.',
        'Bước 2: I = 12 / 6 = 2 A.',
      ],
      explanationAfterRevealVi: 'I = U / R = 12 / 6 = 2 A.',
    ),
    SoloApprovedQuestion(
      id: 'g1-phys-002',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'physics',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Một xe chuyển động thẳng đều đi được quãng đường 90 km trong 1,5 giờ. Tính tốc độ của xe (km/h).',
      reasoningPromptVi: 'Viết công thức tính tốc độ v theo quãng đường s và thời gian t.',
      acceptedAnswers: <String>['60', '60 km/h', '60km/h', 'v=60', 'v = 60 km/h'],
      reasoningKeywords: <String>['s/t', 's / t', '90/1.5', '90/1,5', 'quãng đường', 'chia'],
      oneStepHintVi: 'Áp dụng công thức v = s / t với s = 90 km và t = 1,5 h.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Công thức tốc độ v = s / t.',
        'Bước 2: v = 90 / 1,5 = 60 km/h.',
      ],
      explanationAfterRevealVi: 'v = s / t = 90 / 1,5 = 60 km/h.',
    ),
    SoloApprovedQuestion(
      id: 'g1-phys-003',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'physics',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Tác dụng lực F = 20 N lên vật có khối lượng m = 4 kg (bỏ qua ma sát). Tính gia tốc a của vật (m/s²).',
      reasoningPromptVi: 'Nêu định luật II Newton và phép tính tìm a.',
      acceptedAnswers: <String>['5', '5 m/s2', '5 m/s^2', 'a=5'],
      reasoningKeywords: <String>['f/m', 'f / m', '20/4', 'newton', 'f = m'],
      oneStepHintVi: 'Theo định luật II Newton: F = m·a => a = F / m.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Từ định luật II Newton: a = F / m.',
        'Bước 2: a = 20 / 4 = 5 m/s².',
      ],
      explanationAfterRevealVi: 'a = F / m = 20 / 4 = 5 m/s².',
    ),
    SoloApprovedQuestion(
      id: 'g1-phys-004',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'physics',
      gradeBand: 'Lớp 11',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Một con lắc dao động điều hòa với chu kì T = 0,5 s. Tính tần số dao động f (Hz).',
      reasoningPromptVi: 'Viết mối liên hệ giữa tần số f và chu kì T.',
      acceptedAnswers: <String>['2', '2hz', '2 hz', 'f=2', 'f = 2 hz'],
      reasoningKeywords: <String>['1/t', '1 / t', '1/0.5', '1/0,5', 'nghịch đảo', 'chu kì'],
      oneStepHintVi: 'Tần số là nghịch đảo của chu kì: f = 1 / T.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Áp dụng công thức f = 1 / T.',
        'Bước 2: f = 1 / 0,5 = 2 Hz.',
      ],
      explanationAfterRevealVi: 'f = 1 / T = 1 / 0,5 = 2 Hz.',
    ),
    SoloApprovedQuestion(
      id: 'g1-phys-005',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'physics',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Một vật nặng m = 2 kg chuyển động với tốc độ v = 4 m/s. Tính động năng Wđ của vật (J).',
      reasoningPromptVi: 'Ghi công thức tính động năng trước khi thay số.',
      acceptedAnswers: <String>['16', '16j', '16 j'],
      reasoningKeywords: <String>['1/2', '0.5', '0,5', 'mv^2', 'mv2', '4^2', '16'],
      oneStepHintVi: 'Dùng công thức động năng: Wđ = (1/2) · m · v².',
      gradingRubricStepsVi: <String>[
        'Bước 1: Công thức Wđ = 1/2 · m · v².',
        'Bước 2: Wđ = 0,5 × 2 × 4² = 16 J.',
      ],
      explanationAfterRevealVi: 'Wđ = 1/2 × 2 × 4² = 16 J.',
    ),
    SoloApprovedQuestion(
      id: 'g1-phys-006',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'physics',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Tính công suất P (W) của một máy thực hiện công A = 1200 J trong thời gian t = 20 s.',
      reasoningPromptVi: 'Nêu công thức tính công suất P theo công A và thời gian t.',
      acceptedAnswers: <String>['60', '60w', '60 w', 'p=60'],
      reasoningKeywords: <String>['a/t', 'a / t', '1200/20', 'công', 'chia'],
      oneStepHintVi: 'Công suất bằng công thực hiện chia cho thời gian: P = A / t.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Công thức P = A / t.',
        'Bước 2: P = 1200 / 20 = 60 W.',
      ],
      explanationAfterRevealVi: 'P = A / t = 1200 / 20 = 60 W.',
    ),
    SoloApprovedQuestion(
      id: 'g1-phys-007',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'physics',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Một vật rơi tự do không vận tốc đầu với g = 10 m/s². Tính tốc độ của vật sau 3 giây (m/s).',
      reasoningPromptVi: 'Viết công thức tính tốc độ rơi tự do v theo g và t.',
      acceptedAnswers: <String>['30', '30 m/s', '30m/s', 'v=30'],
      reasoningKeywords: <String>['g*t', 'gt', 'g.t', '10*3', '10x3', 'rơi tự do'],
      oneStepHintVi: 'Trong chuyển động rơi tự do không vận tốc đầu: v = g · t.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Công thức v = g · t.',
        'Bước 2: v = 10 × 3 = 30 m/s.',
      ],
      explanationAfterRevealVi: 'v = g · t = 10 × 3 = 30 m/s.',
    ),

    // --- TIẾNG ANH (english) ---
    SoloApprovedQuestion(
      id: 'g1-eng-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'english',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Chia động từ trong ngoặc: She (live) ____ in Da Nang since 2021.',
      reasoningPromptVi: 'Nêu dấu hiệu thời gian để chọn thì phù hợp.',
      acceptedAnswers: <String>['has lived', "'s lived"],
      reasoningKeywords: <String>['since', 'hiện tại hoàn thành', 'present perfect', 'she', 'has'],
      oneStepHintVi: 'Chú ý cụm "since 2021" dùng với thì hiện tại hoàn thành.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Nhận biết dấu hiệu "since 2021" -> thì Hiện tại hoàn thành.',
        'Bước 2: Chủ ngữ ngôi thứ 3 số ít "She" -> has lived.',
      ],
      explanationAfterRevealVi: '"since 2021" đi với thì Hiện tại hoàn thành -> She has lived.',
    ),
    SoloApprovedQuestion(
      id: 'g1-eng-002',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'english',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Điền dạng đúng của động từ: If it rains tomorrow, we (stay) ____ at home.',
      reasoningPromptVi: 'Xác định câu điều kiện loại mấy và cấu trúc mệnh đề chính.',
      acceptedAnswers: <String>['will stay', "'ll stay"],
      reasoningKeywords: <String>['loại 1', 'type 1', 'first conditional', 'rains', 'will'],
      oneStepHintVi: 'Mệnh đề If ở thì hiện tại đơn -> câu điều kiện loại 1 dùng will + V.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Mệnh đề If chia hiện tại đơn (rains) -> câu điều kiện loại 1.',
        'Bước 2: Mệnh đề chính chia will + V nguyên mẫu -> will stay.',
      ],
      explanationAfterRevealVi: 'Câu điều kiện loại 1: If + S + V(s/es), S + will + V -> will stay.',
    ),
    SoloApprovedQuestion(
      id: 'g1-eng-003',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'english',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Chia động từ ở câu bị động hiện tại đơn: English (speak) ____ in many countries.',
      reasoningPromptVi: 'Nêu cấu trúc bị động thì hiện tại đơn (be + V3).',
      acceptedAnswers: <String>['is spoken'],
      reasoningKeywords: <String>['bị động', 'passive', 'is', 'v3', 'spoken', 'số ít'],
      oneStepHintVi: 'Câu bị động hiện tại đơn có dạng am/is/are + phân từ 2 (V3).',
      gradingRubricStepsVi: <String>[
        'Bước 1: Chủ ngữ "English" số ít ở thể bị động -> is + V3.',
        'Bước 2: Phân từ 2 của "speak" là "spoken" -> is spoken.',
      ],
      explanationAfterRevealVi: 'Bị động hiện tại đơn: English is spoken in many countries.',
    ),
    SoloApprovedQuestion(
      id: 'g1-eng-004',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'english',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Chia động từ trong ngoặc: They (visit) ____ Hue last summer.',
      reasoningPromptVi: 'Chỉ ra dấu hiệu thì quá khứ đơn trong câu.',
      acceptedAnswers: <String>['visited'],
      reasoningKeywords: <String>['last summer', 'quá khứ', 'past', 'ed', 'v2'],
      oneStepHintVi: 'Cụm "last summer" là dấu hiệu thì quá khứ đơn.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Nhận biết "last summer" -> thì quá khứ đơn.',
        'Bước 2: Động từ có quy tắc thêm -ed -> visited.',
      ],
      explanationAfterRevealVi: '"last summer" dùng quá khứ đơn -> They visited Hue last summer.',
    ),
    SoloApprovedQuestion(
      id: 'g1-eng-005',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'english',
      gradeBand: 'Lớp 11',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Điền dạng đúng: I enjoy (read) ____ science books in the morning.',
      reasoningPromptVi: 'Nêu quy tắc dạng động từ theo sau "enjoy".',
      acceptedAnswers: <String>['reading'],
      reasoningKeywords: <String>['enjoy', 'v-ing', 'ving', 'gerund', 'danh động từ'],
      oneStepHintVi: 'Sau động từ "enjoy" dùng động từ đuôi -ing (V-ing).',
      gradingRubricStepsVi: <String>[
        'Bước 1: Cấu trúc enjoy + V-ing.',
        'Bước 2: read -> reading.',
      ],
      explanationAfterRevealVi: 'enjoy + V-ing -> I enjoy reading science books.',
    ),
    SoloApprovedQuestion(
      id: 'g1-eng-006',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'english',
      gradeBand: 'Lớp 11',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Điền dạng so sánh hơn của tính từ: This exercise is (easy) ____ than the last one.',
      reasoningPromptVi: 'Giải thích quy tắc biến đổi tính từ 2 âm tiết tận cùng bằng "y".',
      acceptedAnswers: <String>['easier'],
      reasoningKeywords: <String>['than', 'so sánh hơn', 'ier', 'y', 'ngắn'],
      oneStepHintVi: 'Tính từ tận cùng bằng phụ âm + y đổi y thành i rồi thêm -er.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Có "than" -> dùng so sánh hơn.',
        'Bước 2: easy -> bỏ y thêm ier -> easier.',
      ],
      explanationAfterRevealVi: 'So sánh hơn của easy là easier (than).',
    ),
    SoloApprovedQuestion(
      id: 'g1-eng-007',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'english',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Điền giới từ thích hợp: Our morning class starts ____ 7:00 a.m.',
      reasoningPromptVi: 'Nêu quy tắc giới từ đứng trước mốc giờ cụ thể.',
      acceptedAnswers: <String>['at'],
      reasoningKeywords: <String>['giờ', 'time', '7:00', 'mốc giờ', 'at'],
      oneStepHintVi: 'Trước giờ cụ thể trong ngày (7:00 a.m.) dùng giới từ nào?',
      gradingRubricStepsVi: <String>[
        'Bước 1: 7:00 a.m. là mốc giờ cụ thể.',
        'Bước 2: Dùng giới từ "at" trước giờ cụ thể.',
      ],
      explanationAfterRevealVi: 'Trước giờ cụ thể dùng "at" -> starts at 7:00 a.m.',
    ),

    // --- SINH HỌC (biology) ---
    SoloApprovedQuestion(
      id: 'g1-bio-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'biology',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Khi lai hai cơ thể P thuần chủng AA × aa (trội hoàn toàn), kiểu gen ở F1 là gì?',
      reasoningPromptVi: 'Viết giao tử của bố (AA) và mẹ (aa).',
      acceptedAnswers: <String>['aa', '100% aa', 'Aa', '100% Aa'],
      reasoningKeywords: <String>['giao tử', 'a', 'thuần chủng', 'tổ hợp', 'menđen', 'mendel'],
      oneStepHintVi: 'Cơ thể AA chỉ cho 1 loại giao tử A; cơ thể aa chỉ cho giao tử a.',
      gradingRubricStepsVi: <String>[
        'Bước 1: P: AA cho giao tử A; aa cho giao tử a.',
        'Bước 2: Tổ hợp ở F1 thu được 100% Aa.',
      ],
      explanationAfterRevealVi: 'AA cho A, aa cho a => F1 đồng loạt kiểu gen Aa.',
    ),
    SoloApprovedQuestion(
      id: 'g1-bio-002',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'biology',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Bào quan nào là nơi diễn ra quá trình hô hấp tế bào tạo phần lớn ATP ở tế bào nhân thực?',
      reasoningPromptVi: 'Nêu ngắn vai trò năng lượng của bào quan đó.',
      acceptedAnswers: <String>['ti thể', 'ti the', 'mitochondria'],
      reasoningKeywords: <String>['atp', 'năng lượng', 'hô hấp', 'màng kép', 'nhà máy'],
      oneStepHintVi: 'Bào quan này được ví như "nhà máy năng lượng" của tế bào.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Xác định bào quan đảm nhiệm hô hấp tế bào tạo ATP.',
        'Bước 2: Kết luận là ti thể.',
      ],
      explanationAfterRevealVi: 'Ti thể thực hiện hô hấp tế bào, tổng hợp phần lớn ATP.',
    ),
    SoloApprovedQuestion(
      id: 'g1-bio-003',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'biology',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Trong phân tử DNA mạch kép, theo nguyên tắc bổ sung, nuclêôtit loại A liên kết với loại nào?',
      reasoningPromptVi: 'Nêu nguyên tắc bổ sung giữa các cặp bazơ nitơ trong DNA.',
      acceptedAnswers: <String>['t', 'timin', 'thymine'],
      reasoningKeywords: <String>['bổ sung', 'hiđrô', 'hydro', 'a-t', 'a = t', 'g-x', 'g-c'],
      oneStepHintVi: 'Nhớ cặp bazơ liên kết bằng 2 liên kết hiđrô trong DNA.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Trong DNA, A liên kết bổ sung với T (2 liên kết hiđrô), G liên kết với C/X.',
        'Bước 2: Kết luận loại T (Timin).',
      ],
      explanationAfterRevealVi: 'Theo nguyên tắc bổ sung trong DNA, A liên kết với T.',
    ),
    SoloApprovedQuestion(
      id: 'g1-bio-004',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'biology',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Bào quan nào ở tế bào thực vật chứa sắc tố diệp lục thực hiện quang hợp?',
      reasoningPromptVi: 'Giải thích ngắn vai trò của sắc tố diệp lục.',
      acceptedAnswers: <String>['lục lạp', 'luc lap', 'chloroplast'],
      reasoningKeywords: <String>['quang hợp', 'diệp lục', 'ánh sáng', 'thực vật'],
      oneStepHintVi: 'Bào quan có màu xanh lục hấp thụ năng lượng ánh sáng mặt trời.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Diệp lục hấp thụ ánh sáng thực hiện quang hợp.',
        'Bước 2: Bào quan chứa diệp lục là lục lạp.',
      ],
      explanationAfterRevealVi: 'Lục lạp chứa diệp lục giúp tế bào thực vật quang hợp.',
    ),
    SoloApprovedQuestion(
      id: 'g1-bio-005',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'biology',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Một tế bào nguyên phân liên tiếp 3 lần tạo ra bao nhiêu tế bào con?',
      reasoningPromptVi: 'Viết công thức số tế bào con sau k lần nguyên phân.',
      acceptedAnswers: <String>['8', '8 tế bào'],
      reasoningKeywords: <String>['2^k', '2^3', '2x2x2', '2*2*2', 'lũy thừa', 'nguyên phân'],
      oneStepHintVi: 'Sau k lần nguyên phân, 1 tế bào tạo ra 2^k tế bào con.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Công thức số tế bào con = 2^k với k = 3.',
        'Bước 2: 2^3 = 8 tế bào con.',
      ],
      explanationAfterRevealVi: '1 tế bào nguyên phân 3 lần tạo 2^3 = 8 tế bào con.',
    ),
    SoloApprovedQuestion(
      id: 'g1-bio-006',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'biology',
      gradeBand: 'Lớp 10',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Đơn phân cấu tạo nên phân tử prôtêin là gì?',
      reasoningPromptVi: 'Nêu tên liên kết nối các đơn phân của chuỗi pôlipeptit.',
      acceptedAnswers: <String>['amino acid', 'axit amin', 'acid amin'],
      reasoningKeywords: <String>['peptit', 'peptide', 'đơn phân', 'chuỗi', 'polipeptit'],
      oneStepHintVi: 'Các đơn phân này nối với nhau bằng liên kết peptit.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Prôtêin cấu tạo theo nguyên tắc đa phân từ các đơn phân nối bằng liên kết peptit.',
        'Bước 2: Đơn phân là amino acid (axit amin).',
      ],
      explanationAfterRevealVi: 'Prôtêin được cấu tạo từ các đơn phân amino acid (axit amin).',
    ),
    // --- HÓA HỌC (chemistry) ---
    SoloApprovedQuestion(
      id: 'g1-chem-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'chemistry',
      gradeBand: 'Lớp 12',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Este etyl axetat (CH3COOC2H5) có phân tử khối bằng bao nhiêu g/mol?',
      reasoningPromptVi: 'Tính tổng khối lượng nguyên tử theo công thức C4H8O2.',
      acceptedAnswers: <String>['88', '88 g/mol', '88g/mol'],
      reasoningKeywords: <String>['12', '48', '32', 'c4h8o2', '88'],
      oneStepHintVi: 'Cộng 4*12 + 8*1 + 2*16 để ra phân tử khối.',
      gradingRubricStepsVi: <String>[
        'Bước 1: CH3COOC2H5 có công thức phân tử C4H8O2.',
        'Bước 2: M = 4*12 + 8*1 + 2*16 = 88 g/mol.',
      ],
      explanationAfterRevealVi: 'M(CH3COOC2H5) = 4*12 + 8 + 32 = 88 g/mol.',
    ),
    SoloApprovedQuestion(
      id: 'g1-chem-002',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'chemistry',
      gradeBand: 'Lớp 11',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Dung dịch HCl 0,01 M có độ pH bằng bao nhiêu?',
      reasoningPromptVi: 'Nêu công thức tính pH từ nồng độ ion H+.',
      acceptedAnswers: <String>['2', 'ph=2', 'ph = 2'],
      reasoningKeywords: <String>['-lg', 'log', '0,01', '0.01', '10^-2'],
      oneStepHintVi: 'HCl là axit mạnh điện li hoàn toàn nên [H+] = 10^-2 M, áp dụng pH = -lg[H+].',
      gradingRubricStepsVi: <String>[
        'Bước 1: [H+] = 0,01 = 10^-2 M.',
        'Bước 2: pH = -lg(10^-2) = 2.',
      ],
      explanationAfterRevealVi: 'pH = -lg(0,01) = 2.',
    ),
    // --- NGỮ VĂN (literature) ---
    SoloApprovedQuestion(
      id: 'g1-lit-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'literature',
      gradeBand: 'Lớp 12',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Tác phẩm "Tuyên ngôn Độc lập" (2/9/1945) do ai là tác giả?',
      reasoningPromptVi: 'Nêu ngắn gọn hoàn cảnh ra đời hoặc mục đích chính của văn bản.',
      acceptedAnswers: <String>['hồ chí minh', 'ho chi minh', 'chủ tịch hồ chí minh', 'bác hồ'],
      reasoningKeywords: <String>['ba đình', '1945', 'độc lập', 'tuyên ngôn', 'bác', 'người'],
      oneStepHintVi: 'Đây là văn bản chính luận bất hủ đọc tại Quảng trường Ba Đình ngày 2/9/1945.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Văn bản đọc tại Quảng trường Ba Đình khai sinh nước Việt Nam Dân chủ Cộng hòa.',
        'Bước 2: Tác giả là Chủ tịch Hồ Chí Minh.',
      ],
      explanationAfterRevealVi: 'Tác giả bản Tuyên ngôn Độc lập (2/9/1945) là Chủ tịch Hồ Chí Minh.',
    ),
    SoloApprovedQuestion(
      id: 'g1-lit-002',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'literature',
      gradeBand: 'Lớp 11',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Biện pháp tu từ so sánh gồm hai vế nối với nhau thường gặp qua từ ngữ nào phổ biến nhất?',
      reasoningPromptVi: 'Viết 1 ví dụ ngắn câu có dùng từ so sánh.',
      acceptedAnswers: <String>['như', 'tựa', 'giống như', 'là'],
      reasoningKeywords: <String>['như', 'tựa', 'ví dụ', 'đối chiếu', 'giống'],
      oneStepHintVi: 'Ví dụ: "Trẻ em ___ búp trên cành".',
      gradingRubricStepsVi: <String>[
        'Bước 1: So sánh đối chiếu hai sự vật có nét tương đồng.',
        'Bước 2: Từ so sánh tiêu biểu: "như", "tựa", "giống như", "là".',
      ],
      explanationAfterRevealVi: 'Từ so sánh phổ biến nhất là "như" (ngoài ra có "tựa", "là", "giống như").',
    ),
    // --- LỊCH SỬ (history) ---
    SoloApprovedQuestion(
      id: 'g1-his-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'history',
      gradeBand: 'Lớp 12',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Chiến dịch Điện Biên Phủ kết thúc thắng lợi vào ngày, tháng, năm nào (định dạng DD/MM/YYYY)?',
      reasoningPromptVi: 'Nêu ngắn gọn ý nghĩa quyết định của chiến thắng này đối với Hiệp định Giơ-ne-vơ.',
      acceptedAnswers: <String>['07/05/1954', '7/5/1954', '7-5-1954', '07-05-1954'],
      reasoningKeywords: <String>['1954', 'giơ-ne-vơ', 'geneva', 'pháp', 'đờ cát', '56 ngày'],
      oneStepHintVi: 'Chiến dịch kéo dài 56 ngày đêm và kết thúc đầu tháng 5 năm 1954.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Chiều 07/05/1954, quân ta bắt sống tướng Đờ Cát-tơ-ri.',
        'Bước 2: Thắng lợi buộc Pháp ký Hiệp định Giơ-ne-vơ 1954.',
      ],
      explanationAfterRevealVi: 'Chiến thắng Điện Biên Phủ diễn ra ngày 07/05/1954.',
    ),
    SoloApprovedQuestion(
      id: 'g1-his-002',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'history',
      gradeBand: 'Lớp 12',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'ASEAN được thành lập vào năm nào tại Băng Cốc (Thái Lan)?',
      reasoningPromptVi: 'Kể tên ít nhất 2 quốc gia sáng lập ASEAN.',
      acceptedAnswers: <String>['1967'],
      reasoningKeywords: <String>['thái lan', 'indonesia', 'malaysia', 'singapore', 'philippines', 'băng cốc'],
      oneStepHintVi: 'Tuyên bố Băng Cốc được 5 nước Đông Nam Á ký vào tháng 8 thập niên 1960.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Ngày 08/08/1967 tại Băng Cốc, 5 nước ký Tuyên bố ASEAN.',
        'Bước 2: Năm thành lập là 1967.',
      ],
      explanationAfterRevealVi: 'ASEAN thành lập ngày 08/08/1967.',
    ),
    // --- ĐỊA LÍ (geography) ---
    SoloApprovedQuestion(
      id: 'g1-geo-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'geography',
      gradeBand: 'Lớp 12',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Nước ta nằm trong múi giờ thứ mấy theo giờ quốc tế GMT?',
      reasoningPromptVi: 'Giải thích vì sao múi giờ chuẩn Việt Nam sớm hơn giờ GMT 7 tiếng.',
      acceptedAnswers: <String>['7', 'gmt+7', 'múi giờ 7', 'múi giờ số 7', '+7'],
      reasoningKeywords: <String>['kinh tuyến', '105', '15', 'đông', 'gmt'],
      oneStepHintVi: 'Kinh tuyến trục 105°Đ chia cho 15° mỗi múi giờ sẽ ra số thứ tự múi giờ.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Kinh tuyến 105°Đ / 15° = múi giờ số 7.',
        'Bước 2: Việt Nam thuộc múi giờ GMT+7.',
      ],
      explanationAfterRevealVi: 'Việt Nam nằm trọn trong múi giờ số 7 (GMT+7).',
    ),
    // --- TIN HỌC (informatics) ---
    SoloApprovedQuestion(
      id: 'g1-inf-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'informatics',
      gradeBand: 'Lớp 11',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Số nhị phân 1010 đổi sang hệ thập phân bằng bao nhiêu?',
      reasoningPromptVi: 'Viết khai triển tổng các lũy thừa của 2.',
      acceptedAnswers: <String>['10'],
      reasoningKeywords: <String>['2^3', '2^1', '8 + 2', '8+2', 'lũy thừa'],
      oneStepHintVi: 'Tính 1*2^3 + 0*2^2 + 1*2^1 + 0*2^0.',
      gradingRubricStepsVi: <String>[
        'Bước 1: 1010_2 = 1*8 + 0*4 + 1*2 + 0*1.',
        'Bước 2: Kết quả bằng 10.',
      ],
      explanationAfterRevealVi: '1010 trong hệ nhị phân bằng 8 + 2 = 10 trong hệ thập phân.',
    ),
    // --- GDKT&PL / GDCD (civic_econ) ---
    SoloApprovedQuestion(
      id: 'g1-civ-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'civic_econ',
      gradeBand: 'Lớp 12',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Khi cầu tăng mà cung không đổi, giá cả thị trường có xu hướng tăng hay giảm?',
      reasoningPromptVi: 'Nêu ngắn gọn mối quan hệ giữa cung - cầu và giá cả.',
      acceptedAnswers: <String>['tăng', 'tăng lên', 'giá tăng'],
      reasoningKeywords: <String>['cầu', 'lớn hơn', 'khan hiếm', 'cung', 'tăng'],
      oneStepHintVi: 'Khi lượng người mua vượt lượng hàng hóa sẵn có thì giá biến động ra sao?',
      gradingRubricStepsVi: <String>[
        'Bước 1: Cầu > Cung tạo áp lực cạnh tranh mua.',
        'Bước 2: Giá cả thị trường có xu hướng tăng.',
      ],
      explanationAfterRevealVi: 'Theo quy luật cung - cầu, khi cầu tăng mà cung giữ nguyên thì giá cả tăng.',
    ),
    // --- CÔNG NGHỆ (technology) ---
    SoloApprovedQuestion(
      id: 'g1-tech-001',
      revision: 1,
      rubricRevision: 1,
      subjectCode: 'technology',
      gradeBand: 'Lớp 12',
      curriculum: 'gdpt_2018',
      approvedBy: 'curriculum_seed_v1',
      prompt: 'Mạch điện xoay chiều 3 pha có điện áp dây 380V thì điện áp pha (tải nối sao) bằng bao nhiêu V?',
      reasoningPromptVi: 'Nêu công thức liên hệ giữa Ud và Up khi mắc hình sao.',
      acceptedAnswers: <String>['220', '220v', '220 v'],
      reasoningKeywords: <String>['căn 3', 'sqrt(3)', '1.73', '1,73', 'ud /', '380'],
      oneStepHintVi: 'Với tải nối hình sao, Ud = √3 * Up => Up = 380 / 1,732.',
      gradingRubricStepsVi: <String>[
        'Bước 1: Up = Ud / √3 = 380 / √3.',
        'Bước 2: Up ≈ 220 V.',
      ],
      explanationAfterRevealVi: 'Up = 380 / √3 ≈ 220 V.',
    ),
  ];

  static const List<String> supportedSubjectCodes = <String>[
    'math',
    'physics',
    'english',
    'biology',
  ];

  static String normalizeSubjectKey(String? rawCode) {
    final String c = (rawCode ?? '').trim().toLowerCase();
    switch (c) {
      case 'toan':
      case 'math':
        return 'math';
      case 'vat_ly':
      case 'vat_li':
      case 'physics':
        return 'physics';
      case 'tieng_anh':
      case 'english':
        return 'english';
      case 'sinh_hoc':
      case 'biology':
        return 'biology';
      case 'hoa_hoc':
      case 'chemistry':
        return 'chemistry';
      case 'ngu_van':
      case 'literature':
        return 'literature';
      case 'lich_su':
      case 'history':
        return 'history';
      case 'dia_ly':
      case 'dia_li':
      case 'geography':
        return 'geography';
      case 'tin_hoc':
      case 'informatics':
        return 'informatics';
      case 'gdcd':
      case 'ktpl':
      case 'civics':
      case 'civic_econ':
        return 'civic_econ';
      case 'cong_nghe':
      case 'technology':
        return 'technology';
      default:
        return c.isEmpty ? 'math' : c;
    }
  }

  static List<SoloApprovedQuestion> questionsForSubject(String subjectCode) {
    final String norm = normalizeSubjectKey(subjectCode);
    return allCachedApprovedQuestions
        .where((SoloApprovedQuestion q) => q.subjectCode == norm)
        .toList(growable: false);
  }

  static SoloApprovedQuestion? findById(String questionId) {
    for (final SoloApprovedQuestion q in allCachedApprovedQuestions) {
      if (q.id == questionId) return q;
    }
    return null;
  }

  /// Chọn câu hỏi có sẵn đáp án & rubric trên máy cho chế độ offline/báo thức,
  /// ưu tiên đúng môn + khối lớp và xoay vòng để không lặp lại 1 câu cố định.
  static SoloApprovedQuestion pickOfflineQuestion({
    String? subjectCode,
    String? gradeLevel,
    String? excludeQuestionId,
    int rotationOffset = 0,
  }) {
    final String normSubject = normalizeSubjectKey(subjectCode);
    List<SoloApprovedQuestion> pool = questionsForSubject(normSubject);
    if (pool.isEmpty) {
      pool = questionsForSubject('math');
    }
    if (gradeLevel != null && gradeLevel.trim().isNotEmpty) {
      final String targetGrade = gradeLevel.trim().toLowerCase();
      final List<SoloApprovedQuestion> gradeMatches = pool
          .where((SoloApprovedQuestion q) => q.gradeBand.toLowerCase() == targetGrade)
          .toList(growable: false);
      if (gradeMatches.isNotEmpty) {
        pool = gradeMatches;
      }
    }
    if (pool.length > 1 && excludeQuestionId != null) {
      final List<SoloApprovedQuestion> nonRepeat = pool
          .where((SoloApprovedQuestion q) => q.id != excludeQuestionId)
          .toList(growable: false);
      if (nonRepeat.isNotEmpty) {
        pool = nonRepeat;
      }
    }
    final int safeIndex = (rotationOffset < 0 ? 0 : rotationOffset) % pool.length;
    return pool[safeIndex];
  }

  static bool hasApprovedCacheFor(String subjectCode) =>
      questionsForSubject(subjectCode).length >= 6;

  /// Xáo trộn câu hỏi hoàn toàn deterministic theo `seed` để hỗ trợ Replay.
  static List<SoloApprovedQuestion> selectDeterministicDeck({
    required String subjectCode,
    required int seed,
  }) {
    final List<SoloApprovedQuestion> list =
        List<SoloApprovedQuestion>.from(questionsForSubject(subjectCode));
    if (list.length <= 1) return list;
    int state = seed & 0x7FFFFFFF;
    for (int i = list.length - 1; i > 0; i--) {
      state = ((state * 1103515245) + 12345) & 0x7FFFFFFF;
      final int j = state % (i + 1);
      final SoloApprovedQuestion tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}

/// Bộ chấm bài luyện đơn cục bộ 3 trạng thái (`correct | incorrect | uncertain`).
///
/// - Không gọi Gemini tự quyết HP.
/// - Không lộ đáp án chuẩn trước khi nộp.
/// - `uncertain` mở đường sửa bài hoặc đổi câu khác mà không bị phạt.
SoloGradingFeedback gradeSoloTrainingSubmission({
  required SoloApprovedQuestion question,
  required String answerText,
  required String reasoningText,
}) {
  final String cleanAns = answerText.trim();
  final String cleanReason = reasoningText.trim();
  final String lowerAns = cleanAns.toLowerCase();
  final String lowerReason = cleanReason.toLowerCase();

  if (cleanAns.isEmpty) {
    return SoloGradingFeedback(
      status: SoloGradeStatus.incorrect,
      feedbackVi: 'Bạn chưa nhập đáp án. Hãy nhập đáp án kèm một bước trình bày.',
      oneStepHintVi: question.oneStepHintVi,
      canRetry: true,
      canSwapQuestion: false,
      canRevealRubric: false,
    );
  }

  if (cleanReason.length < 3) {
    return SoloGradingFeedback(
      status: SoloGradeStatus.incorrect,
      feedbackVi:
          'Cần viết ít nhất một bước trình bày lời giải để kích hoạt chiêu (chỉ khoanh đáp án không đủ).',
      oneStepHintVi: question.oneStepHintVi,
      canRetry: true,
      canSwapQuestion: false,
      canRevealRubric: false,
    );
  }

  // Nhánh uncertain: ký hiệu mơ hồ / không rõ để chấm công bằng
  const List<String> uncertainMarkers = <String>[
    '?',
    '...',
    'chưa chắc',
    'chua chac',
    'chưa rõ',
    'chua ro',
    'không rõ',
    'khong ro',
    'mờ',
  ];
  final bool hasUncertainMarker = uncertainMarkers.any(
    (String m) => lowerAns.contains(m) || lowerReason.contains(m),
  );
  if (hasUncertainMarker) {
    return const SoloGradingFeedback(
      status: SoloGradeStatus.uncertain,
      feedbackVi:
          'Bài làm có dấu hiệu chưa rõ để chấm chắc chắn. Bạn có thể sửa lại chữ trình bày hoặc đổi câu khác mà không bị phạt.',
      canRetry: true,
      canSwapQuestion: true,
      canRevealRubric: false,
    );
  }

  final bool answerCorrect = isAnswerAccepted(cleanAns, question.acceptedAnswers);

  final bool hasKeyword = question.reasoningKeywords.any(
    (String kw) => lowerReason.contains(kw.toLowerCase()),
  );
  final bool hasFormulaOrNumber = RegExp(r'[0-9=+\-*/^×÷]').hasMatch(cleanReason);
  final bool hasSubstantiveStep =
      hasKeyword || hasFormulaOrNumber || cleanReason.split(RegExp(r'\s+')).length >= 5;

  if (answerCorrect && !hasSubstantiveStep) {
    // Đáp án trùng nhưng bước trình bày quá chung chung -> uncertain (cho sửa chữ hoặc đổi câu, không xử sai oan)
    return const SoloGradingFeedback(
      status: SoloGradeStatus.uncertain,
      feedbackVi:
          'Đáp án khớp nhưng bước trình bày chưa đủ rõ để xác nhận cách làm. Hãy bổ sung phép tính/lý do ngắn hoặc đổi câu khác (không phạt).',
      canRetry: true,
      canSwapQuestion: true,
      canRevealRubric: false,
    );
  }

  if (answerCorrect && hasSubstantiveStep) {
    return const SoloGradingFeedback(
      status: SoloGradeStatus.correct,
      feedbackVi: 'Đáp án và bước trình bày hợp lệ. Chọn đòn đánh hoặc chiêu thức của bạn.',
      canRetry: false,
      canSwapQuestion: false,
      canRevealRubric: true,
    );
  }

  return SoloGradingFeedback(
    status: SoloGradeStatus.incorrect,
    feedbackVi:
        'Đáp án chưa khớp kết quả chuẩn. Bạn có thể xem gợi ý một bước để thử lại hoặc tiếp tục lượt mà không bị trừ uy tín.',
    oneStepHintVi: question.oneStepHintVi,
    canRetry: true,
    canSwapQuestion: false,
    canRevealRubric: true,
  );
}
