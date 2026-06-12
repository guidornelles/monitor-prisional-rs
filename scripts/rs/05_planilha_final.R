# =============================================================================
# 05_planilha_final.R — Montagem das tabelas finais (padrão Looker do Monitor SP)
# -----------------------------------------------------------------------------
# Junta as três camadas com os MESMOS nomes de variável de SP e adiciona chave
# (id_municipio), recorte regional (nome_regiao_intermediaria) e TAXAS por 100 mil.
# Espelha o modelo de SP (fontes separadas blendadas no Looker pela chave municipal):
#
#   1) painel_criminal_municipio_ano.csv  — grão MUNICÍPIO × ANO
#        nomes de SP: hd_vitima, tot_estupro, roubo_outros, furto_outros, prisoes
#        + hd_ocorrencias (extra RS) + contexto (populacao, pib, distorcao) + *_taxa_100k
#   2) painel_prisional_estabelecimento.csv — grão ESTABELECIMENTO × ANO (camada SISDEPEN)
#        prisional_rs enriquecido com nome_regiao_intermediaria (via Código IBGE)
#   3) painel_contexto_municipio.csv — denominadores/panoramas (cópia de contexto)
#
# Chave municipal robusta: nome normalizado (maiúsculas, sem acento, sem pontuação)
# -> id_municipio, a partir do universo IBGE (contexto). Nomes da SSP que não casam
# são reportados em outputs/auditoria/match_municipios.csv (para não perder município real).
#
# Entradas: data/processed/{criminal_rs_municipio_ano, prisoes_rs_municipio_ano,
#           contexto_rs_municipio, prisional_rs}.csv
# Saídas  : outputs/tabelas/painel_*.csv  + auditoria
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

# Normalização para casar nomes de município entre fontes (SSP x IBGE):
# maiúsculas, sem acento; apóstrofo é DELETADO ("Sant'Ana"->SANTANA) e demais sinais
# (hífen etc.) viram espaço ("Entre-Ijuís"/"Xangri-lá"/"Não-Me-Toque" <-> grafia da SSP).
norm_join <- function(x) {
  x |> stringr::str_to_upper() |> stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_replace_all("['’`]", "") |>
    stringr::str_replace_all("[^A-Z0-9]", " ") |> stringr::str_squish()
}

# Aliases SSP -> IBGE: divergências de grafia e ERROS DE DIGITAÇÃO na fonte da SSP
# (ex.: "Aceguaá"=Aceguá, "São Josedo Ouro"=São José do Ouro, "Estância Velhas"=Estância Velha,
# "DR"=Doutor). Mapa explícito e auditável (preferível a fuzzy às cegas). Chaves em forma norm_join.
# Validado: reduz os não-pareados a ~13 registros, todos de OUTRAS UFs (descartados corretamente).
aliases_municipio <- c(
  "DR MAURICIO CARDOSO"      = "DOUTOR MAURICIO CARDOSO",
  "FAZENDA VILA NOVA"        = "FAZENDA VILANOVA",
  "PINTO BANDEIRA BENTO GONC"= "PINTO BANDEIRA",
  "ESTANCIA VELHAS"          = "ESTANCIA VELHA",
  "XANGRI LAA"               = "XANGRI LA",
  "ACEGUAA"                  = "ACEGUA",
  "ARARICAA"                 = "ARARICA",
  "CAMBARAA DO SUL"          = "CAMBARA DO SUL",
  "IBIACAA"                  = "IBIACA",
  "PICADA CAFU"              = "PICADA CAFE",
  "SAO JOSEDO OURO"          = "SAO JOSE DO OURO",
  "SAO JOSEDO SUL"           = "SAO JOSE DO SUL",
  "SAO JOSEDO HERVAL"        = "SAO JOSE DO HERVAL",
  "SAO JOSEDOS AUSENTES"     = "SAO JOSE DOS AUSENTES",
  "SAO JOSEDO INHACORA"      = "SAO JOSE DO INHACORA"
)
# chave municipal final (normaliza + aplica alias quando houver)
chave_municipio <- function(x) {
  k <- norm_join(x)
  ifelse(k %in% names(aliases_municipio), unname(aliases_municipio[k]), k)
}

# ---- Leitura das camadas -----------------------------------------------------
contexto  <- readr::read_csv(file.path(paths$processed, "contexto_rs_municipio.csv"), show_col_types = FALSE)
criminal  <- readr::read_csv(file.path(paths$processed, "criminal_rs_municipio_ano.csv"), show_col_types = FALSE)
prisoes   <- readr::read_csv(file.path(paths$processed, "prisoes_rs_municipio_ano.csv"), show_col_types = FALSE)

contexto  <- dplyr::mutate(contexto, chave = norm_join(nome))

# ---- Auditoria de pareamento de nomes (antes de juntar) ----------------------
chaves_ibge <- unique(contexto$chave)
nao_pareados <- dplyr::bind_rows(
  criminal |> dplyr::transmute(fonte = "criminal", nom_mun, chave = chave_municipio(nom_mun)),
  prisoes  |> dplyr::transmute(fonte = "prisoes",  nom_mun, chave = chave_municipio(nom_mun))
) |>
  dplyr::filter(stringr::str_to_upper(nom_mun) != "NAN", !is.na(nom_mun)) |>
  dplyr::filter(!chave %in% chaves_ibge) |>
  dplyr::distinct(fonte, nom_mun, chave) |>
  dplyr::arrange(fonte, nom_mun)
readr::write_csv(nao_pareados, file.path(paths$out_aud, "match_municipios.csv"))
if (nrow(nao_pareados))
  message("⚠ ", nrow(nao_pareados), " nome(s) de município sem correspondência no IBGE ",
          "(ver outputs/auditoria/match_municipios.csv) — provavelmente outras UFs/variantes.")

# ---- 1) Painel criminal município × ano --------------------------------------
# agrega por (chave, ano): aliases podem colapsar dois nomes-fonte na mesma chave -> evita duplicar no join
crim <- criminal |>
  dplyr::mutate(chave = chave_municipio(nom_mun)) |>
  dplyr::group_by(chave, ano) |>
  dplyr::summarise(dplyr::across(c(hd_vitima, hd_ocorrencias, tot_estupro, roubo_outros, furto_outros),
                                 ~ sum(.x, na.rm = TRUE)), .groups = "drop")
pris <- prisoes |>
  dplyr::mutate(chave = chave_municipio(nom_mun)) |>
  dplyr::group_by(chave, ano) |>
  dplyr::summarise(prisoes = sum(prisoes, na.rm = TRUE), .groups = "drop")

# grade completa município (IBGE) × ano -> ausência de registro = 0 ocorrências
grade <- tidyr::expand_grid(id_municipio = contexto$id_municipio, ano = cfg$anos) |>
  dplyr::left_join(dplyr::select(contexto, id_municipio, nom_mun = nome,
                                 nome_regiao_intermediaria, chave, populacao, pib,
                                 distorcao_idade_serie_fund), by = "id_municipio")

vars_cont <- c("hd_vitima","hd_ocorrencias","tot_estupro","roubo_outros","furto_outros","prisoes")
painel_criminal <- grade |>
  dplyr::left_join(crim, by = c("chave","ano")) |>
  dplyr::left_join(pris, by = c("chave","ano")) |>
  dplyr::mutate(dplyr::across(dplyr::all_of(vars_cont), ~ tidyr::replace_na(., 0))) |>
  # taxas por 100 mil habitantes (denominador: população Censo 2022)
  dplyr::mutate(dplyr::across(dplyr::all_of(vars_cont),
                              ~ ifelse(populacao > 0, .x / populacao * 1e5, NA_real_),
                              .names = "{.col}_taxa_100k")) |>
  dplyr::select(id_municipio, nom_mun, nome_regiao_intermediaria, ano,
                dplyr::all_of(vars_cont), populacao, pib, distorcao_idade_serie_fund,
                dplyr::ends_with("_taxa_100k")) |>
  dplyr::arrange(nom_mun, ano)
readr::write_csv(painel_criminal, file.path(paths$out_tab, "painel_criminal_municipio_ano.csv"))

# ---- 2) Painel prisional estabelecimento × ano (enriquecido) -----------------
prisional <- readr::read_csv(file.path(paths$processed, "prisional_rs.csv"), show_col_types = FALSE)
col_ibge <- intersect(c("Código IBGE","Codigo IBGE","cod_ibge"), names(prisional))[1]
painel_prisional <- prisional
if (!is.na(col_ibge)) {
  painel_prisional <- prisional |>
    dplyr::mutate(id_municipio = as.integer(.data[[col_ibge]])) |>
    dplyr::left_join(dplyr::select(contexto, id_municipio, nome_regiao_intermediaria),
                     by = "id_municipio")
}
# junta as DERIVADAS (03b, 1º sem) e a MORTALIDADE (03c, 2º sem) por id, se existirem
arq_der <- file.path(paths$processed, "prisional_derivadas_rs.csv")
if (file.exists(arq_der)) {
  der <- readr::read_csv(arq_der, show_col_types = FALSE) |> dplyr::select(-dplyr::any_of("periodo"))
  painel_prisional <- dplyr::left_join(painel_prisional, der, by = "id")
  message("  + ", ncol(der)-1, " colunas derivadas juntadas ao painel prisional.")
}
arq_mort <- file.path(paths$processed, "prisional_mortalidade_rs.csv")
if (file.exists(arq_mort)) {
  mort <- readr::read_csv(arq_mort, show_col_types = FALSE) |> dplyr::select(-dplyr::any_of("periodo"))
  painel_prisional <- dplyr::left_join(painel_prisional, mort, by = "id")
  message("  + mortalidade (2º sem) juntada ao painel prisional.")
}
readr::write_csv(painel_prisional, file.path(paths$out_tab, "painel_prisional_estabelecimento.csv"))

# ---- 3) Painel de contexto (denominadores/panoramas) -------------------------
readr::write_csv(dplyr::select(contexto, -chave),
                 file.path(paths$out_tab, "painel_contexto_municipio.csv"))

# ---- 4) Painel de saúde município × ano (se 04b/01c já gerou) -----------------
# Período próprio (ex.: 2018–2025, como SP) — não restrito a cfg$anos. Junta por código
# IBGE de 6 dígitos (TABNET/SIM) -> id_municipio (7 díg.). Taxas por 100 mil (pop. Censo 2022).
arq_saude <- file.path(paths$processed, "saude_rs_municipio_ano.csv")
if (file.exists(arq_saude)) {
  saude <- readr::read_csv(arq_saude, show_col_types = FALSE) |>
    dplyr::mutate(cod_mun6 = as.character(cod_mun6))
  ind_saude <- setdiff(names(saude), c("cod_mun6", "ano"))
  ctx6 <- contexto |>
    dplyr::mutate(cod_mun6 = substr(as.character(id_municipio), 1, 6)) |>
    dplyr::select(cod_mun6, id_municipio, nom_mun = nome, nome_regiao_intermediaria, populacao)
  # NÃO zera NA: ano sem dado para o indicador permanece NA (não disponível ≠ zero real).
  painel_saude <- ctx6 |>
    dplyr::left_join(saude, by = "cod_mun6") |>
    dplyr::mutate(dplyr::across(dplyr::all_of(ind_saude),
                                ~ ifelse(!is.na(.x) & populacao > 0, .x / populacao * 1e5, NA_real_),
                                .names = "{.col}_taxa_100k")) |>
    dplyr::filter(!is.na(ano)) |>
    dplyr::arrange(nom_mun, ano)
  readr::write_csv(painel_saude, file.path(paths$out_tab, "painel_saude_municipio_ano.csv"))
  message("painel_saude_municipio_ano.csv gravado (", nrow(painel_saude), " linhas; indicadores: ",
          paste(ind_saude, collapse = ", "), ").")
} else {
  message("(saúde) ", basename(arq_saude), " ainda não existe — rode 04b_saude.R após exportar o TABNET.")
}

# ---- Auditoria final ---------------------------------------------------------
auditoria <- tibble::tibble(
  tabela = c("painel_criminal_municipio_ano","painel_prisional_estabelecimento","painel_contexto_municipio"),
  linhas = c(nrow(painel_criminal), nrow(painel_prisional), nrow(contexto)),
  municipios = c(dplyr::n_distinct(painel_criminal$id_municipio), NA, nrow(contexto)),
  nomes_sem_match = c(nrow(nao_pareados), NA, NA)
)
readr::write_csv(auditoria, file.path(paths$out_aud, "planilha_final_cobertura.csv"))

message("OK — painéis finais gravados em outputs/tabelas/ (criminal, prisional, contexto).")
print(auditoria)
