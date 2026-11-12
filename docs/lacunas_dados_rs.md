# Lacunas e matriz de comparabilidade SP ↔ RS

> **Versão candidata de 12/11/2026:** o Sinesp VDE oferece uma série municipal de mandados cumpridos, com cobertura variável; a série entra separada de flagrantes. A SSP-SP confirmou a composição de “Prisões efetuadas”, mas distingue prisões de pessoas presas. O microdado gaúcho de 2022 foi revisado. Consultar as [decisões atuais](decisoes_metodologicas.md); a matriz abaixo preserva o estado da investigação nas datas indicadas.

> Este documento responde a duas perguntas, lado a lado, para cada variável do Monitor:
> 1. **Categoria** — o dado do RS é comparável ao de SP? Que **agregação/desagregação** é necessária?
> 2. **Período** — em que **janela temporal** a comparação é válida?
>
> Convenção: 🟩 FATO (verificado no código SP, na Nota Metodológica SP, nos dicionários da SSP-RS ou nos arquivos). 🟦 inferência/avaliação. 🟥 lacuna. ⏳ decisão pendente da equipe. Data: 2026-06-09. Complementa `docs/fontes_dados_rs.md` e `docs/poc_reconciliacao.md`.

---

## 1. Períodos de cada fonte (fato observado)

| Fonte | Cobertura | Granularidade | Unidade |
|---|---|---|---|
| **SP — Dinâmica Criminal** (SSP-SP) | 🟩 desde **2001** | municipal/anual (soma de semestres) | ocorrências; prisões/armas via Produtividade |
| **SP — Dados Prisionais** (SISDEPEN) | 🟩 desde **2017** | município + estabelecimento | conforme seção |
| **RS — Indicadores Criminais** (tabela agregada) | 🟩 **2002–2025** | ano por município (2002+); **município por mês desde 2011** | ocorrências (homicídio/latrocínio também vítimas, desde 2012) |
| **RS — VCM** (estupro, feminicídio…) | 🟩 **2012–2025** | ano por município (2012+); **mês por município desde 2018** | vítimas |
| **RS — Microdados Mensais** (SPJ ocorrências) | 🟩 **2022–2025** | ocorrência (município + tipo + data + sexo) | ocorrências/vítimas, todos os sexos |
| **RS — Semestrais Lei 15.610** (armas, prisões PC/BM…) | 🟩 **2021.2–2025.2** | por órgão; **com município** para prisões (Inc. VIII/IX); **sem município** para armas | contagem |
| **RS — Indicadores de Atividade** (armas, prisões por força, drogas…) | 🟩 **2007–2026**; estrutura por força limpa só **de 2017** (até 2016 a linha "PC" de *apreensões* já inclui a BM; prisões já são separadas) | **estadual** (sem município), mensal | produtividade por corporação |
| **Contexto** (IBGE pop/PIB, INEP, DATASUS) | 🟩 PIB 2010+; saúde **2018+**; nacional | município | conforme fonte |

---

## 2. Matriz de comparabilidade — componente CRIMINAL

| Indicador (SP) | Categoria: como casar SP↔RS | Transformação necessária | Unidade comparável | **Janela comparável** | Status |
|---|---|---|---|---|---|
| **Homicídio doloso** | SP exclui dolosos de trânsito; RS tem coluna própria "Homicídio Doloso" e separa "homicídio doloso de trânsito" | alinhar exclusão de trânsito; escolher ocorrências (ambos têm) | ocorrências | 🟩 **2002–2025** (anual); municipal-mensal 2011+ | ✅ comparável, série longa |
| **Roubo – outros** | SP = roubo "outros" (exclui veículo, **banco, comércio, carga**). RS "Roubos" exclui veículo mas **inclui banco/comércio** | (a) aproximado: usar "Roubos" agregado direto; (b) estrito: reconstruir via microdado excluindo banco/comércio/carga | ocorrências | 🟩 aproximado **2002–2025**; estrito **2022–2025** | ✅/⚠️ ver nota |
| **Furto – outros** | SP = furto "outros" (exclui veículo, banco etc.). RS "Furtos" exclui veículo mas **inclui abigeato + banco/comércio** | (a) aproximado: "Furtos" direto; (b) estrito: microdado excluindo abigeato/banco/comércio | ocorrências | 🟩 aproximado **2002–2025**; estrito **2022–2025** | ✅/⚠️ ver nota |
| **Estupro** | SP = todos os tipos, **ambos os sexos**, ocorrências, desde 2001. RS: VCM (subconjunto ~metade — recorte Maria da Penha, corr 0,99) **ou** microdado (total, ambos os sexos) | depende da decisão (§7) | ocorrências (microdado) ou subconjunto (VCM) | VCM **2012–2025** (~metade do total) **ou** microdado **2022–2025** (total comparável) | ⏳ **decisão pendente** |
| **Armas de fogo apreendidas** | SP = Produtividade SSP, anual, municipal. RS = Indicadores de Atividade / Lei 15.610, **só estadual** | **2017+**: somar PC + BM (exclusivas, sem dupla contagem; validado 2023 ≈9,5 mil). **2007–2016**: usar só a linha "PC" (já contém a BM — não somar) | total **estadual** anual | 🟩 estadual **2007+ com quebra em 2016/2017** (soma PC+BM só de 2017); municipal: não há | 🟨 só estadual — **não entra no mapa** |
| **Prisões efetuadas** | SP (Res. SSP-SP 160/2001, a confirmar) = **só Polícia Civil**: flagrantes lavrados (APF) + mandados cumpridos. RS análogo = "Flagrantes elaborados pela PC" (Lei 15.610 Inc. IX, **municipal**) + "Presos por mandados pela PC" (atividade, **estadual**) | replicar a fórmula de SP **só com PC** (BM não entra → dupla contagem é irrelevante). Flagrante: Inc. IX por município; mandados: só estadual | ocorrências (flagrante) + presos (mandados) | 🟩 flagrante municipal **2022+**; total estadual **2017+** | 🟨 mandados sem município; unidade (ver nota) |

**Nota roubo/furto "outros":** a comparação 2002–2025 é viável e barata usando os agregados, **com a ressalva** de que o RS inclui banco/comércio (e, no furto, abigeato) que SP exclui de "outros". O impacto disso deve ser medido com o microdado em um ano-ponte (2022–2024) para decidir se a aproximação é aceitável ou se a versão estrita (pós-2022) é necessária.

**Nota prisões efetuadas (correção):** a Lei 15.610 obriga a publicação das prisões da **BM (Inc. VIII — "Prisões efetuadas")** e da **PC (Inc. IX — "Prisões realizadas", tipo de ocorrência "com flagrante")**, ambas por tipo penal e **município** — então **há município nas duas** (cabem no mapa). 🟩 Pelo dicionário e pela lei, **cada inciso traz as prisões de uma corporação** (BM e PC, respectivamente). Verificado em 2023: PC = 30.436; BM = 111.574.

🟩 **Sobreposição PC/BM CONFIRMADA por reconciliação (ver `poc_reconciliacao.md` §4c).** Cruzando a Lei 15.610 com o relatório de Indicadores de Atividade (2023): Inc. IX (PC) = 30.436 = "**flagrantes elaborados** pela PC" (30.426), e **não** as prisões exclusivas da PC (só 7.121). Inc. VIII (BM) = 111.574 = "prisões realizadas pela instituição BM" (111.634). Como a PC lavra ~30 mil autos de flagrante mas só ~7 mil vêm de ação própria, os outros **~23 mil vêm de capturas da BM** que também constam no Inc. VIII. Logo, **somar PC Inc. IX + BM Inc. VIII duplica ~23 mil eventos**. A leitura literal da lei (cada inciso = uma força) está correta, mas o dado publicado do Inc. IX é a lavratura, não as prisões exclusivas da PC.

🟩 **Definição de SP (levantamento documental — Res. SSP-SP nº 160/2001; a confirmar com a equipe SP):** "Prisões efetuadas" é métrica **procedimental** (ocorrências), só da **Polícia Judiciária (Polícia Civil)**:
$$\text{Prisões}_{SP} = \text{Flagrantes lavrados (APF, ocorrências)} + \text{Mandados cumpridos (ocorrências de captura)}$$
Como SP usa **só a PC**, o problema de dupla contagem PC×BM **não se aplica** — a BM nunca entra nesse indicador.

🟩 **Mapeamento RS (só PC):**
- **Flagrantes lavrados** → "Flagrantes elaborados pela PC" = **Lei 15.610 Inc. IX** (municipalizado). 2023 = 30.426; 2024 = 28.895.
- **Mandados cumpridos** → "Presos por mandados pela PC" (Indicadores de Atividade, **só estadual**). 2023 = 8.464; 2024 = 8.579.
- **Total estadual RS ≈ 38,9 mil (2023)** / 37,5 mil (2024), comparável ao indicador de SP.

🟨 **Limitações:** (1) **no mapa**, só o componente **flagrante** é municipalizado (Inc. IX); os mandados existem só em nível estadual. (2) **Unidade:** SP conta *ocorrências* (boletins de captura); o RS "presos por mandados" conta *indivíduos* — diferença pequena (~1 preso por BO), a registrar. (3) Adultos (ambos os indicadores RS são "adultos", como em SP).

🟦 **Indicadores que o RS tem e podem enriquecer o painel do RS** (não no comparativo, ou marcados como exclusivos): latrocínio, CVLI, roubo/furto de veículo, entorpecentes (posse/tráfico), delitos de armas, estelionato — todos 2002+ por ocorrências.

---

## 3. Matriz — componente PRISIONAL (SISDEPEN)

🟩 **A comparabilidade mais forte de todo o projeto.** SP e RS usam a **mesma fonte nacional** (SISDEPEN/SENAPPEN), com a **mesma estrutura**; muda só o filtro de UF. Cobertura **2017+** (a mesma que SP usa).

| Bloco (como no Monitor SP) | Comparável SP↔RS | Janela |
|---|---|---|
| Capacidade e Lotação; Estrutura; Celas; Pessoal; Saúde; Educação; Trabalho | 🟩 sim (idêntico) | 2017+ (1º semestre) |
| População Prisional (sentenciamento, sexo, idade, raça/cor, motivo, tempo de pena, estrangeiros, gestantes/lactantes) | 🟩 sim · ⚠️ ver nota tempo de pena | 2017+ (1º semestre) |
| Morbidade / Agravos transmissíveis (HIV, sífilis, TB, hepatite) | 🟩 sim | 2017+ (1º semestre) |
| Mortalidade (saúde, criminal, suicídio, acidental, desconhecida) | 🟩 sim | 2017+ (**ANUAL = 1º + 2º semestre**, como o `dados_sem2.R` de SP) |
| Controle e Fiscalização (visitas de conselhos, DP, MP, Judiciário…) | 🟩 sim | 2017+ |

⚠️ **Nota — tempo de pena (5.12) e pena remanescente (5.13) do RS: não-confiáveis.** O RS concentra ~78% dos condenados na faixa "Até 6 meses" (vs ~5% em SP), indicando preenchimento incorreto na origem do SISDEPEN-RS. As demais variáveis prisionais não são afetadas. Detalhe em `docs/problemas_dados.md` (item 2). Tratar a distribuição de tempo de pena do RS com cautela ou omiti-la.

🟦 Complemento estadual possível: dados da **Susepe** (Lei 15.610, Inc. X — "número de indivíduos no sistema", por regime) podem servir de contraprova ao SISDEPEN no RS (2021.2+).

---

## 4. Componente CONTEXTO (socioeconômico e saúde)

Todas nacionais → comparáveis para os dois estados, bastando filtrar a UF.

| Painel SP | Fonte | Janela comparável |
|---|---|---|
| Panorama Populacional | IBGE censos | decenal |
| Panorama Econômico (PIB) | IBGE | 🟩 **2010+** |
| Panorama de Saúde (TB, hepatite, HIV, mortalidade) | DATASUS/Ministério da Saúde | 🟩 **2018+** |
| Panorama Educacional — **taxa de distorção idade-série** (INEP) | INEP | anual (🟩 confirmado: SP publica distorção idade-série, não IDEB; feita manualmente no Excel, sem script) |

---

## 5. Síntese das JANELAS de comparação (o que limita o quê)

🟦 Ordenado pela restrição temporal (do mais longo ao mais curto):

- **Criminal — homicídio, furtos, roubos, veículos, latrocínio:** **2002–2025** (anual). Municipal-mensal a partir de **2011**.
- **Prisional (SISDEPEN, todos os blocos):** **2017–presente**.
- **Saúde de contexto (DATASUS):** **2018+**. PIB: **2010+**.
- **Armas apreendidas (estadual):** **2007+** no relatório de atividade, mas **soma PC+BM só vale de 2017** (até 2016 a linha "PC" já contém a BM — quebra de série); só estadual, sem mapa.
- **Prisões efetuadas (definição SP = PC: flagrantes + mandados):** componente **flagrante** municipal **2022+** (Inc. IX); **total estadual** (flagrante + mandados) **2017+**. Só PC (sem BM). O componente de mandados não é municipalizado.
- **Roubo/furto "outros" no padrão estrito de SP:** **2022+** (antes disso, só a aproximação via agregado).
- **Estupro:** **2012+** (VCM, não comparável) **ou** **2022+** (microdado, comparável) — ⏳ pendente.

🟦 **Implicação de design:**
- Um painel comparativo **criminal + prisional** "núcleo" funciona bem de **2017** em diante (intersecção de SISDEPEN com a série criminal longa).
- **Armas e prisões** têm série **estadual longa (2007+)**; mas, **no mapa (municipal)**, prisões só a partir de 2022 e armas não há. Estupro estritamente comparável: 2022+.
- A série **criminal isolada** (homicídio/furto/roubo) pode recuar até **2002**, útil para tendência de longo prazo de cada estado e comparação aproximada.
- Recomenda-se que o painel **exiba a janela válida de cada indicador** (e não force um eixo temporal único), para não sugerir comparações fora do período coberto.

---

## 6. Lacunas propriamente ditas (🟥)

1. **Armas apreendidas por município:** o público só dá total estadual (PC+BM, Inc. VII) ou microdado PC sem município. Para mapa, solicitar à SSP-RS/PC/BM.
2. **Prisões efetuadas — definição resolvida; lacuna remanescente é só municipal:** a métrica de SP (PC: flagrantes + mandados, §2) é reproduzível no RS em **total estadual** (Inc. IX + presos por mandados PC). O **componente de mandados não é municipalizado** no público — então, no mapa, só entra o flagrante (Inc. IX). Para mandados por município, solicitar à SSP-RS/PC. (Resta confirmar a definição de SP com a equipe paulista.)
3. **Estupro comparável a SP em série longa:** inexistente — VCM (2012+) tem unidade/recorte diferentes; microdado (2022+) é comparável mas curto. Ver §4.
4. **Mensal municipal anterior a 2011** e **qualquer dado anterior a 2002:** não disponível no RS.
5. 🟩 **Educação — resolvido:** SP publica **taxa de distorção idade-série** (INEP), não IDEB (o IDEB do script não é usado). Confirmado por M. Martins (equipe SP, 10/06/2026). O dado é nacional (redirecionável p/ RS), mas a extração de SP é **manual no Excel** — para o RS é preciso **construir um script** (não há código a reaproveitar).

---

## 7. Decisão pendente — ESTUPRO (⏳ para a equipe do projeto)

🟩 **Achado documentado (PoC, §4):** os microdados Mensais são confiáveis (reproduzem homicídio/furto/roubo dentro de ±0,4%). Quanto ao estupro, a VCM é um **subconjunto estável** do microdado: **correlação municipal 0,99** (2023 e 2024) e razão VCM/microdado **estável (~0,50 e ~0,46)**. Não é "instável" nem "divergente" (conclusão anterior corrigida — era artefato da linha "GERAL" da planilha VCM). A diferença **não** é ocorrência vs vítima (testado: idêntico) nem sexo (feminino = 0,81). 🟦 **O que explica a ~metade:** a VCM é o produto do **Observatório da Violência Contra a Mulher** (SSP-RS), que abrange o estupro no **recorte da Lei Maria da Penha** (relações familiares/íntimas) — um subconjunto de todos os estupros. A nota 3 da planilha cita só os subtipos (Estupro + Vulnerável); o recorte de contexto vem da definição do produto (**a confirmar na fonte primária do Observatório**). Para o total comparável a SP, usa-se o microdado; a VCM mede ~metade.

| Caminho | Prós | Contras |
|---|---|---|
| **A. Microdado** (ocorrências, ambos os sexos) | comparável à definição de SP | série só **2022+** |
| **B. VCM** (subconjunto ~metade — recorte da Lei Maria da Penha) | série mais longa (**2012+**), oficial, **estável e bem correlacionada** (0,99) com o microdado | mede **~metade** do estupro total → subdimensiona vs SP; recorte de contexto a confirmar na fonte primária |
| **C. Só no painel do RS** (fora do comparativo SP↔RS) | honestidade metodológica máxima | abre mão de comparar estupro entre estados |

🟦 Recomendação técnica (a validar com a equipe): **A para o comparativo SP↔RS** (definição correta), e, se quiserem série histórica do RS, exibir a VCM **apenas no painel do RS** marcada como métrica distinta (combinação A+C). Não usar B no eixo comparativo.

---

## 8. Ressalvas metodológicas transversais

- 🟩 A própria SSP-RS adverte: *"Apesar dos esforços de padronização, a comparabilidade nacional dos dados enfrenta limitações."* Comparar **taxas (por 100 mil) e tendências**, não números absolutos.
- 🟩 **Unidade de análise difere por crime** (ocorrências vs vítimas) — alinhar antes de comparar.
- 🟩 Os números sofrem **revisão** após a extração (a base é administrativa); diferenças de ±0,1–0,3% entre microdado e agregado são esperadas.
- 🟦 SP tem 645 municípios e 11 macrorregiões; RS tem 497 municípios e regiões próprias (RISP/COREDEs) — a agregação regional **não é equivalente** entre estados; comparar no nível municipal ou estadual, e tratar "região" separadamente.

---
🟩 **Base legal (fonte autoritativa do que cada órgão publica):** Lei estadual nº 15.610/2021 (`data/EstatisticasCriminaisRS/DadosAbertos/22201614-lei-n-15-610-...pdf`). Art. 3º obriga a publicação **mensal** de **todos** os registros criminais desagregados (base dos microdados Mensais — dia/hora, tipo, cidade, local, nº/idade/sexo/cor das vítimas). Art. 6º lista os 29 incisos semestrais por órgão — inclui prisões BM (VIII) e PC (IX) por município, armas PC+BM (VII), população prisional Susepe (X), óbitos de internos (XXIV), fugas (XXV), presos em aula/trabalho (XI), socioeducativo FASE (XII).

*Fontes: Lei 15.610/2021; `docs/inventario_repositorio_sp.md`, `docs/fontes_dados_rs.md`, `docs/poc_reconciliacao.md`; dicionários da SSP-RS e Nota Metodológica do Monitor SP (`docs/referencias/`).*
