"""Inventário público e leitura limitada dos cabeçalhos das bases completas MG."""
from pathlib import Path
from urllib.request import urlopen, Request
from lxml import html
import json, hashlib
from concurrent.futures import ThreadPoolExecutor

ROOT=Path(__file__).resolve().parents[2]
RAW=ROOT/'data/raw/sejusp_mg/2026-10-04'
OUT=ROOT/'outputs/tabelas/viabilidade_mg_2026-10-04'

def main():
    page=html.fromstring((RAW/'pasta_bases_completas.html').read_text(encoding='utf-8'))
    files=[]
    for el in page.xpath('//strong[contains(text(),".csv")]'):
        p=next((a for a in el.iterancestors() if a.get('data-id')),None)
        if p is not None:
            files.append(dict(nome=el.text_content(),id=p.get('data-id'),url='https://drive.google.com/file/d/'+p.get('data-id')+'/view'))
    (OUT/'catalogo_bases_completas.json').write_text(json.dumps(files,ensure_ascii=False,indent=2),encoding='utf-8')
    selected=[f for f in files if any(n in f['nome'] for n in ['Crimes Violentos - Jan 2022','Alvo - Roubo','Alvo - Furto Consumado - Jan 2022','Vítimas de Homicidio','Veiculos - Roubo'])]
    def read_head(f):
        url='https://drive.usercontent.google.com/download?id='+f['id']+'&export=download&confirm=t'
        try:
            with urlopen(Request(url,headers={'Range':'bytes=0-65535'}),timeout=60) as r:
                b=r.read(65536);ctype=r.headers.get('Content-Type','');status=r.status
            # Só se preserva uma amostra de bytes, nunca a classificar como base integral.
            name=f['id']+'.amostra'
            (RAW/name).write_bytes(b)
            try:
                b.splitlines()[0].decode('utf-8-sig')
                encoding='utf-8-sig'
            except UnicodeDecodeError:encoding='cp1252'
            s=b.decode(encoding,errors='replace')
            result={**f,'status_http':status,'tipo':ctype,'bytes_lidos':len(b),'arquivo_amostra':name,
                    'sha256_amostra':hashlib.sha256(b).hexdigest(),'encoding_cabecalho':encoding,'cabecalho':s.splitlines()[0] if s else '',
                    'linhas_exemplo':s.splitlines()[1:3],'leitura_parcial':True}
        except Exception as e:result={**f,'erro':str(e)}
        print(json.dumps(result,ensure_ascii=True),flush=True)
        return result
    with ThreadPoolExecutor(max_workers=3) as pool:heads=list(pool.map(read_head,selected))
    (OUT/'cabecalhos_bases_completas.json').write_text(json.dumps(heads,ensure_ascii=False,indent=2),encoding='utf-8')

if __name__=='__main__':main()
