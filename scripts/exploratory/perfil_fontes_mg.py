"""Perfil e controles dos arquivos MG adquiridos para diagnóstico, sem produzir monitor."""
from pathlib import Path
import pandas as pd
import json, hashlib
import openpyxl

ROOT=Path(__file__).resolve().parents[2]
RAW=ROOT/'data/raw/sejusp_mg/2026-10-04'
OUT=ROOT/'outputs/tabelas/viabilidade_mg_2026-10-04'

def main():
    manifest=pd.read_csv(RAW/'MANIFEST_sejusp_mg.csv')
    profiles=[];annual=[];tables={};checks=[];monthly=[]
    for _,r in manifest.iterrows():
        if r['status']!='ok':continue
        fp=RAW/r['arquivo']
        checks.append(dict(arquivo=fp.name,controle='sha256_preservado',ok=hashlib.sha256(fp.read_bytes()).hexdigest()==r.sha256))
        if fp.suffix!='.csv':continue
        d=pd.read_csv(fp,sep=';',encoding='utf-8-sig',low_memory=False)
        measure=d.columns[0]
        keys=[c for c in ['Natureza','Alvo','Cód. IBGE','Mês','Ano Fato'] if c in d]
        p=dict(arquivo=fp.name,rotulo=r.rotulo,colunas=list(d.columns),linhas=len(d),
               unidade=measure,ano_min=int(d['Ano Fato'].min()),ano_max=int(d['Ano Fato'].max()),
               municipios=d['Município'].nunique(),codigos=d['Cód. IBGE'].nunique(),
               nulos=d.isna().sum().to_dict(),chaves_repetidas=int(d.duplicated(keys).sum()),
               negativos=int((d[measure]<0).sum()),naturezas=sorted(d.Natureza.unique().tolist()),
               alvos=sorted(d.Alvo.unique().tolist()) if 'Alvo' in d else [],
               meses_ultimo_ano=sorted(d.loc[d['Ano Fato']==d['Ano Fato'].max(),'Mês'].unique().tolist()))
        profiles.append(p);tables[fp.name]=d
        for key,g in d.groupby(['Ano Fato','Mês']):
            monthly.append(dict(arquivo=fp.name,ano=int(key[0]),mes=int(key[1]),linhas=len(g),total=int(g[measure].sum())))
        for name,ok in [('853_municipios',p['municipios']==853),('chaves_unicas',p['chaves_repetidas']==0),
                        ('medida_nao_negativa',p['negativos']==0),('medida_sem_nulos',p['nulos'][measure]==0)]:
            checks.append(dict(arquivo=fp.name,controle=name,ok=ok))
        by=['Ano Fato','Natureza']+(['Alvo'] if 'Alvo' in d else [])
        for key,g in d.groupby(by):
            key=key if isinstance(key,tuple) else (key,)
            annual.append(dict(arquivo=fp.name,unidade=measure,ano=int(key[0]),natureza=key[1],
                               alvo=key[2] if len(key)>2 else '',municipios=g['Município'].nunique(),
                               meses=','.join(map(str,sorted(g['Mês'].unique()))),linhas=len(g),total=int(g[measure].sum()),
                               zeros=int((g[measure]==0).sum()),nulos=int(g[measure].isna().sum())))
        print(fp.name,len(d),'mun',p['municipios'],'anos',p['ano_min'],p['ano_max'],flush=True)
    # Alvos são partições de registros: testar contra totais municipais mensais.
    controls=[]
    cv=pd.concat([tables[k] for k in ['01_dados_abertos.csv','02_dados_abertos.csv','03_dados_abertos.csv']])
    for a,t,n in [('18_dados_abertos.csv',cv,'ROUBO CONSUMADO'),('19_dados_abertos.csv',tables['15_dados_abertos.csv'],'FURTO CONSUMADO')]:
        key=['Cód. IBGE','Ano Fato','Mês']
        aa=tables[a].groupby(key).Registros.sum().rename('alvos')
        tt=t[t.Natureza==n].set_index(key).Registros.rename('total')
        m=pd.concat([aa,tt],axis=1).loc[aa.index].reset_index()
        m['diferenca']=m.alvos-m.total
        controls.append(dict(indicador=n,linhas=len(m),linhas_diferentes=int((m.diferenca!=0).sum()),
                             diferenca_liquida=int(m.diferenca.sum()),diferenca_absoluta=int(m.diferenca.abs().sum())))
        m[m.diferenca!=0].to_csv(OUT/('residuos_alvos_'+n.split()[0].lower()+'.csv'),index=False,encoding='utf-8-sig')
    # Perfil das planilhas de feminicídio e violência doméstica: todas as abas e cabeçalhos.
    workbooks=[]
    for fp in RAW.glob('*.xlsx'):
        w=openpyxl.load_workbook(fp,read_only=True,data_only=True)
        p=dict(arquivo=fp.name,abas=[])
        for sheet in w:
            rows=[list(row) for row in sheet.iter_rows(min_row=1,max_row=5,values_only=True)]
            p['abas'].append(dict(nome=sheet.title,linhas=sheet.max_row,colunas=sheet.max_column,cabecalhos=rows))
        workbooks.append(p)
        print(fp.name,'abas',len(w.sheetnames),flush=True)
        w.close()
    (OUT/'perfil_csv.json').write_text(json.dumps(profiles,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'perfil_planilhas.json').write_text(json.dumps(workbooks,ensure_ascii=False,indent=2,default=str),encoding='utf-8')
    pd.DataFrame(annual).to_csv(OUT/'cobertura_mg_indicador_ano.csv',index=False,encoding='utf-8-sig')
    pd.DataFrame(controls).to_csv(OUT/'reconciliacao_alvos_totais.csv',index=False,encoding='utf-8-sig')
    pd.DataFrame(checks).to_csv(OUT/'controles_integridade.csv',index=False,encoding='utf-8-sig')
    pd.DataFrame(monthly).to_csv(OUT/'cobertura_mg_arquivo_mes.csv',index=False,encoding='utf-8-sig')
    print(json.dumps(controls,ensure_ascii=True),flush=True)

if __name__=='__main__':main()
