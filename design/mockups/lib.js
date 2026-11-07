// 束流 美术概念图：程序化绘制（与 Godot 着色器同一套参数思路）
const C = { bg:'#04080b', panel:'#08131a', line:'#17323a', dim:'#2c5860', cyan:'#7ff3ff', ice:'#c8fbff', white:'#f2ffff',
  red:'#ff4a33', orange:'#ff9a3c', gold:'#ffd27a', text:'#d4eef0', sub:'#6f979c' };
const FONT = "'Microsoft YaHei UI','Microsoft YaHei','Segoe UI',sans-serif";
const MONO = "'Consolas','Cascadia Mono',monospace";

function rng(seed){ return function(){ seed|=0; seed=seed+0x6D2B79F5|0; let t=Math.imul(seed^seed>>>15,1|seed);
  t=t+Math.imul(t^t>>>7,61|t)^t; return ((t^t>>>14)>>>0)/4294967296; }; }
function rgba(hex,a){ const n=parseInt(hex.slice(1),16); return `rgba(${n>>16},${n>>8&255},${n&255},${a})`; }
function mix(h1,h2,t){ const a=parseInt(h1.slice(1),16), b=parseInt(h2.slice(1),16);
  const c=(s)=>Math.round(((a>>s)&255)*(1-t)+((b>>s)&255)*t); return '#'+((1<<24)+(c(16)<<16)+(c(8)<<8)+c(0)).toString(16).slice(1); }
function glow(ctx,x,y,r,col,a){ ctx.save(); ctx.globalCompositeOperation='lighter';
  const g=ctx.createRadialGradient(x,y,0,x,y,r); g.addColorStop(0,rgba(col,a)); g.addColorStop(0.3,rgba(col,a*0.32));
  g.addColorStop(1,rgba(col,0)); ctx.fillStyle=g; ctx.beginPath(); ctx.arc(x,y,r,0,Math.PI*2); ctx.fill(); ctx.restore(); }
function txt(ctx,s,x,y,size,col,opt={}){ ctx.save(); ctx.font=`${opt.w||400} ${size}px ${opt.mono?MONO:FONT}`;
  ctx.fillStyle=col; ctx.textAlign=opt.align||'left'; ctx.textBaseline=opt.base||'alphabetic';
  if(opt.ls){ ctx.letterSpacing=opt.ls+'px'; } if(opt.glow){ ctx.shadowColor=col; ctx.shadowBlur=opt.glow; }
  ctx.fillText(s,x,y); const w=ctx.measureText(s).width; ctx.restore(); return w; }
function ell(cx,cy,rx,ry,rot,a){ const c=Math.cos(rot), s=Math.sin(rot), x=rx*Math.cos(a), y=ry*Math.sin(a);
  return [cx+x*c-y*s, cy+x*s+y*c, Math.sin(a)]; }

// p: v 价值0..1, d 危险0..1, lock, weird 0..1, style 'normal'|'precise', seed
function drawBeam(ctx,cx,cy,R,p){
  const r=rng(p.seed||7), v=p.v||0, d=p.d||0, lock=!!p.lock, weird=p.weird||0, precise=p.style==='precise';
  const LK = C.lock||C.white; const base = lock ? LK : (C.ramp?C.ramp(v):C.cyan);
  // 背景内腔
  const bg=ctx.createRadialGradient(cx,cy,0,cx,cy,R*1.4); bg.addColorStop(0,rgba(mix(C.in0||'#06161c',C.red,d*0.18),1)); bg.addColorStop(1,C.in1||'#020507');
  ctx.fillStyle=bg; ctx.fillRect(cx-R*2,cy-R*2,R*4,R*4);
  // 背景细网格
  ctx.save(); ctx.strokeStyle=rgba(C.cyan,0.05); ctx.lineWidth=1;
  for(let x=-R*2;x<=R*2;x+=R/8){ ctx.beginPath(); ctx.moveTo(cx+x,cy-R*2); ctx.lineTo(cx+x,cy+R*2); ctx.stroke(); }
  for(let y=-R*2;y<=R*2;y+=R/8){ ctx.beginPath(); ctx.moveTo(cx-R*2,cy+y); ctx.lineTo(cx+R*2,cy+y); ctx.stroke(); }
  ctx.restore();
  // 锁相：六边形磁场网格
  if(lock){ ctx.save(); ctx.strokeStyle=rgba(C.lock?LK:C.ice,0.2); ctx.lineWidth=1.2; const s=R/7;
    for(let q=-10;q<=10;q++) for(let k=-10;k<=10;k++){ const hx=cx+s*1.5*q, hy=cy+s*Math.sqrt(3)*(k+(q&1?0.5:0));
      if(Math.hypot(hx-cx,hy-cy)>R*1.05) continue; ctx.beginPath();
      for(let i=0;i<=6;i++){ const a=Math.PI/3*i; const px=hx+s*Math.cos(a), py=hy+s*Math.sin(a); i?ctx.lineTo(px,py):ctx.moveTo(px,py);} ctx.stroke(); }
    ctx.restore();
    for(let i=1;i<=4;i++){ ctx.save(); ctx.strokeStyle=rgba(LK,0.55/i); ctx.lineWidth=3/i+0.6; ctx.beginPath(); ctx.arc(cx,cy,R*(0.2+i*0.19),0,7); ctx.stroke(); ctx.restore(); }
  }
  const off = d*R*0.07; const ox=cx+off*(r()-0.3), oy=cy+off*(r()-0.6);
  // 危险：束晕杂散光丝
  const wisps=Math.round(d*d*70);
  ctx.save(); ctx.globalCompositeOperation='lighter';
  for(let i=0;i<wisps;i++){ const a=r()*Math.PI*2, L=R*(0.35+r()*0.75); const col=r()<0.5?C.red:C.orange;
    ctx.strokeStyle=rgba(col,0.08+r()*0.25); ctx.lineWidth=0.6+r()*1.6; ctx.beginPath(); ctx.moveTo(ox+Math.cos(a)*R*0.1,oy+Math.sin(a)*R*0.1);
    ctx.bezierCurveTo(ox+Math.cos(a+0.6*(r()-0.5))*L*0.5, oy+Math.sin(a+0.8*(r()-0.5))*L*0.5, ox+Math.cos(a+(r()-0.5))*L*0.8, oy+Math.sin(a+(r()-0.5))*L*0.8, ox+Math.cos(a+(r()-0.5)*1.4)*L, oy+Math.sin(a+(r()-0.5)*1.4)*L); ctx.stroke(); }
  ctx.restore();
  if(d>0.4) glow(ctx,ox,oy,R*1.0,C.red,0.12*d);
  // 环与束团
  const n = lock?6:(1+Math.round(v*5));
  for(let i=0;i<n;i++){
    const rx=R*(0.3+0.115*i), ry=rx*(precise||lock?0.32:0.22+0.14*r()), rot= precise||lock ? (Math.PI/n)*i : i*0.7+r()*0.6;
    const ringCol = mix(base, C.orange, Math.max(0,(d-0.45)*1.6)*(i/(n||1)));
    ctx.save(); ctx.strokeStyle=rgba(ringCol,Math.min(1,(0.18+v*0.25)*(C.lineBoost||1))); ctx.lineWidth=(precise?0.9:1.3)*(C.lineW||1);
    if(precise) ctx.setLineDash([2,5]);
    ctx.beginPath(); for(let k=0;k<=160;k++){ const a=k/160*Math.PI*2; let [x,y]=ell(ox,oy,rx,ry,rot,a);
      const w=d*R*0.035*Math.sin(a*7+i*3)*(0.5+r()); x+=w; y+=w*0.6; k?ctx.lineTo(x,y):ctx.moveTo(x,y);} ctx.stroke(); ctx.restore();
    const kN = lock?7:(2+Math.round(v*4));
    for(let b=0;b<kN;b++){
      const a0 = lock? b/kN*Math.PI*2 + i*0.3 : r()*Math.PI*2;
      const [bx,by,z]=ell(ox,oy,rx,ry,rot,a0); const front=0.55+0.45*z;
      // 拖尾
      ctx.save(); ctx.globalCompositeOperation='lighter';
      const tl= 10+Math.round(v*16)+(lock?14:0);
      for(let t=1;t<tl;t++){ const [tx,ty]=ell(ox,oy,rx,ry,rot,a0-t*0.035); ctx.fillStyle=rgba(lock?LK:ringCol,(1-t/tl)*0.35*front);
        ctx.beginPath(); ctx.arc(tx,ty,(2.4+v*2.5)*(1-t/tl*0.6)*(C.lineW||1),0,7); ctx.fill(); }
      ctx.restore();
      glow(ctx,bx,by,(9+v*16)*front,lock?LK:ringCol,0.85*front);
      glow(ctx,bx,by,3+v*3,C.white,1);
    }
  }
  // 精密态：刻度与同心细环
  if(precise){ ctx.save(); ctx.strokeStyle=rgba(C.ice,0.35); ctx.lineWidth=1;
    for(let i=1;i<=3;i++){ ctx.beginPath(); ctx.arc(ox,oy,R*0.09*i+R*0.05,0,7); ctx.stroke(); }
    for(let k=0;k<72;k++){ const a=k/72*Math.PI*2, r1=R*0.36, r2=r1+(k%6?5:12); ctx.beginPath(); ctx.moveTo(ox+Math.cos(a)*r1,oy+Math.sin(a)*r1); ctx.lineTo(ox+Math.cos(a)*r2,oy+Math.sin(a)*r2); ctx.stroke(); }
    ctx.restore(); }
  // 核心
  const coreCol = lock?LK: mix(base, C.orange, Math.max(0,d-0.5));
  glow(ctx,ox,oy,R*(0.35+0.45*v),coreCol,0.28+0.25*v);
  glow(ctx,ox,oy,R*(0.12+0.14*v),coreCol,0.8);
  glow(ctx,ox,oy,R*(precise?0.035:0.05+0.05*v),C.white,1);
  if(lock){ ctx.save(); ctx.globalCompositeOperation='lighter'; ctx.strokeStyle=rgba(C.white,0.9); ctx.lineWidth=2;
    for(let k=0;k<12;k++){ const a=k/12*Math.PI*2; ctx.beginPath(); ctx.moveTo(ox+Math.cos(a)*R*0.08,oy+Math.sin(a)*R*0.08); ctx.lineTo(ox+Math.cos(a)*R*0.22,oy+Math.sin(a)*R*0.22); ctx.stroke(); } ctx.restore(); }
  // 危险：火花
  ctx.save(); ctx.globalCompositeOperation='lighter';
  for(let i=0;i<Math.round(d*d*40);i++){ const a=r()*Math.PI*2, rr=R*(0.4+r()*0.6), l=4+r()*14; ctx.strokeStyle=rgba(r()<0.5?C.orange:C.gold,0.7);
    ctx.lineWidth=1.2; ctx.beginPath(); ctx.moveTo(ox+Math.cos(a)*rr,oy+Math.sin(a)*rr); ctx.lineTo(ox+Math.cos(a)*(rr+l),oy+Math.sin(a)*(rr+l)); ctx.stroke(); }
  ctx.restore();
  // 离谱态：饰品污染
  if(weird>0){
    const glyphs=['∮','☉','Ψ','∴','⊗','✶','♁','∞','Ω','⌬'];
    for(let i=0;i<Math.round(weird*14);i++){ const a=i/14*Math.PI*2+0.2, rr=R*(0.78+0.08*Math.sin(i*1.7));
      txt(ctx,glyphs[i%glyphs.length],cx+Math.cos(a)*rr,cy+Math.sin(a)*rr,R*0.07,rgba(C.gold,0.55),{align:'center',base:'middle',glow:14}); }
    ctx.save(); ctx.globalCompositeOperation='lighter';
    for(let i=0;i<Math.round(weird*40);i++){ const a=r()*Math.PI*2, rr=R*(0.25+r()*0.6), s=3+r()*7; const x=ox+Math.cos(a)*rr, y=oy+Math.sin(a)*rr*0.6;
      ctx.fillStyle=rgba(C.gold,0.5+r()*0.4); ctx.beginPath(); ctx.moveTo(x,y-s); ctx.lineTo(x+s*0.6,y+s*0.4); ctx.lineTo(x-s*0.5,y+s*0.6); ctx.fill(); }
    ctx.restore();
    // 漂浮的稿纸 / 便利贴 / 硬币 投影残影
    const props=[[-0.62,-0.42,'paper'],[0.58,-0.5,'note'],[0.66,0.38,'coin'],[-0.55,0.5,'paper']];
    for(const [px,py,kind] of props.slice(0,Math.round(weird*4))){ const x=cx+px*R, y=cy+py*R; ctx.save(); ctx.translate(x,y); ctx.rotate(px*0.5);
      ctx.strokeStyle=rgba(C.gold,0.55); ctx.fillStyle=rgba(C.gold,0.06); ctx.lineWidth=1.2; ctx.shadowColor=C.gold; ctx.shadowBlur=12;
      if(kind==='paper'){ ctx.fillRect(-R*0.08,-R*0.11,R*0.16,R*0.22); ctx.strokeRect(-R*0.08,-R*0.11,R*0.16,R*0.22);
        for(let k=0;k<5;k++){ ctx.beginPath(); ctx.moveTo(-R*0.06,-R*0.07+k*R*0.035); ctx.lineTo(R*0.05-(k%2)*R*0.03,-R*0.07+k*R*0.035); ctx.stroke(); } }
      if(kind==='note'){ ctx.fillRect(-R*0.07,-R*0.07,R*0.14,R*0.14); ctx.strokeRect(-R*0.07,-R*0.07,R*0.14,R*0.14); ctx.shadowBlur=0;
        txt(ctx,'100%',0,R*0.015,R*0.045,rgba(C.gold,0.9),{align:'center',w:700}); }
      if(kind==='coin'){ ctx.beginPath(); ctx.ellipse(0,0,R*0.07,R*0.025,0,0,7); ctx.fill(); ctx.stroke(); ctx.beginPath(); ctx.ellipse(0,0,R*0.045,R*0.015,0,0,7); ctx.stroke(); }
      ctx.restore(); }
    glow(ctx,ox,oy,R*0.5,C.gold,0.18*weird);
  }
}

// 玻璃裂纹
function cracks(ctx,x,y,len,seed,col){ const r=rng(seed); ctx.save(); ctx.strokeStyle=col; ctx.lineWidth=1.1; ctx.shadowColor=col; ctx.shadowBlur=6;
  for(let b=0;b<5;b++){ let px=x,py=y,a=r()*Math.PI*2; ctx.beginPath(); ctx.moveTo(px,py);
    for(let k=0;k<6;k++){ a+= (r()-0.5)*0.9; const l=len*(0.1+r()*0.15); px+=Math.cos(a)*l; py+=Math.sin(a)*l; ctx.lineTo(px,py); } ctx.stroke(); }
  ctx.restore(); }

// 警示斜纹条
function hazard(ctx,x,y,w,h,col,a){ ctx.save(); ctx.beginPath(); ctx.rect(x,y,w,h); ctx.clip(); ctx.fillStyle=rgba(col,a);
  for(let i=-h;i<w+h;i+=18){ ctx.beginPath(); ctx.moveTo(x+i,y+h); ctx.lineTo(x+i+9,y+h); ctx.lineTo(x+i+9+h,y); ctx.lineTo(x+i+h,y); ctx.fill(); } ctx.restore(); }

// ===== 舱体 =====
function chamberPorthole(ctx,cx,cy,R,p){
  // 外环加速器 + 磁铁
  const RR=R*1.32;
  ctx.save(); ctx.strokeStyle=rgba(C.cyan,0.18); ctx.lineWidth=10; ctx.beginPath(); ctx.arc(cx,cy,RR,0,7); ctx.stroke();
  ctx.strokeStyle=rgba(C.cyan,0.4); ctx.lineWidth=1; ctx.beginPath(); ctx.arc(cx,cy,RR-9,0,7); ctx.stroke(); ctx.beginPath(); ctx.arc(cx,cy,RR+9,0,7); ctx.stroke(); ctx.restore();
  const lit = p.lock?16:Math.round(4+(p.v||0)*8);
  for(let i=0;i<16;i++){ const a=i/16*Math.PI*2; ctx.save(); ctx.translate(cx+Math.cos(a)*RR,cy+Math.sin(a)*RR); ctx.rotate(a);
    const on=i<lit; ctx.fillStyle=on?rgba(p.lock?C.white:C.cyan,0.85):'#11262c'; ctx.strokeStyle=rgba(C.cyan,0.5);
    ctx.fillRect(-9,-24,18,48); ctx.strokeRect(-9,-24,18,48); if(on){ ctx.shadowColor=p.lock?C.white:C.cyan; ctx.shadowBlur=18; ctx.fillRect(-4,-18,8,36);} ctx.restore(); }
  // 外环上运行的束团
  const ba=-0.6; for(let t=0;t<40;t++){ const a=ba-t*0.02; glow(ctx,cx+Math.cos(a)*RR,cy+Math.sin(a)*RR,10*(1-t/40),p.lock?C.white:C.cyan,0.6*(1-t/40)); }
  // 舱体
  ctx.save(); ctx.beginPath(); ctx.arc(cx,cy,R,0,7); ctx.clip(); drawBeam(ctx,cx,cy,R,p);
  // 玻璃反光
  const gl=ctx.createLinearGradient(cx-R,cy-R,cx+R,cy+R); gl.addColorStop(0,'rgba(255,255,255,0.08)'); gl.addColorStop(0.35,'rgba(255,255,255,0)'); gl.addColorStop(1,'rgba(255,255,255,0.03)');
  ctx.fillStyle=gl; ctx.fillRect(cx-R,cy-R,R*2,R*2); ctx.restore();
  ctx.save(); ctx.strokeStyle=rgba(C.ice,0.12); ctx.lineWidth=3; ctx.beginPath(); ctx.arc(cx,cy,R*0.93,Math.PI*1.1,Math.PI*1.45); ctx.stroke(); ctx.restore();
  // 舱框 + 螺栓
  const dcol = mix(C.cyan,C.red,Math.max(0,(p.d||0)-0.5)*2);
  ctx.save(); ctx.strokeStyle=rgba(dcol,0.7); ctx.lineWidth=2; ctx.beginPath(); ctx.arc(cx,cy,R,0,7); ctx.stroke();
  ctx.strokeStyle=rgba(C.cyan,0.25); ctx.lineWidth=14; ctx.beginPath(); ctx.arc(cx,cy,R+10,0,7); ctx.stroke(); ctx.restore();
  for(let i=0;i<24;i++){ const a=i/24*Math.PI*2; ctx.fillStyle='#2a4a50'; ctx.beginPath(); ctx.arc(cx+Math.cos(a)*(R+10),cy+Math.sin(a)*(R+10),2.5,0,7); ctx.fill(); }
  if((p.d||0)>0.6){ ctx.save(); ctx.beginPath(); ctx.arc(cx,cy,R,0,7); ctx.clip(); cracks(ctx,cx+R*0.62,cy-R*0.7,R*0.5,11,rgba(C.red,0.6)); cracks(ctx,cx-R*0.8,cy+R*0.45,R*0.4,5,rgba(C.orange,0.5)); ctx.restore(); }
}

function chamberTank(ctx,cx,cy,w,h,p){
  const x=cx-w/2, y=cy-h/2, rad=w*0.18;
  ctx.save(); ctx.beginPath(); ctx.roundRect(x,y,w,h,rad); ctx.clip(); drawBeam(ctx,cx,cy,Math.min(w,h)*0.46,p);
  const gl=ctx.createLinearGradient(x,0,x+w,0); gl.addColorStop(0,'rgba(200,250,255,0.10)'); gl.addColorStop(0.12,'rgba(200,250,255,0.02)'); gl.addColorStop(0.18,'rgba(200,250,255,0.09)');
  gl.addColorStop(0.24,'rgba(0,0,0,0)'); gl.addColorStop(0.85,'rgba(0,0,0,0)'); gl.addColorStop(1,'rgba(200,250,255,0.08)'); ctx.fillStyle=gl; ctx.fillRect(x,y,w,h); ctx.restore();
  const dcol = mix(C.cyan,C.red,Math.max(0,(p.d||0)-0.5)*2);
  ctx.save(); ctx.strokeStyle=rgba(dcol,0.65); ctx.lineWidth=2; ctx.beginPath(); ctx.roundRect(x,y,w,h,rad); ctx.stroke(); ctx.restore();
  // 侧刻度
  for(let i=0;i<=20;i++){ const yy=y+rad+i*(h-rad*2)/20; ctx.fillStyle=rgba(C.cyan,i%5?0.25:0.6); ctx.fillRect(x+w+10,yy,i%5?8:16,1.5); }
  // 上下磁体帽
  for(const top of [true,false]){ const yy= top? y-70 : y+h-10; ctx.save();
    ctx.fillStyle='#0b1a20'; ctx.strokeStyle=rgba(C.cyan,0.45); ctx.lineWidth=1.5; ctx.beginPath(); ctx.roundRect(x-30,yy,w+60,80,10); ctx.fill(); ctx.stroke();
    const lit = p.lock?8:Math.round(2+(p.v||0)*5);
    for(let i=0;i<8;i++){ const bx=x-10+i*(w+20)/8; ctx.fillStyle=i<lit?rgba(p.lock?C.white:C.cyan,0.85):'#14303a'; if(i<lit){ctx.shadowColor=C.cyan; ctx.shadowBlur=14;}
      ctx.fillRect(bx+6,yy+(top?18:30),(w+20)/8-12,30); ctx.shadowBlur=0; }
    ctx.restore(); }
  if((p.d||0)>0.6){ ctx.save(); ctx.beginPath(); ctx.roundRect(x,y,w,h,rad); ctx.clip(); cracks(ctx,x+w*0.85,y+h*0.2,w*0.4,3,rgba(C.red,0.6)); ctx.restore(); }
}

function chamberCapsule(ctx,cx,cy,w,h,p){
  const x=cx-w/2, y=cy-h/2;
  // 注入器管道（左）与探测器（右）
  ctx.fillStyle='#0b1a20'; ctx.strokeStyle=rgba(C.cyan,0.4); ctx.lineWidth=1.5;
  ctx.fillRect(x-150,cy-22,160,44); ctx.strokeRect(x-150,cy-22,160,44); txt(ctx,'注入器',x-140,cy-34,16,C.sub);
  ctx.fillRect(x+w-10,cy-22,90,44); ctx.strokeRect(x+w-10,cy-22,90,44);
  ctx.save(); ctx.fillStyle='#0b1a20'; ctx.beginPath(); ctx.roundRect(x+w+80,cy-130,70,260,8); ctx.fill(); ctx.stroke(); ctx.restore();
  txt(ctx,'探测屏',x+w+115,cy-145,16,C.sub,{align:'center'});
  for(let i=0;i<10;i++){ ctx.fillStyle=rgba(C.cyan,0.15+0.05*i); ctx.fillRect(x+w+92,cy-115+i*24,46,16); }
  ctx.save(); ctx.beginPath(); ctx.roundRect(x,y,w,h,h/2); ctx.clip(); drawBeam(ctx,cx,cy,h*0.48,p);
  const gl=ctx.createLinearGradient(0,y,0,y+h); gl.addColorStop(0,'rgba(200,250,255,0.10)'); gl.addColorStop(0.15,'rgba(0,0,0,0)'); gl.addColorStop(0.9,'rgba(0,0,0,0)'); gl.addColorStop(1,'rgba(200,250,255,0.06)');
  ctx.fillStyle=gl; ctx.fillRect(x,y,w,h); ctx.restore();
  const dcol = mix(C.cyan,C.red,Math.max(0,(p.d||0)-0.5)*2);
  ctx.save(); ctx.strokeStyle=rgba(dcol,0.7); ctx.lineWidth=2; ctx.beginPath(); ctx.roundRect(x,y,w,h,h/2); ctx.stroke(); ctx.restore();
  // 磁体箍
  const lit = p.lock?6:Math.round(1+(p.v||0)*4);
  for(let i=0;i<6;i++){ const bx=x+h*0.45+i*(w-h*0.9)/5; ctx.save(); ctx.fillStyle=i<lit?rgba(p.lock?C.white:C.cyan,0.8):'#14303a';
    if(i<lit){ctx.shadowColor=C.cyan; ctx.shadowBlur=16;} ctx.fillRect(bx-7,y-26,14,22); ctx.fillRect(bx-7,y+h+4,14,22); ctx.restore(); }
  if((p.d||0)>0.6){ ctx.save(); ctx.beginPath(); ctx.roundRect(x,y,w,h,h/2); ctx.clip(); cracks(ctx,x+w*0.78,y+h*0.12,h*0.45,9,rgba(C.red,0.65)); cracks(ctx,x+w*0.2,y+h*0.9,h*0.35,4,rgba(C.orange,0.5)); ctx.restore(); }
}

// ===== HUD =====
const OUT=[['完美同步',C.white],['加速成功',C.cyan],['保持稳定','#4f8890'],['射频失谐',C.orange],['束流丢失',C.red]];
function hud(ctx,s){
  const W=1920,H=1080;
  // 顶栏
  txt(ctx,'BEAMLINE',60,62,26,C.text,{ls:10,w:300}); txt(ctx,'束流',330,62,26,C.sub,{w:300});
  txt(ctx,`考核 ${s.stage} / 3`,720,60,24,C.text);
  for(let i=0;i<3;i++){ ctx.fillStyle=i<s.stage?C.cyan:'#16303a'; ctx.fillRect(860+i*26,46,18,18); }
  txt(ctx,`剩余实验 ${s.left}`,1000,60,24,C.text);
  txt(ctx,`种子 ${s.seed}`,1860,60,18,C.sub,{align:'right',mono:true});
  ctx.fillStyle=C.line; ctx.fillRect(60,92,1800,1);
  // 左栏
  txt(ctx,'能级',60,160,20,C.sub); const ew=txt(ctx,`E${s.E}`,60,240,84,s.lock?C.white:C.ice,{w:300,mono:true,glow:s.lock?20:0});
  txt(ctx,`≈ ${s.gev} GeV`,60+ew+16,240,20,C.sub,{mono:true});
  txt(ctx,'潜在成果',60,300,20,C.sub); const vw=txt(ctx,s.value,60,360,52,C.white,{mono:true,glow:12}); txt(ctx,'RP',60+vw+12,360,20,C.sub,{mono:true});
  txt(ctx,'下一次加速',60,450,20,C.sub);
  let bx=60; const bw=340; for(let i=0;i<5;i++){ const w=bw*s.prob[i]/100; ctx.fillStyle=OUT[i][1]; ctx.globalAlpha=i===4&&s.prob[4]>20?1:0.85; ctx.fillRect(bx,466,Math.max(1,w-2),14); ctx.globalAlpha=1; bx+=w; }
  for(let i=0;i<5;i++){ const y=520+i*38; ctx.fillStyle=OUT[i][1]; ctx.fillRect(60,y-12,10,10);
    const hot = i===4 && s.prob[4]>=20; txt(ctx,OUT[i][0],82,y,20,hot?C.red:C.text); txt(ctx,s.prob[i].toFixed(1)+'%',400,y,20,hot?C.red:C.text,{align:'right',mono:true,glow:hot?10:0}); }
  txt(ctx,'锁相充能',60,740,20,C.sub);
  for(let i=0;i<6;i++){ const on=i<s.charge; ctx.save(); ctx.fillStyle=on?(s.lock?C.white:C.cyan):'#14303a'; if(on){ctx.shadowColor=C.cyan;ctx.shadowBlur=12;}
    ctx.beginPath(); const hx=78+i*52, hy=780; for(let k=0;k<6;k++){ const a=Math.PI/3*k+Math.PI/6; k?ctx.lineTo(hx+18*Math.cos(a),hy+18*Math.sin(a)):ctx.moveTo(hx+18*Math.cos(a),hy+18*Math.sin(a)); } ctx.fill(); ctx.restore(); }
  if(s.lock) txt(ctx,`锁相中 · 剩余 ${s.lockLeft} 次`,60,840,22,C.white,{glow:14});
  // 右栏：累计考核图
  const rx=1480; txt(ctx,'累计科研点数',rx,160,20,C.sub); txt(ctx,s.total,rx,206,34,C.text,{mono:true}); txt(ctx,`下一考核线 ${s.line}`,rx,236,18,C.sub,{mono:true});
  ctx.strokeStyle=C.line; ctx.strokeRect(rx,256,380,170);
  ctx.save(); ctx.strokeStyle=rgba(C.orange,0.7); ctx.setLineDash([5,4]); ctx.beginPath(); ctx.moveTo(rx,410);
  [[0,410],[127,410],[127,370],[253,370],[253,300],[380,300]].forEach(([a,b])=>ctx.lineTo(rx+a,b)); ctx.stroke(); ctx.restore();
  ctx.save(); ctx.strokeStyle=C.cyan; ctx.lineWidth=2; ctx.shadowColor=C.cyan; ctx.shadowBlur=8; ctx.beginPath(); s.curve.forEach(([a,b],i)=>i?ctx.lineTo(rx+a,b):ctx.moveTo(rx+a,b)); ctx.stroke(); ctx.restore();
  txt(ctx,'实验日志',rx,480,20,C.sub);
  s.log.forEach((l,i)=>{ const y=516+i*34; ctx.fillStyle=OUT[l[0]][1]; ctx.fillRect(rx,y-12,10,10); txt(ctx,l[1],rx+22,y,18,C.text); txt(ctx,l[2],1860,y,18,C.sub,{align:'right',mono:true}); });
  txt(ctx,'显示概率 / 实际频率（本局）',rx,780,16,C.sub);
  [['成功类','61.8%','63.0%'],['束流丢失','11.2%','10.4%']].forEach((r,i)=>{ const y=812+i*28; txt(ctx,r[0],rx,y,17,C.text); txt(ctx,r[1],rx+250,y,17,C.sub,{mono:true,align:'right'}); txt(ctx,r[2],1860,y,17,C.text,{mono:true,align:'right'}); });
  // 底部按钮
  ctx.fillStyle=C.line; ctx.fillRect(60,930,1800,1);
  const btn=(x,label,key,primary,danger)=>{ ctx.save(); ctx.strokeStyle=danger?rgba(C.red,0.8):rgba(primary?C.cyan:C.text,0.7); ctx.lineWidth=1.5;
    ctx.fillStyle=primary?rgba(C.cyan,0.10):'rgba(255,255,255,0.03)'; ctx.beginPath(); ctx.roundRect(x,958,300,84,4); ctx.fill(); ctx.stroke(); ctx.restore();
    txt(ctx,label,x+150,1008,28,primary?C.ice:C.text,{align:'center',w:500}); txt(ctx,key,x+150,1034,14,C.sub,{align:'center',mono:true}); };
  btn(640,'继续加速','SPACE',true,s.prob[4]>=20); btn(980,'引出束流','E',false,false);
  if(s.caption) txt(ctx,s.caption,1860,1060,15,rgba(C.sub,0.8),{align:'right'});
}

function scene(n){
  const cv=document.getElementById('c'), ctx=cv.getContext('2d');
  ctx.fillStyle=C.bg; ctx.fillRect(0,0,1920,1080);
  // 背景极淡点阵
  ctx.fillStyle=rgba(C.cyan,0.05); for(let x=0;x<1920;x+=40) for(let y=0;y<1080;y+=40) ctx.fillRect(x,y,1,1);
  const S = { stage:2, left:2, seed:'7F3A-19C2', total:'8,420', line:'12,000', log:[[1,'加速成功  E6→E7','+1'],[0,'完美同步  E4→E6','+2'],[3,'射频失谐  E5→E4','-1'],[1,'加速成功  E4→E5','+1'],[2,'保持稳定  E4','0'],[1,'加速成功  E3→E4','+1']],
    curve:[[0,410],[40,404],[90,396],[127,380],[180,372],[230,352],[253,338]] };
  if(n===1){ // 方案 A 竖井
    chamberTank(ctx,960,500,560,640,{v:0.5,d:0.3,seed:3});
    hud(ctx,{...S,E:7,gev:'142',value:'3,880',prob:[7.2,47.6,13.6,13.2,18.4],charge:3,caption:'方案 A · 竖井式观测舱 · 常态（E7）'});
  }
  if(n===2){ // 方案 B 舷窗 + 外环，锁相
    chamberPorthole(ctx,960,505,262,{v:0.75,d:0.1,lock:true,seed:9});
    txt(ctx,'PHASE LOCK',960,134,22,C.white,{align:'center',ls:12,glow:18}); txt(ctx,'4',1300,880,64,C.white,{align:'center',mono:true,glow:24}); txt(ctx,'剩余安全加速',1300,910,16,C.ice,{align:'center'});
    hud(ctx,{...S,E:10,gev:'288',value:'12,640',prob:[9.0,64.0,15.0,12.0,0],charge:6,lock:true,lockLeft:4,caption:'方案 B · 舷窗式观测舱 + 外环加速器 · 锁相狂暴态'});
  }
  if(n===3){ // 方案 C 横向胶囊，超负荷
    chamberCapsule(ctx,920,510,680,360,{v:0.85,d:0.85,seed:21});
    hazard(ctx,580,268,680,10,C.red,0.5); txt(ctx,'束流不稳 · 下一次丢失概率 31%',920,250,20,C.red,{align:'center',glow:10});
    hud(ctx,{...S,E:12,gev:'410',value:'27,300',prob:[4.6,32.2,10.8,12.4,31.0],charge:1,caption:'方案 C · 横向胶囊舱（直连探测屏） · 超负荷态（E12）'});
  }
  if(n===4){ // 成长六阶段
    txt(ctx,'束流成长 · 同一个舱，六种状态',60,80,30,C.text,{w:300}); txt(ctx,'价值通道（亮度/束团/层数）与危险通道（偏心/束晕/红橙/裂纹）分开驱动',60,118,18,C.sub);
    const st=[['基础束流','E1 · 40 RP · 丢失 3%',{v:0.05,d:0.05,seed:1}],['高能束流','E5 · 1.2k · 丢失 14%',{v:0.4,d:0.2,seed:2}],['精密态','E7 · 3.9k · 丢失 9%',{v:0.6,d:0.05,style:'precise',seed:3}],
      ['超负荷态','E11 · 21k · 丢失 30%',{v:0.8,d:0.85,seed:4}],['锁相狂暴态','E10 · 12k · 丢失 0%',{v:0.75,d:0,lock:true,seed:5}],['离谱态','E9 · ×38 · 丢失 22%',{v:0.7,d:0.45,weird:1,seed:6}]];
    st.forEach((q,i)=>{ const cx=210+(i%3)*750*0.66+ (i%3)*80, cy= i<3? 400: 800; const X=230+(i%3)*610, Y=i<3?400:820;
      ctx.save(); ctx.beginPath(); ctx.arc(X,Y,170,0,7); ctx.clip(); drawBeam(ctx,X,Y,170,q[2]); ctx.restore();
      ctx.strokeStyle=rgba(mix(C.cyan,C.red,Math.max(0,(q[2].d-0.5)*2)),0.6); ctx.lineWidth=2; ctx.beginPath(); ctx.arc(X,Y,170,0,7); ctx.stroke();
      if(q[2].d>0.6){ ctx.save(); ctx.beginPath(); ctx.arc(X,Y,170,0,7); ctx.clip(); cracks(ctx,X+110,Y-120,80,i,rgba(C.red,0.6)); ctx.restore(); }
      txt(ctx,`${i+1}`,X+200,Y-110,48,rgba(C.cyan,0.25),{mono:true,w:300}); txt(ctx,q[0],X+200,Y-40,30,q[2].lock?C.white:(q[2].weird?C.gold:(q[2].d>0.6?C.red:C.text)),{w:500});
      txt(ctx,q[1],X+200,Y,18,C.sub,{mono:true}); });
  }
  if(n===5){ // 引出开花
    txt(ctx,'引出 · 探测屏开花（四种品相）',60,70,30,C.text,{w:300});
    const q=[['规整型','precise'],['爆发型','burst'],['污染型','dirty'],['神棍型','weird']];
    q.forEach((k,i)=>{ const X=500+(i%2)*920, Y=i<2?330:790; event(ctx,X,Y,200,k[1],i+3); txt(ctx,k[0],X-420,Y-170,26,k[1]==='weird'?C.gold:(k[1]==='dirty'?C.orange:C.text),{w:500});
      txt(ctx,['+48,200 RP','+184,320 RP','+96,050 RP','+1,240,000 RP'][i],X-420,Y-132,22,C.sub,{mono:true}); });
  }
}

// 探测屏事件图谱
function event(ctx,cx,cy,R,style,seed){
  const r=rng(seed);
  ctx.save(); ctx.beginPath(); ctx.rect(cx-R*2.1,cy-R*1.1,R*4.2,R*2.2); ctx.clip();
  ctx.fillStyle='#03070a'; ctx.fillRect(cx-R*2.1,cy-R*1.1,R*4.2,R*2.2);
  // 探测器层
  ctx.strokeStyle=rgba(C.cyan,0.18); ctx.lineWidth=1; for(let i=1;i<=4;i++){ ctx.beginPath(); ctx.arc(cx,cy,R*0.18*i,0,7); ctx.stroke(); }
  ctx.strokeStyle=rgba(C.cyan,0.12); ctx.beginPath(); ctx.arc(cx,cy,R*0.95,0,7); ctx.stroke();
  const main = style==='weird'?C.gold:(style==='dirty'?C.orange:C.cyan);
  // 量能器塔
  const towers=48; for(let i=0;i<towers;i++){ const a=i/towers*Math.PI*2; let e;
    if(style==='precise') e=0.15+0.5*Math.pow(Math.abs(Math.cos(a*3)),8); else if(style==='burst') e=0.1+r()*0.3+(Math.abs(Math.sin(a))>0.95?0.7:0)+(Math.abs(Math.cos(a+0.6))>0.97?0.6:0);
    else if(style==='dirty') e=r()*0.45; else e=0.15+0.45*Math.pow(Math.abs(Math.sin(a*4)),4);
    const r1=R*0.8, r2=r1+R*0.6*e; ctx.save(); ctx.strokeStyle=rgba(e>0.5?(style==='dirty'?C.red:C.white):main,0.35+e*0.6); ctx.lineWidth=R*0.09;
    ctx.beginPath(); ctx.moveTo(cx+Math.cos(a)*r1,cy+Math.sin(a)*r1); ctx.lineTo(cx+Math.cos(a)*r2,cy+Math.sin(a)*r2); ctx.stroke(); ctx.restore(); }
  // 径迹
  const N= style==='precise'?24 : style==='burst'?140 : style==='dirty'?60 : 36;
  ctx.save(); ctx.globalCompositeOperation='lighter';
  for(let i=0;i<N;i++){ let a, k;
    if(style==='precise'){ a=i/N*Math.PI*2; k=(i%2?1:-1)*0.012; }
    else if(style==='burst'){ const jet=r()<0.6; a= jet? (r()<0.5?Math.PI/2:-Math.PI/2+0.6)+(r()-0.5)*0.5 : r()*Math.PI*2; k=(r()-0.5)*0.05; }
    else if(style==='weird'){ a=i/N*Math.PI*2; k=0.03*Math.sin(i*1.3); }
    else { a=r()*Math.PI*2; k=(r()-0.5)*0.09; }
    let x=cx,y=cy, th=a; const steps= style==='dirty'? 20+r()*40 : 50+r()*20;
    const col = style==='burst'? (r()<0.3?C.orange:(r()<0.5?C.white:C.cyan)) : style==='dirty'? (r()<0.5?C.red:C.orange) : main;
    ctx.strokeStyle=rgba(col,style==='dirty'?0.45:0.7); ctx.lineWidth=style==='burst'?1.4:1.2; ctx.beginPath(); ctx.moveTo(x,y);
    for(let t=0;t<steps;t++){ th+=k; x+=Math.cos(th)*R*0.016; y+=Math.sin(th)*R*0.016; if(Math.hypot(x-cx,y-cy)>R*0.8) break; ctx.lineTo(x,y); }
    ctx.stroke(); }
  if(style==='dirty'){ for(let i=0;i<500;i++){ const a=r()*Math.PI*2, rr=r()*R*0.8; ctx.fillStyle=rgba(r()<0.5?C.red:C.orange,0.3+r()*0.4); ctx.fillRect(cx+Math.cos(a)*rr,cy+Math.sin(a)*rr,2,2); } }
  ctx.restore();
  glow(ctx,cx,cy,R*(style==='burst'?0.7:0.35),style==='burst'?C.white:main,style==='burst'?0.7:0.5);
  if(style==='weird'){ const g=['∮','☉','Ψ','∴','⊗','✶','♁','∞'];
    for(let i=0;i<8;i++){ const a=i/8*Math.PI*2+0.39; txt(ctx,g[i],cx+Math.cos(a)*R*0.55,cy+Math.sin(a)*R*0.55,R*0.12,C.gold,{align:'center',base:'middle',glow:16}); }
    ctx.save(); ctx.strokeStyle=rgba(C.gold,0.6); ctx.lineWidth=1.5; ctx.shadowColor=C.gold; ctx.shadowBlur=14; ctx.beginPath(); ctx.arc(cx,cy,R*0.68,0,7); ctx.stroke(); ctx.restore(); }
  if(style==='precise'){ ctx.save(); ctx.strokeStyle=rgba(C.ice,0.4); ctx.setLineDash([2,4]); ctx.beginPath(); ctx.arc(cx,cy,R*0.62,0,7); ctx.stroke(); ctx.restore(); }
  ctx.restore();
  ctx.strokeStyle=C.line; ctx.lineWidth=1; ctx.strokeRect(cx-R*2.1,cy-R*1.1,R*4.2,R*2.2);
  if(R>120) txt(ctx,'EVT #00042  ·  13.6 TeV',cx+R*2.0,cy+R*1.05,14,C.sub,{align:'right',mono:true,base:'bottom'});
}
