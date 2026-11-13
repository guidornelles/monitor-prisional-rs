# Fontes de dados para o Monitor do Sistema Prisional — RS

> **Revisão de 13/11/2026.** Para fontes e recortes vigentes, consulte [as decisões da candidata](decisoes_metodologicas.md) e [a auditoria SP–RS](auditoria_metodologica_sp_rs.md). As seções datadas preservam o diagnóstico inicial.

> **Auditoria complementar de 03/10/2026:** a fonte nacional Sinesp VDE foi baixada para 2015–2026 e comparada às bases estaduais locais. A aquisição automatizada é viável, mas a substituição é seletiva: homicídios têm município; estupros, armas e os crimes patrimoniais disponíveis têm apenas UF em SP/RS; roubos/furtos “outros” estão ausentes. Mandados cumpridos municipais oferecem uma possibilidade de complemento ao RS, condicionada à ratificação de unidade e localização. Ver [relatório e matriz de viabilidade](auditoria_sinesp_vde_2026-10-03.md). Nenhuma fonte canônica foi substituída. O restante deste documento preserva o diagnóstico anterior e suas datas.

> Objetivo do projeto: **replicar a visualização de dados do Monitor SP e permitir comparação SP↔RS**, com liberdade para repensar a arquitetura de scripts.
>
> Este documento responde a três perguntas:
> 1. Quais fontes do Monitor SP são **nacionais** (basta redirecionar o filtro para o RS) e quais são **exclusivas de SP** (exigem busca de equivalente no RS)?
> 2. Os arquivos criminais do RS que já foram baixados são **suficientes**, ou há dados necessários que a SSP-RS **não publica**?
> 3. Esses dados são **comparáveis** aos de SP, ou exigem **consolidação**, ou são **incomparáveis** por critério distinto?
>
> Convenção: 🟩 **FATO OBSERVADO** = verificado diretamente no código SP ou nos arquivos do RS. 🟦 **INFERÊNCIA** = juízo de viabilidade que ainda precisa de confirmação. Data: 2026-06-09.

---

## 1. Resumo executivo

🟦 **A parte prisional (núcleo do monitor) é de baixo risco; a parte criminal (camada municipal de contexto) é o trabalho real da adaptação.**

- A fonte primária do monitor (SISDEPEN/SENAPPEN) é **nacional** — o RS já está nas mesmas bases. Muda apenas o filtro `UF == "SP"` → `"RS"`. As fontes socioeconômicas (IBGE, INEP) também são nacionais e redirecionáveis pelo código de UF (RS = `43`).
- As fontes **criminais** do Monitor SP vêm da **SSP-SP** e de um scraper próprio — **exclusivas de SP**. É aqui que o RS precisa de fontes próprias. A boa notícia: o RS publica dados criminais **mais granulares que a maioria dos estados**, e você já baixou o essencial.
- **Dinâmica criminal na candidata:** 2022–2025, com homicídio (vítimas), estupro, furtos e roubos de microdados, registros de flagrante e pessoas com mandado cumprido como séries próprias. Armas apreendidas têm total estadual. Harmonizar as rubricas e denominadores antes de comparar com SP.
- 🟦 **Alerta metodológico central para a "comparação SP↔RS":** comparar **valores absolutos** de crimes entre estados é arriscado — SP e RS usam sistemas de registro, taxonomias e critérios de contagem diferentes. A comparação honesta deve ser feita por **taxas (por 100 mil habitantes) e tendências**, não por contagens brutas. 🟩 A própria nota metodológica da SSP-RS reconhece: *"Apesar dos esforços de padronização, a comparabilidade nacional dos dados enfrenta limitações."* Isso precisa estar explícito no monitor.

---

## 2. Classificação das fontes do Monitor SP

🟩 Fontes extraídas da inspeção do repositório SP (ver `docs/inventario_repositorio_sp.md`).

| Fonte usada em SP | Natureza | Para o RS |
|---|---|---|
| **SISDEPEN / SENAPPEN** (bases por ciclo/semestre) | 🟩 **Nacional** | ✅ Redirecionar: trocar filtro `UF=="SP"`→`"RS"`. Mesma fonte, mesma estrutura. |
| IBGE população (`br_ibge_populacao.municipio`, basedosdados) | 🟩 **Nacional** | ✅ Filtrar `sigla_uf=="RS"`. |
| IBGE PIB (`br_ibge_pib.municipio`) | 🟩 **Nacional** | ✅ Filtrar `id_municipio` iniciando em `43` (RS), em vez de `35` (SP). |
| INEP educação — **taxa de distorção idade-série** (indicador efetivamente publicado) | 🟩 **Nacional** | ✅ Usar **distorção idade-série** (INEP), filtrando RS. 🟩 Confirmado por M. Martins (equipe SP, 10/06/2026): o IDEB foi puxado no script mas **não usado**; a distorção idade-série foi extraída da planilha do INEP **manualmente no Excel** (sem script — automação em desenvolvimento). Para o RS, há que **construir essa extração** (não há código SP a reaproveitar). |
| Diretório de municípios (`br_bd_diretorios_brasil.municipio`) | 🟩 **Nacional** | ✅ Filtrar RS. |
| **SSP-SP** (`br_sp_gov_ssp.ocorrencias_registradas`, basedosdados) | 🟩 **Exclusiva de SP** | ⚠️ Equivalente RS = **SSP-RS** (arquivos baixados — seção 3). 🟦 Verificar se basedosdados tem dataset RS equivalente; caso contrário, usar os arquivos da SSP-RS diretamente. |
| **`isdp_scraper`** — base mensal SSP-SP (CSV, projeto externo) | 🟩 **Exclusiva de SP** | ⚠️ Equivalente RS = **Dados Abertos Mensais (SPJ ocorrências)** da SSP-RS (seção 3.3). |
| Validação criminal SP (`SPDadosCriminais`, `DadosProdutividade`) | 🟩 **Exclusiva de SP** | ⚠️ Equivalente RS = Indicadores Criminais + Indicadores de Atividade + Lei 15.610 (seção 3). |
| Saúde — HIV/TB/hepatite + mortalidade (Panorama de Saúde) | 🟩 **Nacional — DATASUS/Ministério da Saúde** (SINAN tuberculose/hepatite, aids.gov.br HIV, mortalidade CID-10; desde 2018) — confirmado pela Nota e por **M. Martins (equipe SP, 10/06/2026)**: as planilhas do script são downloads dos links da Nota | ✅ Redirecionável: extrair do DATASUS para municípios do RS. Os dados **não estão no repo SP** (só o script). |

**Conclusão da seção (revisada com a Nota Metodológica):** das fontes do monitor, **6 são nacionais e redirecionáveis** sem buscar dados novos (SISDEPEN, IBGE população, IBGE PIB, INEP, diretório de municípios e **saúde/DATASUS**); **3 são exclusivas de SP** (todas criminais, da SSP-SP). A dúvida sobre a origem da saúde está **resolvida**: é DATASUS (nacional).

---

## 3. O que o RS publica e o que você já tem

🟩 Inspeção da pasta `data/EstatisticasCriminaisRS` (325 arquivos). Há **quatro produtos distintos**, frequentemente confundidos entre si — além de **dois dicionários de dados oficiais na raiz**, que são ativos centrais do projeto:

- 🟩 `28092847-...-dicionario-de-dados.xlsx` — documenta a série **Indicadores Criminais + VCM**: por indicador, traz **definição, enquadramento legal, desagregações, unidade de análise, periodicidade e anos disponíveis**. É o que permite o de-para rigoroso com SP.
- 🟩 `16165826-clique-aqui-...-dicionario-de-dados.docx` — documenta os **Semestrais da Lei 15.610** campo a campo, por inciso e órgão de origem. Inclui uma **nota metodológica oficial** (ver §5).

### 3.1 Indicadores Criminais por município — *este é o análogo direto da fonte SSP de SP*

🟩 Pasta `IndicadoresCriminais/` (28 arquivos, **2002–2025**). Produzido pelo Observatório Estadual de Segurança Pública (DPI/SSP-RS). Estrutura: planilha anual com aba `GERAL`, aba do ano e abas mensais (JAN–DEZ); uma linha por município (≈502 municípios), uma coluna por indicador. Critério: **fato consumado**.

🟩 **Granularidade por período (do dicionário .xlsx):** total do ano e total do ano por município em **2002–2010**; **municípios por mês a partir de 2011**; total por mês a partir de 2012. Ou seja, há **série municipal mensal longa (desde 2011)**, não apenas recente.

🟩 Indicadores presentes (ano 2022, representativo): Homicídio Doloso; Total de vítimas de Homicídio Doloso; Latrocínio; Furtos; Abigeato; Furto de Veículo; Roubos; Roubo de Veículo; Estelionato; Delitos Relacionados a Armas e Munições; Entorpecentes (Posse/Tráfico); Vítimas de Latrocínio; Vítimas de Lesão Corporal Seguida de Morte; Total de Vítimas de CVLI.

🟩 **Regras de contabilização que afetam o de-para (do dicionário):**
- **Roubo de Veículo é contabilizado de forma independente do grupo de roubos**; **Furto de Veículo, de forma independente do grupo de furtos**. Logo, as colunas "Roubos" e "Furtos" **já excluem os veículos** — **não se deve subtrair**.
- **Abigeato está contido em "Furtos"** ("também computado nos furtos"). Ocorrências bancárias e em estabelecimentos comerciais também estão contidas nos totais de furtos/roubos.
- O conjunto de variáveis **varia ao longo da série** (planilhas `.xls` de 2002–2011 incluem Extorsão/Corrupção; sem CVLI), exigindo harmonização temporal.
- 🟩 **Não há coluna de estupro nesta tabela** — estupro está na série VCM (§3.2).

### 3.2 Violência Contra a Mulher (VCM) — *aqui está o estupro municipalizado oficial*

🟩 Pastas `IndicadoresVCM/` e arquivos `site-violencia-contra-as-mulheres-*`. Abas: Feminicídio Consumado, Feminicídio Tentado, Ameaça, **Estupro**, Lesão Corporal.

🟩 **Do dicionário (.xlsx):** Estupro é **agregado com Estupro de Vulnerável**, unidade **vítimas**, com **total do ano por município a partir de 2012** e **total por mês por município a partir de 2018**. Isso **corrige minha avaliação anterior**: existe estupro municipalizado oficial desde **2012** (anual) — não só a partir dos microdados de 2022.

🟩 **Escopo (verificado na PoC §4):** a VCM é um **subconjunto estável** do estupro total — correlação municipal **0,99** com o microdado, mas em **~metade** do volume (0,50 em 2023; 0,46 em 2024). 🟦 **O que explica a ~metade:** a VCM é o produto do **Observatório da Violência Contra a Mulher** da SSP-RS, que — conforme a descrição do Observatório — abrange o estupro no **recorte da Lei Maria da Penha** (relações familiares ou íntimas contra a mulher), um subconjunto de todos os estupros. A nota 3 da planilha detalha apenas os subtipos (Estupro + Estupro de Vulnerável); o recorte de contexto vem da definição do produto (**a confirmar na página/fonte primária do Observatório**). Não é, portanto, divergência de sistema, e sim **diferença de escopo**. Para "estupro total" comparável a SP, a referência são os **microdados Mensais** (§3.3) — a partir de 2022.

### 3.3 Dados Abertos Mensais — microdados de ocorrências (*análogo ao `isdp_scraper` de SP*)

🟩 Pasta `DadosAbertos/Mensais/`. Arquivos `SPJ_DADOS_ABERTOS_OCORRENCIAS_JAN_DEZ_AAAA` (CSV, `;`, **2022–2025**). **Microdado: uma linha por ocorrência** (~600 mil linhas/ano). Colunas: Sequência, Data Fato, Hora Fato, Grupo Fato, **Tipo Enquadramento**, Tipo Fato, **Município Fato**, Local Fato, Bairro, Quantidade Vítimas, Idade/Sexo/Cor da Vítima.

🟩 O `Tipo Enquadramento` é detalhado e inclui **ESTUPRO, ESTUPRO DE VULNERÁVEL, HOMICÍDIO DOLOSO, todos os subtipos de ROUBO e FURTO, DISPARO DE ARMA DE FOGO** etc. **Como traz Município + tipo + data, esta base permite agregar qualquer indicador por município/período e reconstruir as variáveis de SP — inclusive estupro total.** É a fonte mais flexível que você tem.

### 3.4 Dados Abertos Semestrais — Lei nº 15.610/2021 (transparência por órgão)

🟩 Pasta `DadosAbertos/Semestrais/` (2021.2–2025.2). Microdados por **órgão** (PC, BM, IGP, DCCI, SPGG, Casa Civil, SUSEPE, FASE) e por **inciso** do Art. 6º da Lei 15.610. Relevantes para SP:

- 🟩 **PC Art. 6 Inc. I** — Vítimas Mortas de Crimes Dolosos (tem município) → homicídio.
- **Registros de flagrante e mandados:** o Inc. IX traz registros municipais de flagrante elaborados pela PC. A série estadual de adultos presos em ação exclusiva da PC conta pessoas, com total distinto. O Sinesp VDE disponibiliza pessoas com mandado cumprido por município e total estadual. O Inc. VIII traz dados da BM e sua simples soma com o Inc. IX não é válida.
- 🟩 **PC Art. 6 Inc. VII** — Armas de Fogo Apreendidas pela PC por Tipo/Marca/Calibre. **Uma linha por arma**, com `Data Apreensão`; **sem coluna de município**. Contar as linhas dá o total apreendido pela PC no período.
- 🟩 **BM Art. 6 Inc. VII** (em 2022 nomeado "Item 7") — Armas Apreendidas pela BM: colunas `Tipo;Marca;Calibre;Quantitativo`. **Já vem agregado** — somar `Quantitativo` dá o total da BM no período; **sem município**.
- 🟩 **Verificado por agregação:** somando PC (contagem de linhas) + BM (soma de Quantitativo) nos dois semestres de 2022, obtém-se **9.736 armas de fogo apreendidas no RS em 2022 (PC 3.926 + BM 5.810)** — total anual estadual por corporação. Confere com a unidade anual usada no Monitor SP.
- 🟩 **SSPS/Susepe Inc. X — "Número de indivíduos no sistema" (descoberta relevante):** o dicionário .docx documenta dados **prisionais da Susepe** por unidade prisional, com regime (Provisórios, Regime Fechado, etc.). É uma fonte **estadual nativa do RS sobre a população prisional** — potencial **complemento ou contraprova ao SISDEPEN** no próprio núcleo do monitor. Avaliar em `docs/diagnostico_viabilidade_rs.md`.
- 🟩 Inc. IV (IGP, exames clínicos) inclui categorias de **violência sexual, DST e aborto** — possível camada de saúde estadual.
- Estrutura **muito heterogênea** entre semestres (nomes de arquivo, encoding latin-1, layout por órgão mudando a cada ciclo). Alto custo de padronização; útil como complemento, não como base principal.

### 3.5 Indicadores de Atividade (*análogo direto à seção "Dados de Produtividade" de SP*)

🟩 Arquivos `…indicadores-de-atividade-2007-a-2016`, `…2017-a-2024`, `…2025-a-2026` (raiz). Série **mensal estadual** de produtividade de BM e PC — **cobertura 2007–2026** — com **notas metodológicas oficiais**. Traz, por corporação: armas de fogo apreendidas, prisões (em flagrante, por mandado, de foragidos, por tipo penal), "flagrantes elaborados", drogas, TCs, IPs, etc. É a fonte **mais limpa e pronta** para armas e a chave para entender o universo de prisões — mas **sem município**. 🟩 **Reconciliação (`poc_reconciliacao.md` §4c):** confirma que a Lei 15.610 PC Inc. IX = "flagrantes elaborados" (não prisões exclusivas da PC) e BM Inc. VIII = "prisões realizadas pela instituição" → **somar PC+BM duplica ~23 mil flagrantes**. Armas: exclusivas por corporação **só a partir de 2017** — ⚠️ **até 2016 a linha "PC" já contém a BM** ("Os dados da Polícia Civil contêm os dados da Brigada Militar", confirmado em 2010/2016), então **não somar PC+BM no período antigo** (usar a linha "PC" como total combinado). Quebra de série em 2016/2017.

---

## 4. Comparabilidade variável a variável (Monitor SP → RS)

🟩 Variáveis criminais que o Monitor SP usa (no script `dados municípios_variaveis.R` e na validação): homicídio doloso, estupro total, roubo–outros, furto–outros, armas de fogo apreendidas, prisões efetuadas — agregadas por **município/ano**.

| Indicador em SP | Fonte equivalente no RS | Status | O que fazer |
|---|---|---|---|
| **Homicídio doloso** (SP: exclui vítimas de dolosos de trânsito) | Indicadores Criminais ("Homicídio Doloso" = ocorrências; "Total de vítimas de HD" = vítimas, desde 2012); Mensais; PC Inc. I | 🟩 **Comparável** | RS separa "Homicídio doloso de trânsito" — alinhável ao critério de SP. Decidir entre ocorrências/vítimas e usar a mesma unidade. |
| **Roubo – outros** (SP: só "outros"; exclui carga, **veículo, banco** e variações) | "Roubos" dos Indicadores Criminais (já exclui veículo); **mas inclui bancário/comercial** | 🟨 **Comparável com ressalva** | ⚠️ A Nota SP confirma que veículo já está fora — **não subtrair**. Porém SP exclui também **banco/comércio/carga**, que no RS estão dentro de "Roubos". Para igualar, reconstruir "outros" via **Mensais** (excluir subtipos veículo/banco/comércio). |
| **Furto – outros** (SP: só "outros"; exclui veículo, banco etc.) | "Furtos" dos Indicadores Criminais (exclui veículo; **inclui abigeato e bancário/comercial**) | 🟨 **Comparável com ressalva** | Mesma lógica: reconstruir "outros" via Mensais, descontando abigeato/banco/comércio para casar com a definição de SP. |
| **Estupro – total** (SP: **soma de todos os tipos, incluindo vulnerável, ambos os sexos**) | **Mensais** (ESTUPRO + ESTUPRO DE VULNERÁVEL, todos os sexos; desde 2022). VCM = subconjunto ~metade (corr 0,99), série desde 2012 | 🟩 **Comparável via Mensais** | Match correto = **Mensais** (total). A VCM mede ~metade do total (recorte da Lei Maria da Penha — relações familiares/íntimas, conforme o Observatório) — usar só como subsérie do RS, ciente de que subdimensiona vs SP. |
| **Armas de fogo apreendidas** (SP: seção Dados de Produtividade) | Indicadores de Atividade / Lei 15.610 Inc. VII: **PC** + **BM**, estadual | 🟨 **Comparável no total estadual; sem nível municipal** | Somar PC + BM **a partir de 2017** (exclusivas; ex.: 2022 = 9.736). Até 2016 a linha "PC" já contém a BM (não somar). **Sem município → não entra no mapa.** |
| **Atividade policial** | Lei 15.610, Inc. IX e Sinesp VDE | Duas séries municipais e, para mandados, uma referência estadual | Flagrantes são registros e mandados são pessoas com mandado cumprido; não somar. |

🟨 **Unidade de análise difere por crime (do dicionário) — atenção na comparação:** no RS, furtos, roubos, veículos, estelionato, armas e entorpecentes são contados por **ocorrências**; homicídio e latrocínio têm **ocorrências e vítimas**; estupro, ameaça, lesão e feminicídio (VCM) são por **vítimas**. Antes de comparar com SP, é preciso saber em qual unidade SP contabiliza cada variável e alinhar — somar vítimas com ocorrências produziria números incomparáveis.

🟦 **Indicadores que o RS oferece e SP não enfatiza** (latrocínio, CVLI, abigeato, entorpecentes posse/tráfico, delitos de armas) podem **enriquecer** o monitor do RS, mas, para manter a **comparação**, o painel deve marcar claramente quais indicadores existem nos dois estados e quais são exclusivos de um deles.

---

## 5. Suficiência: o que você tem, o que falta, o que não é público

🟩 **Coberto com o que já foi baixado** (municipalizável e com série temporal):
homicídio doloso, latrocínio, roubos, furtos, roubo/furto de veículo, **estupro (VCM municipal desde 2012; total por ambos os sexos via Mensais desde 2022)**, entorpecentes, CVLI, lesão seguida de morte. Para esses, **os arquivos são suficientes**; o trabalho é de **consolidação/padronização**, não de coleta.

🟨 **Coberto apenas em nível estadual/de período (serve para comparar totais, não para o mapa):**

1. **Armas de fogo apreendidas.** 🟩 Computável como **total estadual** somando PC + BM **a partir de 2017** (verificado 2022 = 9.736; 2023 ≈ 9,5 mil). ⚠️ Até 2016 a linha "PC" já inclui a BM (não somar — §3.5). Atende à unidade anual de SP. **Sem coluna de município → não há mapa.** Para municipalizar, solicitar à **PC/BM** o dado com município.

🟨 **Pendências (não são lacunas de dado, mas de granularidade/decisão):**

1. **Prisões:** obter atos por mandado e confirmar território, competência e cobertura das corporações. A extração LAI de pessoas presas em flagrante é municipal, mas se limita a janeiro–maio de 2026.
2. **Armas por município:** só estadual (sem mapa); para municipalizar, solicitar à SSP-RS/PC/BM.
3. **Continuidade temporal:** os Mensais (microdados) cobrem **2022–2025**; antes disso usam-se Indicadores Criminais (municipal-mensal desde 2011) e VCM (estupro municipal desde 2012) — exige **harmonizar séries de origens/unidades diferentes**.
4. ⏳ **Estupro (decisão da equipe):** microdado (total, comparável a SP, 2022+) vs VCM (subsérie ~metade — recorte Maria da Penha, 2012+) — ver §3.2. Confirmar na fonte primária do Observatório o recorte que explica a ~metade.

🟩 **Prova de conceito — concluída** (ver `docs/poc_reconciliacao.md`): a agregação dos Mensais reproduziu as tabelas oficiais de Indicadores Criminais (2023 e 2024) dentro de ±0,3% para os indicadores de ocorrência, validando o microdado como base única. (Esta seção substitui a recomendação anterior de "rodar uma PoC".)

---

## 6. Implicações para a arquitetura

🟦 Recomendações decorrentes do diagnóstico (a detalhar em `docs/diagnostico_viabilidade_rs.md` e `docs/lacunas_dados_rs.md`):

1. **Adotar os microdados Mensais (3.3) como base criminal principal do RS**, com uma camada de agregação município/período que produza exatamente as variáveis do painel. Isso evita depender da tabela agregada (sem estupro) e dos Semestrais heterogêneos, e dá flexibilidade para qualquer indicador.
2. **Parametrizar a UF** (RS/SP) em vez de filtros hardcoded, viabilizando o painel comparativo com uma única base de código.
3. **Criar um dicionário de-para de indicadores SP↔RS** explicitando, por variável, se é idêntica, consolidada ou exclusiva — e expor isso na interface.
4. **Comparar por taxas e tendências, não por contagens absolutas**, com nota metodológica sobre as diferenças de registro entre as duas SSPs.
5. Tratar os Semestrais da Lei 15.610 e os Indicadores de Atividade como **complemento** — fonte do **total estadual de armas apreendidas** (PC + BM, somáveis a partir de 2017) e de recortes qualitativos — mas não como série municipal principal.

---

## Fontes

- Repositório SP inspecionado: `MonitorPrisional2024` — ver `docs/inventario_repositorio_sp.md`.
- Arquivos RS: `data/EstatisticasCriminaisRS/` (Indicadores Criminais, IndicadoresVCM, Dados Abertos Mensais e Semestrais).
- [SSP-RS — Indicadores Criminais](https://www.ssp.rs.gov.br/indicadores-criminais)
- [SSP-RS — Estatísticas](https://ssp.rs.gov.br/estatisticas)
- [SISDEPEN/SENAPPEN — Bases de dados](https://www.gov.br/senappen/pt-br/servicos/sisdepen/bases-de-dados)
- Nota Metodológica do Monitor SP (NEV-USP, 10/02/2026) — `docs/referencias/Nota_Metodologica_Monitor_SP.pdf`. Fonte das definições de SP (rubricas criminais, DATASUS para saúde, regra 1º/2º semestre).
- Dicionários de dados da SSP-RS — `data/EstatisticasCriminaisRS/` (raiz): `...dicionario-de-dados.xlsx` (Indicadores Criminais + VCM) e `...dicionario-de-dados.docx` (Lei 15.610).

*Documento de inspeção. Fatos observados no código SP e nos arquivos RS estão marcados 🟩; juízos de viabilidade a confirmar estão marcados 🟦/🟥.*
