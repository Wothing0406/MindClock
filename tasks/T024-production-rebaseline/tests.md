# Kế hoạch và kết quả kiểm thử T024

| ID | AC | Kịch bản | Kỳ vọng | Cách chạy | Kết quả |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Kiểm tra hai thư mục, manifest, script pipeline | Không có hai thư mục; asset QA đạt ở vị trí mới | PowerShell Test-Path; `python scripts/build_game_assets.py`; `python scripts/check_game_assets.py`; `python scripts/render_stage_previews.py` | **Đạt 15/11:** hai path False, 228/228 file art được chuyển; builder/preview/QA exit 0. |
| TC-02 | AC-02 | Tìm ngôn ngữ “web product”, link chết và đường chạy | README/docs index/AGENTS đúng; link docs không gãy | đọc diff; `python scripts/check_docs_links.py` | **Đạt 15/11:** 60 file docs link hợp lệ; README/index/AGENTS ưu tiên Android/API. Docs cũ được đánh dấu lịch sử. |
| TC-03 | AC-03 | Review roadmap production, mapping mã hiện có → cổng test | Từng lát cắt có đầu ra và điều kiện mở | review `docs/56`, `docs/57`, `README.md` | **Đạt về tài liệu 15/11:** P0.0–P3 có hành vi/AC/test; quy tắc file/AI coding rõ. Chưa phải sản phẩm đã qua cổng. |
| TC-04 | AC-04 | So `git status` trước/sau và test API/asset | WIP T022/T023 giữ nguyên; test liên quan đạt | `git status`, `pytest`, task checker, diff | **Một phần 15/11:** WIP `services/api`, T022/T023, `mp3/`, launcher vẫn còn; asset/task checker đạt. `pytest --collect-only -q` thu 14 tests; `pytest -q` treo >90 giây, ca health riêng cũng treo trong TestClient, đã dừng; chưa có kết quả API runtime. `git diff --check` toàn repo báo hai dòng whitespace trong `services/api/app/demo_ui.py` thuộc WIP T022, diff chỉ phạm vi T024 exit 0. |

## Cổng theo rủi ro

Không gọi test tĩnh là bằng chứng release. Flutter compile, Android máy thật, PostgreSQL, Firebase và Gemini live chưa thuộc nghiệm thu task tái cấu trúc; ghi chúng vào roadmap với cổng riêng.
