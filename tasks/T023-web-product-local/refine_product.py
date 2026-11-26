from pathlib import Path

p = Path('services/api/app/product.html')
s = p.read_text(encoding='utf-8')
s = s.replace("const reply=[d.message_vi,d.next_question_vi]", "if(d.safety_status==='fallback'||d.model_version==='offline-fallback')throw Error('AI live chưa sẵn sàng. Hệ thống đang dùng hướng dẫn dự phòng.');const reply=[d.message_vi,d.next_question_vi]")
# Recover the task context together with the local timer, without storing chat.
s = s.replace("{alarm:state.alarm,timer:state.timer}", "{alarm:state.alarm,timer:state.timer,study:{task:$('studyTask').value,subject:$('studySubject').value,grade:$('grade').value}}")
s = s.replace("if(s){if(s.alarm", "if(s){if(s.study){$('studyTask').value=s.study.task||'';$('studySubject').value=s.study.subject||'TOAN';$('grade').value=s.study.grade||'Lớp 12'}if(s.alarm")
p.write_text(s, encoding='utf-8')
print('Refined fallback labels and local task restoration')
