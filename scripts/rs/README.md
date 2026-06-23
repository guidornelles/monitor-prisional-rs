# Pipeline da PoC — Monitor Prisional RS

Pipeline reprodutível, modular e auditável que constrói as tabelas do Monitor RS no
padrão de variáveis do Monitor SP, para configuração no Looker Studio.

## Princípios (corrigem os problemas de reprodutibilidade do Monitor SP)
- **Sem branches; tudo em diretórios.** Código em `R/` (funções) e `scripts/rs/` (etapas numeradas).
- **Sem acoplamento por sessão.** Cada etapa lê de `data/raw`/`data/intermediate` e escreve arquivos.
- **Parâmetros e caminhos centralizados** em `00_config.R` (nada hardcoded espalhado).
- **Aquisição scriptada e versões fixadas** (`01a`/`01`); dados brutos NÃO vão para o Git.
- **Auditoria por etapa** em `outputs/auditoria/`.
- **Pacotes travados** via `renv` (`renv.lock`).

## Ordem de execução
1. `renv::restore()` — instala os pacotes (uma vez).
2. **Aquisição** (uma vez, com internet):
   - `01a_download_ssp_rs.R` — dados da SSP-RS (microdados, indicadores criminais, atividade, semestrais, VCM); baixa `.zip` e descompacta; gera `MANIFEST_ssp_rs.csv`.
   - `01_download.R` — nacionais (IBGE população/PIB; **região intermediária via API IBGE**; INEP distorção).
   - `01b_download_sisdepen.R` — SISDEPEN **Base Única** (download direto do SharePoint + `&download=1`, nome versionado, md5); ciclos = fallback.
   - `01c_download_datasus.R` — saúde DATASUS *(opcional; a escrever)*.
3. **Processamento** (`run_all.R` chama na ordem):
   - `02_criminal.R` — ✅ microdados → indicadores criminais por município×ano (regras validadas).
   - `02b_atividade.R` — ✅ prisões em flagrante (PC) por município×ano (Lei 15.610 Art. 6 IX).
   - `03_prisional.R` — ✅ Base Única SISDEPEN → base prisional (esquema 444, padrão Base_Sisdepen), recorte cela física; `Endereço` p/ mapa e `ano_inauguracao`.
   - `03b_prisional_derivadas.R` — ✅ derivadas prisionais (porta `depen.R` + `dados_sem2.R` de SP): regime, pena (binning SP), tipo_penal, continentes, **óbitos ANUAIS 1º+2º sem**, atendimento/gestantes/lactantes, populacao_total/capacidade_total/total_medicos/brasileiro_nato. *(Funde o antigo `03c_mortalidade.R`, descontinuado.)*
   - `04_contexto.R` — ✅ região intermediária + população + PIB + distorção idade-série; `munic_ep`/`ano_ep` (do prisional).
   - `04b_saude.R` — ✅ Panorama de Saúde (TABNET: casos+óbitos TB/hepatite/HIV); cortes por ano consolidado.
   - `05_planilha_final.R` — ✅ painéis no padrão SP + `id_municipio`, `ano`, taxas/100 mil; crosswalk SSP→IBGE.
   - `05b_export_formato_sp.R` — ✅ export formato DataStudio de SP (camada de apresentação): `formato_sp/{contexto_dados,dinamica_criminal,dados_saude}.csv`.
   - `06_auditoria.R` — ✅ auditoria consolidada → `RELATORIO_AUDITORIA.md` + `qualidade_paineis.csv`.
   - `07_validacao_prisional.R` — ✅ validação prisional (cobertura, óbitos anuais, paridade de nomes, consistências) → `validacao_prisional.md`.

## Fluxo de trabalho atual
Os scripts R rodam no ambiente do **pesquisador**; o assistente valida a lógica
(espelho em Python) e inspeciona os arquivos de saída/auditoria a cada etapa.

## Status
| Etapa | Estado |
|---|---|
| 00_config, R/funcoes_criminal | ✅ |
| 01a_download_ssp_rs | ✅ confirmado no run |
| 01_download (nacionais) | ✅ pop/PIB/distorção; **região intermediária via API — re-rodar** |
| 01b_download_sisdepen (Base Única) | ✅ confirmado no run (md5 + 104/103/104/103) |
| 02_criminal | ✅ validado (2022–2025; 2022 furtos sinalizado) |
| 02b_atividade (prisões flagrante) | ✅ confirmado no run |
| 03_prisional | ✅ confirmado no run (esquema 444; 104/103/104/103) |
| 03b_prisional_derivadas | ✅ confirmado no run (derivadas; óbitos anuais; funde o 03c) |
| 04_contexto | ✅ confirmado no run (497/8; munic_ep=77) |
| 04b_saude (TABNET) | ✅ confirmado no run (6 indicadores; NA p/ provisório) |
| 05_planilha_final | ✅ confirmado no run (painéis criminal/prisional/contexto/saúde) |
| 05b_export_formato_sp | ✅ confirmado no run (contexto/criminal/saúde no formato SP) |
| 06_auditoria | ✅ escrito (rodar para gerar o relatório) |
| 07_validacao_prisional | ✅ confirmado no run (tudo OK após correções) |
| 01c_datasus | ✅ escrito (alternativa opcional à mortalidade via TABNET) |
