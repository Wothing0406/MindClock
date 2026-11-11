# Kế hoạch và kết quả kiểm thử T004

| ID | AC | Kịch bản | Kết quả mong đợi | Cách chạy | Kết quả thực |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Staging/manifest/gitignore | raw không lên Git; hash/count/provenance rõ | `python scripts/research_inventory.py`; assertions; `git check-ignore`; `git ls-files --others --exclude-standard data/research scripts` | **Pass 11/11/2026:** 406 JSON/17.054 mục VNHSGE, 3 JSONL/10.880 VMLU, 0 parse error/ID trùng; 9.833 test thiếu đáp án; raw/pycache bị ignore, chỉ README/manifest/script hiện untracked trước commit |
| TC-02 | AC-02 | Contract 3 kết quả, offline, ảnh mờ, lời giải tương đương | không phạt, đường chữ, dừng khẩn cấp | Review docs/07/14/31/39 và local link check | **Pass tài liệu 11/11/2026:** trường bài giải/rubric, `uncertain`, ranked void, offline ungraded và đường chữ nhất quán; chưa có app để chạy hành vi |
| TC-03 | AC-03 | Ví dụ heal, hút khi bị chặn, choáng và đồng thời | HP trong [0,60], stun vẫn trả lời | Review công thức/ví dụ docs/40 và SQL docs/28/35/37 | **Pass tài liệu 11/11/2026:** ví dụ 52/60, hồi 30→42, choáng chỉ khóa thẻ riêng; chưa playtest cân bằng |
| TC-04 | AC-04 | Hồ sơ mới, thiếu lịch, hai đối thủ khác mức | tăng khó từ từ, trận cùng đề, AI không tự đổi giờ | Review docs/32/34/35/39 | **Pass tài liệu 11/11/2026:** 3 phiên đầu band 1; 07:00−25−30−10=05:55; trận cùng revision/rubric; chưa chạy thiết bị |
| TC-05 | AC-05 | Reduce Motion, asset lỗi, nội dung vui | fallback tĩnh/chữ, không xúc phạm | Review docs/22/37/40 | **Pass tài liệu 11/11/2026:** 4 nhân vật, 3 map, FX có fallback, lời thoại mẫu; chưa có asset thật |

## Cổng theo rủi ro

Kiểm tra bổ sung: `python -m py_compile scripts/research_inventory.py` → pass; JSON registry/manifest parse → pass; local Markdown links → 0 thiếu; `git diff --check` → pass sau sửa newline. `python scripts/check_task_records.py` lần đầu báo thiếu `worklog.md`/`handoff.md` và terminal cp1252 không in được tiếng Việt; chạy lại với `PYTHONIOENCODING=utf-8` sau khi tạo hai file. Chưa có app/thiết bị nên không tuyên bố test báo thức/PvP thực tế. Khi coding, cần test người chấm độc lập, hai máy/mạng, retry/void/rating, thiết bị Android thật và dữ liệu trẻ em.
