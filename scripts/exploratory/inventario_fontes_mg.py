"""Aquisição exploratória de fontes públicas MG; não integra o pipeline canônico."""
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urljoin, quote
from lxml import html
from concurrent.futures import ThreadPoolExecutor
import json, hashlib, csv
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'data/raw/sejusp_mg/2026-10-04'
OUT = ROOT / 'outputs/tabelas/viabilidade_mg_2026-10-04'
RAW.mkdir(parents=True, exist_ok=True)
OUT.mkdir(parents=True, exist_ok=True)

def get(url):
    req = Request(url, headers={'User-Agent': 'Mozilla/5.0 (public data research)'})
    with urlopen(req, timeout=120) as r:
        return r.read(), r.geturl(), dict(r.headers)

def preserve(fp, b):
    if fp.exists() and fp.read_bytes()!=b:
        raise RuntimeError('Snapshot já existe com bytes diferentes: '+str(fp))
    fp.write_bytes(b)

def main():
    pages = {
        'dados_abertos': 'https://www.seguranca.mg.gov.br/index.php/transparencia/dados-abertos',
        'violencia_mulher': 'https://www.seguranca.mg.gov.br/index.php/component/sppagebuilder/page/261',
    }
    links=[]
    for name,url in pages.items():
        b,actual,h=get(url)
        preserve(RAW/(name+'.html'),b)
        tree=html.fromstring(b.decode('utf-8'))
        for a in tree.xpath('//a[@href]'):
            label=' '.join(a.text_content().split())
            href=urljoin(actual,a.get('href'))
            if any(x in href.lower() for x in ['.csv','.xlsx','.pdf','drive.google.com','powerbi','page/2500','page/3626']):
                links.append(dict(pagina=name,rotulo=label,url=href))
    # API CKAN pública: descoberta de recursos, sem depender da interface visual.
    api='https://dados.mg.gov.br/api/3/action/package_search?q='+quote('organization:secretaria-de-estado-de-justica-e-seguranca-publica-sejusp')+'&rows=100'
    b,_,_=get(api)
    preserve(RAW/'ckan_sejusp.json',b)
    packages=json.loads(b)['result']['results']
    resources=[]
    for p in packages:
        for r in p['resources']:
            resources.append(dict(dataset=p['name'],title=p['title'],metadata_modified=p.get('metadata_modified'),
                                  resource_id=r['id'],name=r.get('name'),url=r['url'],format=r.get('format'),
                                  last_modified=r.get('last_modified'),datastore_active=r.get('datastore_active')))
    (OUT/'catalogo_links.json').write_text(json.dumps(links,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'catalogo_ckan.json').write_text(json.dumps(resources,ensure_ascii=False,indent=2),encoding='utf-8')
    wanted=[]
    for i,l in enumerate(links):
        url=l['url']
        if '.csv' in url.lower() or (l['pagina']=='violencia_mulher' and '.xlsx' in url.lower()) or 'Metolodogia' in url:
            suffix='.csv' if '.csv' in url.lower() else '.xlsx' if '.xlsx' in url.lower() else '.pdf'
            wanted.append({**l,'arquivo':f'{i:02d}_{l["pagina"]}{suffix}'})
    for r in resources:
        if r['format'].upper()=='JSON':
            wanted.append(dict(pagina='ckan',rotulo=r['title']+' datapackage',url=r['url'],arquivo=r['dataset']+'_datapackage.json'))
    def fetch(l):
        fp=RAW/l['arquivo']
        row={**l,'coleta_utc':datetime.now(timezone.utc).isoformat()}
        try:
            b,actual,h=get(l['url'])
            preserve(fp,b)
            row.update(status='ok',url_final=actual,bytes=len(b),sha256=hashlib.sha256(b).hexdigest(),content_type=h.get('Content-Type'))
        except Exception as e:row.update(status='erro',erro=str(e))
        print(json.dumps(row,ensure_ascii=True),flush=True)
        return row
    with ThreadPoolExecutor(max_workers=4) as pool:manifest=list(pool.map(fetch,wanted))
    cols=list(dict.fromkeys(k for r in manifest for k in r))
    with (RAW/'MANIFEST_sejusp_mg.csv').open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=cols);w.writeheader();w.writerows(manifest)
    print('LINKS',len(links),'CKAN',len(resources),'DOWNLOADS',len(manifest),flush=True)

if __name__=='__main__':main()
