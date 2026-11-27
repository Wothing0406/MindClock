from __future__ import annotations

from datetime import date, datetime, timezone
import hashlib
import random
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import SubjectMemory, TimetableSlot, User
from app.services.eduskills_adapter import normalize_subject_code

_WEEKDAY_LABELS_VI = {
    1: 'Thứ 2',
    2: 'Thứ 3',
    3: 'Thứ 4',
    4: 'Thứ 5',
    5: 'Thứ 6',
    6: 'Thứ 7',
    7: 'Chủ nhật',
}

# Tiến độ chuẩn GDPT 2018 theo giai đoạn tuần học (tuần 1..35) cho các môn THPT.
_CURRICULUM_TOPICS: dict[str, dict[str, list[tuple[str, str]]]] = {
    'TOAN': {
        'Lớp 10': [
            ('Chương I: Mệnh đề và Tập hợp', 'Mệnh đề & Phép toán tập hợp'),
            ('Chương III: Hệ thức lượng trong tam giác', 'Định lý Côsin & Sin'),
            ('Chương VI: Hàm số, đồ thị và ứng dụng', 'Hàm số bậc hai & Parabol'),
            ('Chương IX: Tính xác suất theo định nghĩa cổ điển', 'Tổ hợp & Xác suất'),
        ],
        'Lớp 11': [
            ('Chương I: Hàm số lượng giác & Phương trình', 'Giá trị lượng giác & Công thức cộng'),
            ('Chương II: Dãy số, Cấp số cộng & Cấp số nhân', 'Số hạng tổng quát & Tổng CSC/CSN'),
            ('Chương V: Giới hạn & Hàm số liên tục', 'Giới hạn dãy số & Hàm số'),
            ('Chương IX: Đạo hàm', 'Quy tắc tính đạo hàm & Tiếp tuyến'),
        ],
        'Lớp 12': [
            ('Chương I: Ứng dụng đạo hàm khảo sát hàm số', 'Tính đơn điệu & Cực trị hàm số'),
            ('Chương II: Vectơ & Hệ tọa độ trong không gian', 'Tọa độ Oxyz'),
            ('Chương IV: Nguyên hàm & Tích phân', 'Nguyên hàm cơ bản & Tích phân'),
            ('Chương VI: Xác suất có điều kiện', 'Công thức Bayes & Xác suất'),
        ],
    },
    'NGU_VAN': {
        'Lớp 10': [
            ('Thần thoại và Sử thi', 'Đặc trưng sử thi & Chính tả tiếng Việt'),
            ('Thơ đường luật & Chèo/Tuồng', 'Dùng từ Hán Việt chuẩn nghĩa'),
            ('Văn nghị luận xã hội', 'Lập luận & Phép liên kết câu'),
            ('Truyện ngắn hiện đại', 'Phân biệt lỗi dùng từ & Ngữ pháp'),
        ],
        'Lớp 11': [
            ('Truyện thơ & Truyện ngắn', 'Nghệ thuật tự sự & Biện pháp tu từ'),
            ('Thơ tượng trưng & Văn bản thông tin', 'Nghĩa hàm ẩn & Chính tả chuẩn'),
            ('Kịch & Nghị luận văn học', 'Thao tác lập luận phân tích'),
            ('Ôn tập đọc hiểu & Tiếng Việt', 'Sửa lỗi câu & Diễn đạt logic'),
        ],
        'Lớp 12': [
            ('Nghệ thuật truyện ngắn & Tiểu thuyết', 'Ngôi kể, điểm nhìn & Từ vựng'),
            ('Thơ hiện đại & Hài kịch', 'Hình tượng thơ & Ngữ điệu'),
            ('Nghị luận xã hội về tuổi trẻ', 'Mở bài/Kết bài & Chính tả học thuật'),
            ('Tổng ôn đọc hiểu GDPT 2018', 'Phân biệt nghĩa từ & Biện pháp tu từ'),
        ],
    },
    'TIENG_ANH': {
        'Lớp 10': [
            ('Unit 1–2: Family Life & Humans and Environment', 'Present Simple vs Continuous & Collocations'),
            ('Unit 3–4: Music & For a Better Community', 'Compound Sentences & Past Continuous'),
            ('Unit 5–6: Inventions & Gender Equality', 'Present Perfect & Passive Voice'),
            ('Unit 7–10: Viet Nam & Ecotourism', 'Relative Clauses & Conditional Type 1-2'),
        ],
        'Lớp 11': [
            ('Unit 1–2: A Long and Healthy Life & Generation Gap', 'Past Simple vs Present Perfect & Modals'),
            ('Unit 3–4: Cities of the Future & ASEAN', 'Stative Verbs & Gerunds'),
            ('Unit 5–6: Global Warming & Preserving Heritage', 'Participle Clauses & To-infinitive'),
            ('Unit 7–10: Education & Ecosystems', 'Perfect Gerunds & Cleft Sentences'),
        ],
        'Lớp 12': [
            ('Unit 1–2: Life Stories & Multicultural World', 'Past Continuous & Articles'),
            ('Unit 3–4: Green Living & Urbanisation', 'Verbs with Prepositions & Present Perfect'),
            ('Unit 5–6: World of Work & AI', 'Complex Sentences & Active/Passive Causative'),
            ('Unit 7–10: Media, Wildlife & Lifelong Learning', 'Adverbial Clauses & Reported Speech'),
        ],
    },
    'VAT_LY': {
        'Lớp 10': [
            ('Động học chất điểm', 'Vận tốc, Gia tốc & Chuyển động biến đổi đều'),
            ('Động lực học & Định luật Newton', 'Ba định luật Newton & Lực ma sát'),
            ('Công, Năng lượng & Công suất', 'Định luật bảo toàn cơ năng'),
            ('Động lượng & Chuyển động tròn', 'Bảo toàn động lượng & Lực hướng tâm'),
        ],
        'Lớp 11': [
            ('Dao động điều hòa', 'Chu kỳ, Tần số & Con lắc lò xo'),
            ('Sóng cơ & Sóng âm', 'Bước sóng, Giao thoa & Sóng dừng'),
            ('Điện trường & Tụ điện', 'Định luật Coulomb & Cường độ điện trường'),
            ('Dòng điện không đổi', 'Định luật Ohm & Công suất điện'),
        ],
        'Lớp 12': [
            ('Vật lý nhiệt', 'Nội năng & Nhiệt dung riêng'),
            ('Khí lý tưởng', 'Phương trình trạng thái Clapeyron'),
            ('Từ trường & Cảm ứng điện từ', 'Suất điện động cảm ứng & Sóng điện từ'),
            ('Vật lý hạt nhân', 'Độ hụt khối & Phóng xạ'),
        ],
    },
    'HOA_HOC': {
        'Lớp 10': [
            ('Cấu tạo nguyên tử & Bảng tuần hoàn', 'Cấu hình electron & Xu hướng tuần hoàn'),
            ('Liên kết hóa học', 'Liên kết ion & Cộng hóa trị'),
            ('Phản ứng oxi hóa - khử & Năng lượng', 'Cân bằng e & Biến thiên enthalpy'),
            ('Tốc độ phản ứng & Nhóm Halogen', 'Tính oxi hóa của Cl2, Br2, I2'),
        ],
        'Lớp 11': [
            ('Cân bằng hóa học', 'Hằng số Kc & Chuyển dịch Le Chatelier'),
            ('Nitrogen và Sulfur', 'Ammonia, Nitric acid & Sulfuric acid'),
            ('Đại cương Hóa học hữu cơ', 'Đồng phân & Danh pháp IUPAC'),
            ('Hydrocarbon & Dẫn xuất', 'Alkane, Alkene, Alkyne & Arene'),
        ],
        'Lớp 12': [
            ('Ester - Lipid', 'Phản ứng xà phòng hóa & Este'),
            ('Carbohydrate', 'Glucose, Saccharose, Tinh bột & Cellulose'),
            ('Hợp chất chứa Nitrogen & Polymer', 'Amine, Amino acid & Peptide'),
            ('Pin điện & Đại cương kim loại', 'Thế điện cực chuẩn & Dãy điện hóa'),
        ],
    },
    'LICH_SU': {
        'Lớp 10': [
            ('Lịch sử và Sử học', 'Sử học & Văn minh cổ đại'),
            ('Văn minh Đông Nam Á & Đại Việt', 'Văn minh Thăng Long - Đại Việt'),
            ('Cách mạng công nghiệp cận đại', 'Cách mạng công nghiệp lần 1 & 2'),
            ('Lịch sử bảo vệ chủ quyền Việt Nam', 'Chiến công chống ngoại xâm tiêu biểu'),
        ],
        'Lớp 11': [
            ('Cách mạng tư sản & CNXH', 'Các cuộc cách mạng tư sản tiêu biểu'),
            ('Chủ nghĩa đế quốc & Thuộc địa', 'Phong trào giải phóng dân tộc Á - Phi'),
            ('Chiến tranh bảo vệ Tổ quốc trước 1945', 'Khởi nghĩa Lam Sơn & Tây Sơn'),
            ('Cải cách lịch sử ở Việt Nam', 'Cải cách Hồ Quý Ly, Lê Thánh Tông, Minh Mạng'),
        ],
        'Lớp 12': [
            ('Thế giới trong và sau Chiến tranh lạnh', 'Trật tự thế giới hai cực Ianta & Liên hợp quốc'),
            ('ASEAN & Cách mạng tháng Tám 1945', 'Tổng khởi nghĩa tháng 8/1945'),
            ('Kháng chiến chống Pháp & chống Mỹ', 'Điện Biên Phủ 1954 & Đại thắng Xuân 1975'),
            ('Công cuộc Đổi mới 1986 đến nay', 'Thành tựu Đổi mới & Hội nhập'),
        ],
    },
}

# Kho câu hỏi nhỏ buổi sáng (ABCD) theo môn & trình độ — đồng bộ trực tiếp với SubjectMemory & độ khó.
_MORNING_MCQ_BANK: dict[str, list[dict[str, Any]]] = {
    'TOAN': [
        {
            'prompt': 'Đạo hàm của hàm số y = x^3 - 3x tại điểm x = 2 bằng bao nhiêu?',
            'options': ['3', '6', '9', '12'],
            'correctIndex': 2,
            'steps': ['y\' = 3x^2 - 3', 'Thay x = 2: y\'(2) = 3*(4) - 3 = 9.'],
            'hintVi': 'Tính y\' = 3x^2 - 3 trước rồi thay x = 2.',
        },
        {
            'prompt': 'Trong cấp số cộng có u_1 = 2 và công sai d = 3, số hạng u_4 bằng:',
            'options': ['8', '11', '14', '17'],
            'correctIndex': 1,
            'steps': ['Áp dụng u_n = u_1 + (n - 1)d', 'u_4 = 2 + 3*3 = 11.'],
            'hintVi': 'Nhớ công thức u_n = u_1 + (n - 1)d.',
        },
        {
            'prompt': 'Giá trị của giới hạn lim (2n + 1) / (n + 3) khi n tiến tới dương vô cực là:',
            'options': ['0', '1/3', '2', '3'],
            'correctIndex': 2,
            'steps': ['Chia cả tử và mẫu cho n: (2 + 1/n)/(1 + 3/n)', 'Khi n -> +oo thì giới hạn bằng 2/1 = 2.'],
            'hintVi': 'Chia cả tử và mẫu cho bậc cao nhất là n.',
        },
        {
            'prompt': 'Phương trình sin(x) = 1 có một nghiệm thuộc khoảng [0; pi] là:',
            'options': ['0', 'pi/6', 'pi/4', 'pi/2'],
            'correctIndex': 3,
            'steps': ['Trên [0; pi], sin(x) đạt giá trị 1 duy nhất tại x = pi/2.'],
            'hintVi': 'Góc nào có sin bằng 1 trong nửa đường tròn trên?',
        },
    ],
    'NGU_VAN': [
        {
            'prompt': 'Từ tiếng Việt nào dưới đây viết ĐÚNG chính tả?',
            'options': ['Sán lạn', 'Sáng lạng', 'Xán lạn', 'Sáng lạn'],
            'correctIndex': 2,
            'steps': ['Từ Hán Việt chuẩn là "Xán lạn" (rực rỡ, sáng sủa), âm đầu "x" và vần "an".'],
            'hintVi': 'Từ gốc Hán Việt nghĩa là rực rỡ bắt đầu bằng âm x.',
        },
        {
            'prompt': 'Từ "phong thanh" trong tiếng Việt có nghĩa nào đúng nhất?',
            'options': [
                'Thanh tao, lịch lãm',
                'Nghe đồn thoáng qua, chưa chắc chắn',
                'Âm thanh của gió mùa thu',
                'Cảnh vật vắng lặng, đìu hiu',
            ],
            'correctIndex': 1,
            'steps': ['"Nghe phong thanh" nghĩa là nghe loáng thoáng tin đồn chưa được xác thực.'],
            'hintVi': 'Nghĩ đến cụm "nghe phong thanh tin tức...".',
        },
        {
            'prompt': 'Từ nào sau đây KHÔNG phải từ láy?',
            'options': ['Lung linh', 'Lấp lánh', 'Tươi tốt', 'Xôn xao'],
            'correctIndex': 2,
            'steps': ['"Tươi tốt" là từ ghép đẳng lập (cả hai tiếng "tươi" và "tốt" đều có nghĩa độc lập).'],
            'hintVi': 'Kiểm tra xem từ nào cả hai tiếng đều có nghĩa rõ ràng khi đứng riêng.',
        },
        {
            'prompt': 'Biện pháp tu từ chính trong câu "Thuyền về có nhớ bến chăng?" là:',
            'options': ['So sánh', 'Ẩn dụ & Nhân hóa', 'Nói quá', 'Điệp ngữ'],
            'correctIndex': 1,
            'steps': ['"Thuyền" và "bến" ẩn dụ cho người đi và người ở lại, đồng thời hỏi "nhớ" là nhân hóa.'],
            'hintVi': 'Thuyền không có tình cảm như người nhưng lại biết "nhớ".',
        },
    ],
    'TIENG_ANH': [
        {
            'prompt': 'Trong tiếng Anh, từ "resilient" gần nghĩa nhất với từ nào sau đây?',
            'options': [
                'Kiên cường, mau phục hồi',
                'Dễ vỡ, yếu đuối',
                'Thờ ơ, vô cảm',
                'Ngần ngại, chần chừ',
            ],
            'correctIndex': 0,
            'steps': ['"Resilient" (adj) chỉ khả năng phục hồi nhanh trước khó khăn, kiên cường.'],
            'hintVi': 'Đây là tính từ tích cực mô tả tinh thần vượt khó.',
        },
        {
            'prompt': 'Chọn cụm đúng ngữ pháp: "She insisted ______ helping me finish the homework."',
            'options': ['in', 'on', 'at', 'to'],
            'correctIndex': 1,
            'steps': ['Cấu trúc chuẩn: insist on + V-ing (khăng khăng làm gì).'],
            'hintVi': 'Động từ "insist" đi với giới từ cố định nào?',
        },
        {
            'prompt': 'Từ "sustainable" trong chủ đề Môi trường lớp 11–12 có nghĩa là:',
            'options': [
                'Tạm thời, ngắn hạn',
                'Bền vững, lâu dài',
                'Độc hại, ô nhiễm',
                'Lãng phí năng lượng',
            ],
            'correctIndex': 1,
            'steps': ['"Sustainable development" = Phát triển bền vững.'],
            'hintVi': 'Thường đi cùng danh từ "development" hoặc "energy".',
        },
        {
            'prompt': 'Chọn câu đúng: "By the time we arrived, the class ______."',
            'options': ['starts', 'has started', 'had started', 'will start'],
            'correctIndex': 2,
            'steps': ['Mệnh đề "By the time + QKĐ" kết hợp thì Quá khứ hoàn thành (had + V3/ed).'],
            'hintVi': 'Hành động xảy ra trước một mốc trong quá khứ dùng thì gì?',
        },
    ],
    'VAT_LY': [
        {
            'prompt': 'Trong dao động điều hòa, chu kỳ T và tần số f liên hệ theo công thức nào?',
            'options': ['T = 2*pi*f', 'T = 1 / f', 'T = f^2', 'T = f / 2'],
            'correctIndex': 1,
            'steps': ['Chu kỳ T (giây) là nghịch đảo của tần số f (Hz): T = 1 / f.'],
            'hintVi': 'Chu kỳ là thời gian một dao động, tần số là số dao động trong 1 giây.',
        },
        {
            'prompt': 'Đơn vị chuẩn SI của cường độ dòng điện là:',
            'options': ['Vôn (V)', 'Ôm (Ohm)', 'Ampe (A)', 'Oát (W)'],
            'correctIndex': 2,
            'steps': ['Cường độ dòng điện đo bằng Ampe (A); hiệu điện thế là Vôn (V).'],
            'hintVi': 'Tên nhà bác học Ampère.',
        },
        {
            'prompt': 'Công thức tính động năng của vật khối lượng m chuyển động với tốc độ v là:',
            'options': ['W_d = m*v', 'W_d = 1/2 * m * v^2', 'W_d = m*g*h', 'W_d = 2*m*v'],
            'correctIndex': 1,
            'steps': ['Động năng: W_d = 1/2 * m * v^2 (đơn vị Joule).'],
            'hintVi': 'Có hệ số 1/2 và bình phương vận tốc.',
        },
        {
            'prompt': 'Bước sóng lambda truyền với tốc độ v trong chu kỳ T bằng:',
            'options': ['v / T', 'v * T', 'T / v', '2 * v * T'],
            'correctIndex': 1,
            'steps': ['Quãng đường sóng truyền trong một chu kỳ T là lambda = v * T = v / f.'],
            'hintVi': 'Quãng đường = vận tốc nhân thời gian.',
        },
    ],
    'HOA_HOC': [
        {
            'prompt': 'Dung dịch làm quỳ tím hóa XANH là dung dịch nào sau đây?',
            'options': ['HCl', 'NaOH', 'NaCl', 'H2SO4'],
            'correctIndex': 1,
            'steps': ['NaOH là bazơ kiềm mạnh, làm quỳ tím chuyển sang màu xanh.'],
            'hintVi': 'Chọn chất mang tính kiềm (bazơ).',
        },
        {
            'prompt': 'Trong bảng tuần hoàn, nguyên tố nào có độ âm điện lớn nhất?',
            'options': ['Oxygen (O)', 'Nitrogen (N)', 'Fluorine (F)', 'Chlorine (Cl)'],
            'correctIndex': 2,
            'steps': ['Fluorine (F) đứng đầu nhóm VIIA và có độ âm điện lớn nhất (3,98).'],
            'hintVi': 'Halogen ở chu kỳ 2.',
        },
        {
            'prompt': 'Công thức phân tử của Ethylene (Etilen) là:',
            'options': ['CH4', 'C2H2', 'C2H4', 'C2H6'],
            'correctIndex': 2,
            'steps': ['Ethylene là alkene đơn giản nhất với một nối đôi C=C: C2H4.'],
            'hintVi': 'Alkene có công thức chung CnH2n (n=2).',
        },
        {
            'prompt': 'Kim loại nào dẫn điện tốt nhất trong điều kiện thường?',
            'options': ['Đồng (Cu)', 'Bạc (Ag)', 'Nhôm (Al)', 'Vàng (Au)'],
            'correctIndex': 1,
            'steps': ['Thứ tự dẫn điện: Ag > Cu > Au > Al > Fe.'],
            'hintVi': 'Ký hiệu hóa học là Ag.',
        },
    ],
    'LICH_SU': [
        {
            'prompt': 'Chủ tịch Hồ Chí Minh đọc Tuyên ngôn Độc lập khai sinh nước VNDCCH vào ngày tháng năm nào?',
            'options': ['19/08/1945', '02/09/1945', '07/05/1954', '30/04/1975'],
            'correctIndex': 1,
            'steps': ['Ngày 02/09/1945 tại Quảng trường Ba Đình, Hà Nội.'],
            'hintVi': 'Ngày Quốc khánh của Việt Nam.',
        },
        {
            'prompt': 'Chiến thắng Điện Biên Phủ diễn ra vào năm nào?',
            'options': ['1945', '1950', '1954', '1968'],
            'correctIndex': 2,
            'steps': ['Chiến dịch Điện Biên Phủ toàn thắng ngày 07/05/1954.'],
            'hintVi': 'Năm ký Hiệp định Giơ-ne-vơ.',
        },
        {
            'prompt': 'Đường lối Đổi mới ở Việt Nam chính thức được đề ra tại Đại hội Đảng lần VI năm nào?',
            'options': ['1976', '1986', '1991', '1995'],
            'correctIndex': 1,
            'steps': ['Đại hội VI tháng 12/1986 mở đầu công cuộc Đổi mới toàn diện.'],
            'hintVi': 'Giữa thập niên 1980.',
        },
        {
            'prompt': 'Việt Nam chính thức gia nhập Hiệp hội các quốc gia Đông Nam Á (ASEAN) vào năm nào?',
            'options': ['1967', '1986', '1995', '2007'],
            'correctIndex': 2,
            'steps': ['Ngày 28/07/1995, Việt Nam trở thành thành viên thứ 7 của ASEAN.'],
            'hintVi': 'Cùng năm bình thường hóa quan hệ Việt - Mỹ.',
        },
    ],
}


def compute_school_week(target_date: date | None = None) -> int:
    """Tính tuần học thực tế (1..35) theo năm học Việt Nam (khai giảng đầu tháng 9)."""
    d = target_date or datetime.now(timezone.utc).date()
    start_year = d.year if d.month >= 9 else d.year - 1
    school_start = date(start_year, 9, 5)
    delta_days = max(0, (d - school_start).days)
    week = (delta_days // 7) + 1
    return max(1, min(35, week))


def resolve_curriculum_for_week(
    subject_code: str,
    grade_level: str,
    week: int,
) -> tuple[str, str]:
    norm_sub = normalize_subject_code(subject_code)
    grade = grade_level.strip() if grade_level.strip() in {'Lớp 10', 'Lớp 11', 'Lớp 12'} else 'Lớp 11'
    sub_map = _CURRICULUM_TOPICS.get(norm_sub)
    if not sub_map:
        return (f'Chuyên đề tuần {week}', f'Kiến thức trọng tâm tuần {week}')
    items = sub_map.get(grade) or sub_map.get('Lớp 11') or []
    if not items:
        return (f'Chuyên đề tuần {week}', f'Kiến thức trọng tâm tuần {week}')
    idx = min(len(items) - 1, max(0, (week - 1) // 9))
    return items[idx]


def ensure_memories_for_user(
    db: Session,
    user: User,
    *,
    subject_codes: list[str] | None = None,
    target_date: date | None = None,
) -> list[SubjectMemory]:
    grade = (user.grade_band or 'Lớp 11').strip()
    week = compute_school_week(target_date)
    raw_codes = list(user.selected_subjects_json or []) + (subject_codes or [])
    if not raw_codes:
        raw_codes = ['TOAN', 'NGU_VAN', 'TIENG_ANH']

    normalized_codes: list[str] = []
    for code in raw_codes:
        norm = normalize_subject_code(str(code))
        if norm and norm not in normalized_codes and norm not in {'CHAO_CO', 'SINH_HOAT', 'CHAO_CO_SHL'}:
            normalized_codes.append(norm)

    existing = {
        m.subject_code: m
        for m in db.scalars(select(SubjectMemory).where(SubjectMemory.user_id == user.id))
    }
    changed = False
    for code in normalized_codes:
        if code not in existing:
            chapter, topic = resolve_curriculum_for_week(code, grade, week)
            row = SubjectMemory(
                user_id=user.id,
                subject_code=code,
                grade_level=grade,
                current_week=week,
                current_chapter=chapter,
                current_topic=topic,
                mastery_score=50,
            )
            db.add(row)
            existing[code] = row
            changed = True
    if changed:
        db.flush()
    return sorted(existing.values(), key=lambda x: x.subject_code)


def pick_today_subject_from_timetable(
    db: Session,
    user: User,
    *,
    target_date: date,
    seed_salt: str = '',
) -> tuple[str, str, int]:
    """Đọc TKB đúng thứ hôm nay và chọn ngẫu nhiên 1 môn có tiết trong ngày."""
    weekday = target_date.isoweekday()  # 1..7
    slots = list(
        db.scalars(
            select(TimetableSlot)
            .where(TimetableSlot.user_id == user.id, TimetableSlot.weekday == weekday)
            .order_by(TimetableSlot.position.asc())
        )
    )
    day_label = _WEEKDAY_LABELS_VI.get(weekday, f'Thứ {weekday + 1}')
    candidates = [
        normalize_subject_code(s.subject_code)
        for s in slots
        if s.subject_code
        and not s.subject_code.strip().lower().startswith(('chao_co', 'sinh_hoat', 'nghi'))
    ]
    unique_candidates = list(dict.fromkeys(c for c in candidates if c))
    if unique_candidates:
        seed_int = int(
            hashlib.sha256(f'{user.id}:{target_date.isoformat()}:{seed_salt}'.encode()).hexdigest()[:8],
            16,
        )
        chosen = unique_candidates[seed_int % len(unique_candidates)]
        return chosen, f'Đọc từ TKB {day_label} hôm nay', weekday

    profile_subjects = [normalize_subject_code(str(x)) for x in (user.selected_subjects_json or []) if str(x).strip()]
    if not profile_subjects:
        profile_subjects = ['TOAN', 'NGU_VAN', 'TIENG_ANH']
    seed_int = int(
        hashlib.sha256(f'{user.id}:{target_date.isoformat()}:{seed_salt}'.encode()).hexdigest()[:8],
        16,
    )
    chosen = profile_subjects[seed_int % len(profile_subjects)]
    return chosen, f'{day_label} không có tiết riêng · lấy từ môn đang theo học', weekday


def record_attempt_outcome(
    db: Session,
    user: User,
    subject_code: str,
    is_correct: bool,
) -> SubjectMemory:
    norm = normalize_subject_code(subject_code)
    ensure_memories_for_user(db, user, subject_codes=[norm])
    memory = db.scalar(
        select(SubjectMemory).where(
            SubjectMemory.user_id == user.id,
            SubjectMemory.subject_code == norm,
        )
    )
    assert memory is not None
    memory.attempts_count += 1
    if is_correct:
        memory.correct_count += 1
        memory.mastery_score = min(100, memory.mastery_score + 6)
    else:
        memory.mastery_score = max(10, memory.mastery_score - 3)
    memory.last_practiced_at = datetime.now(timezone.utc)
    db.flush()
    return memory


def _shuffled_options_from_int(
    correct_val: int,
    rng: random.Random,
    *,
    unit: str = '',
) -> tuple[list[str], int]:
    """Sinh 4 phương án số không trùng quanh đáp án đúng."""
    suffix = f' {unit}'.rstrip()
    offsets = [-4, -2, -1, 1, 2, 3, 5, 6, 8]
    rng.shuffle(offsets)
    vals: list[int] = [correct_val]
    for delta in offsets:
        cand = correct_val + delta
        if cand not in vals and (correct_val < 0 or cand >= 0):
            vals.append(cand)
        if len(vals) == 4:
            break
    while len(vals) < 4:
        cand = vals[-1] + 2
        if cand not in vals:
            vals.append(cand)
    rng.shuffle(vals)
    correct_idx = vals.index(correct_val)
    return [f'{v}{suffix}' for v in vals], correct_idx


def _generate_parametric_item(
    subject_code: str,
    grade_level: str,
    week: int,
    rng: random.Random,
) -> dict[str, Any] | None:
    """Sinh câu hỏi chuyển số theo tham số (10k+ biến thể) khớp lớp & tuần học."""
    norm = normalize_subject_code(subject_code)
    clean_grade = grade_level.strip()

    if norm == 'TOAN':
        if clean_grade == 'Lớp 10':
            a = rng.randint(1, 4)
            x0 = rng.randint(-6, 8)
            if x0 == 0:
                x0 = 3
            b = -2 * a * x0
            c = rng.randint(-9, 12)
            b_str = f'+ {b}x' if b >= 0 else f'- {abs(b)}x'
            c_str = f'+ {c}' if c >= 0 else f'- {abs(c)}'
            options, correct_idx = _shuffled_options_from_int(x0, rng)
            return {
                'prompt': f'Hoành độ đỉnh của parabol y = {a}x² {b_str} {c_str} bằng bao nhiêu?',
                'options': options,
                'correctIndex': correct_idx,
                'steps': [
                    f'Áp dụng x_I = -b/(2a) = -({b})/(2·{a}) = {x0}.',
                ],
                'hintVi': 'Công thức hoành độ đỉnh parabol: x = -b / (2a).',
            }
        if clean_grade == 'Lớp 12':
            variant = rng.randint(0, 1)
            if variant == 0:
                a = rng.randint(1, 5)
                b = rng.randint(2, 6)
                k = rng.randint(1, 4)
                ans = a * (b**2) + k * b
                options, correct_idx = _shuffled_options_from_int(ans, rng)
                return {
                    'prompt': f'Tính tích phân I = ∫₀^{b} ({2 * a}x + {k}) dx.',
                    'options': options,
                    'correctIndex': correct_idx,
                    'steps': [
                        f'Nguyên hàm F(x) = {a}x² + {k}x; suy ra F({b}) - F(0) = {ans}.',
                    ],
                    'hintVi': 'Nguyên hàm của 2ax + k là ax² + kx.',
                }
            a = rng.randint(1, 4)
            x0 = rng.randint(1, 6)
            ans = 3 * a * (x0**2)
            options, correct_idx = _shuffled_options_from_int(ans, rng)
            return {
                'prompt': f'Hệ số góc tiếp tuyến của đồ thị y = {a}x³ tại điểm x₀ = {x0} bằng:',
                'options': options,
                'correctIndex': correct_idx,
                'steps': [
                    f"Tính đạo hàm y' = {3 * a}x², thay x₀ = {x0} được y'({x0}) = {ans}.",
                ],
                'hintVi': "Hệ số góc tiếp tuyến tại x₀ là y'(x₀).",
            }
        # Mặc định Lớp 11: Cấp số cộng / Đạo hàm tuần thực tế
        u1 = rng.randint(-5, 12)
        d = rng.randint(2, 9)
        n = rng.randint(6, 18)
        ans = u1 + (n - 1) * d
        options, correct_idx = _shuffled_options_from_int(ans, rng)
        return {
            'prompt': f'Cho cấp số cộng (uₙ) với u₁ = {u1} và công sai d = {d}. Giá trị u_{n} bằng:',
            'options': options,
            'correctIndex': correct_idx,
            'steps': [f'u_{n} = u₁ + ({n} - 1)d = {u1} + {n - 1}·{d} = {ans}.'],
            'hintVi': 'Công thức số hạng tổng quát: uₙ = u₁ + (n - 1)d.',
        }

    if norm == 'VAT_LY':
        if clean_grade == 'Lớp 10':
            m = rng.randint(2, 10)
            h = rng.randint(3, 15)
            ans = m * 10 * h
            options, correct_idx = _shuffled_options_from_int(ans, rng, unit='J')
            return {
                'prompt': f'Một vật khối lượng m = {m} kg ở độ cao h = {h} m (lấy g = 10 m/s²). Thế năng trọng trường bằng:',
                'options': options,
                'correctIndex': correct_idx,
                'steps': [f'W_t = m·g·h = {m}·10·{h} = {ans} J.'],
                'hintVi': 'Công thức thế năng: W_t = mgh.',
            }
        if clean_grade == 'Lớp 12':
            m = rng.randint(1, 5)
            c_kj = 4  # Nước c ≈ 4.2 kJ/kg.K -> lấy 4 để nhẩm nhanh sáng
            dt = rng.randint(5, 25)
            ans = m * c_kj * dt
            options, correct_idx = _shuffled_options_from_int(ans, rng, unit='kJ')
            return {
                'prompt': f'Làm nóng {m} kg chất có nhiệt dung riêng c = {c_kj} kJ/(kg·K) tăng thêm ΔT = {dt} K cần nhiệt lượng:',
                'options': options,
                'correctIndex': correct_idx,
                'steps': [f'Q = m·c·ΔT = {m}·{c_kj}·{dt} = {ans} kJ.'],
                'hintVi': 'Áp dụng Q = m·c·ΔT.',
            }
        # Lớp 11: Sóng cơ λ = v / f
        f = rng.randint(5, 25)
        lam = rng.randint(2, 12)
        v = lam * f
        options, correct_idx = _shuffled_options_from_int(lam, rng, unit='m')
        return {
            'prompt': f'Một sóng truyền với tốc độ v = {v} m/s và tần số f = {f} Hz. Bước sóng λ bằng:',
            'options': options,
            'correctIndex': correct_idx,
            'steps': [f'λ = v / f = {v} / {f} = {lam} m.'],
            'hintVi': 'Áp dụng λ = v / f.',
        }

    if norm == 'HOA_HOC':
        pairs = [('CaCO₃', 100), ('NaOH', 40), ('MgO', 40), ('CuSO₄', 160), ('H₂SO₄', 98)]
        formula, molar_mass = pairs[rng.randrange(len(pairs))]
        n_mol = rng.randint(1, 6)
        mass = n_mol * molar_mass
        options, correct_idx = _shuffled_options_from_int(n_mol, rng, unit='mol')
        return {
            'prompt': f'Số mol của m = {mass} gam chất {formula} (M = {molar_mass}) là bao nhiêu?',
            'options': options,
            'correctIndex': correct_idx,
            'steps': [f'n = m / M = {mass} / {molar_mass} = {n_mol} mol.'],
            'hintVi': 'Áp dụng n = m / M.',
        }

    return None


def build_quick_morning_challenge(
    *,
    subject_code: str,
    grade_level: str,
    memory: SubjectMemory | None,
    difficulty: str = 'basic',
    seed_hint: str = '',
) -> dict[str, Any]:
    """Tạo câu hỏi buổi sáng nhỏ gọn (ABCD 1 chạm hoặc đề ngắn >= 70%), kết hợp chuyển số theo lớp."""
    norm = normalize_subject_code(subject_code)
    items = list(_MORNING_MCQ_BANK.get(norm) or _MORNING_MCQ_BANK['TOAN'])
    week = memory.current_week if memory else compute_school_week()
    chapter = memory.current_chapter if (memory and memory.current_chapter) else resolve_curriculum_for_week(norm, grade_level, week)[0]

    clean_diff = difficulty.strip().lower()
    rng = random.Random(f'{norm}:{grade_level}:{week}:{seed_hint}')

    if clean_diff == 'advanced':
        # Đề ngắn 4 câu trắc nghiệm, đạt >= 70% (tức >= 3/4 câu đúng), ưu tiên sinh chuyển số khác nhau
        selected: list[dict[str, Any]] = []
        seen_prompts: set[str] = set()
        for attempt_idx in range(6):
            sub_rng = random.Random(f'{norm}:{grade_level}:{week}:{seed_hint}:adv:{attempt_idx}')
            gen = _generate_parametric_item(norm, grade_level, week, sub_rng)
            if gen is not None and gen['prompt'] not in seen_prompts:
                seen_prompts.add(gen['prompt'])
                selected.append(gen)
            if len(selected) >= 4:
                break
        rng.shuffle(items)
        for item in items:
            if len(selected) >= 4:
                break
            if item['prompt'] not in seen_prompts:
                seen_prompts.add(item['prompt'])
                selected.append(item)
        while len(selected) < 4:
            selected.append(items[len(selected) % len(items)])
        sub_questions = [
            {
                'index': idx,
                'prompt': item['prompt'],
                'options': list(item['options']),
                'correctOptionIndex': int(item['correctIndex']),
                'steps': list(item['steps']),
            }
            for idx, item in enumerate(selected)
        ]
        return {
            'questionFormat': 'mini_quiz',
            'difficultyMode': 'advanced',
            'passThreshold': 0.7,
            'prompt': f'Đề ngắn {len(sub_questions)} câu ({grade_level} · Tuần {week} · {chapter}): đạt tối thiểu 70% để hoàn thành.',
            'reasoningPromptVi': 'Chọn nhanh đáp án A/B/C/D cho từng câu bên dưới (đạt >= 70%).',
            'options': [],
            'correctOptionIndex': None,
            'accepted': ['70%'],
            'subQuestions': sub_questions,
            'steps': [s for item in selected for s in item['steps'][:1]],
            'hintVi': selected[0]['hintVi'],
            'topicId': chapter,
        }

    # Ưu tiên câu chuyển số đúng lớp cho Toán/Lý/Hóa (~75% cơ hội hoặc fallback bank khi cần)
    parametric = _generate_parametric_item(norm, grade_level, week, rng)
    picked = parametric if parametric is not None else items[rng.randrange(len(items))]
    correct_idx = int(picked['correctIndex'])
    correct_label = picked['options'][correct_idx]
    letter = ['A', 'B', 'C', 'D'][correct_idx]
    return {
        'questionFormat': 'mcq',
        'difficultyMode': 'basic',
        'passThreshold': 1.0,
        'prompt': picked['prompt'],
        'reasoningPromptVi': 'Chạm 1 đáp án đúng bên dưới (không cần gõ dài).',
        'options': list(picked['options']),
        'correctOptionIndex': correct_idx,
        'accepted': [letter, letter.lower(), str(correct_label)],
        'subQuestions': [],
        'steps': list(picked['steps']),
        'hintVi': picked['hintVi'],
        'topicId': chapter,
    }
