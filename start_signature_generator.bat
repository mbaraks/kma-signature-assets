@echo off
setlocal
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is required to run the signature generator.
  pause
  exit /b 1
)

start "KMA Signature Generator" http://localhost:8000/signature_generator.html
node -e "const http=require('http'),fs=require('fs'),path=require('path');const root=process.cwd();http.createServer((req,res)=>{const file=path.join(root,decodeURIComponent(req.url==='/'?'/signature_generator.html':req.url));if(!file.startsWith(root)||!fs.existsSync(file)||fs.statSync(file).isDirectory()){res.writeHead(404);return res.end('Not found');}const type=file.endsWith('.html')?'text/html':file.endsWith('.png')?'image/png':'application/octet-stream';res.writeHead(200,{'Content-Type':type});fs.createReadStream(file).pipe(res);}).listen(8000,()=>console.log('KMA Signature Generator running at http://localhost:8000/signature_generator.html'));"