# Kiểm tra T041

| ID | AC | Kịch bản | Mong đợi | Cách chạy | Kết quả 2026-11-17 |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Soát luồng phòng và PRD | Không bắt chọn môn lại | Rà diff tài liệu | Đạt về tài liệu |
| TC-02 | AC-02 | Soát `deep` ở product và engineering | Silent ở solo và AI | Rà diff tài liệu | Đạt về tài liệu |
| TC-03 | AC-03 | Soát rule, cap, offline, retry | Có ca nghiệm thu rõ | Rà diff tài liệu | Đạt về tài liệu |
| TC-04 | AC-01..03 | Liên kết và task records | Không lỗi | `python scripts/check_docs_links.py`; `python scripts/check_task_records.py`; `git diff --check` | Đạt; chạy lại sau thêm task |

## Giới hạn

Chưa có code nên không tuyên bố EXP, âm thanh hay AI đã hoạt động trên app. Test Android/backend thuộc task triển khai R5.
