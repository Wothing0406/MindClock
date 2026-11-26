
'use strict';
function newId(){
  if(globalThis.crypto.randomUUID)return globalThis.crypto.randomUUID();
  const bytes=new Uint8Array(16);globalThis.crypto.getRandomValues(bytes);
  return Array.from(bytes,b=>b.toString(16).padStart(2,'0')).join('');
}
const $=id=>document.getElementById(id);const STORAGE='mindclock.product.v1';const uid='product_demo_'+location.port;const auth={'Authorization':'Bearer dev:'+uid};
const state={alarm:{time:'06:30',days:[1,2,3,4,5],enabled:false,challenge:true,sound:'gentle'},timer:{minutes:25,remaining:1500000,deadline:null,started:null,id:null,serverId:null},question:null,session:null,history:[],ringing:false,lastRing:'',busy:false,pending:[]};
let alarmDraftDays=[...state.alarm.days];
let toastHandle=null,audioContext=null,oscillators=[],beepInterval=null,lastChat='',restored=false;
function toast(t){$('toast').textContent=t;$('toast').hidden=false;clearTimeout(toastHandle);toastHandle=setTimeout(()=>$('toast').hidden=true,4500)}
function persist(){try{localStorage.setItem(STORAGE,JSON.stringify({alarm:state.alarm,timer:state.timer,pending:state.pending,lastRing:state.lastRing,study:{task:$('studyTask').value,subject:$('studySubject').value,grade:$('grade').value}}))}catch{toast('Trình duyệt chưa cho lưu local. Giữ tab mở để tiếp tục.')}}
function restore(){try{const s=JSON.parse(localStorage.getItem(STORAGE)||'null');if(s){state.pending=Array.isArray(s.pending)?s.pending.filter(x=>x&&typeof x.id==='string'):[];state.lastRing=s.lastRing||'';if(s.study){$('studyTask').value=s.study.task||'';$('studySubject').value=s.study.subject||'TOAN';$('grade').value=s.study.grade||'Lớp 12'}if(s.alarm&&/^\d{2}:\d{2}$/.test(s.alarm.time))Object.assign(state.alarm,s.alarm);if(s.timer&&Number.isFinite(s.timer.remaining)&&[10,25,45].includes(s.timer.minutes)){Object.assign(state.timer,s.timer);restored=!!s.timer.started}}}catch{}}
async function api(path,body,method,key){const control=new AbortController();const t=setTimeout(()=>control.abort(),22000);try{const res=await fetch('/v1'+path,{method:method||(body?'POST':'GET'),headers:{...auth,...(body?{'Content-Type':'application/json'}:{}),...(key?{'Idempotency-Key':key}:{})},body:body?JSON.stringify(body):undefined,signal:control.signal});const d=await res.json().catch(()=>({}));if(!res.ok)throw Error(d.error?.messageVi||d.error?.message_vi||d.error?.message||(res.status===401?'Phiên dùng thử chưa được backend cho phép.':'Chưa thực hiện được yêu cầu ('+res.status+').'));return d}catch(e){if(e.name==='AbortError')throw Error('Trợ lý phản hồi quá lâu. Bạn có thể thử lại.');throw e}finally{clearTimeout(t)}}
function navigate(page){
  const pages=['home','alarm','study','profile'];if(!pages.includes(page))page='home';
  pages.forEach(name=>{$('page-'+name).hidden=name!==page;$('nav-'+name).classList.toggle('active',name===page);$('nav-'+name).setAttribute('aria-current',name===page?'page':'false')});
  document.title='MindClock — '+({home:'Hôm nay',alarm:'Báo thức',study:'Không gian học',profile:'Của bạn'}[page]);
  if(typeof history!=='undefined'&&history.replaceState)history.replaceState(null,'','#'+page);
  window.scrollTo({top:0,behavior:'instant'});updatePending();
}
function renderDays(){const names=['CN','T2','T3','T4','T5','T6','T7'];$('weekdays').replaceChildren();[1,2,3,4,5,6,0].forEach(day=>{const b=document.createElement('button');b.type='button';b.className='day'+(alarmDraftDays.includes(day)?' on':'');b.textContent=names[day];b.setAttribute('aria-pressed',alarmDraftDays.includes(day));b.onclick=()=>{alarmDraftDays=alarmDraftDays.includes(day)?alarmDraftDays.filter(x=>x!==day):[...alarmDraftDays,day];renderDays()};$('weekdays').append(b)})}
function renderAlarm(){const a=state.alarm;alarmDraftDays=[...a.days];$('alarmTime').value=a.time;$('alarmEnabled').checked=a.enabled;$('challengeMode').checked=a.challenge;$('alarmSound').value=a.sound;$('clockDisplay').textContent=a.time;$('alarmBadge').textContent=a.enabled?'Đã bật trong tab':'Chưa bật';$('nextAlarmText').textContent=a.enabled?(a.days.length?'Theo ngày đã chọn':'Lần tiếp theo'):'Bạn có thể thử chuông bất cứ lúc nào';renderDays();updateNextAlarm()}
function unlockAudio(){try{audioContext??=new(window.AudioContext||window.webkitAudioContext)();audioContext.resume().catch(()=>{})}catch{}}
function beep(){if(!audioContext||!state.ringing)return;[0,.32].forEach(offset=>{const o=audioContext.createOscillator(),g=audioContext.createGain();o.type='sine';o.frequency.value=offset?784:659;o.connect(g);g.connect(audioContext.destination);const n=audioContext.currentTime+offset;g.gain.setValueAtTime(0,n);g.gain.linearRampToValueAtTime(.08,n+.02);g.gain.exponentialRampToValueAtTime(.001,n+.23);o.start(n);o.stop(n+.25);oscillators.push(o);o.onended=()=>{oscillators=oscillators.filter(x=>x!==o)}})}
function gentle(){beep();clearInterval(beepInterval);beepInterval=setInterval(beep,1400)}
function ringAlarm(){if(state.ringing)return;unlockAudio();state.ringing=true;$('ringTime').textContent=state.alarm.time;$('ringing').hidden=false;$('floatingStop').hidden=false;$('openAlarmQuestion').hidden=!state.alarm.challenge;document.querySelector('#ringing .stop').focus();if(state.alarm.sound==='bermuda')$('audio').play().catch(()=>{if(state.ringing){gentle();toast('Âm MP3 chưa mở được; đang dùng chuông nhẹ.')}});else gentle()}
function stopAlarm(){state.ringing=false;clearInterval(beepInterval);oscillators.forEach(o=>{try{o.stop()}catch{}});oscillators=[];$('audio').pause();$('audio').currentTime=0;$('ringing').hidden=true;$('floatingStop').hidden=true;toast('Đã dừng chuông.');if(state.session)api('/sessions/'+state.session+'/events',{eventType:'dismiss'},'POST','dismiss-'+state.session).catch(()=>{})}
function openChallenge(){$('ringing').hidden=true;openPractice();if(!state.question)loadQuestion()}
$('alarmForm').addEventListener('submit',async e=>{
  e.preventDefault();const button=$('alarmSave');button.disabled=true;unlockAudio();
  Object.assign(state.alarm,{time:$('alarmTime').value,enabled:$('alarmEnabled').checked,challenge:$('challengeMode').checked,sound:$('alarmSound').value,days:[...alarmDraftDays]});
  const body={localTime:state.alarm.time,timeZone:Intl.DateTimeFormat().resolvedOptions().timeZone,weekdays:state.alarm.days.map(d=>d===0?7:d),enabled:state.alarm.enabled,challengeMode:state.alarm.challenge?'short_review':'none'};
  const serialized=JSON.stringify(body);if(state.alarm.pendingBody!==serialized){state.alarm.pendingBody=serialized;state.alarm.pendingKey='alarm-'+newId()}
  persist();renderAlarm();$('alarmStatus').textContent='Đã lưu trên máy. Giữ tab mở để phát chuông.';
  try{const id=state.alarm.serverId;const data=await api('/alarms'+(id?'/'+encodeURIComponent(id):''),body,id?'PATCH':'POST',id?null:state.alarm.pendingKey);state.alarm.serverId=data.id||id;persist();$('alarmStatus').textContent='Đã lưu local và đồng bộ cấu hình.'}
  catch{$('alarmStatus').textContent='Đã lưu local. Chưa đồng bộ; nhấn Lưu để gửi lại khi có mạng.'}
  finally{button.disabled=false}
});
async function loadQuestion(){const b=$('loadQuestion');b.disabled=true;state.question=null;state.session=null;state.attempt=null;$('submitAnswer').disabled=true;$('answerResult').hidden=true;$('questionText').textContent='Đang lấy câu hỏi…';try{const q=await api('/challenges/next?subject='+encodeURIComponent($('subject').value)+'&date='+new Date().toLocaleDateString('en-CA'));state.question=q;$('questionText').textContent=q.prompt;$('submitAnswer').disabled=false}catch(e){$('questionText').textContent='Chưa lấy được câu đã duyệt cho môn này. Hãy thử môn khác hoặc kết thúc không chấm.';toast(e.message)}finally{b.disabled=false}}
$('answerForm').addEventListener('submit',async e=>{e.preventDefault();if(!state.question)return;const b=$('submitAnswer');b.disabled=true;$('loadQuestion').disabled=true;const attemptBody=JSON.stringify({answerValue:$('answer').value.trim(),reasoningText:$('reasoning').value.trim()});if(!state.attempt||state.attempt.body!==attemptBody)state.attempt={body:attemptBody,key:'answer-'+newId()};const attemptKey=state.attempt.key;try{if(!state.session){const s=await api('/sessions',{localSessionId:'web-'+newId(),questionId:state.question.questionId,localDate:new Date().toLocaleDateString('en-CA')});state.session=s.sessionId}const d=await api('/sessions/'+state.session+'/answers',{answerValue:$('answer').value.trim(),reasoningText:$('reasoning').value.trim()},'POST',attemptKey);state.attempt=null;const result=d.result||'uncertain';$('answerResult').hidden=false;$('answerResult').className='notice'+(result==='incorrect'?' error':'');const title=result==='correct'?'Bài làm đúng.':result==='incorrect'?'Bài này chưa đúng. Bạn có thể thử lại.':'Chưa đủ rõ để chấm. Bạn có thể thử lại hoặc kết thúc không chấm.';$('answerResult').textContent=title+(d.feedback?' '+d.feedback:'')+(d.hint?' Gợi ý: '+d.hint:'');if(result==='correct'&&state.ringing)stopAlarm()}catch(e){$('answerResult').hidden=false;$('answerResult').className='notice error';$('answerResult').textContent=e.message+' Bạn vẫn có thể kết thúc không chấm.'}finally{b.disabled=false;$('loadQuestion').disabled=false}});
function completeUngraded(){if(state.ringing)stopAlarm();$('answerResult').hidden=false;$('answerResult').className='notice';$('answerResult').textContent='Đã kết thúc không chấm. Không cộng điểm.'}
function remaining(){return state.timer.deadline?Math.max(0,state.timer.deadline-Date.now()):state.timer.remaining}
function renderTimer(){
  const t=state.timer,r=remaining(),seconds=Math.ceil(r/1000);
  $('timer').textContent=String(Math.floor(seconds/60)).padStart(2,'0')+':'+String(seconds%60).padStart(2,'0');
  $('timerOrbit').style.setProperty('--progress',Math.min(100,Math.max(0,100-r/(t.minutes*60000)*100))+'%');
  $('timerState').textContent=t.deadline?'Đang tập trung':t.started?(r===0?'Đã hết thời gian':'Đang tạm nghỉ'):'Sẵn sàng bắt đầu';
  $('timerToggle').textContent=t.deadline?'Tạm nghỉ':t.started?(r===0?'Học thêm một phiên':'Tiếp tục học'):'Bắt đầu học';
  $('finishStudy').disabled=!t.started;
  ['studyTask','studySubject','grade'].forEach(id=>$(id).disabled=!!t.started);
  document.querySelectorAll('[data-min]').forEach(b=>{b.classList.toggle('selected',Number(b.dataset.min)===t.minutes);b.disabled=!!t.started});
  if(t.deadline&&r===0){t.deadline=null;t.remaining=0;persist();toast('Hết thời gian tập trung. Bạn có thể kết thúc phiên.');renderTimer()}
}
function setMinutes(m){if(state.timer.started)return;state.timer.minutes=m;state.timer.remaining=m*60000;persist();renderTimer()}
async function toggleTimer(){
  const t=state.timer;if(t.started&&remaining()===0){await finishStudy();return}
  if(!t.started){if(!$('studyTask').value.trim()){$('studyTask').focus();return}t.started=Date.now();t.id='study-'+newId();t.serverId=null;t.context={clientSessionId:t.id,taskTitle:$('studyTask').value.trim(),subjectCode:$('studySubject').value,targetMinutes:t.minutes,startedAt:new Date(t.started).toISOString()}}
  if(t.deadline){t.remaining=remaining();t.deadline=null}else t.deadline=Date.now()+t.remaining;
  persist();renderTimer();
  if(!t.serverId){const id=t.id;try{const d=await api('/study/sessions',t.context||{clientSessionId:id,taskTitle:$('studyTask').value.trim(),subjectCode:$('studySubject').value,targetMinutes:t.minutes},'POST',id);if(t.id===id){t.serverId=d.sessionId||d.id;persist();$('studySync').textContent='Phiên học đã đồng bộ. Timer vẫn chạy local.'}}catch{$('studySync').textContent='Đang học local. Phiên sẽ được giữ lại để gửi sau.'}}
}
async function finishStudy(){
  const t=state.timer;if(!t.started)return;
  const snapshot={...t,elapsed:Math.max(0,Math.floor((Date.now()-t.started)/1000)),endedAt:new Date().toISOString()};
  if(!state.pending.some(x=>x.id===snapshot.id))state.pending.push(snapshot);
  Object.assign(t,{deadline:null,started:null,remaining:t.minutes*60000,id:null,serverId:null,context:null});persist();renderTimer();updatePending();
  $('studySync').textContent='Đã kết thúc và giữ phiên trên máy.';
  try{await syncStudyRecord(snapshot);$('studySync').textContent='Đã lưu phiên học vào hệ thống.'}catch{$('studySync').textContent='Đã kết thúc local. Vào Tôi để gửi lại khi có mạng.'}
}
function bubble(text,role='assistant',error=false){const b=document.createElement('div');b.className='bubble'+(role==='user'?' user':'')+(error?' error':'');const label=document.createElement('small');label.textContent=role==='user'?'Bạn':'MindClock';b.append(label,document.createTextNode(text));$('messages').append(b);$('messages').scrollTop=$('messages').scrollHeight;return b}
async function sendChat(text){if(state.busy)return;state.busy=true;lastChat=text;$('chatSend').disabled=true;$('retryChat').hidden=true;bubble(text,'user');const pending=bubble('Đang tìm bước gợi ý…');try{const d=await api('/study/help',{clientSessionId:state.timer.id||'chat-'+uid,subject:$('studySubject').value,grade:$('grade').value,task:$('studyTask').value.trim()||'Học tự do',questionText:text,recentTurns:state.history.slice(-3)});if(d.safety_status==='fallback'||d.model_version==='offline-fallback')throw Error('AI live chưa sẵn sàng. Hệ thống đang dùng hướng dẫn dự phòng.');const reply=[d.message_vi,d.next_question_vi].filter(Boolean).join('\n\n');if(!reply)throw Error('Trợ lý chưa trả nội dung. Hãy thử lại.');pending.remove();bubble(reply);state.history.push({role:'user',contentVi:text},{role:'assistant',contentVi:reply});state.history=state.history.slice(-3)}catch(e){pending.remove();bubble(e.message+' Timer vẫn hoạt động.', 'assistant',true);$('retryChat').hidden=false}finally{state.busy=false;$('chatSend').disabled=false}}
$('chatForm').addEventListener('submit',e=>{e.preventDefault();const text=$('chatInput').value.trim();if(text){$('chatInput').value='';sendChat(text)}});$('chatInput').addEventListener('keydown',e=>{if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();$('chatForm').requestSubmit()}});
function suggest(t){$('chatInput').value=t;$('chatInput').focus()}function retryChat(){if(lastChat)sendChat(lastChat)}function clearChat(){if(state.busy){toast('Đợi phản hồi hiện tại kết thúc rồi xóa.');return}state.history=[];$('messages').replaceChildren();bubble('Hội thoại đã xóa trên trang. Bạn muốn hỏi điều gì tiếp theo?');$('retryChat').hidden=true;lastChat=''}
async function health(){try{await api('/health');$('health').replaceChildren();const dot=document.createElement('i');dot.className='dot ok';$('health').append(dot,document.createTextNode('Đã kết nối'));$('connectionWarning').hidden=true}catch{$('health').textContent='Đang dùng local';$('connectionWarning').hidden=false;$('connectionWarning').textContent='Chưa kết nối backend. Báo thức và timer local vẫn dùng được; trợ lý AI cần kết nối.'}}

function openPractice(){navigate('home');$('challengeCard').hidden=false;$('challengeCard').scrollIntoView({behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'instant':'smooth'})}
function closePractice(){if(state.ringing){toast('Dừng chuông trước khi đóng câu ôn.');return}$('challengeCard').hidden=true}
function studyView(view){const chat=view==='chat';$('study-focus').hidden=chat;$('study-chat').hidden=!chat;$('study-focus-tab').classList.toggle('active',!chat);$('study-chat-tab').classList.toggle('active',chat);if(chat)$('messages').scrollTop=$('messages').scrollHeight}
function updatePending(){ $('pendingCount').textContent=String(state.pending.length);$('syncPending').disabled=state.pending.length===0; }
async function syncStudyRecord(record){
  let serverId=record.serverId;
  if(!serverId){const created=await api('/study/sessions',record.context||{clientSessionId:record.id,taskTitle:'Phiên học trên máy',targetMinutes:record.minutes},'POST',record.id);serverId=created.sessionId||created.id}
  if(!serverId)throw Error('Chưa nhận được mã phiên học.');
  await api('/study/sessions/'+encodeURIComponent(serverId)+'/finish',{clientSessionId:record.id,finalStatus:'completed',elapsedWallSeconds:record.elapsed,inAppFocusSeconds:0,endedAt:record.endedAt},'POST','finish-'+record.id);
  state.pending=state.pending.filter(x=>x.id!==record.id);persist();updatePending();
}
async function syncPending(){
  if(state.syncing)return;state.syncing=true;$('syncPending').disabled=true;
  try{for(const record of [...state.pending])await syncStudyRecord(record);toast('Đã đồng bộ các phiên học.')}catch(e){toast('Chưa gửi được. Phiên vẫn được giữ trên máy.')}finally{state.syncing=false;updatePending()}
}
function updateNextAlarm(){
  if(!state.alarm.enabled)return;
  const now=new Date(),[h,m]=state.alarm.time.split(':').map(Number);
  for(let offset=0;offset<8;offset++){const next=new Date(now);next.setDate(now.getDate()+offset);next.setHours(h,m,0,0);if(next>now&&(!state.alarm.days.length||state.alarm.days.includes(next.getDay()))){$('nextAlarmText').textContent=(offset===0?'Hôm nay':offset===1?'Ngày mai':next.toLocaleDateString('vi-VN',{weekday:'long'}))+' · '+state.alarm.time;break}}
}
window.addEventListener('hashchange',()=>navigate(location.hash.slice(1)));
if(window.visualViewport){window.visualViewport.addEventListener('resize',()=>{document.body.classList.toggle('keyboard-open',window.visualViewport.height<window.innerHeight*0.76)})}

restore();renderAlarm();renderTimer();navigate((location.hash||'#home').slice(1));updateNextAlarm();const now=new Date();$('greetingDate').textContent=now.toLocaleDateString('vi-VN',{weekday:'long'});$('todayDate').textContent=now.toLocaleDateString('vi-VN',{day:'numeric',month:'long',year:'numeric'});if(restored)$('studySync').textContent='Đã khôi phục phiên học trên máy. Nội dung chat không lưu mặc định.';health();setInterval(()=>{const n=new Date();$('liveClock').textContent=n.toLocaleTimeString('vi-VN');renderTimer();const hm=String(n.getHours()).padStart(2,'0')+':'+String(n.getMinutes()).padStart(2,'0');const key=n.toLocaleDateString()+' '+hm;if(state.alarm.enabled&&hm===state.alarm.time&&key!==state.lastRing&&(!state.alarm.days.length||state.alarm.days.includes(n.getDay()))){state.lastRing=key;persist();ringAlarm();if(!state.alarm.days.length){state.alarm.enabled=false;persist();renderAlarm()}}},500);window.addEventListener('online',health);window.addEventListener('pagehide',()=>{persist();if(state.ringing)stopAlarm()});document.addEventListener('keydown',e=>{if(e.key==='Escape'&&state.ringing)stopAlarm()});
