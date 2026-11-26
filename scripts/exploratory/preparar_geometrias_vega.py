"""Gera paths SVG de malha integral para ensaio isolado no Vega/Data Studio.

Todos os municípios usam a mesma projeção e transformação afim. Não simplifica,
suprime ou reordena vértices, partes e anéis; arredonda somente as coordenadas de
exibição a seis casas decimais. Não publica tabelas/views nem altera fatos.

Exemplo:
    python scripts/exploratory/preparar_geometrias_vega.py
"""

from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import gzip
import hashlib
import json
import math
from pathlib import Path
import statistics


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = ROOT / "outputs/temp/mapa_criminal_ibge_teste_2026-11-23/geo_municipios_rs_2022.geojson"
DEFAULT_OUTPUT = ROOT / "outputs/auditoria/teste_vega_candidata_2026-11-25"
EXPECTED_SOURCE_SHA256 = "41e6480c9c63110eb7ee435866a4f9e9bb178f89c3fca33c680b8fdd89db7644"


def require(condition, description):
    if not condition:
        raise AssertionError(description)


def projection(point):
    """Mesma fórmula do template HTML do protótipo; raio de exibição 1000."""
    lon, lat = point[:2]
    require(math.isfinite(lon) and math.isfinite(lat), "Coordenada não finita")
    lat_radians = math.radians(max(-85, min(85, lat)))
    return math.radians(lon) * 1000, -math.log(math.tan(math.pi / 4 + lat_radians / 2)) * 1000


def parts(geometry):
    require(geometry["type"] in ("Polygon", "MultiPolygon"), "Geometria não poligonal")
    return [geometry["coordinates"]] if geometry["type"] == "Polygon" else geometry["coordinates"]


def signed_area(points):
    return math.fsum(a[0] * b[1] - b[0] * a[1] for a, b in zip(points, points[1:])) / 2


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--width", type=int, default=1000)
    parser.add_argument("--height", type=int, default=1000)
    parser.add_argument("--precision", type=int, default=6)
    parser.add_argument("--padding-ratio", type=float, default=0.045)
    args = parser.parse_args()
    require(args.width > 0 and args.height > 0 and 3 <= args.precision <= 12, "Dimensões/precisão inválidas")
    require(args.padding_ratio >= 0, "Padding negativo")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    source_bytes = args.source.read_bytes()
    source_hash = hashlib.sha256(source_bytes).hexdigest()
    if EXPECTED_SOURCE_SHA256:
        require(source_hash == EXPECTED_SOURCE_SHA256, "Edição da geometria diferente da validada")
    data = json.loads(source_bytes)
    require(data["type"] == "FeatureCollection" and len(data["features"]) == 497, "Esperadas 497 feições municipais")
    features = data["features"]
    ids = [str(feature["properties"]["id_municipio"]) for feature in features]
    require(len(set(ids)) == 497 and all(len(value) == 7 and value.isdigit() for value in ids), "IDs municipais inválidos")

    projected = {}
    vertices = polygons = rings_count = holes = 0
    for feature in features:
        for polygon in parts(feature["geometry"]):
            polygons += 1
            holes += len(polygon) - 1
            for ring in polygon:
                rings_count += 1
                require(len(ring) >= 4 and ring[0][:2] == ring[-1][:2], "Anel inválido ou não fechado")
                for point in ring:
                    vertices += 1
                    key = tuple(point[:2])
                    if key not in projected:
                        projected[key] = projection(point)
    require(vertices == 619347, "Quantidade de vértices diferente da malha validada")
    xmin = min(point[0] for point in projected.values())
    ymin = min(point[1] for point in projected.values())
    xmax = max(point[0] for point in projected.values())
    ymax = max(point[1] for point in projected.values())
    padding = max(xmax - xmin, ymax - ymin) * args.padding_ratio
    padded = (xmin - padding, ymin - padding, xmax + padding, ymax + padding)
    scale = min(args.width / (padded[2] - padded[0]), args.height / (padded[3] - padded[1]))
    offset_x = (args.width - (padded[2] - padded[0]) * scale) / 2 - padded[0] * scale
    offset_y = (args.height - (padded[3] - padded[1]) * scale) / 2 - padded[1] * scale

    def format_coordinate(value):
        formatted = f"{value:.{args.precision}f}".rstrip("0").rstrip(".")
        return "0" if formatted == "-0" else formatted

    normalized = {}
    max_display_error = 0
    for key, (x, y) in projected.items():
        display = (x * scale + offset_x, y * scale + offset_y)
        formatted = tuple(format_coordinate(value) for value in display)
        rounded = tuple(float(value) for value in formatted)
        require(0 <= rounded[0] <= args.width and 0 <= rounded[1] <= args.height, "Coordenada fora do canvas")
        max_display_error = max(max_display_error, math.dist(display, rounded))
        normalized[key] = (formatted, rounded)
    error_bound_display = math.sqrt(2) * 0.5 * 10 ** (-args.precision)
    require(max_display_error <= error_bound_display * 1.00001, "Erro de arredondamento acima do limite")
    bbox = (
        min(value[1][0] for value in normalized.values()),
        min(value[1][1] for value in normalized.values()),
        max(value[1][0] for value in normalized.values()),
        max(value[1][1] for value in normalized.values()),
    )

    rows = []
    per_city = []
    paths_vertices = paths_rings = 0
    orientation_issues = []
    all_outer_signs = set()
    for feature in features:
        properties = feature["properties"]
        commands = []
        city_vertices = city_polygons = city_rings = city_holes = 0
        for polygon in parts(feature["geometry"]):
            city_polygons += 1
            city_holes += len(polygon) - 1
            outer_sign = None
            for ring_index, ring in enumerate(polygon):
                city_rings += 1
                rounded_points = []
                for index, point in enumerate(ring):
                    formatted, rounded = normalized[tuple(point[:2])]
                    commands.append(("M" if index == 0 else "L") + formatted[0] + "," + formatted[1])
                    rounded_points.append(rounded)
                    city_vertices += 1
                commands.append("Z")
                area = signed_area(rounded_points)
                require(area != 0, "Anel degenerado após projeção/arredondamento")
                sign = 1 if area > 0 else -1
                if ring_index == 0:
                    outer_sign = sign
                    all_outer_signs.add(sign)
                elif sign == outer_sign:
                    orientation_issues.append({"id_municipio": properties["id_municipio"], "anel": ring_index})
        path = "".join(commands)
        require(path.count("M") + path.count("L") == city_vertices, "Path perdeu vértices")
        require(path.count("M") == path.count("Z") == city_rings, "Path perdeu anéis")
        paths_vertices += city_vertices
        paths_rings += city_rings
        rows.append({
            "id_municipio": properties["id_municipio"], "geometria_svg": path,
            "svg_width": args.width, "svg_height": args.height,
            "svg_bbox_xmin": bbox[0], "svg_bbox_ymin": bbox[1],
            "svg_bbox_xmax": bbox[2], "svg_bbox_ymax": bbox[3],
        })
        per_city.append({
            "id_municipio": properties["id_municipio"], "nome": properties["nome"],
            "vertices": city_vertices, "partes": city_polygons, "aneis": city_rings, "furos": city_holes,
            "bytes_path_svg": len(path.encode("ascii")),
        })
    require(paths_vertices == vertices and paths_rings == rings_count, "Contagens globais dos paths divergentes")
    require(not orientation_issues, "Anéis internos com mesma orientação que o exterior; revisar preenchimento nonzero")
    # O CSV contém uma linha por município, sem geometria repetida por ano/indicador.
    csv_path = output / "geometrias_svg.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    csv.field_size_limit(10_000_000)
    with csv_path.open(encoding="utf-8", newline="") as stream:
        reread = list(csv.DictReader(stream))
    require(len(reread) == 497 and {row["id_municipio"] for row in reread} == set(ids), "Releitura CSV perdeu municípios")
    require(all(row["geometria_svg"] == original["geometria_svg"] for row, original in zip(reread, rows, strict=True)), "Releitura CSV alterou paths")

    schema = [
        {"name": name, "type": "STRING" if name in ("id_municipio", "geometria_svg") else "INTEGER" if name in ("svg_width", "svg_height") else "FLOAT", "mode": "REQUIRED"}
        for name in rows[0]
    ]
    (output / "schema_geometrias_svg_bigquery.json").write_text(json.dumps(schema, indent=2) + "\n", encoding="utf-8")
    with (output / "geometrias_svg_contagens.csv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(per_city[0]))
        writer.writeheader()
        writer.writerows(sorted(per_city, key=lambda row: row["bytes_path_svg"], reverse=True))

    payload = csv_path.read_bytes()
    path_sizes = [row["bytes_path_svg"] for row in per_city]
    # Mercator de exibição usa raio 1000; Web Mercator métrico usa 6.378.137 m.
    metric_factor = 6378137 / 1000 / scale
    manifest = {
        "gerado_utc": datetime.now(timezone.utc).isoformat(),
        "fonte": args.source.resolve().relative_to(ROOT).as_posix(), "fonte_sha256": source_hash,
        "arquivo_csv": csv_path.relative_to(ROOT).as_posix(),
        "csv_sha256": hashlib.sha256(payload).hexdigest(),
        "municipios": 497, "vertices_origem": vertices, "vertices_paths": paths_vertices,
        "partes_origem": polygons, "aneis_origem": rings_count, "aneis_paths": paths_rings, "furos": holes,
        "coordenadas_unicas_origem": len(projected), "repeticoes_de_coordenadas_compartilhadas_ou_fechamentos": vertices - len(projected),
        "simplificacao": False, "reordenacao_de_vertices_ou_aneis": False,
        "precisao_decimal_path": args.precision,
        "projecao": {
            "formula": "x = longitude_rad * 1000; y = -log(tan(pi/4 + latitude_rad/2)) * 1000; latitude limitada a [-85,85]",
            "mesma_formula_do_prototipo_html": True,
            "bbox_mercator_raio_1000": [xmin, ymin, xmax, ymax],
            "padding_fracao_maior_lado": args.padding_ratio, "padding_unidades_projetadas": padding,
            "bbox_mercator_com_padding": list(padded),
            "transformacao": {"escala_isotropica": scale, "offset_x": offset_x, "offset_y": offset_y},
        },
        "canvas": {"width": args.width, "height": args.height, "viewBox": [0, 0, args.width, args.height], "bbox_global_paths": list(bbox)},
        "arredondamento": {
            "erro_maximo_observado_unidades_svg": max_display_error,
            "limite_superior_unidades_svg": error_bound_display,
            "erro_maximo_observado_metros_no_plano_web_mercator": max_display_error * metric_factor,
            "limite_superior_metros_no_plano_web_mercator": error_bound_display * metric_factor,
            "nota": "Erro numérico da exibição, não medida de precisão posicional da malha. A distância no terreno é menor que a distância do plano Mercator nesta latitude.",
        },
        "orientacao": {"sinais_dos_aneis_exteriores": sorted(all_outer_signs), "furos_com_sinal_oposto_ao_exterior": holes, "problemas": orientation_issues, "preenchimento_nonzero_preserva_furos": True},
        "tamanho": {
            "csv_bytes": len(payload), "csv_gzip_estimado_bytes": len(gzip.compress(payload, mtime=0)),
            "soma_bytes_paths": sum(path_sizes), "maximo_bytes_path": max(path_sizes),
            "mediana_bytes_path": statistics.median(path_sizes), "maiores_10": sorted(per_city, key=lambda row: row["bytes_path_svg"], reverse=True)[:10],
        },
        "notas": [
            "Cada ponto original gera um comando M ou L; Z fecha cada anel. Não houve simplificação ou remoção de vértices repetidos.",
            "Uma transformação global e um cache por coordenada original garantem a mesma posição para divisas compartilhadas.",
            "Vega deve usar path = geometria_svg e o canvas de referência 1000 × 1000; escalar os dois eixos igualmente para manter a proporção.",
            "A geometria é de exibição pré-projetada: não usar projeção geográfica novamente no Vega.",
            "Dados criminais, taxas e geometrias canônicas permanecem inalterados. A tabela de teste acrescenta somente representação derivada.",
            "Tamanho gzip é uma estimativa local, não comprova compressão do transporte do Data Studio.",
        ],
    }
    (output / "geometrias_svg_manifesto.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "status": "preparado", "municipios": len(rows), "vertices": vertices, "partes": polygons, "aneis": rings_count, "furos": holes,
        "dimensoes": manifest["canvas"], "bytes_csv": len(payload), "bytes_maior_path": max(path_sizes),
        "erro_maximo_metros_mercator": max_display_error * metric_factor,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
