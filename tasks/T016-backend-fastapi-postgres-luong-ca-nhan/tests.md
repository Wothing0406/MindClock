# Kế hoạch và kết quả kiểm thử T016

| ID | Liên kết AC | Kịch bản kiểm thử | Kết quả mong đợi | Lệnh dự kiến | Kết quả thực |
| --- | --- | --- | --- | --- | --- |
| `BE-TC-01` | `BE-AC-01` | Gọi `/v1/me`, `/v1/sessions/{id}` với token hết hạn, token sai, và token User A đọc User B | `401` cho token lỗi/hết hạn; `403` cho User A đọc tài nguyên User B | `pytest tests/test_auth_and_isolation.py` | Chưa chạy (task `planned`) |
| `BE-TC-02` | `BE-AC-02` | Chạy Alembic migration trên DB PostgreSQL trống và rollback | Schema khớp `docs/28 §4`, mọi unique constraint hoạt động | `pytest tests/test_migrations_postgres.py` | Chưa chạy (task `planned`) |
| `BE-TC-03` | `BE-AC-04` | Gọi `GET /v1/challenges/next` với câu `published` và kiểm tra DB có câu `draft`/`retired` | Không trả `draft`/`retired`; response tuyệt đối không chứa `answerSpec`/`rubric` | `pytest tests/test_challenges_contract.py` | Chưa chạy (task `planned`) |
| `BE-TC-04` | `BE-AC-05` | Gửi đồng thời 2 request `POST /v1/sessions/{id}/answers` cùng `Idempotency-Key`, và 1 request cùng key nhưng payload khác | Hai request giống nhau trả cùng `attemptId` và chỉ ghi 1 dòng `xp_ledger`; payload khác trả `409 IDEMPOTENCY_CONFLICT` | `pytest tests/test_idempotency_and_xp_postgres.py` | Chưa chạy (task `planned`) |
| `BE-TC-05` | `BE-AC-06` | Upload > 5MB, sai magic bytes, Gemini timeout > 12s, exception giữa chừng | `413` cho ảnh quá lớn, `415` sai MIME; timeout/exception trả `uncertain`, ảnh tạm bị xóa 100%, log không chứa ảnh/token | `pytest tests/test_attempts_upload_and_gemini.py` | Chưa chạy (task `planned`) |
| `BE-TC-06` | `BE-AC-07` | Chế độ thử thách sai rõ lần 1, lần 2, `uncertain`, rồi sai rõ lần 3 | Lần 1–2 `hint=null`, `firstIssue=null`; `uncertain` không tăng lượt sai; lần 3 mới trả gợi ý phương pháp | `pytest tests/test_challenge_hint_policy.py` | Chưa chạy (task `planned`) |
| `BE-TC-07` | `BE-AC-03` | `DELETE /v1/me` retry cùng `Idempotency-Key` và `GET /v1/me/delete-status` | Trả `202` idempotent, thu hồi quyền/ẩn dữ liệu ngay | `pytest tests/test_account_deletion.py` | Chưa chạy (task `planned`) |
