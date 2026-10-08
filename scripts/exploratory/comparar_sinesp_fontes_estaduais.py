"""Reconcilia snapshots nacionais com as fontes estaduais já presentes no projeto.

Uso após auditoria_sinesp_comparacao.py. Todos os insumos ficam intactos.
Não presume que indicadores homônimos tenham a mesma definição.
"""
from pathlib import Path
import pandas as pd
import numpy as np
import re
import json
import hashlib
from auditoria_sinesp_comparacao import norm,ROOT

SNAPSHOT='2026-10-03'
OUT=ROOT/'outputs/tabelas'/f'auditoria_sinesp_{SNAPSHOT}'
CACHE=ROOT/'data/intermediate/sinesp_vde'/SNAPSHOT
sources=[]
def register(fp,role):
    sources.append(dict(arquivo=str(fp.resolve()),papel=role,bytes=fp.stat().st_size,sha256=hashlib.sha256(fp.read_bytes()).hexdigest()))

ALIASES={'DR MAURICIO CARDOSO':'DOUTOR MAURICIO CARDOSO','FAZENDA VILA NOVA':'FAZENDA VILANOVA',
 'FLORINIA':'FLORINEA','SAO LUIS DO PARAITINGA':'SAO LUIZ DO PARAITINGA',
 'BARAO DO COTEGIPE':'BARAO DE COTEGIPE','XANGRILA':'XANGRI LA',
 'PINTO BANDEIRA BENTO GONC':'PINTO BANDEIRA','ESTANCIA VELHAS':'ESTANCIA VELHA','XANGRI LAA':'XANGRI LA',
 'ACEGUAA':'ACEGUA','ARARICAA':'ARARICA','CAMBARAA DO SUL':'CAMBARA DO SUL','IBIACAA':'IBIACA','PICADA CAFU':'PICADA CAFE',
 'SAO JOSEDO OURO':'SAO JOSE DO OURO','SAO JOSEDO SUL':'SAO JOSE DO SUL','SAO JOSEDO HERVAL':'SAO JOSE DO HERVAL',
 'SAO JOSEDOS AUSENTES':'SAO JOSE DOS AUSENTES','SAO JOSEDO INHACORA':'SAO JOSE DO INHACORA'}
def key(x):
    k=re.sub(r'\s+',' ',re.sub(r'[^A-Z0-9 ]',' ',norm(x).replace("'",''))).strip()
    return ALIASES.get(k,k)

def sumn(series):
    return pd.to_numeric(series,errors='coerce').sum(min_count=1)

def national():
    d=pd.concat([pd.read_csv(f,low_memory=False) for f in sorted(CACHE.glob('recorte_sp_rs_*.csv.gz'))],ignore_index=True)
    assert sorted(d.ano.unique())==list(range(2015,2027)), 'Todos os anos devem estar processados'
    d=d[d.abrangencia=='Estadual'].copy()
    d['chave']=d.municipio.map(key)
    d['mes']=pd.to_datetime(d.data_referencia).dt.month
    for c in ['total_vitima','total','total_peso','feminino','masculino','nao_informado']:
        d[c]=pd.to_numeric(d[c],errors='coerce')
    # Não contar total_vitima junto às colunas de sexo: são representações do mesmo total.
    valid=d.total_vitima.notna() & d[['feminino','masculino','nao_informado']].notna().all(axis=1)
    assert (d.loc[valid,'total_vitima']==d.loc[valid,['feminino','masculino','nao_informado']].sum(axis=1)).all()
    dupcols=['uf','municipio','evento','data_referencia','agente','arma','faixa_etaria','abrangencia']
    d[d.duplicated(dupcols,keep=False)].to_csv(OUT/'linhas_chave_repetida_sp_rs.csv',index=False,encoding='utf-8-sig')
    return d

MAP_RS={
 'TOTAL DE VITIMAS DE HOMICIDIO DOLOSO':('Homicídio doloso','vítimas','direta'),
 'VITIMAS DE HOMICIDIO DOLOSO':('Homicídio doloso','vítimas','direta'),
 'HOMICIDIO DOLOSO':('Homicídio doloso','ocorrências','unidade_diferente'),
 'VITIMAS DE LATROCINIO':('Roubo seguido de morte (latrocínio)','vítimas','direta'),
 'LATROCINIO':('Roubo seguido de morte (latrocínio)','ocorrências','unidade_diferente'),
 'VITIMAS DE LESAO CORP. SEG. MORTE':('Lesão corporal seguida de morte','vítimas','direta'),
 'FURTO DE VEICULO':('Furto de veículo','ocorrências','direta'),
 'ROUBO DE VEICULO':('Roubo de veículo','ocorrências','direta'),
 'ENTORPECENTES - TRAFICO':('Tráfico de drogas','ocorrências','direta'),
}
months=['JAN','FEV','MAR','ABR','MAI','JUN','JUL','AGO','SET','OUT','NOV','DEZ']

def rs_official():
    rows=[]
    base=ROOT/'data/EstatisticasCriminaisRS/IndicadoresCriminais'
    for fp in sorted(base.glob('*.xlsx')):
        if not re.search(r'munic',norm(fp.name),re.I):continue
        w=pd.ExcelFile(fp)
        years=[int(s) for s in w.sheet_names if s.isdigit() and 2015<=int(s)<=2025]
        if not years:continue
        register(fp,'SSP-RS indicadores criminais')
        for year in years:
            def table(sn,monthly):
                a=pd.read_excel(fp,sheet_name=sn,header=None)
                if monthly:
                    hdr=next(i for i,r in a.iterrows() if any(norm(v).startswith('MES /') for v in r))
                    timecol=next(j for j,v in enumerate(a.iloc[hdr]) if norm(v).startswith('MES /'))
                else:
                    hdr=next(i for i,r in a.iterrows() if norm(r.iloc[0]).startswith('MUNIC'))
                    timecol=0
                columns={j:MAP_RS[norm(v)] for j,v in enumerate(a.iloc[hdr]) if norm(v) in MAP_RS}
                # GERAL: só o primeiro bloco de 12 meses, antes da primeira linha Total.
                data=a.iloc[hdr+1:hdr+13] if monthly else a.iloc[hdr+1:]
                for _,r in data.iterrows():
                    label=str(r.iloc[timecol])
                    if monthly:
                        m=re.fullmatch(fr'{year}/([A-Za-z]+)',label.strip())
                        if not m:continue
                        mon=months.index(norm(m[1])[:3])+1
                        mun='ESTADO';k='ESTADO'
                    else:
                        if not re.fullmatch(r'[A-Z ]+',key(label)) or norm(label) in ['TOTAL','TOTAL RS','GERAL','NAN'] or '*' in label:continue
                        mun=label;k=key(label);mon=0
                    for j,(event,unit,comp) in columns.items():
                        val=pd.to_numeric(r.iloc[j],errors='coerce')
                        if pd.isna(val):continue
                        rows.append(dict(uf='RS',ano=year,mes=mon,municipio=mun,chave=k,evento=event,valor_estadual=val,
                                         unidade_estadual=unit,comparabilidade=comp,fonte=str(fp.relative_to(ROOT)),aba=sn))
            table(str(year),False)
            if 'GERAL' in w.sheet_names:table('GERAL',True)
    # Feminicídio/VCM: arquivos anuais com grade municipal e meses em colunas.
    vcmfiles=[]
    for folder in [base,ROOT/'data/EstatisticasCriminaisRS/IndicadoresVCM']:
        for fp in folder.glob('*.xlsx'):
            m=re.search(r'(?:MULHERES-|MULHER-|MULHER.*MUNICIPIO-|MULHER.*MUNICIPIOS-)(20\d{2})',norm(fp.name))
            if not m:
                m=re.search(r'MULHER.*?(20\d{2})',norm(fp.name))
            if m and 2018<=int(m[1])<=2025:vcmfiles.append((int(m[1]),fp))
    for year,fp in vcmfiles:
        register(fp,'SSP-RS VCM feminicídios')
        w=pd.ExcelFile(fp)
        for sn in w.sheet_names:
            event='Tentativa de feminicídio' if norm(sn) in ['FEMINICIDIO TENTADO','FEMICIDIO TENTADO'] else 'Feminicídio' if norm(sn) in ['FEMINICIDIO CONSUMADO','FEMICIDIO CONSUMADO'] else None
            if not event:continue
            a=pd.read_excel(fp,sheet_name=sn,header=None)
            try:hdr,col=next((i,j) for i,r in a.iterrows() for j,v in enumerate(r) if norm(v) in ['MUNICIPIO','MUNICIPIOS'])
            except StopIteration:continue
            totals=[]
            for _,r in a.iloc[hdr+1:].iterrows():
                mun=str(r.iloc[col]);k=key(mun)
                if norm(mun) in ['TOTAL','GERAL','TOTAL GERAL','NAN'] or not re.fullmatch(r'[A-Z ]+',k):continue
                nums=pd.to_numeric(r.iloc[col+1:col+13],errors='coerce')
                if not nums.notna().any():continue
                totals.append(nums.to_numpy())
                rows.append(dict(uf='RS',ano=year,mes=0,municipio=mun,chave=k,evento=event,valor_estadual=nums.sum(min_count=1),
                    unidade_estadual='vítimas',comparabilidade='direta',fonte=str(fp.relative_to(ROOT)),aba=sn))
            if totals:
                for mon,val in enumerate(np.nansum(totals,axis=0),1):
                    rows.append(dict(uf='RS',ano=year,mes=mon,municipio='ESTADO',chave='ESTADO',evento=event,valor_estadual=val,
                        unidade_estadual='vítimas',comparabilidade='direta',fonte=str(fp.relative_to(ROOT)),aba=sn))
    return pd.DataFrame(rows)

def compare_join(state,nat,unitcol,keys,context):
    n=nat.groupby(keys,dropna=False)[unitcol].sum(min_count=1).rename('valor_nacional').reset_index()
    comp=state.merge(n,on=keys,how='outer',indicator=True,validate='one_to_one')
    comp['contexto']=context
    comp['diferenca']=comp.valor_nacional-comp.valor_estadual
    comp['diferenca_pct']=np.where(comp.valor_estadual!=0,100*comp.diferenca/comp.valor_estadual,np.nan)
    comp['status_pareamento']=comp.pop('_merge').astype(str)
    return comp

def rs_comparisons(d):
    official=rs_official()
    official.to_csv(CACHE/'extracao_ssp_rs.csv',index=False,encoding='utf-8-sig')
    rs=d[d.uf=='RS']
    parts=[]
    for unit,col in [('vítimas','total_vitima'),('ocorrências','total')]:
        s=official[(official.unidade_estadual==unit)&(official.comparabilidade=='direta')]
        annual=s[s.mes==0]
        for event in annual.evento.unique():
            ss=annual[annual.evento==event]
            nn=rs[(rs.evento==event)&(rs.chave!='NAO INFORMADO')&(rs.ano<=2025)]
            # Mesmo indicador no arquivo nacional pode ser exclusivamente estadual.
            if not nn.empty and col=='total_vitima':
                parts.append(compare_join(ss,nn,col,['uf','ano','chave','evento'],'município-ano'))
        monthly=s[s.mes>0].drop(columns=['chave','municipio'])
        nn=rs[rs.evento.isin(monthly.evento.unique())&(rs.ano<=2025)]
        parts.append(compare_join(monthly,nn,col,['uf','ano','mes','evento'],'estado-mês'))
    result=pd.concat(parts,ignore_index=True)
    result.to_csv(OUT/'comparacao_rs_mensal_municipal.csv',index=False,encoding='utf-8-sig')
    matched=result[result.status_pareamento=='both'].copy()
    matched['abs_diff']=matched.diferenca.abs()
    matched['igual']=matched.diferenca==0
    summary=matched.groupby(['contexto','ano','evento']).agg(pares=('igual','size'),iguais=('igual','sum'),
        nacional=('valor_nacional','sum'),estadual=('valor_estadual','sum'),soma_diferencas_absolutas=('abs_diff','sum'),max_diferenca_absoluta=('abs_diff','max')).reset_index()
    summary['diferenca']=summary.nacional-summary.estadual
    summary['diferenca_pct']=100*summary.diferenca/summary.estadual
    summary['iguais_pct']=100*summary.iguais/summary.pares
    summary.to_csv(OUT/'resumo_reconciliacao_rs.csv',index=False,encoding='utf-8-sig')
    return official,result,summary

def monitor_comparisons(d):
    records=[]
    spfile=ROOT/'data/raw/bases_data_studio/Variáveis de contexto - dinamica_criminal.csv'
    register(spfile,'Monitor-SP export publicado local')
    register(ROOT.parent/'MonitorPrisional2024/dados_ssp_2023.xlsx','Monitor-SP tabela municipal 2023 conferida em inspeção')
    sp=pd.read_csv(spfile)
    sp['chave']=sp['Município (IBGE)'].map(key)
    for year in [2023,2025]:
        a=sp[sp.Ano==year]
        for event,label,unit,col,comp in [
            ('Homicídio doloso','Homicídio doloso','vítimas em 2023; linhas de registros em 2025','total_vitima','2025_unidade_a_confirmar'),
            ('Estupro total','Estupros - total','ocorrências','total_vitima','unidade_diferente'),
            ('Arma de Fogo Apreendida','Armas de fogo apreendidas','armas/linhas de registros PC','total','abrangencia_institucional_a_confirmar'),
            ('Mandado de prisão cumprido','Prisões efetuadas','prisões (flagrantes + mandados)','total','conceito_diferente')]:
            nn=d[(d.uf=='SP')&(d.ano==year)&(d.evento.isin(['Estupro','Estupro de vulnerável']) if event=='Estupro total' else d.evento==event)]
            for period in ([12] if year==2023 else [11,12]):
                n=nn[nn.mes<=period][col].sum(min_count=1)
                value=a.loc[a.Crime==label,'quantidade'].sum(min_count=1)
                records.append(dict(uf='SP',ano=year,evento=event,meses_nacional=period,valor_estadual=value,valor_nacional=n,
                                    unidade_estadual=unit,comparabilidade='composicao_hd_feminicidio_diferente' if year==2023 and event=='Homicídio doloso' else comp,
                                    nota='Monitor 2025 usa jan-jun + jul-nov segundo script de validação; verificar fonte de cada indicador',fonte=str(spfile.relative_to(ROOT))))
    rsfile=ROOT/'data/processed/criminal_rs_municipio_ano.csv';register(rsfile,'Monitor-RS saída criminal existente')
    r=pd.read_csv(rsfile)
    for year,a in r.groupby('ano'):
        nn=d[(d.uf=='RS')&(d.ano==year)]
        for event,var,col,unit,comp in [('Homicídio doloso','hd_vitima','total_vitima','vítimas','direta'),
                ('Homicídio doloso','hd_ocorrencias','total_vitima','ocorrências','unidade_diferente'),
                ('Estupro total','tot_estupro','total_vitima','ocorrências','unidade_diferente')]:
            nat=nn[nn.evento.isin(['Estupro','Estupro de vulnerável']) if event=='Estupro total' else nn.evento==event]
            records.append(dict(uf='RS',ano=year,evento=event,variavel_monitor=var,meses_nacional=12,valor_estadual=a[var].sum(min_count=1),
                valor_nacional=nat[col].sum(min_count=1),unidade_estadual=unit,comparabilidade=comp,fonte=str(rsfile.relative_to(ROOT))))
    result=pd.DataFrame(records)
    result['diferenca']=result.valor_nacional-result.valor_estadual
    result['diferenca_pct']=100*result.diferenca/result.valor_estadual
    result.to_csv(OUT/'comparacao_monitores_estadual_ano.csv',index=False,encoding='utf-8-sig')
    # Somente homicídio tem série municipal comparável no Monitor SP de 2023.
    sn=sp[(sp.Ano==2023)&(sp.Crime=='Homicídio doloso')][['chave','quantidade']].rename(columns={'quantidade':'valor_estadual'})
    nn=d[(d.uf=='SP')&(d.ano==2023)&(d.evento=='Homicídio doloso')&(d.chave!='NAO INFORMADO')]
    join=compare_join(sn,nn,'total_vitima',['chave'],'SP município-2023')
    join.to_csv(OUT/'comparacao_sp_homicidio_municipal_2023.csv',index=False,encoding='utf-8-sig')
    # Hipótese de harmonização auditada, não regra nacional: a igualdade é verificada município a município.
    nn=d[(d.uf=='SP')&(d.ano==2023)&d.evento.isin(['Homicídio doloso','Feminicídio'])&(d.chave!='NAO INFORMADO')]
    harmon=compare_join(sn,nn,'total_vitima',['chave'],'SP 2023 HD + feminicídio (hipótese de harmonização)')
    harmon.to_csv(OUT/'comparacao_sp_homicidio_mais_feminicidio_2023.csv',index=False,encoding='utf-8-sig')
    print('Harmonização SP 2023',len(harmon),'pares',harmon.status_pareamento.value_counts().to_dict(),'iguais',int((harmon.diferenca==0).sum()),'soma abs',harmon.diferenca.abs().sum(),flush=True)
    return result,join

def activity(d):
    rows=[]
    base=ROOT/'data/EstatisticasCriminaisRS'
    fps=list(base.glob('*atividade*.xlsx'))
    for fp in fps:
        if fp.name.startswith('0516'):continue # cópia 2025 redundante com o arquivo 2025-2026 mais recente
        register(fp,'SSP-RS atividade')
        for sn in pd.ExcelFile(fp).sheet_names:
            if not sn.isdigit() or not 2015<=int(sn)<=2026:continue
            a=pd.read_excel(fp,sheet_name=sn,header=None)
            if a.shape[1]<15:continue
            for _,r in a.iterrows():
                label=norm(r.iloc[1])
                if label not in ['ARMAS DE FOGO APREENDIDAS','ARMAS APREENDIDAS','ARMAS APREENDIDAS PELA PC','PRESOS POR MANDADOS PELA PC']:continue
                event='Mandado de prisão cumprido' if 'MANDADO' in label else 'Arma de Fogo Apreendida'
                for m in range(1,13):
                    val=pd.to_numeric(r.iloc[m+1],errors='coerce')
                    if pd.notna(val):rows.append(dict(ano=int(sn),mes=m,evento=event,rotulo=label,valor_estadual=val,fonte=str(fp.relative_to(ROOT))))
    a=pd.DataFrame(rows)
    a.to_csv(OUT/'extracao_atividade_rs.csv',index=False,encoding='utf-8-sig')
    comp=[]
    for event in a.evento.unique():
        # Armas: preservar os componentes e somar BM + PC apenas como aproximação explicitada.
        s=a[a.evento==event].groupby(['ano','mes','evento']).valor_estadual.sum(min_count=1).reset_index()
        s['uf']='RS'
        n=d[(d.uf=='RS')&(d.evento==event)]
        c=compare_join(s,n,'total',['uf','ano','mes','evento'],'atividade estadual-mês')
        c['comparabilidade']='direta' if 'Mandado' in event else 'BM_mais_PC_rotulo_PC_armas_apreendidas_a_confirmar'
        if 'Arma' in event:c.loc[c.ano<=2016,'comparabilidade']='cobertura_institucional_historica_distinta_componentes_incompletos'
        comp.append(c)
    c=pd.concat(comp,ignore_index=True)
    c.to_csv(OUT/'comparacao_atividade_rs.csv',index=False,encoding='utf-8-sig')
    return c

def granularity(d):
    rows=[]
    for (uf,year,event),g in d.groupby(['uf','ano','evento']):
        municipal=g[g.chave!='NAO INFORMADO']
        missing=g[g.chave=='NAO INFORMADO']
        col='total_vitima' if g.total_vitima.notna().any() else 'total' if g.total.notna().any() else 'total_peso'
        rows.append(dict(uf=uf,ano=year,evento=event,unidade_coluna=col,municipios_nomeados=municipal.chave.nunique(),
            linhas=len(g),linhas_numericas=int(g[col].notna().sum()),linhas_sem_valor=int(g[col].isna().sum()),
            meses_numericos=','.join(map(str,sorted(g.loc[g[col].notna(),'mes'].unique()))),
            total=g[col].sum(min_count=1),total_localizado=municipal[col].sum(min_count=1),total_nao_localizado=missing[col].sum(min_count=1),
            dimensao_arma=g.arma.notna().any(),dimensao_agente=g.agente.notna().any(),dimensao_faixa_etaria=g.faixa_etaria.notna().any()))
    pd.DataFrame(rows).to_csv(OUT/'granularidade_sp_rs.csv',index=False,encoding='utf-8-sig')

def main():
    d=national();granularity(d)
    _,rs,summary=rs_comparisons(d)
    mon,sp=monitor_comparisons(d)
    act=activity(d)
    pd.DataFrame(sources).drop_duplicates().to_csv(OUT/'manifesto_insumos_estaduais.csv',index=False,encoding='utf-8-sig')
    print('MONITORES\n',mon.to_string(index=False),flush=True)
    print('RS recente\n',summary[summary.ano>=2022].to_string(index=False),flush=True)
    print('SP homicídio 2023',len(sp),'pares',sp.status_pareamento.value_counts().to_dict(), 'iguais',int((sp.diferenca==0).sum()),'soma abs',sp.diferenca.abs().sum(),flush=True)
    print('ATIVIDADE\n',act[act.status_pareamento=='both'].groupby(['ano','evento'])[['valor_estadual','valor_nacional','diferenca']].sum().to_string(),flush=True)

if __name__=='__main__':main()
