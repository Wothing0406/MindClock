# Đặc tả kỹ thuật T040 (Spec)

## Tiêu chuẩn chấp nhận (Acceptance Criteria)

- **AC-01 (Số thập phân):** Hệ thống nhận diện tương đương giữa dấu phẩy `,` và dấu chấm `.`. Ví dụ `0,5` == `0.5`, `3,14` == `3.14`, `-2,5` == `-2.5`. Bỏ các số 0 thừa ở đuôi số thập phân (`2.50` == `2.5`).
- **AC-02 (Phân số & LaTeX):** Hệ thống quy đổi và so khớp phân số `a/b` hoặc `\frac{a}{b}` với số thập phân tương ứng (với sai số epsilon $\le 10^{-6}$). Ví dụ `3/4` == `0.75` == `0,75` == `\frac{3}{4}`. Hỗ trợ rút gọn phân số (`6/8` == `3/4`).
- **AC-03 (Biến số & Phương trình):** Học sinh nhập `x = 8`, `x=8`, `X = 8`, `8` hoặc `v = 10 m/s`, `I = 2A` đều được bóc tách phần giá trị và đơn vị tương đương với `accepted_answers` của câu hỏi.
- **AC-04 (Đơn vị đo lường):** 
  - Tách bạch và chuẩn hóa các đơn vị phổ biến THPT: độ dài (`m`, `cm`, `mm`, `km`), khối lượng (`kg`, `g`), thời gian (`s`, `giây`, `phút`, `h`), vận tốc (`m/s`, `km/h`), gia tốc (`m/s^2`), điện học (`A`, `mA`, `V`, `mV`, `ôm`, `ohm`, `Ω`), năng lượng (`J`, `kJ`, `cal`), công suất (`W`, `kW`), góc (`rad`, `°`, `độ`), nhiệt độ (`°C`), phần trăm (`%`).
  - Cho phép viết liền (`2A`, `10m/s`) hoặc có khoảng trắng (`2 A`, `10 m/s`).
  - Nếu đề bài đã có sẵn đơn vị trong câu hỏi và accepted có đơn vị, học sinh chỉ nhập phần số (hoặc ngược lại) vẫn được chấp nhận đúng. Nếu học sinh nhập sai đơn vị (ví dụ `2V` thay vì `2A`) thì tính sai.
- **AC-05 (Bảo lưu tính an toàn & Không crash):** Với các câu hỏi trắc nghiệm chữ (A, B, C, D) hoặc văn học / ngoại ngữ (chuỗi ký tự thuần), module giữ nguyên cơ chế so khớp văn bản không làm sai lệch kết quả.
