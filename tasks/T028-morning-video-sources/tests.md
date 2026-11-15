# Kiểm chứng T028

| ID | AC | Cách kiểm | Kết quả |
| --- | --- | --- | --- |
| TC-01 | AC-01 | Review thư viện cảnh/PRD/Android/MEDIA-01 | Đạt: 8 môn có cảnh/câu minh họa; `Mở câu` dừng âm trước cảnh; bỏ cảnh vẫn vào câu. Đây là review tài liệu, chưa test Android runtime. |
| TC-02 | AC-02 | So nguồn chính thức và registry/reviewer/MEDIA-02 | Đạt: nguồn tự tạo/stock phân cấp; giấy phép từng asset, reviewer/retire; link clip chỉ là ứng viên. Chưa có clip thực tế được phê duyệt. |
| TC-03 | AC-03 | Review fallback/Reduce Motion/offline/MEDIA-03 | Đạt trên tài liệu: fallback chữ/poster, không chặn câu/Dừng; chưa đo trên máy thật. |
| TC-04 | AC-04 | Link/task/diff/staged file review | Đạt: `check_docs_links.py` PASS 365 Markdown, `check_task_records.py` PASS, `git diff --cached --check` PASS; 20 staged file đều là AGENTS/README/docs/T028, không có WIP app. |

Không xác nhận clip bên ngoài đã được duyệt quyền chỉ bằng trang license chung. Không chạy Android runtime trong task docs.
