# Nhật ký T009

| Vòng/ngày | Tái hiện và nguyên nhân | Sửa | Test lại/kết luận |
| --- | --- | --- | --- |
| 1 / 12-11-2026 | Ảnh người dùng: actor trái/phải khác cỡ, cắt chân; ảnh ghép đầu tiên 170 px vẫn quá nhỏ. | Chuẩn hóa mọi action 512²/root `(256,478)`, render 240²/root sân y=350; native facing từng tướng. | Chân cùng baseline, không chạm mép. Kết luận hướng nhìn khi ấy bỏ sót Hàn Bối Pháp; xem vòng 6. |
| 2 / 12-11-2026 | FX bitmap từ sheet còn nền màu, trông như một mảng bay và lặp chung. | 9 SVG projectile riêng từng tướng/chiêu, 3 status FX SVG; event bay từ attacker tới defender, self FX riêng. | `test_arena_renderer.js` đạt hai hướng; `check_game_assets.py` đạt 9 SVG unique. |
| 3 / 12-11-2026 | QA báo thiếu `effects/runtime/*.svg`: script tạo sai `demo/assets/effects`. | Sửa path từ `ROOT.parent.parent` thành `ROOT.parent`, xóa folder thừa. | QA chạy lại đạt. |
| 4 / 12-11-2026 | QA DOM báo thiếu `roster` ID trong HTML. | Thêm `id=roster`. | QA chạy lại đạt. |
| 5 / 12-11-2026 | Docs/49 và README còn trỏ layout T008; T008 clip/video dễ bị hiểu nhầm là motion cuối. | Viết docs/49–51, README, dọn `demo/assets/arena` và exporter cũ; ghi rõ frame sequence/art review. | `check_docs_links.py`, `check_task_records.py` đạt; không còn ref runtime cũ trong demo. |
| 6 / 13-11-2026 | Ảnh người dùng cho thấy Hàn Bối Pháp ở slot trái quay ra ngoài. `native_facing` trong renderer, builder, manifest, preview và QA ghi `left`, nhưng sprite nguồn thực tế nhìn phải. | Sửa native facing riêng Hàn Bối Pháp thành `right`; cập nhật test hai slot và dựng lại preview. | Hai ảnh ghép cho thấy Hàn Bối Pháp nhìn về đối thủ ở cả hai slot; unit/asset QA đạt. Chờ thao tác Android thật. |

Giới hạn: browser automation trong phiên trước không mở được `localhost` hoặc `file:`; chưa có thao tác Chrome Android thật, nên task ở `verifying` dù script/ảnh tĩnh đạt.
