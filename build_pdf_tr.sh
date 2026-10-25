#!/bin/bash
# Baut Pflege_Lernfuehrer_komplett.pdf aus allen Markdown-Dateien (pandoc + Chromium).
set -e
cd "$(dirname "$0")"
OUT=Pflege_Calisma_Rehberi_TR
TMP=$(mktemp -d)
FILES="tr/README_TR.md tr/00_Envanter_Celiskiler.md tr/01_Hemsirelik_Temelleri.md tr/02_Iletisim_Dokunma.md tr/02b_Hasta_Diyaloglari.md tr/03_Hijyen_Enfeksiyon.md tr/04_Cilt_Hucre_Doku.md tr/05_Vucut_Isisi_Ates.md tr/06_Hareket_Dusme.md tr/07_Profilaksiler.md tr/08_Ilk_Yardim.md tr/09_Bakim_Sureci_Vakalar.md tr/10_Dokumentasyon_Operatorler.md tr/11_Almanca_Gramer.md tr/12_Meslek_Baglami_Calisma_Plani.md tr/ekler/Ek1_Sozluk.md tr/ekler/Ek2_Sinav_Kaliplari.md tr/ekler/Ek3_Konu_Ozetleri.md tr/ekler/Ek4_Flashcards_TR.md tr/ekler/Ek5_Deneme_Sinavlari.md tr/ekler/Ek5b_Cevaplar.md tr/ekler/Ek5c_Operator_Vakalari.md tr/ekler/Ek5d_Operator_Cevaplari.md tr/ekler/Ek6_Klinik_Vakalar.md tr/ekler/Ek7_Takip_Tablosu.md tr/ekler/Ek8_Kaynakca.md"
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
pandoc $TMP/all.md -f gfm -t html5 -s --toc --toc-depth=2 --metadata title="Hemşirelik Ausbildung — Türkçe Çalışma Rehberi" -c $TMP/style.css --embed-resources -o $TMP/all.html 2>/dev/null || pandoc $TMP/all.md -f gfm -t html5 -s --toc --toc-depth=2 --metadata title="Hemşirelik Ausbildung — Türkçe Çalışma Rehberi" -c $TMP/style.css --self-contained -o $TMP/all.html
node -e "
const {chromium}=require('playwright');
(async()=>{const b=await chromium.launch();const p=await b.newPage();
await p.goto('file://$TMP/all.html');
await p.pdf({path:'$OUT.pdf',format:'A4',margin:{top:'14mm',bottom:'14mm',left:'10mm',right:'10mm'},printBackground:true,displayHeaderFooter:true,footerTemplate:'<div style=\"font-size:7px;width:100%;text-align:center\"><span class=\"pageNumber\"></span> / <span class=\"totalPages\"></span></div>',headerTemplate:'<div></div>'});
await b.close();})();"
echo built $OUT.pdf
