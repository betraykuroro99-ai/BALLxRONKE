import http from 'node:http';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
const root=path.resolve('dist');
const mime={'.html':'text/html','.css':'text/css','.mjs':'text/javascript','.js':'text/javascript','.png':'image/png','.json':'application/json','.svg':'image/svg+xml'};
const port=Number(process.env.PORT||4173);
http.createServer(async(req,res)=>{try{const p=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));if(p!==root&&!p.startsWith(root+path.sep))throw Error();const file=p===root?path.join(root,'index.html'):p;res.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');res.end(await readFile(file));}catch{res.writeHead(404);res.end('Not found');}}).listen(port,'0.0.0.0',()=>console.log('Local: http://localhost:'+port));
