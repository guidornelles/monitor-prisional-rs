# Decisões metodológicas — PoC do Monitor Prisional RS

> Log das escolhas que parametrizam o pipeline (`scripts/rs/00_config.R` → `cfg$escolhas`).
> Mudar uma decisão = mudar o parâmetro, sem reescrever o código. Marcadores: 🟩 verificado · ⏳ a decidir/confirmar com a equipe. Data: 2026-06-10.

## Reprodutibilidade (corrige os problemas do Monitor SP)
- **Scripts numerados + `run_all.R` + `renv`** (decidido) — sem branches, sem acoplamento em memória, com lockfile de pacotes.
- Cada etapa **lê/escreve arquivos** em `data/{raw,intermediate,processed}`; nenhuma depende de objeto em memória de outra.
- Caminhos e parâmetros **centralizados** em `00_config.R` (nada hardcoded espalhado).
- **Dados nacionais baixados por script** (não manual) — segue as Notas Metodológicas de SP.
- **Arquivos de auditoria** gerados a cada etapa (`outputs/auditoria/`) para conferência.

## Escolhas por indicador
| Indicador | Decisão | Status |
|---|---|---|
| Estupro | **Microdado total** (Estupro + Vulnerável, ambos os sexos) — comparável a SP | 🟩 |
| Roubo/Furto "outros" | **Reconstrução estrita via microdado** (exclui veículo + banco/comércio/carga) | 🟩 / ⏳ ver nota |
| Homicídio | **Duas variáveis**: `hd_vitima` (agregado oficial "Total de vítimas de HD") + `hd_ocorrencias` (microdado) | ⏳ levar à equipe SP |
| Armas / Prisões | Só PC, conforme SP (Res. 160/2001); armas estadual, prisões = flagrante municipal + mandados estadual | 🟩 / ⏳ confirmar com SP |
| Período | **2022–2025** (era dos microdados) | 🟩 |
| Taxas | Absolutos **+ por 100 mil** (população a integrar no módulo de contexto) | 🟩 |

## Recorte territorial e regional
🟩 **Unidade base:** município. **Região:** o Monitor de SP usa as **regiões geográficas intermediárias do IBGE** (verificado: a coluna `nome_regiao_intermediaria` consta na `populacao_municipios_sp.xlsx`, e as regiões exibidas no painel batem com as regiões intermediárias do IBGE para SP). **Decisão:** adotar o **mesmo conceito para o RS** — regiões geográficas intermediárias do IBGE (RS tem 8). O mapeamento município→região vem do **diretório de municípios do IBGE** (mesma fonte que SP usou via basedosdados); no módulo de contexto, obteremos `cod_ibge → nome_regiao_intermediaria` de fonte IBGE reprodutível (divisão regional 2017 / pacote `geobr` ou SIDRA), sem depender de billing GCP.

### Notas e perguntas para a equipe SP / SSP-RS
- **`hd_vitima` vs `hd_ocorrencias`:** o nome de SP é `hd_vitima` (vítimas). O campo "Quantidade Vítimas" do microdado RS superconta vítimas (~+15%) vs. o agregado oficial; por isso `hd_vitima` usa o **agregado oficial** e mantemos `hd_ocorrencias` do microdado. **Perguntar a SP** qual exatamente alimenta o monitor.
- **Composição de "roubo/furto outros":** SP exclui veículo, banco, carga "e outras variações". A reconstrução estrita exclui veículo + banco/comércio/carga/transporte (e abigeato no furto). **Confirmar com SP** a lista exata de subtipos do "outros".

## Validação (auditoria automática — `outputs/auditoria/criminal_reconciliacao.csv`)
Reconciliação dos **totais** reconstruídos do microdado vs. a coluna oficial dos Indicadores Criminais:

| Ano | Δ homicídio | Δ furtos | Δ roubos | Veredito |
|---|---:|---:|---:|---|
| 2023 | −0,19% | −0,05% | −0,29% | ✅ reconcilia |
| 2024 | −0,07% | +0,01% | −0,36% | ✅ reconcilia |
| 2025 | −0,21% | −1,96% | −1,30% | 🟨 desvio leve (revisão recente?) |
| 2022 | −0,25% | **−24,4%** | −4,3% | 🟥 **anomalia — investigar** |

🟥 **Achado 2022 — aprofundado (ver `docs/problemas_dados.md`):** déficit de furtos isolado em 2022. Confirmado:
- Oficial 2022 **"Furto" = 128.047** (coluna isolada; "Abigeato"=4.881 e "Furto de Veículo"=8.953 são colunas à parte — não é total agregado).
- Microdado 2022: **todos** os enquadramentos com "FURTO" = **104.449**; o subconjunto comparável (exclui furto de veículo e abigeato) = **92.793**; nosso `furtos_total` = 96.768. Mesmo a soma de TODOS os furtos do microdado fica abaixo do "Furto" oficial.
- Déficit **uniforme nos 12 meses** (~7–8 mil/mês) → não é mês faltante, é descompasso sistemático.
- Roubos 2022 também levemente baixos (−4,3%); homicídio bate. 2023–2025 reconciliam.
- **Leitura:** o microdado aberto de 2022 parece **sub-registrar crimes patrimoniais** (sobretudo furtos), não explicável por classificação. **Pendência:** confirmar com a SSP-RS se o microdado aberto de 2022 saiu incompleto para furtos, ou se o "Furto" oficial de 2022 usa mapeamento de enquadramentos/fonte diferente. Até lá, **tratar 2022 com cautela** (sinalizar nos painéis criminais).

O "outros estrito" fica ~7% abaixo do total de roubos (a exclusão banco/comércio/carga) — por construção, e por isso **não** se compara diretamente com a coluna oficial "Roubos".

## Panorama de Saúde — `01c_download_datasus.R` (mortalidade) + `04b_saude_casos.R` (casos)
🟩 **Espelha SP** (Notas Metodológicas): por município×ano, **casos notificados e mortes** por tuberculose, hepatite e HIV (DATASUS). SP compila isso **manualmente do TABNET**.
🟩 **Decisão: TABNET para tudo (canônico), em `04b_saude.R`.** Como os CASOS notificados (TB/hepatite/HIV) só existem via TABNET (o `microdatasus` não cobre esses SINAN — verificado na doc oficial: só dengue/chikungunya/zika/malária/chagas/leishmaniose/leptospirose), optou-se por fazer **também a mortalidade pelo TABNET (SIM/CID-10)**, unificando o fluxo, evitando a dependência do `microdatasus` (install_github, read.dbc no Windows, FTP instável) e espelhando o método de SP. São ~6 exportações (linha=Município residência, coluna=Ano, filtro UF=RS): casos TB (`tubercbr.def`), hepatite (`hepabr.def`), HIV (aids.gov.br); óbitos TB/hepatite/HIV (SIM, filtrando CID-10 A15–A19 / B15–B19 / B20–B24).
- **Alternativa opcional:** `01c_download_datasus.R` faz só a mortalidade via `microdatasus` (SIM-DO), para quem preferir automatizar essa parte.
- 🟩 `04b_saude.R` (ingestão) escrito e **validado** contra o export real de tuberculose: formato largo (`"Município de residência";"2018"...;"Total"`), código IBGE de 6 díg. + nome, `-`=0, rodapé "Total"/`&` descartados; reproduz exatamente os totais do TABNET (6.479…7.846/ano) e os 6 díg. casam 100% com o IBGE. O mesmo parser serve para hepatite/HIV/óbitos (indicador inferido do nome do arquivo). Junção por `substr(id_municipio,1,6)`.
- 🟩 **Período: 2018–2025** (como SP). Camada com janela própria; painel separado (`painel_saude_municipio_ano.csv`), não no painel criminal (2022–2025).
- 🟩 **Cobertura temporal heterogênea → NA por indicador (não 0).** Lacuna estrutural (ano ausente para um indicador) = NA, não zero; zeros reais vêm do "-" do TABNET. Corte por **último ano consolidado** (`cfg$saude_ano_max*`; valores além = NA, provisório): **casos_hepatite até 2023** (SINAN hepatites virais consolidado só até 2023, conforme nota do TABNET); **demais até 2024** (SINAN casos e SIM óbitos: 2025 ainda provisório em jun/2026). Validado: 6 indicadores, hepatite NA em 2024–2025, tudo NA em 2025.
- 🟩 **Seis exportações ingeridas** (TB/hepatite/HIV × casos/óbitos). Totais conferem com a linha "Total" do TABNET.

🟩 **Correção (qualidade):** a API do IBGE devolveu 1 registro vazio (498 linhas = 497 municípios + 1 NA), que tornava `id_municipio` float. Corrigido na fonte (`01_download.R` filtra NA) e defensivamente no `04_contexto.R`.

## Planilha final / crosswalk municipal — `05_planilha_final.R`
🟩 **Saída espelhando o Looker de SP** (tabelas separadas, blendadas pela chave municipal):
- `outputs/tabelas/painel_criminal_municipio_ano.csv` — grão município×ano: `hd_vitima, tot_estupro, roubo_outros, furto_outros, prisoes` (nomes de SP) + `hd_ocorrencias` (extra RS) + `populacao, pib, distorcao_idade_serie_fund` + `*_taxa_100k`. Grade completa **497×4** (ausência de registro = 0 ocorrências). Validado: 1.988 linhas, sem duplicatas.
- `painel_prisional_estabelecimento.csv` — camada SISDEPEN por estabelecimento, enriquecida com `nome_regiao_intermediaria` via `Código IBGE`.
- `painel_contexto_municipio.csv` — denominadores/panoramas.

🟩 **Crosswalk de nome de município (SSP→IBGE):** chave = nome normalizado (maiúsculas, sem acento; apóstrofo deletado, hífen→espaço). Resolve "Sant'Ana"↔"Santana", "Entre-Ijuís", "Xangri-lá", "Não-Me-Toque". Mais um **mapa de aliases explícito** (15 entradas) para divergências de grafia e **erros de digitação na fonte** ("Aceguaá"=Aceguá, "São Josedo Ouro"=São José do Ouro, "Estância Velhas"=Estância Velha, "DR"=Doutor, "Pinto Bandeira (Bento Gonç)"=Pinto Bandeira). Preferiu-se mapa explícito a fuzzy às cegas (auditável). Resultado: **495/497** municípios com flagrantes pareados; residual não-pareado = ~13 registros (0,04% das prisões), todos de **outras UFs** (SC/RJ/SP/MG/PR), corretamente descartados. Auditoria em `outputs/auditoria/match_municipios.csv`.

## Prisões e armas — `02b_atividade.R`
🟩 **`prisoes` = flagrantes da PC por município** (fonte: dados abertos Lei 15.610/2021, Art. 6º Inc. IX — "Prisões em Flagrante pela PC por Fato e Município", 1 arquivo/semestre, microdado). Contagem de linhas por município×ano (soma dos dois semestres). Cobertura RS (totais): 2022≈28.373 · 2023≈30.432 · 2024≈28.901 · 2025≈31.680; municípios com ≥1 flagrante por ano: 438/452/477/471.
- ⚠️ **Limite (divergência de SP a documentar):** inclui **somente flagrantes**. Mandados de prisão só existem em nível **estadual** no RS — não municipalizáveis —, então ficam de fora. A composição de `prisoes` no RS pode diferir da de SP.
- 🟥 **`ap_armas` NÃO entra na tabela municipal:** no RS as apreensões de armas só existem em **nível estadual**. Não se reparte total estadual entre municípios (seria invenção). SP tem armas por município porque a SSP-SP publica assim. Opção: tabela estadual separada (`armas_rs_estadual_ano`), grão estado×ano — fora do mapa municipal.
- ⚠️ **Encoding (problema de dados):** os CSVs de flagrante variam entre **UTF-8 e CP850 (DOS)**. Ler CP850 como latin1 gera mojibake ("SÆO LEOPOLDO") que vira chave duplicada de município (inflou 2022 de 438 para 558). `02b` escolhe o encoding por bytes (menos caracteres suspeitos) e normaliza nome (maiúsculas + sem acento) para casar com o IBGE. Também há **bloco de título** antes do cabeçalho (detectado dinamicamente) e **rodapé** ("Fonte:"/"Extração:") descartado pelo filtro de município vazio.
- ⏳ **Match município→IBGE:** ~522 chaves distintas (2022–2025) vs 497 do IBGE — excesso são municípios de outros estados/variantes; o join no `05` casa por nome normalizado e **audita os não-pareados** (para não perder município real do RS por divergência de grafia).

## Derivadas prisionais — `03b_prisional_derivadas.R` + `03c_mortalidade.R`
🟩 **Colunas derivadas que o Base_Sisdepen de SP publica** (não estão no SISDEPEN bruto), calculadas por **padrão de nome** (não transcrição). Validado: 414 estabelecimentos; cada regime soma exatamente 3 colunas (Estadual+Federal+Outros).
- **Regime (4.1):** `provisorios/sentenciado_fechado/semiaberto/aberto/internacao/tratamento × M/F` — fiel a SP.
- **Pena (5.12)** `pena_{m,f}_{0_4,1_8,8_15,15_20,20_30,30_50,50_mais,sem_info}` e **pena remanescente (5.13)** `pena_remanescente_{m,f}_{0_4,4_8,8_15,15_20,20_30,30_50,50mais}` — fiel a SP (mantém os rótulos de SP, ainda que "1_8anos" contenha a faixa 4–8 anos: é o nome de SP, não erro de conta).
- **Filhos (5.10):** `mulheres/homens_presos_com_filhos_as` = soma de 1..10 e "11 ou mais".
- **Tipo penal (5.14) — CORRIGIDO** (decisões do pesquisador; ver `docs/auditoria_tipo_penal_sp.md`):
  - `desarmamento` = **soma dos 5 tipos** (SP somava só 1 — bug auditado). Validado: total RS_M 15.283 (vs ~só Art.X no SP).
  - `contra_patrimonio` = **AMPLO: 13 subtipos** do CP (furto/roubo/latrocínio + extorsão, extorsão mediante sequestro, apropriação indébita e previdenciária, estelionato, receptação e qualificada).
  - `outros` = **RESIDUAL**: total 5.14 (por sexo) − soma dos 5 grupos nomeados → partição sem dupla contagem (validado ≥ 0; RS_M = 207.913 − 186.298 = 21.615).
  - `contra_pessoa` (8), `dignidade_sexual` (7), `drogas` (3) — somas fiéis. Totais M/F/Total a partir das colunas do grupo.
  - ⚠️ **Diverge do output (bugado) de SP**; levar à equipe de SP.
- **Mortalidade (`03c`, seção 6.8, 2º semestre** — como a Nota de SP e o `dados_sem2.R`): `obitos_{naturais,criminais,suicidios,acidentais,desconhecida}_{m,f,total}`. Validado RS: 69/52/61/81 óbitos (2022–2025). Junta-se ao painel prisional por `id` no `05`.

## Camada prisional (SISDEPEN-RS) — `03_prisional.R`
🟩 **Fonte: Base Única consolidada da SENAPPEN** (`cfg$escolhas$sisdepen_fonte = "base_unica"`). Decisão revista após inspeção: a SENAPPEN publica, sim, uma **Base Única** ("Todos os ciclos em arquivo único") via SharePoint, além dos arquivos por ciclo. Verificado no arquivo consolidado (28.825 linhas, ciclos 2016–2025, 1.782 colunas).

**Por que a Base Única, e não os arquivos por ciclo (como SP fez):**
1. **`Tipo de Recolhimento` (cela física/domiciliar) vem 100% preenchido em TODOS os anos (2016–2025).** Nos arquivos por ciclo, esse campo só existe a partir de 2024 — o que obrigava a uma aproximação em 2022–2023 (via `1.2 Tipo de estabelecimento`). A Base Única **elimina a aproximação**: recorte cela física nativo e exato em toda a série.
2. Traz **`ID` de estabelecimento estável entre ciclos** (protege contra mudança de nomenclatura — alinhado à filosofia de crosswalk da tese) e `ciclo`/`Ano`/`Referência` (empilhamento longitudinal embutido).
3. **Esquema único de 1.782 colunas** — sem a heterogeneidade entre ciclos (arquivos por ciclo variam: 2022 tinha 1.334 colunas; 2024, 1.737).
4. É a fonte canônica usada na tese do pesquisador, que atualiza os ciclos a partir dela.

**O que SP fez (evidência do `depen.R`, repositório SP):** leu arquivos **por ciclo**, 1º semestre, 2017→2023, com único filtro `UF == "SP"` — **sem recorte por tipo/recolhimento**. SP não precisou filtrar porque sua janela terminou em 2023, antes de o campo existir nos arquivos por ciclo. **Erro de SP a corrigir:** SP manteve no Monitor estabelecimentos que são apenas cadastros de prisão domiciliar / monitoração eletrônica (inflando contagens — caso de 2021, em que a administração de SP triplicou cadastros do mesmo estabelecimento: cela física + domiciliar + domiciliar c/ monit. eletrônica). Nosso recorte corrige isso.

🟩 **Recorte (`cfg$escolhas$prisional_recorte = "cela_fisica"`):** `UF == RS` + `Tipo de Recolhimento == "Cela física"` + **salvaguarda por nome** (exclui registros tipados cela física mas nomeados domiciliar/monitoração — replica o filtro duplo da tese; em RS hoje não há nenhum, mas guarda ciclos futuros). Semestre 1 (perfil/capacidade/estrutura, como SP); mortalidade (seção 6.8) = semestre 2 (`prisional_semestre = 2L`).

🟩 **Espelhamento de SP:** seleciona a interseção com o esquema `Base_Sisdepen` de SP (`data/raw/sp_schema_prisional.csv`, 377 colunas) + 3 colunas de identidade da Base Única (`ID`, `ciclo`, `Referência`). Resultado: **311/377** colunas. As ~66 ausentes são **variáveis derivadas por SP** (`provisorios_*`, `sentenciado_*`, `obitos_*`, faixas de pena), computadas em `depen.R` a partir das colunas brutas — replicação é passo posterior.

**Cobertura RS (cela física, 1º sem):** 2022=104 · 2023=103 · 2024=104 · 2025=103 (auditoria: `outputs/auditoria/prisional_cobertura.csv`). **Validação cruzada:** a aproximação por ciclo de 2022 dava 107 — a Base Única (campo nativo) dá 104, mostrando que a aproximação **supercontava 3 unidades**. Mais um argumento pela Base Única.

🟩 **Reprodutibilidade — resolvida (era o único trade-off):** a Base Única é baixada de forma **scriptável** direto do SharePoint, anexando `&download=1` ao link de compartilhamento (testado: download estável, mesmo md5 em repetições). `01b_download_sisdepen.R` faz o download (URL em `cfg$sisdepen_baseunica_url`), confere **md5** (`cfg$sisdepen_baseunica_md5 = a4ab2749887c49879b47b10fc72d86b4`, 70.983.784 bytes — o que `download.file` produz) e grava manifesto. Fallback: se o SharePoint devolver HTML de interstício, o script avisa e o download manual cobre. Os arquivos **por ciclo** (gov.br, `baixar_ciclos = TRUE`) ficam como validação independente. Arquivo localizado por `00_config.R::arquivo_baseunica` (padrão `*baseunica*.xlsx`).
- **Nome de arquivo versionado:** o `01b` salva com o nome que o SharePoint informa no `Content-Disposition` (via `httr2`), que embute o **timestamp do release** (ex.: `sisdepen_baseunica_2025-2_25032026-163420.xlsx` = 25/03/2026 16:34:20). Assim cada versão é autoidentificável e não sobrescreve outra — alinhado ao tratamento de *mutability of administrative data*. `arquivo_baseunica()` localiza por `*baseunica*.xlsx` e usa o mais recente.
- **Nota de proveniência:** o **canônico é o arquivo baixado pelo script** (md5 `a4ab2749`, 70.983.784 bytes), não cópias manuseadas. A cópia no repo da tese (md5 `2ca60a94`, +1.448 bytes) difere por reescrita do Excel ou release anterior — ~1,4 KB em 71 MB, irrelevante para os dados. Confirmar equivalência pelos números da auditoria do `03` (RS cela física 104/103/104/103). O md5 é checado como **aviso** (não erro): nova versão da SENAPPEN gera novo nome + novo md5; atualizar `cfg$sisdepen_baseunica_md5`.
- *Nota de qualidade:* a coluna `Ano` da Base Única mistura tipos em 2025 (texto `"2025"` e número `2025`); usamos `Referência` ("AAAA/S") para semestre/ano, que é consistente.
