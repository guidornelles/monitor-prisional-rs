# Executar da raiz do projeto: Rscript --vanilla scripts/tests/test_mapa_prisional.R
# Testes do contrato do mapa; não escrevem dados, configuração ou auditorias.
source(file.path("R", "funcoes_mapa_prisional.R"))

falha <- function(expr, trecho) {
  erro <- tryCatch({ force(expr); NULL }, error = identity)
  stopifnot(inherits(erro, "error"), grepl(trecho, conditionMessage(erro), fixed = TRUE))
}
estoque <- function(ate) {
  d <- expand.grid(ID = c("10", "20"), ano = seq.int(2023L, ate),
                   stringsAsFactors = FALSE)
  d[["Referência"]] <- paste0(d$ano, "/1")
  d$nome <- paste("Unidade", d$ID)
  d$quantidade <- seq_len(nrow(d)) + 0.5
  d$informada <- rep(c(TRUE, FALSE), length.out = nrow(d))
  d$data <- as.Date("2020-01-01") + seq_len(nrow(d))
  d$categoria <- factor(rep(c("a", "b"), length.out = nrow(d)))
  d
}
auditoria_valida <- function(painel, anos, fonte) {
  r <- auditar_mapa_ultimo_ano_validado(painel, anos, fonte)
  stopifnot(all(r$checagens))
  r
}
auditoria_invalida <- function(painel, anos, fonte, nome) {
  r <- auditar_mapa_ultimo_ano_validado(painel, anos, fonte)
  stopifnot(!r$checagens[[nome]])
}

# O mesmo contrato acompanha a ampliação da janela, sem data do PC ou semestre 2.
for (ate in 2024:2026) {
  original <- estoque(ate)
  anos <- seq.int(2023L, ate)
  marcado <- adicionar_mapa_ultimo_ano_validado(original, anos)
  stopifnot(identical(names(marcado), c(names(original), "mapa_ultimo_ano_validado")),
            all(vapply(names(original), function(k) identical(original[[k]], marcado[[k]]), logical(1))),
            identical(marcado$mapa_ultimo_ano_validado, original$ano == ate))
  r <- auditoria_valida(marcado, anos, original)
  stopifnot(r$ano == ate, r$estabelecimentos == 2L)
}

original <- estoque(2025L)
anos <- 2023:2025
marcado <- adicionar_mapa_ultimo_ano_validado(original, anos)
falha(adicionar_mapa_ultimo_ano_validado(original[original$ano != 2025L, ], anos), "ano ausente ou extra")
falha(adicionar_mapa_ultimo_ano_validado(original[original$ano != 2024L, ], anos), "ano ausente ou extra")
falha(adicionar_mapa_ultimo_ano_validado(original, 2023:2024), "ano ausente ou extra")
falha(adicionar_mapa_ultimo_ano_validado(original, c(2023, NA)), "Janela prisional inválida")
falha(adicionar_mapa_ultimo_ano_validado(marcado, anos), "já existe")
sem2 <- original
sem2[["Referência"]][1] <- "2023/2"
falha(adicionar_mapa_ultimo_ano_validado(sem2, anos), "primeiro semestre")

# Mantém a contagem e os IDs, mas desloca TRUE para o ano errado: deve ser detectado.
alterado <- marcado
alterado$mapa_ultimo_ano_validado <- alterado$ano == 2024L
auditoria_invalida(alterado, anos, original, "Mapa marca exclusivamente o maior ano da janela configurada")
alterado <- marcado
alterado$mapa_ultimo_ano_validado[which(alterado$mapa_ultimo_ano_validado)[1]] <- FALSE
auditoria_invalida(alterado, anos, original, "Contagem do mapa coincide com o estoque independente do último ano")
alterado <- marcado
alterado$mapa_ultimo_ano_validado <- as.integer(alterado$mapa_ultimo_ano_validado)
auditoria_invalida(alterado, anos, original, "Marcador do mapa lógico e sem valores ausentes")
alterado <- marcado
alterado$mapa_ultimo_ano_validado[1] <- NA
auditoria_invalida(alterado, anos, original, "Marcador do mapa lógico e sem valores ausentes")
alterado <- marcado[names(original)]
auditoria_invalida(alterado, anos, original, "Marcador do mapa presente como última coluna")
alterado <- marcado[c("mapa_ultimo_ano_validado", names(original))]
auditoria_invalida(alterado, anos, original, "Marcador do mapa presente como última coluna")
fonte_alterada <- original
fonte_alterada$ID[fonte_alterada$ano == 2025L & fonte_alterada$ID == "20"] <- "30"
auditoria_invalida(marcado, anos, fonte_alterada, "IDs do mapa coincidem com o estoque independente do primeiro semestre")

# Só dois ciclos de um ano posterior geram aviso; não ampliam o marcador.
stopifnot(is.null(alerta_ano_mapa_prisional(c("2025/1", "2025/2", "2026/1"), anos)),
          grepl("2026", alerta_ano_mapa_prisional(c("2026/1", "2026/2"), anos)),
          identical(marcado$mapa_ultimo_ano_validado, original$ano == 2025L))

# Contrato real já validado: 551 colunas existentes preservadas, mais uma lógica.
arq <- file.path("outputs", "temp", "revisao_pipeline_2026-11-20", "tabelas",
                 "painel_prisional_estabelecimento.csv")
if (file.exists(arq) && requireNamespace("readr", quietly = TRUE)) {
  real <- readr::read_csv(arq, show_col_types = FALSE)
  stopifnot(ncol(real) == 551L)
  novo <- adicionar_mapa_ultimo_ano_validado(real, 2017:2025)
  stopifnot(ncol(novo) == 552L, sum(novo$mapa_ultimo_ano_validado) == 103L,
            all(vapply(names(real), function(k) identical(real[[k]], novo[[k]]), logical(1))))
  auditoria_valida(novo, 2017:2025, real)
  message("Contrato real: 927 linhas; 551 colunas preservadas; 103 TRUE em 2025/1.")
}
message("Testes do mapa: janelas 2024/2025/2026, lacunas e adulterações detectadas (OK).")
