# Auditoria dos documentos do diagnóstico (2026-06-09)

> Revisão criteriosa dos quatro documentos antes de avançar para o diagnóstico de viabilidade. Objetivo: garantir que **toda afirmação marcada como fato (🟩) tenha uma verificação que a sustente**, rebaixar para inferência o que não tiver, e corrigir contradições entre documentos.
>
> Critério adotado: 🟩 só permanece se a afirmação foi (a) verificada por computação nesta sessão, (b) lida diretamente em arquivo oficial (lei, dicionário, Nota Metodológica, código SP), ou (c) confirmada por inspeção de dados. Caso contrário, vira 🟦/⏳.

## 1. Resultado por documento

| Documento | Estado | Ação |
|---|---|---|
| `inventario_repositorio_sp.md` | ✅ Sólido | Tudo verificado por inspeção git/código e leitura da Nota Metodológica. Sem correções. |
| `poc_reconciliacao.md` | ✅ Sólido | 1 imprecisão corrigida: §5 dizia "todos dentro de ±0,3%", mas latrocínio é −2,4%/−3,5% (baixo volume) — reescrito. |
| `lacunas_dados_rs.md` | ✅ Consistente | Reflete as correções de prisões/armas. Sem contradições. |
| `fontes_dados_rs.md` | ⚠️→✅ Corrigido | Tinha **7 trechos desatualizados** que contradiziam correções posteriores (listados em §3). Todos alinhados. |

## 2. Afirmações empíricas-chave e sua verificação

Cada fato 🟩 carregante foi confirmado por computação nesta sessão:

| Afirmação | Como foi verificada | Evidência |
|---|---|---|
| Microdado reproduz Indicadores Criminais 2023 (ocorrência) | Agregação Python + awk independente | Homicídio −0,2%; Furtos −0,1%; Roubos −0,3%; veículos ~0% |
| Idem 2024 (replicação) | Repetição do mesmo método | Mesma faixa de erro; ≥96% dos municípios dentro de 1% |
| "Roubos"/"Furtos" já excluem veículos (não subtrair) | A reconstrução por soma de subtipos (excl. veículo) bateu com os agregados | Furtos 125.466 vs 125.529 |
| Abigeato está dentro de "Furtos" | Incluído na soma de furtos → reconciliou | (mesma verificação) |
| Estupro: VCM é subconjunto estável (~metade) do microdado, corr 0,99 | Recálculo municipal com GERAL excluída (ver §7) | 2023: VCM_mun 2.820 vs micro 5.627 (0,50); 2024: 2.522 vs 5.478 (0,46); corr 0,985–0,990 |
| Prisões: Inc. IX (PC) = "flagrantes elaborados", não exclusivo PC | Cruzamento Lei 15.610 × Indicadores de Atividade | Inc. IX 30.436 ≈ atividade 30.426; exclusivo PC = 7.121 |
| Prisões: Inc. VIII (BM) = "prisões realizadas pela instituição" | Mesmo cruzamento | Inc. VIII 111.574 ≈ atividade 111.634 |
| Somar PC+BM duplica ~23 mil flagrantes | Diferença flagrantes elaborados (30,4 mil) − exclusivos PC (7,1 mil) | ~23 mil |
| Armas: PC e BM exclusivas, somáveis (2017+) | Cruzamento Lei 15.610 × atividade | 2023: PC 3.907≈3.887; BM 5.613≈5.611 |
| Armas até 2016: linha "PC" já contém a BM | Inspeção das abas 2007–2016 | PC armas ≥ BM armas em todos os 10 anos; nota explícita em 2010/2016 |
| Prisões pré-2017: "PC contém BM" é falso | Comparação BM vs PC todos os anos | BM "prisões realizadas" 20–30× a PC (ex.: 2016 → 108.670 vs 6.032) |
| Períodos das fontes RS | Listagem de arquivos | Indicadores 2002–2025; VCM 2012–2025; Mensais 2022–2025; Semestrais 2021.2–2025.2; Atividade 2007–2026 |
| Estrutura/scripts/fontes do repo SP | Inspeção git (todas as branches/commits) + leitura dos scripts | branch `R`@`efe1a1a`; pipeline `depen.R`→`dados_sem2.R` |
| Saúde = DATASUS; SP desde 2001; SISDEPEN 2017; regra 1º/2º sem | Leitura da Nota Metodológica do Monitor SP | `docs/referencias/Nota_Metodologica_Monitor_SP.pdf` |
| Incisos da Lei 15.610 (VIII/IX prisões, VII armas, X Susepe…) | Leitura integral da lei (PDF) | `…22201614-lei-n-15-610…pdf` |

## 3. Correções aplicadas em `fontes_dados_rs.md`

Trechos que estavam **desatualizados** em relação às verificações posteriores (e que se contradiziam com `poc_reconciliacao.md` §4c e com o próprio §3.5):

1. §3.4 (prisões): dizia *"não dá para saber se o Inc. IX exclui a BM… confirmar com a SSP-RS"* → corrigido para a sobreposição **confirmada** (usar só Inc. IX, não somar).
2. §4 tabela (prisões): *"somar dá o total… verificar sobreposição"* → **não somar; usar Inc. IX**.
3. §4 tabela (armas): fonte dizia só "BM" e somava sem ressalva → **PC + BM, somáveis de 2017**.
4. §5 item armas: faltava a quebra de 2016/2017 → adicionada.
5. §5 item prisões: listado como lacuna "a confirmar" → reclassificado (sobreposição resolvida; resta escopo vs SP).
6. §5 item saúde: ainda listava "confirmar se é DATASUS" → **removido** (já resolvido como DATASUS no §2).
7. §5: recomendava *"rodar uma PoC"* já concluída → substituído por referência ao resultado da PoC.

## 4. Afirmações 🟩 que se apoiam em fonte documental (não re-derivadas dos dados)

Permanecem como fato por estarem em **documento oficial**, mas registro a distinção: não foram reconfirmadas abrindo os arquivos-fonte ano a ano. Se forem usadas como premissa crítica, vale validar:

- "Indicadores Criminais têm série municipal **mensal desde 2011**" — afirmação do **dicionário .xlsx** (não abri as planilhas mensais de 2011).
- "VCM tem estupro municipal **mensal desde 2018**" — idem (dicionário).
- "SP — Dinâmica Criminal **desde 2001**" e "DATASUS **desde 2018**" — afirmações da **Nota Metodológica de SP** (não verificadas nas bases primárias).

## 5. Itens genuinamente em aberto (não são fatos — são decisões/pendências)

- ⏳ **Estupro**: microdado (total, comparável a SP, 2022+) vs VCM (subsérie ~metade, 2012+) — decisão da equipe. A ~metade é explicada pelo **recorte da Lei Maria da Penha** da VCM (Observatório SSP-RS), **a confirmar na fonte primária** (ver §9).
- 🟨 **Prisões por município (componente mandados)**: o público só municipaliza o flagrante (Inc. IX); o componente de mandados é estadual — para o mapa completo, solicitar à SSP-RS/PC.

**Itens já resolvidos** (antes em aberto): saúde = DATASUS (confirmado por Nota + M. Martins); educação = distorção idade-série, não IDEB (confirmado por M. Martins); definição de "prisões efetuadas" de SP = só PC (flagrantes + mandados), Res. SSP-SP 160/2001 (levantamento documental, a confirmar formalmente com a equipe SP). A sobreposição PC×BM deixou de ser problema porque a métrica de SP é PC-only.

## 6. Lição metodológica incorporada

Os erros corrigidos ao longo do diagnóstico (prisões "sem município"; "não somar / dupla contagem"; "PC contém BM") tiveram a **mesma origem**: tratar uma leitura isolada (um arquivo, uma nota, um inciso) como conclusão antes de cruzá-la com os dados. A regra adotada daqui em diante: **nenhuma nota metodológica vira fato sem ser batida contra os números, em mais de um ano/fonte**. A verificação empírica é o critério final, acima da documentação oficial.

## 7. Adendo — erro encontrado APÓS a auditoria (estupro / linha "GERAL")

A primeira versão desta auditoria **manteve** a conclusão anterior de que "a VCM diverge muito do microdado no estupro e é instável ano a ano". Ao testar uma hipótese levantada pela equipe (ocorrências vs vítimas), recalculei e descobri que **aquela conclusão estava errada** — e a auditoria não a havia pego, porque eu confiei nos meus números anteriores em vez de re-derivá-los.

Causa: a planilha VCM tem uma linha **"GERAL"** (total) que eu não excluía. Ela inflava o total da VCM (de 2.820 para 5.640 em 2023) e, como entrava no cruzamento municipal como outlier (VCM>0, micro=0), **destruía a correlação** (aparente 0,13).

Corrigido (GERAL excluída): a VCM é um **subconjunto estável** do microdado — **correlação municipal 0,99**, razão **0,50 (2023) / 0,46 (2024)**. A diferença **não** é ocorrência vs vítima (refutado: corr idêntica 0,990/0,994), nem sexo (feminino = 0,81). **Exame da planilha:** a nota 3 da VCM declara a **mesma definição** do microdado (Estupro + Estupro de Vulnerável) — portanto a divergência de ~2× é **entre dois produtos/sistemas da SSP-RS** (SPJ Dados Abertos × SIP/PROCERGS) sob a mesma definição **de subtipos**, de causa então não esclarecida. (Naquele momento retratei a especulação de "recorte de violência doméstica" por não estar na nota 3.) **→ Resolvido depois (§9):** a descrição do Observatório estabelece o recorte da Lei Maria da Penha, que explica a ~metade — a confirmar na fonte primária.

Documentos corrigidos: `poc_reconciliacao.md` (§2, §4, §4b), `lacunas_dados_rs.md` (§2, §7), `fontes_dados_rs.md` (§3.2, §4) e esta tabela (§2).

## 8. Re-execução completa do zero (a pedido) — resultados

Todas as planilhas reexaminadas; números re-derivados sem confiar em valores anteriores. Guarda anti-contaminação aplicada: em cada tabela oficial, listei as linhas **não-municipais** comparando com o conjunto canônico de 497 municípios.

- **Linhas-agregado detectadas:** Indicadores Criminais → só "Total RS" (já excluída) + 3 notas de rodapé + "Pinto Bandeira" (grafia divergente, 1 município pequeno). VCM → "Geral" (agregado), notas e 4 municípios com grafia divergente (Barão de Cotegipe, Não-Me-Toque, Xangri-lá, Pinto Bandeira). Nenhuma outra contaminação.
- **Reconciliação criminal (re-rodada 2023 e 2024):** homicídio, latrocínio, furtos, furto de veículo, roubos, roubo de veículo — Δ estadual entre −0,4% e +0,01% (latrocínio −2,4/−3,5%, baixo volume); **99–100% dos municípios dentro de 1 caso/1%**. ✅
- **Prisões 2023 (re-cruzado):** Lei 15.610 PC Inc. IX = 30.436 ≈ atividade "flagrantes elaborados" 30.426; BM Inc. VIII = 111.574 ≈ "prisões realizadas" 111.634. ✅
- **Armas (re-derivado 2022/2023):** Lei 15.610 ≈ atividade (BM 5.613 vs 5.611 em 2023); somas 9.735 (2022) / 9.504 (2023); exclusivas por corporação. ✅
- **Estupro:** ver §7 (corrigido).

**Conclusão:** salvo o estupro (recorte Maria da Penha a confirmar — §9) e as pendências de decisão (§5 lacunas), os números estão **re-verificados e estáveis** — base pronta para o diagnóstico.

## 9. Estupro — escopo da VCM identificado (Observatório / Lei Maria da Penha)

Sequência da investigação (registro honesto das idas e vindas): (a) primeiro concluí "VCM diverge muito/instável" — **errado** (artefato da linha GERAL); (b) corrigido, achei VCM ≈ metade, corr 0,99, e **especulei** "violência doméstica"; (c) **retratei** a especulação ao ver que a nota 3 da planilha cita só os subtipos; (d) ao buscar os links das páginas da SSP-RS, a **descrição oficial do Observatório da Violência Contra a Mulher** estabelece que o produto cobre o **recorte da Lei Maria da Penha** (relações familiares/íntimas contra a mulher) — o que **explica** a ~metade.

Estado: explicação **sourced** (descrição do Observatório na página da SSP-RS), mas obtida via busca, não por leitura direta da página (renderizada em JavaScript). **A confirmar na fonte primária** antes de tratar como fato definitivo. A nota 3 da planilha (só subtipos) não contradiz — apenas não menciona o recorte de contexto, que é do nível do produto. Propagado a `fontes`, `lacunas`, `poc` e `diagnostico`.

**Lição (reforço):** a auditoria correta exige **re-derivar** os números, não reconferir prosa. Confiar em conclusão própria anterior foi o mesmo erro de origem que a auditoria deveria combater.

---
*Auditoria executada sobre os quatro documentos do diagnóstico. As verificações por computação foram refeitas/confirmadas nesta sessão sobre os arquivos em `data/EstatisticasCriminaisRS/`.*
