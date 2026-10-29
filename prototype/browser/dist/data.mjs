export const ELEMENTS={
 stone:{name:'Stone',color:'#e6c891',description:'Reliable impact damage.'},
 fire:{name:'Ember',color:'#ff935b',description:'Burns enemies for damage over time.'},
 frost:{name:'Frost',color:'#84e2fa',description:'Slows enemy descent and movement.'},
 brood:{name:'Brood',color:'#ffabd2',description:'Splits into baby orbs on impact.'},
 laser:{name:'Beam',color:'#d9b0ff',description:'Pierces one extra target.'},
 poison:{name:'Venom',color:'#b5ef87',description:'Inflicts a lasting poison.'},
 dark:{name:'Void',color:'#af9be8',description:'Critical strikes deal double damage.'},
 iron:{name:'Iron',color:'#c6d6dc',description:'Gains damage with each wall bounce.'},
 vampire:{name:'Sanguine',color:'#ff8291',description:'Hits can restore a little health.'},
 lightning:{name:'Spark',color:'#ffe984',description:'Chains damage to a nearby enemy.'},
 ghost:{name:'Wisp',color:'#d9f5e9',description:'Passes through the first target.'},
 earth:{name:'Quake',color:'#dba57b',description:'Deals splash damage around impact.'},
 light:{name:'Light',color:'#fff3b1',description:'Deals extra damage to armored targets.'},
 wind:{name:'Gale',color:'#a7e8d9',description:'Pushes enemies back up the pit.'},
 charm:{name:'Charm',color:'#ffb3e3',description:'Strikes weaken enemies briefly.'},
 egg:{name:'Spore',color:'#dfe1a0',description:'Leaves a small burst of splash damage.'},
 toxic_sun:{name:'Toxic Sun',color:'#ffd66b',description:'Evolved: burning, poisonous explosions.'},
 stormglass:{name:'Stormglass',color:'#9cfff4',description:'Evolved: freezing chain lightning.'},
 eclipse:{name:'Eclipse',color:'#e2c1ff',description:'Evolved: piercing critical blasts.'}
};
const rows=[
 ['warrior','Ronke','The Warrior','A good arm. A better attitude.','A balanced runner with 15% more impact damage.','stone'],
 ['itchy_finger','Hotshot','The Itchy Finger','Subtlety was never the plan.','Fires 65% faster, with a little extra scatter.','fire'],
 ['repentant','Blue Monday','The Repentant','Every bounce is a second chance.','Orbs gain 8% damage every time they bounce.','frost'],
 ['cohabitants','The Whole Family','The Cohabitants','Family time. With projectiles.','Launches a mirrored second orb at 60% damage.','brood'],
 ['cogitator','Professor Bonk','The Cogitator','Already thought of that.','Automatically picks upgrades; starts with a damage bonus.','laser'],
 ['embedded','Old Irons','The Embedded','Still standing. Still throwing.','All orbs pierce through their first two targets.','poison'],
 ['shade','Nightshift','The Shade','Nothing personal. Probably.','Fires down from the far end of the pit; 25% critical chance.','dark'],
 ['shieldbearer','The Wall','The Shieldbearer','Return to sender.','Nearby returning orbs rebound off the shield once for double damage.','iron'],
 ['spendthrift','Big Spender','The Spendthrift','Why throw one?','Throws a three-orb fan with each shot.','vampire'],
 ['juggler','Jinx','The Juggler','Eyes on the ball. All of them.','Orbs begin with a splash-damage landing at the aim point.','lightning'],
 ['empty_nester','Auntie Blue','The Empty Nester','Finally, some peace and chaos.','Throws three matching wisps; no baby-orb splitting.','ghost'],
 ['flagellant','Brother Bounce','The Flagellant','The floor is just another wall.','Orbs bounce off the bottom of the pit instead of returning.','egg'],
 ['makeshift_sisyphus','King Again','The Makeshift Sisyphus','Rock bottom is a starting point.','Direct hits become triple-strength area damage.','earth'],
 ['physicist','Dr. Orbit','The Physicist','An applied force of nature.','Gravity pulls orbs toward the top of the pit.','light'],
 ['tactician','The General','The Tactician','One move ahead of the mess.','Enemies advance only briefly after each of your shots.','iron'],
 ['radical','Wild Thing','The Radical','Trust the process. Mostly.','Auto-aims and automatically chooses upgrades.','wind'],
 ['falconer','Birdwatch','The Falconer','A two-bird operation.','Twin falcons launch orbs from the sides of the pit.','lightning'],
 ['carouser','Last Call','The Carouser','One more round.','Returning orbs orbit you briefly, dealing contact damage.','charm'],
 ['tunneller','Digby','The Tunneller','There is always a deeper way.','Orbs wrap between the top and bottom twice.','earth'],
 ['tiptoer','Softstep','The Tiptoer','Quiet feet. Loud impact.','Fewer hit points, but enemy shots are 40% less accurate.','laser'],
 ['hoary_hoarder','Grandpa Gold','The Hoary Hoarder','Travel light? Absolutely not.','Only five orb charges, but 65% more damage.','stone'],
 ['ballbearer','Ball Boy','The Ballbearer','Prepared for every occasion.','Starts with sixteen orb charges.','stone'],
 ['false_messiah','The Showman','The False Messiah','A very persuasive trajectory.','Every third level offers four upgrade choices. No streaming connection required.','dark']
];
export const CREW=rows.map((r,index)=>({id:r[0],name:r[1],role:r[2],tagline:r[3],perk:r[4],element:r[5],index}));
export const FUSIONS=[{id:'toxic_sun',ingredients:['fire','poison'],name:'Toxic Sun'},{id:'stormglass',ingredients:['frost','lightning'],name:'Stormglass'},{id:'eclipse',ingredients:['light','dark'],name:'Eclipse'}];
export const UPGRADES=[
 {id:'power',name:'Heavy hands',description:'All orbs deal 22% more damage.',icon:'↗',kind:'POWER'},
 {id:'haste',name:'Quick release',description:'Throw 18% faster.',icon:'»',kind:'TEMPO'},
 {id:'capacity',name:'More is more',description:'Add 2 orb charges. Refill your supply.',icon:'◉',kind:'CAPACITY'},
 {id:'vitality',name:'Heart of the jungle',description:'Gain 20 maximum health and heal 30.',icon:'♥',kind:'RECOVERY'},
 {id:'ricochet',name:'Angle of attack',description:'Every wall bounce adds 10% damage.',icon:'⌁',kind:'BOUNCE'},
 {id:'speed',name:'Light on your feet',description:'Move 15% faster. Dash recovers sooner.',icon:'➜',kind:'MOVEMENT'},
 ...['fire','frost','poison','lightning','light','dark','earth','vampire','brood'].map(id=>({id:'element_'+id,name:ELEMENTS[id].name+' orb',description:ELEMENTS[id].description+' Add it to your throws.',icon:'●',kind:'NEW ORB',element:id}))
];
export const WORLDS=[{name:'The Verdant Ruins',subtitle:'Where the jungle swallowed the old world.',color:'#68bba1'},{name:'The Ember Vault',subtitle:'Something down here is still burning.',color:'#f2a66f'},{name:'The Astral Hollow',subtitle:'The last light falls a little differently.',color:'#b6b4ec'}];
