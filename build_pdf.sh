#!/bin/bash
# Baut Pflege_Lernfuehrer_komplett.pdf aus allen Markdown-Dateien (pandoc + Chromium).
set -e
cd "$(dirname "$0")"
OUT=Pflege_Lernfuehrer_komplett
TMP=$(mktemp -d)
FILES="README.md 00_Inventar_und_Konusu_Haritasi.md 01_LF1_Grundverstaendnis_Pflege.md 02_Kommunikation.md 02b_Pflegedeutsch_Dialoge.md 03_Hygiene_und_Infektionsschutz.md 04_Haut_Zelle_Gewebe.md 05_Koerpertemperatur_Fieber.md 06_Mobilitaet_und_Sturzprophylaxe.md 07_Prophylaxen_Thrombose_Pneumonie.md 08_Erste_Hilfe.md 09_Pflegeprozess_und_Klinisches_Denken.md 10_Dokumentation_und_Operatoren.md 11_Grammatik_fuer_die_Pflege.md 12_Berufskontext_und_Lernplan.md ekler/Ek1_Woerterbuch.md ekler/Ek2_Pruefungssaetze.md ekler/Ek3_Konu_Ozetleri.md ekler/Ek4_Flashcards.md ekler/Ek5_Probeklausuren.md ekler/Ek5b_Antwortschluessel.md ekler/Ek6_Klinische_Faelle.md ekler/Ek7_Lernverfolgung.md ekler/Ek8_Quellen_und_Seitenindex.md"
: > $TMP/all.md
for f in $FILES; do
  # Links auf lokale .md-Dateien → nur Text (im PDF gibt es keine Dateien); externe Links bleiben
  python3 -I - "$f" >> $TMP/all.md <<'PY'
import re,sys
t=open(sys.argv[1],encoding="utf-8").read()
t=re.sub(r'\[([^\]]+)\]\((?!http)[^)]*\.(?:md|csv)(?:#[^)]*)?\)',r'\1',t)
print(t); print("\n<div style='page-break-after:always'></div>\n")
PY
done
cat > $TMP/style.css <<'CSS'
body{font-family:"DejaVu Sans","Liberation Sans",sans-serif;font-size:9.5pt;line-height:1.35;max-width:none;margin:0 6mm}
h1{font-size:17pt;border-bottom:2px solid #1d4e89;padding-bottom:2px;margin-top:0}h2{font-size:13pt;color:#1d4e89}h3{font-size:11pt}
table{border-collapse:collapse;width:100%;margin:6px 0;font-size:8.6pt}th,td{border:1px solid #bbb;padding:2px 4px;vertical-align:top}th{background:#e8eef6}
blockquote{border-left:3px solid #e0a800;margin:6px 0;padding:2px 8px;background:#fff8e1}code{font-size:8.5pt}
CSS
pandoc $TMP/all.md -f gfm -t html5 -s --toc --toc-depth=2 --metadata title="Pflege-Ausbildung Lernführer (DE–TR)" -c $TMP/style.css --embed-resources -o $TMP/all.html 2>/dev/null || pandoc $TMP/all.md -f gfm -t html5 -s --toc --toc-depth=2 --metadata title="Pflege-Ausbildung Lernführer (DE–TR)" -c $TMP/style.css --self-contained -o $TMP/all.html
node -e "
const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage();
await p.goto('file://$TMP/all.html');
await p.pdf({path:'$OUT.pdf',format:'A4',margin:{top:'14mm',bottom:'14mm',left:'10mm',right:'10mm'},printBackground:true,displayHeaderFooter:true,footerTemplate:'<div style=\"font-size:7px;width:100%;text-align:center\"><span class=\"pageNumber\"></span> / <span class=\"totalPages\"></span></div>',headerTemplate:'<div></div>'});
await b.close();})();"
echo built $OUT.pdf
