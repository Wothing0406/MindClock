# Skills của dự án MindClock

**Phạm vi cài:** `.agents/skills/` trong repo, không cài toàn máy. Codex hỗ trợ skill ở phạm vi dự án tại đường dẫn này theo [tài liệu OpenAI](https://developers.openai.com/api/reference/cli#installation). Nguồn đã kiểm tra ngày 10/11/2026. Skill là **hướng dẫn làm việc cho coding agent**, không phải thư viện runtime hay sự bảo đảm về chất lượng.

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

Các skill đã được cài từ thư mục cụ thể bằng công cụ cài skill vào `.agents/skills/`. Khi có phiên coding mới, agent có thể đọc skill tương ứng; `AGENTS.md` và đặc tả MindClock vẫn là nguồn quy tắc dự án. Không tự chạy script/CLI phụ thuộc chỉ vì skill có nhắc đến.

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
| `flutter-expert`, `fastapi-pro`, `firebase` trong catalog | Chưa cài vì hướng dẫn rất rộng, một số nội dung không khớp stack Firestore/FastAPI hiện tại hoặc đòi rà soát bảo mật kỹ | Chọn riêng khi task coding cụ thể cần. [Flutter](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/flutter-expert), [FastAPI](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/fastapi-pro), [Firebase](https://github.com/sickn33/agentic-awesome-skills/tree/main/skills/firebase) |

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
- **Game/Art:** `game-design` cho luật [đấu trường](21-dau-truong-xep-hang.md); `game-art` cho [linh thú](22-nhan-vat-rpg.md), còn quyết định điểm/riêng tư phải theo đặc tả dự án.
- **QA:** test plan của repo là nguồn chuẩn; `find-skills` chỉ khi cần công cụ mới có lý do rõ.

