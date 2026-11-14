from sqlalchemy.orm import Session

from app.db.models import Question

SEED_QUESTIONS: list[dict] = [
    {
        'id': 'math9-linear-001',
        'subject_code': 'TOAN',
        'grade_band': 'Lớp 9',
        'topic_id': 'linear_equation_1var',
        'difficulty': 1,
        'prompt': 'Giải phương trình 2(x - 3) = 10.',
        'answer_spec_json': {'accepted': ['8', 'x=8', 'x = 8']},
        'reasoning_prompt_vi': 'Viết một hoặc hai bước biến đổi chính của bạn.',
        'rubric_json': {
            'steps': ['Nhân phá ngoặc hoặc chia hai vế cho 2', 'Tìm x = 8'],
            'hint_vi': 'Chia hai vế cho 2 trước sẽ rút gọn rất nhanh: x - 3 = 5.',
        },
        'rubric_revision': 3,
        'status': 'published',
        'source_type': 'approved_bank',
        'approved_by': 'curriculum_seed_v1',
    },
    {
        'id': 'math7-ratio-001',
        'subject_code': 'TOAN',
        'grade_band': 'Lớp 7',
        'topic_id': 'proportion_basic',
        'difficulty': 1,
        'prompt': 'Tìm x biết x / 4 = 9 / 12.',
        'answer_spec_json': {'accepted': ['3', 'x=3', 'x = 3']},
        'reasoning_prompt_vi': 'Nêu cách rút gọn vế phải trước khi nhân chéo.',
        'rubric_json': {
            'steps': ['Rút gọn 9/12 = 3/4', 'Suy ra x = 3'],
            'hint_vi': 'Thử rút gọn phân số 9/12 trước khi tìm x nhé.',
        },
        'rubric_revision': 1,
        'status': 'published',
        'source_type': 'approved_bank',
        'approved_by': 'curriculum_seed_v1',
    },
    {
        'id': 'math12-deriv-001',
        'subject_code': 'TOAN',
        'grade_band': 'Lớp 12',
        'topic_id': 'derivative_poly',
        'difficulty': 2,
        'prompt': 'Tính đạo hàm của hàm số y = x^3 - 3x tại điểm x = 2.',
        'answer_spec_json': {'accepted': ['9', "y'(2)=9", "y'(2) = 9"]},
        'reasoning_prompt_vi': "Viết biểu thức y'(x) trước khi thay x = 2.",
        'rubric_json': {
            'steps': ["y'(x) = 3x^2 - 3", "y'(2) = 3*4 - 3 = 9"],
            'hint_vi': 'Tính đạo hàm y\'(x) = 3x^2 - 3 rồi thay x = 2.',
        },
        'rubric_revision': 1,
        'status': 'published',
        'source_type': 'approved_bank',
        'approved_by': 'curriculum_seed_v1',
    },
    {
        'id': 'eng9-tense-001',
        'subject_code': 'TIENG_ANH',
        'grade_band': 'Lớp 9',
        'topic_id': 'present_perfect_vs_past',
        'difficulty': 1,
        'prompt': 'Chia động từ trong ngoặc: She (live) ____ in Da Nang since 2021.',
        'answer_spec_json': {'accepted': ['has lived', "'s lived"]},
        'reasoning_prompt_vi': 'Giải thích ngắn dấu hiệu thời gian trong câu.',
        'rubric_json': {
            'steps': ['Nhận biết "since 2021"', 'Dùng hiện tại hoàn thành "has lived"'],
            'hint_vi': 'Từ "since 2021" đi với thì hiện tại hoàn thành (has/have + V3).',
        },
        'rubric_revision': 1,
        'status': 'published',
        'source_type': 'approved_bank',
        'approved_by': 'curriculum_seed_v1',
    },
    {
        'id': 'lit9-device-001',
        'subject_code': 'NGU_VAN',
        'grade_band': 'Lớp 9',
        'topic_id': 'rhetoric_metaphor',
        'difficulty': 1,
        'prompt': 'Trong câu "Ngày ngày mặt trời đi qua trên lăng / Thấy một mặt trời trong lăng rất đỏ", hình ảnh "mặt trời" thứ hai sử dụng biện pháp tu từ nào?',
        'answer_spec_json': {'accepted': ['ẩn dụ', 'an du', 'biện pháp ẩn dụ']},
        'reasoning_prompt_vi': 'Nêu điểm tương đồng gợi ra biện pháp đó.',
        'rubric_json': {
            'steps': ['Xác định "mặt trời trong lăng" ẩn dụ cho Bác Hồ'],
            'hint_vi': 'So sánh ngầm dựa trên nét tương đồng về nguồn sáng và vai trò soi đường.',
        },
        'rubric_revision': 1,
        'status': 'published',
        'source_type': 'approved_bank',
        'approved_by': 'curriculum_seed_v1',
    },
    {
        'id': 'phys9-ohm-001',
        'subject_code': 'VAT_LY',
        'grade_band': 'Lớp 9',
        'topic_id': 'ohms_law',
        'difficulty': 1,
        'prompt': 'Đặt hiệu điện thế U = 12 V vào hai đầu điện trở R = 6 Ω. Tính cường độ dòng điện I (theo ampe).',
        'answer_spec_json': {'accepted': ['2', '2a', '2 a', '2A', 'i=2a']},
        'reasoning_prompt_vi': 'Ghi công thức định luật Ôm bạn vừa áp dụng.',
        'rubric_json': {
            'steps': ['I = U / R', 'I = 12 / 6 = 2 A'],
            'hint_vi': 'Áp dụng công thức I = U / R.',
        },
        'rubric_revision': 1,
        'status': 'published',
        'source_type': 'approved_bank',
        'approved_by': 'curriculum_seed_v1',
    },
    {
        'id': 'bio9-genetics-001',
        'subject_code': 'SINH_HOC',
        'grade_band': 'Lớp 9',
        'topic_id': 'mendel_law',
        'difficulty': 1,
        'prompt': 'Theo quy luật phân li của Menđen, khi lai hai cơ thể P thuần chủng khác nhau về một cặp tính trạng tương phản (AA × aa), tỉ lệ kiểu gen ở F1 là gì?',
        'answer_spec_json': {'accepted': ['100% Aa', 'Aa', '100% aa (dị hợp)', 'toàn bộ Aa']},
        'reasoning_prompt_vi': 'Viết giao tử tạo ra từ bố (AA) và mẹ (aa).',
        'rubric_json': {
            'steps': ['AA cho 1 loại giao tử A; aa cho 1 loại giao tử a', 'Tổ hợp F1 thu được 100% Aa'],
            'hint_vi': 'Mỗi cơ thể thuần chủng chỉ tạo ra một loại giao tử duy nhất.',
        },
        'rubric_revision': 1,
        'status': 'published',
        'source_type': 'approved_bank',
        'approved_by': 'curriculum_seed_v1',
    },
    {
        'id': 'cs10-bin-001',
        'subject_code': 'TIN_HOC',
        'grade_band': 'Lớp 10',
        'topic_id': 'binary_representation',
        'difficulty': 1,
        'prompt': 'Chuyển số thập phân 13 sang hệ nhị phân (viết chuỗi bit).',
        'answer_spec_json': {'accepted': ['1101', '1101_2', '0b1101']},
        'reasoning_prompt_vi': 'Nêu các lũy thừa của 2 hoặc phép chia liên tiếp cho 2.',
        'rubric_json': {
            'steps': ['13 = 8 + 4 + 0 + 1 = 1×2^3 + 1×2^2 + 0×2^1 + 1×2^0', 'Kết quả nhị phân là 1101'],
            'hint_vi': 'Tách 13 thành tổng các lũy thừa của 2 (8, 4, 2, 1).',
        },
        'rubric_revision': 1,
        'status': 'published',
        'source_type': 'approved_bank',
        'approved_by': 'curriculum_seed_v1',
    },
]


def seed_approved_questions(db: Session) -> int:
    inserted = 0
    for item in SEED_QUESTIONS:
        existing = db.get(Question, item['id'])
        if existing is None:
            db.add(Question(**item))
            inserted += 1
    if inserted:
        db.commit()
    return inserted
