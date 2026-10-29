import {WIDTH,HEIGHT,clamp} from './engine.mjs';
import {ELEMENTS} from './data.mjs';
const palette=['#8cbd90','#cca574','#bdacdf'];
export class Renderer {
 constructor(canvas){this.canvas=canvas;this.ctx=canvas.getContext('2d');this.sprite=null;this.particles=[];this.labels=[];this.rings=[];this.chains=[];this.shake=0;this.reduced=globalThis.matchMedia?.('(prefers-reduced-motion: reduce)').matches||false;this.lastFrame=0}
 load(crew){const img=new Image();img.src=`assets/crew/${crew.id}.png`;this.sprite=img}
 event(e){
  if(['hit','kill','hurt','dash','surge','shield'].includes(e.type)){
   const count=e.type==='kill'?11:e.type==='surge'?35:5,color=e.color||(e.type==='hurt'?'#f59a81':e.type==='kill'?'#b7d58e':'#efc17c');
   if(!this.reduced)for(let i=0;i<count;i++){const a=Math.random()*Math.PI*2,s=35+Math.random()*130;this.particles.push({x:e.x,y:e.y,vx:Math.cos(a)*s,vy:Math.sin(a)*s,life:.25+Math.random()*.4,max:.65,color,size:2+Math.random()*3})}
   if(e.type==='hurt')this.shake=7;if(e.type==='surge'){this.shake=6;this.rings.push({x:e.x,y:e.y,r:30,life:.8,color:'#efcc8b'})}
  }
  if(e.type==='damage'&&this.labels.length<60)this.labels.push({x:e.x+(Math.random()-.5)*20,y:e.y-20,text:String(e.value),crit:e.crit,life:.65});
  if(['splash','shield'].includes(e.type))this.rings.push({x:e.x,y:e.y,r:e.r||50,life:.25,color:e.type==='shield'?'#c8dce0':'#d9bc83'});
  if(e.type==='chain')this.chains.push({...e,life:.13});
  if(this.particles.length>220)this.particles.splice(0,this.particles.length-220);
 }
 draw(run,input,dt){
  const ctx=this.ctx,t=run.time,p=run.player,accent=palette[run.world];ctx.save();ctx.clearRect(0,0,WIDTH,HEIGHT);
  this.shake=Math.max(0,this.shake-dt*28);if(this.shake&&!this.reduced)ctx.translate((Math.random()-.5)*this.shake,(Math.random()-.5)*this.shake);
  const bg=ctx.createLinearGradient(0,0,0,HEIGHT);bg.addColorStop(0,run.world===1?'#27251d':run.world===2?'#242735':'#142d26');bg.addColorStop(1,'#10211f');ctx.fillStyle=bg;ctx.fillRect(0,0,WIDTH,HEIGHT);
  // Worn temple paving and side walls.
  ctx.strokeStyle='#78967a0b';ctx.lineWidth=1;for(let y=-40;y<HEIGHT;y+=66){ctx.beginPath();ctx.moveTo(18,y);ctx.lineTo(WIDTH-18,y);ctx.stroke();for(let x=(Math.floor(y/66)%2)*60+22;x<WIDTH;x+=118){ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(x,y+66);ctx.stroke()}}
  for(let i=0;i<60;i++){const x=24+(i*139.1)%550,y=(i*83.4+t*1.4)%HEIGHT;ctx.fillStyle=accent+'12';ctx.fillRect(x,y,1.5,1.5)}
  const vignette=ctx.createRadialGradient(300,380,90,300,420,510);vignette.addColorStop(0,'#0000');vignette.addColorStop(1,'#0005');ctx.fillStyle=vignette;ctx.fillRect(0,0,WIDTH,HEIGHT);
  ctx.fillStyle='#2d4638';ctx.fillRect(0,0,12,HEIGHT);ctx.fillRect(WIDTH-12,0,12,HEIGHT);ctx.fillStyle='#60734e';ctx.fillRect(12,0,2,HEIGHT);ctx.fillRect(WIDTH-14,0,2,HEIGHT);
  for(let y=28;y<HEIGHT;y+=75){ctx.fillStyle='#8b9d6560';ctx.fillRect(3,y,6,18);ctx.fillRect(WIDTH-9,y,6,18);ctx.fillStyle='#0a1814';ctx.fillRect(0,y+34,12,2);ctx.fillRect(WIDTH-12,y+34,12,2)}
  ctx.save();ctx.setLineDash([4,10]);ctx.strokeStyle='#e1a08244';ctx.beginPath();ctx.moveTo(20,HEIGHT-120);ctx.lineTo(WIDTH-20,HEIGHT-120);ctx.stroke();ctx.restore();ctx.fillStyle='#bb89775c';ctx.font='8px "DM Sans",sans-serif';ctx.textAlign='right';ctx.fillText('HOLD THE LINE',WIDTH-26,HEIGHT-128);
  if(run.phase==='playing'){
   const ax=input.aimX??p.x,ay=input.aimY??100,d=Math.hypot(ax-p.x,ay-p.y)||1,len=Math.min(200,d);ctx.save();ctx.setLineDash([2,11]);ctx.strokeStyle='#f0d6a14d';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(p.x,p.y-20);ctx.lineTo(p.x+(ax-p.x)/d*len,p.y-20+(ay-p.y)/d*len);ctx.stroke();ctx.restore();
  }
  for(const e of run.enemies)this.enemy(e,t,accent);
  for(const b of run.bullets){ctx.shadowBlur=9;ctx.shadowColor='#df9ba3';ctx.fillStyle='#df9ba3';ctx.beginPath();ctx.arc(b.x,b.y,b.r,0,Math.PI*2);ctx.fill();ctx.shadowBlur=0;ctx.fillStyle='#fff5e8';ctx.beginPath();ctx.arc(b.x-1,b.y-1,b.r*.35,0,Math.PI*2);ctx.fill()}
  for(const b of run.balls){const color=ELEMENTS[b.type].color;ctx.save();ctx.strokeStyle=color+'35';ctx.lineWidth=b.r*1.2;ctx.lineCap='round';ctx.beginPath();ctx.moveTo(b.x-b.vx*.025,b.y-b.vy*.025);ctx.lineTo(b.x,b.y);ctx.stroke();ctx.shadowBlur=this.reduced?0:11;ctx.shadowColor=color;ctx.fillStyle=color;ctx.beginPath();ctx.arc(b.x,b.y,b.r,0,Math.PI*2);ctx.fill();ctx.shadowBlur=0;ctx.fillStyle='#fff8e7';ctx.beginPath();ctx.arc(b.x-1.3,b.y-1.3,1.9,0,Math.PI*2);ctx.fill();ctx.restore()}
  // Use the checked eight-frame character strips, never a drawn replacement.
  ctx.save();ctx.fillStyle='#0004';ctx.beginPath();ctx.ellipse(p.x,p.y+27,29,8,0,0,Math.PI*2);ctx.fill();
  if(p.invincible>0){ctx.strokeStyle='#f1c78177';ctx.lineWidth=2;ctx.beginPath();ctx.ellipse(p.x,p.y,43,48,0,0,Math.PI*2);ctx.stroke()}
  let frame=0;if(run.phase==='defeat')frame=7;else if(p.hurt>.07)frame=6;else if(p.shoot>0)frame=p.shoot>.15?1:p.shoot>.08?2:3;else if(p.moving||p.dash>0)frame=4+Math.floor(t*7)%2;
  this.lastFrame=frame;
  if(p.invincible>0&&!this.reduced)ctx.globalAlpha=.7+Math.sin(t*30)*.3;
  if(this.sprite?.complete&&this.sprite.naturalWidth)ctx.drawImage(this.sprite,frame*128,0,128,128,p.x-84,p.y-127,168,168);
  ctx.restore();
  if(p.dashCd>0){ctx.strokeStyle='#e9c98e65';ctx.lineWidth=2;ctx.beginPath();ctx.arc(p.x,p.y+28,18,-Math.PI/2,-Math.PI/2+Math.PI*2*(1-p.dashCd/3.5));ctx.stroke()}
  for(const particle of this.particles){particle.life-=dt;particle.x+=particle.vx*dt;particle.y+=particle.vy*dt;particle.vy+=90*dt;ctx.globalAlpha=clamp(particle.life/.4,0,1);ctx.fillStyle=particle.color;ctx.fillRect(particle.x,particle.y,particle.size,particle.size)}ctx.globalAlpha=1;this.particles=this.particles.filter(p=>p.life>0);
  for(const ring of this.rings){ring.life-=dt;ctx.globalAlpha=clamp(ring.life*3,0,.6);ctx.strokeStyle=ring.color;ctx.lineWidth=2;ctx.beginPath();ctx.arc(ring.x,ring.y,ring.r*(1.2-ring.life),0,Math.PI*2);ctx.stroke()}ctx.globalAlpha=1;this.rings=this.rings.filter(r=>r.life>0);
  for(const chain of this.chains){chain.life-=dt;ctx.strokeStyle='#eaffd9';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(chain.x,chain.y);ctx.lineTo((chain.x+chain.x2)/2+8,(chain.y+chain.y2)/2-8);ctx.lineTo(chain.x2,chain.y2);ctx.stroke()}this.chains=this.chains.filter(c=>c.life>0);
  for(const label of this.labels){label.life-=dt;label.y-=35*dt;ctx.globalAlpha=clamp(label.life*2,0,1);ctx.fillStyle=label.crit?'#ffe3a1':'#f5f0db';ctx.font=`${label.crit?'bold 20px':'14px'} "Barlow Condensed",sans-serif`;ctx.textAlign='center';ctx.fillText(label.text+(label.crit?'!':''),label.x,label.y)}ctx.globalAlpha=1;this.labels=this.labels.filter(l=>l.life>0);
  if(run.combo>2&&run.comboTime>0){ctx.textAlign='center';ctx.font='700 20px "Barlow Condensed",sans-serif';ctx.fillStyle='#e6c68f';ctx.fillText(run.combo+'× COMBO',300,HEIGHT-177)}
  ctx.restore();
 }
 enemy(e,t,accent){
  const ctx=this.ctx,s=e.size,half=s/2;ctx.save();ctx.translate(e.x,e.y);if(e.kind==='swift')ctx.rotate(Math.sin(t*2+e.id)*.06);
  ctx.fillStyle='#0004';ctx.beginPath();ctx.ellipse(0,half+4,half*.9,7,0,0,Math.PI*2);ctx.fill();
  const fill=e.flash>0?'#f4edc9':e.kind==='boss'?'#7d8162':e.kind==='granite'?'#9a8261':e.kind==='prism'?'#837b9b':e.kind==='swift'?'#a4a76c':'#64866c';
  ctx.fillStyle=fill;ctx.strokeStyle='#0c1a16';ctx.lineWidth=3;ctx.beginPath();ctx.roundRect(-half,-half,s,s,e.kind==='boss'?20:7);ctx.fill();ctx.stroke();
  ctx.strokeStyle='#ffffff18';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(-half+7,-half+8);ctx.lineTo(half-8,-half+8);ctx.stroke();
  if(e.kind==='granite'){ctx.strokeStyle='#514631';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(-half+4,-half+5);ctx.lineTo(-5,-3);ctx.lineTo(-13,half-3);ctx.moveTo(-5,-3);ctx.lineTo(half-3,6);ctx.stroke();ctx.fillStyle='#bdad7c';ctx.fillRect(half-13,-half+8,6,6)}
  else if(e.kind==='prism'){ctx.fillStyle='#dab8f4';ctx.beginPath();ctx.moveTo(0,-half+6);ctx.lineTo(half-8,0);ctx.lineTo(0,half-6);ctx.lineTo(-half+8,0);ctx.closePath();ctx.fill();ctx.strokeStyle='#f3dafa';ctx.lineWidth=1;ctx.stroke()}
  else{ctx.fillStyle=e.kind==='boss'?'#485f3e':'#91ad6b';ctx.beginPath();ctx.roundRect(-half-2,-half-2,s*.6,9,4);ctx.fill();ctx.beginPath();ctx.ellipse(half-6,-half+4,8,4,.5,0,Math.PI*2);ctx.fill();ctx.strokeStyle='#36543b';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(-half+9,-half+9);ctx.lineTo(-half+4,-3);ctx.stroke()}
  if(e.kind!=='prism'){
   const eye=e.kind==='boss'?10:4,spread=e.kind==='boss'?22:10;ctx.fillStyle='#0b211a';for(const x of [-spread,spread]){ctx.beginPath();ctx.ellipse(x,-3,eye,eye*1.15,0,0,Math.PI*2);ctx.fill();ctx.fillStyle=e.kind==='boss'?'#f6c77c':'#dfe7b9';ctx.beginPath();ctx.arc(x+1,0,eye*.35,0,Math.PI*2);ctx.fill();ctx.fillStyle='#0b211a'}ctx.strokeStyle='#243d28';ctx.lineWidth=e.kind==='boss'?4:2;ctx.beginPath();ctx.moveTo(-7,half*.44);ctx.lineTo(7,half*.44);ctx.stroke();
  }
  if(e.burn>0||e.poison>0||e.slow>0||e.weak>0){ctx.strokeStyle=e.slow>0?'#8ee5ed':e.poison>0?'#b3e589':e.burn>0?'#ffc18a':'#ffbee3';ctx.lineWidth=2;ctx.beginPath();ctx.roundRect(-half-3,-half-3,s+6,s+6,9);ctx.stroke()}
  if(e.hp<e.maxHp||e.kind==='boss'){ctx.fillStyle='#0a1813';ctx.fillRect(-half,half+8,s,4);ctx.fillStyle=e.kind==='boss'?'#e6ba7a':accent;ctx.fillRect(-half,half+8,s*clamp(e.hp/e.maxHp,0,1),4)}
  if(e.kind==='boss'){ctx.font='8px "DM Sans",sans-serif';ctx.textAlign='center';ctx.fillStyle='#efdfbc';ctx.fillText(e.maxHp>600?'THE ROOT OF IT ALL':'THE GATEKEEPER',0,-half-12)}
  ctx.restore();
 }
}
