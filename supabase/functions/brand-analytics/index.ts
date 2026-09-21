// Server-rendered brand analytics page for a Magic Media trigger.
//
// This deliberately is NOT a Claude Artifact: artifacts run under a CSP that
// blocks fetch/XHR to arbitrary hosts (like this project's own Supabase
// REST API), and every runtime capability that could bridge that is scoped
// to signed-in Claude users or org members — unusable for a link handed to
// an external brand contact who has never used Claude. A Supabase Edge
// Function is a normal HTTP endpoint: real query params, and server-side
// code has no browser CSP to work around. Data is queried here and baked
// directly into the returned HTML — the browser does zero further fetching.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[c]!));
}

function page(bodyHtml: string): string {
  return `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Magic Media Trigger Analytics</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@600;700;800&family=Source+Serif+4:opsz,wght@8..60,400;8..60,600;8..60,700&family=IBM+Plex+Mono:wght@400;500;600&display=swap');
  :root {
    --paper:#f4f3ef; --surface:#fbfaf7; --ink:#201f1c; --ink-muted:#5b584f; --ink-faint:#8a8577;
    --rule:#d9d5c9; --rule-strong:#c7c2b3; --gold:#a96a1f; --gold-ink:#7c4d16; --gold-fill:#c1852e;
    --amber-bg:#f4e6d3; --shadow:0 1px 2px rgba(32,31,28,.06),0 8px 24px -12px rgba(32,31,28,.12);
  }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) {
      --paper:#1a1917; --surface:#221f1b; --ink:#ede9e0; --ink-muted:#a89f8f; --ink-faint:#776f60;
      --rule:#3a362e; --rule-strong:#4a4536; --gold:#d9a34b; --gold-ink:#e8b968; --gold-fill:#d9a34b;
      --amber-bg:#2c2418; --shadow:0 1px 2px rgba(0,0,0,.3),0 8px 24px -12px rgba(0,0,0,.5);
    }
  }
  :root[data-theme="dark"] {
    --paper:#1a1917; --surface:#221f1b; --ink:#ede9e0; --ink-muted:#a89f8f; --ink-faint:#776f60;
    --rule:#3a362e; --rule-strong:#4a4536; --gold:#d9a34b; --gold-ink:#e8b968; --gold-fill:#d9a34b;
    --amber-bg:#2c2418; --shadow:0 1px 2px rgba(0,0,0,.3),0 8px 24px -12px rgba(0,0,0,.5);
  }
  * { box-sizing: border-box; }
  body { background:var(--paper); color:var(--ink); font-family:'Source Serif 4',Georgia,serif; font-size:17px; line-height:1.6; margin:0; }
  .masthead { border-bottom:1px solid var(--rule); padding:40px 24px 28px; }
  .masthead-inner { max-width:900px; margin:0 auto; }
  .eyebrow { font-family:'IBM Plex Mono',monospace; font-size:12px; letter-spacing:.12em; text-transform:uppercase; color:var(--gold-ink); margin:0 0 10px; }
  h1 { font-family:'Big Shoulders Display',sans-serif; font-weight:800; font-size:clamp(30px,5vw,46px); text-transform:uppercase; margin:0 0 8px; line-height:1; }
  .meta-row { display:flex; flex-wrap:wrap; gap:10px; align-items:center; font-family:'IBM Plex Mono',monospace; font-size:12.5px; color:var(--ink-muted); }
  .badge { display:inline-block; padding:3px 10px; border-radius:100px; background:var(--amber-bg); color:var(--gold-ink); letter-spacing:.04em; }
  main { max-width:900px; margin:0 auto; padding:40px 24px 96px; }
  .stat-row { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:18px; margin-bottom:36px; }
  .stat-tile { padding:22px 24px; border:1px solid var(--rule-strong); border-radius:8px; background:var(--surface); box-shadow:var(--shadow); }
  .stat-tile .k { font-family:'IBM Plex Mono',monospace; font-size:11px; text-transform:uppercase; letter-spacing:.08em; color:var(--ink-faint); margin-bottom:8px; }
  .stat-tile .v { font-family:'Big Shoulders Display',sans-serif; font-weight:700; font-size:40px; font-variant-numeric:tabular-nums; line-height:1; }
  .stat-tile .v.small { font-family:'Source Serif 4',serif; font-weight:600; font-size:20px; }
  .chart-card { padding:26px 24px 18px; border:1px solid var(--rule-strong); border-radius:8px; background:var(--surface); box-shadow:var(--shadow); }
  .chart-card h2 { font-family:'Big Shoulders Display',sans-serif; font-weight:700; font-size:18px; letter-spacing:.01em; text-transform:uppercase; margin:0 0 4px; }
  .chart-card .sub { font-family:'IBM Plex Mono',monospace; font-size:12px; color:var(--ink-faint); margin-bottom:18px; }
  .chart-wrap { position:relative; overflow-x:auto; }
  svg { display:block; overflow:visible; }
  .gridline { stroke:var(--rule); stroke-width:1; }
  .axis-label { fill:var(--ink-faint); font-family:'IBM Plex Mono',monospace; font-size:10.5px; }
  .bar { fill:var(--gold-fill); }
  .bar:hover { fill:var(--gold-ink); }
  .tooltip { position:absolute; pointer-events:none; opacity:0; transition:opacity .1s ease; background:var(--ink); color:var(--paper); font-family:'IBM Plex Mono',monospace; font-size:12px; padding:6px 10px; border-radius:5px; white-space:nowrap; transform:translate(-50%,-100%); z-index:5; }
  .empty-state, .error-state { padding:60px 24px; text-align:center; color:var(--ink-muted); font-size:15.5px; }
  .error-state { color:var(--gold-ink); }
  .lookup-card { max-width:520px; margin:40px auto 0; padding:28px 26px; border:1px solid var(--rule-strong); border-radius:8px; background:var(--surface); box-shadow:var(--shadow); }
  .lookup-card h2 { font-family:'Big Shoulders Display',sans-serif; font-weight:700; font-size:20px; text-transform:uppercase; margin:0 0 6px; }
  .lookup-card p { font-size:15px; color:var(--ink-muted); margin:0 0 18px; }
  .lookup-row { display:flex; gap:10px; flex-wrap:wrap; }
  .lookup-row input { flex:1 1 260px; font-family:'IBM Plex Mono',monospace; font-size:14px; padding:11px 14px; border:1px solid var(--rule-strong); border-radius:6px; background:var(--paper); color:var(--ink); }
  .lookup-row button { font-family:'IBM Plex Mono',monospace; font-size:13px; font-weight:600; letter-spacing:.03em; text-transform:uppercase; padding:11px 20px; border:none; border-radius:6px; background:var(--gold); color:var(--paper); cursor:pointer; }
  .lookup-row button:hover { background:var(--gold-ink); }
  .back-link { display:inline-block; margin-bottom:20px; font-family:'IBM Plex Mono',monospace; font-size:12.5px; color:var(--ink-faint); text-decoration:none; }
  .back-link:hover { color:var(--gold-ink); }
  footer { max-width:900px; margin:0 auto; padding:0 24px 64px; font-family:'IBM Plex Mono',monospace; font-size:12px; color:var(--ink-faint); border-top:1px solid var(--rule); padding-top:20px; }
</style>
</head>
<body>
${bodyHtml}
<footer>Magic Media — brand analytics. Questions? <a href="mailto:jamalcampbell@outlook.com" style="color:var(--gold-ink)">jamalcampbell@outlook.com</a></footer>
</body>
</html>`;
}

function lookupBody(errorMsg?: string): string {
  return `
<div class="masthead"><div class="masthead-inner">
  <p class="eyebrow">Magic Media — Brand Analytics</p>
  <h1>Trigger Analytics</h1>
</div></div>
<main>
  ${errorMsg ? `<div class="error-state">${escapeHtml(errorMsg)}</div>` : ""}
  <div class="lookup-card">
    <h2>View Your Trigger's Analytics</h2>
    <p>Paste the Trigger ID Magic Media gave you to see how many times it's been scanned.</p>
    <form method="get" class="lookup-row">
      <input type="text" name="trigger" placeholder="e.g. 955b54ba-7da7-41b5-a8a6-c2e17723194a" autocomplete="off" spellcheck="false">
      <button type="submit">View Analytics</button>
    </form>
  </div>
</main>`;
}

function resultBody(
  trigger: { title: string; content_type: string; created_at: string },
  totalScans: number,
  daily: { day: string; scans: number }[],
): string {
  const fmtDate = (iso: string) =>
    new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });

  let chartHtml: string;
  if (totalScans === 0) {
    chartHtml = `<div class="chart-card"><h2>Daily Scans</h2><div class="empty-state">No scans yet — check back once people start finding this trigger.</div></div>`;
  } else {
    const byDay: Record<string, number> = {};
    daily.forEach((row) => { byDay[row.day] = row.scans; });

    const days: string[] = [];
    const today = new Date();
    for (let i = 29; i >= 0; i--) {
      const d = new Date(today);
      d.setDate(d.getDate() - i);
      days.push(d.toISOString().slice(0, 10));
    }
    const counts = days.map((d) => byDay[d] || 0);
    const maxCount = Math.max(1, ...counts);

    const W = 820, H = 220, padL = 34, padR = 6, padT = 10, padB = 26;
    const plotW = W - padL - padR, plotH = H - padT - padB;
    const barGap = 2;
    const barW = Math.max(2, plotW / days.length - barGap);

    let gridHtml = "";
    for (let g = 0; g <= 4; g++) {
      const y = padT + plotH - (g / 4) * plotH;
      gridHtml += `<line class="gridline" x1="${padL}" x2="${W - padR}" y1="${y}" y2="${y}" />`;
      gridHtml += `<text class="axis-label" x="${padL - 6}" y="${y + 3}" text-anchor="end">${Math.round((g / 4) * maxCount)}</text>`;
    }

    let barsHtml = "";
    days.forEach((day, i) => {
      const c = counts[i];
      const barH = (c / maxCount) * plotH;
      const x = padL + i * (plotW / days.length);
      const y = padT + plotH - barH;
      barsHtml += `<rect class="bar" x="${x}" y="${y}" width="${barW}" height="${Math.max(barH, c > 0 ? 2 : 0)}" rx="3" data-day="${day}" data-count="${c}"></rect>`;
    });

    let labelsHtml = "";
    [0, 14, 29].forEach((i) => {
      const x = padL + i * (plotW / days.length) + barW / 2;
      labelsHtml += `<text class="axis-label" x="${x}" y="${H - 6}" text-anchor="middle">${new Date(days[i]).toLocaleDateString("en-US", { month: "short", day: "numeric" })}</text>`;
    });

    chartHtml = `<div class="chart-card">
      <h2>Daily Scans</h2>
      <div class="sub">Last 30 days</div>
      <div class="chart-wrap">
        <svg viewBox="0 0 ${W} ${H}" width="100%" style="height:${H}px">${gridHtml}${barsHtml}${labelsHtml}</svg>
      </div>
    </div>
    <div class="tooltip" id="tooltip"></div>
    <script>
      (function () {
        var tooltip = document.getElementById("tooltip");
        document.querySelectorAll(".bar").forEach(function (bar) {
          bar.addEventListener("mousemove", function (e) {
            var day = bar.getAttribute("data-day");
            var count = bar.getAttribute("data-count");
            var d = new Date(day);
            tooltip.textContent = d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" }) + " — " + count + (count === "1" ? " scan" : " scans");
            tooltip.style.left = e.pageX + "px";
            tooltip.style.top = (e.pageY - 10) + "px";
            tooltip.style.opacity = "1";
          });
          bar.addEventListener("mouseleave", function () { tooltip.style.opacity = "0"; });
        });
      })();
    </script>`;
  }

  return `
<div class="masthead"><div class="masthead-inner">
  <p class="eyebrow">Magic Media — Brand Analytics</p>
  <h1>${escapeHtml(trigger.title)}</h1>
  <div class="meta-row">
    <span class="badge">${escapeHtml(trigger.content_type)}</span>
    <span>Live since ${fmtDate(trigger.created_at)}</span>
  </div>
</div></div>
<main>
  <a class="back-link" href="/functions/v1/brand-analytics">&larr; Look up another trigger</a>
  <div class="stat-row">
    <div class="stat-tile"><div class="k">Total Scans</div><div class="v">${totalScans}</div></div>
    <div class="stat-tile"><div class="k">Content Type</div><div class="v small">${escapeHtml(trigger.content_type)}</div></div>
    <div class="stat-tile"><div class="k">Live Since</div><div class="v small">${fmtDate(trigger.created_at)}</div></div>
  </div>
  ${chartHtml}
</main>`;
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const triggerId = url.searchParams.get("trigger")?.trim();

  const html = (body: string, status = 200) =>
    new Response(page(body), { status, headers: { "Content-Type": "text/html; charset=utf-8" } });

  if (!triggerId) {
    return html(lookupBody());
  }

  const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRe.test(triggerId)) {
    return html(lookupBody("That doesn't look like a valid Trigger ID. Double-check it and try again."), 200);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const client = createClient(supabaseUrl, serviceRoleKey);

  const [{ data: info, error: infoErr }, { data: countData, error: countErr }, { data: dailyData, error: dailyErr }] =
    await Promise.all([
      client.from("triggers").select("title, content_type, created_at").eq("id", triggerId).eq("status", "approved").maybeSingle(),
      client.rpc("get_scan_count", { p_trigger_id: triggerId }),
      client.rpc("get_scan_counts_daily", { p_trigger_id: triggerId, p_days: 30 }),
    ]);

  if (infoErr || countErr || dailyErr) {
    return html(lookupBody("Couldn't load this trigger's data right now. Try again shortly."), 200);
  }

  if (!info) {
    return html(lookupBody("This trigger isn't approved yet, or the ID is wrong. Double-check it and try again."), 200);
  }

  return html(resultBody(info, countData ?? 0, dailyData ?? []));
});
