from pathlib import Path
import pandas as pd
import json
import hashlib
import subprocess
from auditoria_sinesp_comparacao import ROOT

OUT=ROOT/'outputs/tabelas/auditoria_sinesp_2026-10-03'
controls=[]
def check(name,condition):
    controls.append(dict(controle=name,aprovado=bool(condition)))
    if not condition:raise AssertionError(name)
manifest=pd.read_csv(ROOT/'data/raw/sinesp_vde/2026-10-03/MANIFEST_sinesp_vde.csv')
check('12 arquivos nacionais de 2015 a 2026',manifest.ano_link.tolist()==list(range(2015,2027)))
for r in manifest.itertuples():
    f=ROOT/r.arquivo
    check(f'integridade nacional {r.ano_link}',f.stat().st_size==r.bytes and hashlib.sha256(f.read_bytes()).hexdigest()==r.sha256)
state_manifest=pd.read_csv(OUT/'manifesto_insumos_estaduais.csv')
for r in state_manifest.itertuples():
    f=Path(r.arquivo)
    check(f'insumo estadual preservado {f.name}',f.stat().st_size==r.bytes and hashlib.sha256(f.read_bytes()).hexdigest()==r.sha256)
s=pd.read_csv(OUT/'comparacao_sp_homicidio_municipal_2023.csv')
print('SP não pareados',s[s.status_pareamento!='both'].to_string(index=False))
r=pd.read_csv(OUT/'comparacao_rs_mensal_municipal.csv',low_memory=False)
print('RS não pareados 2024',r[(r.status_pareamento!='both')&(r.ano==2024)].groupby(['evento','chave','status_pareamento'],dropna=False).valor_estadual.sum(min_count=1).to_string())
m=pd.read_csv(OUT/'comparacao_monitores_estadual_ano.csv')
print('MON SP 2023',m[(m.uf=='SP')&(m.ano==2023)][['evento','valor_estadual','valor_nacional','diferenca_pct']].to_string(index=False))
summ=pd.read_csv(OUT/'resumo_reconciliacao_rs.csv')
print('RS HISTÓRICO',summ[(summ.contexto=='estado-mês')&(summ.ano<2022)].to_string(index=False))
g=pd.read_csv(OUT/'granularidade_sp_rs.csv')
print('GRÃO RECENTE',g[(g.ano==2025)&(g.uf=='RS')][['evento','municipios_nomeados','meses_numericos','total','total_nao_localizado']].to_string(index=False))
dup=pd.read_csv(OUT/'linhas_chave_repetida_sp_rs.csv')
print('DUPLICIDADES',dup.groupby(['uf','ano','evento']).size().to_string())
cov=pd.read_csv(OUT/'cobertura_nacional_uf_indicador_ano.csv')
print('COBERTURA',cov.groupby('ano').agg(ufs=('uf','nunique'),eventos=('evento','nunique'),linhas=('lines','sum'),ind_uf_sem_valor=('valid',lambda s:int((s==0).sum()))).to_string())
check('27 UFs em cada ano',cov.groupby('ano').uf.nunique().eq(27).all())
check('linhas lidas iguais às dimensões XML',sum(int(x.split(':')[1][1:])-1 for x in manifest.dimensao_xml)==int(cov.lines.sum()))
check('SP 2023 todos os 645 municípios pareados',len(s)==645 and s.status_pareamento.eq('both').all())
h=pd.read_csv(OUT/'comparacao_sp_homicidio_mais_feminicidio_2023.csv')
check('SP 2023 harmonização estadual independente',h.valor_nacional.sum()==2728 and h.valor_estadual.sum()==2728)
check('SP 2023 639 municípios iguais na harmonização',int(h.diferenca.eq(0).sum())==639)
recent=summ[(summ.contexto=='estado-mês')&(summ.ano==2024)]
check('RS 2024 oito indicadores coincidem nos doze meses',len(recent)==8 and recent.iguais.eq(12).all())
check('chaves repetidas SP/RS não alteram totais de vítimas',dup.total_vitima.eq(0).all())
check('diferenças têm o sinal nacional menos estadual',(m.diferenca==m.valor_nacional-m.valor_estadual).all())
for f in ROOT.joinpath('scripts/exploratory').glob('*sinesp*.py'):
    compile(f.read_text(encoding='utf-8'),str(f),'exec')
check('scripts têm sintaxe válida',True)
check('sem dados brutos nacionais rastreados no Git',not subprocess.check_output(['git','ls-files','data/raw/sinesp_vde'],cwd=ROOT,text=True).strip())
check('repositório SP continua sem alterações',not subprocess.check_output(['git','status','--porcelain'],cwd=ROOT.parent/'MonitorPrisional2024',text=True).strip())
pd.DataFrame(controls).to_csv(OUT/'controles_validacao.csv',index=False,encoding='utf-8-sig')
print('Controles aprovados:',len(controls))
