// 多色调色板方案（#10 以后的图使用）
const RAMP = [['#5b5cff',0],['#3f9dff',0.22],['#45e8ff',0.45],['#5dffc0',0.7],['#f2fff6',1]]; // 能级：靛→天蓝→青→薄荷→白
function ramp(v){ v=Math.max(0,Math.min(1,v)); for(let i=1;i<RAMP.length;i++){ if(v<=RAMP[i][1]){ const t=(v-RAMP[i-1][1])/(RAMP[i][1]-RAMP[i-1][1]); return mix(RAMP[i-1][0],RAMP[i][0],t);} } return RAMP[RAMP.length-1][0]; }
function usePalette2(){
  Object.assign(C,{ bg:'#070913', panel:'#0d1222', line:'#1e2740', dim:'#3a4a6e', cyan:'#45e8ff', ice:'#c9f7ff', white:'#f6f8ff',
    red:'#ff4d6a', orange:'#ff8f3d', gold:'#ffc65a', text:'#e8ecf6', sub:'#8590ad', lock:'#b77bff', pink:'#ff7ad9', mint:'#5dffc0' });
  C.ramp = ramp;
  OUT[0][1]=C.white; OUT[1][1]='#45e8ff'; OUT[2][1]='#5f6b8f'; OUT[3][1]=C.orange; OUT[4][1]=C.red;
}
function lightPool(ctx,x,col,a,w){ const g=ctx.createRadialGradient(x,FLOOR,0,x,FLOOR,w); g.addColorStop(0,rgba(col,a)); g.addColorStop(1,rgba(col,0));
  ctx.fillStyle=g; ctx.fillRect(x-w,CEIL,w*2,FLOOR-CEIL+30); }
function building(ctx){ // 覆盖：带分区环境色
  // 上层：退休教授办公室，暖褐台灯
  ctx.fillStyle='#0d0b10'; ctx.fillRect(0,0,1920,CEIL-24);
  const lg=ctx.createRadialGradient(1380,110,0,1380,110,420); lg.addColorStop(0,'rgba(255,170,90,0.16)'); lg.addColorStop(1,'rgba(255,170,90,0)'); ctx.fillStyle=lg; ctx.fillRect(900,0,1020,CEIL-24);
  for(let i=0;i<6;i++){ ctx.fillStyle=['#2a1d1a','#1c2230','#2b2418','#1d1a2a','#272019','#1a2422'][i]; ctx.fillRect(820+i*70,60,50,110); }
  ctx.fillStyle='#2a1f19'; ctx.fillRect(1300,120,160,50); ctx.fillStyle='#ffb36a'; ctx.fillRect(1330,96,14,8); glow(ctx,1337,100,40,'#ffb36a',0.5);
  txt(ctx,'退休教授办公室（以后开放）',1500,150,16,'rgba(255,190,140,0.55)');
  // 楼板
  ctx.fillStyle='#151a2b'; ctx.fillRect(0,CEIL-24,1920,24); ctx.fillRect(0,FLOOR,1920,22);
  hazard(ctx,0,FLOOR+22,1920,6,C.gold,0.18);
  // 地下储藏室：暗绿荧光
  ctx.fillStyle='#060d0b'; ctx.fillRect(0,FLOOR+28,1920,260);
  const sg=ctx.createRadialGradient(1000,FLOOR+150,0,1000,FLOOR+150,700); sg.addColorStop(0,'rgba(80,255,170,0.07)'); sg.addColorStop(1,'rgba(80,255,170,0)'); ctx.fillStyle=sg; ctx.fillRect(0,FLOOR+28,1920,260);
  const boxes=['#3a2a4a','#4a3a22','#22384a','#4a2230','#2a4a3a'];
  for(let i=0;i<9;i++){ const x=420+i*130; ctx.strokeStyle='#1b2e2a'; ctx.strokeRect(x,FLOOR+70,100,170); ctx.beginPath(); ctx.moveTo(x,FLOOR+130); ctx.lineTo(x+100,FLOOR+130); ctx.moveTo(x,FLOOR+190); ctx.lineTo(x+100,FLOOR+190); ctx.stroke();
    ctx.fillStyle=boxes[i%5]; ctx.fillRect(x+10+(i*17)%50,FLOOR+100,24,30); ctx.fillStyle=boxes[(i+2)%5]; ctx.fillRect(x+40,FLOOR+160,30,30); }
  glow(ctx,1003,FLOOR+113,26,C.gold,0.6); ctx.fillStyle=C.gold; ctx.beginPath(); ctx.arc(1003,FLOOR+113,5,0,7); ctx.fill();
  txt(ctx,'地下储藏室 / 失物招领箱（以后开放）',420,FLOOR+270,16,'rgba(140,230,190,0.5)');
  // 主层：冷蓝背墙，左侧偏靛、右侧探测区偏紫
  const wg=ctx.createLinearGradient(0,0,1920,0); wg.addColorStop(0,'#0a0f22'); wg.addColorStop(0.5,'#08131c'); wg.addColorStop(1,'#130c22');
  ctx.fillStyle=wg; ctx.fillRect(0,CEIL,1920,FLOOR-CEIL);
  ctx.strokeStyle='rgba(120,150,220,0.08)'; ctx.lineWidth=1; for(let x=0;x<1920;x+=160){ ctx.strokeRect(x+6,CEIL+14,148,FLOOR-CEIL-28); }
  ctx.fillStyle='#141b30'; ctx.fillRect(0,CEIL,1920,14);
  // 线槽里的彩色电缆
  [['#ff4d6a',CEIL+20],['#45e8ff',CEIL+26],['#ffc65a',CEIL+32]].forEach(([c,y])=>{ ctx.strokeStyle=rgba(c,0.45); ctx.lineWidth=2; ctx.beginPath(); ctx.moveTo(0,y); for(let x=0;x<=1920;x+=240) ctx.quadraticCurveTo(x+120,y+10,x+240,y); ctx.stroke(); });
  for(let x=200;x<1920;x+=320){ ctx.fillStyle=rgba(C.ice,0.5); ctx.fillRect(x,CEIL+14,80,4); }
  // 分区光池
  lightPool(ctx,465,'#ffc65a',0.13,260);   // 采购终端 暖金
  lightPool(ctx,1100,'#45e8ff',0.10,420);  // 胶囊舱 青
  lightPool(ctx,1680,'#b77bff',0.13,320);  // 探测区 紫
  lightPool(ctx,245,'#5b5cff',0.10,240);   // 注入器 靛
  ctx.strokeStyle='#4b5a80'; ctx.lineWidth=2; for(let i=0;i<10;i++){ ctx.beginPath(); ctx.moveTo(30+i*9,FLOOR-i*30); ctx.lineTo(70+i*9,FLOOR-i*30); ctx.stroke(); }
  // 地面反光
  const fg=ctx.createLinearGradient(0,FLOOR-40,0,FLOOR); fg.addColorStop(0,'rgba(0,0,0,0)'); fg.addColorStop(1,'rgba(120,160,255,0.06)'); ctx.fillStyle=fg; ctx.fillRect(0,FLOOR-40,1920,40);
}
function quad(ctx,x){ // 覆盖：四极铁漆成砖红，二极铁蓝（真实加速器常见涂装）
  ctx.fillStyle='#5a2a2e'; ctx.strokeStyle='#ff8a7a'; ctx.lineWidth=1.2; ctx.fillRect(x-26,BEAMY-60,52,120); ctx.strokeRect(x-26,BEAMY-60,52,120);
  ctx.fillStyle='#c9504f'; ctx.fillRect(x-20,BEAMY-52,40,22); ctx.fillRect(x-20,BEAMY+30,40,22);
  ctx.fillStyle='#1b2236'; ctx.fillRect(x-8,BEAMY+60,16,FLOOR-BEAMY-60); }
function dipole(ctx,x){ ctx.fillStyle='#1d3a7a'; ctx.strokeStyle='#7aa8ff'; ctx.lineWidth=1.2; ctx.fillRect(x-40,BEAMY-46,80,92); ctx.strokeRect(x-40,BEAMY-46,80,92);
  ctx.fillStyle='#2f5fc4'; ctx.fillRect(x-34,BEAMY-40,68,18); ctx.fillRect(x-34,BEAMY+22,68,18); ctx.fillStyle='#1b2236'; ctx.fillRect(x-10,BEAMY+46,20,FLOOR-BEAMY-46); }
function injector(ctx){ ctx.fillStyle='#14233a'; ctx.strokeStyle='#7f8cff'; ctx.lineWidth=1.5; ctx.fillRect(150,BEAMY-110,190,220); ctx.strokeRect(150,BEAMY-110,190,220);
  for(let i=0;i<5;i++){ ctx.fillStyle=rgba(ramp(i/8),0.35+i*0.12); ctx.fillRect(170+i*32,BEAMY-80,20,160); }
  ctx.fillStyle='#1b2236'; ctx.fillRect(190,BEAMY+110,110,FLOOR-BEAMY-110); txt(ctx,'注入器',245,BEAMY-124,18,C.sub,{align:'center'}); }
function detector(ctx,x){ const cols=['#3a2a6a','#4a2f80','#5a3896','#6a40ad','#7a48c4'];
  for(let i=0;i<5;i++){ const h=120+i*60; ctx.fillStyle=cols[i]; ctx.fillRect(x+i*24,BEAMY-h/2,30,h); ctx.strokeStyle='#c9a2ff'; ctx.lineWidth=1; ctx.strokeRect(x+i*24,BEAMY-h/2,30,h); }
  ctx.fillStyle='#1b2236'; ctx.fillRect(x+20,BEAMY+180,110,FLOOR-BEAMY-180);
  const sx=x-30, sy=CEIL+40, sw=260, sh=150; ctx.fillStyle='#05060c'; ctx.fillRect(sx,sy,sw,sh); ctx.strokeStyle='#6a58a8'; ctx.strokeRect(sx,sy,sw,sh);
  event(ctx,sx+sw/2,sy+sh/2,sh*0.42,'burst',3); txt(ctx,'探测屏',x+70,BEAMY+230,18,C.sub,{align:'center'}); }
function terminal(ctx,x){ ctx.fillStyle='#2a2010'; ctx.strokeStyle=C.gold; ctx.lineWidth=1.5; ctx.fillRect(x,FLOOR-170,70,170); ctx.strokeRect(x,FLOOR-170,70,170);
  ctx.fillStyle=rgba(C.gold,0.35); ctx.fillRect(x+10,FLOOR-155,50,40); glow(ctx,x+35,FLOOR-135,60,C.gold,0.25); txt(ctx,'$',x+35,FLOOR-125,22,'#fff0c8',{align:'center',mono:true});
  txt(ctx,'采购终端',x+35,FLOOR-184,16,'#e8cf9a',{align:'center'}); }
function consoleDesk(ctx,x){ ctx.fillStyle='#1a2236'; ctx.strokeStyle='#8aa0d8'; ctx.lineWidth=1.5;
  ctx.beginPath(); ctx.moveTo(x,FLOOR); ctx.lineTo(x,FLOOR-90); ctx.lineTo(x+150,FLOOR-110); ctx.lineTo(x+150,FLOOR); ctx.closePath(); ctx.fill(); ctx.stroke();
  [['#ff4d6a',x+20],['#ffc65a',x+40],['#5dffc0',x+60]].forEach(([c,bx])=>{ ctx.fillStyle=c; ctx.fillRect(bx,FLOOR-80-(bx-x)*0.13,10,6); });
  ctx.save(); ctx.translate(x+70,FLOOR-140); ctx.rotate(-0.15); ctx.fillStyle='#05070e'; ctx.fillRect(-50,-34,100,64); ctx.strokeStyle=C.cyan; ctx.strokeRect(-50,-34,100,64);
  const lc=[C.cyan,C.mint,C.gold,C.cyan,C.red]; for(let i=0;i<5;i++){ ctx.fillStyle=rgba(lc[i],0.85); ctx.fillRect(-40,-24+i*11,20+((i*37)%60),4);} ctx.restore();
  glow(ctx,x+70,FLOOR-140,90,C.cyan,0.15); }
function figure2(ctx,x,y,h){ figure(ctx,x,y,h,1,'console'); ctx.fillStyle='#ff4d6a'; ctx.fillRect(x+4*h/150,y-118*h/150,8*h/150,6*h/150); } // 工牌一点红

function sceneP2(n){
  usePalette2(); const cv=document.getElementById('c'), ctx=cv.getContext('2d'); ctx.fillStyle=C.bg; ctx.fillRect(0,0,1920,1080);
  if(n===10||n===12){
    const state = n===10? {v:0.62,d:0.3,seed:21} : {v:0.8,d:0,lock:true,seed:22};
    const draw=(zoom)=>{ building(ctx); injector(ctx); detector(ctx,1600); terminal(ctx,430);
      beamPipe(ctx,340,820,0.5); beamPipe(ctx,1380,1600,0.3); dipole(ctx,560); quad(ctx,720); quad(ctx,1490);
      chamberCapsuleSide(ctx,1100,BEAMY,560,300,state); consoleDesk(ctx,880); figure2(ctx,910,FLOOR,150);
      if(!zoom){ worldTag(ctx,1300,BEAMY-160,[['E8',30,ramp(0.62),12],['6,240 RP',20],['丢失 18.4%',16,C.orange]]); prompt(ctx,910,FLOOR-180,'空格','继续加速'); } };
    if(n===10){ draw(false); topBar(ctx,'多色方案 · 侧视控制室（E8 常态）'); }
    else { ctx.save(); ctx.translate(960,520); ctx.scale(1.55,1.55); ctx.translate(-1100,-BEAMY); draw(true); ctx.restore();
      const gL=ctx.createLinearGradient(0,0,560,0); gL.addColorStop(0,'rgba(7,9,19,0.96)'); gL.addColorStop(0.8,'rgba(7,9,19,0.93)'); gL.addColorStop(1,'rgba(7,9,19,0)'); ctx.fillStyle=gL; ctx.fillRect(0,0,560,1080);
      const gR=ctx.createLinearGradient(1360,0,1920,0); gR.addColorStop(0,'rgba(7,9,19,0)'); gR.addColorStop(0.2,'rgba(7,9,19,0.93)'); gR.addColorStop(1,'rgba(7,9,19,0.96)'); ctx.fillStyle=gR; ctx.fillRect(1360,0,560,1080);
      ctx.fillStyle='rgba(7,9,19,0.9)'; ctx.fillRect(0,0,1920,96); ctx.fillRect(0,920,1920,160);
      txt(ctx,'PHASE LOCK',960,140,22,C.lock,{align:'center',ls:12,glow:18});
      hud(ctx,{stage:2,left:2,seed:'7F3A-19C2',total:'8,420',line:'12,000',E:11,gev:'352',value:'18,900',prob:[9.0,64.0,15.0,12.0,0],charge:6,lock:true,lockLeft:3,
        log:[[0,'完美同步  E9→E11','+2'],[1,'加速成功  E8→E9','+1'],[1,'加速成功  E7→E8','+1'],[1,'加速成功  E6→E7','+1'],[2,'保持稳定  E6','0'],[1,'加速成功  E5→E6','+1']],
        curve:[[0,410],[40,404],[90,396],[127,380],[180,372],[230,352],[253,338]],caption:'多色方案 · 控制台推近 · 锁相（紫）'}); }
  }
  if(n===11){
    txt(ctx,'多色方案 · 色板与能级色阶',60,80,30,C.text,{w:300}); txt(ctx,'每种颜色只代表一件事：能级=冷色渐变；危险=珊瑚红/橙；锁相=电紫；钱与饰品=琥珀金；离谱=金+粉',60,118,18,C.sub);
    const Es=[1,3,5,7,9,11,13]; Es.forEach((e,i)=>{ const v=(e-1)/12, X=170+i*260, Y=330; ctx.save(); ctx.beginPath(); ctx.arc(X,Y,110,0,7); ctx.clip(); drawBeam(ctx,X,Y,110,{v,d:0.05,seed:30+i}); ctx.restore();
      ctx.strokeStyle=rgba(ramp(v),0.7); ctx.lineWidth=2; ctx.beginPath(); ctx.arc(X,Y,110,0,7); ctx.stroke(); txt(ctx,'E'+e,X,Y+150,24,ramp(v),{align:'center',mono:true,glow:10}); });
    const g=ctx.createLinearGradient(60,0,1860,0); RAMP.forEach(([c,t])=>g.addColorStop(t,c)); ctx.fillStyle=g; ctx.fillRect(60,520,1800,14);
    const st=[['锁相',{v:0.75,lock:true,seed:5},C.lock],['超负荷',{v:0.7,d:0.85,seed:4},C.red],['离谱',{v:0.7,d:0.3,weird:1,seed:6},C.gold]];
    st.forEach((q,i)=>{ const X=230+i*420, Y=760; ctx.save(); ctx.beginPath(); ctx.arc(X,Y,150,0,7); ctx.clip(); drawBeam(ctx,X,Y,150,q[1]); ctx.restore();
      ctx.strokeStyle=rgba(q[2],0.7); ctx.lineWidth=2; ctx.beginPath(); ctx.arc(X,Y,150,0,7); ctx.stroke(); txt(ctx,q[0],X,Y+190,24,q[2],{align:'center',w:500}); });
    const sw=[['背景','#070913'],['面板','#0d1222'],['文字','#e8ecf6'],['次要','#8590ad'],['能级','#45e8ff'],['薄荷','#5dffc0'],['锁相','#b77bff'],['危险','#ff4d6a'],['失谐','#ff8f3d'],['金/钱','#ffc65a'],['离谱粉','#ff7ad9'],['二极铁','#2f5fc4'],['四极铁','#c9504f']];
    sw.forEach(([n2,c],i)=>{ const X=1460+(i%3)*140, Y=600+Math.floor(i/3)*90; ctx.fillStyle=c; ctx.fillRect(X,Y,50,50); ctx.strokeStyle='#2a3350'; ctx.strokeRect(X,Y,50,50);
      txt(ctx,n2,X+58,Y+22,15,C.text); txt(ctx,c,X+58,Y+44,13,C.sub,{mono:true}); });
  }
}
