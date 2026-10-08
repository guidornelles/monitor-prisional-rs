"""Aquisição auditável do Sinesp VDE; nenhuma fonte estadual é alterada.

Uso: python scripts/exploratory/auditoria_sinesp_inspecao.py --snapshot AAAA-MM-DD
Reexecução preserva arquivos já baixados. Novo snapshot exige outra data/pasta.
"""
from pathlib import Path
import urllib.request
import re
import pandas as pd
import argparse
import hashlib
import json
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor

ROOT = Path(__file__).resolve().parents[2]
URL = 'https://www.gov.br/mj/pt-br/assuntos/sua-seguranca/seguranca-publica/estatistica/dados-nacionais-1/base-de-dados-e-notas-metodologicas-dos-gestores-estaduais-sinesp-vde-2022-e-2023'
def main():
    p = argparse.ArgumentParser()
    p.add_argument('--snapshot', required=True)
    args = p.parse_args()
    if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', args.snapshot):
        raise ValueError('snapshot deve ser AAAA-MM-DD')
    dest = ROOT / 'data/raw/sinesp_vde' / args.snapshot
    dest.mkdir(parents=True, exist_ok=True)
    page = dest / 'pagina_origem.html'
    if not page.exists():
        page.write_bytes(urllib.request.urlopen(URL, timeout=60).read())
    html = page.read_text(encoding='utf-8')
    urls = sorted(set(re.findall(r'href="([^"]+/bancovde-\d{4}\.xlsx/@@download/file)"', html)))
    if not urls:
        raise RuntimeError('Nenhum download VDE encontrado; verificar mudança do portal')
    def download(url):
        name = re.search(r'bancovde-\d{4}\.xlsx', url).group()
        fp = dest / name
        meta_file = dest / (name + '.http.json')
        if not fp.exists():
            with urllib.request.urlopen(url, timeout=120) as r:
                data = r.read()
                if not data.startswith(b'PK'):
                    raise RuntimeError(f'{url}: conteúdo não é XLSX')
                meta = dict(url=url, final_url=r.url, retrieved_utc=datetime.now(timezone.utc).isoformat(),
                            content_type=r.headers.get('Content-Type'), last_modified=r.headers.get('Last-Modified'),
                            etag=r.headers.get('ETag'))
            fp.write_bytes(data)
            meta_file.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding='utf-8')
        meta = json.loads(meta_file.read_text(encoding='utf-8'))
        with zipfile.ZipFile(fp) as z:
            with z.open('xl/worksheets/sheet1.xml') as sheet:
                prefix = sheet.read(2000).decode()
            dim = re.search(r'<dimension ref="([^"]+)"', prefix)
        result = dict(ano_link=int(re.search(r'\d{4}', name).group()), arquivo=str(fp.relative_to(ROOT)),
                      bytes=fp.stat().st_size, sha256=hashlib.sha256(fp.read_bytes()).hexdigest(),
                      dimensao_xml=dim.group(1) if dim else None, **meta)
        print(name, result['dimensao_xml'], flush=True)
        return result
    with ThreadPoolExecutor(max_workers=4) as pool:
        rows = list(pool.map(download, urls))
    pd.DataFrame(rows).to_csv(dest / 'MANIFEST_sinesp_vde.csv', index=False, encoding='utf-8-sig')
    print('Downloads e manifesto concluídos:', dest)

if __name__ == '__main__':
    main()
