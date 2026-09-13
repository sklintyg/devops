#!/usr/bin/env bash
# Renders doc/local-dev-environment-analysis.md into a self-contained HTML file next to it.
# The Markdown file is the source; edit it and run this script. Requires only bash and cat.
set -euo pipefail
cd "$(dirname "$0")"
MD=local-dev-environment-analysis.md
OUT=local-dev-environment-analysis.html
MARKED=assets/marked-4.3.0.min.js

if grep -q '</script' "$MD"; then echo "The Markdown must not contain '</script'." >&2; exit 1; fi

{
cat <<'HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Intygstjänster Dev Environment</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,400;0,500;0,600;1,400&family=IBM+Plex+Sans+Condensed:wght@500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
:root{
  --paper:#F3F5F6; --ink:#1B2226; --muted:#5B6B72; --accent:#0F6E68; --accent-ink:#0B4F4B;
  --panel:#E6ECED; --line:#CBD5D8; --code-bg:#E9EFF0; --diagram-bg:#1B2226; --diagram-ink:#D8E2E4;
  --th:#DCE4E6;
}
@media (prefers-color-scheme: dark){
  :root:not([data-theme="light"]){
    --paper:#14191B; --ink:#E6EBEC; --muted:#98A6AB; --accent:#4FC3B8; --accent-ink:#8FE0D6;
    --panel:#1E2629; --line:#2F3B3F; --code-bg:#1E2629; --diagram-bg:#0E1214; --diagram-ink:#C9D4D7;
    --th:#263034;
  }
}
:root[data-theme="dark"]{
  --paper:#14191B; --ink:#E6EBEC; --muted:#98A6AB; --accent:#4FC3B8; --accent-ink:#8FE0D6;
  --panel:#1E2629; --line:#2F3B3F; --code-bg:#1E2629; --diagram-bg:#0E1214; --diagram-ink:#C9D4D7;
  --th:#263034;
}
*{box-sizing:border-box}
body{background:var(--paper);color:var(--ink);font-family:"IBM Plex Sans",system-ui,-apple-system,"Segoe UI",sans-serif;font-size:16px;line-height:1.55;padding-inline:20px;padding-block:0 64px;margin:0}
.wrap{max-width:1180px;margin:0 auto;display:grid;grid-template-columns:240px minmax(0,1fr);gap:48px}
@media (max-width:900px){.wrap{grid-template-columns:minmax(0,1fr)}nav.toc{position:static;max-height:none;border-right:0;border-bottom:1px solid var(--line);padding-bottom:12px;margin-bottom:8px}}
nav.toc{position:sticky;top:0;align-self:start;max-height:100vh;overflow-y:auto;padding-block:32px 24px;padding-right:16px;border-right:1px solid var(--line);font-size:13.5px}
nav.toc .eyebrow{font-family:"IBM Plex Mono",ui-monospace,monospace;font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);margin-bottom:10px}
nav.toc ol{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:6px}
nav.toc a{color:var(--ink);text-decoration:none;display:block;padding:2px 0;border-left:2px solid transparent;padding-left:10px}
nav.toc a:hover,nav.toc a:focus-visible{border-left-color:var(--accent);color:var(--accent-ink);outline:none}
nav.toc ol ol{margin-top:4px;margin-left:10px;gap:3px}
nav.toc ol ol a{color:var(--muted);font-size:12.5px}
main{padding-block:32px 0;min-width:0}
header.masthead{border-bottom:1px solid var(--line);padding-bottom:20px;margin-bottom:28px}
header.masthead .eyebrow{font-family:"IBM Plex Mono",ui-monospace,monospace;font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:var(--accent-ink)}
header.masthead h1{font-family:"IBM Plex Sans Condensed","IBM Plex Sans",sans-serif;font-weight:600;font-size:clamp(28px,4vw,40px);line-height:1.1;margin:8px 0 10px;text-wrap:balance;letter-spacing:-.01em}
header.masthead p{color:var(--muted);margin:0;max-width:68ch}
header.masthead .meta{display:flex;flex-wrap:wrap;gap:8px 20px;margin-top:14px;font-family:"IBM Plex Mono",ui-monospace,monospace;font-size:12.5px;color:var(--muted)}
article{max-width:76ch}
article h1{display:none}
article h2{font-family:"IBM Plex Sans Condensed","IBM Plex Sans",sans-serif;font-weight:600;font-size:26px;line-height:1.15;margin:56px 0 14px;padding-top:18px;border-top:1px solid var(--line);text-wrap:balance;scroll-margin-top:24px}
article h2:first-of-type{margin-top:0;border-top:0;padding-top:0}
article h3{font-family:"IBM Plex Sans Condensed","IBM Plex Sans",sans-serif;font-weight:600;font-size:19px;margin:34px 0 8px;text-wrap:balance;scroll-margin-top:24px}
article h3 .idx{font-family:"IBM Plex Mono",ui-monospace,monospace;color:var(--accent-ink);font-weight:500;font-size:15px;margin-right:8px}
article p{margin:0 0 14px}
article ul,article ol{margin:0 0 16px;padding-left:22px}
article li{margin-bottom:6px}
article li>ul{margin-top:6px}
article strong{font-weight:600}
article a{color:var(--accent-ink)}
article code{font-family:"IBM Plex Mono",ui-monospace,monospace;font-size:.88em;background:var(--code-bg);padding:1px 5px;border-radius:3px}
article pre{background:var(--code-bg);border:1px solid var(--line);padding:14px 16px;overflow-x:auto;margin:0 0 18px;border-radius:4px;font-size:13.5px;line-height:1.5}
article pre code{background:none;padding:0;font-size:inherit}
article pre.diagram{background:var(--diagram-bg);color:var(--diagram-ink);border-color:transparent;font-size:12.5px;line-height:1.45}
article pre.diagram code{color:inherit}
article .tablewrap{overflow-x:auto;margin:0 0 18px;border:1px solid var(--line);border-radius:4px}
article table{border-collapse:collapse;width:100%;font-size:14px;font-variant-numeric:tabular-nums}
article th{background:var(--th);text-align:left;font-weight:600;padding:8px 12px;border-bottom:1px solid var(--line);white-space:nowrap}
article td{padding:7px 12px;border-bottom:1px solid var(--line);vertical-align:top}
article tr:last-child td{border-bottom:0}
article td code,article th code{white-space:nowrap}
article blockquote{margin:0 0 16px;padding:8px 16px;border-left:3px solid var(--accent);background:var(--panel);color:var(--ink)}
article hr{border:0;border-top:1px solid var(--line);margin:32px 0}
.status{display:inline-block;font-family:"IBM Plex Mono",ui-monospace,monospace;font-size:12px;letter-spacing:.04em;padding:2px 8px;border:1px solid var(--accent);color:var(--accent-ink);border-radius:2px}
@media (prefers-reduced-motion:no-preference){html{scroll-behavior:smooth}}
</style>
</head>
<body>
<div class="wrap">
<nav class="toc" aria-label="Sections"><div class="eyebrow">Sections</div><ol id="toc"></ol></nav>
<main>
<header class="masthead">
  <div class="eyebrow">Intyg / devops · doc</div>
  <h1>Local development environment for Intygstjänster</h1>
  <p>Analysis of today's setup and a catalogue of ideas to try: one compose project, any app native or containerized, one address scheme, a single CLI, and an environment that coding agents can read.</p>
  <div class="meta"><span class="status">proposal · nothing implemented</span><span>2026-09-13</span><span>source: doc/local-dev-environment-analysis.md</span></div>
</header>
<article id="doc"></article>
</main>
</div>
<script type="text/markdown" id="md">
HEAD
cat "$MD"
printf '</script>\n<script>\n'
cat "$MARKED"
cat <<'TAIL'

</script>
<script>
(function(){
  var src = document.getElementById('md').textContent;
  var esc = function(s){return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');};
  var renderer = new marked.Renderer();
  renderer.html = function(html){ return esc(html); };
  var slug = function(t){return t.toLowerCase().replace(/[^a-z0-9åäö]+/g,'-').replace(/^-|-$/g,'');};
  renderer.heading = function(text, level, raw){
    var id = slug(raw);
    var m = /^([A-N])\. (.*)$/.exec(raw);
    var inner = m && level===3 ? '<span class="idx">'+m[1]+'</span>'+text.replace(/^[A-N]\. /,'') : text;
    return '<h'+level+' id="'+id+'">'+inner+'</h'+level+'>';
  };
  renderer.table = function(header, body){ return '<div class="tablewrap"><table><thead>'+header+'</thead><tbody>'+body+'</tbody></table></div>'; };
  var origCode = renderer.code.bind(renderer);
  renderer.code = function(code, lang, escaped){
    var out = origCode(code, lang, escaped);
    if (!lang && /compose network|laptop/.test(code)) out = out.replace('<pre>','<pre class="diagram">');
    return out;
  };
  marked.setOptions({ renderer: renderer, gfm: true, headerIds: false, mangle: false });
  document.getElementById('doc').innerHTML = marked.parse(src);
  var toc = document.getElementById('toc'), cur = null, ideas = false;
  document.querySelectorAll('#doc h2, #doc h3').forEach(function(h){
    var a = document.createElement('a'); a.href = '#'+h.id; a.textContent = h.textContent.replace(/^\d+\.\s*/,'');
    var li = document.createElement('li'); li.appendChild(a);
    if (h.tagName === 'H2') { toc.appendChild(li); cur = li; ideas = /^Ideas$/.test(a.textContent); }
    else if (ideas && cur) { var sub = cur.querySelector('ol') || cur.appendChild(document.createElement('ol')); sub.appendChild(li); }
  });
})();
</script>
</body>
</html>
TAIL
} > "$OUT"
echo "wrote $OUT ($(wc -c < "$OUT") bytes)"
