// 侧视角剖面实验室概念图
const FLOOR=800, CEIL=200, BEAMY=520;

function figure(ctx,x,y,h,facing,pose){ // 白大褂几何剪影，y=脚底
  const s=h/150; ctx.save(); ctx.translate(x,y); ctx.scale(facing*s,s);
  ctx.shadowColor=C.cyan; ctx.shadowBlur=14;
  // 腿
  ctx.strokeStyle='#cfe6ea'; ctx.lineWidth=7; ctx.lineCap='round';
  const step = pose==='walk'?14:0;
  ctx.beginPath(); ctx.moveTo(-6,-62); ctx.lineTo(-6-step,0); ctx.moveTo(6,-62); ctx.lineTo(6+step,0); ctx.stroke();
  // 白大褂
  ctx.fillStyle='#e8f6f8'; ctx.beginPath(); ctx.moveTo(-17,-122); ctx.lineTo(17,-122); ctx.lineTo(24,-48); ctx.lineTo(-22,-48); ctx.closePath(); ctx.fill();
  ctx.shadowBlur=0; ctx.strokeStyle=rgba(C.cyan,0.9); ctx.lineWidth=1.5; ctx.stroke();
  ctx.strokeStyle='#9bb9be'; ctx.lineWidth=1; ctx.beginPath(); ctx.moveTo(2,-120); ctx.lineTo(2,-50); ctx.stroke();
  // 手臂（伸向控制台）
  ctx.strokeStyle='#e8f6f8'; ctx.lineWidth=6; ctx.beginPath(); ctx.moveTo(10,-112);
  if(pose==='console'){ ctx.lineTo(30,-86); ctx.lineTo(48,-84); } else { ctx.lineTo(16,-70); } ctx.stroke();
  // 头
  ctx.fillStyle='#0b1a20'; ctx.shadowColor=C.cyan; ctx.shadowBlur=12; ctx.beginPath(); ctx.arc(0,-138,14,0,7); ctx.fill();
  ctx.strokeStyle=C.cyan; ctx.lineWidth=2; ctx.stroke();
  // 护目镜一道光
  ctx.fillStyle=C.cyan; ctx.fillRect(4,-142,10,3);
  ctx.restore();
}

function building(ctx){
  // 上层：退休教授办公室（暗）
  ctx.fillStyle='#060c10'; ctx.fillRect(0,0,1920,CEIL-24);
  ctx.strokeStyle=C.line; ctx.lineWidth=2; ctx.strokeRect(-2,-2,1924,CEIL-22);
  for(let i=0;i<6;i++){ ctx.fillStyle='#0c171d'; ctx.fillRect(820+i*70,60,50,110); } // 书架
  ctx.fillStyle='#0c171d'; ctx.fillRect(1300,120,160,50); ctx.fillRect(1320,90,30,30);
  txt(ctx,'退休教授办公室（以后开放）',1500,150,16,rgba(C.sub,0.6));
  // 楼板
  ctx.fillStyle='#0d1c22'; ctx.fillRect(0,CEIL-24,1920,24); ctx.fillRect(0,FLOOR,1920,22);
  hazard(ctx,0,FLOOR+22,1920,6,C.cyan,0.12);
  // 下层：地下储藏室（暗）
  ctx.fillStyle='#050a0d'; ctx.fillRect(0,FLOOR+28,1920,260);
  for(let i=0;i<9;i++){ const x=420+i*130; ctx.strokeStyle='#14262d'; ctx.strokeRect(x,FLOOR+70,100,170); ctx.beginPath(); ctx.moveTo(x,FLOOR+130); ctx.lineTo(x+100,FLOOR+130); ctx.moveTo(x,FLOOR+190); ctx.lineTo(x+100,FLOOR+190); ctx.stroke();
    ctx.fillStyle='#0f1d23'; ctx.fillRect(x+10+(i*17)%50,FLOOR+100,24,30); ctx.fillRect(x+40,FLOOR+160,30,30); }
  ctx.fillStyle=rgba(C.gold,0.25); ctx.beginPath(); ctx.arc(1003,FLOOR+113,6,0,7); ctx.fill(); // 一枚硬币的微光
  txt(ctx,'地下储藏室 / 失物招领箱（以后开放）',420,FLOOR+270,16,rgba(C.sub,0.6));
  // 主层背墙面板
  ctx.fillStyle='#071116'; ctx.fillRect(0,CEIL,1920,FLOOR-CEIL);
  ctx.strokeStyle='#0e1f26'; ctx.lineWidth=1; for(let x=0;x<1920;x+=160){ ctx.strokeRect(x+6,CEIL+14,148,FLOOR-CEIL-28); }
  // 天花线槽与灯
  ctx.fillStyle='#0d1c22'; ctx.fillRect(0,CEIL,1920,14);
  for(let x=200;x<1920;x+=320){ ctx.fillStyle=rgba(C.ice,0.5); ctx.fillRect(x,CEIL+14,80,4);
    const g=ctx.createLinearGradient(0,CEIL+18,0,CEIL+220); g.addColorStop(0,rgba(C.ice,0.06)); g.addColorStop(1,rgba(C.ice,0));
    ctx.fillStyle=g; ctx.beginPath(); ctx.moveTo(x,CEIL+18); ctx.lineTo(x+80,CEIL+18); ctx.lineTo(x+150,CEIL+220); ctx.lineTo(x-70,CEIL+220); ctx.fill(); }
  // 楼梯（左）
  ctx.strokeStyle=C.dim; ctx.lineWidth=2; for(let i=0;i<10;i++){ ctx.beginPath(); ctx.moveTo(30+i*9,FLOOR-i*30); ctx.lineTo(70+i*9,FLOOR-i*30); ctx.stroke(); }
  // 地面反光
  const fg=ctx.createLinearGradient(0,FLOOR-40,0,FLOOR); fg.addColorStop(0,'rgba(0,0,0,0)'); fg.addColorStop(1,rgba(C.cyan,0.05)); ctx.fillStyle=fg; ctx.fillRect(0,FLOOR-40,1920,40);
}

function beamPipe(ctx,x1,x2,lit){
  ctx.fillStyle='#0b1a20'; ctx.fillRect(x1,BEAMY-14,x2-x1,28);
  ctx.strokeStyle=rgba(C.cyan,0.45); ctx.lineWidth=1.5; ctx.strokeRect(x1,BEAMY-14,x2-x1,28);
  for(let x=x1+40;x<x2;x+=90){ ctx.fillStyle='#132a32'; ctx.fillRect(x,BEAMY-20,10,40); }
  ctx.save(); ctx.globalCompositeOperation='lighter'; const g=ctx.createLinearGradient(x1,0,x2,0); g.addColorStop(0,rgba(C.cyan,0)); g.addColorStop(0.5,rgba(C.cyan,lit)); g.addColorStop(1,rgba(C.cyan,0));
  ctx.fillStyle=g; ctx.fillRect(x1,BEAMY-2,x2-x1,4); ctx.restore();
}
function quad(ctx,x){ ctx.fillStyle='#10242b'; ctx.strokeStyle=rgba(C.cyan,0.5); ctx.lineWidth=1.5; ctx.fillRect(x-26,BEAMY-60,52,120); ctx.strokeRect(x-26,BEAMY-60,52,120);
  ctx.fillStyle=rgba(C.cyan,0.8); ctx.shadowColor=C.cyan; ctx.shadowBlur=12; ctx.fillRect(x-18,BEAMY-50,36,6); ctx.fillRect(x-18,BEAMY+44,36,6); ctx.shadowBlur=0;
  ctx.fillStyle='#0b1a20'; ctx.fillRect(x-8,BEAMY+60,16,FLOOR-BEAMY-60); }

function injector(ctx){ ctx.fillStyle='#0c1b21'; ctx.strokeStyle=rgba(C.cyan,0.5); ctx.lineWidth=1.5;
  ctx.fillRect(150,BEAMY-110,190,220); ctx.strokeRect(150,BEAMY-110,190,220);
  for(let i=0;i<5;i++){ ctx.fillStyle=rgba(C.cyan,0.2+i*0.12); ctx.fillRect(170+i*32,BEAMY-80,20,160); }
  ctx.fillStyle='#0b1a20'; ctx.fillRect(190,BEAMY+110,110,FLOOR-BEAMY-110); txt(ctx,'注入器',245,BEAMY-124,18,C.sub,{align:'center'}); }

function detector(ctx,x){ // 侧剖探测器 + 墙上的探测屏
  ctx.fillStyle='#0c1b21'; ctx.strokeStyle=rgba(C.cyan,0.5); ctx.lineWidth=1.5;
  for(let i=0;i<5;i++){ const h=120+i*60; ctx.strokeRect(x+i*24,BEAMY-h/2,30,h); ctx.fillStyle=rgba(C.cyan,0.06+i*0.03); ctx.fillRect(x+i*24,BEAMY-h/2,30,h); }
  ctx.fillStyle='#0b1a20'; ctx.fillRect(x+20,BEAMY+180,110,FLOOR-BEAMY-180);
  // 墙上的大屏
  const sx=x-30, sy=CEIL+40, sw=260, sh=150; ctx.fillStyle='#03070a'; ctx.fillRect(sx,sy,sw,sh); ctx.strokeStyle=C.dim; ctx.strokeRect(sx,sy,sw,sh);
  event(ctx,sx+sw/2,sy+sh/2,sh*0.42,'precise',3);
  txt(ctx,'探测屏',x+70,BEAMY+230+0,18,C.sub,{align:'center'}); }

function consoleDesk(ctx,x){ // 控制台
  ctx.fillStyle='#0d1d23'; ctx.strokeStyle=rgba(C.cyan,0.5); ctx.lineWidth=1.5;
  ctx.beginPath(); ctx.moveTo(x,FLOOR); ctx.lineTo(x,FLOOR-90); ctx.lineTo(x+150,FLOOR-110); ctx.lineTo(x+150,FLOOR); ctx.closePath(); ctx.fill(); ctx.stroke();
  ctx.save(); ctx.translate(x+70,FLOOR-140); ctx.rotate(-0.15); ctx.fillStyle='#03080b'; ctx.fillRect(-50,-34,100,64); ctx.strokeStyle=rgba(C.cyan,0.8); ctx.strokeRect(-50,-34,100,64);
  ctx.fillStyle=rgba(C.cyan,0.8); for(let i=0;i<5;i++) ctx.fillRect(-40,-24+i*11,20+((i*37)%60),4); ctx.restore();
  glow(ctx,x+70,FLOOR-140,90,C.cyan,0.15); }

function terminal(ctx,x){ ctx.fillStyle='#0d1d23'; ctx.strokeStyle=rgba(C.gold,0.5); ctx.lineWidth=1.5; ctx.fillRect(x,FLOOR-170,70,170); ctx.strokeRect(x,FLOOR-170,70,170);
  ctx.fillStyle=rgba(C.gold,0.25); ctx.fillRect(x+10,FLOOR-155,50,40); txt(ctx,'$',x+35,FLOOR-125,22,C.gold,{align:'center',mono:true}); txt(ctx,'采购终端',x+35,FLOOR-184,16,C.sub,{align:'center'}); }

function prompt(ctx,x,y,key,label){ ctx.save(); ctx.fillStyle='rgba(4,10,13,0.85)'; ctx.strokeStyle=rgba(C.cyan,0.6); ctx.beginPath(); ctx.roundRect(x-80,y-24,160,36,4); ctx.fill(); ctx.stroke(); ctx.restore();
  ctx.strokeStyle=C.cyan; ctx.strokeRect(x-72,y-17,44,22); txt(ctx,key,x-50,y,13,C.cyan,{align:'center'}); txt(ctx,label,x-18,y,16,C.text); }

function worldTag(ctx,x,y,lines){ ctx.save(); ctx.strokeStyle=rgba(C.cyan,0.5); ctx.beginPath(); ctx.moveTo(x,y); ctx.lineTo(x+40,y-40); ctx.lineTo(x+170,y-40); ctx.stroke(); ctx.restore();
  lines.forEach((l,i)=>txt(ctx,l[0],x+46,y-48-(lines.length-1-i)*26,l[1],l[2]||C.text,{mono:true,glow:l[3]||0})); }

function topBar(ctx,cap){ ctx.fillStyle='rgba(4,8,11,0.75)'; ctx.fillRect(0,0,1920,56);
  txt(ctx,'BEAMLINE',40,38,20,C.text,{ls:8,w:300}); txt(ctx,'考核 2 / 3',600,38,20,C.text); txt(ctx,'累计 8,420 / 12,000',760,38,20,C.text,{mono:true});
  txt(ctx,'剩余实验 2',1060,38,20,C.text); txt(ctx,cap,1880,38,15,C.sub,{align:'right'}); }

function labScene(ctx,opt,zoom){
  building(ctx);
  injector(ctx); detector(ctx,1600);
  terminal(ctx,430);
  if(opt==='tank'){
    beamPipe(ctx,340,860,0.5); beamPipe(ctx,1260,1600,0.3); quad(ctx,720); quad(ctx,1400);
    // 立式玻璃舱：从地到顶
    const cx=1060,w=380,top=CEIL+40,bot=FLOOR-20; chamberTankSide(ctx,cx,w,top,bot,{v:0.5,d:0.3,seed:3});
    consoleDesk(ctx,560); figure(ctx,560+30,FLOOR,150,1,'console');
    if(!zoom){ worldTag(ctx,cx+w/2+10,BEAMY-120,[['E7',30,C.ice,10],['3,880 RP',20],['丢失 18.4%',16,C.orange]]);
    prompt(ctx,590,FLOOR-180,'空格','继续加速'); }
  }
  if(opt==='capsule'){
    beamPipe(ctx,340,820,0.5); beamPipe(ctx,1380,1600,0.3); quad(ctx,700);
    chamberCapsuleSide(ctx,1100,BEAMY,560,300,{v:0.5,d:0.3,seed:21});
    consoleDesk(ctx,880); figure(ctx,880+30,FLOOR,150,1,'console');
    worldTag(ctx,1300,BEAMY-160,[['E7',30,C.ice,10],['3,880 RP',20],['丢失 18.4%',16,C.orange]]);
    prompt(ctx,910,FLOOR-180,'空格','继续加速');
  }
  if(opt==='porthole'){
    // 背墙上的圆形观察窗，墙后是环形加速器隧道
    beamPipe(ctx,340,1600,0.45); quad(ctx,700); quad(ctx,1420);
    portholeWall(ctx,1060,450,230,{v:0.5,d:0.3,seed:9});
    beamPipe(ctx,820,1300,0.6);
    consoleDesk(ctx,880); figure(ctx,880+30,FLOOR,150,1,'console');
    worldTag(ctx,1300,300,[['E7',30,C.ice,10],['3,880 RP',20],['丢失 18.4%',16,C.orange]]);
    prompt(ctx,910,FLOOR-180,'空格','继续加速');
  }
}

function chamberTankSide(ctx,cx,w,top,bot,p){
  const x=cx-w/2, h=bot-top;
  // 底座与顶盖
  ctx.fillStyle='#0c1b21'; ctx.strokeStyle=rgba(C.cyan,0.5); ctx.lineWidth=1.5;
  ctx.fillRect(x-30,bot-10,w+60,30); ctx.strokeRect(x-30,bot-10,w+60,30); ctx.fillRect(x-30,top-30,w+60,40); ctx.strokeRect(x-30,top-30,w+60,40);
  const lit=Math.round(2+(p.v||0)*5); for(let i=0;i<8;i++){ ctx.save(); ctx.fillStyle=i<lit?rgba(C.cyan,0.85):'#14303a'; if(i<lit){ctx.shadowColor=C.cyan;ctx.shadowBlur=12;}
    ctx.fillRect(x-14+i*(w+28)/8,top-20,(w+28)/8-10,18); ctx.fillRect(x-14+i*(w+28)/8,bot-2,(w+28)/8-10,12); ctx.restore(); }
  ctx.save(); ctx.beginPath(); ctx.roundRect(x,top+10,w,h-20,40); ctx.clip(); drawBeam(ctx,cx,BEAMY,w*0.5,p);
  const gl=ctx.createLinearGradient(x,0,x+w,0); gl.addColorStop(0,'rgba(200,250,255,0.10)'); gl.addColorStop(0.1,'rgba(200,250,255,0.02)'); gl.addColorStop(0.16,'rgba(200,250,255,0.08)'); gl.addColorStop(0.22,'rgba(0,0,0,0)'); gl.addColorStop(1,'rgba(200,250,255,0.06)');
  ctx.fillStyle=gl; ctx.fillRect(x,top,w,h); ctx.restore();
  ctx.strokeStyle=rgba(C.cyan,0.6); ctx.lineWidth=2; ctx.beginPath(); ctx.roundRect(x,top+10,w,h-20,40); ctx.stroke();
}
function chamberCapsuleSide(ctx,cx,cy,w,h,p){
  const x=cx-w/2,y=cy-h/2;
  ctx.fillStyle='#0b1a20'; ctx.fillRect(cx-140,cy+h/2,40,FLOOR-cy-h/2); ctx.fillRect(cx+100,cy+h/2,40,FLOOR-cy-h/2);
  ctx.save(); ctx.beginPath(); ctx.roundRect(x,y,w,h,h/2); ctx.clip(); drawBeam(ctx,cx,cy,h*0.48,p);
  const gl=ctx.createLinearGradient(0,y,0,y+h); gl.addColorStop(0,'rgba(200,250,255,0.10)'); gl.addColorStop(0.15,'rgba(0,0,0,0)'); gl.addColorStop(1,'rgba(200,250,255,0.05)'); ctx.fillStyle=gl; ctx.fillRect(x,y,w,h); ctx.restore();
  ctx.strokeStyle=rgba(C.cyan,0.6); ctx.lineWidth=2; ctx.beginPath(); ctx.roundRect(x,y,w,h,h/2); ctx.stroke();
  const lit=Math.round(1+(p.v||0)*4); for(let i=0;i<6;i++){ const bx=x+h*0.45+i*(w-h*0.9)/5; ctx.save(); ctx.fillStyle=i<lit?rgba(C.cyan,0.8):'#14303a'; if(i<lit){ctx.shadowColor=C.cyan;ctx.shadowBlur=14;}
    ctx.fillRect(bx-7,y-24,14,20); ctx.fillRect(bx-7,y+h+4,14,20); ctx.restore(); }
}
function portholeWall(ctx,cx,cy,R,p){
  // 墙后隧道里的外环（透视为一条弧带）
  ctx.save(); ctx.beginPath(); ctx.arc(cx,cy,R,0,7); ctx.clip(); drawBeam(ctx,cx,cy,R,p);
  ctx.strokeStyle=rgba(C.cyan,0.2); ctx.lineWidth=18; ctx.beginPath(); ctx.ellipse(cx,cy+R*0.55,R*1.4,R*0.25,0,Math.PI,0); ctx.stroke(); ctx.restore();
  ctx.strokeStyle='#183038'; ctx.lineWidth=26; ctx.beginPath(); ctx.arc(cx,cy,R+14,0,7); ctx.stroke();
  ctx.strokeStyle=rgba(C.cyan,0.6); ctx.lineWidth=2; ctx.beginPath(); ctx.arc(cx,cy,R,0,7); ctx.stroke();
  for(let i=0;i<24;i++){ const a=i/24*Math.PI*2; ctx.fillStyle='#2f535a'; ctx.beginPath(); ctx.arc(cx+Math.cos(a)*(R+14),cy+Math.sin(a)*(R+14),3,0,7); ctx.fill(); }
}

function labMock(n){
  const cv=document.getElementById('c'), ctx=cv.getContext('2d'); ctx.fillStyle=C.bg; ctx.fillRect(0,0,1920,1080);
  if(n===6){ labScene(ctx,'tank'); topBar(ctx,'场景方案 1 · 立式玻璃舱（落地，顶天立地）'); }
  if(n===7){ labScene(ctx,'capsule'); topBar(ctx,'场景方案 2 · 横向胶囊舱（串在束流线上）'); }
  if(n===8){ labScene(ctx,'porthole'); topBar(ctx,'场景方案 3 · 墙上圆形观察窗（墙后是环形隧道）'); }
  if(n===9){ // 方案1 推近
    ctx.save(); ctx.translate(960,520); ctx.scale(1.55,1.55); ctx.translate(-1060,-BEAMY); labScene(ctx,'tank',true); ctx.restore();
    const gL=ctx.createLinearGradient(0,0,560,0); gL.addColorStop(0,'rgba(4,8,11,0.96)'); gL.addColorStop(0.8,'rgba(4,8,11,0.93)'); gL.addColorStop(1,'rgba(4,8,11,0)'); ctx.fillStyle=gL; ctx.fillRect(0,0,560,1080);
    const gR=ctx.createLinearGradient(1360,0,1920,0); gR.addColorStop(0,'rgba(4,8,11,0)'); gR.addColorStop(0.2,'rgba(4,8,11,0.93)'); gR.addColorStop(1,'rgba(4,8,11,0.96)'); ctx.fillStyle=gR; ctx.fillRect(1360,0,560,1080);
    ctx.fillStyle='rgba(4,8,11,0.9)'; ctx.fillRect(0,0,1920,96); ctx.fillRect(0,920,1920,160);
    hud(ctx,{stage:2,left:2,seed:'7F3A-19C2',total:'8,420',line:'12,000',E:7,gev:'142',value:'3,880',prob:[7.2,47.6,13.6,13.2,18.4],charge:3,
      log:[[1,'加速成功  E6→E7','+1'],[0,'完美同步  E4→E6','+2'],[3,'射频失谐  E5→E4','-1'],[1,'加速成功  E4→E5','+1'],[2,'保持稳定  E4','0'],[1,'加速成功  E3→E4','+1']],
      curve:[[0,410],[40,404],[90,396],[127,380],[180,372],[230,352],[253,338]],caption:'在控制台按开始 → 镜头平滑推近观测舱，仪表从两侧滑入（方案 1 示意）'});
  }
}
