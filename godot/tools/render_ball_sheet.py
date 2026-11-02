from PIL import Image, ImageDraw, ImageFont
import argparse, json
from pathlib import Path
parser = argparse.ArgumentParser(description="Render shared ball glyph primitives; requires Pillow.")
parser.add_argument("input", type=Path, help="JSON from preview_ball_visuals.gd")
parser.add_argument("output", type=Path, help="Output PNG")
parser.add_argument("--font", default="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
args = parser.parse_args()
rows=json.load(args.input.open())
scale=3;w,h=1170,860
img=Image.new('RGB',(w*scale,h*scale),'#101d3d');draw=ImageDraw.Draw(img)
fontpath=args.font
font=ImageFont.truetype(fontpath,12*scale); small=ImageFont.truetype(fontpath,10*scale);title=ImageFont.truetype(fontpath,20*scale)
draw.text((18*scale,12*scale),'BALLxRONKE / shared ball glyph preview',font=title,fill='#fff1d6')
draw.text((18*scale,40*scale),'Left: unchanged 1x gameplay size   Right: 3x inspection view. These are glyph previews, not in-game screenshots.',font=small,fill='#a0b9ca')
for i,row in enumerate(rows):
 x,y=15+(i%9)*128,65+(i//9)*78
 draw.rounded_rectangle((x*scale,y*scale,(x+122)*scale,(y+72)*scale),radius=5*scale,fill='#1c3655')
 name=row['name'];name=name if len(name)<19 else name[:17]+'…'
 draw.text(((x+5)*scale,(y+5)*scale),name,font=small,fill='#fff1d6')
 for zoom,cx,cy in [(1,x+23,y+46),(3,x+83,y+46)]:
  r=row['radius']*zoom*scale;cx*=scale;cy*=scale
  draw.ellipse((cx-r-.6*scale*zoom,cy-r-.6*scale*zoom,cx+r+.6*scale*zoom,cy+r+.6*scale*zoom),fill='#101d3d')
  draw.ellipse((cx-r,cy-r,cx+r,cy+r),fill='#'+row['color'][:6])
  for mark in row['marks']:
   color=mark.get('color') or ('#101d3d' if mark.get('ink') else row['visual']['accent'])
   if mark['kind']=='circle':
    px,py=mark['center'];px,py=cx+px*r,cy+py*r;rr=mark['radius']*r
    draw.ellipse((px-rr,py-rr,px+rr,py+rr),fill=color)
   else:
    pts=[(cx+px*r,cy+py*r) for px,py in mark['points']]
    if mark['kind']=='poly':draw.polygon(pts,fill=color)
    else:draw.line(pts,fill=color,width=max(1,round(max(.8,row['radius']*.22)*zoom*scale)),joint='curve')
img.resize((w,h),Image.Resampling.LANCZOS).save(args.output)
