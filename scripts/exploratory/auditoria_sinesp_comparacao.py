"""Auditoria Sinesp VDE versus insumos locais SP/RS, isolada do pipeline canônico.

Lê XLSX em fluxo para evitar materializar milhões de células vazias.
Não altera arquivos de entrada. Resultados são snapshots, não promoção de fonte.
"""
from pathlib import Path
import pandas as pd
import numpy as np
import zipfile
from lxml import etree as ET
from concurrent.futures import ProcessPoolExecutor
from collections import defaultdict, Counter
import unicodedata
import re
import json
import hashlib
import argparse
from datetime import datetime, timedelta

ROOT = Path(__file__).resolve().parents[2]
NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'

def norm(x):
    return re.sub(r'\s+', ' ', ''.join(c for c in unicodedata.normalize('NFKD', str(x)) if not unicodedata.combining(c)).upper()).strip()

def xlsx_rows(fp):
    """Leitor de valores armazenados da primeira aba; esquema validado na aquisição."""
    with zipfile.ZipFile(fp) as z:
        shared = []
        if 'xl/sharedStrings.xml' in z.namelist():
            with z.open('xl/sharedStrings.xml') as f:
                for _, el in ET.iterparse(f, events=('end',)):
                    if el.tag == NS + 'si':
                        shared.append(''.join(t.text or '' for t in el.iter(NS+'t')))
                        el.clear()
        with z.open('xl/worksheets/sheet1.xml') as f:
            for _, el in ET.iterparse(f, events=('end',), tag=NS+'row'):
                vals = [None] * 14
                for c in el:
                    ref = c.attrib['r']
                    if ref[1].isalpha():
                        raise ValueError('Mudança de esquema')
                    idx = ord(ref[0])-65
                    if idx >= 14:
                        raise ValueError('Mudança de esquema (>14 colunas)')
                    v = c.find(NS+'v')
                    if c.attrib.get('t') == 's' and v is not None:
                        value = shared[int(v.text)]
                    elif c.attrib.get('t') == 'inlineStr':
                        value = ''.join(t.text or '' for t in c.iter(NS+'t'))
                    elif v is not None:
                        value = float(v.text)
                    else:
                        value = None
                    vals[idx] = value
                yield vals
                el.clear()
                while el.getprevious() is not None:
                    del el.getparent()[0]

def inspect_year(args):
    snapshot,year=args
    raw = ROOT/'data/raw/sinesp_vde'/snapshot
    out = ROOT/'data/intermediate/sinesp_vde'/snapshot
    out.mkdir(parents=True, exist_ok=True)
    coverage=[]
    if True:
        fp=raw/f'bancovde-{year}.xlsx'
        rows=xlsx_rows(fp)
        header=next(rows)
        expected=['uf','municipio','evento','data_referencia','agente','arma','faixa_etaria','feminino','masculino','nao_informado','total_vitima','total','total_peso','abrangencia']
        assert header == expected, (fp,header)
        groups={}
        cats={c:Counter() for c in ['agente','arma','faixa_etaria','abrangencia']}
        selected=[]
        n=0
        for r in rows:
            n+=1
            if not r[0]:
                continue
            date = datetime(1899,12,30) + timedelta(days=r[3])
            assert date.year == year, (fp,date)
            key=(r[0],r[2])
            if key not in groups:
                groups[key]=dict(munis=set(),months=set(),lines=0,valid=0,zeros=0,nonzero=0,missing=0,total=0,total_vitima=0,total_peso=0,abrangencia=set())
            g=groups[key]
            g['munis'].add(r[1]);g['months'].add(date.month);g['lines']+=1;g['abrangencia'].add(r[13])
            numeric=[r[i] for i in [10,11,12] if isinstance(r[i],(int,float))]
            if numeric:
                g['valid']+=1
                g['zeros']+=int(all(v==0 for v in numeric))
                g['nonzero']+=int(any(v!=0 for v in numeric))
            else:
                g['missing']+=1
            for c,i in [('total_vitima',10),('total',11),('total_peso',12)]:
                if isinstance(r[i],(int,float)):g[c]+=r[i]
            for c,i in [('agente',4),('arma',5),('faixa_etaria',6),('abrangencia',13)]:
                if r[i] is not None:cats[c][str(r[i])]+=1
            if r[0] in ['SP','RS']:
                r[3]=date.strftime('%Y-%m-%d')
                selected.append(r)
        for (uf,ev),g in groups.items():
            coverage.append(dict(ano=year,uf=uf,evento=ev,municipios=len(g['munis']),meses=','.join(map(str,sorted(g['months']))),
                                 abrangencia=';'.join(map(str,sorted(g['abrangencia'],key=str))),
                                 **{k:v for k,v in g.items() if k not in ['munis','months','abrangencia']}))
        schema=dict(ano=year,linhas=n,colunas=header,dimensoes={c:dict(v) for c,v in cats.items()})
        sdf=pd.DataFrame(selected,columns=header)
        sdf['ano']=year
        sdf.to_csv(out/f'recorte_sp_rs_{year}.csv.gz',index=False,compression='gzip',encoding='utf-8')
        print('Processado nacional', year, n, 'SP/RS',len(selected),flush=True)
    return coverage,schema

def inspect_national(snapshot, years):
    out = ROOT/'outputs/tabelas'/f'auditoria_sinesp_{snapshot}'
    out.mkdir(parents=True, exist_ok=True)
    coverage=[]
    schema=[]
    with ProcessPoolExecutor(max_workers=4) as pool:
        for cov,sch in pool.map(inspect_year,[(snapshot,y) for y in years]):
            coverage.extend(cov);schema.append(sch)
    pd.DataFrame(coverage).to_csv(out/'cobertura_nacional_uf_indicador_ano.csv',index=False,encoding='utf-8-sig')
    (out/'esquema_nacional.json').write_text(json.dumps(schema,ensure_ascii=False,indent=2),encoding='utf-8')
    cache=ROOT/'data/intermediate/sinesp_vde'/snapshot
    sel=pd.concat([pd.read_csv(cache/f'recorte_sp_rs_{y}.csv.gz',low_memory=False) for y in years],ignore_index=True)
    print('Eventos SP/RS:',sorted(sel.evento.unique()),flush=True)
    print(sel.groupby(['uf','ano','evento'])[['total_vitima','total','total_peso']].sum(min_count=1).tail(65).to_string(),flush=True)
    print('Dimensões:',schema[-1]['dimensoes'],flush=True)
    return sel,out

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--snapshot',default='2026-10-03')
    p.add_argument('--years',nargs='+',type=int,default=list(range(2015,2027)))
    a=p.parse_args()
    inspect_national(a.snapshot,a.years)
