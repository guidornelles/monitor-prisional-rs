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
#           data/raw/sp_schema_prisional.csv     (444 colunas; regenerado do header da base do DataStudio ∩ Base Única)
# Saída   : data/processed/prisional_rs.csv
# Auditoria: outputs/auditoria/prisional_cobertura.csv (estab. por ano × recorte)
# =============================================================================

source(here::here("scripts/rs/00_config.R"))

schema <- readr::read_csv(here::here("data/raw/sp_schema_prisional.csv"), show_col_types = FALSE)$variavel
norm_txt <- function(x) stringi::stri_trans_general(stringr::str_squish(stringr::str_to_lower(x)), "Latin-ASCII")

# Identidade da Base Única que preservamos além do esquema de SP (rastreabilidade longitudinal)
COLS_ID <- c("ID", "ciclo", "Referência")

# Colunas ALÉM do esquema que queremos capturar. Vazio porque o sp_schema_prisional.csv foi
# REGENERADO (2026-06) a partir do que SP de fato mantém (header da base do DataStudio ∩ Base
# Única): 444 colunas, incluindo as seções antes faltantes (6.1–6.7, 7.3/7.5, 2.14–2.18, 5.5).
# Mantido como mecanismo para adições futuras pontuais (colunas que SP não mantenha e queiramos).
COLS_EXTRA <- character(0)

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

  # 2.13 "cela(s)-seguro": a Base Única traz a coluna ORIGINAL (com o dado Sim/Não) e uma
  # VARIANTE de aspas trocadas que vem VAZIA (artefato da consolidação). O sp_schema espera
  # a variante (SP renomeia a original p/ ela em depen.R). Replicamos: descartamos a variante
  # vazia e renomeamos a original para o nome do schema, levando o dado adiante.
  c213_orig <- '2.13 Há "cela(s)-seguro"?'
  c213_var  <- '2.13 Há cela(s)-seguro"?"'
  if (c213_orig %in% names(df)) {
    if (c213_var %in% names(df)) df[[c213_var]] <- NULL
    names(df)[names(df) == c213_orig] <- c213_var
  }
  df
}

base <- ler_base_unica()

# ---- Espelhamento do esquema de SP + identidade da Base Única ----------------
presentes <- intersect(schema, names(base))
id_presentes <- intersect(c(COLS_ID, "ano", "periodo", "id"), names(base))
extra_presentes <- intersect(COLS_EXTRA, names(base))   # colunas fora do schema que queremos (ex.: 2.16)
prisional <- dplyr::select(base, dplyr::all_of(unique(c(id_presentes, presentes, extra_presentes))))

# ---- Endereço pronto para o mapa (espelha o depen.R de SP) --------------------
# SP anexa " - <estado>, <país>" ao Endereço para o gráfico de localização ancorar
# no estado/país certos. No RS os endereços vêm só com a rua -> no Google Maps vários
# caíam FORA do RS (ruas homônimas entre estados). Anexamos município + RS + Brasil.
# GUARDA: não duplica o município se ele já aparecer na linha de endereço.
estado_extenso <- "Rio Grande do Sul"; pais <- "Brasil"
if (all(c("Endereço", "Município") %in% names(prisional))) {
  end <- prisional[["Endereço"]]; mun <- prisional[["Município"]]
  end_squish <- stringr::str_squish(tidyr::replace_na(as.character(end), ""))
  end_norm   <- norm_txt(end_squish); mun_norm <- norm_txt(as.character(mun))
  tem_mun  <- nzchar(mun_norm) & stringr::str_detect(end_norm, stringr::fixed(mun_norm))
  end_vazio <- !nzchar(end_squish)
  prisional[["Endereço"]] <- dplyr::case_when(
    end_vazio ~ paste0(mun, " - ", estado_extenso, ", ", pais),
    tem_mun   ~ paste0(end_squish, " - ", estado_extenso, ", ", pais),
    TRUE      ~ paste0(end_squish, ", ", mun, " - ", estado_extenso, ", ", pais))
  message("  Endereço ajustado p/ geolocalização (município + ", estado_extenso, " + ", pais, ").")
}

# ---- ano_inauguracao: ano do "1.6 Data de inauguração..." (p/ filtro do mapa) -
# SP filtra o Mapa de Estabelecimentos pelo ano de inauguração. O campo bruto é texto
# dd/mm/aaaa (e em SP vem com formatos inconsistentes); extraímos um ANO inteiro robusto
# (\\b(19|20)\\d{2}\\b) para o filtro não depender do Looker interpretar texto-data.
col_inaug <- intersect("1.6 Data de inauguração do estabelecimento", names(prisional))[1]
if (!is.na(col_inaug)) {
  prisional$ano_inauguracao <- suppressWarnings(as.integer(stringr::str_extract(
    as.character(prisional[[col_inaug]]), "\\b(19|20)\\d{2}\\b")))
  message("  ano_inauguracao derivado (", sum(!is.na(prisional$ano_inauguracao)), "/",
          nrow(prisional), " com ano).")
}

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
# - Schema REGENERADO (2026-06): o sp_schema_prisional.csv antigo (377) era um recorte
#   incompleto que deixava seções inteiras de fora (6.1–6.7, 7.3/7.5, 2.14–2.18, 5.5).
#   O novo (444) = colunas que SP de fato mantém (header da base do DataStudio) ∩ Base Única,
#   então praticamente TODAS casam (length(presentes) ≈ length(schema)). As variáveis DERIVADAS
#   por SP (provisorios_*, obitos_*, faixas de pena, continentes, atendimento…) NÃO entram no
#   schema — são computadas no 03b a partir das brutas (porta depen.R + dados_sem2.R).
# - Mortalidade (6.8) é ANUAL (1º + 2º sem), computada no 03b (não mais só 2º sem).
#   O 03 produz o 1º semestre (perfil/capacidade); o 03b lê os dois semestres.
