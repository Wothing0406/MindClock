# Kế hoạch và kết quả kiểm thử T003

| ID | AC | Kịch bản | Kết quả mong đợi | Cách chạy | Kết quả thực |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | RP 0/139/159/179/199/219/1199; coin tổng 60; HP ví dụ docs/37 | Đúng bậc/công thức; không coin âm | Python kiểm tra ví dụ + rà docs/37 | **Đạt 11/11/2026**; công thức RP/coin đúng; HP ví dụ kiểm tay theo công thức |
| TC-02 | AC-02 | Kiểm tra 5 skill Sprite Forge + 2 skill Flutter, art docs mới | Có SKILL.md trong project, asset 2D | PowerShell `Test-Path` bảy skill + `rg` 3D | **Đạt 11/11/2026**; 7/7 file hiện diện; docs hiện hành trỏ sprite 2D |
| TC-03 | AC-03 | Parse registry; kiểm tra trạng thái ba nguồn | JSON hợp lệ, `metadata_only`, quyền nêu rõ | `python -m json.tool data/sources/registry.json`; Python assert | **Đạt 11/11/2026**; 3/3 chỉ metadata; không có corpus được nạp |
| TC-04 | AC-04 | Kiểm tra task, link nội bộ, diff đã stage | Không thiếu link/file, không lỗi khoảng trắng | `python scripts/check_task_records.py`, Python local links, `git diff --cached --check` | **Đạt 11/11/2026**; Task records OK, Local links OK; staged diff check exit 0 sau khi dọn whitespace skill nguồn |

Không có test runtime app vì T003 chỉ sửa docs, registry metadata và cài hướng dẫn skill. Test trận/đồng bộ/coin ledger là acceptance cho task coding sau này. Không cài package Python/ffmpeg hoặc chạy sinh ảnh, nên chưa xác nhận các pipeline tạo sprite hoạt động trên máy này.
