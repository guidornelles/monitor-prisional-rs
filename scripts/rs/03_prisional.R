# =============================================================================
# 03_prisional.R — Camada prisional (SISDEPEN-RS), no padrão do Monitor SP
# -----------------------------------------------------------------------------
# Constrói a base prisional do RS espelhando a estrutura do Base_Sisdepen de SP
# (mesmas colunas SISDEPEN ⇒ mesmos nomes de variável ⇒ Looker reaproveitável).
#
# FONTE: Base Única consolidada da SENAPPEN (cfg$escolhas$sisdepen_fonte="base_unica").
#   Por que a Base Única (e não os arquivos por ciclo, como SP fez):
#   - "Tipo de Recolhimento" (cela física / domiciliar) vem 100% preenchido em
#     TODOS os anos (2016–2025). Nos arquivos por ciclo, esse campo só existe a
#     partir de 2024 — o que obrigava a uma aproximação em 2022–2023. A Base Única
#     elimina a aproximação: recorte cela física nativo e exato em toda a série.
#   - Traz `ID` de estabelecimento ESTÁVEL entre ciclos (protege contra mudança de
#     nomenclatura) e `ciclo`/`Ano`/`Referência` (empilhamento longitudinal embutido).
#   - Esquema único (1.782 colunas) — sem a heterogeneidade entre ciclos.
#   Aquisição: download MANUAL do SharePoint da SENAPPEN -> data/raw/sisdepen/
#   (ver 00_config.R::arquivo_baseunica e docs/decisoes_metodologicas.md).
#
# RECORTE (cfg$escolhas$prisional_recorte = "cela_fisica"):
#   - UF == "RS"
#   - Tipo de Recolhimento == "Cela física"  (exclui domiciliar / monitoração eletrônica)
#   - + salvaguarda por NOME: exclui registros tipados "cela física" mas nomeados como
#     domiciliar/monitoração (corrige o erro de SP: estabelecimentos triplicados em 2021
#     — cela física + domiciliar + domiciliar c/ monit. eletrônica — inflando contagens).
#   - Semestre = cfg$escolhas$prisional_semestre (1 = perfil/capacidade/estrutura, como SP).
#
# Entrada : data/raw/sisdepen/*baseunica*.xlsx   (Base Única, manual)
#           data/raw/sp_schema_prisional.csv     (377 colunas-alvo do Base_Sisdepen de SP)
# Saída   : data/processed/prisional_rs.csv
# Auditoria: outputs/auditoria/prisional_cobertura.csv (estab. por ano × recorte)
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

schema <- readr::read_csv(here::here("data/raw/sp_schema_prisional.csv"), show_col_types = FALSE)$variavel
norm_txt <- function(x) stringi::stri_trans_general(stringr::str_squish(stringr::str_to_lower(x)), "Latin-ASCII")

# Identidade da Base Única que preservamos além do esquema de SP (rastreabilidade longitudinal)
COLS_ID <- c("ID", "ciclo", "Referência")

# ---- Recorte de estabelecimentos ---------------------------------------------
aplicar_recorte <- function(df) {
  if (identical(cfg$escolhas$prisional_recorte, "todos")) return(df)
  nome_norm <- norm_txt(df[["Nome do Estabelecimento"]])
  df |>
    dplyr::filter(
      norm_txt(.data[["Tipo de Recolhimento"]]) == "cela fisica",
      !stringr::str_detect(nome_norm, "domiciliar|monitoramento eletronico|monitoracao eletronica")
    )
}

# ---- Leitura da Base Única ---------------------------------------------------
ler_base_unica <- function() {
  arq <- arquivo_baseunica()
  message("Base Única: ", basename(arq))
  # suppressWarnings: o readxl adivinha algumas colunas Sim/Não como lógicas (vazias nos
  # ~15k primeiros registros nacionais, texto depois) e emite "Expecting logical ... got
  # 'Sim'/'Não'". São avisos benignos: filtramos UF==RS + 1º sem e selecionamos o esquema
  # adiante; não afetam os números (a auditoria confere 104/103/104/103).
  df <- suppressWarnings(readxl::read_excel(arq, sheet = 1, guess_max = 10000))

  # filtra UF + semestre alvo (via Referência "AAAA/S") + anos da PoC
  sem <- cfg$escolhas$prisional_semestre
  ref_alvo <- paste0(cfg$anos, "/", sem)            # ex.: 2022/1, 2023/1, ...
  df <- df |>
    dplyr::mutate(UF = toupper(.data[["UF"]]),
                  ref = as.character(.data[["Referência"]])) |>
    dplyr::filter(UF == cfg$uf, ref %in% ref_alvo)

  df <- aplicar_recorte(df)

  # ano a partir da Referência; zera NA numérico (como SP); id no padrão de SP
  df <- df |>
    dplyr::mutate(
      ano = as.integer(stringr::str_extract(ref, "^\\d{4}")),
      periodo = as.character(ano),
      id = paste(`Nome do Estabelecimento`, UF, ano, sep = "-"),
      dplyr::across(where(is.numeric), ~ ifelse(is.na(.), 0, .))
    )
  df
}

base <- ler_base_unica()

# ---- Espelhamento do esquema de SP + identidade da Base Única ----------------
presentes <- intersect(schema, names(base))
id_presentes <- intersect(c(COLS_ID, "ano", "periodo", "id"), names(base))
prisional <- dplyr::select(base, dplyr::all_of(unique(c(id_presentes, presentes))))
readr::write_csv(prisional, file.path(paths$processed, "prisional_rs.csv"))

# ---- Auditoria: cobertura por ano --------------------------------------------
auditoria <- base |>
  dplyr::count(ano, name = "estab_recorte") |>
  dplyr::mutate(recorte = cfg$escolhas$prisional_recorte,
                fonte = cfg$escolhas$sisdepen_fonte,
                cols_match = length(presentes),
                cols_schema = length(schema))
readr::write_csv(auditoria, file.path(paths$out_aud, "prisional_cobertura.csv"))

message("OK — prisional_rs.csv (", nrow(prisional), " linhas, ", ncol(prisional),
        " colunas; ", length(presentes), "/", length(schema), " do esquema SP) e auditoria gravados.")
print(auditoria)

# NOTAS:
# - As ~65 colunas do esquema de SP ausentes aqui são variáveis DERIVADAS por SP
#   (provisorios_*, sentenciado_*, obitos_*, faixas de pena), computadas em depen.R
#   a partir das colunas brutas do SISDEPEN. Replicá-las é passo posterior (transform
#   estilo depen.R) — a base bruta (312/377) já é o alicerce.
# - Mortalidade (seção 6.8) usa o 2º semestre: rodar com cfg$escolhas$prisional_semestre = 2L.
