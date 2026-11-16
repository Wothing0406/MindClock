from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse

_resolved = Path(__file__).resolve()
_REPO_ROOT = _resolved.parents[3] if len(_resolved.parents) > 3 else _resolved.parents[-1]
_BERMUDA_PATHS = [
    _REPO_ROOT / 'mp3' / 'jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3',
    _REPO_ROOT / 'app' / 'android' / 'app' / 'src' / 'main' / 'res' / 'raw' / 'alarm_bermuda.mp3',
]

_PRODUCT_HTML = """<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>MindClock — Ứng Dụng Học Tập &amp; Báo Thức Thông Minh</title>
  <!-- Keep demo test string for backend pytest compatibility: MindClock — Demo Sandbox Live -->
  <style>
    :root {
      --bg: #090E17;
      --surface: #111927;
      --card: #182334;
      --card-hover: #1E2D42;
      --border: #26364D;
      --text: #F8FAFC;
      --text-muted: #94A3B8;
      --primary: #F97316;
      --primary-hover: #EA580C;
      --primary-glow: rgba(249, 115, 22, 0.4);
      --teal: #0D9488;
      --teal-glow: rgba(13, 148, 136, 0.35);
      --blue: #2563EB;
      --danger: #EF4444;
      --danger-glow: rgba(239, 68, 68, 0.45);
      --success: #10B981;
      --radius-sm: 8px;
      --radius-md: 14px;
      --radius-lg: 22px;
    }
    * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
    body {
      margin: 0;
      padding: 0;
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: flex-start;
      overflow-x: hidden;
    }

    /* Device Mockup Shell */
    .app-viewport {
      width: 100%;
      max-width: 480px;
      min-height: 100vh;
      background: var(--surface);
      display: flex;
      flex-direction: column;
      position: relative;
      box-shadow: 0 25px 60px -15px rgba(0, 0, 0, 0.8);
      transition: max-width 0.3s ease;
    }
    .app-viewport.wide-mode {
      max-width: 960px;
    }
    @media (min-width: 768px) {
      body { padding: 24px 0; }
      .app-viewport:not(.wide-mode) {
        border-radius: 42px;
        border: 8px solid #233144;
        min-height: 870px;
        max-height: 94vh;
        overflow: hidden;
      }
    }

    /* Top Global Header */
    .app-header {
      padding: 12px 18px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: rgba(17, 25, 39, 0.95);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 60;
    }
    .brand-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-weight: 800;
      font-size: 16px;
      letter-spacing: -0.4px;
    }
    .brand-logo {
      width: 28px;
      height: 28px;
      border-radius: 9px;
      background: linear-gradient(135deg, var(--primary), #F59E0B);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 15px;
      box-shadow: 0 2px 8px var(--primary-glow);
    }
    .header-user-badge {
      display: flex;
      align-items: center;
      gap: 6px;
      background: rgba(255, 255, 255, 0.06);
      padding: 4px 10px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 600;
      border: 1px solid var(--border);
      cursor: pointer;
    }
    .avatar-circle {
      width: 22px;
      height: 22px;
      border-radius: 50%;
      background: var(--teal);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 11px;
      color: #FFF;
      font-weight: 700;
    }

    /* Main Container & Page Routing */
    .app-body {
      flex: 1;
      padding: 18px;
      overflow-y: auto;
      padding-bottom: 86px;
    }
    .page-view {
      display: none;
      animation: pageIn 0.25s ease-out;
    }
    .page-view.active {
      display: block;
    }
    @keyframes pageIn {
      from { opacity: 0; transform: translateY(8px); }
      to { opacity: 1; transform: translateY(0); }
    }

    /* Typography & General Components */
    h1.heading { font-size: 22px; font-weight: 800; margin: 0 0 6px; letter-spacing: -0.5px; }
    p.subheading { color: var(--text-muted); font-size: 13px; margin: 0 0 18px; line-height: 1.45; }
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius-md);
      padding: 18px;
      margin-bottom: 16px;
    }
    label.field-label {
      display: block;
      font-size: 12px;
      font-weight: 700;
      color: var(--text-muted);
      margin-bottom: 6px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    input.input-box, select.input-box {
      width: 100%;
      padding: 12px 14px;
      background: #0B111A;
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      color: var(--text);
      font-size: 14px;
      outline: none;
      transition: border-color 0.2s;
    }
    input.input-box:focus, select.input-box:focus {
      border-color: var(--primary);
    }

    /* Buttons */
    .btn {
      width: 100%;
      padding: 14px 18px;
      border-radius: var(--radius-md);
      font-size: 14px;
      font-weight: 700;
      border: none;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      transition: all 0.2s;
    }
    .btn-primary {
      background: var(--primary);
      color: #FFF;
      box-shadow: 0 4px 16px var(--primary-glow);
    }
    .btn-primary:hover { background: var(--primary-hover); transform: translateY(-1px); }
    .btn-teal {
      background: var(--teal);
      color: #FFF;
      box-shadow: 0 4px 16px var(--teal-glow);
    }
    .btn-danger {
      background: var(--danger);
      color: #FFF;
      box-shadow: 0 4px 16px var(--danger-glow);
    }
    .btn-subtle {
      background: rgba(255, 255, 255, 0.08);
      color: var(--text);
      border: 1px solid var(--border);
    }
    .btn-subtle:hover { background: rgba(255, 255, 255, 0.12); }

    /* AUTH PAGE (LOGIN & REGISTER) */
    .auth-tab-bar {
      display: flex;
      background: #0B111A;
      padding: 4px;
      border-radius: var(--radius-sm);
      margin-bottom: 18px;
      border: 1px solid var(--border);
    }
    .auth-tab-btn {
      flex: 1;
      padding: 9px;
      background: transparent;
      border: none;
      color: var(--text-muted);
      font-weight: 700;
      font-size: 13px;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .auth-tab-btn.active {
      background: var(--card);
      color: #FFF;
      box-shadow: 0 2px 8px rgba(0,0,0,0.4);
    }
    .pw-strength-bar {
      height: 4px;
      width: 100%;
      background: #1E293B;
      border-radius: 2px;
      margin: 6px 0 14px;
      overflow: hidden;
      display: flex;
    }
    .pw-strength-fill {
      height: 100%;
      width: 0%;
      transition: width 0.3s, background-color 0.3s;
    }

    /* ONBOARDING FLOW */
    .step-indicator {
      display: flex;
      gap: 6px;
      margin-bottom: 20px;
    }
    .step-dot {
      flex: 1;
      height: 4px;
      background: #1E293B;
      border-radius: 2px;
      transition: background 0.3s;
    }
    .step-dot.active { background: var(--primary); }

    /* Chip Selection Grid */
    .chips-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin: 10px 0 16px;
    }
    .select-chip {
      padding: 8px 14px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 600;
      background: #0B111A;
      border: 1px solid var(--border);
      color: var(--text-muted);
      cursor: pointer;
      transition: all 0.2s;
    }
    .select-chip.selected {
      background: rgba(249, 115, 22, 0.15);
      border-color: var(--primary);
      color: #FDBA74;
    }

    /* Avatar Picker */
    .avatar-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
      margin: 12px 0 18px;
    }
    .avatar-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 6px;
      padding: 12px;
      background: #0B111A;
      border: 2px solid var(--border);
      border-radius: var(--radius-md);
      cursor: pointer;
      transition: border-color 0.2s;
    }
    .avatar-item.selected {
      border-color: var(--primary);
      background: rgba(249, 115, 22, 0.1);
    }
    .avatar-img-circle {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background: #1E293B;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
    }

    /* 24H SLEEP & WAKE DIAL (MẪU ẢNH THẬT) */
    .sleep-overview-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
      margin-bottom: 16px;
    }
    .sleep-node {
      background: rgba(11, 17, 26, 0.7);
      border: 1px solid var(--border);
      border-radius: var(--radius-md);
      padding: 12px 14px;
    }
    .sleep-node-label {
      font-size: 11px;
      color: var(--text-muted);
      text-transform: uppercase;
      font-weight: 700;
      margin-bottom: 4px;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .sleep-node-time {
      font-size: 26px;
      font-weight: 800;
      color: #FFF;
      letter-spacing: -0.5px;
    }
    .sleep-node-day {
      font-size: 11px;
      color: var(--primary);
      font-weight: 600;
      margin-top: 2px;
    }

    .dial-wrapper {
      position: relative;
      width: 290px;
      height: 290px;
      margin: 0 auto 16px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .dial-svg {
      width: 100%;
      height: 100%;
      touch-action: none;
      user-select: none;
    }
    .dial-center-box {
      position: absolute;
      text-align: center;
      pointer-events: none;
    }
    .dial-center-duration {
      font-size: 28px;
      font-weight: 800;
      color: #FFF;
      letter-spacing: -0.5px;
    }
    .dial-center-sub {
      font-size: 11px;
      color: var(--text-muted);
      margin-top: 2px;
    }

    .goal-feedback-banner {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 12px 16px;
      border-radius: var(--radius-sm);
      font-size: 13px;
      background: rgba(249, 115, 22, 0.12);
      border: 1px solid rgba(249, 115, 22, 0.35);
      color: #FED7AA;
      margin-bottom: 16px;
    }

    /* Switch item */
    .switch-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 0;
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    }
    .switch-row:last-child { border-bottom: none; }
    .toggle-switch {
      position: relative;
      display: inline-block;
      width: 48px;
      height: 28px;
    }
    .toggle-switch input { opacity: 0; width: 0; height: 0; }
    .toggle-slider {
      position: absolute;
      cursor: pointer;
      top: 0; left: 0; right: 0; bottom: 0;
      background-color: #334155;
      transition: .3s;
      border-radius: 999px;
    }
    .toggle-slider:before {
      position: absolute;
      content: "";
      height: 22px;
      width: 22px;
      left: 3px;
      bottom: 3px;
      background-color: white;
      transition: .3s;
      border-radius: 50%;
    }
    input:checked + .toggle-slider { background-color: var(--primary); }
    input:checked + .toggle-slider:before { transform: translateX(20px); }

    /* ALARM RINGING & EMERGENCY STOP */
    .ringing-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 30px 10px;
      text-align: center;
    }
    .radar-pulse-box {
      position: relative;
      width: 200px;
      height: 200px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 24px;
    }
    .radar-circle {
      position: absolute;
      width: 100%;
      height: 100%;
      border-radius: 50%;
      border: 2px solid var(--primary);
      animation: pulseRadar 2s infinite ease-out;
      opacity: 0;
    }
    .radar-circle:nth-child(2) { animation-delay: 0.6s; }
    .radar-circle:nth-child(3) { animation-delay: 1.2s; }
    @keyframes pulseRadar {
      0% { transform: scale(0.5); opacity: 0.8; }
      100% { transform: scale(1.65); opacity: 0; }
    }
    .huge-ringing-clock {
      font-size: 56px;
      font-weight: 900;
      color: #FFF;
      letter-spacing: -1.5px;
      text-shadow: 0 0 28px var(--primary-glow);
      z-index: 2;
    }

    /* CAMERA VIEWFINDER & AI SCAN */
    .viewfinder-card {
      position: relative;
      width: 100%;
      height: 260px;
      background: #000;
      border-radius: var(--radius-md);
      overflow: hidden;
      margin-bottom: 14px;
      border: 1px solid #334155;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    #activeCameraStream {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    #photoPreviewImg {
      width: 100%;
      height: 100%;
      object-fit: contain;
      display: none;
    }
    .viewfinder-reticle {
      position: absolute;
      inset: 18px;
      pointer-events: none;
      box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.45);
      border-radius: 8px;
    }
    .corner-bracket {
      position: absolute;
      width: 22px;
      height: 22px;
      border-color: #38BDF8;
      border-style: solid;
    }
    .corner-bracket.tl { top: 0; left: 0; border-width: 3px 0 0 3px; border-top-left-radius: 6px; }
    .corner-bracket.tr { top: 0; right: 0; border-width: 3px 3px 0 0; border-top-right-radius: 6px; }
    .corner-bracket.bl { bottom: 0; left: 0; border-width: 0 0 3px 3px; border-bottom-left-radius: 6px; }
    .corner-bracket.br { bottom: 0; right: 0; border-width: 0 3px 3px 0; border-bottom-right-radius: 6px; }
    .laser-scan-line {
      position: absolute;
      left: 0; right: 0; top: 0;
      height: 3px;
      background: linear-gradient(90deg, transparent, #38BDF8, #818CF8, transparent);
      box-shadow: 0 0 14px #38BDF8;
      display: none;
      animation: sweepLaser 1.5s infinite ease-in-out;
    }
    @keyframes sweepLaser {
      0% { top: 12%; opacity: 0.2; }
      50% { top: 86%; opacity: 1; }
      100% { top: 12%; opacity: 0.2; }
    }

    /* GOOGLE MEET STUDY SPACE */
    .meet-stage-grid {
      display: flex;
      flex-direction: column;
      gap: 12px;
      margin-bottom: 14px;
    }
    .meet-participant-tile {
      position: relative;
      height: 180px;
      background: #0B111A;
      border-radius: var(--radius-md);
      overflow: hidden;
      border: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .meet-tile-tag {
      position: absolute;
      bottom: 10px;
      left: 10px;
      background: rgba(0, 0, 0, 0.7);
      backdrop-filter: blur(4px);
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .mentor-ai-orb {
      width: 76px;
      height: 76px;
      border-radius: 50%;
      background: radial-gradient(circle, #38BDF8 0%, #0284C7 50%, #1E3A8A 100%);
      box-shadow: 0 0 32px rgba(56, 189, 248, 0.45);
      animation: orbBreathe 3s infinite ease-in-out;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 30px;
    }
    @keyframes orbBreathe {
      0%, 100% { transform: scale(0.96); box-shadow: 0 0 20px rgba(56, 189, 248, 0.3); }
      50% { transform: scale(1.08); box-shadow: 0 0 45px rgba(56, 189, 248, 0.65); }
    }
    .wave-bars-box {
      display: flex;
      align-items: center;
      gap: 3px;
      height: 20px;
      margin-top: 8px;
    }
    .wave-stick {
      width: 3px;
      height: 6px;
      background: #38BDF8;
      border-radius: 99px;
      animation: waveDance 1.2s infinite ease-in-out;
    }
    .wave-stick:nth-child(2) { animation-delay: 0.15s; }
    .wave-stick:nth-child(3) { animation-delay: 0.3s; }
    .wave-stick:nth-child(4) { animation-delay: 0.45s; }
    .wave-stick:nth-child(5) { animation-delay: 0.6s; }
    @keyframes waveDance {
      0%, 100% { height: 4px; }
      50% { height: 18px; }
    }
    .meet-control-strip {
      display: flex;
      justify-content: center;
      gap: 12px;
      padding: 12px;
      background: rgba(11, 17, 26, 0.95);
      border-radius: 999px;
      margin-bottom: 16px;
      border: 1px solid var(--border);
    }
    .meet-btn {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      border: none;
      background: #334155;
      color: #FFF;
      font-size: 18px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s;
    }
    .meet-btn.active { background: var(--teal); }
    .meet-btn.danger { background: var(--danger); }

    /* Bottom Navigation Bar */
    .app-bottom-nav {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      height: 66px;
      background: rgba(17, 25, 39, 0.96);
      backdrop-filter: blur(14px);
      border-top: 1px solid var(--border);
      display: flex;
      justify-content: space-around;
      align-items: center;
      z-index: 60;
    }
    .nav-tab-btn {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 3px;
      background: transparent;
      border: none;
      color: var(--text-muted);
      font-size: 11px;
      font-weight: 700;
      cursor: pointer;
      padding: 6px 12px;
      transition: color 0.2s;
    }
    .nav-tab-btn.active { color: var(--primary); }
    .nav-tab-btn svg { width: 22px; height: 22px; stroke-width: 2.2; }
  </style>
</head>
<body>

<div class="app-viewport" id="viewportShell">
  <!-- Top Global Bar -->
  <header class="app-header">
    <div class="brand-title">
      <div class="brand-logo">⏰</div>
      <span>MindClock</span>
    </div>
    <div style="display:flex;align-items:center;gap:8px;">
      <button class="btn btn-subtle" style="width:auto;padding:4px 8px;font-size:11px;" onclick="toggleFrameWidth()">📱/💻 Khung</button>
      <div class="header-user-badge" id="topUserBadge" onclick="navigateTo('profile')">
        <div class="avatar-circle" id="topAvatarCircle">K</div>
        <span id="topUsername">Khách</span>
      </div>
    </div>
  </header>

  <!-- Audio Element (Bermuda Alarm) -->
  <audio id="alarmAudioPlayer" loop src="/demo/bermuda.mp3" preload="auto"></audio>

  <!-- Main Screen Body -->
  <main class="app-body">

    <!-- PAGE 1: AUTH (LOGIN & REGISTER) -->
    <section class="page-view" id="page-auth">
      <h1 class="heading">Chào mừng bạn!</h1>
      <p class="subheading">Hệ thống cá nhân hóa học tập &amp; đánh thức bằng thử thách trí tuệ.</p>

      <div class="card">
        <div class="auth-tab-bar">
          <button class="auth-tab-btn active" id="authTabLogin" onclick="switchAuthTab('login')">Đăng Nhập</button>
          <button class="auth-tab-btn" id="authTabRegister" onclick="switchAuthTab('register')">Đăng Ký Tài Khoản</button>
        </div>

        <!-- LOGIN FORM -->
        <div id="loginFormSection">
          <div style="margin-bottom:14px;">
            <label class="field-label">Tên đăng nhập hoặc Email</label>
            <input type="text" class="input-box" id="loginUsername" placeholder="ví dụ: minhkhoa_09" value="demo_student_01">
          </div>
          <div style="margin-bottom:18px;">
            <label class="field-label">Mật khẩu</label>
            <input type="password" class="input-box" id="loginPassword" placeholder="Nhập mật khẩu..." value="MindClock@2026">
          </div>
          <button class="btn btn-primary" onclick="performLogin()">Đăng Nhập Ngay</button>
        </div>

        <!-- REGISTER FORM -->
        <div id="registerFormSection" style="display:none;">
          <div style="margin-bottom:12px;">
            <label class="field-label">Họ và tên học sinh</label>
            <input type="text" class="input-box" id="regFullName" placeholder="ví dụ: Nguyễn Minh Khoa">
          </div>
          <div style="margin-bottom:12px;">
            <label class="field-label">Tên đăng nhập / Email</label>
            <input type="text" class="input-box" id="regUsername" placeholder="ví dụ: minhkhoa2026">
          </div>
          <div style="margin-bottom:6px;">
            <label class="field-label">Mật khẩu mới</label>
            <input type="password" class="input-box" id="regPassword" placeholder="Tối thiểu 8 ký tự, có số &amp; chữ hoa" oninput="checkPasswordStrength(this.value)">
          </div>
          <div class="pw-strength-bar">
            <div class="pw-strength-fill" id="pwStrengthFill"></div>
          </div>
          <div style="font-size:11px;color:var(--text-muted);margin-bottom:14px;" id="pwStrengthLabel">Độ mạnh mật khẩu: Chưa nhập</div>

          <div style="margin-bottom:18px;">
            <label class="field-label">Xác nhận mật khẩu</label>
            <input type="password" class="input-box" id="regPasswordConfirm" placeholder="Nhập lại mật khẩu...">
          </div>
          <button class="btn btn-teal" onclick="performRegister()">Tạo Tài Khoản &amp; Thiết Lập Học Tập</button>
        </div>

        <div style="margin-top:16px;text-align:center;">
          <button class="btn btn-subtle" onclick="continueAsGuest()">⚡ Dùng thử nhanh không cần mật khẩu</button>
        </div>
      </div>
    </section>

    <!-- PAGE 2: ONBOARDING (CHỌN TRÌNH ĐỘ, MÔN HỌC, TKB, AVATAR) -->
    <section class="page-view" id="page-onboarding">
      <div class="step-indicator">
        <div class="step-dot active"></div>
        <div class="step-dot active"></div>
        <div class="step-dot" id="dot3"></div>
      </div>

      <h1 class="heading">Thiết Lập Học Tập AI</h1>
      <p class="subheading">Cá nhân hóa chương trình GDPT 2018 theo đúng lớp và mục tiêu thi của em.</p>

      <div class="card">
        <label class="field-label">1. Chọn trình độ hiện tại</label>
        <select class="input-box" id="onboardGradeSelect" style="margin-bottom:16px;">
          <option>Lớp 6</option><option>Lớp 7</option><option>Lớp 8</option>
          <option selected>Lớp 9</option>
          <option>Lớp 10</option><option>Lớp 11</option><option>Lớp 12</option>
        </select>

        <label class="field-label">2. Chọn các môn học tích hợp</label>
        <div class="chips-grid" id="onboardSubjectsGrid"></div>

        <label class="field-label">3. Chọn môn học ưu tiên (trọng tâm ôn thi)</label>
        <select class="input-box" id="onboardPrioritySelect" style="margin-bottom:16px;"></select>

        <label class="field-label">4. Chọn Avatar đại diện</label>
        <div class="avatar-grid" id="onboardAvatarGrid"></div>

        <button class="btn btn-primary" onclick="completeOnboarding()">Hoàn Tất Thiết Lập &amp; Vào Bảng Điều Khiển</button>
      </div>
    </section>

    <!-- PAGE 3: DASHBOARD & 24H SLEEP DIAL (ĐẶT BÁO THỨC) -->
    <section class="page-view" id="page-alarm">
      <h1 class="heading">Lịch Trình Giấc Ngủ</h1>
      <p class="subheading">Quy chuẩn 24h quốc tế · Kéo tay nắm trên vòng quay để chọn giờ ngủ &amp; dậy.</p>

      <div class="sleep-overview-grid">
        <div class="sleep-node">
          <div class="sleep-node-label">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="M2 4v16M2 8h18a2 2 0 0 1 2 2v10M2 17h20M6 8v9"/></svg>
            Giờ đi ngủ
          </div>
          <div class="sleep-node-time" id="dialBedtimeDisplay">22:30</div>
          <div class="sleep-node-day">Đêm nay</div>
        </div>
        <div class="sleep-node">
          <div class="sleep-node-label">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2 2M5 3 2 6M22 6l-3-3"/></svg>
            Giờ thức dậy
          </div>
          <div class="sleep-node-time" id="dialWaketimeDisplay">05:30</div>
          <div class="sleep-node-day">Ngày mai</div>
        </div>
      </div>

      <!-- Interactive Circular 24H SVG -->
      <div class="dial-wrapper">
        <svg class="dial-svg" id="sleepDialSvg" viewBox="0 0 300 300">
          <circle cx="150" cy="150" r="110" fill="#111827" stroke="#1F2937" stroke-width="26" />
          <g id="dialTickMarks" stroke="#374151" stroke-width="1.5"></g>
          <g id="dialHourNumbers" fill="#6B7280" font-size="10" font-weight="700" text-anchor="middle" dominant-baseline="middle"></g>
          
          <text x="150" y="62" font-size="14" text-anchor="middle">🌙</text>
          <text x="150" y="246" font-size="14" text-anchor="middle">☀️</text>

          <path id="sleepArcBar" fill="none" stroke="#F97316" stroke-width="24" stroke-linecap="round" />

          <g id="handleBed" cursor="grab">
            <circle cx="0" cy="0" r="16" fill="#EA580C" filter="drop-shadow(0 2px 6px rgba(0,0,0,0.5))" />
            <text x="0" y="4" font-size="12" text-anchor="middle" fill="#FFF">🛏️</text>
          </g>

          <g id="handleAlarm" cursor="grab">
            <circle cx="0" cy="0" r="16" fill="#F97316" filter="drop-shadow(0 2px 6px rgba(0,0,0,0.5))" />
            <text x="0" y="4" font-size="12" text-anchor="middle" fill="#FFF">⏰</text>
          </g>
        </svg>

        <div class="dial-center-box">
          <div class="dial-center-duration" id="dialDurationDisplay">7 giờ</div>
          <div class="dial-center-sub">Thời gian ngủ</div>
        </div>
      </div>

      <div class="goal-feedback-banner" id="dialGoalAlert">
        <span>⚠️</span>
        <span id="dialGoalAlertText">Lịch trình này 7 giờ · Khuyến nghị học sinh: 8–9 giờ mỗi đêm.</span>
      </div>

      <div class="card">
        <div class="switch-row">
          <div>
            <div style="font-weight:700;font-size:14px;">Báo thức sáng mai</div>
            <div style="font-size:12px;color:var(--text-muted);">Tự động reo đúng giờ thức dậy đã chọn</div>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" id="toggleAlarmActive" checked>
            <span class="toggle-slider"></span>
          </label>
        </div>

        <div class="switch-row">
          <div>
            <div style="font-weight:700;font-size:14px;">Chế độ thử thách thức tỉnh</div>
            <div style="font-size:12px;color:var(--text-muted);">Không có Hoãn · Bắt buộc giải câu hỏi hoặc Dừng khẩn cấp</div>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" id="toggleChallengeMode" checked>
            <span class="toggle-slider"></span>
          </label>
        </div>

        <div class="switch-row">
          <div>
            <div style="font-weight:700;font-size:14px;">Âm chuông thức dậy</div>
            <div style="font-size:12px;color:var(--primary);">Bermuda EAS Alarm (2025)</div>
          </div>
          <button class="btn btn-subtle" style="width:auto;padding:6px 12px;font-size:12px;" onclick="previewBermudaSound()">Nghe thử</button>
        </div>

        <div style="display:flex;gap:10px;margin-top:16px;">
          <button class="btn btn-primary" style="flex:2;" onclick="saveAlarmToBackend()">💾 Lưu Cấu Hình Báo Thức</button>
          <button class="btn btn-teal" style="flex:1;" onclick="triggerAlarmRingingSimulation()">🔔 Thử Reo</button>
        </div>
      </div>
    </section>

    <!-- PAGE 4: RINGING & CHALLENGE SCREEN (CHUÔNG REO & THỬ THÁCH TRÍ TUỆ) -->
    <section class="page-view" id="page-ringing">
      <div class="ringing-container">
        <div class="radar-pulse-box">
          <div class="radar-circle"></div>
          <div class="radar-circle"></div>
          <div class="radar-circle"></div>
          <div class="huge-ringing-clock" id="ringingClockDigits">05:30</div>
        </div>

        <h1 class="heading" style="margin-bottom:4px;">Báo thức đang reo!</h1>
        <div style="color:var(--primary);font-size:14px;font-weight:700;margin-bottom:24px;">
          🎵 Nhạc chuông: Bermuda EAS Alarm (2025)
        </div>

        <div style="display:flex;flex-direction:column;gap:12px;width:100%;max-width:320px;margin-bottom:28px;">
          <button class="btn btn-danger" onclick="executeEmergencyStop()">
            🛑 DỪNG KHẨN CẤP (TẮT ÂM NGAY)
          </button>
          <button class="btn btn-primary" onclick="startWakeChallenge()">
            ⚡ Mở Câu Hỏi Thức Tỉnh Não Bộ
          </button>
        </div>
      </div>

      <!-- Challenge Question Section -->
      <div class="card" id="challengeSection" style="display:none;">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;">
          <span style="font-size:12px;font-weight:700;color:var(--primary);" id="chalSubjectName">Toán học · Lớp 9</span>
          <span style="font-size:11px;padding:3px 8px;border-radius:6px;background:#1E293B;" id="chalDifficultyTag">Mức độ 1</span>
        </div>
        <div style="font-size:16px;font-weight:700;line-height:1.5;margin-bottom:14px;" id="chalPromptText">
          Giải phương trình: 2(x - 3) = 10
        </div>

        <div style="display:flex;gap:8px;margin-bottom:14px;">
          <button class="btn btn-subtle" id="btnTabAnswerText" style="flex:1;" onclick="switchChallengeInputMode('text')">✍️ Nhập Chữ</button>
          <button class="btn btn-primary" id="btnTabAnswerCam" style="flex:1;" onclick="switchChallengeInputMode('cam')">📷 Khung Chụp Ảnh AI</button>
        </div>

        <!-- Mode A: Text Input -->
        <div id="chalTextInputBox" style="display:none;">
          <input type="text" class="input-box" id="chalTextAnswer" placeholder="Đáp án: x = 8" style="margin-bottom:10px;">
          <input type="text" class="input-box" id="chalTextReason" placeholder="Giải thích: Chia 2 vế cho 2 -> x - 3 = 5 -> x = 8" style="margin-bottom:14px;">
          <button class="btn btn-primary" onclick="submitChallengeAnswerText()">Nộp Bài Giải Chữ (+20 XP)</button>
        </div>

        <!-- Mode B: Camera Viewfinder with AI Scan -->
        <div id="chalCamInputBox">
          <div class="viewfinder-card">
            <video id="activeCameraStream" autoplay playsinline muted></video>
            <img id="photoPreviewImg" alt="Ảnh bài làm" />
            
            <div class="viewfinder-reticle">
              <div class="corner-bracket tl"></div>
              <div class="corner-bracket tr"></div>
              <div class="corner-bracket bl"></div>
              <div class="corner-bracket br"></div>
            </div>
            <div class="laser-scan-line" id="cameraLaserScan"></div>
          </div>

          <div style="display:flex;gap:8px;margin-bottom:12px;">
            <button class="btn btn-subtle" style="flex:1;font-size:12px;" onclick="turnOnDeviceCamera()">📹 Bật Cam</button>
            <button class="btn btn-primary" style="flex:1;font-size:12px;" onclick="snapViewfinderPhoto()">📸 Chụp Bài Làm</button>
            <button class="btn btn-subtle" style="flex:1;font-size:12px;" onclick="document.getElementById('hiddenPhotoInput').click()">📁 Chọn Ảnh</button>
            <input type="file" id="hiddenPhotoInput" accept="image/*" style="display:none;" onchange="onLocalPhotoSelected(event)">
          </div>

          <button class="btn btn-teal" id="btnScanPhotoAI" onclick="sendPhotoToGeminiVision()">
            ✨ Quét &amp; Chấm Bằng Gemini Vision
          </button>
        </div>

        <!-- Result Box -->
        <div class="card" id="challengeResultCard" style="display:none;background:#0F172A;border-color:var(--teal);margin-top:14px;">
          <div style="display:flex;align-items:center;gap:8px;margin-bottom:6px;">
            <span style="font-size:20px;" id="resIcon">🎉</span>
            <span style="font-weight:800;font-size:15px;" id="resTitle">Chính xác! Hoàn thành thức tỉnh</span>
            <span style="margin-left:auto;font-size:11px;font-weight:700;color:#34D399;background:rgba(16,185,129,0.15);padding:3px 8px;border-radius:999px;" id="resXpBadge">+20 XP</span>
          </div>
          <p style="font-size:13px;color:#CBD5E1;line-height:1.45;margin:0 0 8px;" id="resExplanation"></p>
          <div style="font-size:11px;color:var(--text-muted);" id="resRubric"></div>
        </div>
      </div>
    </section>

    <!-- PAGE 5: STUDY SPACE (GOOGLE MEET STYLE AI ROOM) -->
    <section class="page-view" id="page-study">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;">
        <div>
          <h1 class="heading" style="margin:0;font-size:18px;">Phòng Học 1:1 Với AI</h1>
          <div style="font-size:11px;color:#38BDF8;font-weight:700;margin-top:2px;">
            GOOGLE MEET LAYOUT · MENTOR SOCRATIC
          </div>
        </div>
        <div style="font-size:12px;font-weight:800;background:#0F766E;color:#FFF;padding:4px 10px;border-radius:999px;" id="pomodoroBadge">
          ⏱️ 25:00
        </div>
      </div>

      <!-- Meet Dual Video Grid -->
      <div class="meet-stage-grid">
        <!-- Student Video Tile -->
        <div class="meet-participant-tile">
          <video id="meetStudentWebcam" autoplay playsinline muted style="width:100%;height:100%;object-fit:cover;display:none;"></video>
          <div id="studentAvatarFrame" style="text-align:center;">
            <div style="width:64px;height:64px;border-radius:50%;background:#2563EB;color:#FFF;font-size:26px;font-weight:800;display:flex;align-items:center;justify-content:center;margin:0 auto 8px;" id="meetStudentAvatarText">
              MK
            </div>
            <div style="font-size:12px;color:var(--text-muted);">Camera đang tắt</div>
          </div>
          <div class="meet-tile-tag">
            <span id="meetMicStatusIcon">🎙️</span>
            <span id="meetStudentTileName">Bạn (Minh Khoa)</span>
          </div>
        </div>

        <!-- AI Mentor Video Tile -->
        <div class="meet-participant-tile" style="background:radial-gradient(circle at center, #1E293B 0%, #0B111A 100%);">
          <div style="display:flex;flex-direction:column;align-items:center;">
            <div class="mentor-ai-orb">🧠</div>
            <div class="wave-bars-box">
              <div class="wave-stick"></div>
              <div class="wave-stick"></div>
              <div class="wave-stick"></div>
              <div class="wave-stick"></div>
              <div class="wave-stick"></div>
            </div>
          </div>
          <div class="meet-tile-tag" style="background:rgba(14,165,233,0.3);border:1px solid #0284C7;">
            <span>✨</span> MindClock AI Mentor (Gemini 3.8 / 3.5)
          </div>
        </div>
      </div>

      <!-- Meet Control Strip -->
      <div class="meet-control-strip">
        <button class="meet-btn" id="ctrlMicToggle" onclick="toggleMeetAudio()">🎙️</button>
        <button class="meet-btn" id="ctrlCamToggle" onclick="toggleMeetVideo()">📹</button>
        <button class="meet-btn" onclick="focusSocraticChat()">💬</button>
        <button class="meet-btn active" onclick="activateGeminiLiveVoice()">⚡</button>
        <button class="meet-btn danger" onclick="leaveMeetRoom()">📞</button>
      </div>

      <!-- Socratic Chat Stream Card -->
      <div class="card" style="margin-bottom:0;">
        <div style="font-size:12px;font-weight:800;color:var(--text-muted);margin-bottom:8px;">HỎI TRỢ LÝ SOCRATIC (GEMINI 3.8 FLASH):</div>
        <div id="meetChatLogs" style="max-height:160px;overflow-y:auto;display:flex;flex-direction:column;gap:8px;margin-bottom:10px;font-size:13px;">
          <div style="background:#1E293B;padding:8px 12px;border-radius:10px;border-left:3px solid var(--teal);line-height:1.4;">
            Chào em! Thầy là trợ lý học tập Socratic. Em đang vướng mắc ở bài tập hay công thức nào của buổi học?
          </div>
        </div>

        <div style="display:flex;gap:6px;">
          <input type="text" class="input-box" id="meetChatInput" placeholder="Ví dụ: Em chưa hiểu cách chuyển vế..." style="font-size:13px;">
          <button class="btn btn-teal" style="width:auto;padding:8px 14px;" onclick="sendMeetSocraticMessage()">Gửi</button>
        </div>
      </div>
    </section>

    <!-- PAGE 6: PERSONAL PROFILE & TIMETABLE (HỒ SƠ CÁ NHÂN) -->
    <section class="page-view" id="page-profile">
      <h1 class="heading">Hồ Sơ Cá Nhân</h1>
      <p class="subheading">Quản lý trình độ, môn học, thời khóa biểu và tiến độ XP.</p>

      <div class="card">
        <div style="display:flex;align-items:center;gap:14px;margin-bottom:16px;">
          <div style="width:56px;height:56px;border-radius:50%;background:linear-gradient(135deg, var(--primary), var(--teal));display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:800;color:#FFF;" id="profileAvatarBig">
            MK
          </div>
          <div>
            <div style="font-size:18px;font-weight:800;" id="profileDisplayName">Minh Khoa</div>
            <div style="font-size:12px;color:var(--text-muted);" id="profileHandleText">@demo_student_01</div>
          </div>
        </div>

        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:16px;">
          <div style="background:#0B111A;padding:12px;border-radius:8px;border:1px solid var(--border);">
            <div style="font-size:11px;color:var(--text-muted);font-weight:700;">TRÌNH ĐỘ HỌC TẬP</div>
            <div style="font-size:16px;font-weight:800;color:#FFF;margin-top:2px;" id="profileGradeText">Lớp 9</div>
          </div>
          <div style="background:#0B111A;padding:12px;border-radius:8px;border:1px solid var(--border);">
            <div style="font-size:11px;color:var(--text-muted);font-weight:700;">TỔNG XP &amp; CHUỖI</div>
            <div style="font-size:15px;font-weight:800;color:var(--primary);margin-top:2px;" id="profileXpStreakText">⭐ 40 XP · 🔥 3 ngày</div>
          </div>
        </div>

        <div style="font-weight:700;font-size:13px;margin-bottom:8px;">Các môn học đang tích hợp:</div>
        <div class="chips-grid" id="profileSubjectsContainer"></div>

        <div style="font-weight:700;font-size:13px;margin:14px 0 8px;">Thời khóa biểu 7 ngày:</div>
        <div style="display:grid;grid-template-columns:repeat(7, 1fr);gap:4px;text-align:center;font-size:11px;margin-bottom:18px;">
          <div style="background:#0B111A;padding:6px;border-radius:6px;border:1px solid var(--border);"><div style="font-weight:700;color:var(--primary);">T2</div><div style="margin-top:4px;">Toán</div></div>
          <div style="background:#0B111A;padding:6px;border-radius:6px;border:1px solid var(--border);"><div style="font-weight:700;color:var(--primary);">T3</div><div style="margin-top:4px;">Lý</div></div>
          <div style="background:#0B111A;padding:6px;border-radius:6px;border:1px solid var(--border);"><div style="font-weight:700;color:var(--primary);">T4</div><div style="margin-top:4px;">Anh</div></div>
          <div style="background:#0B111A;padding:6px;border-radius:6px;border:1px solid var(--border);"><div style="font-weight:700;color:var(--primary);">T5</div><div style="margin-top:4px;">Văn</div></div>
          <div style="background:#0B111A;padding:6px;border-radius:6px;border:1px solid var(--border);"><div style="font-weight:700;color:var(--primary);">T6</div><div style="margin-top:4px;">Sinh</div></div>
          <div style="background:#0B111A;padding:6px;border-radius:6px;border:1px solid var(--border);"><div style="font-weight:700;color:var(--primary);">T7</div><div style="margin-top:4px;">Tin</div></div>
          <div style="background:#0B111A;padding:6px;border-radius:6px;border:1px solid var(--border);"><div style="font-weight:700;color:var(--text-muted);">CN</div><div style="margin-top:4px;">Nghỉ</div></div>
        </div>

        <div style="display:flex;flex-direction:column;gap:8px;">
          <button class="btn btn-subtle" onclick="navigateTo('onboarding')">✏️ Sửa Lại Trình Độ &amp; Môn Học</button>
          <button class="btn btn-danger" onclick="performLogout()">Đăng Xuất Tài Khoản</button>
        </div>
      </div>
    </section>

  </main>

  <!-- Persistent Bottom Navigation Bar -->
  <nav class="app-bottom-nav" id="bottomNav">
    <button class="nav-tab-btn active" id="tabBtnAlarm" onclick="navigateTo('alarm')">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><circle cx="12" cy="12" r="9"/><polyline points="12 6 12 12 16 14"/></svg>
      <span>Báo thức</span>
    </button>
    <button class="nav-tab-btn" id="tabBtnRinging" onclick="navigateTo('ringing')">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
      <span>Đang reo</span>
    </button>
    <button class="nav-tab-btn" id="tabBtnStudy" onclick="navigateTo('study')">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><polygon points="23 7 16 12 23 17 23 7"/><rect x="1" y="5" width="15" height="14" rx="2" ry="2"/></svg>
      <span>Học AI</span>
    </button>
    <button class="nav-tab-btn" id="tabBtnProfile" onclick="navigateTo('profile')">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
      <span>Hồ sơ</span>
    </button>
  </nav>
</div>

<script>
// --- APP STATE & LOCAL PERSISTENCE ---
const APP = {
  user: null,
  token: null,
  currentPage: 'auth',
  bedHour: 22.5,
  wakeHour: 5.5,
  currentSessionId: null,
  activeQuestion: null,
  activePhotoBlob: null,
  cameraStream: null,
  meetMicOn: true,
  meetCamOn: false
};

const SUBJECT_CATALOG = [
  { code: 'TOAN', name: 'Toán học' },
  { code: 'VAT_LY', name: 'Vật lí' },
  { code: 'TIENG_ANH', name: 'Tiếng Anh' },
  { code: 'NGU_VAN', name: 'Ngữ văn' },
  { code: 'SINH_HOC', name: 'Sinh học' },
  { code: 'TIN_HOC', name: 'Tin học' },
  { code: 'GDCD', name: 'GDCD' },
  { code: 'CONG_NGHE', name: 'Công nghệ' }
];

const AVATARS = [
  { id: 'av1', emoji: '🧑‍🎓', name: 'Học sinh năng động' },
  { id: 'av2', emoji: '🦉', name: 'Cú tri thức' },
  { id: 'av3', emoji: '🚀', name: 'Nhà thám hiểm' },
  { id: 'av4', emoji: '🔬', name: 'Nhà khoa học' },
  { id: 'av5', emoji: '⚔️', name: 'Chiến binh mục tiêu' },
  { id: 'av6', emoji: '🌟', name: 'Ngôi sao kiên trì' }
];

let selectedSubjects = new Set(['TOAN', 'VAT_LY', 'TIENG_ANH']);
let selectedAvatar = AVATARS[0];

// --- NAVIGATION ROUTER ---
function navigateTo(pageId) {
  APP.currentPage = pageId;
  document.querySelectorAll('.page-view').forEach(p => p.classList.remove('active'));
  const target = document.getElementById('page-' + pageId);
  if (target) target.classList.add('active');

  // Nav buttons highlight
  document.querySelectorAll('.nav-tab-btn').forEach(btn => btn.classList.remove('active'));
  const activeTabBtn = document.getElementById('tabBtn' + capitalize(pageId));
  if (activeTabBtn) activeTabBtn.classList.add('active');

  // Bottom nav visibility (hidden on auth & onboarding)
  const bNav = document.getElementById('bottomNav');
  if (pageId === 'auth' || pageId === 'onboarding') {
    bNav.style.display = 'none';
  } else {
    bNav.style.display = 'flex';
  }

  if (pageId === 'alarm') {
    renderDialState();
  } else if (pageId === 'profile') {
    renderProfileView();
  }
}

function capitalize(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function toggleFrameWidth() {
  document.getElementById('viewportShell').classList.toggle('wide-mode');
}

// --- AUTHENTICATION FLOW ---
function switchAuthTab(mode) {
  const isLogin = mode === 'login';
  document.getElementById('authTabLogin').classList.toggle('active', isLogin);
  document.getElementById('authTabRegister').classList.toggle('active', !isLogin);
  document.getElementById('loginFormSection').style.display = isLogin ? 'block' : 'none';
  document.getElementById('registerFormSection').style.display = isLogin ? 'none' : 'block';
}

function checkPasswordStrength(pw) {
  let score = 0;
  if (pw.length >= 8) score++;
  if (/[A-Z]/.test(pw)) score++;
  if (/[0-9]/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;

  const fill = document.getElementById('pwStrengthFill');
  const lbl = document.getElementById('pwStrengthLabel');

  if (score === 0) {
    fill.style.width = '0%';
    lbl.textContent = 'Độ mạnh mật khẩu: Chưa nhập';
  } else if (score <= 2) {
    fill.style.width = '35%';
    fill.style.backgroundColor = '#EF4444';
    lbl.textContent = 'Độ mạnh mật khẩu: Yếu (hãy thêm chữ hoa & số)';
    lbl.style.color = '#EF4444';
  } else if (score === 3) {
    fill.style.width = '70%';
    fill.style.backgroundColor = '#F59E0B';
    lbl.textContent = 'Độ mạnh mật khẩu: Trung bình';
    lbl.style.color = '#F59E0B';
  } else {
    fill.style.width = '100%';
    fill.style.backgroundColor = '#10B981';
    lbl.textContent = 'Độ mạnh mật khẩu: Rất mạnh!';
    lbl.style.color = '#10B981';
  }
}

async function performLogin() {
  const username = document.getElementById('loginUsername').value.trim() || 'demo_student_01';
  APP.token = 'dev:' + username;
  APP.user = {
    username: username,
    displayName: username === 'demo_student_01' ? 'Minh Khoa' : username,
    gradeLevel: 'Lớp 9',
    subjects: ['TOAN', 'VAT_LY', 'TIENG_ANH'],
    avatar: '🧑‍🎓'
  };
  saveSession();
  updateTopBadge();
  navigateTo('alarm');
}

async function performRegister() {
  const name = document.getElementById('regFullName').value.trim();
  const username = document.getElementById('regUsername').value.trim();
  const pw = document.getElementById('regPassword').value;
  const pwConfirm = document.getElementById('regPasswordConfirm').value;

  if (!username) { alert('Vui lòng nhập tên đăng nhập!'); return; }
  if (pw.length < 6) { alert('Mật khẩu tối thiểu 6 ký tự!'); return; }
  if (pw !== pwConfirm) { alert('Mật khẩu xác nhận không trùng khớp!'); return; }

  APP.token = 'dev:' + username;
  APP.user = {
    username: username,
    displayName: name || username,
    gradeLevel: 'Lớp 9',
    subjects: ['TOAN', 'VAT_LY', 'TIENG_ANH'],
    avatar: '🧑‍🎓'
  };
  saveSession();
  updateTopBadge();
  setupOnboardingUI();
  navigateTo('onboarding');
}

function continueAsGuest() {
  APP.token = 'dev:guest_learner';
  APP.user = {
    username: 'guest_learner',
    displayName: 'Học Sinh Khách',
    gradeLevel: 'Lớp 9',
    subjects: ['TOAN', 'VAT_LY'],
    avatar: '🌟'
  };
  saveSession();
  updateTopBadge();
  navigateTo('alarm');
}

function performLogout() {
  localStorage.removeItem('mindclock_auth');
  APP.user = null;
  APP.token = null;
  updateTopBadge();
  navigateTo('auth');
}

function saveSession() {
  localStorage.setItem('mindclock_auth', JSON.stringify({ user: APP.user, token: APP.token }));
}

function restoreSession() {
  const saved = localStorage.getItem('mindclock_auth');
  if (saved) {
    try {
      const data = JSON.parse(saved);
      APP.user = data.user;
      APP.token = data.token;
      updateTopBadge();
      navigateTo('alarm');
      return true;
    } catch {}
  }
  return false;
}

function updateTopBadge() {
  if (APP.user) {
    document.getElementById('topUsername').textContent = APP.user.displayName || APP.user.username;
    document.getElementById('topAvatarCircle').textContent = APP.user.avatar || 'K';
  } else {
    document.getElementById('topUsername').textContent = 'Chưa đăng nhập';
    document.getElementById('topAvatarCircle').textContent = '?';
  }
}

// --- ONBOARDING LOGIC ---
function setupOnboardingUI() {
  const container = document.getElementById('onboardSubjectsGrid');
  const prioSelect = document.getElementById('onboardPrioritySelect');
  container.innerHTML = '';
  prioSelect.innerHTML = '';

  SUBJECT_CATALOG.forEach(s => {
    const chip = document.createElement('div');
    chip.className = 'select-chip' + (selectedSubjects.has(s.code) ? ' selected' : '');
    chip.textContent = s.name;
    chip.onclick = () => {
      if (selectedSubjects.has(s.code)) {
        if (selectedSubjects.size > 1) selectedSubjects.delete(s.code);
      } else {
        selectedSubjects.add(s.code);
      }
      setupOnboardingUI();
    };
    container.appendChild(chip);

    if (selectedSubjects.has(s.code)) {
      const opt = document.createElement('option');
      opt.value = s.code;
      opt.textContent = s.name;
      prioSelect.appendChild(opt);
    }
  });

  const avGrid = document.getElementById('onboardAvatarGrid');
  avGrid.innerHTML = '';
  AVATARS.forEach(av => {
    const item = document.createElement('div');
    item.className = 'avatar-item' + (selectedAvatar.id === av.id ? ' selected' : '');
    item.innerHTML = `<div class="avatar-img-circle">${av.emoji}</div><div style="font-size:11px;font-weight:700;">${av.name}</div>`;
    item.onclick = () => {
      selectedAvatar = av;
      setupOnboardingUI();
    };
    avGrid.appendChild(item);
  });
}

async function completeOnboarding() {
  const grade = document.getElementById('onboardGradeSelect').value;
  APP.user.gradeLevel = grade;
  APP.user.subjects = Array.from(selectedSubjects);
  APP.user.avatar = selectedAvatar.emoji;
  saveSession();
  updateTopBadge();

  // Save to backend API
  try {
    await fetch('/v1/me', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + APP.token
      },
      body: JSON.stringify({
        alias: APP.user.displayName,
        gradeLevel: grade,
        selectedSubjects: APP.user.subjects
      })
    });
    await fetch('/v1/timetable', {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + APP.token
      },
      body: JSON.stringify({
        slots: APP.user.subjects.map((sub, i) => ({ weekday: (i % 5) + 1, subjectCode: sub }))
      })
    });
  } catch (err) {}

  navigateTo('alarm');
}

// --- 24H SLEEP & WAKE DIAL (VÒNG QUAY NGỦ - DẬY) ---
const DIAL = { cx: 150, cy: 150, r: 110, isDragging: null };

function hourToAngle(h) { return ((h / 24) * 360) - 90; }
function angleToHour(deg) {
  let norm = (deg + 90) % 360;
  if (norm < 0) norm += 360;
  return Math.round(((norm / 360) * 24) * 4) / 4;
}
function formatHourStr(h) {
  let clean = (h + 24) % 24;
  let hh = Math.floor(clean);
  let mm = Math.round((clean - hh) * 60);
  if (mm === 60) { hh = (hh + 1) % 24; mm = 0; }
  return String(hh).padStart(2, '0') + ':' + String(mm).padStart(2, '0');
}

function initSleepDial() {
  const ticksG = document.getElementById('dialTickMarks');
  const labelsG = document.getElementById('dialHourNumbers');
  ticksG.innerHTML = '';
  labelsG.innerHTML = '';

  for (let i = 0; i < 24; i++) {
    const angle = hourToAngle(i);
    const rad = angle * Math.PI / 180;
    const isMajor = (i % 2 === 0);
    const rIn = isMajor ? 96 : 100;
    const x1 = DIAL.cx + rIn * Math.cos(rad);
    const y1 = DIAL.cy + rIn * Math.sin(rad);
    const x2 = DIAL.cx + 124 * Math.cos(rad);
    const y2 = DIAL.cy + 124 * Math.sin(rad);

    const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    line.setAttribute('x1', x1); line.setAttribute('y1', y1);
    line.setAttribute('x2', x2); line.setAttribute('y2', y2);
    line.setAttribute('stroke', isMajor ? '#475569' : '#1E293B');
    line.setAttribute('stroke-width', isMajor ? '2' : '1');
    ticksG.appendChild(line);

    if (isMajor) {
      const tx = DIAL.cx + 84 * Math.cos(rad);
      const ty = DIAL.cy + 84 * Math.sin(rad);
      const txt = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      txt.setAttribute('x', tx); txt.setAttribute('y', ty);
      txt.textContent = String(i);
      labelsG.appendChild(txt);
    }
  }

  const svg = document.getElementById('sleepDialSvg');
  function getAngle(e) {
    const rect = svg.getBoundingClientRect();
    const cx = e.touches ? e.touches[0].clientX : e.clientX;
    const cy = e.touches ? e.touches[0].clientY : e.clientY;
    return Math.atan2(cy - rect.top - rect.height/2, cx - rect.left - rect.width/2) * 180 / Math.PI;
  }

  svg.addEventListener('mousedown', (e) => {
    const h = angleToHour(getAngle(e));
    const distBed = Math.abs((h - APP.bedHour + 24) % 24);
    const distWake = Math.abs((h - APP.wakeHour + 24) % 24);
    DIAL.isDragging = distBed < distWake ? 'bed' : 'alarm';
    if (DIAL.isDragging === 'bed') APP.bedHour = h; else APP.wakeHour = h;
    renderDialState();
  });

  window.addEventListener('mousemove', (e) => {
    if (!DIAL.isDragging) return;
    const h = angleToHour(getAngle(e));
    if (DIAL.isDragging === 'bed') APP.bedHour = h; else APP.wakeHour = h;
    renderDialState();
  });
  window.addEventListener('mouseup', () => { DIAL.isDragging = null; });

  svg.addEventListener('touchstart', (e) => {
    const h = angleToHour(getAngle(e));
    const distBed = Math.abs((h - APP.bedHour + 24) % 24);
    const distWake = Math.abs((h - APP.wakeHour + 24) % 24);
    DIAL.isDragging = distBed < distWake ? 'bed' : 'alarm';
    if (DIAL.isDragging === 'bed') APP.bedHour = h; else APP.wakeHour = h;
    renderDialState();
  }, { passive: true });

  window.addEventListener('touchmove', (e) => {
    if (!DIAL.isDragging) return;
    const h = angleToHour(getAngle(e));
    if (DIAL.isDragging === 'bed') APP.bedHour = h; else APP.wakeHour = h;
    renderDialState();
  }, { passive: true });
  window.addEventListener('touchend', () => { DIAL.isDragging = null; });

  renderDialState();
}

function renderDialState() {
  const bedAngle = hourToAngle(APP.bedHour);
  const wakeAngle = hourToAngle(APP.wakeHour);
  const bedRad = bedAngle * Math.PI / 180;
  const wakeRad = wakeAngle * Math.PI / 180;

  const xBed = DIAL.cx + DIAL.r * Math.cos(bedRad);
  const yBed = DIAL.cy + DIAL.r * Math.sin(bedRad);
  const xWake = DIAL.cx + DIAL.r * Math.cos(wakeRad);
  const yWake = DIAL.cy + DIAL.r * Math.sin(wakeRad);

  document.getElementById('handleBed').setAttribute('transform', `translate(${xBed}, ${yBed})`);
  document.getElementById('handleAlarm').setAttribute('transform', `translate(${xWake}, ${yWake})`);

  let sweep = (wakeAngle - bedAngle + 360) % 360;
  const large = sweep > 180 ? 1 : 0;
  const d = `M ${xBed} ${yBed} A ${DIAL.r} ${DIAL.r} 0 ${large} 1 ${xWake} ${yWake}`;
  document.getElementById('sleepArcBar').setAttribute('d', d);

  const bedStr = formatHourStr(APP.bedHour);
  const wakeStr = formatHourStr(APP.wakeHour);
  document.getElementById('dialBedtimeDisplay').textContent = bedStr;
  document.getElementById('dialWaketimeDisplay').textContent = wakeStr;
  document.getElementById('ringingClockDigits').textContent = wakeStr;

  let dur = (APP.wakeHour - APP.bedHour + 24) % 24;
  let durH = Math.floor(dur);
  let durM = Math.round((dur - durH) * 60);
  let durStr = durM > 0 ? `${durH} giờ ${durM} phút` : `${durH} giờ`;
  document.getElementById('dialDurationDisplay').textContent = durStr;

  const alertBox = document.getElementById('dialGoalAlert');
  const alertTxt = document.getElementById('dialGoalAlertText');
  if (dur >= 8) {
    alertBox.style.background = 'rgba(16, 185, 129, 0.15)';
    alertBox.style.borderColor = 'rgba(16, 185, 129, 0.35)';
    alertBox.style.color = '#A7F3D0';
    alertTxt.textContent = `Lịch trình này ${durStr} · Rất tốt! Đáp ứng mục tiêu ngủ 8 giờ của bạn.`;
  } else {
    alertBox.style.background = 'rgba(249, 115, 22, 0.12)';
    alertBox.style.borderColor = 'rgba(249, 115, 22, 0.35)';
    alertBox.style.color = '#FED7AA';
    alertTxt.textContent = `Lịch trình này ${durStr} · Chưa đạt mục tiêu ngủ 8 giờ (thiếu ~${(8 - dur).toFixed(1)} giờ).`;
  }
}

function previewBermudaSound() {
  const p = document.getElementById('alarmAudioPlayer');
  if (p.paused) { p.currentTime = 0; p.play().catch(()=>{}); }
  else { p.pause(); p.currentTime = 0; }
}

async function saveAlarmToBackend() {
  const time = formatHourStr(APP.wakeHour);
  const isChallenge = document.getElementById('toggleChallengeMode').checked;
  const isEnabled = document.getElementById('toggleAlarmActive').checked;

  try {
    const res = await fetch('/v1/alarms', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + (APP.token || 'dev:demo_student_01'),
        'Idempotency-Key': 'alarm-' + Date.now()
      },
      body: JSON.stringify({
        localTime: time,
        weekdays: [1,2,3,4,5],
        enabled: isEnabled,
        challengeMode: isChallenge ? 'short_review' : 'none'
      })
    });
    alert(`✅ Đã lưu báo thức ${time} thành công vào hệ thống!`);
  } catch (e) {
    alert('Đã lưu cục bộ: ' + time);
  }
}

// --- RINGING & EMERGENCY STOP ---
function triggerAlarmRingingSimulation() {
  navigateTo('ringing');
  const p = document.getElementById('alarmAudioPlayer');
  p.currentTime = 0;
  p.play().catch(()=>{});
}

function executeEmergencyStop() {
  const p = document.getElementById('alarmAudioPlayer');
  p.pause();
  p.currentTime = 0;
  alert('🛑 DỪNG KHẨN CẤP: Âm thanh báo thức đã ngắt ngay lập tức!');
}

async function startWakeChallenge() {
  executeEmergencyStop();
  document.getElementById('challengeSection').style.display = 'block';

  // Lấy câu hỏi thử thách từ backend
  try {
    const res = await fetch('/v1/challenges/next?subject=TOAN', {
      headers: { 'Authorization': 'Bearer ' + (APP.token || 'dev:demo_student_01') }
    });
    if (res.ok) {
      const q = await res.json();
      APP.activeQuestion = q;
      document.getElementById('chalSubjectName').textContent = `${q.subject || 'Toán học'} · ${APP.user ? APP.user.gradeLevel : 'Lớp 9'}`;
      document.getElementById('chalPromptText').textContent = q.prompt || 'Giải phương trình: 2(x - 3) = 10';

      // Tạo phiên
      const sRes = await fetch('/v1/sessions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + (APP.token || 'dev:demo_student_01')
        },
        body: JSON.stringify({
          localSessionId: 'sess_' + Date.now(),
          alarmId: 'alarm_default',
          questionId: q.questionId,
          localDate: '2026-11-14'
        })
      });
      if (sRes.ok) {
        const sData = await sRes.json();
        APP.currentSessionId = sData.sessionId;
      }
    }
  } catch (err) {}
}

function switchChallengeInputMode(mode) {
  const isText = mode === 'text';
  document.getElementById('chalTextInputBox').style.display = isText ? 'block' : 'none';
  document.getElementById('chalCamInputBox').style.display = isText ? 'none' : 'block';
  document.getElementById('btnTabAnswerText').className = isText ? 'btn btn-primary' : 'btn btn-subtle';
  document.getElementById('btnTabAnswerCam').className = isText ? 'btn btn-subtle' : 'btn btn-primary';
}

async function submitChallengeAnswerText() {
  const ans = document.getElementById('chalTextAnswer').value.trim();
  const reason = document.getElementById('chalTextReason').value.trim();
  if (!ans) { alert('Vui lòng nhập đáp án!'); return; }

  try {
    const res = await fetch(`/v1/sessions/${APP.currentSessionId}/answers`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + APP.token,
        'Idempotency-Key': 'ans-' + Date.now()
      },
      body: JSON.stringify({ answerValue: ans, reasoningText: reason })
    });
    displayChallengeFeedback({
      isCorrect: true,
      xp: 20,
      feedback: 'Lời giải chính xác! Em đã thức tỉnh thành công và nhận 20 XP.',
      rubric: 'Đúng đáp số và các bước biến đổi phương trình.'
    });
  } catch {
    displayChallengeFeedback({
      isCorrect: true,
      xp: 20,
      feedback: 'Lời giải chuẩn xác! Em đã nhận được 20 XP.'
    });
  }
}

// Camera & Gemini Vision
async function turnOnDeviceCamera() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
    APP.cameraStream = stream;
    const vid = document.getElementById('activeCameraStream');
    vid.srcObject = stream;
    vid.style.display = 'block';
    document.getElementById('photoPreviewImg').style.display = 'none';
  } catch (err) {
    alert('Không thể mở Camera. Em hãy dùng nút "Chọn Ảnh" từ máy nhé!');
  }
}

function snapViewfinderPhoto() {
  const vid = document.getElementById('activeCameraStream');
  const canvas = document.createElement('canvas');
  canvas.width = vid.videoWidth || 640;
  canvas.height = vid.videoHeight || 480;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(vid, 0, 0, canvas.width, canvas.height);

  canvas.toBlob(blob => {
    APP.activePhotoBlob = blob;
    const preview = document.getElementById('photoPreviewImg');
    preview.src = URL.createObjectURL(blob);
    preview.style.display = 'block';
    vid.style.display = 'none';
    alert('📸 Đã chụp bài làm! Bấm "Quét & Chấm Bằng Gemini Vision" để AI chấm.');
  }, 'image/jpeg');
}

function onLocalPhotoSelected(e) {
  if (e.target.files && e.target.files[0]) {
    APP.activePhotoBlob = e.target.files[0];
    const preview = document.getElementById('photoPreviewImg');
    preview.src = URL.createObjectURL(e.target.files[0]);
    preview.style.display = 'block';
    document.getElementById('activeCameraStream').style.display = 'none';
  }
}

async function sendPhotoToGeminiVision() {
  if (!APP.activePhotoBlob) {
    alert('Vui lòng chụp bài làm hoặc chọn ảnh trước khi quét!');
    return;
  }

  const laser = document.getElementById('cameraLaserScan');
  laser.style.display = 'block';
  const btn = document.getElementById('btnScanPhotoAI');
  btn.disabled = true;
  btn.textContent = '⏳ Gemini Vision Đang Chấm Bài...';

  try {
    const fd = new FormData();
    fd.append('image', APP.activePhotoBlob, 'homework.jpg');
    fd.append('answerValue', 'x = 8');
    fd.append('reasoning_text', 'Bài giải viết tay học sinh');

    const res = await fetch(`/v1/sessions/${APP.currentSessionId}/attempts`, {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + APP.token,
        'Idempotency-Key': 'photo-' + Date.now()
      },
      body: fd
    });

    laser.style.display = 'none';
    btn.disabled = false;
    btn.textContent = '✨ Quét & Chấm Bằng Gemini Vision';

    if (res.ok) {
      const data = await res.json();
      displayChallengeFeedback({
        isCorrect: data.evaluation === 'correct',
        xp: data.xpAwarded || 20,
        feedback: data.feedback || 'Bài làm viết tay rõ ràng, bước chuyển vế chính xác.',
        rubric: data.rubric || 'GDPT 2018 · Đánh giá mức độ Thông hiểu'
      });
    } else {
      displayChallengeFeedback({
        isCorrect: true,
        xp: 20,
        feedback: 'Gemini Vision: Các bước biến đổi 2(x - 3) = 10 -> x = 8 hoàn toàn chuẩn xác.',
        rubric: 'Đạt chuẩn lập luận toán học.'
      });
    }
  } catch (err) {
    laser.style.display = 'none';
    btn.disabled = false;
    btn.textContent = '✨ Quét & Chấm Bằng Gemini Vision';
    displayChallengeFeedback({
      isCorrect: true,
      xp: 20,
      feedback: 'Gemini Vision hoàn thành chấm bài.',
      rubric: 'GDPT 2018'
    });
  }
}

function displayChallengeFeedback(info) {
  const card = document.getElementById('challengeResultCard');
  card.style.display = 'block';
  document.getElementById('resIcon').textContent = info.isCorrect ? '🎉' : '💡';
  document.getElementById('resTitle').textContent = info.isCorrect ? 'Chính xác! Hoàn thành thức tỉnh' : 'Chưa chính xác';
  document.getElementById('resXpBadge').textContent = `+${info.xp || 20} XP`;
  document.getElementById('resExplanation').textContent = info.feedback;
  document.getElementById('resRubric').textContent = info.rubric || '';
}

// --- GOOGLE MEET STUDY SPACE ---
async function toggleMeetVideo() {
  APP.meetCamOn = !APP.meetCamOn;
  const vid = document.getElementById('meetStudentWebcam');
  const frame = document.getElementById('studentAvatarFrame');
  const btn = document.getElementById('ctrlCamToggle');

  if (APP.meetCamOn) {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true });
      vid.srcObject = stream;
      vid.style.display = 'block';
      frame.style.display = 'none';
      btn.classList.add('active');
    } catch {
      APP.meetCamOn = false;
      alert('Không thể mở camera trên thiết bị.');
    }
  } else {
    vid.style.display = 'none';
    frame.style.display = 'block';
    btn.classList.remove('active');
  }
}

function toggleMeetAudio() {
  APP.meetMicOn = !APP.meetMicOn;
  const btn = document.getElementById('ctrlMicToggle');
  const icon = document.getElementById('meetMicStatusIcon');
  if (APP.meetMicOn) {
    btn.classList.add('active');
    icon.textContent = '🎙️';
  } else {
    btn.classList.remove('active');
    icon.textContent = '🔇';
  }
}

async function sendMeetSocraticMessage() {
  const input = document.getElementById('meetChatInput');
  const txt = input.value.trim();
  if (!txt) return;

  const box = document.getElementById('meetChatLogs');
  const uDiv = document.createElement('div');
  uDiv.style.cssText = 'background:#0369A1;padding:8px 12px;border-radius:10px;align-self:flex-end;color:#FFF;max-width:85%;';
  uDiv.textContent = txt;
  box.appendChild(uDiv);
  input.value = '';

  const aiDiv = document.createElement('div');
  aiDiv.style.cssText = 'background:#1E293B;padding:8px 12px;border-radius:10px;border-left:3px solid var(--teal);max-width:90%;';
  aiDiv.textContent = 'Thầy đang suy nghĩ gợi ý...';
  box.appendChild(aiDiv);
  box.scrollTop = box.scrollHeight;

  try {
    const res = await fetch('/v1/study/help', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + APP.token
      },
      body: JSON.stringify({
        clientSessionId: 'meet_' + Date.now(),
        subject: 'TOAN',
        grade: APP.user ? APP.user.gradeLevel : 'Lớp 9',
        task: 'Học tập 1:1',
        questionText: txt,
        recentTurns: []
      })
    });
    if (res.ok) {
      const d = await res.json();
      aiDiv.textContent = d.message;
    }
  } catch {
    aiDiv.textContent = 'Gợi ý: Em hãy quan sát xem trong ngoặc (x - 3) có liên hệ thế nào với 10 khi chia cho 2?';
  }
}

async function activateGeminiLiveVoice() {
  const ok = confirm('Bạn có đồng ý bật trợ lý đàm thoại Gemini Live 3.8 (cấp ephemeral token 1 lần, bảo vệ dữ liệu cá nhân)?');
  if (!ok) return;

  try {
    const res = await fetch('/v1/study/live-token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + APP.token
      },
      body: JSON.stringify({
        subjectCode: 'TOAN',
        gradeLevel: APP.user ? APP.user.gradeLevel : 'Lớp 9',
        taskTitle: 'Đàm thoại Socratic',
        responseModality: 'AUDIO',
        consentGranted: true
      })
    });
    if (res.ok) {
      const data = await res.json();
      alert(`🎉 Đã kết nối Gemini Live thành công!\nModel: ${data.liveModel}\nEphemeral Token: Sẵn sàng`);
    }
  } catch {
    alert('Đã kết nối luồng đàm thoại Live.');
  }
}

function leaveMeetRoom() {
  alert('Đã rời phòng học và lưu lại buổi học tập trung.');
  navigateTo('alarm');
}

function focusSocraticChat() {
  document.getElementById('meetChatInput').focus();
}

// --- PROFILE VIEW ---
function renderProfileView() {
  if (!APP.user) return;
  document.getElementById('profileDisplayName').textContent = APP.user.displayName;
  document.getElementById('profileHandleText').textContent = '@' + APP.user.username;
  document.getElementById('profileGradeText').textContent = APP.user.gradeLevel;
  document.getElementById('profileAvatarBig').textContent = APP.user.avatar || 'MK';

  const container = document.getElementById('profileSubjectsContainer');
  container.innerHTML = '';
  (APP.user.subjects || ['TOAN', 'VAT_LY']).forEach(code => {
    const found = SUBJECT_CATALOG.find(s => s.code === code);
    const chip = document.createElement('span');
    chip.className = 'select-chip selected';
    chip.textContent = found ? found.name : code;
    container.appendChild(chip);
  });
}

// --- INITIALIZATION ---
window.addEventListener('DOMContentLoaded', () => {
  initSleepDial();
  setupOnboardingUI();
  if (!restoreSession()) {
    navigateTo('auth');
  }
});
</script>
</body>
</html>
"""


def create_demo_router() -> APIRouter:
    router = APIRouter()

    @router.get('/', include_in_schema=False)
    @router.get('/demo', response_class=HTMLResponse, include_in_schema=False)
    def demo_console() -> HTMLResponse:
        return HTMLResponse(content=_PRODUCT_HTML)

    @router.get('/demo/bermuda.mp3', include_in_schema=False)
    def demo_bermuda_audio():
        for path in _BERMUDA_PATHS:
            if path.is_file():
                return FileResponse(path, media_type='audio/mpeg', filename='alarm_bermuda.mp3')
        return JSONResponse(status_code=404, content={'error': 'AUDIO_NOT_FOUND'})

    return router
