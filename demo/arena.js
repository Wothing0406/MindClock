"use strict";
// Offline visual training only. Real matches require server grading and settlement (docs/46).
const characters = {
  ha_nhan: {slug:"ha-nhan",name:"Hà Nhân",role:"Đấu sĩ bền bỉ",description:"Tu sĩ áo vải, bình tĩnh, giữ nhịp học đều. Vòng giáp như trang vở được gấp lại.",how:"Làm đúng liên tiếp để hồi giáp; dùng Bước Vững khi giáp sắp vỡ.",tradeoff:"Sát thương vừa phải, khó kết trận sớm.",passive:{name:"Giữ Nhịp",text:"Hai bài đúng liên tiếp: hồi 8 giáp, tối đa hai lần."},skills:[{name:"Bước Vững",damage:25,armor:6,cost:1,desc:"25 sát thương · hồi 6 giáp"},{name:"Tĩnh Tâm Phản Kích",damage:32,heal:8,cost:2,desc:"32 sát thương · hồi 8 máu nếu còn sống"}]},
  han_boi_thap: {slug:"han-boi-phap",name:"Hàn Bối Pháp",role:"Hộ pháp phòng thủ",description:"Hộ pháp đeo tháp giấy, nghiêm túc quá mức. Tháp dựng lên đúng lúc giáp vừa vỡ.",how:"Dựng chắn để chịu đòn; Trấn Tháp giúp phục hồi giáp đã mất.",tradeoff:"Đòn nhẹ, phải giữ trận đủ lâu.",passive:{name:"Tháp Còn Đứng",text:"Giáp vỡ lần đầu: nhận 12 chắn ở vòng sau, một lần mỗi trận."},skills:[{name:"Dựng Tháp",damage:18,ward:14,cost:1,desc:"18 sát thương · nhận 14 chắn"},{name:"Trấn Tháp",damage:28,armor:16,cost:2,desc:"28 sát thương · hồi 16 giáp"}]},
  tuyet_dinh: {slug:"tuyet-dinh",name:"Tuyệt Đỉnh",role:"Kiếm sĩ sát thương",description:"Kiếm khách áo đỏ, ra chiêu rất chắc tay; tóc có thể không nghe lời.",how:"Giữ chuỗi đúng để tích Kiếm Ý, rồi chọn thời điểm ra đòn lớn.",tradeoff:"Không tự hồi giáp; chiêu mạnh để lại nhịp đánh thường yếu.",passive:{name:"Kiếm Ý",text:"Hai bài đúng liên tiếp: đòn thường kế +6, tối đa hai lần."},skills:[{name:"Một Nét Thành Chiêu",damage:38,cost:1,desc:"38 sát thương · không hồi/chắn"},{name:"Đường Kiếm Cuối Trang",damage:46,cost:2,drawback:true,desc:"46 sát thương · đòn thường kế còn 22"}]}
};
const order = ["ha_nhan","han_boi_thap","tuyet_dinh"];
const avatarNames = [["cao-giay","Cáo Giấy"],["cu-meo","Cú Mèo"],["rua-xanh","Rùa Xanh"],["tho-so","Thỏ Sổ"],["may-nho","Mây Nhỏ"],["ca-chep","Cá Chép"]];
const rankNames = [["thuong","Thường"],["dong","Đồng"],["bac","Bạc"],["vang","Vàng"],["bach-kim","Bạch Kim"],["kim-cuong","Kim Cương"],["tinh-anh","Tinh Anh"]];
const questions = [{text:"6 + 7 = ?",answer:"13"},{text:"18 ÷ 2 = ?",answer:"9"},{text:"Một hình vuông cạnh 3 cm có chu vi bao nhiêu cm?",answer:"12"}];
const $ = id => document.getElementById(id);
const renderer = new ArenaRenderer($("battle-canvas"));
const fresh = () => ({hp:100,armor:50,ward:0,qi:0,streak:0,passiveCount:0,charged:false,weakBasic:false,used:[false,false],broken:false});
let selected="ha_nhan",opponent="han_boi_thap",hero=fresh(),enemy=fresh(),ready=false,turn=0,finished=false,log=[],roundToken=0,sound=false;
let localAvatarUrl=null,badgeId="dong";
const {clamp,applyDamage}=window.ArenaRules;
function note(message){log.unshift(message);log=log.slice(0,8);$("event-text").textContent=message;$("event-log").replaceChildren(...log.map(s=>{const li=document.createElement("li");li.textContent=s;return li}));}
function makeRoster(){const box=$("roster");box.replaceChildren(...order.map(id=>{const x=characters[id],b=document.createElement("button");b.type="button";b.className="roster-card";b.dataset.character=id;b.innerHTML=`<span class="card-portrait"><img src="./assets/game/characters/${x.slug}/runtime/idle.webp" alt=""></span><span class="card-text"><strong>${x.name}</strong><small>${x.role}</small></span>`;b.addEventListener("click",()=>{selected=id;reset()});return b}));}
function makeCosmetics(){
  const avatars=$("avatar-options"),ranks=$("rank-options"),badges=$("badge-options");
  avatars.replaceChildren(...avatarNames.map(([id,name])=>{
    const b=document.createElement("button");b.type="button";b.title=name;b.setAttribute("aria-label","Avatar "+name);
    const img=document.createElement("img");img.src=`./assets/game/ui/avatars/${id}.webp`;img.alt="";b.append(img);
    b.addEventListener("click",()=>{
      if(localAvatarUrl){URL.revokeObjectURL(localAvatarUrl);localAvatarUrl=null}
      $("chosen-avatar").src=img.src;$("chosen-avatar").alt="Avatar "+name;
      $("avatar-message").textContent="Đã chọn avatar có sẵn. Bản xem thử không lưu thay đổi.";
      avatars.querySelectorAll("button").forEach(x=>x.setAttribute("aria-pressed",String(x===b)));
    });return b;
  }));
  ranks.replaceChildren(...rankNames.map(([id,name])=>{
    const b=document.createElement("button");b.type="button";b.title=name;b.setAttribute("aria-label","Khung "+name);
    const img=document.createElement("img");img.src=`./assets/game/ui/rank/${id}.svg`;img.alt="";b.append(img);
    b.addEventListener("click",()=>{$("avatar-frame").style.backgroundImage=`url('${img.src}')`;ranks.querySelectorAll("button").forEach(x=>x.setAttribute("aria-pressed",String(x===b)))});
    return b;
  }));
  badges.replaceChildren(...rankNames.slice(1).map(([id,name])=>{
    const b=document.createElement("button");b.type="button";b.title=name;b.setAttribute("aria-label","Huy hiệu "+name);
    const img=document.createElement("img");img.src=`./assets/game/ui/rank/badges/${id}.svg`;img.alt="";b.append(img);
    b.addEventListener("click",()=>{badgeId=id;$("profile-badge").src=img.src;$("profile-badge").alt="Huy hiệu "+name+" minh họa";$("result-badge").src=img.src;$("result-badge").alt=$("profile-badge").alt;badges.querySelectorAll("button").forEach(x=>x.setAttribute("aria-pressed",String(x===b)))});
    return b;
  }));
  avatars.firstChild?.click();ranks.firstChild?.click();badges.firstChild?.click();
}
async function previewUpload(){
  const file=$("avatar-upload").files?.[0];if(!file)return;
  const error=window.ProfileRules.validateAvatarFile(file);
  if(error){$("avatar-message").textContent=error;$("avatar-upload").value="";return}
  try{
    const bitmap=await createImageBitmap(file);
    if(!window.ProfileRules.validateAvatarDimensions(bitmap.width,bitmap.height)){bitmap.close();throw new Error("bad dimensions")}
    bitmap.close();
    if(localAvatarUrl)URL.revokeObjectURL(localAvatarUrl);
    localAvatarUrl=URL.createObjectURL(file);
    $("chosen-avatar").src=localAvatarUrl;$("chosen-avatar").alt="Ảnh vừa chọn, chỉ xem trên máy";
    $("avatar-message").textContent="Đang xem thử ảnh trên máy. Tải lại trang sẽ mất ảnh; không gửi lên server.";
    $("avatar-options").querySelectorAll("button").forEach(x=>x.setAttribute("aria-pressed","false"));
  }catch{$("avatar-message").textContent="Không đọc được ảnh này. Chọn ảnh khác."}
  $("avatar-upload").value="";
}
function render(){const kit=characters[selected],foe=characters[opponent];$("hero-name").textContent=kit.name;$("enemy-name").textContent=foe.name;$("hero-role").textContent=kit.role;$("kit-title").textContent=kit.name;$("kit-role").textContent=kit.role;$("kit-description").textContent=kit.description;$("kit-how").textContent=kit.how;$("kit-tradeoff").textContent=kit.tradeoff;$("kit-passive").textContent=kit.passive.name+": "+kit.passive.text;for(const [p,s] of [["hero",hero],["enemy",enemy]]){$(p+"-hp").textContent=s.hp+"/100";$(p+"-armor").textContent=s.armor+"/50";$(p+"-ward").textContent=s.ward;$(p+"-hp-bar").style.width=s.hp+"%";$(p+"-armor-bar").style.width=s.armor*2+"%"}$("hero-qi").textContent=hero.qi+"/3";$("hero-streak").textContent=hero.streak;$("question-count").textContent=`Câu ${turn+1}/6 · chấm đáp án mẫu`;$("question-text").textContent=questions[turn%questions.length].text;document.querySelectorAll(".roster-card").forEach(b=>b.setAttribute("aria-pressed",String(b.dataset.character===selected)));renderAbilities();renderPoses();}
function renderAbilities(){
  const kit=characters[selected];
  const entries=[
    {id:"basic",name:"Đánh thường",desc:`${hero.weakBasic?22:28}${hero.charged?" + 6":""} sát thương`,cost:0},
    {id:"skill1",...kit.skills[0]},
    {id:"skill2",...kit.skills[1]}
  ];
  $("ability-list").replaceChildren(...entries.map((a,i)=>{
    const b=document.createElement("button");b.className="ability";b.type="button";b.dataset.action=a.id;
    b.disabled=!ready||finished||hero.qi<a.cost||(i>0&&hero.used[i-1])||(selected==="tuyet_dinh"&&i===2&&turn===5);
    const icon=document.createElement("span");icon.className="ability-icon";icon.textContent=i===0?"／":String(i);
    const txt=document.createElement("span");
    const title=document.createElement("strong");title.textContent=a.name;
    const detail=document.createElement("small");detail.textContent=a.desc;
    txt.append(title,detail);
    const cost=document.createElement("span");cost.className="ability-cost";cost.textContent=a.cost+" khí";
    b.append(icon,txt,cost);b.addEventListener("click",()=>perform(a.id));return b;
  }));
}
function renderPoses(){
  const kit=characters[selected],labels=["idle","basic","skill1","skill2","hurt","stun","heal","victory"];
  $("pose-grid").replaceChildren(...labels.map(id=>{
    const b=document.createElement("button");b.type="button";b.className="pose-card";
    const img=document.createElement("img");
    img.src=`./assets/game/characters/${kit.slug}/runtime/${id==="idle"?"idle.webp":`frames/${id}/f00.webp`}`;
    img.alt="";img.loading="lazy";
    const s=document.createElement("span");s.textContent={idle:"Đứng",basic:"Đánh thường",skill1:"Chiêu 1",skill2:"Chiêu 2",hurt:"Trúng đòn",stun:"Choáng",heal:"Hồi phục",victory:"Thắng"}[id];
    b.append(img,s);b.addEventListener("click",()=>{
      if(id==="basic"||id.startsWith("skill"))renderer.attack(kit.slug,id,0);
      else if(id!=="idle")renderer.state(kit.slug,id==="victory"?"win":id);
      else renderer.skip();
      note("Xem tư thế: "+kit.name+" · "+s.textContent);
    });
    return b;
  }));
}
function awardPassive(){const kit=characters[selected];if(hero.passiveCount>=2||hero.streak<2||hero.streak%2)return;if(selected==="ha_nhan"){const n=Math.min(8,50-hero.armor);hero.armor+=n;note(kit.passive.name+": +"+n+" giáp.")}if(selected==="tuyet_dinh"){hero.charged=true;note(kit.passive.name+": đòn thường kế +6.")}hero.passiveCount++;}
function submitAnswer(){if(finished||ready)return;const q=questions[turn%questions.length],v=$("answer-input").value.trim().replace(",","."),reason=$("reason-input").value.trim();if(!reason){note("Viết ít nhất một bước làm trước khi nộp.");return}if(v!==q.answer){hero.streak=0;note("Đáp án chưa đúng. Thử lại câu này; không bị trừ điểm.");render();return}ready=true;note("Đáp án mẫu đúng. Chọn một hành động. Phần trình bày chưa được AI chấm.");render();}
function perform(id){
  if(!ready||finished)return;
  const kit=characters[selected],idx=id==="skill1"?0:1,skill=id==="basic"?null:kit.skills[idx];
  if(skill&&(hero.qi<skill.cost||hero.used[idx]||(selected==="tuyet_dinh"&&id==="skill2"&&turn===5)))return;
  ready=false;
  const amount=skill?skill.damage:(hero.weakBasic?22:28)+(hero.charged?6:0);
  if(id==="basic"){hero.weakBasic=false;hero.charged=false}
  else{hero.qi-=skill.cost;hero.used[idx]=true;if(skill.drawback)hero.weakBasic=true}
  const loss=applyDamage(enemy,amount,opponent);
  if(skill?.ward)hero.ward=clamp(hero.ward+skill.ward,0,20);
  if(skill?.armor)hero.armor=clamp(hero.armor+skill.armor,0,50);
  if(skill?.heal&&hero.hp>0)hero.hp=clamp(hero.hp+skill.heal,0,100);
  hero.qi=clamp(hero.qi+1,0,3);hero.streak++;
  const selfEffect=skill?.ward?`characters/${kit.slug}/fx/passive.svg`:skill?.heal?"effects/runtime/healing.svg":skill?.armor?`characters/${kit.slug}/fx/passive.svg`:null;
  renderer.attack(kit.slug,id,amount,selfEffect);
  note(`${kit.name}: ${skill?skill.name:"Đánh thường"}, ${amount} sát thương (chắn −${loss.w}, giáp −${loss.a}, máu −${loss.h}).`);
  turn++;$("answer-input").value="";$("reason-input").value="";render();
  const token=++roundToken;
  setTimeout(()=>{
    if(token!==roundToken)return;
    if(enemy.hp>0){
      const hit=applyDamage(hero,28,selected);
      renderer.attack(characters[opponent].slug,"basic",28,null,"right");
      note(`${characters[opponent].name} phản đòn tập: giáp −${hit.a}, máu −${hit.h}.`);
    }
    // Ward lasts for the current opponent hit. The guardian passive grants a fresh next-round ward.
    hero.ward=0;enemy.ward=0;
    if(selected==="han_boi_thap"&&hero.broken&&hero.passiveCount===0&&hero.hp>0){
      hero.ward=12;hero.passiveCount=1;hero.broken=false;
      note("Tháp Còn Đứng: +12 chắn cho lượt kế.");
      setTimeout(()=>{if(token===roundToken)renderer.passive(kit.slug)},850);
    }
    if(selected!=="han_boi_thap"){
      const shouldShow=hero.streak>=2&&hero.streak%2===0&&hero.passiveCount<2;
      awardPassive();
      if(shouldShow)setTimeout(()=>{if(token===roundToken)renderer.passive(kit.slug)},850);
    }
    if(enemy.hp===0||hero.hp===0||turn>=6){
      finished=true;
      const won=hero.hp>enemy.hp||(hero.hp===enemy.hp&&hero.armor>enemy.armor);
      $("result-card").hidden=false;
      $("result-title").textContent=won?`${kit.name} hoàn thành lượt tập`:"Kết thúc lượt tập";
      if(won){setTimeout(()=>{if(token===roundToken)renderer.state(kit.slug,"win")},950);note("Hết lượt tập: "+kit.name+" thắng. Không thay đổi điểm hạng.")}
      else note("Hết lượt tập. Đặt lại để thử cách chơi khác.");
    }
    render();
  },1020);
}
function preview(id){const kit=characters[selected];if(id==="hurt"){const x=applyDamage(hero,28,selected);note("Xem trúng đòn: giáp −"+x.a+", máu −"+x.h+".")}if(id==="stun")note("Xem choáng hình ảnh; không mất lượt.");if(id==="heal"){const n=Math.min(8,100-hero.hp);hero.hp+=n;note("Xem hồi phục: +"+n+" máu.")}if(id==="win")note("Xem điệu thắng của "+kit.name+". Kết quả thật cần máy chủ xác nhận.");renderer.state(kit.slug,id);render();}
function reset(){roundToken++;hero=fresh();enemy=fresh();ready=false;turn=0;finished=false;$("result-card").hidden=true;opponent=order[(order.indexOf(selected)+1)%3];renderer.setCharacters(characters[selected].slug,characters[opponent].slug);$("answer-input").value="";$("reason-input").value="";log=[];render();note("Đã đặt lại. Làm câu mẫu rồi chọn hành động.");}
$("submit-answer").addEventListener("click",submitAnswer);$("answer-input").addEventListener("keydown",e=>{if(e.key==="Enter")$("reason-input").focus()});$("reason-input").addEventListener("keydown",e=>{if(e.key==="Enter")submitAnswer()});$("reset").addEventListener("click",reset);$("skip-fx").addEventListener("click",()=>renderer.skip());$("sound-toggle").addEventListener("click",()=>{sound=!sound;renderer.setSound(sound);$("sound-toggle").textContent=sound?"Tắt âm":"Bật âm";$("sound-toggle").setAttribute("aria-pressed",String(sound))});$("clear-log").addEventListener("click",()=>{log=[];$("event-log").replaceChildren();note("Đã xóa nhật ký.")});document.querySelectorAll("[data-preview]").forEach(b=>b.addEventListener("click",()=>preview(b.dataset.preview)));makeRoster();makeCosmetics();reset();
$("avatar-upload").addEventListener("change",previewUpload);
$("remove-avatar").addEventListener("click",()=>$("avatar-options").firstChild?.click());
window.addEventListener("beforeunload",()=>{if(localAvatarUrl)URL.revokeObjectURL(localAvatarUrl)});
