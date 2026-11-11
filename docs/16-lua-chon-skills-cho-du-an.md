# Skills của dự án MindClock

**Phạm vi cài:** `.agents/skills/` trong repo, không cài toàn máy. Codex hỗ trợ skill ở phạm vi dự án tại đường dẫn này theo [tài liệu OpenAI](https://developers.openai.com/api/reference/cli#installation). Nguồn kiểm tra/cập nhật ngày 11/11/2026. Skill là **hướng dẫn làm việc cho coding agent**, không phải thư viện runtime hay sự bảo đảm về chất lượng.

## 1. Đã cài

| Skill | Nguồn | Dùng khi | Lý do chọn |
| --- | --- | --- | --- |
| `frontend-design` | [Anthropic](https://github.com/anthropics/skills/tree/main/skills/frontend-design) | Thiết kế/hiệu chỉnh giao diện, đặc biệt bản demo và dashboard | Giúp giữ bản sắc “bình minh trên trang vở”, tránh UI mẫu chung |
| `flutter-custom-design-system` | [TheSimpleApp](https://github.com/TheSimpleApp/flutter-app-skills/tree/main/skills/flutter-custom-design-system) | Coding Flutter sau khi token UI được chốt | Token một nguồn, component có semantics, giữ thiết kế riêng |
| `api-design-principles` | [AAS catalog](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/api-design-principles) | Review `/v1`, error, version, pagination, auth | Giữ hợp đồng client–server rõ |
| `requirements-writing` | [AAS catalog](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/requirements-writing) | Viết/review acceptance, trace từ PRD tới test | Giảm yêu cầu mơ hồ; có file hướng dẫn và ghi nguồn/licence |
| `find-skills` | [Vercel Labs](https://github.com/vercel-labs/skills/tree/main/skills/find-skills) | Tìm skill cho việc mới sau này | Chỉ dùng để tìm, phải đọc nguồn trước khi cài |
| `ios-flows` | [sickn33](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/ios-flows) | Thiết kế và rà soát luồng iPhone | Chú ý điều hướng, quyền hệ thống, trạng thái iOS |
| `apple-hig-expert` | [alirezarezvani](https://github.com/alirezarezvani/claude-skills/tree/main/product-team/apple-hig-expert/skills/apple-hig-expert) | Audit UI iOS sau khi có màn thật | Kiểm tra tính nhất quán iOS và accessibility; phải đối chiếu HIG chính thức |
| `game-design` | [sickn33](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/game-development/game-design) | Thiết kế rank, trận, vòng thưởng | Giúp ghi vòng lặp và điều kiện cân bằng có thể test |
| `game-art` | [sickn33](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/game-development/game-art) | Brief nhân vật, asset và kiểm tra nhất quán | Cần cho character bible và bàn giao họa sĩ |
| `product-discovery` | [alirezarezvani](https://github.com/alirezarezvani/claude-skills/tree/main/product-team/skills/product-discovery) | Kiểm chứng giả thuyết với người học | Tránh coi điểm hấp dẫn trên pitch là giá trị đã được chứng minh |
| `generate2dsprite` + `generate2dmedia` | [Agent Sprite Forge](https://github.com/0x0funky/agent-sprite-forge) | Tạo master 2D, frame/FX và kiểm tra tuyến tạo media | Asset gốc cho Cú Mực/Cáo Nắng/Rồng Giấy; không phải runtime Flutter |
| `video2dsprite` + `codeart2d` | [Agent Sprite Forge](https://github.com/0x0funky/agent-sprite-forge) | Chỉ khi cần thêm frame hoặc vẽ bằng mã theo yêu cầu | Giữ cùng bộ phụ thuộc nội bộ; **không tự chạy video/API trả phí** |
| `generate2dmap` | [Agent Sprite Forge](https://github.com/0x0funky/agent-sprite-forge) | Để dành nếu sau này có bản đồ 2D | Cài cùng bộ vì script tham chiếu nhau; **không cần cho MVP** |
| `flutter-apply-architecture-best-practices` | [Flutter team](https://github.com/flutter/agent-plugins/tree/main/skills/flutter-apply-architecture-best-practices) | Tách UI, logic, dữ liệu khi bắt đầu app | Chỉ dùng khi phù hợp kiến trúc MindClock; không thay spec báo thức offline |
| `flutter-add-widget-test` | [Flutter team](https://github.com/flutter/agent-plugins/tree/main/skills/flutter-add-widget-test) | Test thanh HP, kỹ năng, ví và trạng thái lớn chữ | Bổ sung test theo rủi ro, không viết test chỉ lặp implementation |

Các skill đã được cài từ thư mục cụ thể bằng công cụ cài skill vào `.agents/skills/`. Bộ Agent Sprite Forge gồm 5 thư mục cần giữ cùng cấp vì có tham chiếu script; bản skill đã cài **không cài Python packages, ffmpeg, API key hoặc tạo ảnh**. Khi có phiên coding mới, agent có thể đọc skill tương ứng; `AGENTS.md` và đặc tả MindClock vẫn là nguồn quy tắc dự án. Không tự chạy script/CLI phụ thuộc chỉ vì skill có nhắc đến. Asset sinh từ công cụ có điều kiện bản quyền riêng với mã MIT của repo; xem [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md).

## 2. Đã xem nhưng chưa cài

| Skill/bộ | Quyết định | Khi nào xem lại |
| --- | --- | --- |
| `vercel-react-best-practices` | Chưa phù hợp Flutter Android MVP | Khi dashboard web dùng React/Next.js. [Nguồn](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices) |
| `web-design-guidelines` | Dành cho audit UI web, chưa có web code | Khi làm dashboard giáo viên/phụ huynh. [Nguồn](https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines) |
| `agent-browser` | Browser QA hữu ích cho web, cần cài CLI riêng | Khi có web app cần test tương tác. [Nguồn](https://github.com/vercel-labs/agent-browser/tree/main/skills/agent-browser) |
| `browser-use` (lặp 2 lần trong danh sách) | Trùng mục đích browser QA; không cần hai công cụ cùng lúc | Chọn một sau khi có web UI. [Nguồn](https://github.com/browser-use/browser-use/tree/main/skills/browser-use) |
| Toàn bộ `sickn33/agentic-awesome-skills` | Là catalog hàng nghìn skill, không đưa cả repo vào dự án | Chỉ chọn từng skill đã đọc và hợp task. [Nguồn](https://github.com/sickn33/agentic-awesome-skills) |
| Toàn bộ `alirezarezvani/claude-skills` | Là bộ nhiều lĩnh vực, không đưa cả repo vào dự án | Chỉ chọn từng skill đã đọc và hợp task. [Nguồn](https://github.com/alirezarezvani/claude-skills) |
| `ios-developer` trong catalog | Hướng dẫn có phần tập trung iOS 18, chưa phản ánh AlarmKit iOS 26 | Xem lại khi tài liệu được cập nhật và có task Swift cụ thể. [Nguồn](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/ios-developer) |
| `senior-computer-vision` | Chủ yếu xử lý CV truyền thống/YOLO, chưa hợp chấm lời giải bằng Gemini và rubric | Chỉ dùng nếu đội tự huấn luyện OCR/CV riêng. [Nguồn](https://github.com/alirezarezvani/claude-skills) |
| `flutter-expert`, `fastapi-pro`, `firebase` trong catalog | Chưa cài vì hướng dẫn rất rộng; task phải chọn phần hợp Flutter/FastAPI/PostgreSQL và Firebase Authentication, không dùng Firestore nghiệp vụ | Chọn riêng khi task coding cụ thể cần. [Flutter](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/flutter-expert), [FastAPI](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/fastapi-pro), [Firebase](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/firebase) |
| `flutter-performance` từ kết quả tìm kiếm | Không thấy đường dẫn skill tương ứng trong repo `flutter/agent-plugins` hiện tại; không cài chỉ theo kết quả tìm kiếm | Khi có mã nguồn và tài liệu đã xác minh; ưu tiên đo Flutter DevTools/máy thật theo docs/27 |
| Skill kinh tế game bên thứ ba | Kết quả tìm có ít lượt cài và chưa có bằng chứng phù hợp giáo dục/trẻ vị thành niên; `game-design` hiện có đủ cho bước docs | Xem lại khi có số liệu cân bằng trận/coin và task mô phỏng cụ thể |

## 3. Quy tắc thêm skill mới

1. Bắt đầu từ **việc cần làm** (Flutter alarm, API contract, QA, dashboard), không từ danh sách skill phổ biến.
2. Kiểm tra nguồn gốc, `SKILL.md`, file tham chiếu/script, licence, yêu cầu cài binary/API key và tác động lên repo.
3. Chọn tối đa một skill chính và một skill bổ trợ cho một task; nếu trùng chức năng, giữ một.
4. Cài đúng phạm vi dự án `.agents/skills/`, ghi nguồn và mục đích vào bảng này; không cài global nếu không được yêu cầu.
5. Skill không được thay thế quy tắc MindClock về báo thức an toàn, dữ liệu trẻ em, chấm AI và không lưu ảnh mặc định.

## 4. Cách dùng theo vai coding

- **Product/UX:** `product-discovery` để kiểm chứng giả thuyết, `requirements-writing` để chốt acceptance; `frontend-design` cho hướng mỹ thuật. Với iPhone dùng `ios-flows`/`apple-hig-expert` và đối chiếu [iOS spec](20-ios-demo-va-phat-hanh.md).
- **Mobile Flutter:** `flutter-custom-design-system` khi code UI; dùng [kiến trúc](06-kien-truc-va-du-lieu.md) và [iOS spec](20-ios-demo-va-phat-hanh.md) cho alarm native, không suy từ skill UI ra hành vi OS.
- **Backend:** `api-design-principles` khi đổi contract; dùng tài liệu chính thức Firebase/Gemini khi triển khai từng SDK.
- **Game/Art:** `game-design` cho [luật HP/RP/coin](37-kinh-te-rank-va-nhan-vat-2d.md); `game-art` cho [linh thú](22-nhan-vat-rpg.md); `generate2dsprite` cho asset 2D và `codeart2d` khi chủ động chọn vẽ bằng mã. Không dùng `generate2dmap` cho MVP. Luật điểm/quyền riêng tư luôn theo đặc tả dự án.
- **QA:** test plan của repo là nguồn chuẩn; `find-skills` chỉ khi cần công cụ mới có lý do rõ.

