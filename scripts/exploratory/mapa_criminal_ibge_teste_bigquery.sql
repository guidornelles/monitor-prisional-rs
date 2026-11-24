-- Pacote de teste: malha IBGE 2022 + fatos criminais validados de 2022 a 2025.
-- Não executado automaticamente. Substituir __PROJECT_ID__ por um projeto
-- autorizado com faturamento vinculado antes de executar no BigQuery.
-- Criar um dataset isolado chamado monitor_rs_mapa_teste_20261123 e carregar:
--   fatos_criminais.csv -> fatos_criminais (schema_fatos_bigquery.json)
--   geometrias_municipais_bq.csv -> geometrias_raw (schema_geometrias_bigquery.json)
-- Usar CSV UTF-8, separador vírgula, cabeçalho de uma linha e campos com aspas.
-- As tabelas de origem deste pacote são de teste; nenhuma tabela da candidata
-- ou do projeto paulista é referenciada ou modificada.

ASSERT (
  SELECT COUNT(*) = 497 AND COUNT(DISTINCT id_municipio) = 497
  FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.geometrias_raw`
) AS 'A malha deve conter exatamente 497 IDs municipais únicos';

ASSERT (
  SELECT COUNT(*) = 11928
  FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.fatos_criminais`
) AS 'Esperados 497 municipios x 4 anos x 6 indicadores';

ASSERT NOT EXISTS (
  SELECT ano, indicador
  FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.fatos_criminais`
  GROUP BY ano, indicador
  HAVING COUNT(*) != 497 OR COUNT(DISTINCT id_municipio) != 497
) AS 'Cada combinacao ano e indicador deve conter os mesmos 497 municipios';

ASSERT NOT EXISTS (
  SELECT 1
  FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.fatos_criminais`
  WHERE ano NOT BETWEEN 2022 AND 2025 OR quantidade IS NULL
     OR populacao IS NULL OR populacao <= 0 OR taxa IS NULL
) AS 'Fatos devem preservar cobertura e valores do CSV validado';

ASSERT NOT EXISTS (
  SELECT 1
  FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.fatos_criminais` f
  LEFT JOIN `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.geometrias_raw` g
  USING (id_municipio)
  WHERE g.id_municipio IS NULL
) AS 'Nenhum fato pode ficar sem geometria por codigo IBGE';

-- SAFE devolve NULL em caso de erro: o ASSERT seguinte impede sua aceitação.
-- Não usar make_valid para ocultar ou reparar silenciosamente erros da carga.
CREATE OR REPLACE TABLE
  `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.geometrias_municipais` AS
SELECT id_municipio, nome, nome_malha_ibge, uf, ano_malha,
       SAFE.ST_GEOGFROMTEXT(geometry_wkt) AS geometria
FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.geometrias_raw`;

ASSERT NOT EXISTS (
  SELECT 1
  FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.geometrias_municipais`
  WHERE geometria IS NULL OR ST_ISEMPTY(geometria)
) AS 'A carga deve produzir 497 geometrias nao vazias';

ASSERT (
  SELECT SUM(ST_NUMPOINTS(geometria)) <= 1000000
  FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.geometrias_municipais`
) AS 'O recorte de um ano e um indicador deve caber no limite da camada';

CREATE OR REPLACE VIEW
  `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.mapa_criminal_ibge` AS
SELECT f.id_municipio, f.nome, f.regiao, f.ano, f.indicador,
       f.quantidade, f.populacao, f.taxa,
       f.quantidade_informada, f.meses_informados,
       g.ano_malha, g.geometria,
       CONCAT(f.nome, ', Rio Grande do Sul, Brasil') AS local_google
FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.fatos_criminais` f
JOIN `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.geometrias_municipais` g
USING (id_municipio);

-- Esta consulta deve retornar 497 feições e um total inferior a 1 milhão.
SELECT COUNT(*) AS municipios, SUM(ST_NUMPOINTS(geometria)) AS vertices,
       COUNTIF(geometria IS NULL OR ST_ISEMPTY(geometria)) AS geometrias_ausentes
FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.mapa_criminal_ibge`
WHERE ano = 2025 AND indicador = 'Total de furto - outros';

-- Caso acompanhado na candidata: 691 furtos, população 84.421 e taxa 818,52.
SELECT id_municipio, nome, ano, indicador, quantidade, populacao, taxa,
       ST_NUMPOINTS(geometria) AS vertices, ST_AREA(geometria) / 1e6 AS area_km2
FROM `__PROJECT_ID__.monitor_rs_mapa_teste_20261123.mapa_criminal_ibge`
WHERE id_municipio = '4317103' AND ano = 2025
  AND indicador = 'Total de furto - outros';
