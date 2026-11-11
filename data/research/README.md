# Khu nghiên cứu nguồn đề (chỉ ở máy)

`raw/`, `staging/` và `private-reports/` bị Git bỏ qua. Nội dung VNHSGE/VMLU trong các thư mục này chỉ để xem cấu trúc, kiểm tra chất lượng và thử bộ chấm nội bộ; **không phải ngân hàng câu đã duyệt của ứng dụng**. Không sao chép câu/ảnh/đáp án vào docs, fixture public, app hoặc demo khi quyền tái sử dụng từng mục chưa rõ. Không dùng ViMMRC 2.0 khi chưa có thỏa thuận truy cập.

`data/sources/registry.json` ghi nguồn và trạng thái; `research-manifest.json` ghi commit/hash/count file thực tế sau tải, không chứa văn bản câu. Bản đã tải trên máy tạo manifest: VNHSGE 406 tệp JSON/17.054 mục; mirror VMLU 3 JSONL/10.880 mục. VMLU `test.jsonl` thiếu trường đáp án ở 9.833 mục. Đây là **số mục parse được**, không phải số câu được duyệt. Xóa raw bằng cách xóa thư mục local nếu không còn nghiên cứu. Khi chạy thử AI trên corpus, không gửi câu nguồn tới dịch vụ bên ngoài trước khi kiểm tra điều khoản nguồn và chính sách dữ liệu.

## Tái tạo trên máy thành viên (nếu được phép nghiên cứu nguồn)

Từ gốc repo, tải VNHSGE vào `data/research/raw/vnhsge` bằng sparse clone ở commit ghi trong manifest; chỉ lấy `Dataset/VNHSGE-V/JSON format/**/*.json`, bỏ ảnh/Word. Tải mirror VMLU `https://huggingface.co/datasets/tridm/VMLU` vào `data/research/raw/vmlu-hf-mirror`, checkout commit trong manifest. Sau đó chạy `python scripts/research_inventory.py` và đối chiếu `sha256_file_set`; nếu hash khác, không trộn số liệu với bản này. Cần mạng khi clone, script inventory chỉ dùng thư viện Python chuẩn và không gửi dữ liệu đi đâu. Không copy thư mục raw sang Git hoặc APK.

Đường nhập sản phẩm tách riêng: `raw → kiểm tra quyền từng item → kiểm tra chương trình, đáp án, rubric trình bày → người dạy duyệt → published`. Không có thao tác “import tất cả” từ khu này.
