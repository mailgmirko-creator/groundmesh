# Start GroundMesh Grid
cd "C:\Users\mailg\Projects\TinySelfLearner"
.\.venv\Scripts\Activate.ps1

# start Flask in background (hidden window)
Start-Process -WindowStyle Hidden .\.venv\Scripts\python.exe .\web\app.py

# open Cloudflare tunnel in this console (shows your public URL)
cloudflared tunnel --url http://localhost:5000
