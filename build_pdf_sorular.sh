#!/bin/bash
# Baut Pflege_Lernfuehrer_komplett.pdf aus allen Markdown-Dateien (pandoc + Chromium).
set -e
cd "$(dirname "$0")"
OUT=Pflege_Operatoren_Soru_Bankasi_DE_TR
TMP=$(mktemp -d)
FILES="sorular/00_Giris.md sorular/01_Vakalar_1-5.md sorular/02_Vakalar_6-10.md sorular/03_Vakalar_11-15.md"
: > $TMP/all.md
for f in $FILES; do
  # Links auf lokale .md-Dateien → nur Text (im PDF gibt es keine Dateien); externe Links bleiben
  python3 -I - "$f" >> $TMP/all.md <<'PY'
import re,sys
t=open(sys.argv[1],encoding="utf-8").read()
t=re.sub(r'\[([^\]]+)\]\((?!http)[^)]*\.(?:md|csv)(?:#[^)]*)?\)',r'\1',t)
L=t.split('\n');o=[]
for i,l in enumerate(L):
    if l.startswith('|') and o and o[-1].strip() and not o[-1].startswith('|'): o.append('')
    o.append(l)
t='\n'.join(o)
print(t); print("\n<div style='page-break-after:always'></div>\n")
PY
done
cat > $TMP/style.css <<'CSS'
body{font-family:"DejaVu Sans","Liberation Sans",sans-serif;font-size:9.5pt;line-height:1.35;max-width:none;margin:0 6mm}
h1{font-size:17pt;border-bottom:2px solid #1d4e89;padding-bottom:2px;margin-top:0}h2{font-size:13pt;color:#1d4e89}h3{font-size:11pt}
table{border-collapse:collapse;width:100%;margin:6px 0;font-size:8.6pt}th,td{border:1px solid #bbb;padding:2px 4px;vertical-align:top}th{background:#e8eef6}
blockquote{border-left:3px solid #e0a800;margin:6px 0;padding:2px 8px;background:#fff8e1}code{font-size:8.5pt}
CSS
pandoc $TMP/all.md -f gfm -t html5 -s --toc --toc-depth=2 --metadata title="Operatör Soru Bankası — Almanca + Türkçe" -c $TMP/style.css --embed-resources -o $TMP/all.html 2>/dev/null || pandoc $TMP/all.md -f gfm -t html5 -s --toc --toc-depth=2 --metadata title="Operatör Soru Bankası — Almanca + Türkçe" -c $TMP/style.css --self-contained -o $TMP/all.html
node -e "
const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage();
await p.goto('file://$TMP/all.html');
await p.pdf({path:'$OUT.pdf',format:'A4',margin:{top:'14mm',bottom:'14mm',left:'10mm',right:'10mm'},printBackground:true,displayHeaderFooter:true,footerTemplate:'<div style=\"font-size:7px;width:100%;text-align:center\"><span class=\"pageNumber\"></span> / <span class=\"totalPages\"></span></div>',headerTemplate:'<div></div>'});
await b.close();})();"
echo built $OUT.pdf
