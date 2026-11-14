from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse

_REPO_ROOT = Path(__file__).resolve().parents[3]
_BERMUDA_PATHS = [
    _REPO_ROOT / 'mp3' / 'jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3',
    _REPO_ROOT / 'app' / 'android' / 'app' / 'src' / 'main' / 'res' / 'raw' / 'alarm_bermuda.mp3',
]

_DEMO_HTML = """<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>MindClock — Môi trường Demo Live (PC &amp; Android)</title>
  <style>
    :root {
      --paper: #FAF6EE;
      --card: #FFFFFF;
      --ink: #1C2526;
      --muted: #5A6568;
      --outline: #E2DACB;
      --sunrise: #E86A2B;
      --teal: #0D6E6E;
      --teal-soft: #E6F2F1;
      --warm-soft: #FDF0E7;
      --night: #121A24;
      --night-text: #E9EEF4;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
      background: var(--paper);
      color: var(--ink);
      line-height: 1.45;
    }
    .wrap {
      max-width: 820px;
      margin: 0 auto;
      padding: 16px;
    }
    header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 10px;
      margin-bottom: 16px;
    }
    h1 { font-size: 22px; margin: 0; }
    .pill {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 600;
      background: var(--teal-soft);
      color: var(--teal);
      border: 1px solid var(--teal);
    }
    .card {
      background: var(--card);
      border: 1px solid var(--outline);
      border-radius: 14px;
      padding: 16px;
      margin-bottom: 14px;
    }
    .card.night {
      background: var(--night);
      color: var(--night-text);
      border-color: #253445;
    }
    h2 { font-size: 16px; margin: 0 0 10px; }
    label { display: block; font-size: 13px; font-weight: 600; margin: 8px 0 4px; }
    input, select, textarea {
      width: 100%;
      padding: 9px 11px;
      border-radius: 8px;
      border: 1px solid var(--outline);
      font-size: 14px;
      background: #fff;
      color: var(--ink);
    }
    .row { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 10px; }
    .chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 6px; }
    .chip {
      padding: 6px 10px;
      border-radius: 999px;
      border: 1px solid var(--outline);
      background: var(--paper);
      font-size: 13px;
      cursor: pointer;
    }
    .chip.on {
      background: var(--teal);
      color: #fff;
      border-color: var(--teal);
    }
    button {
      border: 0;
      border-radius: 10px;
      padding: 10px 14px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      background: var(--teal);
      color: #fff;
      margin-top: 8px;
    }
    button.warm { background: var(--sunrise); }
    button.danger { background: #B83227; }
    button.subtle { background: var(--paper); color: var(--ink); border: 1px solid var(--outline); }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .btn-row { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 6px; }
    pre {
      background: #172026;
      color: #E2ECE9;
      padding: 10px;
      border-radius: 8px;
      font-size: 12px;
      overflow-x: auto;
      margin: 8px 0 0;
      white-space: pre-wrap;
    }
    .caption { font-size: 12px; color: var(--muted); }
    .night .caption { color: #B5C2CF; }
  </style>
</head>
<body>
<div class="wrap">
  <header>
    <div>
      <h1>MindClock — Demo Sandbox Live</h1>
      <div class="caption">Chạy thật trên FastAPI + SQLite/PostgreSQL + Gemini 3.8/3.5/Live (key chỉ ở server)</div>
    </div>
    <span class="pill" id="healthPill">Đang kiểm tra /v1/health...</span>
  </header>

  <div class="card">
    <h2>1. Hồ sơ &amp; Trình độ học sinh (/v1/me &amp; /v1/timetable)</h2>
    <div class="row">
      <div>
        <label for="uid">Tài khoản thử (dev Bearer)</label>
        <input id="uid" value="demo_student_01" />
      </div>
      <div>
        <label for="alias">Tên hiển thị</label>
        <input id="alias" value="Minh Khoa" />
      </div>
      <div>
        <label for="grade">Trình độ hiện tại</label>
        <select id="grade">
          <option>Lớp 6</option>
          <option>Lớp 7</option>
          <option>Lớp 8</option>
          <option selected>Lớp 9</option>
          <option>Lớp 10</option>
          <option>Lớp 11</option>
          <option>Lớp 12</option>
        </select>
      </div>
    </div>
    <label>Môn học tích hợp</label>
    <div class="chips" id="subjectChips"></div>
    <div class="btn-row">
      <button onclick="saveProfile()">Lưu hồ sơ &amp; TKB mẫu</button>
      <button class="subtle" onclick="loadProgress()">Xem XP / Tiến độ</button>
      <button class="danger" onclick="deleteAccount()">Xóa dữ liệu tài khoản</button>
    </div>
    <pre id="profileOut">Chưa thao tác.</pre>
  </div>

  <div class="card night">
    <h2>2. Mô phỏng Chuông báo thức + Dừng khẩn cấp + Chấm thử thách (/v1/alarms, /v1/sessions)</h2>
    <div class="caption">Nhạc chuông Bermuda phát từ backend; Dừng khẩn cấp tắt âm ngay lập tức và đồng bộ sự kiện sau.</div>
    <audio id="alarmAudio" loop src="/demo/bermuda.mp3"></audio>
    <div class="btn-row">
      <button class="warm" onclick="startAlarmDemo()">1) Đặt &amp; Reo chuông Bermuda</button>
      <button class="danger" onclick="emergencyStop()">Dừng khẩn cấp ngay</button>
      <button onclick="loadNextChallenge()">2) Mở câu hỏi thử thách</button>
    </div>
    <pre id="challengeBox">Bấm "Mở câu hỏi thử thách" để lấy câu từ ngân hàng đã duyệt.</pre>
    <div class="row">
      <div>
        <label for="ansText">Đáp án chữ</label>
        <input id="ansText" placeholder="Ví dụ: x = 8" />
      </div>
      <div>
        <label for="reasonText">Bước giải ngắn</label>
        <input id="reasonText" placeholder="Chia hai vế cho 2 -> x - 3 = 5" />
      </div>
    </div>
    <div class="btn-row">
      <button onclick="submitAnswer()">3) Nộp bài chữ (chấm + XP server)</button>
    </div>
    <label for="photoFile">Hoặc thử chấm ảnh bài viết tay bằng Gemini Vision (/v1/sessions/{id}/attempts)</label>
    <input id="photoFile" type="file" accept="image/jpeg,image/png,image/webp" />
    <div class="btn-row">
      <button class="subtle" onclick="submitPhoto()">Nộp ảnh bài làm</button>
    </div>
    <pre id="gradeOut">Chưa nộp bài.</pre>
  </div>

  <div class="card">
    <h2>3. Câu hỏi cá nhân hóa + Trợ lý Socratic + Gemini Live (/v1/questions/personalized, /v1/study/*)</h2>
    <div class="row">
      <div>
        <label for="aiSubject">Môn tạo câu hỏi</label>
        <select id="aiSubject">
          <option value="TOAN">Toán (TOAN)</option>
          <option value="VAT_LY">Vật lí (VAT_LY)</option>
          <option value="TIENG_ANH">Tiếng Anh (TIENG_ANH)</option>
          <option value="NGU_VAN">Ngữ văn (NGU_VAN)</option>
          <option value="SINH_HOC">Sinh học (SINH_HOC)</option>
          <option value="TIN_HOC">Tin học (TIN_HOC)</option>
        </select>
      </div>
      <div>
        <label for="topicHint">Chủ đề gợi ý</label>
        <input id="topicHint" value="Phương trình bậc nhất" />
      </div>
      <div>
        <label for="difficulty">Độ khó (1-3)</label>
        <select id="difficulty">
          <option value="1" selected>1 - Cơ bản</option>
          <option value="2">2 - Thông hiểu</option>
          <option value="3">3 - Vận dụng</option>
        </select>
      </div>
    </div>
    <div class="btn-row">
      <button onclick="generatePersonalized()">Tạo câu hỏi cá nhân hóa (AI)</button>
    </div>
    <pre id="personalOut">Chưa tạo câu hỏi cá nhân hóa.</pre>

    <label for="helpInput">Hỏi trợ lý Socratic trong Không gian học (/v1/study/help)</label>
    <input id="helpInput" placeholder="Mình đang vướng bước chuyển vế bài 2(x - 3) = 10" />
    <div class="btn-row">
      <button onclick="askStudyHelp()">Hỏi AI Socratic</button>
    </div>
    <pre id="helpOut">Chưa gửi câu hỏi Socratic.</pre>

    <label>
      <input type="checkbox" id="liveConsent" style="width:auto;margin-right:6px" />
      Tôi đồng ý rõ ràng bật trợ lý thoại Gemini Live (gemini-3.8-live, cấp token 1 lần, không bật mic nền)
    </label>
    <div class="btn-row">
      <button class="warm" onclick="mintLiveToken()">Xin ephemeral token Gemini Live</button>
    </div>
    <pre id="liveOut">Chưa xin token Live.</pre>
  </div>
</div>

<script>
const ALL_SUBJECTS = [
  ['TOAN', 'Toán'], ['VAT_LY', 'Vật lí'], ['TIENG_ANH', 'Tiếng Anh'],
  ['NGU_VAN', 'Ngữ văn'], ['SINH_HOC', 'Sinh học'], ['TIN_HOC', 'Tin học']
];
let selectedSubjects = new Set(['TOAN', 'VAT_LY', 'TIENG_ANH']);
let currentSessionId = null;

function renderSubjectChips() {
  const host = document.getElementById('subjectChips');
  host.innerHTML = '';
  for (const [code, label] of ALL_SUBJECTS) {
    const btn = document.createElement('span');
    btn.className = 'chip' + (selectedSubjects.has(code) ? ' on' : '');
    btn.textContent = label;
    btn.onclick = () => {
      if (selectedSubjects.has(code) && selectedSubjects.size > 1) selectedSubjects.delete(code);
      else selectedSubjects.add(code);
      renderSubjectChips();
    };
    host.appendChild(btn);
  }
}

function authHeaders(extra = {}) {
  const uid = document.getElementById('uid').value.trim() || 'demo_student_01';
  return { 'Authorization': 'Bearer dev:' + uid, ...extra };
}

async function api(method, path, body = null, idem = null) {
  const headers = authHeaders(body ? { 'Content-Type': 'application/json' } : {});
  if (idem) headers['Idempotency-Key'] = idem;
  const res = await fetch(path, { method, headers, body: body ? JSON.stringify(body) : null });
  const text = await res.text();
  let json = text;
  try { json = JSON.parse(text); } catch {}
  return { status: res.status, data: json };
}

async function checkHealth() {
  const r = await fetch('/v1/health');
  const d = await r.json();
  document.getElementById('healthPill').textContent =
    `API OK · ${d.dbDialect} · ${d.geminiPrimaryModel} / ${d.geminiLiveModel}`;
}

async function saveProfile() {
  const me = await api('PATCH', '/v1/me', {
    alias: document.getElementById('alias').value,
    gradeLevel: document.getElementById('grade').value,
    selectedSubjects: Array.from(selectedSubjects)
  });
  const tt = await api('PUT', '/v1/timetable', {
    slots: Array.from(selectedSubjects).map((s, idx) => ({ weekday: (idx % 5) + 1, subjectCode: s }))
  });
  document.getElementById('profileOut').textContent = JSON.stringify({ me, timetable: tt }, null, 2);
}

async function loadProgress() {
  const r = await api('GET', '/v1/progress/summary');
  document.getElementById('profileOut').textContent = JSON.stringify(r, null, 2);
}

async function deleteAccount() {
  const r = await api('DELETE', '/v1/me');
  document.getElementById('profileOut').textContent = JSON.stringify(r, null, 2);
}

async function startAlarmDemo() {
  await api('POST', '/v1/alarms', {
    localTime: '06:00', weekdays: [1,2,3,4,5], enabled: true, challengeMode: 'short_review'
  }, 'demo-alarm-' + Date.now());
  const audio = document.getElementById('alarmAudio');
  audio.currentTime = 0;
  audio.play().catch(() => {});
  document.getElementById('gradeOut').textContent = 'Đang phát chuông Bermuda (bấm Dừng khẩn cấp ngay nếu cần tắt âm).';
}

async function emergencyStop() {
  const audio = document.getElementById('alarmAudio');
  audio.pause();
  audio.currentTime = 0;
  let ev = null;
  if (currentSessionId) {
    ev = await api('POST', `/v1/sessions/${currentSessionId}/events`, { eventType: 'dismiss' }, 'stop-' + Date.now());
  }
  document.getElementById('gradeOut').textContent = JSON.stringify({ stoppedLocalAudio: true, serverEvent: ev }, null, 2);
}

async function loadNextChallenge() {
  const subj = document.getElementById('aiSubject').value;
  const ch = await api('GET', `/v1/challenges/next?subject=${encodeURIComponent(subj)}&date=2026-11-14`);
  if (ch.status === 200) {
    const sess = await api('POST', '/v1/sessions', {
      localSessionId: 'demo_sess_' + Date.now(),
      alarmId: 'demo_alarm',
      questionId: ch.data.questionId,
      localDate: '2026-11-14'
    });
    currentSessionId = sess.data.sessionId;
  }
  document.getElementById('challengeBox').textContent = JSON.stringify({ sessionId: currentSessionId, challenge: ch }, null, 2);
}

async function submitAnswer() {
  if (!currentSessionId) {
    await loadNextChallenge();
  }
  const r = await api('POST', `/v1/sessions/${currentSessionId}/answers`, {
    answerValue: document.getElementById('ansText').value,
    reasoningText: document.getElementById('reasonText').value
  }, 'ans-' + Date.now());
  document.getElementById('gradeOut').textContent = JSON.stringify(r, null, 2);
}

async function submitPhoto() {
  if (!currentSessionId) {
    await loadNextChallenge();
  }
  const fileEl = document.getElementById('photoFile');
  if (!fileEl.files || !fileEl.files[0]) {
    document.getElementById('gradeOut').textContent = 'Chọn ảnh JPEG/PNG/WebP trước khi gửi.';
    return;
  }
  const fd = new FormData();
  fd.append('image', fileEl.files[0]);
  fd.append('answerValue', document.getElementById('ansText').value);
  fd.append('reasoning_text', document.getElementById('reasonText').value);
  const res = await fetch(`/v1/sessions/${currentSessionId}/attempts`, {
    method: 'POST',
    headers: authHeaders({ 'Idempotency-Key': 'photo-' + Date.now() }),
    body: fd
  });
  document.getElementById('gradeOut').textContent = JSON.stringify({ status: res.status, data: await res.json() }, null, 2);
}

async function generatePersonalized() {
  document.getElementById('personalOut').textContent = 'Đang gọi Gemini...';
  const r = await api('POST', '/v1/questions/personalized', {
    subjectCode: document.getElementById('aiSubject').value,
    gradeLevel: document.getElementById('grade').value,
    topicHint: document.getElementById('topicHint').value,
    difficulty: Number(document.getElementById('difficulty').value),
    saveToBank: true
  });
  document.getElementById('personalOut').textContent = JSON.stringify(r, null, 2);
}

async function askStudyHelp() {
  document.getElementById('helpOut').textContent = 'Đang hỏi trợ lý Socratic...';
  const r = await api('POST', '/v1/study/help', {
    clientSessionId: 'demo_study_01',
    subject: document.getElementById('aiSubject').value,
    grade: document.getElementById('grade').value,
    task: document.getElementById('topicHint').value || 'Ôn tập chủ đề',
    questionText: document.getElementById('helpInput').value || 'Mình nên bắt đầu từ bước nào?',
    recentTurns: []
  });
  document.getElementById('helpOut').textContent = JSON.stringify(r, null, 2);
}

async function mintLiveToken() {
  const consent = document.getElementById('liveConsent').checked;
  const r = await api('POST', '/v1/study/live-token', {
    subjectCode: document.getElementById('aiSubject').value,
    gradeLevel: document.getElementById('grade').value,
    taskTitle: document.getElementById('topicHint').value || 'Ôn tập cá nhân',
    responseModality: 'AUDIO',
    consentGranted: consent
  });
  document.getElementById('liveOut').textContent = JSON.stringify(r, null, 2);
}

renderSubjectChips();
checkHealth();
</script>
</body>
</html>
"""


def create_demo_router() -> APIRouter:
    router = APIRouter()

    @router.get('/', include_in_schema=False)
    @router.get('/demo', response_class=HTMLResponse, include_in_schema=False)
    def demo_console() -> HTMLResponse:
        return HTMLResponse(content=_DEMO_HTML)

    @router.get('/demo/bermuda.mp3', include_in_schema=False)
    def demo_bermuda_audio():
        for path in _BERMUDA_PATHS:
            if path.is_file():
                return FileResponse(path, media_type='audio/mpeg', filename='alarm_bermuda.mp3')
        return JSONResponse(status_code=404, content={'error': 'AUDIO_NOT_FOUND'})

    return router
