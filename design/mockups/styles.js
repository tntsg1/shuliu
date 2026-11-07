// 非荧光风格（哑光、无辉光）四套：#13–#16
const _glow0 = window.glow;
window.glow = function(ctx,x,y,r,col,a){ if(!C.matte) return _glow0(ctx,x,y,r,col,a);
  ctx.save(); ctx.globalAlpha=Math.min(1,a*0.9); ctx.fillStyle=col; ctx.beginPath(); ctx.arc(x,y,Math.max(2,r*0.36),0,Math.PI*2); ctx.fill(); ctx.restore(); };
function matteCtx(ctx){
  const P=CanvasRenderingContext2D.prototype, gco=Object.getOwnPropertyDescriptor(P,'globalCompositeOperation'), sb=Object.getOwnPropertyDescriptor(P,'shadowBlur');
  Object.defineProperty(ctx,'globalCompositeOperation',{set(v){gco.set.call(ctx,v==='lighter'?'source-over':v);},get(){return gco.get.call(ctx);}});
  Object.defineProperty(ctx,'shadowBlur',{set(v){sb.set.call(ctx,0);},get(){return 0;}});
}
function rampOf(stops){ return v=>{ v=Math.max(0,Math.min(1,v)); const n=stops.length-1, i=Math.min(n-1,Math.floor(v*n)); return mix(stops[i],stops[i+1],v*n-i); }; }

const STYLES = {
  13:{ name:'方案一 · 工程图纸（米色纸面 + 墨线 + 少量彩色墨水）',
    C:{ bg:'#efe8d8', panel:'#e6dcc8', line:'#b9ae98', dim:'#8a8170', cyan:'#2f5d9e', ice:'#2f5d9e', white:'#2b2a28', red:'#c2412d', orange:'#d9822b', gold:'#c9971a',
        text:'#2b2a28', sub:'#7a7264', lock:'#6a4fb0', in0:'#f7f2e6', in1:'#e3d8c2', lineBoost:2.6 },
    ramp:['#3a4fa0','#2f7fa8','#2f9a8a','#6a9f45','#c9971a'],
    S:{ office:'#e2d7c0', lamp:'#e8b45a', books:['#9e4a3a','#3a5a8a','#c9971a','#4a7a5a','#7a5a9a','#a87a4a'], slab:'#cfc3a8', storage:'#ddd2b8', boxes:['#b06a50','#5a7aa8','#c9a24a','#6a9a7a','#8a6aa8'],
        wall:['#ece4d2','#efe8d8','#e9e0cc'], panel:'rgba(120,105,80,0.18)', cables:['#c2412d','#2f5d9e','#c9971a'], pools:0.0, stair:'#8a8170', bar:'rgba(239,232,216,0.92)',
        equip:'#d8ccb2', equipLine:'#2b2a28', pipe:'#cfc3a8', dip:['#3a5fa8','#2f4f8e'], quad:['#c2563f','#a8442f'], det:['#d9cbe8','#c4b0dc','#ae96cf','#987dc2','#8264b5'], term:'#e9cf8a', figLine:'#2b2a28' } },
  14:{ name:'方案二 · 七十年代实验室（墨绿墙 + 米白设备 + 芥末黄/铁锈橙）',
    C:{ bg:'#1f2724', panel:'#27312d', line:'#4a5650', dim:'#7d8a80', cyan:'#5fa39a', ice:'#d9cfb4', white:'#f1e8d2', red:'#c4473a', orange:'#d8792e', gold:'#d9a62e',
        text:'#efe6cf', sub:'#a59f88', lock:'#9a7cc4', in0:'#2a3632', in1:'#1a221f', lineBoost:1.8 },
    ramp:['#4f7fa0','#3f8f8a','#8fb06a','#d9c27a','#f1e6c8'],
    S:{ office:'#2a231c', lamp:'#e8b04a', books:['#7a3a2a','#3a4a3a','#8a6a2a','#4a3a2a','#5a5a3a','#6a4a2a'], slab:'#4a3b2e', storage:'#1d1f1a', boxes:['#8a5a3a','#5a6a4a','#9a7a3a','#6a4a3a','#4a5a5a'],
        wall:['#2e3a36','#2b3632','#2e3a36'], panel:'rgba(200,190,160,0.07)', cables:['#c4473a','#d9a62e','#5fa39a'], pools:0.06, stair:'#a59f88', bar:'rgba(31,39,36,0.92)',
        equip:'#c9b99a', equipLine:'#2a2620', pipe:'#9a8e76', dip:['#4f6fa0','#3e5a88'], quad:['#c4573a','#a8452c'], det:['#6a5a8a','#7a6a9a','#8a7aa8','#9a8ab6','#aa9ac4'], term:'#d9a62e', figLine:'#2a2620' } },
  15:{ name:'方案三 · 扁平海报（藏青底 + 平涂高饱和色块）',
    C:{ bg:'#1f2a44', panel:'#26334f', line:'#3a4a6e', dim:'#6f7fa3', cyan:'#5aa9e6', ice:'#f4f1ea', white:'#f4f1ea', red:'#f26b5b', orange:'#f29b4b', gold:'#f7c548',
        text:'#f4f1ea', sub:'#9fb0d0', lock:'#9b7be0', in0:'#2a3a5e', in1:'#1a2440', lineBoost:2.2 },
    ramp:['#5a6fe6','#5aa9e6','#4fc1a6','#a8d86a','#f4f1ea'],
    S:{ office:'#28304a', lamp:'#f7c548', books:['#f26b5b','#5aa9e6','#f7c548','#4fc1a6','#9b7be0','#f29b4b'], slab:'#33416a', storage:'#1a2238', boxes:['#f26b5b','#f7c548','#4fc1a6','#9b7be0','#5aa9e6'],
        wall:['#26334f','#24304b','#28304f'], panel:'rgba(160,180,230,0.08)', cables:['#f26b5b','#f7c548','#4fc1a6'], pools:0.05, stair:'#9fb0d0', bar:'rgba(31,42,68,0.95)',
        equip:'#3a4a72', equipLine:'#f4f1ea', pipe:'#4a5a84', dip:['#5aa9e6','#3f86c4'], quad:['#f26b5b','#d4503f'], det:['#5c4a9a','#6d58b0','#7e67c4','#9076d4','#9b7be0'], term:'#f7c548', figLine:'#1f2a44' } },
  16:{ name:'方案四 · 冷灰工业（低饱和灰 + 安全黄/信号红点缀）',
    C:{ bg:'#16191d', panel:'#1f2328', line:'#343a42', dim:'#6a737e', cyan:'#8fb3d4', ice:'#d8e2ea', white:'#eef0f2', red:'#c8453b', orange:'#d98a3a', gold:'#e0b13a',
        text:'#e6e9ec', sub:'#8a939d', lock:'#a993cf', in0:'#262b31', in1:'#15181c', lineBoost:1.8 },
    ramp:['#6f86a8','#7da0c4','#a9c4d9','#d8e4ea','#f2e2bf'],
    S:{ office:'#1e1d1b', lamp:'#e0b880', books:['#4a4440','#3a4048','#55504a','#40403a','#4a4650','#504a42'], slab:'#2c3137', storage:'#14171a', boxes:['#4a4f56','#5a5040','#3e4a50','#5a4648','#4a5248'],
        wall:['#22262b','#24282d','#22262b'], panel:'rgba(200,210,220,0.05)', cables:['#c8453b','#e0b13a','#6a737e'], pools:0.05, stair:'#6a737e', bar:'rgba(22,25,29,0.95)',
        equip:'#3a4048', equipLine:'#9aa3ad', pipe:'#4a5058', dip:['#4a6a90','#3a5674'], quad:['#a8473d','#8a3a32'], det:['#3e4652','#4a5360','#56606e','#626d7c','#6e7a8a'], term:'#e0b13a', figLine:'#16191d' } },
};

function sceneStyle(n){
  const st=STYLES[n]; Object.assign(C,st.C); C.matte=true; C.lineW=2.2; C.ramp=rampOf(st.ramp); const S=st.S;
  OUT[0][1]=C.white; OUT[1][1]=st.ramp[2]; OUT[2][1]=C.dim; OUT[3][1]=C.orange; OUT[4][1]=C.red;
  const cv=document.getElementById('c'), ctx=cv.getContext('2d'); matteCtx(ctx);
  ctx.fillStyle=C.bg; ctx.fillRect(0,0,1920,1080);
  // 上层办公室
  ctx.fillStyle=S.office; ctx.fillRect(0,0,1920,CEIL-24);
  S.books.forEach((b,i)=>{ ctx.fillStyle=b; ctx.fillRect(820+i*70,60,50,110); ctx.fillStyle='rgba(0,0,0,0.15)'; ctx.fillRect(820+i*70,60,8,110); });
  ctx.fillStyle=S.slab; ctx.fillRect(1300,120,160,50); ctx.fillStyle=S.lamp; ctx.beginPath(); ctx.moveTo(1322,118); ctx.lineTo(1352,118); ctx.lineTo(1344,96); ctx.lineTo(1330,96); ctx.fill();
  txt(ctx,'退休教授办公室（以后开放）',1500,150,16,C.sub);
  ctx.fillStyle=S.slab; ctx.fillRect(0,CEIL-24,1920,24); ctx.fillRect(0,FLOOR,1920,22);
  hazard(ctx,0,FLOOR+22,1920,6,C.gold,0.6);
  // 储藏室
  ctx.fillStyle=S.storage; ctx.fillRect(0,FLOOR+28,1920,260);
  for(let i=0;i<9;i++){ const x=420+i*130; ctx.strokeStyle=C.line; ctx.lineWidth=1.5; ctx.strokeRect(x,FLOOR+70,100,170); ctx.beginPath(); ctx.moveTo(x,FLOOR+130); ctx.lineTo(x+100,FLOOR+130); ctx.moveTo(x,FLOOR+190); ctx.lineTo(x+100,FLOOR+190); ctx.stroke();
    ctx.fillStyle=S.boxes[i%5]; ctx.fillRect(x+10+(i*17)%50,FLOOR+100,24,30); ctx.fillStyle=S.boxes[(i+2)%5]; ctx.fillRect(x+40,FLOOR+160,30,30); }
  ctx.fillStyle=C.gold; ctx.beginPath(); ctx.arc(1003,FLOOR+113,6,0,7); ctx.fill();
  txt(ctx,'地下储藏室 / 失物招领箱（以后开放）',420,FLOOR+270,16,C.sub);
  // 主层墙
  const wg=ctx.createLinearGradient(0,0,1920,0); wg.addColorStop(0,S.wall[0]); wg.addColorStop(0.5,S.wall[1]); wg.addColorStop(1,S.wall[2]); ctx.fillStyle=wg; ctx.fillRect(0,CEIL,1920,FLOOR-CEIL);
  ctx.strokeStyle=S.panel; ctx.lineWidth=1.5; for(let x=0;x<1920;x+=160) ctx.strokeRect(x+6,CEIL+14,148,FLOOR-CEIL-28);
  ctx.fillStyle=S.slab; ctx.fillRect(0,CEIL,1920,14);
  S.cables.forEach((c,k)=>{ const y=CEIL+20+k*6; ctx.strokeStyle=c; ctx.lineWidth=2.5; ctx.beginPath(); ctx.moveTo(0,y); for(let x=0;x<=1920;x+=240) ctx.quadraticCurveTo(x+120,y+10,x+240,y); ctx.stroke(); });
  for(let x=200;x<1920;x+=320){ ctx.fillStyle=S.lamp; ctx.fillRect(x,CEIL+14,80,5);
    if(S.pools){ ctx.fillStyle=rgba(S.lamp,S.pools); ctx.beginPath(); ctx.moveTo(x,CEIL+19); ctx.lineTo(x+80,CEIL+19); ctx.lineTo(x+170,FLOOR); ctx.lineTo(x-90,FLOOR); ctx.fill(); } }
  ctx.strokeStyle=S.stair; ctx.lineWidth=2; for(let i=0;i<10;i++){ ctx.beginPath(); ctx.moveTo(30+i*9,FLOOR-i*30); ctx.lineTo(70+i*9,FLOOR-i*30); ctx.stroke(); }
  const box=(x,y,w,h,f)=>{ ctx.fillStyle=f; ctx.fillRect(x,y,w,h); ctx.strokeStyle=S.equipLine; ctx.lineWidth=1.5; ctx.strokeRect(x,y,w,h); };
  // 注入器
  box(150,BEAMY-110,190,220,S.equip); st.ramp.forEach((c,i)=>{ ctx.fillStyle=c; ctx.fillRect(170+i*32,BEAMY-80,20,160); });
  ctx.fillStyle=S.slab; ctx.fillRect(190,BEAMY+110,110,FLOOR-BEAMY-110); txt(ctx,'注入器',245,BEAMY-124,18,C.sub,{align:'center'});
  // 束流管
  const pipe=(x1,x2)=>{ box(x1,BEAMY-14,x2-x1,28,S.pipe); for(let x=x1+40;x<x2;x+=90){ ctx.fillStyle=S.equipLine; ctx.fillRect(x,BEAMY-18,6,36);} };
  pipe(340,820); pipe(1380,1600);
  const mag=(x,w,h,cols)=>{ box(x-w/2,BEAMY-h/2,w,h,cols[1]); ctx.fillStyle=cols[0]; ctx.fillRect(x-w/2+6,BEAMY-h/2+6,w-12,h*0.22); ctx.fillRect(x-w/2+6,BEAMY+h/2-6-h*0.22,w-12,h*0.22);
    ctx.fillStyle=S.slab; ctx.fillRect(x-8,BEAMY+h/2,16,FLOOR-BEAMY-h/2); };
  mag(560,80,92,S.dip); mag(720,52,120,S.quad); mag(1490,52,120,S.quad);
  // 探测器 + 墙屏
  S.det.forEach((c,i)=>{ const h=120+i*60; box(1600+i*24,BEAMY-h/2,30,h,c); });
  ctx.fillStyle=S.slab; ctx.fillRect(1620,BEAMY+180,110,FLOOR-BEAMY-180);
  box(1570,CEIL+40,260,150,C.in1); event(ctx,1700,CEIL+115,63,'precise',3); txt(ctx,'探测屏',1670,BEAMY+230,18,C.sub,{align:'center'});
  // 采购终端
  box(430,FLOOR-170,70,170,S.equip); box(440,FLOOR-155,50,40,S.term); txt(ctx,'$',465,FLOOR-125,22,S.equipLine,{align:'center',mono:true}); txt(ctx,'采购终端',465,FLOOR-184,16,C.sub,{align:'center'});
  // 胶囊舱
  const cx=1100,w=560,h=300,x=cx-w/2,y=BEAMY-h/2, state={v:0.7,d:0.3,seed:21};
  ctx.fillStyle=S.slab; ctx.fillRect(cx-140,y+h,40,FLOOR-y-h); ctx.fillRect(cx+100,y+h,40,FLOOR-y-h);
  ctx.save(); ctx.beginPath(); ctx.roundRect(x,y,w,h,h/2); ctx.clip(); drawBeam(ctx,cx,BEAMY,h*0.48,state);
  ctx.fillStyle='rgba(255,255,255,0.10)'; ctx.fillRect(x,y+18,w,10); ctx.restore();
  ctx.strokeStyle=S.equipLine; ctx.lineWidth=3; ctx.beginPath(); ctx.roundRect(x,y,w,h,h/2); ctx.stroke();
  for(let i=0;i<6;i++){ const bx=x+h*0.45+i*(w-h*0.9)/5, on=i<4; box(bx-8,y-26,16,22,on?st.ramp[2]:S.equip); box(bx-8,y+h+4,16,22,on?st.ramp[2]:S.equip); }
  // 控制台
  ctx.fillStyle=S.equip; ctx.strokeStyle=S.equipLine; ctx.lineWidth=1.5; ctx.beginPath(); ctx.moveTo(880,FLOOR); ctx.lineTo(880,FLOOR-90); ctx.lineTo(1030,FLOOR-110); ctx.lineTo(1030,FLOOR); ctx.closePath(); ctx.fill(); ctx.stroke();
  [C.red,C.gold,st.ramp[2]].forEach((c,i)=>{ ctx.fillStyle=c; ctx.fillRect(900+i*20,FLOOR-84-i*2.6,12,7); });
  ctx.save(); ctx.translate(950,FLOOR-140); ctx.rotate(-0.15); box(-50,-34,100,64,C.in1); [st.ramp[2],st.ramp[3],C.gold,st.ramp[1],C.red].forEach((c,i)=>{ ctx.fillStyle=c; ctx.fillRect(-40,-24+i*11,20+((i*37)%60),4); }); ctx.restore();
  // 角色（哑光：白大褂 + 风格描边）
  ctx.save(); ctx.translate(910,FLOOR); const k=1;
  ctx.strokeStyle=S.figLine; ctx.lineWidth=7; ctx.lineCap='round'; ctx.beginPath(); ctx.moveTo(-6,-62); ctx.lineTo(-6,0); ctx.moveTo(6,-62); ctx.lineTo(6,0); ctx.stroke();
  ctx.fillStyle='#f4f1ea'; ctx.strokeStyle=S.figLine; ctx.lineWidth=2; ctx.beginPath(); ctx.moveTo(-17,-122); ctx.lineTo(17,-122); ctx.lineTo(24,-48); ctx.lineTo(-22,-48); ctx.closePath(); ctx.fill(); ctx.stroke();
  ctx.fillStyle=C.red; ctx.fillRect(5,-116,8,6);
  ctx.strokeStyle='#f4f1ea'; ctx.lineWidth=6; ctx.beginPath(); ctx.moveTo(10,-112); ctx.lineTo(30,-86); ctx.lineTo(48,-84); ctx.stroke();
  ctx.fillStyle='#3a3430'; ctx.beginPath(); ctx.arc(0,-138,14,0,7); ctx.fill(); ctx.fillStyle='#e8c9a8'; ctx.beginPath(); ctx.arc(3,-136,10,-1.2,1.6); ctx.fill(); ctx.restore();
  // 场景标签与提示
  ctx.strokeStyle=C.dim; ctx.lineWidth=1.5; ctx.beginPath(); ctx.moveTo(1300,BEAMY-160); ctx.lineTo(1340,BEAMY-200); ctx.lineTo(1470,BEAMY-200); ctx.stroke();
  txt(ctx,'E8',1346,BEAMY-260,30,st.ramp[3]===C.white?C.text:mix(st.ramp[2],C.text,0.2),{mono:true,w:700}); txt(ctx,'6,240 RP',1346,BEAMY-234,20,C.text,{mono:true}); txt(ctx,'丢失 18.4%',1346,BEAMY-208,16,C.orange,{mono:true});
  ctx.fillStyle=S.bar; ctx.strokeStyle=S.equipLine; ctx.beginPath(); ctx.roundRect(830,FLOOR-204,160,36,4); ctx.fill(); ctx.stroke(); box(838,FLOOR-197,44,22,S.term); txt(ctx,'空格',860,FLOOR-180,13,S.equipLine,{align:'center'}); txt(ctx,'继续加速',892,FLOOR-180,16,C.text);
  // 顶栏
  ctx.fillStyle=S.bar; ctx.fillRect(0,0,1920,56); ctx.fillStyle=C.line; ctx.fillRect(0,56,1920,1);
  txt(ctx,'BEAMLINE',40,38,20,C.text,{ls:8,w:500}); txt(ctx,'考核 2 / 3',600,38,20,C.text); txt(ctx,'累计 8,420 / 12,000',760,38,20,C.text,{mono:true}); txt(ctx,'剩余实验 2',1060,38,20,C.text);
  txt(ctx,st.name,1880,38,15,C.sub,{align:'right'});
  // 右下角：同风格下的能级色阶 + 三种特殊态小样
  const bx0=60, by0=FLOOR+60; ctx.fillStyle=S.bar; ctx.fillRect(bx0-20,by0-30,330,220); ctx.strokeStyle=C.line; ctx.strokeRect(bx0-20,by0-30,330,220);
  txt(ctx,'能级色阶',bx0,by0-6,15,C.sub); const gg=ctx.createLinearGradient(bx0,0,bx0+290,0); st.ramp.forEach((c,i)=>gg.addColorStop(i/4,c)); ctx.fillStyle=gg; ctx.fillRect(bx0,by0+6,290,14);
  [['锁相',{v:0.75,lock:true,seed:5},C.lock],['超负荷',{v:0.7,d:0.85,seed:4},C.red],['离谱',{v:0.7,d:0.3,weird:1,seed:6},C.gold]].forEach((q,i)=>{ const X=bx0+45+i*100, Y=by0+90;
    ctx.save(); ctx.beginPath(); ctx.arc(X,Y,42,0,7); ctx.clip(); drawBeam(ctx,X,Y,42,q[1]); ctx.restore(); ctx.strokeStyle=q[2]; ctx.lineWidth=2; ctx.beginPath(); ctx.arc(X,Y,42,0,7); ctx.stroke();
    txt(ctx,q[0],X,Y+66,14,q[2],{align:'center'}); });
}
