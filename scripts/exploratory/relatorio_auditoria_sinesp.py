"""Relatório derivado da auditoria; não altera dados ou indicadores canônicos."""
import pandas as pd
import numpy as np
import json
from auditoria_sinesp_comparacao import ROOT

OUT=ROOT/'outputs/tabelas/auditoria_sinesp_2026-10-03'
def table(df):
    def fmt(v):
        if pd.isna(v):return '—'
        if isinstance(v,(float,np.floating)):return f'{v:,.2f}'.rstrip('0').rstrip('.').replace(',','@').replace('.',',').replace('@','.')
        return str(v).replace('|','/')
    return '| '+' | '.join(map(str,df.columns))+' |\n| '+' | '.join(['---']*len(df.columns))+' |\n'+'\n'.join('| '+' | '.join(map(fmt,r))+' |' for r in df.itertuples(index=False,name=None))

def main():
    man=pd.read_csv(ROOT/'data/raw/sinesp_vde/2026-10-03/MANIFEST_sinesp_vde.csv')
    cov=pd.read_csv(OUT/'cobertura_nacional_uf_indicador_ano.csv')
    gr=pd.read_csv(OUT/'granularidade_sp_rs.csv')
    summ=pd.read_csv(OUT/'resumo_reconciliacao_rs.csv')
    mon=pd.read_csv(OUT/'comparacao_monitores_estadual_ano.csv')
    sp=pd.read_csv(OUT/'comparacao_sp_homicidio_mais_feminicidio_2023.csv')
    rs=pd.read_csv(OUT/'comparacao_rs_mensal_municipal.csv',low_memory=False)
    act=pd.read_csv(OUT/'comparacao_atividade_rs.csv')
    schem=json.loads((OUT/'esquema_nacional.json').read_text(encoding='utf-8'))
    covsum=cov.groupby('ano').agg(UFs=('uf','nunique'),eventos=('evento','nunique'),linhas=('lines','sum'),UF_indicadores_sem_valor=('valid',lambda s:int((s==0).sum()))).reset_index()
    covsum.to_csv(OUT/'resumo_cobertura_nacional.csv',index=False,encoding='utf-8-sig')
    matrix=pd.DataFrame([
      ['Homicídio doloso','Municipal/mês; sexo','2015–2026','viável com limpeza/padronização','SP 2023 exige investigar HD + feminicídio; RS não deve receber essa soma. Reconciliar versões, categorias e geografia.'],
      ['Estupros total','Estadual/mês; sexo','2015–2026','metodologicamente problemático','Total nacional = vítimas de estupro + vulnerável; monitor = ocorrências. Sem município em SP/RS.'],
      ['Roubos — outros','Ausente','—','inviável com os dados atuais','Veículos, carga e instituições financeiras não reconstituem roubos — outros.'],
      ['Furtos — outros','Ausente','—','inviável com os dados atuais','Furto de veículo não substitui furtos — outros. Não resolve déficit de furtos 2022 no microdado RS.'],
      ['Armas apreendidas','Estadual/mês; espécie de arma','2015–2026','viável com limpeza/padronização','Viável para uma camada estadual; SP municipal não é substituível. Filtrar abrangência estadual e conferir PC/BM.'],
      ['Prisões efetuadas','Mandados municipal/mês; flagrantes ausentes','2015–2026','metodologicamente problemático','Mandados cumpridos não equivalem a flagrantes nem a prisões totais.'],
      ['Feminicídio e tentativa','Municipal/mês; sexo','2015–2026','viável com limpeza/padronização','Nova dimensão possível. A existência de grade não prova disponibilidade histórica em cada UF.'],
      ['Latrocínio/lesão seguida de morte','Municipal/mês; sexo','2015–2026','viável com limpeza/padronização','Usar vítimas, conferir definições e alterações históricas; RS 2015–2017 tem divergências relevantes.'],
      ['Veículos e tráfico','Estadual/mês','2015–2026','viável com limpeza/padronização','Boa reconciliação RS em muitos anos, mas sem localização municipal nesses XLSX.'],
    ],columns=['Indicador','Grão observado SP/RS','Janela publicada','Viabilidade','Condição/limite'])
    matrix.to_csv(OUT/'matriz_viabilidade.csv',index=False,encoding='utf-8-sig')
    rshd=summ[(summ.evento=='Homicídio doloso')&(summ.contexto=='município-ano')][['ano','pares','iguais','nacional','estadual','diferenca','diferenca_pct','soma_diferencas_absolutas']]
    recent=summ[(summ.contexto=='estado-mês')&(summ.ano.isin([2024,2025]))][['ano','evento','nacional','estadual','diferenca','diferenca_pct','iguais','pares']]
    sp23=mon[(mon.uf=='SP')&(mon.ano==2023)][['evento','valor_nacional','valor_estadual','diferenca','diferenca_pct','comparabilidade']]
    sp25=mon[(mon.uf=='SP')&(mon.ano==2025)&(mon.meses_nacional==11)][['evento','valor_nacional','valor_estadual','diferenca','diferenca_pct','comparabilidade']]
    rsp=mon[(mon.uf=='RS')&(mon.variavel_monitor=='tot_estupro')][['ano','valor_nacional','valor_estadual','diferenca','diferenca_pct']]
    spdiff=sp[sp.diferenca!=0][['chave','valor_nacional','valor_estadual','diferenca']]
    activity=act[act.status_pareamento=='both'].groupby(['ano','evento']).agg(nacional=('valor_nacional','sum'),estadual=('valor_estadual','sum'),meses_pareados=('mes','size'),diferenca=('diferenca','sum')).reset_index()
    activity['diferenca_pct']=100*activity.diferenca/activity.estadual
    activity=activity[activity.ano>=2017]
    sample=gr[(gr.uf=='RS')&(gr.ano==2025)][['evento','municipios_nomeados','unidade_coluna','total_nao_localizado','dimensao_arma','dimensao_agente','dimensao_faixa_etaria']]
    hd25=rs[(rs.contexto=='município-ano')&(rs.ano==2025)&(rs.evento=='Homicídio doloso')&(rs.status_pareamento=='both')].sort_values('diferenca',key=lambda s:s.abs(),ascending=False).head(12)
    hd25.to_csv(OUT/'maiores_diferencas_homicidio_rs_2025.csv',index=False,encoding='utf-8-sig')
    zero=cov[(cov.valid>0)&(cov.nonzero==0)]
    zero.to_csv(OUT/'alertas_series_nacionais_somente_zero.csv',index=False,encoding='utf-8-sig')
    missing=cov[cov.valid==0]
    missing.to_csv(OUT/'lacunas_nacionais_uf_indicador_ano.csv',index=False,encoding='utf-8-sig')
    raw_mb=man.bytes.sum()/1024**2
    report=f'''# Auditoria Sinesp VDE e viabilidade de expansão nacional do Monitor Prisional

Data da auditoria: 03/10/2026. Snapshot nacional: `data/raw/sinesp_vde/2026-10-03/`. Evidência numérica: `outputs/tabelas/auditoria_sinesp_2026-10-03/`. Fontes estaduais: arquivos locais existentes, com hashes no manifesto. Nenhum pipeline canônico foi executado; nenhuma fonte ou saída vigente foi substituída.

## Parecer

**A base é uma alternativa tecnicamente viável para uma camada nacional seletiva, com ingestão automatizada. Ela não substitui integralmente as fontes estaduais do monitor atual.** Homicídios e outros indicadores letais têm dados municipais. Estupros, apreensões de armas e os recortes patrimoniais disponíveis são estaduais nos arquivos examinados de SP e RS. Roubos e furtos “outros” não estão presentes. Mandados cumpridos não equivalem ao indicador de prisões efetuadas.

**Fato observado:** as diferenças não têm uma única magnitude. No RS, diversos indicadores coincidem exatamente em muitos anos. Em 2025, comparado ao arquivo local SSP-RS, homicídios diferem em +1,35% e roubos de veículos em +4,41%. Em SP 2023, a comparação direta de homicídio gera −8,10%, mas a soma nacional de homicídio e feminicídio reproduz o total do monitor: 2.507 + 221 = 2.728. Depois dessa harmonização experimental, 639 dos 645 municípios coincidem, com diferenças residuais em seis municípios.

**Inferência:** boa parte da equivalência depende de taxonomia, unidade de contagem, localização e versão. A uniformidade de formato e aquisição não garante uniformidade substantiva. **Decisão pendente:** a substituição de qualquer indicador canônico exige ratificação da equipe; esta auditoria não promove a base nacional.

## 1. Aquisição, origem e versões

Foram baixados todos os 12 XLSX oferecidos na página, de 2015 a 2026, preservados sem edição: **{raw_mb:.1f} MiB**, **{sum(s['linhas'] for s in schem):,} registros**. Cada arquivo tem URL, instante UTC, tamanho e SHA-256 no `MANIFEST_sinesp_vde.csv`. A página HTML original foi preservada. Os arquivos brutos estão ignorados pelo Git; não houve commit ou push.

A URL fornecida ainda termina em “2022-e-2023”, mas a página se apresenta como 2015–2026. A referência de aquisição são os links efetivamente encontrados no HTML, não o texto do endereço. Os downloads são HTTP públicos, sem login ou execução de navegador. A automação de aquisição foi testada nesta auditoria. Não foi agendada atualização recorrente.

Os dados são informados pelos gestores estaduais e outros órgãos, conforme a Resolução ConSinesp nº 6/2021. O arquivo mistura `Estadual`, `Polícia Federal` e `Polícia Rodoviária Federal`. **Todas as reconciliações estaduais deste relatório usam exclusivamente `abrangencia == Estadual`**. A tabela de cobertura geral inclui todas as abrangências e serve ao inventário, não à soma comparativa entre SSPs.

O snapshot de 2026 é parcial: em SP/RS os indicadores estaduais apresentam meses numéricos de janeiro a agosto. Comparações de atividade RS em 2026 usam somente os meses numéricos em comum com o arquivo estadual local, explicitados nas tabelas. Não se compara essa soma parcial com um ano inteiro.

### Inventário nacional e lacunas

{table(covsum)}

“UF_indicadores_sem_valor” significa combinação UF×evento sem valor numérico em nenhuma linha do arquivo anual, considerando as abrangências existentes; não significa falta de ocorrências. A grade de linhas, municípios e meses pode existir mesmo quando as medidas estão vazias. Séries integralmente zeradas foram listadas como alerta de investigação, não classificadas automaticamente como lacuna. A auditoria de conteúdo e reconciliação com SSPs foi aprofundada em SP e RS; nos demais estados, realizou-se inventário de estrutura e disponibilidade numérica.

## 2. Desagregação e unidades

Os 14 campos são: `uf`, `municipio`, `evento`, `data_referencia`, `agente`, `arma`, `faixa_etaria`, `feminino`, `masculino`, `nao_informado`, `total_vitima`, `total`, `total_peso`, `abrangencia`. Não há código IBGE, ID de boletim, bairro, data diária do fato, raça/cor ou situação de homologação por linha. `data_referencia` representa o mês, não a data individual da ocorrência.

`total_vitima` deve ser usado para vítimas; `total` para ocorrências, armas, atendimentos ou documentos, conforme o evento; `total_peso` para apreensões em peso. As três colunas não são intercambiáveis. Também não se soma `total_vitima` ao total de sexo: o primeiro reproduz feminino + masculino + não informado, relação verificada no recorte SP/RS inteiro.

Em SP/RS, o bloco municipal contém homicídio doloso, feminicídio, tentativas de homicídio/feminicídio, latrocínio, lesão corporal seguida de morte, suicídio, mortes a esclarecer, mortes no trânsito de abrangência estadual e mandados cumpridos. No RS de 2025, cada um apresenta 497 nomes municipais, além de “NÃO INFORMADO”; em SP, 645. A presença de nomes é distinta da presença de valores e da validação da territorialização.

Nos demais indicadores, `municipio = NÃO INFORMADO` representa o dado estadual sem localização, não um município nem uma base municipal com valores zero. Armas têm espécie; desaparecidos/localizados têm faixa etária; mortes de agentes têm categoria de agente. Essas dimensões estão nesses blocos estaduais e não criam recortes municipais. `agente` não identifica a instituição apreensora de armas: não permite, por si só, separar PC de BM nesse indicador.

{table(sample)}

A SSP-RS oferece microdados com município, bairro/local, data/hora do fato, enquadramento, consumado/tentado e características das vítimas. O Sinesp agrega e perde essas possibilidades de reconstrução. Os insumos SP incluem tabelas municipais e export do monitor; o Sinesp perde o município para estupro e armas. Regiões intermediárias/“macrorregiões” não são nativas no Sinesp, mas podem ser derivadas do município mediante crosswalk IBGE.

## 3. Método de comparação e controles

1. Preservar snapshots e comparar dados locais com a versão nacional de 03/10/2026. Arquivos estaduais não foram atualizados ou regravados.
2. Selecionar a mesma abrangência institucional e o mesmo período, explicitando comparações parciais. O SP publicado local tem 2001, 2023 e 2025; 2001 está fora da janela nacional. O script SP de validação de 2025 lê janeiro–junho e julho–novembro; os totais de 2025 são tratados como parciais e a definição por indicador permanece sob conferência.
3. Usar comparação direta apenas entre a mesma medida. Homicídio/latrocínio/lesão: vítimas, não número de boletins. Estupro do monitor: ocorrências; Sinesp: vítimas. Prisões totais/flagrantes e mandados: conceitos diferentes.
4. Normalizar acentos, caixa e pontuação e aplicar aliases explicitamente verificados. SP: Florínia/Florínea e São Luís/São Luiz do Paraitinga. RS VCM: Barão do Cotegipe/Barão de Cotegipe e Xangrila/Xangri-lá. Os aliases anteriores do projeto foram preservados na camada de auditoria. Não houve fuzzy matching ou alteração dos nomes brutos.
5. Somar registros por chave analítica, sem deduplicar automaticamente. O portal avisa sobre duas linhas de estupro/tentativa de homicídio. No recorte SP/RS foram encontradas chaves completas repetidas também em outros eventos, todas no município “NÃO INFORMADO”, com total de vítimas zero. As linhas foram mantidas e registradas; nesse recorte não alteram os totais. Estupro e estupro de vulnerável foram somados explicitamente para o total de vítimas de violência sexual.
6. Calcular Δ = nacional − estadual e Δ% = 100×Δ/estadual. Denominador zero gera percentual indisponível. Ausência de linha/valor permanece ausência; não é preenchida com zero. Relatar também pares iguais e soma de |Δ| para detectar compensação entre municípios/meses.

Não foram recalculadas taxas populacionais. Comparar a mesma contagem entre fontes não requer denominador; converter em taxa não corrige diferença de definição. Uma futura publicação deve fixar população por município/ano e manter notas sobre o registro criminal e as revisões.

## 4. Rio Grande do Sul

### Homicídio: vítimas por município e ano

{table(rshd)}

Os totais de 2022 e 2024 coincidem, mas há dois municípios com diferenças compensadas em cada ano. Em 2025 são 30 municípios diferentes e soma de diferenças absolutas de 42 vítimas, enquanto a diferença líquida é 14. Logo, igualdade estadual ou pequeno desvio percentual não prova igualdade territorial. Os maiores resíduos constam de `maiores_diferencas_homicidio_rs_2025.csv`.

### Indicadores semelhantes da SSP-RS, comparação estado/mês

{table(recent)}

Em 2024 os oito indicadores listados coincidem nos 12 meses. Em 2023, a maior parte também coincide ou tem diferenças pequenas. Em 2025 surgem resíduos maiores: lesão seguida de morte (+6,98%, três vítimas), latrocínio (+6,67%, duas vítimas), roubo de veículo (+4,41%, 79 ocorrências). As tabelas preservam a dimensão absoluta para evitar exagerar diferenças percentuais em eventos raros.

**Limitação temporal:** os arquivos estaduais locais têm datas distintas: homicídios/veículos 2025 usam atualização de maio/2026; Sinesp foi obtido em outubro/2026. A página atual da SSP-RS já anuncia revisão de setembro/2026 para 2025. Portanto, estes resíduos são diferenças entre snapshots, não prova de erro no envio estadual. Não foi isolada causalmente a contribuição de revisão, data de referência ou taxonomia.

**Histórico 2015–2017:** as divergências por categoria podem ser relevantes. Em 2015, vítimas de latrocínio: nacional 112 e estadual 145 (−22,76%); lesão seguida de morte: 25 versus 33 (−24,24%). Em 2016, latrocínio: 126 versus 169 (−25,44%); lesão: 17 versus 27 (−37,04%). Em 2017, latrocínio: 96 versus 137 (−29,93%). Já furto/roubo de veículos e tráfico coincidem nesses anos. A série histórica não deve ser declarada uniformemente reconciliada com base nos resultados recentes.

### Armas e mandados na atividade estadual

{table(activity)}

De 2017 a 2025, os totais anuais nacionais de armas coincidem com a soma dos componentes BM e PC extraídos das tabelas de atividade. Exemplo: 2024 = 5.386 BM + 3.893 PC = 9.279. O rótulo PC é “armas apreendidas pela PC”, a ser confirmado como exclusivamente armas de fogo antes de fixar regra conceitual. Essa concordância anual não dispensa o exame mensal disponível no CSV.

Mandados coincidem no total anual em 2017–2019 e 2022–2025; divergem em 2020 (+115) e 2021 (−46). A base nacional disponibiliza mandados por município, o que é uma **nova possibilidade concreta** para complementar o RS, que utiliza flagrantes municipais e mandados estaduais. É preciso ratificar se a localização nacional é de cumprimento, registro ou outra referência, e confirmar a unidade pessoa/mandado antes de somar a flagrantes. A norma e os arquivos não fornecem ID individual que permita deduplicar pessoas.

2015–2016 foram preservados na comparação de atividade como casos de cobertura institucional histórica distinta/componentes incompletos, e excluídos da tabela acima. A nota da PC informa mudança de metodologia e impossibilidade anterior de separar as apreensões exclusivas da instituição. Não interpretar essas diferenças como simples falha nacional.

### Estupro: diferença medida entre unidades diferentes

{table(rsp)}

Nacional = vítimas de estupro + estupro de vulnerável; estadual = linhas de ocorrências consumadas agregadas no produto RS. Os percentuais são diferenças numéricas observadas, **não taxas de erro nem medidas de subnotificação**. Sem equivalência vítimas/ocorrências e sem município no Sinesp, não há substituição direta. O recorte VCM não foi usado como total equivalente de estupros.

## 5. São Paulo

### Comparação com o monitor, 2023

{table(sp23)}

**Harmonização experimental de homicídio:** 2.507 nacional em homicídio + 221 em feminicídio = 2.728 no monitor. O total coincide, e **639/645 municípios (99,07%)** coincidem após aliases. Há seis resíduos municipais, soma de diferenças absolutas = 10, e diferença líquida estadual zero:

{table(spdiff)}

Esse teste sustenta a interpretação de diferença de composição no indicador homônimo de SP 2023, com pequenos resíduos de territorialização/versão. **É inferência apoiada pela decomposição empírica**, não uma instrução oficial verificada do gestor SP para todo o período. A página VDE consultada não oferece nota específica de SP ou RS. A fórmula não pode ser aplicada universalmente: no RS 2024, o homicídio nacional sozinho já reproduz as 1.418 vítimas estaduais, e acrescentar 73 feminicídios produziria dupla contagem em relação ao agregado de referência.

Estupros diferem em +7,16%, com unidades distintas. Armas diferem em −1,04%, além da perda do município. A comparação entre mandados e prisões efetuadas é mantida apenas para demonstrar a incompatibilidade de conceito; −56,82% não significa que a base nacional deixou de registrar esse percentual de prisões.

### SP 2025, comparação nacional janeiro–novembro

{table(sp25)}

A comparação anual integral também foi calculada e preservada em `comparacao_monitores_estadual_ano.csv`, explicitamente rotulada com 12 meses. Ela não é o teste de equivalência temporal com o produto parcial SP. Armas janeiro–novembro ficam próximas: 12.898 versus 12.889 (+9; +0,07%). Homicídio tem ainda o problema de vítimas no Sinesp versus contagem de linhas pelo script SP de 2025. Portanto, não há ratificação de equivalência só pelo alinhamento de meses. O painel online não foi usado como prova de regeneração; a referência é o export local inspecionado.

## 6. Matriz de viabilidade

{table(matrix)}

**Proposta:** manter uma camada nacional comum de indicadores validados e uma camada estadual complementar. O núcleo prisional SISDEPEN não muda. Para o RS, homicídio é o candidato mais forte a substituição seletiva; armas estaduais são outro candidato condicionado à abrangência. Para SP, homicídio exige harmonização por ano e ratificação. Estupro municipal, armas municipais SP, roubos/furtos “outros” e prisões totais requerem fontes estaduais ou novo desenho do monitor.

Uma ampliação nacional pode incluir homicídios, feminicídios, latrocínios, lesões seguidas de morte e mandados municipais, além de um painel estadual separado de estupros, veículos, tráfico e armas. Esses indicadores novos devem ser nomeados por sua medida real. Não manter o nome antigo do indicador quando a fonte entrega outro conceito.

## 7. Roteiro de implementação após ratificação

1. Aprovar indicador, unidade e grão; definir lista nacional comum e lista de complementos estaduais. Registrar uma regra UF×indicador×período para sobreposição homicídio/feminicídio e outras categorias.
2. Criar adaptador Sinesp separado do pipeline atual, utilizando os scripts exploratórios como prova técnica. Aquisição por descoberta dos links do portal, download completo para pasta de versão, verificação de XLSX, hash, dimensões e esquema. Não sobrescrever snapshots.
3. Criar crosswalk municipal com códigos IBGE e aliases auditados; guardar “não informado” em categoria territorial separada. Não ratear totais estaduais.
4. Automatizar controles de cobertura numérica UF/indicador/mês, lacunas versus zero, chaves repetidas, soma por sexo, abrangência, sobreposição de categorias e reconciliação com snapshots estaduais. Produzir relatório de mudança entre versões nacionais, inclusive revisões de anos antigos.
5. Definir política para 2026 provisório e data de corte por UF/indicador; publicar última atualização e meses disponíveis. Atualização homogênea de arquivos não implica defasagem idêntica entre estados.
6. Antes de expandir aos demais estados, revisar as notas dos gestores, zeros sistemáticos e combinações sem valor inventariadas. Priorizar pelo menos um teste independente por UF/indicador selecionado. Não extrapolar a reconciliação SP/RS como validação dos demais estados.

## 8. Limitações e decisões abertas

- Ratificar com SP a composição homicídio/feminicídio e a unidade de 2025. O teste 2023 é forte, mas não generaliza sozinho.
- Confirmar referência territorial e unidade de mandados nacionais; ausência de ID impede deduplicação de pessoas.
- Distinguir o efeito de atualização do estadual 2025 do efeito de taxonomia, comparando versões com cortes documentados em etapa posterior.
- Validar zeros históricos e cobertura real por UF. São informações declaradas por gestores; os registros não medem criminalidade não registrada.
- Manter fontes estaduais para indicadores ausentes ou com grão mais fino. As taxas populacionais e a composição regional permanecem decisões do monitor.
- A infraestrutura de automação foi testada para aquisição e auditoria nesta máquina. Não foram testadas execuções futuras nem criado agendamento, e não foi instalado pacote ou serviço.

## 9. Artefatos e reprodução

- Brutos: `data/raw/sinesp_vde/2026-10-03/bancovde-AAAA.xlsx`, HTML original, metadados HTTP e `MANIFEST_sinesp_vde.csv` (SHA-256).
- Intermediários ignorados pelo Git: `data/intermediate/sinesp_vde/2026-10-03/recorte_sp_rs_AAAA.csv.gz` e extração da SSP-RS.
- Tabelas principais: `resumo_reconciliacao_rs.csv`, `comparacao_rs_mensal_municipal.csv`, `comparacao_monitores_estadual_ano.csv`, `comparacao_sp_homicidio_mais_feminicidio_2023.csv`, `comparacao_atividade_rs.csv`, `granularidade_sp_rs.csv`, `matriz_viabilidade.csv`.
- Controles: manifestos, `linhas_chave_repetida_sp_rs.csv`, `lacunas_nacionais_uf_indicador_ano.csv`, `alertas_series_nacionais_somente_zero.csv`, `resumo_cobertura_nacional.csv`.
- Validação executada: `controles_validacao.csv` registra a conferência dos hashes nacionais/estaduais, dimensões, cobertura, totais, pareamento e preservação do repositório SP. As verificações foram aprovadas. Isso valida a reprodução desta auditoria, não elimina as limitações substantivas listadas.

Com o Python e bibliotecas pandas, numpy, openpyxl e lxml disponíveis:

```powershell
python scripts/exploratory/auditoria_sinesp_inspecao.py --snapshot 2026-10-03
python scripts/exploratory/auditoria_sinesp_comparacao.py --snapshot 2026-10-03
python scripts/exploratory/comparar_sinesp_fontes_estaduais.py
python scripts/exploratory/relatorio_auditoria_sinesp.py
python scripts/exploratory/verificar_auditoria_sinesp.py
```

Para nova aquisição, usar outra data de snapshot; não reutilizar a pasta histórica. Os três scripts posteriores estão fixados no snapshot desta auditoria, que deve ser alterado explicitamente se o objetivo for produzir uma nova análise.

## Fontes e localização da evidência

- [MJSP — página VDE 2015–2026](https://www.gov.br/mj/pt-br/assuntos/sua-seguranca/seguranca-publica/estatistica/dados-nacionais-1/base-de-dados-e-notas-metodologicas-dos-gestores-estaduais-sinesp-vde-2022-e-2023), acesso 03/10/2026; URLs anuais no manifesto.
- [ConSinesp — Resolução nº 6/2021](https://bibliotecadigital.mj.gov.br/bitstream/1/5913/5/RES_CONSINESP_2021_6.html), origem, unidades e fluxo de envio/homologação. Consultada como referência metodológica; não realizada auditoria jurídica de vigência normativa.
- [SSP-RS — Indicadores Criminais](https://www.ssp.rs.gov.br/indicadores-criminais), usada para verificar a existência de revisão 2025 mais recente. A comparação numérica utiliza arquivos locais preservados.
- Monitor SP: export `data/raw/bases_data_studio/Variáveis de contexto - dinamica_criminal.csv` no RS; `dados_ssp_2023.xlsx` no checkout SP confirma os totais de 2023. Script `R:validation/criminal_data_proccessing.R` confirma a leitura parcial 2025 e contagem de registros; `R:dados municípios_variaveis.R` identifica as rubricas de 2023. Inspeção de branches, sem checkout, edição, commit ou push no SP.
- Monitor RS: `data/processed/criminal_rs_municipio_ano.csv`, `R/funcoes_criminal.R`, `scripts/rs/02_criminal.R`, `scripts/rs/02b_atividade.R`, `scripts/rs/05_planilha_final.R`, tabelas oficiais em `data/EstatisticasCriminaisRS/`; caminhos e hashes dos insumos numéricos em `manifesto_insumos_estaduais.csv`.
'''
    (ROOT/'docs/auditoria_sinesp_vde_2026-10-03.md').write_text(report,encoding='utf-8')
    print('Relatório gerado',len(report),'caracteres')
    print('Harmonização SP',sp.valor_nacional.sum(),sp.valor_estadual.sum(),len(spdiff),'municípios divergentes')
    print('Meses 2026 SP/RS',gr[gr.ano==2026].meses_numericos.unique())

if __name__=='__main__':main()
