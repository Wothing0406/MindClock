/// Danh mục môn học và cấp lớp theo `docs/32 §1`.
class SubjectInfo {
  const SubjectInfo({
    required this.code,
    required this.nameVi,
    required this.hasApprovedQuestions,
  });

  final String code;
  final String nameVi;
  final bool hasApprovedQuestions;
}

class SubjectCatalog {
  const SubjectCatalog._();

  static const List<String> gradeLevels = <String>[
    'Lớp 6',
    'Lớp 7',
    'Lớp 8',
    'Lớp 9',
    'Lớp 10',
    'Lớp 11',
    'Lớp 12',
  ];

  static const List<SubjectInfo> allSubjects = <SubjectInfo>[
    SubjectInfo(code: 'math', nameVi: 'Toán', hasApprovedQuestions: true),
    SubjectInfo(code: 'literature', nameVi: 'Ngữ văn', hasApprovedQuestions: false),
    SubjectInfo(code: 'english', nameVi: 'Tiếng Anh', hasApprovedQuestions: true),
    SubjectInfo(code: 'physics', nameVi: 'Vật lí', hasApprovedQuestions: false),
    SubjectInfo(code: 'chemistry', nameVi: 'Hóa học', hasApprovedQuestions: false),
    SubjectInfo(code: 'biology', nameVi: 'Sinh học', hasApprovedQuestions: true),
    SubjectInfo(code: 'history', nameVi: 'Lịch sử', hasApprovedQuestions: false),
    SubjectInfo(code: 'geography', nameVi: 'Địa lí', hasApprovedQuestions: false),
    SubjectInfo(code: 'informatics', nameVi: 'Tin học', hasApprovedQuestions: false),
    SubjectInfo(code: 'technology', nameVi: 'Công nghệ', hasApprovedQuestions: false),
    SubjectInfo(
      code: 'civic_econ',
      nameVi: 'Giáo dục kinh tế và pháp luật',
      hasApprovedQuestions: false,
    ),
  ];

  static SubjectInfo? findByCode(String code) {
    for (final SubjectInfo subject in allSubjects) {
      if (subject.code == code) return subject;
    }
    return null;
  }

  static String nameFor(String code) {
    return findByCode(code)?.nameVi ?? code;
  }

  static bool isApproved(String code) {
    return findByCode(code)?.hasApprovedQuestions ?? false;
  }
}
