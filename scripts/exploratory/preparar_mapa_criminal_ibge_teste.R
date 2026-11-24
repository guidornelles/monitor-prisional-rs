# Teste isolado da malha municipal IBGE 2022 com os fatos criminais validados.
# Não altera a pipeline, as tabelas canônicas, a candidata ou os dados de origem.
# Executar da raiz: Rscript --vanilla scripts/exploratory/preparar_mapa_criminal_ibge_teste.R
# Pacotes: sf, readr, jsonlite e digest. Todos já disponíveis no ambiente do projeto.
# Com --vanilla no Windows, usa a biblioteca local já instalada para esta versão
# e plataforma do R. Não ativa o renv, não faz bootstrap nem restaura pacotes.
# Nos demais sistemas, os pacotes devem estar disponíveis no ambiente carregado.
if (.Platform$OS.type == "windows") {
  .versao_r_mapa <- paste0("R-", R.version$major, ".",
                           strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1])
  .biblioteca_mapa <- file.path("renv", "library", "windows", .versao_r_mapa,
                                R.version$platform)
  if (!dir.exists(.biblioteca_mapa)) {
    stop("Biblioteca local do projeto não encontrada para este R: ", .biblioteca_mapa)
  }
  .libPaths(c(normalizePath(.biblioteca_mapa, winslash = "/", mustWork = TRUE), .libPaths()))
}
suppressPackageStartupMessages({ library(sf); library(readr) })
options(encoding = "UTF-8", timeout = max(120, getOption("timeout")))
stopifnot(requireNamespace("jsonlite", quietly = TRUE), requireNamespace("digest", quietly = TRUE))

out <- "outputs/temp/mapa_criminal_ibge_teste_2026-11-23"
aud <- "outputs/auditoria/mapa_criminal_ibge_teste_2026-11-23"
cache <- "data/raw/ibge_malha_2022"
invisible(lapply(c(out, aud, cache), dir.create, recursive = TRUE, showWarnings = FALSE))
entrada <- "outputs/temp/mapa_ultimo_ano_2026-11-23/tabelas/formato_sp/dinamica_criminal.csv"
url <- paste0("https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/",
              "malhas_municipais/municipio_2022/UFs/RS/RS_Municipios_2022.zip")
zip <- file.path(cache, "RS_Municipios_2022.zip")
sha_zip <- "93051c815e4451a60187ed25ab412e507a0504142c0c381f6f2a6cd5cf93eed7"
if (!file.exists(zip)) download.file(url, zip, mode = "wb", method = "libcurl")
hash <- function(p) {
  # Hash dos bytes, sem depender da checagem de caminhos do digest no Windows.
  digest::digest(readBin(p, what = "raw", n = file.info(p)$size),
                 algo = "sha256", serialize = FALSE)
}
stopifnot(identical(hash(zip), sha_zip), file.exists(entrada))

orig <- read_csv(entrada, col_types = cols(`ID Município` = col_character()), show_col_types = FALSE)
fatos <- data.frame(
  id_municipio = orig[["ID Município"]], nome = orig[["Município (IBGE)"]],
  regiao = orig[["Nome Macrorregião"]], ano = orig$Ano, indicador = orig$Crime,
  quantidade = orig$quantidade, populacao = orig[["população"]], taxa = orig$taxa,
  quantidade_informada = orig$quantidade_informada, meses_informados = orig$meses_informados,
  stringsAsFactors = FALSE
)
ids <- sort(unique(fatos$id_municipio))
indicadores <- c(
  homicidio_doloso_vitimas = "Vítimas de homicídio doloso",
  estupros_total = "Estupros - total",
  furto_outros = "Total de furto - outros",
  roubo_outros = "Total de roubo - outros",
  flagrantes_pc = "Flagrantes da Polícia Civil",
  mandados_cumpridos = "Mandados de prisão cumpridos"
)
stopifnot(nrow(fatos) == 11928L, length(ids) == 497L,
          all(grepl("^43[0-9]{5}$", ids)), setequal(fatos$ano, 2022:2025),
          setequal(fatos$indicador, unname(indicadores)),
          !anyDuplicated(fatos[c("id_municipio", "ano", "indicador")]),
          all(is.finite(fatos$populacao) & fatos$populacao > 0),
          all(table(fatos$ano, fatos$indicador) == 497L))
for (col in c("quantidade", "taxa")) stopifnot(identical(fatos[[col]], orig[[col]]))
stopifnot(identical(fatos$populacao, orig[["população"]]))
delta_taxa <- abs(fatos$taxa - fatos$quantidade / fatos$populacao * 1e5)
stopifnot(all(delta_taxa <= 1e-10))
cad <- fatos[match(ids, fatos$id_municipio), c("id_municipio", "nome", "regiao")]
stopifnot(all(vapply(split(fatos, fatos$id_municipio), function(x) {
  length(unique(x$nome)) == 1L && length(unique(x$regiao)) == 1L &&
    length(unique(x$populacao)) == 1L
}, logical(1))))

malha <- st_read(paste0("/vsizip/", normalizePath(zip, winslash = "/")), quiet = TRUE)
stopifnot(st_crs(malha)$epsg == 4674L, !anyDuplicated(malha$CD_MUN),
          all(st_is_valid(malha)), !any(st_is_empty(malha)))
extras <- malha[!malha$CD_MUN %in% ids, ]
# A edição do IBGE traz duas feições aquáticas além dos 497 municípios.
# Elas são contexto sem indicador, nunca municípios inventados ou zeros criminais.
stopifnot(setequal(extras$CD_MUN, c("4300001", "4300002")))
municipios <- malha[match(ids, malha$CD_MUN), ]
stopifnot(nrow(municipios) == 497L, identical(as.character(municipios$CD_MUN), ids))
geometria_origem <- st_geometry(municipios)
geo <- st_transform(municipios, 4326)

contar <- function(geometria) {
  # Conserva partes desconectadas (inclusive ilhas) e anéis interiores.
  multipoligonos <- st_cast(geometria, "MULTIPOLYGON", warn = FALSE)
  data.frame(partes = vapply(multipoligonos, length, integer(1)),
             aneis = vapply(multipoligonos, function(g) sum(lengths(g)), integer(1)))
}
estrutura_antes <- contar(geometria_origem)
estrutura_depois <- contar(st_geometry(geo))
vertices <- nrow(st_coordinates(geo))
stopifnot(vertices < 1000000L, all(st_is_valid(geo)),
          identical(estrutura_antes, estrutura_depois))
message("Malha municipal: ", nrow(geo), " códigos; ", vertices,
        " vértices. Geometria original preservada, sem simplificação.")

# Topologia do conjunto: a transformação comum preserva os limites compartilhados.
# Compara sobreposição por área na projeção métrica e a estrutura dos anéis.
plana <- st_transform(municipios, 5880)
uniao <- st_union(st_geometry(plana))
sobreposicao_m2 <- as.numeric(sum(st_area(plana)) - sum(st_area(uniao)))
stopifnot(abs(sobreposicao_m2) < 1)

geometria <- st_geometry(geo)
geo <- st_sf(cad, nome_malha_ibge = municipios$NM_MUN, uf = "RS",
             ano_malha = 2022L, ano_denominador = 2022L, geometry = geometria)
for (ano in c(2022L, 2025L)) {
  q <- fatos[fatos$ano == ano & fatos$indicador == indicadores[[1]], ]
  geo[[paste0("populacao_", ano)]] <- q$populacao[match(ids, q$id_municipio)]
  for (slug in names(indicadores)) {
    q <- fatos[fatos$ano == ano & fatos$indicador == indicadores[[slug]], ]
    q <- q[match(ids, q$id_municipio), ]
    for (campo in c("quantidade", "taxa", "quantidade_informada")) {
      geo[[paste(campo, slug, ano, sep = "_")]] <- q[[campo]]
    }
  }
}
arq_geo <- file.path(out, "geo_municipios_rs_2022.geojson")
st_write(geo, arq_geo, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE,
         layer_options = c("RFC7946=YES", "COORDINATE_PRECISION=15", "SIGNIFICANT_FIGURES=17"))
contexto_agua <- st_transform(extras, 4326)
st_write(contexto_agua, file.path(out, "contexto_lagoas_ibge_2022.geojson"),
         driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE,
         layer_options = c("RFC7946=YES", "COORDINATE_PRECISION=15"))

wkt <- data.frame(id_municipio = ids, nome = cad$nome,
                  nome_malha_ibge = municipios$NM_MUN, uf = "RS", ano_malha = 2022L,
                  geometry_wkt = st_as_text(st_geometry(geo), digits = 17),
                  stringsAsFactors = FALSE)
write_csv(wkt, file.path(out, "geometrias_municipais_bq.csv"), na = "")
write_csv(fatos, file.path(out, "fatos_criminais.csv"), na = "")
jsonlite::write_json(fatos, file.path(out, "fatos_criminais.json"), dataframe = "rows",
                     digits = NA, na = "null", auto_unbox = TRUE)

# Reabre os artefatos: valida o que será carregado, não apenas o objeto em memória.
geo_lido <- st_read(arq_geo, quiet = TRUE)
fatos_lidos <- read_csv(file.path(out, "fatos_criminais.csv"),
                       col_types = cols(id_municipio = col_character()), show_col_types = FALSE)
# RFC 7946 pode inverter a orientação dos anéis ao escrever GeoJSON. Essa
# orientação não altera vértices, limites, ilhas ou buracos da geometria.
igual_direto <- st_equals_exact(st_geometry(geo), st_geometry(geo_lido), par = 1e-11)
igual_invertido <- st_equals_exact(st_geometry(geo), st_reverse(st_geometry(geo_lido)), par = 1e-11)
limites_iguais <- vapply(seq_len(nrow(geo)), function(i) {
  i %in% igual_direto[[i]] || i %in% igual_invertido[[i]]
}, logical(1))
stopifnot(nrow(geo_lido) == 497L, identical(geo_lido$id_municipio, ids),
          st_crs(geo_lido)$epsg == 4326L, all(st_is_valid(geo_lido)),
          identical(contar(st_geometry(geo_lido)), estrutura_antes),
          all(limites_iguais),
          isTRUE(all.equal(fatos_lidos, fatos, check.attributes = FALSE, tolerance = 1e-15)))
for (ano in c(2022L, 2025L)) for (slug in names(indicadores)) {
  q <- fatos[fatos$ano == ano & fatos$indicador == indicadores[[slug]], ]
  q <- q[match(ids, q$id_municipio), ]
  for (campo in c("quantidade", "taxa", "quantidade_informada")) {
    stopifnot(isTRUE(all.equal(geo_lido[[paste(campo, slug, ano, sep = "_")]],
                                q[[campo]], check.attributes = FALSE, tolerance = 1e-14)))
  }
}

aud_municipios <- cbind(cad, nome_malha_ibge = municipios$NM_MUN,
  vertices = vapply(st_geometry(geo), function(g) nrow(st_coordinates(g)), integer(1)),
  partes = estrutura_antes$partes, aneis = estrutura_antes$aneis,
  aneis_interiores = estrutura_antes$aneis - estrutura_antes$partes,
  valido = st_is_valid(geo_lido))
write_csv(aud_municipios, file.path(aud, "cobertura_geometrias_497.csv"))
totais <- aggregate(quantidade ~ ano + indicador, data = fatos, sum)
totais$municipios <- 497L
totais$municipios_informados <- vapply(seq_len(nrow(totais)), function(i) {
  sum(fatos$quantidade_informada[fatos$ano == totais$ano[i] & fatos$indicador == totais$indicador[i]])
}, numeric(1))
write_csv(totais, file.path(aud, "controle_fatos_24.csv"))
write_csv(data.frame(slug = names(indicadores), indicador = unname(indicadores)),
          file.path(aud, "dicionario_indicadores.csv"))
artefatos <- list.files(out, full.names = TRUE, pattern = "\\.(csv|json|geojson)$")
manifesto <- list(
  data_preparacao = "2026-11-23", tipo = "teste isolado, sem publicação",
  fonte_malha = url, ano_malha = 2022L, crs_origem = 4674L, crs_saida = 4326L,
  zip_sha256 = sha_zip, entrada_fatos = entrada, entrada_fatos_sha256 = hash(entrada),
  anos_fatos = 2022:2025, anos_atributos_geojson = c(2022L, 2025L),
  municipios = 497L, fatos = nrow(fatos), indicadores = length(indicadores),
  vertices_municipios = vertices, vertices_arquivo_ibge_incluindo_lagoas = nrow(st_coordinates(malha)),
  simplificacao = "nenhuma: original cabe no limite de 1 milhão de vértices por camada",
  componentes_preservados = TRUE, aneis_preservados = TRUE,
  sobreposicao_m2 = sobreposicao_m2, max_diferenca_recalculo_taxa = max(delta_taxa),
  bbox = as.list(st_bbox(geo)), lagoas_sem_fatos = as.character(extras$CD_MUN),
  nomes_diferentes_entre_fontes = sum(cad$nome != municipios$NM_MUN),
  geos = unname(sf_extSoftVersion()[["GEOS"]]),
  arquivos = lapply(artefatos, function(p) list(arquivo = basename(p),
                  bytes = unname(file.info(p)$size), sha256 = hash(p))),
  limites = c(
    "Malha produzida pelo IBGE para fins estatísticos; não é demarcação legal de limites.",
    "A mesma malha 2022 representa todos os anos; o denominador é a população do Censo 2022.",
    "Quantidade e taxa são copiadas. quantidade_informada deve distinguir indisponibilidade de zero observado.",
    "Lagoa Mirim e Lagoa dos Patos são feições oficiais de contexto, sem dados municipais atribuídos.",
    "Configurar até 1 milhão de vértices na camada; conferir a contagem após eventual ingestão BigQuery."
  )
)
jsonlite::write_json(manifesto, file.path(aud, "manifesto.json"), pretty = TRUE,
                     auto_unbox = TRUE, digits = NA)
message("OK: ", arq_geo, "; 11928 fatos e WKT separados. Vértices: ", vertices)
