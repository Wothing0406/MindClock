# Đặc tả T080 — Đồng Hồ Xoay 24h & Tải APK GitHub Trỏ `api.ieltsoasis.site`

## Acceptance Criteria

- **AC-01 (Đồng hồ xoay 24h đồng bộ theme):**
  - `AlarmConfigScreen` có vòng đồng hồ 24h (`0` trên đỉnh, `12` ở đáy, bước 5 phút) cho phép kéo trực tiếp nút **Đi ngủ** và nút **Báo thức dậy**.
  - Tâm vòng tròn hiển thị chính xác thời lượng ngủ (`X giờ Y phút`, nhãn `Thời gian ngủ`) và tự cập nhật khi kéo hoặc bấm nút tinh chỉnh `±` hiện có.
  - Màu sắc dùng 100% token trong `MindClockTheme` (`primary`, `primarySoft`, `sunrise`, `sunriseSoft`, `surface`, `ink`, `inkMuted`, `outline`), không dùng emoji hệ thống, dùng vector `CustomPainter` + `Icon`/`MindClockIcon`.
  - Hỗ trợ `320dp` & `200%` text scaling không overflow.
- **AC-02 (Build APK + GitHub Releases + Trang tải):**
  - Có script `scripts/build_release_apk.ps1` build APK trỏ mặc định `https://api.ieltsoasis.site`.
  - Có GitHub Actions `.github/workflows/android-release-apk.yml` build APK trỏ `MINDCLOCK_API_BASE_URL` (mặc định `https://api.ieltsoasis.site`) và tự động tạo GitHub Release đính kèm file `.apk`.
  - Có trang tĩnh `docs/download/index.html` sẵn sàng deploy lên Cloudflare Pages (`https://ieltsoasis.site/`) với link tải trực tiếp từ GitHub Releases.
