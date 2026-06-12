# =============================================================================
# R/funcoes_criminal.R — Funções da camada criminal (microdado -> indicadores)
# -----------------------------------------------------------------------------
# Regras de classificação VALIDADAS na prova de conceito (ver docs/poc_reconciliacao.md):
# reproduzem as tabelas oficiais de Indicadores Criminais dentro de ±0,4% (2023 e 2024).
#
# Princípio de reprodutibilidade: funções puras, sem estado global; cada uma
# recebe e devolve data frames. Nenhum acoplamento por objeto em memória entre
# scripts (problema do Monitor SP).
# =============================================================================

# Normaliza nome de município: maiúsculas, sem acento, espaços colapsados.
normalizar_municipio <- function(x) {
  x |>
    stringr::str_to_upper() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_squish()
}

# Linhas que NÃO são município (totais/agregados/rodapés) — para excluir de somas.
# Inclui "TOTAL RS" e "GERAL" (linhas-agregado que contaminaram análises iniciais).
eh_nao_municipio <- function(x) {
  x %in% c("", "TOTAL", "TOTAL RS", "RIO GRANDE DO SUL", "RS", "GERAL") |
    stringr::str_starts(x, "FONTE") |
    stringr::str_starts(x, "NOTA") |
    stringr::str_starts(x, "OBS")
}

# Classifica cada ocorrência (Tipo Enquadramento normalizado) numa categoria do Monitor.
# Regras (validadas): veículo é contabilizado À PARTE; latrocínio = roubos "com morte";
# "OUTROS ROUBOS"/"OUTROS FURTOS" entram nos totais gerais (por isso usa-se str_detect).
classificar_enquadramento <- function(enq_norm) {
  is_roubo <- stringr::str_detect(enq_norm, "ROUBO")
  is_furto <- stringr::str_detect(enq_norm, "FURTO")
  is_morte <- stringr::str_detect(enq_norm, "COM MORTE")
  roubo_veic <- enq_norm %in% c("ROUBO DE VEICULO", "ROUBO DE VEICULO COM LESOES")
  furto_veic <- enq_norm %in% c("FURTO DE VEICULO", "FURTO VEICULO AUTOMOTOR TRANSPORTE OUTRO ESTADO")

  dplyr::case_when(
    enq_norm == "HOMICIDIO DOLOSO"                      ~ "homicidio_doloso",
    enq_norm %in% c("ESTUPRO", "ESTUPRO DE VULNERAVEL") ~ "estupro",
    is_roubo & is_morte                                  ~ "latrocinio",
    roubo_veic & !is_morte                               ~ "roubo_veiculo",
    is_roubo & !roubo_veic & !is_morte                   ~ "roubos",          # = "roubo outros" do RS
    furto_veic                                           ~ "furto_veiculo",
    is_furto & !furto_veic                               ~ "furtos",          # = "furto outros" do RS
    TRUE                                                 ~ "outro"
  )
}

# Lê um microdado anual (CSV ';' latin-1), seleciona colunas necessárias,
# filtra fato consumado e classifica. Devolve uma linha por ocorrência consumada.
ler_microdado <- function(caminho_csv, consumado_apenas = TRUE) {
  m <- readr::read_delim(
    caminho_csv, delim = ";", locale = readr::locale(encoding = "latin1"),
    col_select = c("Tipo Enquadramento", "Tipo Fato", "Municipio Fato",
                   "Quantidade Vítimas", "Sexo Vítima"),
    col_types = readr::cols(.default = "c"), progress = FALSE
  ) |>
    dplyr::rename(enq = `Tipo Enquadramento`, tipo_fato = `Tipo Fato`,
                  municipio = `Municipio Fato`, qtd_vitimas = `Quantidade Vítimas`,
                  sexo_vitima = `Sexo Vítima`)
  if (consumado_apenas) {
    m <- dplyr::filter(m, stringr::str_to_lower(stringr::str_trim(tipo_fato)) == "consumado")
  }
  m |>
    dplyr::mutate(
      enq_norm  = normalizar_municipio(enq),       # mesma normalização serve p/ enquadramento
      municipio = normalizar_municipio(municipio),
      qtd_vitimas = dplyr::coalesce(suppressWarnings(as.integer(qtd_vitimas)), 0L),
      classe = classificar_enquadramento(enq_norm)
    )
}

# Subtipos a excluir do "outros" ESTRITO (padrão SP): banco, comércio, carga, transporte.
# (A composição exata do "outros" de SP é um ponto a confirmar com a equipe SP.)
PADRAO_EXCLUIR_OUTROS <-
  "BANCARIO|ESTABELECIMENTO COMERCIAL|MINIMERCADO|ARMAZEM|JOALHERIA|OTICA|CARGA|MALOTE|CASA LOTERICA|POSTO BANCARIO|TRANSPORTE COLETIVO|LOTACAO"

# Município válido (descarta rodapés/agregados/grafias-lixo da tabela oficial).
municipio_valido <- function(x) {
  !eh_nao_municipio(x) & stringr::str_detect(x, "[A-Z]") &
    !stringr::str_detect(x, "\\*") & stringr::str_length(x) <= 40 & !stringr::str_starts(x, "-")
}

# Agrega o microdado por município x ano. Emite DOIS níveis para roubo/furto:
#  - *_total  : todos (exceto veículo/latrocínio) — reconcilia com a coluna oficial "Roubos"/"Furtos" (AUDITORIA)
#  - *_outros : padrão ESTRITO de SP (exclui banco/comércio/carga) — INDICADOR ENTREGÁVEL
agregar_criminal <- function(micro, ano) {
  micro |>
    dplyr::filter(municipio_valido(municipio)) |>
    dplyr::mutate(
      excl  = stringr::str_detect(enq_norm, PADRAO_EXCLUIR_OUTROS),
      abig  = stringr::str_detect(enq_norm, "ABIGEATO")
    ) |>
    dplyr::group_by(municipio) |>
    dplyr::summarise(
      ano              = ano,
      hd_ocorrencias   = sum(classe == "homicidio_doloso"),
      hd_vitimas_micro = sum(qtd_vitimas[classe == "homicidio_doloso"]),
      tot_estupro      = sum(classe == "estupro"),
      roubos_total     = sum(classe == "roubos"),
      roubo_outros     = sum(classe == "roubos" & !excl),
      furtos_total     = sum(classe == "furtos"),
      furto_outros     = sum(classe == "furtos" & !excl & !abig),
      .groups = "drop"
    )
}
