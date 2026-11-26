from pathlib import Path
p=Path('services/api/app/product.js')
s=p.read_text(encoding='utf-8')
s=s.replace('let toastHandle=null,', 'let alarmDraftDays=[...state.alarm.days];\nlet toastHandle=null,')
lines=s.splitlines()
for i,line in enumerate(lines):
    if line.startswith('function renderDays('):
        lines[i]=line.replace('state.alarm.days','alarmDraftDays')
    if line.startswith('function renderAlarm('):
        lines[i]=line.replace('const a=state.alarm;', 'const a=state.alarm;alarmDraftDays=[...a.days];')
    if line.startswith("$('alarmForm').addEventListener"):
        lines[i]='''$('alarmForm').addEventListener('submit',async e=>{
  e.preventDefault();const button=$('alarmSave');button.disabled=true;unlockAudio();
  Object.assign(state.alarm,{time:$('alarmTime').value,enabled:$('alarmEnabled').checked,challenge:$('challengeMode').checked,sound:$('alarmSound').value,days:[...alarmDraftDays]});
  const body={localTime:state.alarm.time,timeZone:Intl.DateTimeFormat().resolvedOptions().timeZone,weekdays:state.alarm.days.map(d=>d===0?7:d),enabled:state.alarm.enabled,challengeMode:state.alarm.challenge?'short_review':'none'};
  const serialized=JSON.stringify(body);if(state.alarm.pendingBody!==serialized){state.alarm.pendingBody=serialized;state.alarm.pendingKey='alarm-'+crypto.randomUUID()}
  persist();renderAlarm();$('alarmStatus').textContent='Đã lưu trên máy. Giữ tab mở để phát chuông.';
  try{const id=state.alarm.serverId;const data=await api('/alarms'+(id?'/'+encodeURIComponent(id):''),body,id?'PATCH':'POST',id?null:state.alarm.pendingKey);state.alarm.serverId=data.id||id;persist();$('alarmStatus').textContent='Đã lưu local và đồng bộ cấu hình.'}
  catch{$('alarmStatus').textContent='Đã lưu local. Chưa đồng bộ; nhấn Lưu để gửi lại khi có mạng.'}
  finally{button.disabled=false}
});'''
p.write_text('\n'.join(lines)+'\n',encoding='utf-8')
html=Path('services/api/app/mobile.html')
h=html.read_text(encoding='utf-8').replace('<button class="btn wide" type="submit">Lưu báo thức</button>','<button id="alarmSave" class="btn wide" type="submit">Lưu báo thức</button>')
html.write_text(h,encoding='utf-8')
print('Alarm save/update/retry and draft days fixed')
