# Kiểm thử

TC01 ↔ AC01: liên tiếp/trùng ngày/thiếu ngày/timezone/tương lai.
TC02 ↔ AC02: ngưỡng level 0/99/100/399/400, không ghi ledger.
TC03 ↔ AC03: API A/B và phân trang; auth bắt buộc.
20/11/2026 Windows: pytest tests/test_progression.py -q PASS 4; pytest tests/test_api_v1.py -q PASS 19 (SQLite TestClient, không chứng minh PostgreSQL). Lượt đầu lỗi import helper test đã sửa; lần chạy hạn chế treo ở TestClient đã dừng, chạy môi trường đầy đủ đạt.

Flutter analyze --no-pub PASS; flutter test --no-pub test/personal_flow_real_service_test.dart PASS 6 (harness, chưa hai điện thoại thật). Docs links PASS 610 Markdown; task records PASS; diff check PASS với cảnh báo LF/CRLF.

Chưa kiểm migration/transaction PostgreSQL, timezone-change policy bền vững, đồng bộ hai thiết bị, profile UI đầy đủ hay thưởng pet. Không mở ranked.

Bổ sung từ T067: `scripts/run_progression_postgres.py` PASS 1 trên PostgreSQL Docker, DB UUID test riêng với Alembic head, A/B, hai client, ledger unique và lịch sử/summary. PostgreSQL không còn chưa kiểm ở lát tiến độ này; timezone snapshot/system grace và hai điện thoại vẫn là phần sau.
