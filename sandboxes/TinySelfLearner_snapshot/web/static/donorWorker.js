/* donorWorker.js — runs off the UI thread to avoid page freezing */
let running = false;
let device = "anonymous";
let total = 0;
let paused = false;

function sleep(ms) {
  return new Promise(res => setTimeout(res, ms));
}

self.onmessage = async (e) => {
  const { type, payload } = e.data || {};
  if (type === "start") {
    device = (payload?.device || "anonymous").slice(0, 64);
    if (!running) {
      running = true;
      paused = false;
      loop().catch(err => {
        // Report error back; main can show a toast
        self.postMessage({ type: "error", error: String(err) });
      });
    }
  } else if (type === "stop") {
    running = false;
  } else if (type === "pause") {
    paused = true;
  } else if (type === "resume") {
    paused = false;
  }
};

async function loop() {
  while (running) {
    if (paused) {
      await sleep(300);
      continue;
    }

    // Ask server for a task (duration only for now)
    let duration_ms = 500;
    try {
      const r = await fetch("/task", { cache: "no-store" });
      if (r.ok) {
        const j = await r.json();
        duration_ms = Math.max(50, Math.min(5000, +j.duration_ms || 500));
      }
    } catch (_) {
      // Backoff if offline or server hiccup
      await sleep(1000);
      continue;
    }

    // Instead of busy spin, just wait
    await sleep(duration_ms);

    // Use duration as "cycles" so numbers feel responsive without CPU burn
    const cycles = duration_ms;

    // Submit result
    try {
      await fetch("/submit", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ device, cycles })
      });
      total += cycles;
      self.postMessage({ type: "progress", tick: cycles, total });
    } catch (_) {
      // network error: keep going with gentle backoff
      await sleep(500);
    }
  }
  self.postMessage({ type: "stopped" });
}
