# Catálogo independente para validar o painel SISDEPEN-RS contra a Base Única.
# As seleções são explícitas. Não importa funções do pipeline 03/03b.
# Campos ausentes contribuem com zero nas contagens, conforme decisão de 15/11/2026.

catalogo_prisional <- function() {
  sexos <- c(masculino = "Masculino", feminino = "Feminino")
  regimes <- c(
    provisorios = "Presos provisórios (sem condenação)",
    sentenciado_fechado = "Presos sentenciados - regime fechado",
    sentenciado_semiaberto = "Presos sentenciados - regime semiaberto",
    sentenciado_aberto = "Presos sentenciados - regime aberto",
    internacao = "Medida de segurança - internação",
    tratamento = "Medida de segurança - tratamento ambulatorial"
  )
  justicas <- c("Justiça Estadual", "Justiça Federal", "Outros(Just. Trab., cível)")
  somas <- list()
  for (regime in names(regimes)) for (sexo in names(sexos)) {
    somas[[paste(regime, sexo, sep = "_")]] <- paste(
      "4.1 População prisional", regimes[[regime]],
      paste(justicas, sexos[[sexo]]), sep = " | "
    )
  }
  somas$populacao_total <- "4.1 População prisional | Total"
  somas$capacidade_total <- paste(
    "1.3 Capacidade do estabelecimento", unname(sexos), "Total", sep = " | "
  )
  somas$total_medicos <- paste(
    "3.1 Quantidade de Servidores que atuam no Sistema Prisional",
    c("Médicos - clínicos gerais", "Médicos – ginecologistas",
      "Médicos – psiquiatras", "Médicos - outras especialidades"), "Total", sep = " | "
  )
  somas$brasileiro_nato <- paste(
    "5.8 Quantidade de pessoas privadas de liberdade por nacionalidade",
    "Brasileiro nato", unname(sexos), sep = " | "
  )

  faixas <- c(
    "Até 6 meses (inclusive)", "Mais de 6 meses até 1 ano (inclusive)",
    "Mais de 1 ano até 2 anos (inclusive)", "Mais de 2 até 4 anos (inclusive)",
    "Mais de 4 até 8 anos (inclusive)", "Mais de 8 até 15 anos (inclusive)",
    "Mais de 15 até 20 anos (inclusive)", "Mais de 20 até 30 anos (inclusive)",
    "Mais de 30 até 50 anos (inclusive)", "Mais de 50 até 100 anos (inclusive)",
    "Mais de 100 anos", "Número de pessoas sem informação"
  )
  pena_total <- list(
    `0_2anos` = 1:3, `2_4anos` = 4L, `4_8anos` = 5L, `8_15anos` = 6L,
    `15_20anos` = 7L, `20_30anos` = 8L, `30_maisanos` = 9:11, sem_info = 12L
  )
  pena_restante <- list(
    `0_4anos` = 1:4, `4_8anos` = 5L, `8_15anos` = 6L,
    `15_20anos` = 7L, `20_30anos` = 8L, `30_50anos` = 9L, `50maisanos` = 10:11
  )
  prefixos_pena <- c(
    pena = "5.12 Quantidade de pessoas privadas de liberdade por tempo total de penas (presos/as condenados/as e )",
    pena_remanescente = "5.13 Quantidade de pessoas privadas de liberdade por tempo de pena remanescente (presos/as condenados/as e)"
  )
  cortes <- list(pena = pena_total, pena_remanescente = pena_restante)
  for (quesito in names(cortes)) for (sexo in names(sexos)) {
    for (faixa in names(cortes[[quesito]])) {
      somas[[paste(quesito, sexo, faixa, sep = "_")]] <- paste(
        prefixos_pena[[quesito]], faixas[cortes[[quesito]][[faixa]]],
        sexos[[sexo]], sep = " | "
      )
    }
  }
  for (sexo in names(sexos)) {
    nome <- c(masculino = "homens_presos", feminino = "mulheres_presas")[[sexo]]
    somas[[paste0(nome, "_com_filhos_as")]] <- paste(
      "5.10 Número de filhos/as", c(as.character(1:10), "11 ou mais"),
      sexos[[sexo]], sep = " | "
    )
  }

  # Países e rubricas 5.14 ficam fixados abaixo, conforme os rótulos da edição
  # sisdepen_baseunica_2025-2_25032026-163420.xlsx. Alterações no esquema exigem
  # revisar este catálogo, sem ampliar silenciosamente seleções por texto.
  paises <- list()
  rubricas <- list()
  paises$america <- c(
    "Antígua e Barbuda",
    "Argentina",
    "Bahamas",
    "Barbados",
    "Belize",
    "Bolívia",
    "Canadá",
    "Chile",
    "Colômbia",
    "Costa Rica",
    "Cuba",
    "Dominica",
    "El Salvador",
    "Equador",
    "Estados Unidos da América",
    "Granada",
    "Guatemala",
    "Guiana",
    "Guiana Francesa",
    "Haiti",
    "Honduras",
    "Ilhas Cayman",
    "Jamaica",
    "México",
    "Nicarágua",
    "Panamá",
    "Paraguai",
    "Peru",
    "Porto Rico",
    "República Dominicana",
    "Santa Lúcia",
    "Suriname",
    "São Cristóvão e Névis",
    "São Vicente e Granadinas",
    "Trindade e Tobago",
    "Uruguai",
    "Venezuela",
    "Outros países do continente americano"
  )

  paises$asia <- c(
    "Afeganistão",
    "Armênia",
    "Arábia Saudita",
    "Azerbaijão",
    "Bahrein",
    "Bangladesh",
    "Brunei",
    "Butão",
    "Camboja",
    "Catar",
    "Cazaquistão",
    "China",
    "Chipre",
    "Cingapura",
    "Coréia do Norte",
    "Coréia do Sul",
    "Egito",
    "Emirados Árabes Unidos",
    "Filipinas",
    "Geórgia",
    "Índia",
    "Indonésia",
    "Iraque",
    "Irã",
    "Israel",
    "Iêmen",
    "Japão",
    "Jordânia",
    "Kuwait",
    "Laos",
    "Líbano",
    "Macau",
    "Maldivas",
    "Malásia",
    "Mianmar",
    "Mongólia",
    "Nepal",
    "Omã",
    "Paquistão",
    "Quirguistão",
    "Sri Lanka",
    "Síria",
    "Tailândia",
    "Taiwan",
    "Tajiquistão",
    "Timor Leste",
    "Turcomenistão",
    "Turquia",
    "Uzbequistão",
    "Vietnã",
    "Outros países do continente asiático"
  )

  paises$africa <- c(
    "África do Sul",
    "Angola",
    "Argélia",
    "Benin",
    "Botsuana",
    "Burkina Faso",
    "Burundi",
    "Cabo Verde",
    "Camarões",
    "Chade",
    "República do Congo",
    "Costa do Marfim",
    "Djibouti",
    "Egito",
    "Eritreia",
    "Eswatini",
    "Etiópia",
    "Gabão",
    "Gana",
    "Guiné",
    "Guiné Bissau",
    "Guiné Equatorial",
    "Gâmbia",
    "Ilha de Comores",
    "Ilhas Seychelles",
    "Ilhas São Tomé e Príncipe",
    "Lesoto",
    "Libéria",
    "Líbia",
    "Madagascar",
    "Malauí",
    "Mali",
    "Marrocos",
    "Mauritânia",
    "Moçambique",
    "Namíbia",
    "Nigéria",
    "Níger",
    "Quênia",
    "República Centro-Africana",
    "República de Maurício",
    "Ruanda",
    "Senegal",
    "Serra Leoa",
    "Somália",
    "Sudão",
    "Sudão do Sul",
    "Tanzânia",
    "Togo",
    "Tunísia",
    "Uganda",
    "Zimbabue",
    "Zâmbia",
    "Outros países do continente africano"
  )

  paises$europa <- c(
    "Albânia",
    "Alemanha",
    "Áustria",
    "Andorra",
    "Bielorrússia",
    "Bélgica",
    "Bulgária",
    "Bósnia e Herzegovina",
    "Cazaquistão",
    "Chipre",
    "Croácia",
    "Dinamarca",
    "Escócia",
    "Eslováquia",
    "Eslovênia",
    "Espanha",
    "Estônia",
    "Finlândia",
    "França",
    "Grécia",
    "Países Baixos ou Holanda",
    "Hungria",
    "Inglaterra",
    "Irlanda",
    "Irlanda do Norte",
    "Islândia",
    "Itália",
    "Letônia",
    "Liechtenstein",
    "Lituânia",
    "Luxemburgo",
    "Macedônia do Norte",
    "Malta",
    "Moldávia",
    "Montenegro",
    "Mônaco",
    "Noruega",
    "País de Gales",
    "Polônia",
    "Portugal",
    "Reino Unido",
    "República Tcheca",
    "Romênia",
    "Rússia",
    "San Marino",
    "Suécia",
    "Suíça",
    "Sérvia",
    "Ucrânia",
    "Vaticano",
    "Outros países do continente europeu",
    "Holanda"
  )

  paises$oceania <- c(
    "Austrália",
    "Estados Federados da Micronésia",
    "Fiji",
    "Ilhas Marshall",
    "Ilhas Salomão",
    "Kiribati",
    "Nauru",
    "Nova Zelândia",
    "Palau",
    "Papua-Nova Guiné",
    "Samoa",
    "Tonga",
    "Tuvalu",
    "Vanuatu",
    "Outros países do continente Oceania"
  )

  rubricas$contra_pessoa <- c(
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a pessoa | Homicídio simples (Art. 121, caput)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a pessoa | Homicílio culposo (Art. 121, § 3°)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a pessoa | Homicídio qualificado (Art. 121, § 2°)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a pessoa | Aborto (Art. 124, 125, 126 e 127)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a pessoa | Lesão corporal (Art. 129, caput e § 1°, 2°, 3° e 6°)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a pessoa | Violência doméstica (Art. 129,  § 9°)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a pessoa | Sequestro e cárcere privado (Art. 148)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a pessoa | Outros - não listados acima entre os artigos 122 e 154-A"
  )

  rubricas$contra_patrimonio <- c(
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Furto simples (Art. 155)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Furto qualificado (Art. 155, § 4° e 5°)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Roubo simples (Art. 157)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Roubo qualificado (Art. 157, § 2°",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Latrocínio (Art. 157, § 3°)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Extorsão (Art. 158)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Extorsão mediante sequestro (Art. 159)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Apropriação indébita (Art. 168)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Apropriação indébita previdenciária (Art. 168-A)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Estelionato (Art. 171)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Receptação (Art. 180)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Receptação qualificada (Art. 180, § 1°)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra o patrimônio | Outros - não listados acima entre os artigos 156 e 179"
  )

  rubricas$dignidade_sexual <- c(
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a dignidade sexual | Estupro (Art. 213)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a dignidade sexual | Atentado violento ao pudor (Art. 214)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a dignidade sexual | Estupro de vulnerável (Art. 217-A)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a dignidade sexual | Corrupção de menores (Art. 218)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a dignidade sexual | Tráfico internacional de pessoa para fim de exploração sexual (Art. 231)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a dignidade sexual | Tráfico interno de pessoa para fim de exploração sexual (Art. 231-A)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: CÓDIGO PENAL | Grupo: Crimes contra a dignidade sexual | Outros (Artigos 215, 216-A, 218-A, 218-B, 227, 228, 229, 230)"
  )

  rubricas$drogas <- c(
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: LEGISLAÇÃO ESPECÍFICA | Grupo: Drogas (Lei 6.368/76 e Lei 11.343/06) | Tráfico de drogas (Art. 12 da Lei 6.368/76 e Art. 33 da Lei 11.343/06)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: LEGISLAÇÃO ESPECÍFICA | Grupo: Drogas (Lei 6.368/76 e Lei 11.343/06) | Associação para o tráfico (Art. 14 da Lei 6.368/76 e Art. 35 da Lei 11.343/06)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: LEGISLAÇÃO ESPECÍFICA | Grupo: Drogas (Lei 6.368/76 e Lei 11.343/06) | Tráfico internacional de drogas (Art. 18 da Lei 6.368/76 e Art. 33 e 40, inciso I da Lei 11.343/06)"
  )

  rubricas$desarmamento <- c(
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: LEGISLAÇÃO ESPECÍFICA | Grupo: Estatuto do Desarmamento (Lei 10.826, de 22/12/2003) | Porte ilegal de arma de fogo de uso permitido (Art. 14)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: LEGISLAÇÃO ESPECÍFICA | Grupo: Estatuto do Desarmamento (Lei 10.826, de 22/12/2003) | Disparo de arma de fogo (Art. 15)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: LEGISLAÇÃO ESPECÍFICA | Grupo: Estatuto do Desarmamento (Lei 10.826, de 22/12/2003) | Posse ou porte ilegal de arma de fogo de uso restrito (Art. 16)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: LEGISLAÇÃO ESPECÍFICA | Grupo: Estatuto do Desarmamento (Lei 10.826, de 22/12/2003) | Comércio ilegal de arma de fogo (Art. 17)",
    "5.14 Quantidade de incidências por tipo penal |  GRUPO: LEGISLAÇÃO ESPECÍFICA | Grupo: Estatuto do Desarmamento (Lei 10.826, de 22/12/2003) | Tráfico internacional de arma de fogo (Art. 18)"
  )

  continentes <- c(america = "América", asia = "Ásia", africa = "África",
                   europa = "Europa", oceania = "Oceania")
  for (continente in names(continentes)) {
    somas[[paste0("continente_", continente)]] <- as.vector(outer(
      paises[[continente]], unname(sexos), function(pais, sexo) paste(
        "5.8 Quantidade de pessoas privadas de liberdade por nacionalidade",
        continentes[[continente]], pais, sexo, sep = " | "
      )
    ))
  }
  for (grupo in names(rubricas)) for (sexo in c(unname(sexos), "Total")) {
    somas[[paste("tipo_penal", grupo, tolower(sexo), sep = "_")]] <-
      paste(rubricas[[grupo]], sexo, sep = " | ")
  }
  residuos <- list()
  for (sexo in names(sexos)) {
    residuos[[paste0("tipo_penal_outros_", sexo)]] <- list(
      total = paste("5.14 Quantidade de incidências por tipo penal", sexos[[sexo]], sep = " | "),
      descontar = paste("tipo_penal", names(rubricas), sexo, sep = "_")
    )
  }

  sem2_numericos <- c(
    atendimento_estabelecimento = "6.6 Informações da área de saúde - total do período | Consultas médicas realizadas no estabelecimento | Total",
    atendimento_externo = "6.6 Informações da área de saúde - total do período | Consultas médicas realizadas externamente | Total",
    atendimento_psicologico = "6.6 Informações da área de saúde - total do período | Consultas psicológicas | Total",
    atendimento_odonto = "6.6 Informações da área de saúde - total do período | Consultas odontológicas | Total",
    quantidade_lactantes = "5.9 Faixa etária dos filhos que estão no estabelecimento (aplicável apenas para estabelecimentos com mulheres) | Quantidade de lactantes"
  )
  sem2_texto <- c(
    cela_gestantes = "2.1 Há cela adequada/ dormitório para gestantes? (apenas para estabelecimentos com vagas para mulheres)"
  )
  # Os campos brutos correspondentes continuam sendo o retrato do primeiro ciclo.
  brutos_sem1 <- c(
    unlist(somas[c("populacao_total", "capacidade_total")], use.names = FALSE),
    unname(sem2_numericos[names(sem2_numericos) != "atendimento_odonto"]),
    "5.9 Faixa etária dos filhos que estão no estabelecimento (aplicável apenas para estabelecimentos com mulheres) | Quantidade de gestantes/parturientes"
  )
  list(somas = somas, residuos = residuos, sem2_numericos = sem2_numericos,
       sem2_texto = sem2_texto, brutos_sem1 = brutos_sem1)
}

referencia_derivadas_prisionais <- function(sem1, sem2, catalogo) {
  somar <- function(d, campos) {
    # Um produto matricial deixa explícito o peso 1 de cada numerador selecionado.
    valores <- as.matrix(d[, campos, drop = FALSE])
    valores[is.na(valores)] <- 0
    as.vector(valores %*% rep(1, length(campos)))
  }
  esperado <- lapply(catalogo$somas, function(campos) somar(sem1, campos))
  for (campo in names(catalogo$residuos)) {
    regra <- catalogo$residuos[[campo]]
    total <- somar(sem1, regra$total)
    grupos <- Reduce(`+`, esperado[regra$descontar])
    esperado[[campo]] <- pmax(0, total - grupos)
  }
  esperado$tipo_penal_outros_total <- esperado$tipo_penal_outros_masculino +
    esperado$tipo_penal_outros_feminino
  for (campo in names(catalogo$sem2_numericos)) {
    esperado[[campo]] <- somar(sem2, catalogo$sem2_numericos[[campo]])
  }
  for (campo in names(catalogo$sem2_texto)) {
    esperado[[campo]] <- as.character(sem2[[catalogo$sem2_texto[[campo]]]])
  }
  for (campo in catalogo$brutos_sem1) esperado[[campo]] <- somar(sem1, campo)
  for (campo in unname(catalogo$sem2_texto)) esperado[[campo]] <- as.character(sem1[[campo]])
  esperado
}

comparar_referencia_prisional <- function(painel, esperado) {
  campos <- names(esperado)
  divergencias <- vapply(campos, function(campo) {
    if (!campo %in% names(painel)) return(nrow(painel))
    valor <- painel[[campo]]
    alvo <- esperado[[campo]]
    igual <- (is.na(valor) & is.na(alvo)) | (!is.na(valor) & !is.na(alvo) & valor == alvo)
    sum(!igual)
  }, integer(1))
  data.frame(campo = campos, divergencias = unname(divergencias), stringsAsFactors = FALSE)
}
