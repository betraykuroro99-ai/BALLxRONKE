"""Bundle the static app into a single local HTML file without module fetches."""
from pathlib import Path
import base64
import json
import mimetypes
import re
import zipfile

ROOT=Path(__file__).parent
DIST=ROOT/'dist'
assets={}
for file in sorted((DIST/'assets').rglob('*')):
    if file.is_file():
        mime=mimetypes.guess_type(file.name)[0] or 'application/octet-stream'
        assets[file.relative_to(DIST).as_posix()]='data:'+mime+';base64,'+base64.b64encode(file.read_bytes()).decode()
code='\n'.join((DIST/file).read_text() for file in ['data.mjs','engine.mjs','renderer.mjs','app.mjs'])
code=re.sub(r'^import .*?;\s*$', '', code, flags=re.M)
code=re.sub(r'\bexport (?=(?:const|class|function)\b)', '', code)
code=re.sub(r'(\.src\s*=\s*)(`assets/[^`]+`|\'assets/[^\']+\'|"assets/[^\"]+")',r'\1asset(\2)',code)
code=re.sub(r'src="(assets/[^\"]+)"',lambda m:'src="${asset(`'+m[1]+'`)}"',code)
code='const ASSETS='+json.dumps(assets)+';\nconst asset=p=>ASSETS[p]||p;\n'+code
style=re.sub(r"@import url\([^;]+;", '', (DIST/'style.css').read_text())
for name,url in assets.items():style=style.replace("url('"+name+"')","url('"+url+"')")
html=(DIST/'index.html').read_text().replace('<link rel="stylesheet" href="style.css">','<style>'+style+'</style>')
html=html.replace('<script type="module" src="app.mjs"></script>','<script>\n(()=>{\n'+code.replace('</script','<\\/script')+'\n})();\n</script>')
for name,url in assets.items():html=html.replace('src="'+name+'"','src="'+url+'"').replace('href="'+name+'"','href="'+url+'"')
output=ROOT.parent.parent/'ronke-orbfall-play.html'
output.write_text(html)
with zipfile.ZipFile(ROOT.parent.parent/'ronke-orbfall-source.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for p in sorted(ROOT.rglob('*')):
        if p.is_file() and '.git' not in p.parts and '__pycache__' not in p.parts and 'qa' not in p.parts:
            archive.write(p,Path('ronke-orbfall')/p.relative_to(ROOT))
print('Offline game:',output,'('+str(output.stat().st_size)+' bytes)')
