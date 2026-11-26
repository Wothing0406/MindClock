from pathlib import Path

p = Path('services/api/app/product.js')
s = p.read_text(encoding='utf-8')
def line(prefix, replacement):
    global s
    lines = s.splitlines()
    hits = [i for i, value in enumerate(lines) if value.startswith(prefix)]
    assert len(hits) == 1, (prefix, hits)
    lines[hits[0]] = replacement
    s = '\n'.join(lines) + '\n'

s = s.replace("busy:false};", "busy:false,pending:[]};")
s = s.replace("timer:state.timer,study:", "timer:state.timer,pending:state.pending,lastRing:state.lastRing,study:")
s = s.replace("if(s){if(s.study)", "if(s){state.pending=Array.isArray(s.pending)?s.pending.filter(x=>x&&typeof x.id==='string'):[];state.lastRing=s.lastRing||'';if(s.study)")
line('function navigate(', '''function navigate(page){
  const pages=['home','alarm','study','profile'];if(!pages.includes(page))page='home';
  pages.forEach(name=>{$('page-'+name).hidden=name!==page;$('nav-'+name).classList.toggle('active',name===page);$('nav-'+name).setAttribute('aria-current',name===page?'page':'false')});
  document.title='MindClock — '+({home:'Hôm nay',alarm:'Báo thức',study:'Không gian học',profile:'Của bạn'}[page]);
  if(typeof history!=='undefined'&&history.replaceState)history.replaceState(null,'','#'+page);
  window.scrollTo({top:0,behavior:'instant'});updatePending();
}''')
line('function openChallenge(', "function openChallenge(){$('ringing').hidden=true;openPractice();if(!state.question)loadQuestion()}")
# Keep retry keys until a conclusive response; a timeout must not create a second attempt.
s=s.replace("const attemptKey='answer-'+crypto.randomUUID();", "const attemptBody=JSON.stringify({answerValue:$('answer').value.trim(),reasoningText:$('reasoning').value.trim()});if(!state.attempt||state.attempt.body!==attemptBody)state.attempt={body:attemptBody,key:'answer-'+crypto.randomUUID()};const attemptKey=state.attempt.key;")
s=s.replace("const result=d.result||'uncertain';", "state.attempt=null;const result=d.result||'uncertain';")
s=s.replace("state.question=null;state.session=null;", "state.question=null;state.session=null;state.attempt=null;")
line('function renderTimer(', '''function renderTimer(){
  const t=state.timer,r=remaining(),seconds=Math.ceil(r/1000);
  $('timer').textContent=String(Math.floor(seconds/60)).padStart(2,'0')+':'+String(seconds%60).padStart(2,'0');
  $('timerOrbit').style.setProperty('--progress',Math.min(100,Math.max(0,100-r/(t.minutes*60000)*100))+'%');
  $('timerState').textContent=t.deadline?'Đang tập trung':t.started?(r===0?'Đã hết thời gian':'Đang tạm nghỉ'):'Sẵn sàng bắt đầu';
  $('timerToggle').textContent=t.deadline?'Tạm nghỉ':t.started?(r===0?'Học thêm một phiên':'Tiếp tục học'):'Bắt đầu học';
  $('finishStudy').disabled=!t.started;
  ['studyTask','studySubject','grade'].forEach(id=>$(id).disabled=!!t.started);
  document.querySelectorAll('[data-min]').forEach(b=>{b.classList.toggle('selected',Number(b.dataset.min)===t.minutes);b.disabled=!!t.started});
  if(t.deadline&&r===0){t.deadline=null;t.remaining=0;persist();toast('Hết thời gian tập trung. Bạn có thể kết thúc phiên.');renderTimer()}
}''')
line('async function toggleTimer(', '''async function toggleTimer(){
  const t=state.timer;if(t.started&&remaining()===0){await finishStudy();return}
  if(!t.started){if(!$('studyTask').value.trim()){$('studyTask').focus();return}t.started=Date.now();t.id='study-'+crypto.randomUUID();t.serverId=null;t.context={clientSessionId:t.id,taskTitle:$('studyTask').value.trim(),subjectCode:$('studySubject').value,targetMinutes:t.minutes,startedAt:new Date(t.started).toISOString()}}
  if(t.deadline){t.remaining=remaining();t.deadline=null}else t.deadline=Date.now()+t.remaining;
  persist();renderTimer();
  if(!t.serverId){const id=t.id;try{const d=await api('/study/sessions',t.context||{clientSessionId:id,taskTitle:$('studyTask').value.trim(),subjectCode:$('studySubject').value,targetMinutes:t.minutes},'POST',id);if(t.id===id){t.serverId=d.sessionId||d.id;persist();$('studySync').textContent='Phiên học đã đồng bộ. Timer vẫn chạy local.'}}catch{$('studySync').textContent='Đang học local. Phiên sẽ được giữ lại để gửi sau.'}}
}''')
line('async function finishStudy(', '''async function finishStudy(){
  const t=state.timer;if(!t.started)return;
  const snapshot={...t,elapsed:Math.max(0,Math.floor((Date.now()-t.started)/1000)),endedAt:new Date().toISOString()};
  if(!state.pending.some(x=>x.id===snapshot.id))state.pending.push(snapshot);
  Object.assign(t,{deadline:null,started:null,remaining:t.minutes*60000,id:null,serverId:null,context:null});persist();renderTimer();updatePending();
  $('studySync').textContent='Đã kết thúc và giữ phiên trên máy.';
  try{await syncStudyRecord(snapshot);$('studySync').textContent='Đã lưu phiên học vào hệ thống.'}catch{$('studySync').textContent='Đã kết thúc local. Vào Tôi để gửi lại khi có mạng.'}
}''')
# Do not clear a question that is submitted while an earlier request is in flight.
s=s.replace("b.disabled=true;const attemptBody", "b.disabled=true;$('loadQuestion').disabled=true;const attemptBody")
s=s.replace("finally{b.disabled=false}});", "finally{b.disabled=false;$('loadQuestion').disabled=false}});")
extra = '''
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
'''
s=s.replace('restore();renderAlarm();renderTimer();',extra+"\nrestore();renderAlarm();renderTimer();navigate((location.hash||'#home').slice(1));updateNextAlarm();")
s=s.replace("state.lastRing=key;ringAlarm();", "state.lastRing=key;persist();ringAlarm();")
s=s.replace("renderDays()}\n", "renderDays();updateNextAlarm()}\n")
s=s.replace("$('floatingStop').hidden=false;document.querySelector", "$('floatingStop').hidden=false;$('openAlarmQuestion').hidden=!state.alarm.challenge;document.querySelector")
p.write_text(s,encoding='utf-8')
print('Mobile JS upgraded')
