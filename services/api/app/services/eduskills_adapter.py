from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum
from typing import Any

from app.services.gemini_service import normalize_subject_code

EDUSKILLS_POLICY_VERSION = 'eduskills-vn-adapter-v1.0'


class EduSkillsMode(StrEnum):
    AUTHOR_DRAFT = 'AUTHOR_DRAFT'
    GRADE_CANDIDATE = 'GRADE_CANDIDATE'
    HINT_ONE_STEP = 'HINT_ONE_STEP'
    POST_ATTEMPT_EXPLAIN = 'POST_ATTEMPT_EXPLAIN'


SUBJECT_PEDAGOGY_RULES_VI: dict[str, str] = {
    'TOAN': (
        'Kiểm tra biến đổi tương đương, điều kiện xác định (nếu có) và phép tính số học từng bước; '
        'chấp nhận cách giải tương đương hợp lệ.'
    ),
    'VAT_LY': (
        'Kiểm tra đúng công thức vật lí, đại lượng, đơn vị SI (V, A, Ω, m/s...) và bản chất hiện tượng.'
    ),
    'HOA_HOC': (
        'Kiểm tra bảo toàn nguyên tố/khối lượng, hệ số cân bằng phương trình và điều kiện phản ứng.'
    ),
    'SINH_HOC': (
        'Kiểm tra quy luật di truyền/sinh học, tỉ lệ giao tử - kiểu gen - kiểu hình và thuật ngữ chuẩn GDPT 2018.'
    ),
    'NGU_VAN': (
        'Kiểm tra nhận diện đúng biện pháp tu từ/luận điểm chính và nêu được dấu hiệu/tác dụng ngắn gọn.'
    ),
    'TIENG_ANH': (
        'Kiểm tra dấu hiệu thì/cấu trúc ngữ pháp (time markers, subject-verb agreement) và dạng từ đúng.'
    ),
    'TIN_HOC': (
        'Kiểm tra biểu diễn nhị phân/thuật toán từng bước, giá trị biên và độ chính xác của chuỗi kết quả.'
    ),
}


@dataclass(frozen=True)
class EduSkillsPromptSpec:
    mode: EduSkillsMode
    policy_version: str
    subject_code: str
    allows_final_answer_reveal: bool
    system_instruction_vi: str


def build_eduskills_prompt_spec(
    mode: EduSkillsMode,
    subject_code: str,
    *,
    grade_band: str = 'Lớp 10',
) -> EduSkillsPromptSpec:
    norm_subject = normalize_subject_code(subject_code)
    subject_rule = SUBJECT_PEDAGOGY_RULES_VI.get(
        norm_subject,
        'Đối chiếu từng bước lập luận theo chuẩn chương trình GDPT 2018 của Bộ GD&ĐT.',
    )

    if mode == EduSkillsMode.AUTHOR_DRAFT:
        instruction = (
            f'[EduSkills-VN · {EDUSKILLS_POLICY_VERSION} · AUTHOR_DRAFT]\n'
            f'Soạn bản nháp câu hỏi và MorningCard cho {grade_band} môn {norm_subject}.\n'
            f'Quy tắc bộ môn: {subject_rule}\n'
            'Đầu ra chỉ là draft chờ reviewer duyệt; không tự xuất bản vào ngân hàng chấm điểm.'
        )
        allows_reveal = True
    elif mode == EduSkillsMode.GRADE_CANDIDATE:
        instruction = (
            f'[EduSkills-VN · {EDUSKILLS_POLICY_VERSION} · GRADE_CANDIDATE]\n'
            f'Đề xuất kết quả chấm 3 trạng thái (correct|incorrect|uncertain) cho môn {norm_subject}.\n'
            f'Quy tắc bộ môn: {subject_rule}\n'
            'CẤM tự quyết định XP/chuỗi/gian lận; CẤM tiết lộ đáp án cuối trong feedback khi bài làm chưa đúng.'
        )
        allows_reveal = False
    elif mode == EduSkillsMode.HINT_ONE_STEP:
        instruction = (
            f'[EduSkills-VN · {EDUSKILLS_POLICY_VERSION} · HINT_ONE_STEP]\n'
            f'Đưa ra đúng 1 bước gợi mở tiếp theo hoặc câu hỏi kiểm tra cho môn {norm_subject} (từ lần sai rõ thứ 3).\n'
            f'Quy tắc bộ môn: {subject_rule}\n'
            'TUYỆT ĐỐI KHÔNG dùng chế độ giải trọn bài 4 tầng (giai-chi-tiet) và KHÔNG lộ đáp án cuối.'
        )
        allows_reveal = False
    elif mode == EduSkillsMode.POST_ATTEMPT_EXPLAIN:
        instruction = (
            f'[EduSkills-VN · {EDUSKILLS_POLICY_VERSION} · POST_ATTEMPT_EXPLAIN]\n'
            f'Giải thích ngắn gọn bản chất và lời giải chuẩn sau khi phiên học môn {norm_subject} đã kết thúc (correct hoặc abandoned).\n'
            f'Quy tắc bộ môn: {subject_rule}'
        )
        allows_reveal = True
    else:
        raise ValueError(f'Unsupported EduSkillsMode: {mode}')

    return EduSkillsPromptSpec(
        mode=mode,
        policy_version=EDUSKILLS_POLICY_VERSION,
        subject_code=norm_subject,
        allows_final_answer_reveal=allows_reveal,
        system_instruction_vi=instruction,
    )


def sanitize_pre_reveal_hint(
    hint_vi: str | None,
    accepted_answers: list[str],
    *,
    fallback_hint_vi: str = 'Hãy kiểm tra lại công thức hoặc phép biến đổi ở bước đầu tiên.',
) -> str:
    """Đảm bảo gợi ý 1 bước trước khi kết thúc phiên không bao giờ làm lộ thẳng đáp án chuẩn."""
    if not hint_vi or not hint_vi.strip():
        return fallback_hint_vi

    candidate = hint_vi.strip()
    lower_candidate = candidate.lower()
    for ans in accepted_answers:
        clean_ans = str(ans).strip().lower()
        if not clean_ans:
            continue
        # Chặn trường hợp hint chứa nguyên biểu thức đáp án như "x = 8" hoặc đáp án dài > 2 ký tự
        if len(clean_ans) >= 3 and clean_ans in lower_candidate:
            return fallback_hint_vi
        if f'= {clean_ans}' in lower_candidate or f'={clean_ans}' in lower_candidate:
            return fallback_hint_vi
    return candidate


def extract_public_morning_card(question: Any) -> dict[str, Any]:
    """Trích xuất phần công khai của MorningCard cho `GET /v1/challenges/next` (ẩn hoàn toàn `revealVi`)."""
    rubric = getattr(question, 'rubric_json', None) or {}
    raw_card = rubric.get('morning_card') if isinstance(rubric, dict) else None
    q_id = getattr(question, 'id', 'unknown')
    q_rev = getattr(question, 'revision', 1)
    subject = getattr(question, 'subject_code', 'TOAN')
    topic = getattr(question, 'topic_id', 'general')

    if isinstance(raw_card, dict):
        card_id = str(raw_card.get('card_id') or f'mc_{q_id}')
        duration = int(raw_card.get('duration_target_seconds') or 8)
        outcome = str(
            raw_card.get('learning_outcome')
            or f'Ôn tập trọng tâm chủ đề {topic}'
        )
        setup_vi = str(
            raw_card.get('setup_vi')
            or 'Một tình huống ngắn buổi sáng cần bạn vận dụng đúng quy tắc cốt lõi.'
        )
        cliff_vi = str(
            raw_card.get('cliff_vi')
            or 'Bước biến đổi đầu tiên cần thực hiện là gì?'
        )
        static_fallback_vi = str(
            raw_card.get('static_fallback_vi')
            or f'{setup_vi} {cliff_vi}'
        )
        asset_id = str(raw_card.get('asset_id') or f'team-owned-{card_id}')
    else:
        card_id = f'mc_{q_id}'
        duration = 8
        outcome = f'Vận dụng kiến thức {subject} ({topic})'
        setup_vi = 'Khởi động buổi sáng bằng một tình huống gắn trực tiếp với câu hỏi hôm nay.'
        cliff_vi = 'Hãy suy nghĩ một bước lập luận ngắn trước khi chốt đáp án.'
        static_fallback_vi = f'{setup_vi} {cliff_vi}'
        asset_id = f'team-owned-{card_id}'

    return {
        'cardId': card_id,
        'questionId': q_id,
        'questionRevision': q_rev,
        'learningOutcome': outcome,
        'durationTargetSeconds': max(6, min(duration, 12)),
        'setupVi': setup_vi,
        'cliffVi': cliff_vi,
        'staticFallbackVi': static_fallback_vi,
        'assetId': asset_id,
        'skipAllowed': True,
        'eduSkillsPolicyVersion': EDUSKILLS_POLICY_VERSION,
    }


def extract_post_attempt_reveal_vi(question: Any) -> str:
    """Trả nội dung giải thích/đoạn kết (`POST_ATTEMPT_EXPLAIN`) CHỈ sau khi phiên đã `completed` hoặc `abandoned`."""
    rubric = getattr(question, 'rubric_json', None) or {}
    if isinstance(rubric, dict):
        raw_card = rubric.get('morning_card')
        if isinstance(raw_card, dict) and raw_card.get('reveal_vi'):
            return str(raw_card['reveal_vi']).strip()
        steps = rubric.get('steps')
        if isinstance(steps, list) and steps:
            joined = ' → '.join(str(s).strip() for s in steps if str(s).strip())
            if joined:
                return f'Các bước giải chuẩn: {joined}.'
    return 'Bạn đã hoàn tất lượt ôn sáng nay. Hãy xem lại các bước biến đổi cốt lõi của chủ đề này.'
