# =============================================================================
# util_centroides.R — Centroides (lat/lon) dos municípios do RS para mapas no Looker
# -----------------------------------------------------------------------------
# Gera latitude/longitude do centro de cada município do RS a partir das malhas
# oficiais do IBGE (via geobr), para usar como camada de MAPA DE BOLHAS no Looker
# Studio (Geo por lat/long) — contorna a limitação do mapa municipal nativo.
#
# Saída: data/processed/centroides_municipios_rs.csv (id_municipio, nome, lat, lon)
#
# Requer: geobr e sf (instalar à parte; não fazem parte do pipeline principal):
#   install.packages(c("geobr","sf"))   # e depois renv::snapshot() se quiser travar
# Uso: source("scripts/rs/util_centroides.R")
# =============================================================================

source(here::here("scripts/rs/00_config.R"))
for (p in c("geobr","sf")) if (!requireNamespace(p, quietly = TRUE))
  stop("Pacote '", p, "' ausente. Instale: install.packages(c('geobr','sf')).")

COD_UF_RS <- 43
muni <- geobr::read_municipality(code_muni = COD_UF_RS, year = 2022, simplified = TRUE)

# centroide de cada polígono (suppressWarnings: aviso de centroide em lon/lat é inócuo p/ bolhas)
cen <- suppressWarnings(sf::st_centroid(sf::st_geometry(muni)))
xy  <- sf::st_coordinates(cen)

centroides <- tibble::tibble(
  id_municipio = as.integer(muni$code_muni),
  nome         = muni$name_muni,
  lat          = round(xy[, "Y"], 6),
  lon          = round(xy[, "X"], 6)
) |>
  dplyr::arrange(nome)

# Looker aceita um único campo "Latitude, Longitude" (texto "lat,lon") como Geo
centroides$lat_lon <- paste(centroides$lat, centroides$lon, sep = ", ")

readr::write_csv(centroides, file.path(paths$processed, "centroides_municipios_rs.csv"))
message("OK — centroides_municipios_rs.csv (", nrow(centroides), " municípios).")
print(utils::head(centroides))
