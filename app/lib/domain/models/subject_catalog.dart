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

  static const List<String> thptGradeLevels = <String>[
    'Lớp 10',
    'Lớp 11',
    'Lớp 12',
  ];

  static const List<String> gradeLevels = <String>[
    'Lớp 10',
    'Lớp 11',
    'Lớp 12',
    'Lớp 9',
    'Lớp 8',
    'Lớp 7',
    'Lớp 6',
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

  static const Map<String, String> _backendAliases = <String, String>{
    'toan': 'math',
    'math': 'math',
    'ngu_van': 'literature',
    'nguvan': 'literature',
    'van': 'literature',
    'literature': 'literature',
    'tieng_anh': 'english',
    'tienganh': 'english',
    'anh': 'english',
    'english': 'english',
    'vat_ly': 'physics',
    'vat_li': 'physics',
    'physics': 'physics',
    'hoa_hoc': 'chemistry',
    'chemistry': 'chemistry',
    'sinh_hoc': 'biology',
    'biology': 'biology',
    'lich_su': 'history',
    'history': 'history',
    'dia_ly': 'geography',
    'dia_li': 'geography',
    'geography': 'geography',
    'tin_hoc': 'informatics',
    'informatics': 'informatics',
    'cong_nghe': 'technology',
    'technology': 'technology',
    'gdcd': 'civic_econ',
    'ktpl': 'civic_econ',
    'gdktpl': 'civic_econ',
    'civics': 'civic_econ',
    'civic_econ': 'civic_econ',
  };

  /// Chuẩn hóa mã môn học hai chiều giữa server (`TOAN`, `NGU_VAN`...) và catalog Flutter (`math`, `literature`...).
  static String normalizeCode(String code) {
    final String clean = code.trim().toLowerCase();
    return _backendAliases[clean] ?? clean;
  }

  static SubjectInfo? findByCode(String code) {
    final String clean = normalizeCode(code);
    for (final SubjectInfo subject in allSubjects) {
      if (subject.code == clean) return subject;
    }
    if (clean == 'activity') {
      return const SubjectInfo(
        code: 'activity',
        nameVi: 'Sinh hoạt / HĐTN',
        hasApprovedQuestions: false,
      );
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
