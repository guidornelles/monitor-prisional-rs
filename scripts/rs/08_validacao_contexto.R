# Valida fontes -> contexto -> exportações e numerador/denominador das taxas.
# Nenhuma fonte é alterada. Diferenças interrompem o orquestrador.
source(here::here("scripts/rs/00_config.R"))
source(here::here("R/funcoes_contexto.R"))

linhas <- c("# Validação do contexto e das taxas", "",
             "Referências: Censo 2022; PIB municipal em mil reais correntes; Inep Total/Total.", "")
falhas <- character()
confere <- function(rotulo, condicao) {
  ok <- length(condicao) == 1L && !is.na(condicao) && isTRUE(condicao)
  linhas <<- c(linhas, paste0("- ", if (ok) "OK" else "FALHA", " — ", rotulo))
  if (!ok) falhas <<- c(falhas, rotulo)
  invisible(ok)
}
iguais <- function(a, b, tolerancia = 1e-8) {
  a <- as.numeric(a); b <- as.numeric(b)
  length(a) == length(b) && identical(is.na(a), is.na(b)) &&
    all(abs(a[!is.na(a)] - b[!is.na(b)]) <= tolerancia)
}
ler <- function(diretorio, arquivo) readr::read_csv(file.path(diretorio, arquivo), show_col_types = FALSE)
ordenar <- function(d) d[order(d$id_municipio), , drop = FALSE]

dir_nac <- file.path(paths$raw, "nacional")
pop <- ordenar(contexto_ler_sidra(file.path(dir_nac, "ibge_populacao_municipios_rs_2022.csv"),
                                cfg$contexto$ano_populacao, 93, "Pessoas", "populacao"))
pib <- ordenar(contexto_ler_sidra(file.path(dir_nac, "ibge_pib_municipios_rs.csv"),
                                cfg$contexto$ano_pib, 37, "Mil Reais", "pib"))
tdi <- ordenar(contexto_ler_tdi(contexto_arquivo_tdi(file.path(dir_nac, "inep_distorcao"),
                                                  cfg$contexto$ano_tdi, cfg$inep_tdi_xlsx_md5),
                              cfg$contexto$ano_tdi, cfg$uf))
contexto <- ordenar(ler(paths$processed, "contexto_rs_municipio.csv"))
cadastro <- ler(dir_nac, "ibge_municipios_regioes_rs.csv") |>
  dplyr::filter(!is.na(id_municipio))
contexto_validar_chaves(cadastro, n = cfg$n_municipios, fonte = "Cadastro IBGE")
for (nm in c("pop", "pib", "tdi", "contexto"))
  contexto_validar_chaves(get(nm), ids = cadastro$id_municipio, fonte = nm)
confere("Cadastro e contexto têm os mesmos municípios, sem chaves repetidas", TRUE)
confere("Cadastro RS contém oito regiões intermediárias", dplyr::n_distinct(cadastro$nome_regiao_intermediaria) == 8L)
idx_cadastro <- match(contexto$id_municipio, cadastro$id_municipio)
confere("Regiões do contexto correspondem ao cadastro IBGE",
        identical(contexto$nome_regiao_intermediaria, cadastro$nome_regiao_intermediaria[idx_cadastro]))
for (par in list(c("pop", "populacao"), c("pib", "pib"), c("tdi", "distorcao_idade_serie_fund"))) {
  campo <- par[[2]]
  confere(paste("Contexto reproduz a fonte:", campo), iguais(contexto[[campo]], get(par[[1]])[[campo]]))
}
confere("Denominadores municipais positivos", all(contexto$populacao > 0))
fontes <- ler(paths$out_aud, "contexto_fontes.csv")
confere("Três fontes com ano e hash registrados", nrow(fontes) == 3L &&
          iguais(fontes$ano, unlist(cfg$contexto), 0) && all(nchar(fontes$md5) == 32L))
entradas <- c(file.path(dir_nac, "ibge_populacao_municipios_rs_2022.csv"),
              file.path(dir_nac, "ibge_pib_municipios_rs.csv"),
              contexto_arquivo_tdi(file.path(dir_nac, "inep_distorcao"), cfg$contexto$ano_tdi,
                                    cfg$inep_tdi_xlsx_md5))
confere("Manifesto corresponde aos arquivos efetivamente lidos e seus hashes",
        identical(fontes$arquivo, normalizePath(entradas, winslash = "/")) &&
          identical(fontes$md5, unname(tools::md5sum(entradas))))

exportado <- ler(file.path(paths$out_tab, "formato_sp"), "contexto_dados.csv")
contexto_validar_chaves(dplyr::rename(exportado, id_municipio = `ID Município`),
                       ids = contexto$id_municipio, fonte = "Exportação do contexto")
exportado <- exportado[match(contexto$id_municipio, exportado[["ID Município"]]), ]
confere("Cabeçalho do PIB informa mil reais correntes, sem rótulo legado em reais",
        "PIB (mil R$ correntes)" %in% names(exportado) && !"PIB (em R$)" %in% names(exportado))
confere("Exportação mantém valores do PIB na escala original",
        iguais(exportado[["PIB (mil R$ correntes)"]], pib$pib))
confere("Exportação mantém a população do Censo 2022", iguais(exportado$Pop_2022, pop$populacao))
confere("Exportação mantém o Inep do ano fixado", iguais(exportado[["Distorção idade-serie"]],
                                                        tdi$distorcao_idade_serie_fund))

criminal <- ler(paths$out_tab, "painel_criminal_municipio_ano.csv")
chave <- paste(criminal$id_municipio, criminal$ano, sep = ":")
grade <- as.vector(outer(contexto$id_municipio, cfg$anos_criminal, paste, sep = ":"))
confere("Criminal tem uma linha por município/ano e grade completa",
        !anyDuplicated(chave) && setequal(chave, grade))
pop_fonte <- pop$populacao[match(criminal$id_municipio, pop$id_municipio)]
confere("Denominador criminal é o Censo fixado, sem duplicação", iguais(criminal$populacao, pop_fonte))
indicadores <- c("hd_vitima", "hd_ocorrencias", "tot_estupro", "roubo_outros", "furto_outros",
                 "prisoes", "mandados_cumpridos")
for (campo in indicadores) {
  confere(paste("Taxa por 100 mil = numerador / Censo 2022:", campo),
          iguais(criminal[[paste0(campo, "_taxa_100k")]], criminal[[campo]] / pop_fonte * 1e5))
}
longo <- ler(file.path(paths$out_tab, "formato_sp"), "dinamica_criminal.csv")
rubricas <- c(hd_vitima = "Vítimas de homicídio doloso", tot_estupro = "Estupros - total",
              roubo_outros = "Total de roubo - outros", furto_outros = "Total de furto - outros",
              prisoes = "Flagrantes da Polícia Civil", mandados_cumpridos = "Mandados de prisão cumpridos")
chave_longo <- paste(longo[["ID Município"]], longo$Ano, longo$Crime, sep = ":")
confere("Exportação criminal tem seis indicadores por município/ano, sem duplicatas",
        nrow(longo) == length(grade) * length(rubricas) && !anyDuplicated(chave_longo) &&
          setequal(longo$Crime, unname(rubricas)))
for (campo in names(rubricas)) {
  bloco <- longo[longo$Crime == rubricas[[campo]], ]
  idx <- match(chave, paste(bloco[["ID Município"]], bloco$Ano, sep = ":"))
  confere(paste("Exportação preserva numerador, denominador e taxa:", campo),
          !anyNA(idx) && iguais(bloco$quantidade[idx], criminal[[campo]]) &&
            iguais(bloco[["população"]][idx], pop_fonte) &&
            iguais(bloco$taxa[idx], criminal[[campo]] / pop_fonte * 1e5))
}
linhas <- c(linhas, "", paste0("Resultado: ", length(falhas), " falha(s)."),
             "A validação não altera as regras de cobertura nem equipara automaticamente os universos de SP e RS.")
readr::write_lines(linhas, file.path(paths$out_aud, "validacao_contexto.md"))
if (length(falhas)) stop("Validação de contexto falhou: ", paste(falhas, collapse = "; "))
message("OK — validação de contexto, escala do PIB, fontes e taxas exportadas.")
