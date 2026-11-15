# Catalog chương trình THPT và máy lập kế hoạch

**Nguồn học thuật:** chương trình giáo dục phổ thông do Bộ GD&ĐT ban hành, được sửa đổi/bổ sung; app phải lưu phiên bản và người duyệt trước khi seed. [Văn bản hợp nhất](https://moet.gov.vn/content/vanban/Lists/VBPQ/Attachments/1483/vbhn-ttu-322018-202021-132022-ttbgddt.pdf), [chương trình tổng thể](https://moet.gov.vn/content/tintuc/Lists/News/Attachments/8421/chuong-trinh-tong-the-ctgdpt-2018.pdf). Không suy danh mục chuẩn từ dataset đề thi hay để Gemini tự bịa môn/chuyên đề.

## Phạm vi đầu và mô hình

THPT lớp 10–12 là cohort đầu. Catalog gồm `curriculum(id, sourceUrl, effectiveFrom, reviewedAt, reviewerId, status)`, `grade(10|11|12)`, `subject(code, displayNameVi, category, validGrades)`, `topic(code, subject, grade, outcome, ordering, reviewer)`, `subjectOffering` theo lựa chọn user/trường nếu cần. `category=compulsory|elective|optional|school_specific`; giá trị phải được reviewer đối chiếu văn bản đang hiệu lực trước seed. Không khóa người dùng vào một tổ hợp thi giả định. Môn trường dạy khác lịch quy định có thể thêm ở TKB với nhãn `Môn riêng`, nhưng không tự có câu scored.

### Ma trận seed ban đầu cho lớp 10, 11, 12

Theo [chương trình tổng thể đã hợp nhất của Bộ GD&ĐT](https://moet.gov.vn/content/vanban/Lists/VBPQ/Attachments/1483/vbhn-chuong-trinh-tong-the.pdf), ba lớp có cùng **tên môn/hoạt động cấp THPT**, còn `topic` và yêu cầu cần đạt khác theo lớp. Seed tên mã ổn định sau khi người duyệt kiểm lại văn bản hiệu lực:

| Nhóm | Mã catalog đề xuất | Cách hiện trong app |
| --- | --- | --- |
| Môn bắt buộc | `literature`, `mathematics`, `foreign_language_1`, `history`, `physical_education`, `national_defense_security` | Ngữ văn, Toán, Ngoại ngữ 1, Lịch sử, Giáo dục thể chất, Giáo dục quốc phòng và an ninh. `foreign_language_1` cần chọn ngôn ngữ thật; không mặc định là Tiếng Anh. |
| Hoạt động/nội dung bắt buộc | `career_experience`, `local_education` | Hoạt động trải nghiệm, hướng nghiệp và Nội dung giáo dục của địa phương; được đưa vào TKB/nhắc việc, chỉ có câu ôn khi có nội dung đã duyệt tương ứng. |
| Môn lựa chọn | `geography`, `economic_legal_education`, `physics`, `chemistry`, `biology`, `technology`, `informatics`, `music`, `fine_arts` | Địa lí, Giáo dục kinh tế và pháp luật, Vật lí, Hóa học, Sinh học, Công nghệ, Tin học, Âm nhạc, Mĩ thuật. Học sinh chọn **4 môn** theo tổ hợp trường đang cung cấp; app hỏi môn thực học, không tự ép một tổ hợp. |
| Môn tự chọn | `ethnic_language`, `foreign_language_2` | Tiếng dân tộc thiểu số, Ngoại ngữ 2; chỉ hiện khi học sinh khai báo có học. |
| Chuyên đề học tập | `specialized_topic` + `parent_subject_code` | Ba cụm chuyên đề của ba môn phù hợp mỗi năm, nếu trường/học sinh nhập; tách với môn chính và chỉ gợi ý bài khi đã có rubric. |

Chọn môn trong onboarding chỉ xác định **môn đang học**; mục tiêu thi tốt nghiệp là trường dữ liệu khác, không suy ra tất cả môn học từ tổ hợp thi. Mỗi `grade_subject` có `grade`, `subject_code`, `catalog_version`, `availability`, `question_pool_status`, `school_offering` và khóa duy nhất `(grade, subject_code, catalog_version)`. `availability=curriculum` không đồng nghĩa `question_pool_status=published`; UI phải hiện môn trong lịch ngay cả khi chưa có câu chấm. Admin seed `draft` → reviewer xác nhận từng lớp/môn/chuyên đề → `published`; thay đổi văn bản tạo version mới thay vì sửa lịch sử.

## Lựa chọn người học

`user_grade`, `selected_subjects`, `exam_focus_subjects`, `self_assessment_by_subject`, `learning_goal`, `timetable_revision`. Khi đổi lớp, giữ lịch cũ cho user xem, đánh dấu slot không còn tương thích và yêu cầu xác nhận; không tự xóa bài/tiến độ. Câu hỏi chỉ hiện nếu `grade + subject + topic + curriculumVersion + modeEligibility + published + rights` khớp. Không có pool thì `practice_only` hoặc `not_available`, không phát câu AI draft làm điểm.

## Planner có kiểm soát

Input: môn/lớp/mục tiêu do user chọn, TKB đã xác nhận, quỹ thời gian và kết quả bài chấm chắc; output: tối đa 3 việc/ngày, mỗi việc `subject`, `topic`, `duration`, `reason`, `source`, `confidence`, `requiresConfirmation`. Rule engine bảo đảm lịch không chồng buổi học, không đặt học vào giờ ngủ hoặc ép dậy sớm. Gemini chỉ xếp thứ tự/diễn đạt/gợi một việc nhỏ; output structured, validate subject/topic có thật, thời lượng hợp lệ, không tạo lesson ngoài pool. User có `Sửa`, `Bỏ qua`, `Áp dụng`; không tạo alarm/notification mới từ planner nếu chưa xác nhận riêng. AI lỗi thì rule-based plan hiển thị với nhãn chính xác.

## Quy trình nội dung và test

Admin nhập catalog từ nguồn được phép → reviewer môn/chương trình xác nhận → publish immutable version → mapping câu/rubric → test grade/subject/topic → mở cohort. Không commit PDF/corpus bên thứ ba nếu quyền chưa rõ; lưu URL và metadata. Test lớp 10/11/12, môn bắt buộc/lựa chọn, school-specific, đổi lớp giữa năm, version mới, câu rút/retired, kỳ nghỉ và lịch ngoại lệ, AI output môn không tồn tại. Mọi plan có `planner_rule_version`, `catalog_version`, `model_version` nếu có AI, không cập nhật lặng lẽ sau user đã xác nhận.
