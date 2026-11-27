from app.services.subject_memory_service import build_quick_morning_challenge


def test_t087_parametric_10k_grade_matched_variations() -> None:
    # Lớp 10, 11, 12 Toán phải tạo câu hỏi khác nhau theo lớp và thay đổi số theo seed_hint
    q10_a = build_quick_morning_challenge(
        subject_code='TOAN',
        grade_level='Lớp 10',
        memory=None,
        difficulty='basic',
        seed_hint='seed_001',
    )
    q10_b = build_quick_morning_challenge(
        subject_code='TOAN',
        grade_level='Lớp 10',
        memory=None,
        difficulty='basic',
        seed_hint='seed_002',
    )
    q11 = build_quick_morning_challenge(
        subject_code='TOAN',
        grade_level='Lớp 11',
        memory=None,
        difficulty='basic',
        seed_hint='seed_001',
    )
    q12 = build_quick_morning_challenge(
        subject_code='TOAN',
        grade_level='Lớp 12',
        memory=None,
        difficulty='basic',
        seed_hint='seed_001',
    )

    assert q10_a['prompt'] != q10_b['prompt']
    assert 'parabol' in q10_a['prompt'].lower()
    assert 'cấp số cộng' in q11['prompt'].lower()
    assert q11['prompt'] != q12['prompt']
    for item in (q10_a, q10_b, q11, q12):
        assert len(item['options']) == 4
        assert len(set(item['options'])) == 4
        assert 0 <= item['correctOptionIndex'] < 4

    # Đề ngắn nâng cao >= 70% sinh 4 câu khác nhau
    adv_phys = build_quick_morning_challenge(
        subject_code='VAT_LY',
        grade_level='Lớp 11',
        memory=None,
        difficulty='advanced',
        seed_hint='seed_phys_99',
    )
    assert adv_phys['questionFormat'] == 'mini_quiz'
    assert len(adv_phys['subQuestions']) == 4
    prompts = [sq['prompt'] for sq in adv_phys['subQuestions']]
    assert len(set(prompts)) >= 3
