"""Conferência reproduzível da classificação cartográfica adotada em 24/11/2026.

Não altera fatos, SQL ou configuração do painel. Lê o pacote validado, verifica
os cortes do SQL contra o catálogo e registra contagens de classes. A comparação
com contagens e hash congelados é intencional: uma edição nova dos dados exige
revisar os controles, não simplesmente regenerar um resultado com aparência de
aprovação. Usa somente a biblioteca padrão do Python.

Executar da raiz do repositório:
    python scripts/exploratory/validar_escala_mapa_criminal.py
"""

from __future__ import annotations

import argparse
from bisect import bisect_left
from collections import Counter, defaultdict
import csv
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / "outputs/auditoria/mapa_criminal_candidata_bigquery_2026-11-24/escala_comum"
DEFAULT_FACTS = ROOT / "outputs/temp/mapa_criminal_ibge_teste_2026-11-23/fatos_criminais.csv"
EXPECTED_SHA256 = "256f9b413c910d35f0d3489fdace9f0f85e2f1f543da3399cb105938eb4b0881"
# Contagens calculadas independentemente sobre o pacote antes da criação da view.
# Cada lista contém zero e as cinco faixas positivas em 2022 + 2025.
EXPECTED_PAIR_COUNTS = {
    "Vítimas de homicídio doloso": [550, 123, 136, 73, 76, 36],
    "Estupros - total": [154, 189, 217, 236, 110, 88],
    "Total de roubo - outros": [396, 170, 148, 138, 83, 59],
    "Total de furto - outros": [2, 269, 220, 257, 129, 117],
    "Flagrantes da Polícia Civil": [92, 220, 231, 238, 128, 85],
    "Mandados de prisão cumpridos": [539, 102, 100, 136, 67, 50],
}
PALETTE = ["#FFFFFF", "#FFFFB2", "#FECC5C", "#FD8D3C", "#F03B20", "#BD0026"]


def require(condition: bool, description: str) -> None:
    if not condition:
        raise AssertionError(description)


def classify(value: float, cuts: list[int]) -> int:
    """bisect_left inclui o limite superior na classe, como os <= do SQL."""
    require(math.isfinite(value) and value >= 0, "Taxa deve ser finita e não negativa")
    return 0 if value == 0 else bisect_left(cuts, value) + 1


def labels(cuts: list[int]) -> list[str]:
    return [
        "0. Taxa zero",
        f"1. >0 a {cuts[0]}",
        f"2. >{cuts[0]} a {cuts[1]}",
        f"3. >{cuts[1]} a {cuts[2]}",
        f"4. >{cuts[2]} a {cuts[3]}",
        f"5. >{cuts[3]}",
    ]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--facts", type=Path, default=DEFAULT_FACTS)
    parser.add_argument("--evidence", type=Path, default=EVIDENCE)
    args = parser.parse_args()
    evidence = args.evidence.resolve()
    require(evidence.is_dir(), "Pasta de evidências não encontrada")
    source_hash = hashlib.sha256(args.facts.read_bytes()).hexdigest()
    require(source_hash == EXPECTED_SHA256, "CSV diferente do pacote validado; revisar a edição e os controles")

    catalog = json.loads((evidence / "cortes.json").read_text(encoding="utf-8-sig"))
    cuts = {entry["indicador"]: entry["c"] for entry in catalog}
    require(len(cuts) == len(catalog) == 6, "Catálogo deve ter seis indicadores únicos")
    require(set(cuts) == set(EXPECTED_PAIR_COUNTS), "Universo de indicadores inesperado")
    boundary_checks = 0
    for indicator, bounds in cuts.items():
        require(len(bounds) == 4 and all(type(v) is int and v > 0 for v in bounds), f"Cortes inválidos: {indicator}")
        require(bounds == sorted(set(bounds)), f"Cortes sem ordem estrita: {indicator}")
        require(classify(0, bounds) == 0, "Zero saiu da classe exclusiva")
        require(classify(math.nextafter(0, math.inf), bounds) == 1, "Positivo mínimo foi classificado como zero")
        require(classify(bounds[-1] * 1000, bounds) == 5, "Classe superior não comporta valores extremos")
        boundary_checks += 3
        for ordinal, boundary in enumerate(bounds, start=1):
            require(classify(boundary, bounds) == ordinal, f"Erro no limite superior: {indicator}/{boundary}")
            require(classify(math.nextafter(boundary, -math.inf), bounds) == ordinal, "Erro imediatamente abaixo do corte")
            require(classify(math.nextafter(boundary, math.inf), bounds) == ordinal + 1, "Erro imediatamente acima do corte")
            boundary_checks += 3

    sql = (evidence / "view_candidata.sql").read_text(encoding="utf-8-sig")
    sql_pattern = re.compile(
        r"SELECT '((?:''|[^'])+)' AS indicador, (\d+) AS c1, (\d+) AS c2, (\d+) AS c3, (\d+) AS c4"
    )
    sql_cuts = {name.replace("''", "'"): [int(x) for x in values] for name, *values in sql_pattern.findall(sql)}
    require(sql_cuts == cuts, "Cortes publicados no SQL divergem do catálogo")
    compact_sql = " ".join(sql.split())
    required_case = "CASE WHEN taxa = 0 THEN 0 WHEN taxa <= c1 THEN 1 WHEN taxa <= c2 THEN 2 WHEN taxa <= c3 THEN 3 WHEN taxa <= c4 THEN 4 ELSE 5 END"
    require(required_case in compact_sql, "Condições da classificação SQL divergentes")
    require("LEFT JOIN cortes USING (indicador)" in compact_sql, "Os cortes não dependem exclusivamente do indicador")
    require("SELECT origem.*, c1, c2, c3, c4" in compact_sql, "SQL deixou de preservar os campos da origem")
    require("SELECT * EXCEPT(c1,c2,c3,c4)" in compact_sql, "Projeção final inesperada")
    require("NULLIF" not in compact_sql.upper(), "SQL voltou a converter zero em ausência")

    expected_colors = {}
    for bounds in cuts.values():
        for ordinal, label in enumerate(labels(bounds)):
            if label in expected_colors:
                require(expected_colors[label] == PALETTE[ordinal], "Rótulo compartilhado tem cor ambígua")
            expected_colors[label] = PALETTE[ordinal]
    configured = json.loads((evidence / "cores.json").read_text(encoding="utf-8-sig"))
    observed = json.loads((evidence / "cores_conferidas.json").read_text(encoding="utf-8-sig"))
    require({r["label"]: r["cor"] for r in configured} == expected_colors, "Catálogo de cores incompleto ou divergente")
    require(len(configured) == len(expected_colors), "Rótulos de cor duplicados")
    require({r["label"]: r["cor"] for r in observed} == expected_colors, "Cores conferidas na interface divergem das previstas")
    require(len(observed) == len(expected_colors), "Leitura de cores contém duplicados")
    for row in observed:
        rgb = tuple(int(row["cor"][i:i+2], 16) for i in (1, 3, 5))
        require(row["rgb"] == f"rgb{rgb}", f"Hex/RGB incompatíveis: {row['label']}")

    with args.facts.open(encoding="utf-8-sig", newline="") as stream:
        facts = list(csv.DictReader(stream))
    require(len(facts) == 11928, "Quantidade de fatos inesperada")
    keys = [(r["id_municipio"], r["ano"], r["indicador"]) for r in facts]
    require(len(set(keys)) == len(keys), "Chave município/ano/indicador duplicada")
    grid = defaultdict(set)
    bins = defaultdict(list)
    pair_counts = {indicator: [0] * 6 for indicator in cuts}
    zero_unreported = Counter()
    repeated_rate_categories = defaultdict(set)
    repeated_rate_scopes = defaultdict(set)
    zero_count = 0
    for row in facts:
        indicator = row["indicador"]
        require(indicator in cuts, "Indicador sem cortes")
        year = int(row["ano"])
        require(year in range(2022, 2026), "Ano fora da janela validada")
        value = float(row["taxa"])
        ordinal = classify(value, cuts[indicator])
        grid[(year, indicator)].add(row["id_municipio"])
        bins[(year, indicator, ordinal)].append(row)
        pair = (indicator, value.hex())
        repeated_rate_categories[pair].add(ordinal)
        repeated_rate_scopes[pair].add((year, row["regiao"]))
        if year in (2022, 2025):
            pair_counts[indicator][ordinal] += 1
            if ordinal == 0 and row["quantidade_informada"] == "FALSE":
                zero_unreported[indicator] += 1
        if ordinal == 0:
            zero_count += 1
            require(float(row["quantidade"]) == 0, "Taxa zero com quantidade positiva")
    require(len(grid) == 24 and all(len(ids) == 497 for ids in grid.values()), "Grade de 24 grupos de 497 municípios incompleta")
    require(zero_count == 3441, "Quantidade de zeros da série divergiu")
    require(pair_counts == EXPECTED_PAIR_COUNTS, "Contagens de classes 2022/2025 divergem do controle independente")
    require(all(sum(v) == 994 for v in pair_counts.values()), "Janela comparada não soma 994 fatos por indicador")
    require(all(len(values) == 1 for values in repeated_rate_categories.values()), "Mesma taxa/indicador recebeu categorias diferentes")
    duplicate_scopes = sum(len(scopes) > 1 for scopes in repeated_rate_scopes.values())
    require(duplicate_scopes > 0, "Não houve casos reais repetidos para conferir invariância territorial/temporal")
    positive_duplicate_scopes = sum(
        len(scopes) > 1 and float.fromhex(pair[1]) > 0
        for pair, scopes in repeated_rate_scopes.items()
    )
    require(positive_duplicate_scopes > 0, "Conferência de invariância só encontrou repetições de zero")
    require(zero_unreported["Flagrantes da Polícia Civil"] == 92, "Cobertura dos zeros de flagrantes divergiu")
    require(zero_unreported["Mandados de prisão cumpridos"] == 175, "Cobertura dos zeros de mandados divergiu")
    require(sum(zero_unreported.values()) == 267, "Cobertura dos demais zeros divergiu")

    # A fonte realmente executada no BigQuery deve reproduzir a classificação
    # calculada aqui; aprovar apenas o texto do SQL não comprovaria a publicação.
    native_export = json.loads((evidence / "validacao_nativa.json").read_text(encoding="utf-8-sig"))
    require(isinstance(native_export, list) and len(native_export) == 1, "Exportação nativa inesperada")
    native = native_export[0]
    for field, expected in {
        "linhas": 11928, "municipios": 497, "classes_ausentes_invalidas": 0,
        "zero_classificado_errado": 0, "divergencias": 0, "rotulos_unicos": 30,
    }.items():
        require(int(native[field]) == expected, f"Controle BigQuery divergente: {field}")
    native_classes = {}
    for row in native["classes"]:
        key = (int(row["ano"]), row["indicador"], int(row["faixa_ordem"]))
        require(key not in native_classes, f"Classe duplicada no BigQuery: {key}")
        require(key[0] in (2022, 2025) and key[1] in cuts and key[2] in range(6), f"Classe nativa inesperada: {key}")
        native_classes[key] = row
    absent_classes = []
    for year in (2022, 2025):
        for indicator in cuts:
            for ordinal, label in enumerate(labels(cuts[indicator])):
                key = (year, indicator, ordinal)
                local_rows = bins[key]
                actual = native_classes.get(key)
                if not local_rows:
                    require(actual is None, f"BigQuery retornou uma classe sem fatos locais: {key}")
                    absent_classes.append(key)
                    continue
                require(actual is not None, f"Classe com fatos ausente no BigQuery: {key}")
                require(actual["faixa_taxa"] == label, f"Rótulo nativo divergente: {key}")
                require(int(actual["municipios"]) == len(local_rows), f"Contagem nativa divergente: {key}")
                rates = [float(row["taxa"]) for row in local_rows]
                require(math.isclose(float(actual["minimo"]), min(rates), rel_tol=1e-12, abs_tol=1e-12), f"Taxa mínima nativa divergente: {key}")
                require(math.isclose(float(actual["maximo"]), max(rates), rel_tol=1e-12, abs_tol=1e-12), f"Taxa máxima nativa divergente: {key}")
    require(len(native_classes) == 71, "Número de classes nativas inesperado")
    require(absent_classes == [(2025, "Total de furto - outros", 0)], "Ausência de classe não explicada pelos fatos locais")
    require(sum(int(row["municipios"]) for row in native_classes.values()) == 5964, "Grupos nativos não somam 497 × 6 × 2 fatos")

    expected_rgb = {row["label"]: row["rgb"] for row in observed}

    def verify_legend(legend: list[dict], expected_labels: set[str], description: str) -> None:
        """Ordem visual pode variar; associação nominal entre faixa/cor é fixa."""
        require(isinstance(legend, list), f"Legenda inválida: {description}")
        require(len(legend) == len({row["faixa"] for row in legend}), f"Faixa duplicada na legenda: {description}")
        require({row["faixa"] for row in legend} == expected_labels, f"Faixas exibidas divergem dos fatos: {description}")
        for row in legend:
            require(row["cor"] == expected_rgb[row["faixa"]], f"Cor da faixa '{row['faixa']}' divergente: {description}")

    legends = json.loads((evidence / "testes_legendas.json").read_text(encoding="utf-8-sig"))
    require(len(legends) == 6 and {row["indicador"] for row in legends} == set(cuts), "Teste de legendas não abrange exatamente seis indicadores")
    legend_checks = 0
    for indicator_test in legends:
        indicator = indicator_test["indicador"]
        require(len(indicator_test["mapas"]) == 2, f"Teste não contém os dois mapas: {indicator}")
        for year, legend in zip((2022, 2025), indicator_test["mapas"], strict=True):
            expected_labels = {
                label for ordinal, label in enumerate(labels(cuts[indicator]))
                if bins[(year, indicator, ordinal)]
            }
            verify_legend(legend, expected_labels, f"{indicator}/{year}/RS")
            legend_checks += 1

    region_test = json.loads((evidence / "teste_ijui.json").read_text(encoding="utf-8-sig"))
    require(region_test["regiao"] == "Ijuí" and region_test["indicador"] == "Mandados de prisão cumpridos", "Teste regional inesperado")
    require(len(region_test["mapas"]) == 2, "Teste de Ijuí não contém os dois mapas")
    regional_counts = {}
    for year, legend in zip((2022, 2025), region_test["mapas"], strict=True):
        indicator = region_test["indicador"]
        counts = [
            sum(row["regiao"] == region_test["regiao"] for row in bins[(year, indicator, ordinal)])
            for ordinal in range(6)
        ]
        require(sum(counts) > 0, f"Região sem municípios no CSV: {year}")
        expected_labels = {label for ordinal, label in enumerate(labels(cuts[indicator])) if counts[ordinal]}
        verify_legend(legend, expected_labels, f"{indicator}/{year}/Ijuí")
        regional_counts[year] = counts
        legend_checks += 1

    output = evidence / "validacao_local"
    output.mkdir(exist_ok=True)
    with (output / "contagens_faixas.csv").open("w", encoding="utf-8", newline="") as stream:
        fields = ["ano", "indicador", "faixa_ordem", "faixa_taxa", "cor", "municipios", "taxa_minima", "taxa_maxima", "zeros_nao_informados"]
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        for year, indicator in sorted(grid):
            for ordinal, label in enumerate(labels(cuts[indicator])):
                rows = bins[(year, indicator, ordinal)]
                values = [float(r["taxa"]) for r in rows]
                writer.writerow({
                    "ano": year, "indicador": indicator, "faixa_ordem": ordinal,
                    "faixa_taxa": label, "cor": PALETTE[ordinal], "municipios": len(rows),
                    "taxa_minima": min(values) if values else "",
                    "taxa_maxima": max(values) if values else "",
                    "zeros_nao_informados": sum(ordinal == 0 and r["quantidade_informada"] == "FALSE" for r in rows),
                })
    result = {
        "status": "aprovado", "gerado_utc": datetime.now(timezone.utc).isoformat(),
        "fonte": args.facts.resolve().relative_to(ROOT).as_posix(), "sha256": source_hash,
        "registros": len(facts), "grupos_ano_indicador": len(grid), "municipios_por_grupo": 497,
        "testes_de_limite": boundary_checks, "rotulos_com_cores_conferidas": len(expected_colors),
        "taxas_zero_2022_2025_serie_completa": zero_count,
        "pares_indicador_taxa_repetidos_em_mais_de_um_ano_ou_regiao": duplicate_scopes,
        "pares_positivos_repetidos_em_mais_de_um_ano_ou_regiao": positive_duplicate_scopes,
        "contagens_2022_e_2025": pair_counts,
        "zeros_com_quantidade_nao_informada_2022_e_2025": dict(zero_unreported),
        "bigquery": {
            "classes_reconciliadas": len(native_classes),
            "fatos_reconciliados_no_par_2022_2025": 5964,
            "classes_ausentes_com_contagem_local_zero": absent_classes,
            "divergencias_numeradores_denominadores_taxas_geometrias": int(native["divergencias"]),
        },
        "interface": {
            "legendas_conferidas": legend_checks,
            "indicadores_estaduais_conferidos": len(legends),
            "anos_dos_mapas_na_ordem_das_evidencias": [2022, 2025],
            "contagens_locais_por_faixa_no_teste_ijui": regional_counts,
            "cores_nominais_divergentes": 0,
        },
        "notas": [
            "As classes dependem somente do indicador e da taxa, com cortes fixos nos dois anos e em qualquer território.",
            "A classe zero inclui contagens não informadas convertidas em zero pela regra do projeto.",
            "O CSV de contagens inclui 24 grupos anuais e seis classes por grupo, inclusive classes vazias.",
            "A conferência reconcilia os arquivos obrigatórios exportados do BigQuery e das legendas da interface; não executa uma consulta nova nem controla o navegador.",
            "A geometria não é revalidada neste teste de classificação.",
        ],
    }
    (output / "resultado.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": result["status"], "registros": len(facts), "grupos": len(grid), "testes_limite": boundary_checks, "saida": str(output)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
