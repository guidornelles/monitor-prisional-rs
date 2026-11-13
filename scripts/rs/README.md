# Pipeline da versão candidata do Monitor Prisional RS

O pipeline R gera as tabelas do RS para uma cópia de revisão no Data Studio. A PoC de junho e o Monitor SP servem de referência e não são atualizados por este processo. A PoC que compara os dois estados é uma entrega posterior.

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
| `02b_atividade.R` | Flagrantes da Polícia Civil pela SSP-RS. A série conta registros da fonte, não pessoas únicas. |
| `03_prisional.R` e `03b_prisional_derivadas.R` | Base de cela física e variáveis derivadas, com semestre de referência, identificadores e cobertura temporal explícitos. |
| `04_contexto.R` e `04b_saude.R` | Municípios e regiões intermediárias do IBGE, população e demais variáveis de contexto; séries municipais de saúde. |
| `02c_mandados_sinesp.R` | Mandados cumpridos, abrangência estadual do VDE, associados ao código IBGE. Mantém a série própria e audita cobertura, valores sem localização e reconciliação. |
| `05_planilha_final.R` | Consolida as tabelas de criminal, prisional, contexto e saúde, com chaves e taxas onde aplicáveis. |
| `05b_export_formato_sp.R` | Gera `formato_sp/contexto_dados.csv`, `formato_sp/dinamica_criminal.csv`, `formato_sp/dados_saude.csv` e `formato_sp/mandados_estadual.csv` para apresentação. A tabela prisional entra diretamente. |
| `06_auditoria.R` e `07_validacao_prisional.R` | Reúnem os controles das tabelas geradas, inclusive cobertura, chaves, reconciliação e óbitos anuais. |

### Atualizar uma camada

Para uma alteração pontual, use outro `MONITOR_RS_RUN_DIR` e copie para `processed/` as saídas intermediárias da execução validada de referência. Assim as etapas comuns podem usar as outras camadas da mesma edição. Rode as etapas na ordem abaixo e compare as saídas com a execução anterior antes de trocar uma conexão.

| Atualização | Etapas antes dos exportadores |
| --- | --- |
| Ocorrências e vítimas | `01a_download_ssp_rs.R` para as categorias `mensais,indicadores_criminais`, depois `02_criminal.R`. |
| Flagrantes da Polícia Civil | `01a_download_ssp_rs.R` para `semestrais`, depois `02b_atividade.R`. Confira que existem dois arquivos por ano. |
| Mandados do Sinesp VDE | Fixe o snapshot e a referência estadual, depois rode `02c_mandados_sinesp.R`. |
| Estoques, perfil, condições ou fluxos prisionais | `01b_download_sisdepen.R` se o insumo faltar, depois `03_prisional.R`, `03b_prisional_derivadas.R` e `04_contexto.R` para recalcular presença de estabelecimentos. |
| Panorama de Saúde | Arquive versões anteriores fora da pasta de ingestão. Mantenha uma edição ativa por indicador, município e ano. Atualize o insumo e o corte do indicador validado, depois rode `04b_saude.R`. |
| Cadastro municipal ou denominador | `01_download.R` para adquirir os insumos faltantes, depois `04_contexto.R`. Rode também `02c_mandados_sinesp.R` se mudar a associação municipal. |

Finalize com `05_planilha_final.R`, `05b_export_formato_sp.R`, `06_auditoria.R` e `07_validacao_prisional.R`. Essas etapas também podem regerar tabelas de outras camadas. Compare seus hashes com a referência para verificar se a alteração ficou no escopo.

### Atualizar os panoramas populacional, econômico e educacional

O [script de panoramas históricos](../exploratory/preparar_panoramas_historicos_rs.py) requer Python e `openpyxl`, além dos CSVs de cadastro municipal e população do Censo 2022 preparados por `01_download.R`. Ele consulta o SIDRA e o Inep, valida cobertura e totais e grava três CSVs e o `manifesto_panoramas.json`. A execução de referência usou a pasta `outputs/temp/candidata_2026-11-12/panoramas_historicos`.

```powershell
python scripts/exploratory/preparar_panoramas_historicos_rs.py --baixar --saida outputs/temp/revisao_2026-11-13/panoramas_historicos
```

Para refazer as tabelas a partir dos mesmos insumos, reutilize a pasta com os downloads e execute o comando sem `--baixar`. Para ampliar os períodos, confirme a nova divulgação e ajuste os anos e verificações de cobertura no script. O PIB usa mil reais correntes. As linhas censitárias preservam a cobertura municipal de cada edição e usam o cadastro atual de regiões intermediárias. A taxa de distorção idade-série do ensino fundamental é o total municipal de redes e localizações. Para carregar os gráficos, use somente as linhas `Recorte = Município` e guarde as linhas `Estado` para conferência.

O Sinesp não substitui o microdado estadual. Mandados cumpridos e flagrantes aparecem separados; o indicador paulista **Prisões efetuadas** reúne flagrantes e prisões por mandado, mas conta prisões, não a soma de pessoas presas. O total RS só pode ser equiparado depois de validar unidade, geografia e cobertura institucional.

No Windows, a execução de revisão usou R 4.5.3, `LC_ALL=English_United States.utf8`, a biblioteca local do projeto em `.libPaths()` e `options(encoding = "UTF-8")`. Isso evita que a leitura dos nomes de município e das rubricas dependa da configuração de idioma da sessão. Em outra instalação, use a biblioteca correspondente ao R e à plataforma.

## Validação da candidata

- **Criminal:** conferir as chaves e a grade esperada de 497 municípios × 4 anos, a cobertura mensal das entradas, os totais estaduais e as diferenças municipais entre versões. Distinguir zero observado, município sem correspondência e ausência de dado na fonte. Comparar o total reconstruído à coluna oficial equivalente; os recortes “outros” têm composição própria.
- **Prisional:** verificar 2017–2025, os ciclos do primeiro e segundo semestre, os identificadores de estabelecimento e a população e capacidade por ano. Manter 2022–2025 como ponte com a PoC. Conferir óbitos por semestre e ano; semestre ausente não equivale a zero. Faixas de pena e grupos penais com problemas de fonte ou fórmula exigem nota de limitação e não entram no comparativo inicial.
- **Mandados:** conferir meses numéricos, ausência versus zero, municípios sem localização, abrangência estadual e totais anuais contra os Indicadores de Atividade do RS. Exibir totais municipais apenas com 12 meses informados. A soma dos municípios exibidos pode ficar abaixo do total estadual, que tem apuração separada.
- **Saúde:** conferir os cortes de cada indicador. Em 2025, a tuberculose soma 7.846 casos confirmados em 12 meses e cobre os 497 municípios. As quantidades das cinco outras séries em 2025 ficam vazias.
- **Panoramas:** conferir a soma populacional por censo, a escala em mil reais correntes do PIB e a cobertura de 497 municípios no Inep de 2025. Identificar o ano e o método de agregação na descrição dos gráficos.
- **Data Studio:** seguir o [guia da cópia de revisão](../../docs/looker_studio_guia.md). Confirmar que cada gráfico usa a fonte esperada e reproduz as tabelas validadas. Anotar o que ficou fora e por quê, sem tratar a versão candidata como publicação oficial.

As [decisões metodológicas](../../docs/decisoes_metodologicas.md) registram o escopo da candidata. Consulte o [índice de tabelas](../../outputs/tabelas/README.md) para escolher o arquivo e o [índice de auditorias](../../outputs/auditoria/README.md) para conferir o resultado. Guarde o manifesto e as auditorias junto às tabelas efetivamente conectadas.
