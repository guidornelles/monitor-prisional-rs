# Pipeline da versão candidata do Monitor Prisional RS

O pipeline R gera as tabelas do RS para uma cópia de revisão no Data Studio. A PoC de junho e o Monitor SP servem de referência e não são atualizados por este processo. A PoC que compara os dois estados é uma entrega posterior.

Este guia incorpora as regras aprovadas em 15/11/2026 e as decisões mantidas na revisão de 20/11. Os critérios e testes da candidata conectada em 13/11 estão registrados no [guia do Data Studio](../../docs/looker_studio_guia.md). A execução integral e os testes finais de 20/11 foram concluídos em `outputs/temp/revisao_pipeline_2026-11-20`, com zero falhas de cálculo. Essa revisão local não substituiu arquivos canônicos ou conexões nem publicou ou atualizou o painel.

| Camada | Janela da candidata | Unidade principal |
| --- | --- | --- |
| Dinâmica criminal | 2022–2025 (`cfg$anos_criminal`) | Município × ano. Armas, quando exibidas, permanecem em fonte separada por estado × ano. |
| Dados prisionais | 2017–2025 (`cfg$anos_prisional`) | Estabelecimento de cela física × ano. Estoques no primeiro semestre; óbitos dos dois semestres, com cobertura verificada. |
| Contexto e saúde | Janelas próprias | Município ou município × ano, conforme a fonte. A saúde preserva os cortes por indicador. |

2026 fica fora da candidata. A ampliação prisional para 2026 será feita na próxima atualização anual. A futura PoC RS–SP pode partir de 2022, com a base paulista de 2022 e apenas indicadores e competências harmonizados.

## Preparação e insumos

1. Trabalhe a partir da raiz do projeto, com as dependências de `renv.lock`. Se a biblioteca ainda não estiver disponível, restaure-a com `renv::restore()`. Defina `MONITOR_RS_RUN_DIR` com um diretório novo para isolar a execução. A candidata de 12/11/2026 foi gerada em `outputs/temp/candidata_2026-11-12`. Sem essa variável, as rotinas escrevem nos diretórios padrão.
2. Fixe a versão dos arquivos da SSP-RS antes da execução. Use a extração revisada de **23/06/2026** para 2022 e identifique a extração de cada um dos outros anos. O [portal da SSP-RS](https://www.ssp.rs.gov.br/dados-abertos) também oferece uma versão de 2025 extraída em **06/10/2026**; o uso de uma nova extração exige reconciliação contra a anterior. Registre arquivo, origem, data e hash. Preserve a PoC e os brutos anteriores; não edite os dados brutos.
3. Fixe a Base Única do SISDEPEN e o snapshot do Sinesp VDE. Para o Sinesp, confira `cfg$sinesp_dir` e o manifesto de aquisição. A referência da [auditoria](../../docs/auditoria_sinesp_vde_2026-10-03.md) é o snapshot de 03/10/2026. Uma atualização do portal constitui outra versão a auditar.
4. Se algum insumo faltar, use `01a_download_ssp_rs.R` (SSP-RS), `01_download.R` (IBGE e demais insumos nacionais) ou `01b_download_sisdepen.R` (Base Única; arquivos por ciclo como alternativa). Para atualizar só as entradas da dinâmica criminal, use `MONITOR_RS_SSP_CATEGORIAS=mensais,indicadores_criminais` antes de `01a`. Os microdados mensais são extraídos em pasta por ZIP de versão fixada no catálogo `data/raw/ssp_rs_fontes.csv`. Para saúde, a ingestão canônica é a de exportações TABNET em `04b_saude.R`; `01c_download_datasus.R` é uma alternativa apenas para mortalidade.
5. Confira os anos explícitos em `cfg$contexto`: `ano_populacao = 2022L`, `ano_pib = 2023L` e `ano_tdi = 2025L`. `01_download.R` e `04_contexto.R` usam os mesmos parâmetros; não selecione um arquivo Inep pela ordem em que aparece na pasta. Preserve edições anteriores e identifique o arquivo ativo por ano. O ZIP `TDI_2025_MUNICIPIOS.zip` está fixado em `cfg$inep_tdi_zip_md5`, MD5 `7c20771f6ab6d3dd3afaf0a6faea58c9`; o XLSX está fixado em `cfg$inep_tdi_xlsx_md5`, MD5 `1845302b4368913b66103cc8abfd27ca`, publicado pelo Inep dentro do ZIP e conferido na revisão. O download usa arquivo temporário, promovido apenas com hash válido. A extração existente não é sobrescrita; exige-se um único XLSX do ano, com o hash conferido também no processamento e na validação. Hash divergente exige revisão da edição e reconciliação, sem atualização automática da referência.

Para a tuberculose de 2025, `04b_saude.R` usa a tabulação municipal fixada em `data/raw/nacional/saude/`, com 497 municípios e zeros explícitos. A consulta usa município de residência nas linhas, ano de diagnóstico nas colunas, conteúdo **Casos confirmados**, UF de residência RS, os arquivos de 2024 e 2025 e a opção **Exibir linhas zeradas**. A versão de maio de 2026 permanece sujeita a revisão. As exportações históricas ficam como insumos do restante da série. [Formulário TabNet](https://tabnet.datasus.gov.br/cgi/deftohtm.exe?sinannet/cnv/tubercbr.def).

## Processamento

A partir da raiz do projeto, execute o processamento integral em um diretório novo. Exemplo em PowerShell, com R disponível no terminal.

```powershell
$env:MONITOR_RS_RUN_DIR = 'outputs/temp/revisao_2026-11-13'
Rscript scripts/rs/run_all.R
```

As etapas leem os insumos preservados em `data/raw/` e gravam os resultados em `intermediate/`, `processed/`, `tabelas/` e `auditoria/` sob o diretório de execução. A aquisição ocorre antes do processamento. O [índice de insumos](../../data/raw/README.md) distingue os arquivos versionados das bases baixadas localmente.

| Etapa | O que produz ou valida |
| --- | --- |
| `02_criminal.R` | Reconstrói ocorrências consumadas do microdado e reconcilia com o agregado oficial. Vítimas de homicídio vêm do agregado; ocorrências de homicídio são mantidas para conferência. |
| `02b_atividade.R` | Registros de flagrantes da Polícia Civil pela SSP-RS. Soma arquivos disponíveis e audita semestres ausentes ou parciais. |
| `03_prisional.R` e `03b_prisional_derivadas.R` | Base de cela física, estoque do primeiro semestre e fluxos derivados. Para óbitos 6.8, soma os dois semestres com zeros de contribuição e cobertura preservada. |
| `04_contexto.R` e `04b_saude.R` | Municípios e regiões intermediárias do IBGE, população 2022, PIB 2023 em mil R$ correntes e distorção idade-série 2025; séries municipais de saúde com cortes próprios. |
| `02c_mandados_sinesp.R` | Pessoas com mandado cumprido, abrangência estadual do VDE, associadas ao código IBGE. Soma os meses informados e audita cobertura, valores sem localização e reconciliação estadual. |
| `05_planilha_final.R` | Consolida as tabelas de criminal, prisional, contexto e saúde, com chaves e taxas onde aplicáveis. |
| `05b_export_formato_sp.R` | Gera `formato_sp/contexto_dados.csv`, `formato_sp/dinamica_criminal.csv`, `formato_sp/dados_saude.csv` e `formato_sp/mandados_estadual.csv` para apresentação. A tabela prisional entra diretamente. |
| `06_auditoria.R` e `07_validacao_prisional.R` | Reúnem os controles das tabelas geradas, inclusive cobertura, chaves, reconciliação e óbitos anuais. |
| `08_validacao_contexto.R` | Confronta fontes de contexto com valores processados, exportados e usados nas taxas; verifica anos, unidades, chaves e os 497 municípios. Integra `run_all.R`. |

O auxiliar [`R/funcoes_contexto.R`](../../R/funcoes_contexto.R) é compartilhado por aquisição, processamento e validação. Ele verifica os hashes do ZIP e do XLSX do Inep, seleciona o arquivo do ano e verifica conteúdo, unidade e chaves das fontes. `04_contexto.R` grava `contexto_fontes.csv` com arquivo, ano e MD5; `08_validacao_contexto.R` grava `validacao_contexto.md` e interrompe a execução quando há divergências. Esses arquivos ficam na pasta `auditoria/` da execução. Os testes de contrato em [`scripts/tests/test_contexto.R`](../tests/test_contexto.R) cobrem seleção do ano, ausência e ambiguidade de arquivo, hashes, referência, unidade e chaves; execute-os da raiz com `Rscript scripts/tests/test_contexto.R`.

### Atualizar uma camada

Para uma alteração pontual, use outro `MONITOR_RS_RUN_DIR` e copie para `processed/` as saídas intermediárias da execução validada de referência. Assim as etapas comuns podem usar as outras camadas da mesma edição. Rode as etapas na ordem abaixo e compare as saídas com a execução anterior antes de trocar uma conexão.

| Atualização | Etapas antes dos exportadores |
| --- | --- |
| Ocorrências e vítimas | `01a_download_ssp_rs.R` para as categorias `mensais,indicadores_criminais`, depois `02_criminal.R`. |
| Flagrantes da Polícia Civil | `01a_download_ssp_rs.R` para `semestrais`, depois `02b_atividade.R`. Confira os arquivos disponíveis, a competência de cada extração e a cobertura registrada na auditoria. |
| Mandados do Sinesp VDE | Fixe o snapshot e a referência estadual, depois rode `02c_mandados_sinesp.R`. Aceite meses sem valor nas duas fontes. Confira divergências de valor ou de cobertura entre elas. |
| Estoques, perfil, condições ou fluxos prisionais | `01b_download_sisdepen.R` se o insumo faltar, depois `03_prisional.R`, `03b_prisional_derivadas.R` e `04_contexto.R` para recalcular presença de estabelecimentos. |
| Panorama de Saúde | Arquive versões anteriores fora da pasta de ingestão. Mantenha uma edição ativa por indicador, município e ano. Atualize o insumo e o corte do indicador validado, depois rode `04b_saude.R`. |
| Cadastro municipal ou denominador | `01_download.R` para adquirir os insumos faltantes, depois `04_contexto.R`. Rode também `02c_mandados_sinesp.R` se mudar a associação municipal. |

Finalize com `05_planilha_final.R`, `05b_export_formato_sp.R`, `06_auditoria.R`, `07_validacao_prisional.R` e `08_validacao_contexto.R`. Essas etapas também podem regerar tabelas de outras camadas. Compare seus hashes com a referência para verificar se a alteração ficou no escopo. A revisão de 20/11 ampliou a validação prisional para recalcular indicadores a partir dos quesitos de origem, além das consistências entre derivados, e executou os validadores sem falhas de cálculo; em novas execuções, guarde os respectivos resultados antes de aprovar as tabelas.

### Atualizar os panoramas populacional, econômico e educacional

O [script de panoramas históricos](../exploratory/preparar_panoramas_historicos_rs.py) requer Python e `openpyxl`, além dos CSVs de cadastro municipal e população do Censo 2022 preparados por `01_download.R`. Ele consulta o SIDRA e o Inep, valida cobertura e totais e grava três CSVs e o `manifesto_panoramas.json`. A execução de referência usou a pasta `outputs/temp/candidata_2026-11-12/panoramas_historicos`.

```powershell
python scripts/exploratory/preparar_panoramas_historicos_rs.py --baixar --saida outputs/temp/revisao_2026-11-13/panoramas_historicos
```

Para refazer as tabelas a partir dos mesmos insumos, reutilize a pasta com os downloads e execute o comando sem `--baixar`. Para ampliar os períodos, confirme a nova divulgação e ajuste os anos e verificações de cobertura no script. O PIB usa mil reais correntes; preserve essa escala e o rótulo `PIB (mil R$ correntes)`, também no contexto de ano único. As linhas censitárias preservam a cobertura municipal de cada edição e usam o cadastro atual de regiões intermediárias. A distorção idade-série é do ensino fundamental de **2025**, total municipal de redes e localizações (`FUN_CAT_0`), no contexto e no panorama histórico. A candidata mantém a média simples das taxas municipais por região, identificada como média; não é a taxa calculada sobre todas as matrículas regionais. Para carregar os gráficos, use somente as linhas `Recorte = Município` e guarde as linhas `Estado` para conferência.

A troca do cabeçalho legado `PIB (em R$)` por `PIB (mil R$ correntes)` corrige a unidade, sem multiplicar os valores por mil. Na próxima conexão de contexto no Data Studio, atualize os campos da fonte e confira ou remapeie os gráficos e campos calculados que referenciam o nome anterior. A revisão local de 20/11 não realiza essa troca na planilha ou no painel.

### Escolhas prisionais preservadas em 20/11

O RS mantém a categoria nativa **“Cela física”**, estoques de junho e o total de médicos das **quatro categorias** do quesito 3.1: clínicos gerais, ginecologistas, psiquiatras e outras especialidades. Em 2025/1, são 103 estabelecimentos e 38.519 pessoas. A exportação paulista auditada tem 181 registros e 214.159 pessoas, ante 180 e 213.401 na categoria “Cela física”; a diferença é o registro de **“Prisão domiciliar com monitoração eletrônica”**, com 758 pessoas. O script SP também exporta três campos médicos; essa seleção não demonstra a fórmula do gráfico. A [consulta complementar à equipe SP](../../docs/email_complementar_sp_recorte_medicos.md) pede confirmação de intencionalidade; ela não condiciona a preservação das escolhas RS. Consulte as [decisões metodológicas](../../docs/decisoes_metodologicas.md) para harmonizar um recorte comparativo separado.

O Sinesp não substitui o microdado estadual. Mandados cumpridos e flagrantes aparecem separados; o indicador paulista **Prisões efetuadas** reúne flagrantes e prisões por mandado, mas conta prisões, não a soma de pessoas presas. O total RS só pode ser equiparado depois de validar unidade, geografia e cobertura institucional.

Nas contagens numéricas do formulário prisional, converta o vazio em contribuição zero no painel, com cobertura aferida a partir dos campos de origem. Preserve as ausências em campos categóricos, identificadores, datas, denominadores e indicadores sem publicação. O zero calculado precisa ser interpretado à luz da cobertura do quesito ou do período.

No Windows, a execução de revisão usou R 4.5.3, `LC_ALL=English_United States.utf8`, a biblioteca local do projeto em `.libPaths()` e `options(encoding = "UTF-8")`. Isso evita que a leitura dos nomes de município e das rubricas dependa da configuração de idioma da sessão. Em outra instalação, use a biblioteca correspondente ao R e à plataforma.

## Validação da candidata

- **Criminal:** conferir as chaves e a grade esperada de 497 municípios × 4 anos, a cobertura mensal das entradas, os totais estaduais e as diferenças municipais entre versões. Distinguir zero observado, município sem correspondência e ausência de dado na fonte. Comparar o total reconstruído à coluna oficial equivalente; os recortes “outros” têm composição própria.
- **Prisional:** conferir 2017–2025, os ciclos do primeiro e segundo semestre, os identificadores, a população e a capacidade. Recalcular os indicadores a partir dos campos de origem e comparar os derivados por estabelecimento e ano, preservando cela física e as quatro categorias médicas. Para óbitos 6.8, confira a soma dos dois semestres por ID e ano no universo de junho, os vazios por campo e ciclo e as unidades exclusivas do segundo semestre registradas à parte. Para 2017–2022, acompanhe a soma observada de óbitos com a cobertura, em especial em 2018. Faixas de pena e grupos penais com problemas de fonte ou fórmula exigem nota de limitação e ficam fora do comparativo inicial.
- **Flagrantes:** confira as competências e arquivos que compõem cada ano. Indique semestres parciais ou ausentes ao apresentar os totais, que incluem os registros disponíveis.
- **Mandados:** confira os meses informados, zeros explícitos, município ignorado e concordância mensal com os Indicadores de Atividade do RS. Uma competência sem valor nas duas fontes fica fora da soma estadual. A soma municipal usa os meses informados e produz zero quando nenhum mês tem valor, com cobertura zero registrada. O valor estadual tem apuração própria e pode incluir registros sem município.
- **Saúde:** conferir os cortes de cada indicador. Em 2025, a tuberculose soma 7.846 casos confirmados em 12 meses e cobre os 497 municípios. As quantidades das cinco outras séries em 2025 ficam vazias.
- **Contexto e panoramas:** executar `08_validacao_contexto.R`; conferir fontes contra contexto, export e taxas, ano da população (2022), PIB (2023, mil R$ correntes) e os 497 valores do Inep de 2025. Conferir também soma populacional por censo e compatibilidade do contexto com o panorama educacional. Identificar o ano e o método de agregação na descrição dos gráficos.
- **Data Studio:** seguir o [guia da cópia de revisão](../../docs/looker_studio_guia.md). Confirmar que cada gráfico usa a fonte esperada e reproduz as tabelas validadas. Anotar o que ficou fora e por quê, sem tratar a versão candidata como publicação oficial.

As [decisões metodológicas](../../docs/decisoes_metodologicas.md) registram o escopo da candidata. Consulte o [índice de tabelas](../../outputs/tabelas/README.md) para escolher o arquivo e o [índice de auditorias](../../outputs/auditoria/README.md) para conferir o resultado. Guarde o manifesto e as auditorias junto às tabelas efetivamente conectadas.

### Resultado da execução local de 20/11

`outputs/temp/revisao_pipeline_2026-11-20` contém a execução integral concluída e os testes finais aprovados. `auditoria/validacao_prisional.md` registra 86 campos do catálogo comparados em 927 linhas e 15 séries de óbitos sem divergência de cálculo. `auditoria/validacao_contexto.md` terminou com zero falhas. Os oito controles de `auditoria/regressao_pipeline.csv` passaram: perfil prisional idêntico a 15/11, criminal idêntico exceto TDI, 497 valores TDI iguais à extração Python, totais de população e PIB preservados e detecção das perturbações de taxa, PIB multiplicado por mil, ano TDI e chave duplicada. `scripts/tests/test_contexto.R` também passou. Os alertas de fonte e cobertura seguem nos relatórios; o resultado local não equivale à atualização da planilha ou do painel.
