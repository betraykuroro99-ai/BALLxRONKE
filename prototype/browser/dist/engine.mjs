import {CREW,ELEMENTS,FUSIONS,UPGRADES} from './data.mjs';
export const WIDTH=600, HEIGHT=820, LAST_WAVE=10;
export const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const norm=(x,y)=>{const d=Math.hypot(x,y)||1;return{x:x/d,y:y/d}};
export function seeded(seed){let a=seed>>>0;return()=>{a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
export class Run {
 constructor({crewId='warrior',world=0,seed=Date.now(),meta={}}={}){
  this.crew=CREW.find(c=>c.id===crewId)||CREW[0];this.world=clamp(world,0,2);this.seed=seed;this.rng=seeded(seed);this.phase='playing';this.time=0;this.wave=0;this.waveClock=0;this.nextWave=0;this.id=0;this.balls=[];this.enemies=[];this.bullets=[];this.events=[];this.kills=0;this.bounces=0;this.combo=0;this.bestCombo=0;this.comboTime=0;this.level=1;this.xp=0;this.xpNeed=10;this.choices=[];this.upgradeClock=0;this.surge=0;this.surgeTime=0;this.turnTime=0;this.reward=0;this.picks=[];
  const c=this.crew.id,health=(c==='tiptoer'?65:c==='shieldbearer'?140:100)+clamp(meta.vitality||0,0,3)*10;
  const capacity=(c==='hoary_hoarder'?5:c==='ballbearer'?16:9)+clamp(meta.reserves||0,0,3);
  this.player={x:300,y:750,hp:health,maxHp:health,ammo:capacity,capacity,hurt:0,shoot:0,dash:0,dashCd:0,moving:false,invincible:0};
  this.stats={damage:(c==='warrior'?1.15:c==='hoary_hoarder'?1.65:c==='cogitator'?1.2:1)*(1+clamp(meta.power||0,0,3)*.05),interval:c==='itchy_finger'?.17:.28,speed:250,bounce:0};
  this.elements=[this.crew.element];this.elementLevels={[this.crew.element]:1};this.shotClock=0;this.shotCount=0;this.spawnWave();
 }
 emit(type,data={}){this.events.push({type,...data});if(this.events.length>180)this.events.shift()}
 drain(){return this.events.splice(0)}
 advance(dt,input={}){
  dt=clamp(dt,0,.1);
  if(this.phase==='upgrade'){
   if(['cogitator','radical'].includes(this.crew.id)){this.upgradeClock+=dt;if(this.upgradeClock>.9)this.chooseUpgrade(0)}
   return;
  }
  if(this.phase!=='playing')return;
  const count=Math.max(1,Math.ceil(dt/(1/120))),step=dt/count;
  for(let i=0;i<count&&this.phase==='playing';i++)this.step(step,input);
 }
 spawnWave(){
  this.wave++;this.waveClock=0;this.nextWave=0;const boss=this.wave%5===0;
  const rows=boss?1:Math.min(3,1+Math.floor(this.wave/3));
  for(let row=0;row<rows;row++)for(let col=0;col<8;col++){
   if(this.rng()<.17&&!boss)continue;
   const r=this.rng(),kind=r<.16?'prism':r<.33?'granite':r<.47?'swift':'moss';
   const size=kind==='swift'?37:kind==='granite'?55:47;
   const hp=(18+this.wave*7+this.world*5)*(kind==='granite'?1.7:kind==='swift'?.7:1);
   this.enemies.push({id:++this.id,x:55+col*70,y:65+row*66,size,hp,maxHp:hp,kind,speed:kind==='swift'?15:7+this.wave*.6,fire:2+this.rng()*4,burn:0,poison:0,slow:0,weak:0,dead:false,flash:0});
  }
  if(boss){const hp=(this.wave===5?420:900)*(1+this.world*.15);this.enemies.push({id:++this.id,x:300,y:120,size:110,hp,maxHp:hp,kind:'boss',speed:5,fire:2,burn:0,poison:0,slow:0,weak:0,dead:false,flash:0})}
  this.emit('wave',{wave:this.wave,boss});
 }
 step(dt,input){
  this.time+=dt;this.waveClock+=dt;this.comboTime-=dt;if(this.comboTime<=0)this.combo=0;
  const p=this.player,c=this.crew.id;
  p.hurt=Math.max(0,p.hurt-dt);p.shoot=Math.max(0,p.shoot-dt);p.invincible=Math.max(0,p.invincible-dt);p.dashCd=Math.max(0,p.dashCd-dt);p.dash=Math.max(0,p.dash-dt);this.surgeTime=Math.max(0,this.surgeTime-dt);this.turnTime=Math.max(0,this.turnTime-dt);
  let mx=clamp(input.moveX||0,-1,1),my=clamp(input.moveY||0,-1,1);if(Math.hypot(mx,my)>1){const n=norm(mx,my);mx=n.x;my=n.y}p.moving=Math.hypot(mx,my)>.05;
  if(input.dash&&p.dashCd<=0){p.dash=.18;p.dashCd=3.5;p.invincible=Math.max(p.invincible,.25);const n=norm(mx||((input.aimX??p.x)>p.x?1:-1),my);p.dashX=n.x;p.dashY=n.y;this.emit('dash',{x:p.x,y:p.y})}
  const speed=this.stats.speed*(p.dash>0?3:1);
  p.x=clamp(p.x+(p.dash>0?p.dashX:mx)*speed*dt,25,WIDTH-25);p.y=clamp(p.y+(p.dash>0?p.dashY:my)*speed*dt,HEIGHT-190,HEIGHT-32);
  if(input.surge&&this.surge>=100){this.surge=0;this.surgeTime=4;p.invincible=1.2;p.hp=Math.min(p.maxHp,p.hp+6);for(let i=0;i<16;i++){const a=-Math.PI+i/16*Math.PI*2;this.addBall(p.x,p.y,Math.cos(a),Math.sin(a),this.elements[i%this.elements.length],1.5,false)}this.emit('surge',{x:p.x,y:p.y})}
  this.shotClock-=dt;
  if((input.shoot||c==='radical')&&this.shotClock<=0&&p.ammo>0&&this.balls.length<90){this.shoot(input);this.shotClock=Math.max(.08,this.stats.interval)}
  const worldDt=dt*(this.surgeTime>0?.55:1)*(c==='tactician'&&this.turnTime<=0?0:1);
  for(const e of this.enemies){
   if(e.dead)continue;e.flash=Math.max(0,e.flash-dt);e.burn=Math.max(0,e.burn-dt);e.poison=Math.max(0,e.poison-dt);e.slow=Math.max(0,e.slow-dt);e.weak=Math.max(0,e.weak-dt);
   if(e.burn>0||e.poison>0){e.hp-=(e.burn>0?4:0)*this.stats.damage*dt+(e.poison>0?3.5:0)*this.stats.damage*dt;if(e.hp<=0){this.kill(e);continue}}
   e.y+=e.speed*worldDt*(e.slow>0?.35:1);
   if(e.kind==='boss')e.x=300+Math.sin(this.time*.65)*140;
   if(e.y+e.size/2>HEIGHT-120){this.hurt(e.kind==='boss'?28:10,e.x,e.y);e.dead=true;this.emit('breach',{x:e.x,y:e.y})}
   if(e.kind==='prism'||e.kind==='boss'){
    e.fire-=worldDt;
    if(e.fire<=0){e.fire=e.kind==='boss'?1.5:4.5;const n=norm(p.x-e.x,p.y-e.y),spread=c==='tiptoer'?.6:.12;const a=Math.atan2(n.y,n.x)+(this.rng()-.5)*spread;
     const count=e.kind==='boss'?3:1;for(let i=0;i<count;i++){const angle=a+(i-(count-1)/2)*.21;this.bullets.push({x:e.x,y:e.y,vx:Math.cos(angle)*145,vy:Math.sin(angle)*145,r:e.kind==='boss'?7:5,damage:e.weak>0?5:10})}
    }
   }
  }
  for(const bullet of this.bullets){bullet.x+=bullet.vx*worldDt;bullet.y+=bullet.vy*worldDt;if(Math.hypot(bullet.x-p.x,bullet.y-p.y)<22+bullet.r){this.hurt(bullet.damage,bullet.x,bullet.y);bullet.dead=true}if(bullet.y>HEIGHT+20||bullet.x<0||bullet.x>WIDTH||bullet.y<0)bullet.dead=true}
  for(const b of [...this.balls]){
   if(b.dead)continue;b.life-=dt;if(b.life<=0){this.returnBall(b);continue}
   if(b.orbit){b.orbitTime+=dt;b.x=p.x+Math.cos(b.orbitTime*9+b.angle)*46;b.y=p.y+Math.sin(b.orbitTime*9+b.angle)*30;if(b.orbitTime>1.1){this.returnBall(b);continue}}
   else{
    if(c==='physicist')b.vy-=165*dt;
    const velocity=Math.hypot(b.vx,b.vy);if(velocity>880){b.vx*=880/velocity;b.vy*=880/velocity}
    b.x+=b.vx*dt;b.y+=b.vy*dt;
    if(b.x<16+b.r){b.x=16+b.r;b.vx=Math.abs(b.vx);this.wall(b)}else if(b.x>WIDTH-16-b.r){b.x=WIDTH-16-b.r;b.vx=-Math.abs(b.vx);this.wall(b)}
    if(b.y<22+b.r){if(c==='tunneller'&&b.wraps<2){b.y=HEIGHT-45;b.wraps++}else{b.y=22+b.r;b.vy=Math.abs(b.vy);this.wall(b)}}
    if(c==='shieldbearer'&&!b.shield&&b.vy>0&&Math.hypot(b.x-p.x,b.y-p.y)<78){b.shield=true;b.vy=-Math.abs(b.vy);b.damage*=2;this.emit('shield',{x:b.x,y:b.y})}
    if(c==='carouser'&&!b.orbit&&b.vy>0&&Math.hypot(b.x-p.x,b.y-p.y)<80){b.orbit=true;b.orbitTime=0;b.angle=Math.atan2(b.y-p.y,b.x-p.x)}
    if(b.y>HEIGHT-16){if(c==='flagellant'){b.y=HEIGHT-17;b.vy=-Math.abs(b.vy);this.wall(b)}else if(c==='tunneller'&&b.wraps<2){b.y=35;b.wraps++}else{this.returnBall(b);continue}}
   }
   for(const e of this.enemies){
    if(e.dead||b.dead||(b.hits[e.id]??-10)>this.time-.16)continue;
    const half=e.size/2,qx=clamp(b.x,e.x-half,e.x+half),qy=clamp(b.y,e.y-half,e.y+half),dx=b.x-qx,dy=b.y-qy;
    if(dx*dx+dy*dy>b.r*b.r)continue;
    b.hits[e.id]=this.time;this.hit(e,b);
    if(b.pierce>0){b.pierce--;continue}
    if(b.orbit)continue;
    let n=norm(dx,dy);
    if(dx===0&&dy===0){const faces=[{d:b.x-(e.x-half),x:-1,y:0},{d:e.x+half-b.x,x:1,y:0},{d:b.y-(e.y-half),x:0,y:-1},{d:e.y+half-b.y,x:0,y:1}].sort((a,z)=>a.d-z.d);n=faces[0]}
    const dot=b.vx*n.x+b.vy*n.y;if(dot<0){b.vx-=2*dot*n.x;b.vy-=2*dot*n.y}
    if(n.x)b.x=(n.x<0?e.x-half-b.r-1:e.x+half+b.r+1);if(n.y)b.y=(n.y<0?e.y-half-b.r-1:e.y+half+b.r+1);
   }
  }
  this.balls=this.balls.filter(b=>!b.dead);this.enemies=this.enemies.filter(e=>!e.dead);this.bullets=this.bullets.filter(b=>!b.dead);
  if(this.phase!=='playing')return;
  if(!this.enemies.length){this.nextWave+=dt;if(this.nextWave>1.6){if(this.wave===LAST_WAVE)this.finish(true);else this.spawnWave()}}
  else if(this.waveClock>17&&this.wave<LAST_WAVE&&this.enemies.length<46)this.spawnWave();
 }
 shoot(input){
  const p=this.player,c=this.crew.id;let ax=input.aimX??p.x,ay=input.aimY??100;
  if(c==='radical'){const e=this.enemies.filter(e=>!e.dead).sort((a,b)=>b.y-a.y)[0];if(e){ax=e.x;ay=e.y}}
  let ox=p.x,oy=p.y-22;if(c==='shade'){oy=35;ax=input.aimX??300;ay=Math.max(100,input.aimY??350)}
  const n=norm(ax-ox,c==='shade'?Math.max(20,ay-oy):Math.min(-35,ay-oy));let angle=Math.atan2(n.y,n.x);
  if(c==='itchy_finger')angle+=(this.rng()-.5)*.24;
  const type=this.elements[this.shotCount%this.elements.length];p.ammo--;p.shoot=.21;this.turnTime=.16;this.shotCount++;
  if(c==='juggler'){oy=clamp(ay,80,HEIGHT-220);ox=clamp(ax,45,WIDTH-45);this.splash(ox,oy,60,12*this.stats.damage)}
  if(c==='falconer'){
   for(const x of [30,WIDTH-30]){const v=norm(ax-x,Math.min(-35,ay-(p.y-35)));this.addBall(x,p.y-35,v.x,v.y,type,.7,x===30)}
  }else{
   this.addBall(ox,oy,Math.cos(angle),Math.sin(angle),type,c==='cohabitants'?.6:1,true);
   if(c==='cohabitants')this.addBall(ox,oy,-Math.cos(angle),Math.sin(angle),type,.6,false);
   if(['spendthrift','empty_nester'].includes(c))for(const d of [-.15,.15])this.addBall(ox,oy,Math.cos(angle+d),Math.sin(angle+d),type,.7,false);
  }
  this.emit('shot',{x:ox,y:oy,type});
 }
 addBall(x,y,dx,dy,type,mult=1,refund=true){
  if(this.balls.length>=96)return;
  const speed=560+(this.crew.id==='itchy_finger'?40:0),pierce=this.crew.id==='embedded'?2:['laser','ghost','eclipse'].includes(type)?1:0;
  this.balls.push({id:++this.id,x,y,vx:dx*speed,vy:dy*speed,r:5.5,type,damage:15*this.stats.damage*mult*(1+((this.elementLevels[type]||1)-1)*.15),pierce,life:8,refund,wraps:0,shield:false,orbit:false,hits:{},bounces:0,child:!refund,dead:false});
 }
 wall(b){this.bounces++;b.bounces++;b.damage=Math.min(200,b.damage*(1+this.stats.bounce+(this.crew.id==='repentant'?.08:0)+(b.type==='iron'?.04:0)));this.emit('bounce',{x:b.x,y:b.y,color:ELEMENTS[b.type].color});if(b.bounces>28)this.returnBall(b)}
 returnBall(b){if(b.dead)return;b.dead=true;if(b.refund)this.player.ammo=Math.min(this.player.capacity,this.player.ammo+1)}
 hit(e,b){
  const type=b.type,c=this.crew.id;let damage=b.damage;
  const crit=this.rng()<(c==='shade'?.25:['dark','eclipse'].includes(type)?.18:.04);if(crit)damage*=2;
  if(type==='light'&&e.kind==='granite')damage*=1.6;
  this.damage(e,c==='makeshift_sisyphus'?0:damage,crit);
  if(['fire','toxic_sun'].includes(type))e.burn=3;
  if(['poison','toxic_sun'].includes(type))e.poison=4;
  if(['frost','stormglass'].includes(type))e.slow=3;
  if(type==='wind')e.y=Math.max(30,e.y-(e.kind==='boss'?3:14));
  if(type==='charm')e.weak=4;
  if(type==='vampire')this.player.hp=Math.min(this.player.maxHp,this.player.hp+.5);
  if(['earth','egg','toxic_sun','eclipse'].includes(type)||c==='makeshift_sisyphus')this.splash(e.x,e.y,c==='makeshift_sisyphus'?75:53,damage*(c==='makeshift_sisyphus'?3:type==='toxic_sun'?1.1:.55));
  if(['lightning','stormglass'].includes(type)){const next=this.enemies.filter(t=>t!==e&&!t.dead&&Math.hypot(t.x-e.x,t.y-e.y)<125).sort((a,z)=>Math.hypot(a.x-e.x,a.y-e.y)-Math.hypot(z.x-e.x,z.y-e.y))[0];if(next){this.damage(next,damage*.65);if(type==='stormglass')next.slow=2;this.emit('chain',{x:e.x,y:e.y,x2:next.x,y2:next.y})}}
  if(type==='brood'&&!b.child&&c!=='empty_nester'){b.child=true;for(const d of [-.7,.7]){const a=Math.atan2(b.vy,b.vx)+d;this.addBall(b.x,b.y,Math.cos(a),Math.sin(a),'stone',.35,false)}}
  this.emit('hit',{x:b.x,y:b.y,color:ELEMENTS[type].color,crit});
 }
 damage(e,value,crit=false){if(e.dead||value<=0)return;e.hp-=value;e.flash=.08;this.emit('damage',{x:e.x,y:e.y,value:Math.round(value),crit});if(e.hp<=0)this.kill(e)}
 splash(x,y,r,damage){for(const e of this.enemies)if(!e.dead&&Math.hypot(e.x-x,e.y-y)<r+e.size*.3)this.damage(e,damage);this.emit('splash',{x,y,r})}
 kill(e){if(e.dead)return;e.dead=true;this.kills++;this.combo++;this.comboTime=1.8;this.bestCombo=Math.max(this.bestCombo,this.combo);this.surge=clamp(this.surge+(e.kind==='boss'?30:5),0,100);this.xp+=e.kind==='boss'?12:e.kind==='granite'?3:2;this.emit('kill',{x:e.x,y:e.y,kind:e.kind});this.checkLevel()}
 checkLevel(){if(this.phase!=='playing'||this.xp<this.xpNeed)return;this.xp-=this.xpNeed;this.level++;this.xpNeed=8+this.level*4;this.phase='upgrade';this.upgradeClock=0;this.choices=this.getChoices();this.emit('level',{level:this.level,auto:['cogitator','radical'].includes(this.crew.id)})}
 getChoices(){
  const pool=UPGRADES.filter(u=>!u.element||!this.elements.includes(u.element)).map(u=>({...u}));
  for(const f of FUSIONS)if(f.ingredients.every(i=>this.elements.includes(i))&&!this.elements.includes(f.id))pool.unshift({id:'fusion_'+f.id,name:f.name,description:ELEMENTS[f.id].description,icon:'✦',kind:'EVOLUTION',fusion:f.id});
  const fusion=pool.find(u=>u.fusion),choices=[];if(fusion)choices.push(fusion);
  const shuffled=pool.filter(u=>u!==fusion);for(let i=shuffled.length-1;i>0;i--){const j=Math.floor(this.rng()*(i+1));[shuffled[i],shuffled[j]]=[shuffled[j],shuffled[i]]}
  const count=this.crew.id==='false_messiah'&&this.level%3===0?4:3;return [...choices,...shuffled].slice(0,count);
 }
 chooseUpgrade(index){
  if(this.phase!=='upgrade'||!this.choices[index])return false;
  const u=this.choices[index],p=this.player;
  if(u.id==='power')this.stats.damage*=1.22;
  if(u.id==='haste')this.stats.interval=Math.max(.08,this.stats.interval*.82);
  if(u.id==='capacity'){p.capacity+=2;p.ammo=p.capacity}
  if(u.id==='vitality'){p.maxHp+=20;p.hp=Math.min(p.maxHp,p.hp+30)}
  if(u.id==='ricochet')this.stats.bounce+=.1;
  if(u.id==='speed'){this.stats.speed=Math.min(440,this.stats.speed*1.15);p.dashCd=Math.max(0,p.dashCd-.75)}
  if(u.element){this.elements.push(u.element);this.elementLevels[u.element]=1}
  if(u.fusion){const f=FUSIONS.find(f=>f.id===u.fusion);this.elements=this.elements.filter(t=>!f.ingredients.includes(t));this.elements.push(f.id);this.elementLevels[f.id]=2}
  this.picks.push(u.name);this.choices=[];this.phase='playing';this.emit('upgrade',{name:u.name,fusion:!!u.fusion});this.checkLevel();return true;
 }
 hurt(value,x,y){const p=this.player;if(p.invincible>0||this.phase==='defeat'||this.phase==='victory')return;p.hp=Math.max(0,p.hp-value);p.hurt=.4;p.invincible=.85;this.emit('hurt',{x:x??p.x,y:y??p.y,value});if(p.hp<=0)this.finish(false)}
 finish(win){if(['victory','defeat'].includes(this.phase))return;this.phase=win?'victory':'defeat';this.reward=Math.floor(this.kills*.45+this.wave*2+(win?30:0));this.emit('end',{win,reward:this.reward})}
}
