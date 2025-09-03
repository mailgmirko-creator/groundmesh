from flask import Flask, request, jsonify, send_from_directory, Response
from pathlib import Path
from werkzeug.utils import secure_filename
import json, html, os

app = Flask(__name__, static_folder="static", static_url_path="/static")

# ---- Config ----
STATE_FILE = Path("stats.json")
PROFILES_FILE = Path("profiles.json")
SUGGESTIONS_FILE = Path("suggestions.json")
AVATAR_DIR = Path(app.static_folder) / "avatars"
AVATAR_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_EXTENSIONS = {"png","jpg","jpeg","gif","webp"}
app.config["MAX_CONTENT_LENGTH"] = 2 * 1024 * 1024  # 2 MB

def load_json(path, default):
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            return default
    return default

def save_json(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")

def norm_dev(s):
    return (s or "").strip()[:64]

def flag_for_country(c):
    if not c: return ""
    code = {
        "Montenegro":"🇲🇪","Serbia":"🇷🇸","Croatia":"🇭🇷","Bosnia and Herzegovina":"🇧🇦",
        "Slovenia":"🇸🇮","North Macedonia":"🇲🇰","Albania":"🇦🇱","Kosovo":"🇽🇰","Italy":"🇮🇹",
        "Germany":"🇩🇪","France":"🇫🇷","Spain":"🇪🇸","Portugal":"🇵🇹","United Kingdom":"🇬🇧",
        "USA":"🇺🇸","Canada":"🇨🇦","China":"🇨🇳","Japan":"🇯🇵","South Korea":"🇰🇷"
    }
    return code.get(c, "")

def set_profile_field(device, **fields):
    device = norm_dev(device)
    profiles = load_json(PROFILES_FILE, {})
    cur = profiles.get(device, {})
    cur.update({k:v for k,v in fields.items() if v is not None})
    profiles[device] = cur
    save_json(PROFILES_FILE, profiles)
    return cur

# ---------- Home ----------
@app.route("/")
def index():
    return send_from_directory("static", "index.html")

# ---------- Data APIs ----------
@app.route("/stats")
def stats():
    return jsonify(load_json(STATE_FILE, {"total_cycles": 0, "contributors": {}}))

@app.route("/profiles_json")
def profiles_json():
    return jsonify(load_json(PROFILES_FILE, {}))

@app.route("/leaderboard")
def leaderboard():
    state = load_json(STATE_FILE, {"total_cycles": 0, "contributors": {}})
    profiles = load_json(PROFILES_FILE, {})
    rows = []
    for device, cycles in state.get("contributors", {}).items():
        p = profiles.get(device, {})
        rows.append({
            "device": device,
            "cycles": int(cycles),
            "name": p.get("name", ""),
            "country": p.get("country", ""),
            "avatar": p.get("avatar", "")
        })
    rows.sort(key=lambda r: r["cycles"], reverse=True)
    return jsonify({"leaders": rows[:200], "total_cycles": state.get("total_cycles", 0)})

# ---------- Pages ----------
@app.route("/leaders")
def leaders_page():
    data = leaderboard().json
    rows = data.get("leaders", [])
    total = int(data.get("total_cycles", 0))

    by_country = {}
    for r in rows:
        c = (r.get("country") or "").strip()
        if c:
            by_country[c] = by_country.get(c, 0) + int(r.get("cycles", 0))

    country_rows = "".join(
        f"<tr><td>{html.escape(c)}</td><td>{by_country[c]}</td></tr>"
        for c in sorted(by_country, key=lambda k: by_country[k], reverse=True)
    )

    tr = []
    for i, r in enumerate(rows, 1):
        flag = flag_for_country(r.get("country"))
        av = r.get("avatar") or ""
        avatar_img = f'<img src="{html.escape(av)}" alt="" style="width:28px;height:28px;border-radius:50%;object-fit:cover;margin-right:.5rem;border:1px solid #ddd" />' if av else ""
        name_cell = f'{avatar_img}{html.escape(r.get("name") or "")}'
        tr.append(
            f"<tr><td>{i}</td>"
            f"<td>{name_cell}</td>"
            f"<td><code>{html.escape(r.get('device') or '')}</code></td>"
            f"<td>{flag} {html.escape(r.get('country') or '')}</td>"
            f"<td>{int(r.get('cycles') or 0)}</td></tr>"
        )
    leaders_html = "".join(tr)

    html_doc = f"""<!doctype html>
<html lang="en"><head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>GroundMesh — Leaders</title>
<link rel="stylesheet" href="/static/styles.css" />
</head><body>
<nav class="nav">
  <a href="/">Home</a>
  <a class="active" href="/leaders">Leaders</a>
  <a href="/profiles">Profiles</a>
  <a href="/profile">My Profile</a>
  <a href="/suggestions">Suggestions</a>
</nav>
<main class="container">
  <h1>Leaders</h1>
  <p class="muted">Total cycles: <b>{total}</b></p>
  <h2>Top Contributors</h2>
  <table><thead><tr><th>#</th><th>Name</th><th>Device</th><th>Country</th><th>Cycles</th></tr></thead><tbody>
    {leaders_html}
  </tbody></table>
  <h2>Cycles by Country</h2>
  <table><thead><tr><th>Country</th><th>Cycles</th></tr></thead><tbody>
    {country_rows or '<tr><td colspan="2" class="muted">No country data yet</td></tr>'}
  </tbody></table>
</main></body></html>"""
    return Response(html_doc, mimetype="text/html")

@app.route("/profiles")
def profiles_page():
    profiles = load_json(PROFILES_FILE, {})
    rows = []
    for device, p in profiles.items():
        name = html.escape(p.get("name") or "")
        country = p.get("country") or ""
        flag = flag_for_country(country)
        av = p.get("avatar") or ""
        avatar_img = f'<img src="{html.escape(av)}" alt="" style="width:24px;height:24px;border-radius:50%;object-fit:cover;margin-right:.4rem;border:1px solid #ddd" />' if av else ""
        rows.append(f"<tr><td>{avatar_img}{name}</td><td><code>{html.escape(device)}</code></td><td>{flag} {html.escape(country)}</td></tr>")
    profiles_html = "".join(rows) or '<tr><td colspan="3" class="muted">No profiles saved yet</td></tr>'

    html_doc = """<!doctype html>
<html lang="en"><head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>GroundMesh — Profiles</title>
<link rel="stylesheet" href="/static/styles.css" />
</head><body>
<nav class="nav">
  <a href="/">Home</a>
  <a href="/leaders">Leaders</a>
  <a class="active" href="/profiles">Profiles</a>
  <a href="/profile">My Profile</a>
  <a href="/suggestions">Suggestions</a>
</nav>
<main class="container">
  <h1>Profiles</h1>
  <p class="muted">All participants who saved a profile (Name, Avatar, Device, Country). Click <b>My Profile</b> below to edit yours.</p>
  <table>
    <thead><tr><th>Name</th><th>Device</th><th>Country</th></tr></thead>
    <tbody>""" + profiles_html + """</tbody>
  </table>
  <p><a class="primary" style="padding:.6rem 1rem; display:inline-block;" href="/profile">My Profile</a></p>
</main></body></html>"""
    return Response(html_doc, mimetype="text/html")

@app.route("/profile")
def profile_prompt():
    html_doc = """<!doctype html>
<html lang="en"><head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>Edit My Profile</title>
<link rel="stylesheet" href="/static/styles.css" />
</head><body>
<nav class="nav">
  <a href="/">Home</a>
  <a href="/leaders">Leaders</a>
  <a class="active" href="/profile">My Profile</a>
  <a href="/suggestions">Suggestions</a>
</nav>
<main class="container">
  <h1>Edit My Profile</h1>
  <p class="muted">Enter your <b>Device ID</b> (the same one you use on Home) to edit your profile.</p>
  <div class="row">
    <input id="device" placeholder="Device ID (e.g., Mirko-Laptop)" />
    <button class="primary" onclick="go()">Open</button>
  </div>
</main>
<script>
function go(){
  const d = (document.getElementById('device').value||'').trim();
  if(!d){ alert('Please enter your Device ID'); return; }
  location.href = '/profile/' + encodeURIComponent(d);
}
</script>
</body></html>"""
    return Response(html_doc, mimetype="text/html")

# ---------- Upload Avatar ----------
def allowed_file(filename):
    return "." in filename and filename.rsplit(".",1)[1].lower() in ALLOWED_EXTENSIONS

@app.route("/upload_avatar", methods=["POST"])
def upload_avatar():
    device = norm_dev(request.form.get("device"))
    if not device:
        return jsonify({"ok":False,"error":"missing device"}), 400
    if "file" not in request.files:
        return jsonify({"ok":False,"error":"missing file"}), 400
    f = request.files["file"]
    if f.filename == "":
        return jsonify({"ok":False,"error":"empty filename"}), 400
    if not allowed_file(f.filename):
        return jsonify({"ok":False,"error":"unsupported type"}), 400

    ext = f.filename.rsplit(".",1)[1].lower()
    fname = secure_filename(f"{device}.{ext}")
    # remove old avatar(s) for this device
    for e in ALLOWED_EXTENSIONS:
        p = AVATAR_DIR / f"{device}.{e}"
        if p.exists():
            try: p.unlink()
            except Exception: pass
    save_path = AVATAR_DIR / fname
    f.save(save_path)

    public_url = f"/static/avatars/{fname}"
    set_profile_field(device, avatar=public_url)
    return jsonify({"ok":True, "url": public_url})

@app.route("/rename_device", methods=["POST"])
def rename_device():
    body = request.get_json(force=True, silent=True) or {}
    old = norm_dev(body.get("old_device"))
    new = norm_dev(body.get("new_device"))
    if not old or not new:
        return jsonify({"ok": False, "error": "Both old_device and new_device are required"}), 400
    if old == new:
        return jsonify({"ok": True, "unchanged": True})

    state = load_json(STATE_FILE, {"total_cycles": 0, "contributors": {}})
    profiles = load_json(PROFILES_FILE, {})

    old_cycles = int(state.get("contributors", {}).get(old, 0))
    new_cycles = int(state.get("contributors", {}).get(new, 0))
    total_new = old_cycles + new_cycles
    if old in state.get("contributors", {}):
        del state["contributors"][old]
    if total_new > 0:
        state["contributors"][new] = total_new

    old_prof = profiles.get(old, {})
    new_prof = profiles.get(new, {})
    merged = {**old_prof, **new_prof}
    profiles.pop(old, None)
    profiles[new] = merged

    save_json(STATE_FILE, state)
    save_json(PROFILES_FILE, profiles)

    # rename avatar file if exists
    for e in ALLOWED_EXTENSIONS:
        p_old = AVATAR_DIR / f"{old}.{e}"
        p_new = AVATAR_DIR / f"{new}.{e}"
        if p_old.exists():
            try:
                if p_new.exists(): p_new.unlink()
                p_old.rename(p_new)
            except Exception:
                pass

    return jsonify({"ok": True, "moved_cycles": old_cycles, "new_total_for_device": total_new})

@app.route("/profile/<path:device>")
def profile_edit(device):
    device = norm_dev(device)
    state = load_json(STATE_FILE, {"total_cycles": 0, "contributors": {}})
    profiles = load_json(PROFILES_FILE, {})
    prof = profiles.get(device, {"name":"", "country":"", "avatar":""})
    cycles = int(state.get("contributors", {}).get(device, 0))
    name = html.escape(prof.get("name") or "")
    country = html.escape(prof.get("country") or "")
    avatar = html.escape(prof.get("avatar") or "")

    html_doc = f"""<!doctype html>
<html lang="en"><head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>Profile — {html.escape(device)}</title>
<link rel="stylesheet" href="/static/styles.css" />
</head><body>
<nav class="nav">
  <a href="/">Home</a>
  <a href="/leaders">Leaders</a>
  <a class="active" href="/profile">My Profile</a>
  <a href="/suggestions">Suggestions</a>
</nav>
<main class="container">
  <h1>My Profile</h1>
  <p class="muted">Device: <code id="devcode">{html.escape(device)}</code> • Cycles: <b id="cy">{cycles}</b></p>

  <div class="row">
    <label>Name <input id="name" value="{name}" /></label>
    <label>Country
      <select id="country"></select>
    </label>
    <label>Avatar URL <input id="avatar" value="{avatar}" placeholder="https://... (or leave blank if uploading)" /></label>
    <button class="primary" onclick="save()">Save</button>
  </div>

  <div class="row" style="align-items:center;gap:.8rem;">
    <label>Upload Avatar <input id="avatarfile" type="file" accept="image/*" /></label>
    <button onclick="uploadAvatar()">Upload</button>
    <img id="preview" src="{avatar}" alt="" style="width:40px;height:40px;border-radius:50%;object-fit:cover;border:1px solid #ddd;{'' if avatar else 'display:none;'}" />
  </div>

  <div class="row">
    <label>Device ID <input id="newdev" value="{html.escape(device)}" /></label>
    <button onclick="renameDev()">Rename Device</button>
  </div>

  <p id="saved" class="muted"></p>
</main>
<script>
async function loadCountries(){{
  const r = await fetch('/static/countries.json');
  const countries = await r.json();
  const sel = document.getElementById('country');
  sel.innerHTML = '';
  countries.forEach(c=>{{
    const opt = document.createElement('option');
    opt.value = c;
    opt.textContent = c;
    sel.appendChild(opt);
  }});
  sel.value = "{country}";
}}

async function save(){{
  const name = document.getElementById('name').value.slice(0,80);
  const country = document.getElementById('country').value.slice(0,80);
  const avatar = document.getElementById('avatar').value.slice(0,300);
  await fetch('/profile', {{
    method:'POST',
    headers:{{'Content-Type':'application/json'}},
    body: JSON.stringify({{ device: "{html.escape(device)}", name, country, avatar }})
  }});
  document.getElementById('saved').textContent = 'Saved ✔';
  const prev = document.getElementById('preview');
  if(avatar) {{ prev.src = avatar; prev.style.display='inline-block'; }}
  setTimeout(()=>document.getElementById('saved').textContent='', 2000);
}}

async function uploadAvatar(){{
  const f = document.getElementById('avatarfile').files[0];
  if(!f) {{ alert('Choose an image first'); return; }}
  const fd = new FormData();
  fd.append('device', "{html.escape(device)}");
  fd.append('file', f);
  const r = await fetch('/upload_avatar', {{ method:'POST', body: fd }});
  const j = await r.json();
  if(!j.ok) {{ alert('Upload failed: ' + (j.error||'unknown')); return; }}
  document.getElementById('avatar').value = j.url;
  const prev = document.getElementById('preview');
  prev.src = j.url + '?t=' + Date.now();
  prev.style.display='inline-block';
  document.getElementById('saved').textContent = 'Avatar uploaded ✔';
  setTimeout(()=>document.getElementById('saved').textContent='', 2000);
}}

async function renameDev(){{
  const oldDevice = "{html.escape(device)}";
  const newDevice = (document.getElementById('newdev').value||'').trim().slice(0,64);
  if(!newDevice) {{ alert('Please enter a new device id'); return; }}
  if(newDevice === oldDevice) {{ alert('New device id is the same'); return; }}

  const res = await fetch('/rename_device', {{
    method:'POST',
    headers:{{'Content-Type':'application/json'}},
    body: JSON.stringify({{ old_device: oldDevice, new_device: newDevice }})
  }});
  const j = await res.json();
  if(!j.ok) {{ alert('Rename failed: ' + (j.error||'unknown')); return; }}
  try {{ localStorage.setItem('device', newDevice); }} catch(e) {{}}
  location.href = '/profile/' + encodeURIComponent(newDevice);
}}

loadCountries();
</script>
</body></html>"""
    return Response(html_doc, mimetype="text/html")

# ---------- Suggestions ----------
@app.route("/suggest", methods=["POST"])
def suggest():
    data = request.get_json(force=True, silent=True) or {}
    device = norm_dev(data.get("device"))
    text = (data.get("text") or "").strip()
    if not text:
        return jsonify({"ok":False,"error":"Empty suggestion"}),400
    suggestions = load_json(SUGGESTIONS_FILE, [])
    suggestions.append({"device":device,"text":text})
    save_json(SUGGESTIONS_FILE, suggestions)
    return jsonify({"ok":True,"saved":text})

@app.route("/suggestions")
def suggestions_page():
    suggestions = load_json(SUGGESTIONS_FILE, [])
    rows = "".join(
        f"<tr><td><code>{html.escape(s['device'] or '')}</code></td><td>{html.escape(s['text'])}</td></tr>"
        for s in suggestions
    ) or "<tr><td colspan=2 class=muted>No suggestions yet</td></tr>"
    html_doc = f"""<!doctype html><html><head>
<meta charset=utf-8><link rel=stylesheet href=/static/styles.css>
<title>Suggestions</title></head><body>
<nav class=nav>
 <a href=/>Home</a>
 <a href=/leaders>Leaders</a>
 <a href=/profiles>Profiles</a>
 <a href=/profile>My Profile</a>
 <a class=active href=/suggestions>Suggestions</a>
</nav>
<main class=container>
<h1>Suggestions</h1>
<form onsubmit="send();return false;" class=row>
 <input id=text style="flex:1" placeholder="Your suggestion" />
 <button class=primary>Submit</button>
</form>
<table><thead><tr><th>Device</th><th>Suggestion</th></tr></thead><tbody>{rows}</tbody></table>
</main>
<script>
async function send(){{
 const t=document.getElementById('text').value.trim();
 if(!t) return;
 await fetch('/suggest',{{method:'POST',headers:{{'Content-Type':'application/json'}},body:JSON.stringify({{device:localStorage.getItem('device')||'',text:t}})}})
 location.reload();
}}
</script>
</body></html>"""
    return Response(html_doc,mimetype="text/html")

# ---------- Work loop ----------
@app.route("/task")
def task():
    return jsonify({"duration_ms": 500})

@app.route("/submit", methods=["POST"])
def submit():
    data = request.get_json(force=True, silent=True) or {}
    device = norm_dev(data.get("device") or "anonymous")
    cycles = int(data.get("cycles") or 0)
    state = load_json(STATE_FILE, {"total_cycles": 0, "contributors": {}})
    state["total_cycles"] = int(state.get("total_cycles", 0)) + cycles
    per = int(state["contributors"].get(device, 0)) + cycles
    state["contributors"][device] = per
    save_json(STATE_FILE, state)
    return jsonify({"ok": True, "your_total": per, "global_total": state["total_cycles"]})

@app.route("/profile", methods=["POST"])
def profile():
    data = request.get_json(force=True, silent=True) or {}
    device = norm_dev(data.get("device") or "anonymous")
    name = (data.get("name") or "")[:80]
    country = (data.get("country") or "")[:80]
    avatar = (data.get("avatar") or "")[:300]
    profiles = load_json(PROFILES_FILE, {})
    current = profiles.get(device, {})
    current.update({"name": name, "country": country, "avatar": avatar})
    profiles[device] = current
    save_json(PROFILES_FILE, profiles)
    return jsonify({"ok": True, "saved": profiles[device]})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
