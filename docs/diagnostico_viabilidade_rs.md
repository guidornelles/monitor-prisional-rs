# Diagnóstico de viabilidade — adaptação do Monitor do Sistema Prisional (SP → RS)

> Documento-síntese, base para apresentação ao grupo do projeto. Consolida `inventario_repositorio_sp.md`, `fontes_dados_rs.md`, `lacunas_dados_rs.md`, `poc_reconciliacao.md` e `auditoria.md`.
>
> **Objetivo do projeto:** replicar a visualização de dados do Monitor do Sistema Prisional de SP (NEV-USP) para o Rio Grande do Sul **e permitir a comparação SP↔RS**, com liberdade para repensar a arquitetura.
>
> Convenção de evidência: 🟩 **fato verificado** (computação nesta análise, ou leitura de fonte oficial — lei, dicionário, Nota Metodológica, código SP); 🟦 **inferência/avaliação**; ⏳ **decisão pendente da equipe**; 🟥 **lacuna/limitação**. Data: 2026-06-10.

---

## 1. Sumário executivo

🟦 **A adaptação é viável.** O monitor tem duas metades com riscos muito diferentes:

- **Núcleo prisional — baixo risco.** Vem do **SISDEPEN/SENAPPEN**, base **nacional**: o RS já está nela, com a mesma estrutura. Adaptar é, essencialmente, trocar o filtro de UF. É a parte que dá nome ao monitor e é a de menor esforço.
- **Camada criminal municipal — o trabalho real.** Vem da **SSP-SP**, exclusiva de SP. O RS tem fontes próprias, **mais granulares que as da maioria dos estados**, e já as temos em mãos. Validamos empiricamente que dá para reproduzir os indicadores de SP a partir delas.

🟩 **Validação central (prova de conceito):** os microdados de ocorrências da SSP-RS reproduzem as tabelas oficiais agregadas do estado, em 2023 **e** 2024, com desvio estadual entre −0,4% e +0,01% e 99–100% dos municípios dentro de 1 caso/1%. Isso autoriza usar o microdado como **base única e auditável** do componente criminal.

🟦 **Mensagem metodológica que deve abrir a apresentação:** comparar **valores absolutos** de crimes entre SP e RS é arriscado (sistemas de registro e critérios distintos — a própria SSP-RS adverte sobre isso). A comparação honesta é por **taxas (por 100 mil) e tendências**, com a janela temporal válida de cada indicador explícita.

As únicas questões genuinamente em aberto são **decisões da equipe** (não falhas de dados), detalhadas na §8.

---

## 2. O que está verificado × o que é decisão pendente

| Tema | Situação | Evidência / próximo passo |
|---|---|---|
| Núcleo prisional (SISDEPEN) comparável SP↔RS | 🟩 Verificado | Fonte nacional, mesma estrutura, 2017+ |
| Saúde de contexto = DATASUS (nacional) | 🟩 Confirmado | Nota Metodológica + M. Martins (equipe SP) |
| Educação = taxa de distorção idade-série (não IDEB) | 🟩 Confirmado | M. Martins; SP a faz manualmente — RS precisa construir o script |
| Microdado criminal reproduz os agregados oficiais | 🟩 Verificado (2023 e 2024) | Reconciliação ±0,4% (§5) |
| Homicídio, furtos, roubos, veículos: comparáveis | 🟩 Verificado | Reconciliação + dicionário |
| Definição de "prisões efetuadas" de SP (só PC) | 🟩 Levantado (Res. 160/2001) | A **confirmar formalmente** com a equipe SP |
| Armas apreendidas: somar PC+BM só de 2017 | 🟩 Verificado | Cruzamento Lei 15.610 × atividade; quebra 2016/2017 |
| **Estupro**: microdado (total) × VCM (~metade) | ⏳ **Decisão da equipe** | Definir a fonte; VCM = recorte Maria da Penha (a confirmar na fonte primária) |
| Estupro: VCM mede ~metade do total | 🟦 Explicado (a confirmar) | Recorte da Lei Maria da Penha (Observatório SSP-RS); corr 0,99 com o microdado |
| Prisões/armas **por município** em série longa | 🟥 Limitação | Armas só estadual; prisões-mandados só estadual |

---

## 3. O Monitor de SP: o que é e como é construído

🟩 Iniciativa do NEV-USP, publicada em **Looker Studio**, com unidade de observação nos **645 municípios** paulistas (agregáveis em 11 macrorregiões). Tem duas partes: **Dados de Contexto** (população, PIB, saúde, educação) e **Dinâmica Criminal**; e **Dados Prisionais** (SISDEPEN). Código em **R**, no repositório `MonitorPrisional2024` (branch `R`).

🟩 **Fragilidade de reprodutibilidade observada** (relevante para a decisão de arquitetura do RS):

- Código e dados **espalhados em branches** distintas; a `main` está praticamente vazia.
- Acoplamento por **objeto em memória** entre `depen.R` e `dados_sem2.R` (sem persistência intermediária).
- **Sem `renv`/lockfile** (versões de pacotes não fixadas); billing GCP próprio para `basedosdados`.
- Etapas **manuais fora do repositório** (ex.: a educação/distorção idade-série é tratada no Excel; o IDEB do script não é usado).

🟦 Isso favorece **repensar a arquitetura** no RS (em vez de copiar), o que o projeto já admite.

---

## 4. Fontes: nacionais (redirecionáveis) × exclusivas de SP

🟩 Das fontes do Monitor SP, **6 são nacionais** (basta filtrar a UF para o RS) e **3 são exclusivas de SP** (criminais, da SSP-SP):

| Fonte (SP) | Natureza | Para o RS |
|---|---|---|
| SISDEPEN/SENAPPEN (prisional) | 🟩 Nacional | Trocar filtro `UF` para RS |
| IBGE população, IBGE PIB, diretório de municípios | 🟩 Nacional | Filtrar RS (`id` inicia em 43) |
| INEP — distorção idade-série | 🟩 Nacional | Construir extração (SP faz manual) |
| DATASUS — TB/hepatite/HIV/mortalidade | 🟩 Nacional | Redirecionar download para o RS |
| SSP-SP — ocorrências, produtividade | 🟩 **Exclusiva de SP** | Usar fontes da **SSP-RS** (§6) |

---

## 5. Validação empírica (prova de conceito)

🟩 Reconciliação dos **microdados Mensais** (SPJ Dados Abertos da SSP-RS) contra as **tabelas oficiais de Indicadores Criminais**, com guarda anti-contaminação (exclusão de linhas-agregado e footnotes). Resultado estadual:

| Indicador | 2023 (oficial → recon) | 2024 (oficial → recon) |
|---|---|---|
| Homicídio doloso (ocorrências) | 1.570 → 1.567 (−0,2%) | 1.338 → 1.337 (−0,1%) |
| Furtos | 125.529 → 125.466 (−0,1%) | 105.373 → 105.380 (0,0%) |
| Roubos | 32.506 → 32.412 (−0,3%) | 20.771 → 20.697 (−0,4%) |
| Furto de veículo | 8.556 → 8.557 | 6.639 → 6.638 |
| Roubo de veículo | 3.594 → 3.593 | 2.299 → 2.295 |
| Latrocínio | 42 → 41 | 29 → 28 |

🟩 99–100% dos municípios dentro de 1 caso/1% nos dois anos. As regras de classificação (o de-para microdado→indicador) são **estáveis entre anos** e estão documentadas em `poc_reconciliacao.md`. **Conclusão:** o microdado é uma base confiável e flexível.

🟩 **Achado de transparência para a apresentação:** o processo expôs (e corrigiu) erros de agregação — linhas de total ("Total RS", "GERAL") que contaminavam somas e correlações. O método final inclui detecção sistemática dessas linhas. (Ver `auditoria.md`.)

---

## 6. Comparabilidade SP↔RS — por categoria e por período

🟩 Dois eixos, lado a lado. "Janela" = intervalo em que a comparação é válida.

| Indicador (SP) | Categoria: como casar | Janela comparável | Status |
|---|---|---|---|
| **Homicídio doloso** | RS "Homicídio Doloso" (exclui trânsito, como SP); ocorrências | **2002+** (anual); municipal-mensal 2011+ | 🟩 comparável |
| **Roubo / Furto "outros"** | "Roubos"/"Furtos" do RS já **excluem veículos** (não subtrair), mas **incluem banco/comércio** (e furto inclui abigeato) que SP exclui | aproximado **2002+**; estrito (via microdado) **2022+** | 🟨 consolidação |
| **Estupro (total)** | **Microdado** (Estupro + Vulnerável, ambos os sexos); VCM mede ~metade | microdado **2022+**; VCM 2012+ | ⏳ decisão (§8) |
| **Armas apreendidas** | PC + BM (só estadual); **somar só de 2017** (até 2016 a linha "PC" já inclui a BM) | estadual **2007+** (estrutura por força limpa de 2017) | 🟨 sem mapa |
| **Prisões efetuadas** | SP = **só PC**: flagrantes lavrados + mandados cumpridos. RS = Inc. IX (flagrante, municipal) + presos por mandados PC (estadual) | flagrante municipal **2022+**; total estadual **2017+** | 🟨 mandados sem mapa |
| **Núcleo prisional (SISDEPEN)** | Mesma fonte nacional, mesma estrutura | **2017+** | 🟩 comparável |
| Contexto: PIB / saúde / educação | Nacionais | PIB 2010+; saúde 2018+; educação anual | 🟩 comparável |

🟩 **Regra de ouro dos períodos:** um painel **criminal + prisional "núcleo"** funciona de **2017+**; incluir **armas, prisões e estupro estritamente comparáveis** restringe a **2022+**; a **série criminal isolada** (homicídio/furto/roubo) recua a **2002**. Recomenda-se exibir a janela válida de cada indicador, não um eixo único.

🟦 **Atenção (do dicionário):** a **unidade de análise difere por crime** — furtos/roubos/armas por ocorrências; homicídio/latrocínio por ocorrências e vítimas; estupro/feminicídio por vítimas. Alinhar a unidade antes de comparar.

🟩 **Resolução da dúvida de prisões (sem dupla contagem):** como SP conta **só a Polícia Civil**, a métrica do RS também é PC-only — a soma PC+BM, que duplicaria flagrantes, **não se aplica**. O "flagrantes elaborados pela PC" (Inc. IX) corresponde exatamente ao 1º componente de SP.

---

## 7. Avaliação de viabilidade

**Técnica — 🟩 alta.** Todas as fontes necessárias existem e estão acessíveis; o microdado foi validado; as transformações são conhecidas e documentadas. O custo está na engenharia de consolidação (padronizar séries de origens e unidades distintas), não na disponibilidade do dado.

**Metodológica — 🟨 média, com cuidados.** Comparabilidade entre estados exige rigor: taxas e tendências (não absolutos), unidade de análise alinhada por crime, janelas temporais explícitas, e uma divergência conhecida no estupro entre dois produtos da SSP-RS a esclarecer.

**Institucional — 🟦 favorável, com solicitações pontuais.** A SSP-RS é transparente (Lei 15.610/2021 obriga microdados mensais e 29 indicadores semestrais). Para granularidade municipal de **armas** e do **componente de mandados** das prisões, será preciso solicitar dados à SSP-RS/PC/BM.

---

## 8. Decisões e perguntas para o grupo

⏳ **1. Estupro — qual fonte usar no comparativo SP↔RS?**
- **Microdado** (recomendado para comparar com SP): total, ambos os sexos, ocorrências — mas só desde 2022.
- **VCM**: série mais longa (2012+), mas mede ~metade do total — é o produto do Observatório da Violência Contra a Mulher, com **recorte da Lei Maria da Penha** (relações familiares/íntimas); subconjunto estável (correlação municipal 0,99 com o microdado).
- A confirmar **na fonte primária do Observatório**: que o recorte Maria da Penha é o que explica a ~metade (a descrição foi obtida da página da SSP-RS, a validar).

🟨 **2. Prisões por município:** aceitamos exibir no mapa só o componente **flagrante** (municipalizado), mantendo o total estadual completo? Ou solicitamos à SSP-RS o componente de **mandados** com município?

🟩→a confirmar **3. Definição de "prisões efetuadas" de SP:** validar formalmente com a equipe SP a fórmula levantada (Res. 160/2001: PC = flagrantes + mandados).

🟨 **4. Profundidade histórica × comparabilidade estrita:** para roubo/furto "outros", aceitamos a aproximação via agregado (série 2002+) ou exigimos a reconstrução estrita via microdado (2022+)?

🟦 **5. Região:** SP usa 11 macrorregiões; o RS tem recortes próprios (RISP/COREDEs) não equivalentes. Definir se o comparativo será municipal/estadual, tratando "região" à parte.

---

## 9. Recomendações de arquitetura (RS)

🟦 Decorrências do diagnóstico:

1. **Base criminal = microdados Mensais**, com uma camada de agregação município/período que produza as variáveis do painel — validada, flexível e auditável. Os agregados (Indicadores Criminais) entram para a série histórica longa (2002+).
2. **Pipeline reprodutível**: `targets` (orquestração, elimina o acoplamento em memória) + `renv` (lockfile) — corrige as fragilidades observadas em SP.
3. **Parametrizar a UF** (RS/SP) numa única base de código, em vez de filtros hardcoded — viabiliza o painel comparativo.
4. **Dicionário de-para SP↔RS** por indicador (idêntico / consolidado / exclusivo / janela válida), exposto na interface.
5. **Comparar por taxas e tendências**, com nota metodológica e a janela de cada indicador visível.
6. Construir a extração de **educação (distorção idade-série)** e de **saúde (DATASUS)** que em SP são manuais/parciais.

---

## 10. Roteiro de adaptação proposto

🟦 Sequência sugerida:

1. **Confirmar** com a equipe SP a definição de prisões e, com a SSP-RS, a divergência do estupro.
2. **Decidir** os itens da §8 com o grupo.
3. **Núcleo prisional (SISDEPEN-RS)** — adaptar primeiro (menor risco, maior valor: é o monitor "prisional").
4. **Camada criminal** — construir o pipeline microdado→indicadores (de-para validado) + série histórica via agregados.
5. **Contexto** — IBGE/INEP/DATASUS para o RS.
6. **Painel comparativo** SP↔RS por taxas, com janelas explícitas.

---

## 11. Ressalvas metodológicas (a explicitar na apresentação)

- 🟩 Comparabilidade interestadual é limitada por critérios de registro distintos (a própria SSP-RS adverte) → **taxas e tendências**, não absolutos.
- 🟩 Unidade de análise difere por crime (ocorrências × vítimas).
- 🟩 Dados administrativos sofrem **revisão** após a extração (diferenças de ±0,1–0,3% são esperadas).
- 🟩 Produtividade policial **pré-2017** no RS não é separável/somável por corporação de forma consistente (a PC consolidava apreensões da BM) — usar 2017+ para armas/prisões por força.
- 🟩 Estupro: a VCM mede ~metade do total — recorte da Lei Maria da Penha (Observatório SSP-RS), a confirmar na fonte primária; para o total comparável a SP, usar o microdado.

---
*Síntese baseada em inspeção do repositório SP (somente leitura), leitura das fontes oficiais (Lei 15.610/2021, dicionários da SSP-RS, Nota Metodológica do Monitor SP), confirmações da equipe SP (M. Martins) e reconciliação empírica dos microdados RS (2023 e 2024). Verificações em `docs/auditoria.md`; detalhes nos demais documentos de `docs/`.*
