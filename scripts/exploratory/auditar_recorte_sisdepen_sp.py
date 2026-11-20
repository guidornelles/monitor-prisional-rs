"""Audit the SP export against SISDEPEN cycles without changing either input.

Uses only the Python standard library. Outputs selected comparisons and aggregates,
never a replacement prison database or an automatic entity crosswalk.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import html
import io
import json
import re
import subprocess
import unicodedata
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from pathlib import Path
from zipfile import ZipFile


SP_COMMIT = "45c714419387a1b85f92df459de7399a7dedaec5"
SP_DATA_COMMIT = "4db9d98a83f1c80fa7e73746578e14b42690ef8f"  # local sem_02 snapshot
ROW = re.compile(rb"<(?:\w+:)?row\b[^>]*>(.*?)</(?:\w+:)?row>", re.S)
# A self-closing empty cell must not consume the value of the following cell.
CELL = re.compile(rb"<(?:\w+:)?c\b([^>]*?)(?<!/)>(.*?)</(?:\w+:)?c>", re.S)
VALUE = re.compile(rb"<(?:\w+:)?v>(.*?)</(?:\w+:)?v>", re.S)
TEXT = re.compile(rb"<(?:\w+:)?t\b[^>]*>(.*?)</(?:\w+:)?t>", re.S)
ADDRESS = re.compile(rb'\br="([A-Z]+)\d+"')
POP = "4.1 População prisional | Total"
CAP_M = "1.3 Capacidade do estabelecimento | Masculino | Total"
CAP_F = "1.3 Capacidade do estabelecimento | Feminino | Total"
TYPE = "Tipo de Recolhimento"
NAME = "Nome do Estabelecimento"
FACT = "1.2 Tipo de estabelecimento - originalmente destinado"
MORTALITY = {
    "saude": "Óbitos naturais/ óbitos por motivos de saúde",
    "criminais": "Óbitos criminais",
    "suicidio": "Óbitos suicídios",
    "acidentais": "Óbitos acidentais",
    "desconhecida": "Óbitos com causa desconhecida",
}
FLOWS = {
    "consultas_internas": "6.6 Informações da área de saúde - total do período | Consultas médicas realizadas no estabelecimento | Total",
    "consultas_externas": "6.6 Informações da área de saúde - total do período | Consultas médicas realizadas externamente | Total",
    "consultas_odonto": "6.6 Informações da área de saúde - total do período | Consultas odontológicas | Total",
    "lactantes": "5.9 Faixa etária dos filhos que estão no estabelecimento (aplicável apenas para estabelecimentos com mulheres) | Quantidade de lactantes",
}
MORT_FIELDS = {
    f"obitos_{cause}_{sex.lower()}":
    f"6.8 Mortalidade no Sistema Prisional (total do período) | {label} | {sex}"
    for cause, label in MORTALITY.items()
    for sex in ("Masculino", "Feminino", "Total")
}
SELECTED = [
    "UF", "ID", "ciclo", "Referência", NAME, TYPE, FACT,
    "Situação do Estabelecimento", "Outras Denominações", "Endereço", "CEP",
    "Município", "Código IBGE", POP, CAP_M, CAP_F, *FLOWS.values(), *MORT_FIELDS.values(),
]


def fold(value):
    text = unicodedata.normalize("NFKD", value or "")
    return " ".join("".join(c for c in text if not unicodedata.combining(c)).upper().split())


def base_name(value):
    # Only remove an explicitly marked modality suffix. Preserve sex, prison
    # numbers, titles and all other distinctions between physical establishments.
    return re.split(r"\s*-\s*(?=DOMICILIAR|MONITORAMENTO|MONITORACAO)", fold(value), maxsplit=1)[0]


def name_modality(value):
    name = fold(value)
    domiciliary = "DOMICILIAR" in name
    monitored = "MONITORAMENTO ELETRONICO" in name or "MONITORACAO ELETRONICA" in name
    if domiciliary and monitored:
        return "domiciliar_e_monitoramento_no_nome"
    if domiciliary:
        return "domiciliar_no_nome"
    if monitored:
        return "monitoramento_no_nome"
    return "sem_marcador_no_nome"


def strict_physical(row):
    return row.get(TYPE) == "Cela física" and name_modality(row[NAME]) == "sem_marcador_no_nome"


def number(value):
    if value == "" or value is None:
        return 0
    parsed = float(value)
    if not parsed.is_integer():
        raise ValueError(f"Noninteger prison count {value!r}")
    return int(parsed)


def capacity(row):
    return number(row.get(CAP_M, "")) + number(row.get(CAP_F, ""))


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def git_bytes(repo, spec):
    return subprocess.check_output(["git", "-C", str(repo), "show", spec])


def read_selected_xlsx(source, reference=None):
    """Stream complete XML rows, decoding only SP rows after reading the header."""
    with ZipFile(source) as book:
        strings = []
        if "xl/sharedStrings.xml" in book.namelist():
            strings = ["".join(item.itertext()) for item in ET.fromstring(book.read("xl/sharedStrings.xml"))]

        def decode(row):
            cells = {}
            for attributes, inner in CELL.findall(row):
                location = ADDRESS.search(attributes)
                if not location:
                    continue
                value = VALUE.search(inner)
                if value:
                    token = value.group(1).decode("utf-8")
                    cells[location.group(1)] = strings[int(token)] if b't="s"' in attributes else html.unescape(token)
                elif b't="inlineStr"' in attributes:
                    cells[location.group(1)] = "".join(html.unescape(t.decode("utf-8")) for t in TEXT.findall(inner))
            return cells

        buffer = b""
        headers = None
        rows = []
        with book.open("xl/worksheets/sheet1.xml") as sheet:
            while block := sheet.read(4 * 1024 * 1024):
                buffer += block
                endings = list(re.finditer(rb"</(?:\w+:)?row>", buffer))
                if not endings:
                    continue
                end = endings[-1].end()
                complete, buffer = buffer[:end], buffer[end:]
                for raw_row in ROW.findall(complete):
                    values = decode(raw_row) if headers is None else None
                    if headers is None:
                        headers = {label: col for col, label in values.items()}
                        if "UF" not in headers:
                            raise ValueError("First row has no UF field")
                        uf_column = headers["UF"]
                        uf_pattern = re.compile(
                            rb'<(?:\w+:)?c\b([^>]*\br="' + uf_column +
                            rb'\d+"[^>]*)>(.*?)</(?:\w+:)?c>', re.S
                        )
                        continue
                    # UF occurs in a different column across historical files.
                    uf_cell = uf_pattern.search(raw_row)
                    if uf_cell is None:
                        continue
                    uf_values = decode(b"<c " + uf_cell.group(1) + b">" + uf_cell.group(2) + b"</c>")
                    if uf_values.get(uf_column) != "SP":
                        continue
                    values = decode(raw_row)
                    row = {label: values.get(headers.get(label), "") for label in SELECTED}
                    row["Referência"] = reference or row["Referência"]
                    if re.fullmatch(r"(?:201[7-9]|202[0-5])/[12]", row["Referência"]):
                        rows.append(row)
        return rows, set(headers)


def aggregate(rows):
    output = {
        "registros": len(rows),
        "ids_distintos": len({row["ID"] for row in rows if row["ID"]}),
        "populacao": sum(number(row[POP]) for row in rows),
        "capacidade": sum(capacity(row) for row in rows),
        "populacao_ausente": sum(not row[POP] for row in rows),
        "capacidade_ambos_sexos_ausente": sum(not row[CAP_M] and not row[CAP_F] for row in rows),
        "endereco_ausente": sum(not row["Endereço"].strip() for row in rows),
    }
    for label, source in FLOWS.items():
        output[label] = sum(number(row[source]) for row in rows)
    for cause in MORTALITY:
        column = MORT_FIELDS[f"obitos_{cause}_total"]
        output[f"obitos_{cause}"] = sum(number(row[column]) for row in rows)
    output["obitos_total"] = sum(output[f"obitos_{cause}"] for cause in MORTALITY)
    return output


def write_csv(path, rows):
    if not rows:
        return
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def association_rows(rows):
    output = []
    for ref in ("2020/1", "2020/2", "2021/1", "2021/2"):
        cycle = [r for r in rows if r["Referência"] == ref]
        for row in cycle:
            if strict_physical(row):
                continue
            same_base = [r for r in cycle if base_name(r[NAME]) == base_name(row[NAME])
                         and r["Código IBGE"] == row["Código IBGE"]]
            name_only = [r for r in cycle if base_name(r[NAME]) == base_name(row[NAME])]
            physical_base = [r for r in same_base if strict_physical(r)]
            physical_address = [r for r in cycle if strict_physical(r) and row["Endereço"].strip()
                                and fold(r["Endereço"]) == fold(row["Endereço"])
                                and r["Código IBGE"] == row["Código IBGE"]]
            output.append({
                "referencia": ref, "id": row["ID"], "tipo_nativo": row[TYPE],
                "modalidade_nome": name_modality(row[NAME]), "nome": row[NAME],
                "municipio": row["Município"], "tipo_estabelecimento_1_2": row[FACT],
                "codigo_ibge": row["Código IBGE"],
                "populacao": number(row[POP]), "capacidade": capacity(row),
                "endereco": row["Endereço"], "nome_base_candidato": base_name(row[NAME]),
                "registros_mesmo_nome_base_municipio": len(same_base),
                "tipos_nativos_mesmo_nome_base": " ; ".join(sorted({r[TYPE] for r in same_base})),
                "ids_mesmo_nome_base": " ; ".join(sorted(r["ID"] for r in same_base)),
                "registros_mesmo_nome_base_sem_exigir_municipio": len(name_only),
                "ids_mesmo_nome_base_sem_exigir_municipio": " ; ".join(sorted(r["ID"] for r in name_only)),
                "nomes_mesmo_nome_base_sem_exigir_municipio": " ; ".join(r[NAME] for r in name_only),
                "ids_fisicos_mesmo_nome_base": " ; ".join(sorted(r["ID"] for r in physical_base)),
                "nomes_fisicos_mesmo_nome_base": " ; ".join(r[NAME] for r in physical_base),
                "ids_fisicos_mesmo_endereco_municipio": " ; ".join(sorted(r["ID"] for r in physical_address)),
                "ids_fisicos_iguais_ao_id_registro": " ; ".join(r["ID"] for r in cycle if strict_physical(r) and r["ID"] == row["ID"]),
                "limite": "Associação textual para inspeção; não deduplica estabelecimentos ou pessoas",
            })
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    repo = Path(__file__).resolve().parents[2]
    parser.add_argument("--base", type=Path, default=repo / "data/raw/sisdepen/sisdepen_baseunica_2025-2_25032026-163420.xlsx")
    parser.add_argument("--export", type=Path, default=repo / "data/raw/bases_data_studio/base_sisdepen - Sheet1.csv")
    parser.add_argument("--sp-repo", type=Path, default=repo.parent / "MonitorPrisional2024")
    parser.add_argument("--out", type=Path, default=repo / "outputs/tabelas/auditoria_recorte_sisdepen_sp_2026-11-20")
    args = parser.parse_args()
    def input_label(path):
        # Record a portable repository path, never a personal absolute directory.
        try:
            return path.resolve().relative_to(repo).as_posix()
        except ValueError:
            return path.name
    status_before = subprocess.check_output(["git", "-C", str(args.sp_repo), "status", "--porcelain"])
    rows, _ = read_selected_xlsx(args.base)
    with args.export.open(encoding="utf-8-sig", newline="") as stream:
        exported = list(csv.DictReader(stream))
    if any(r["UF"] != "SP" for r in exported):
        raise ValueError("Export contains another UF")
    assert len(rows) == len({(r["ID"], r["Referência"]) for r in rows})
    assert len(exported) == len({r["id"] for r in exported})
    args.out.mkdir(parents=True, exist_ok=True)

    cycle_summary = []
    types_summary = []
    for ref in sorted({r["Referência"] for r in rows}):
        cycle = [r for r in rows if r["Referência"] == ref]
        subsets = {
            "todos": cycle,
            "cela_fisica_rotulo_nativo": [r for r in cycle if r[TYPE] == "Cela física"],
            "cela_fisica_com_salvaguarda_nome": [r for r in cycle if strict_physical(r)],
            "rotulo_fisico_com_nome_domiciliar_monitoramento": [r for r in cycle if r[TYPE] == "Cela física" and not strict_physical(r)],
            "domiciliar_monitorado_rotulo_nativo": [r for r in cycle if r[TYPE] == "Domiciliar com monitoramento eletrônico"],
            "outros_rotulos": [r for r in cycle if r[TYPE] not in ("Cela física", "Domiciliar com monitoramento eletrônico")],
        }
        for label, group in subsets.items():
            cycle_summary.append({"referencia": ref, "universo": label, **aggregate(group)})
        for label in sorted({r[TYPE] for r in cycle}):
            group = [r for r in cycle if r[TYPE] == label]
            types_summary.append({"referencia": ref, "tipo_nativo": label, **aggregate(group)})

    annual = []
    unmatched = []
    for year in range(2017, 2026):
        cycle1 = [r for r in rows if r["Referência"] == f"{year}/1"]
        cycle2 = [r for r in rows if r["Referência"] == f"{year}/2"]
        exp = [r for r in exported if r["periodo"] == str(year)]
        key = lambda r: f"{r[NAME]}-SP-{year}"
        by_name1 = {key(r): r for r in cycle1}
        by_name2 = {key(r): r for r in cycle2}
        by_id2 = {r["ID"]: r for r in cycle2}
        matches = [(r, by_name1[r["id"]]) for r in exp if r["id"] in by_name1]
        native_physical = [r for r in cycle1 if r[TYPE] == "Cela física"]
        strict = [r for r in cycle1 if strict_physical(r)]
        row = {
            "ano": year, "registros_exportados": len(exp),
            "populacao_exportada": sum(number(r[POP]) for r in exp),
            "capacidade_exportada": sum(capacity(r) for r in exp),
            "registros_base_unica_todos": len(cycle1),
            "populacao_base_unica_todos": sum(number(r[POP]) for r in cycle1),
            "capacidade_base_unica_todos": sum(capacity(r) for r in cycle1),
            "registros_fisicos_rotulo_nativo": len(native_physical),
            "populacao_fisica_rotulo_nativo": sum(number(r[POP]) for r in native_physical),
            "capacidade_fisica_rotulo_nativo": sum(capacity(r) for r in native_physical),
            "registros_fisicos_salvaguarda_nome": len(strict),
            "populacao_fisica_salvaguarda_nome": sum(number(r[POP]) for r in strict),
            "capacidade_fisica_salvaguarda_nome": sum(capacity(r) for r in strict),
            "linhas_export_associadas_nome_uf_ano": len(matches),
            "linhas_export_sem_par_exato": len(exp) - len(matches),
            "linhas_associadas_populacao_igual": sum(number(a[POP]) == number(b[POP]) for a, b in matches),
            "linhas_associadas_capacidade_igual": sum(capacity(a) == capacity(b) for a, b in matches),
            "linhas_associadas_nao_fisicas": sum(not strict_physical(b) for _, b in matches),
            "linhas_associadas_sem_par_nome_sem2": sum(a["id"] not in by_name2 for a, _ in matches),
            "linhas_associadas_sem_par_id_sem2": sum(b["ID"] not in by_id2 for _, b in matches),
        }
        for label, source in {"obitos_total": None, **FLOWS}.items():
            fields = [MORT_FIELDS[f"obitos_{cause}_total"] for cause in MORTALITY] if source is None else [source]
            name_sum = sum(number(by_name2.get(a["id"], {}).get(field, "")) for a, _ in matches for field in fields)
            id_sum = sum(number(by_id2.get(b["ID"], {}).get(field, "")) for _, b in matches for field in fields)
            row[f"sem2_{label}_juncao_nome"] = name_sum
            row[f"sem2_{label}_juncao_id"] = id_sum
        row["obitos_anuais_exportados"] = sum(number(r[f"obitos_{c}_total"]) for r in exp for c in MORTALITY)
        annual.append(row)
        for r in exp:
            if r["id"] not in by_name1:
                candidates = [s for s in cycle1 if s["Código IBGE"] == r["Código IBGE"]
                              and number(s[POP]) == number(r[POP]) and capacity(s) == capacity(r)]
                unmatched.append({"ano": year, "id_apresentacao_export": r["id"],
                                  "populacao_export": number(r[POP]), "capacidade_export": capacity(r),
                                  "ids_candidatos_mesmo_municipio_populacao_capacidade": " ; ".join(s["ID"] for s in candidates),
                                  "nomes_candidatos": " ; ".join(s[NAME] for s in candidates),
                                  "limite": "Candidatos por atributos não substituem correspondência de identidade"})

    historical = []
    blobs = {}
    for ref, path in (("2020/2", "9o-ciclo-base-de-dados-2020-2-semestre.xlsx"),
                      ("2021/2", "11o-ciclo-base-de-dados-2021-2-semestre.xlsx")):
        spec = f"{SP_DATA_COMMIT}:{path}"
        payload = git_bytes(args.sp_repo, spec)
        original, headers = read_selected_xlsx(io.BytesIO(payload), ref)
        blobs[spec] = hashlib.sha256(payload).hexdigest()
        for label in sorted({name_modality(r[NAME]) for r in original}):
            group = [r for r in original if name_modality(r[NAME]) == label]
            historical.append({"referencia": ref, "fonte": spec, "modalidade_pelo_nome": label,
                               "possui_tipo_recolhimento": TYPE in headers,
                               "possui_id_nativo": "ID" in headers, **aggregate(group)})

    nominal_groups = defaultdict(list)
    for row in rows:
        if row["Referência"] == "2021/2":
            nominal_groups[base_name(row[NAME])].append(row)
    triads = []
    for label, group in sorted(nominal_groups.items()):
        if len(group) != 3 or len({name_modality(r[NAME]) for r in group}) != 3:
            continue
        for row in group:
            triads.append({"referencia": "2021/2", "nome_base_candidato": label,
                           "id": row["ID"], "nome": row[NAME], "tipo_nativo": row[TYPE],
                           "modalidade_nome": name_modality(row[NAME]),
                           "tipo_estabelecimento_1_2": row[FACT], "municipio": row["Município"],
                           "codigo_ibge": row["Código IBGE"], "endereco": row["Endereço"],
                           "populacao": number(row[POP]), "capacidade": capacity(row),
                           "limite": "Tríade de nomes e modalidades; não comprova duplicidade física ou de pessoas"})

    write_csv(args.out / "resumo_estoque_anual.csv", annual)
    write_csv(args.out / "resumo_ciclos.csv", cycle_summary)
    write_csv(args.out / "tipos_nativos_por_ciclo.csv", types_summary)
    write_csv(args.out / "associacoes_modalidades_2020_2021.csv", association_rows(rows))
    write_csv(args.out / "export_sem_par_exato.csv", unmatched)
    write_csv(args.out / "arquivos_historicos_sp_sem2.csv", historical)
    write_csv(args.out / "triades_nominais_2021_2.csv", triads)
    manifest = {
        "base_unica": {"arquivo": input_label(args.base), "sha256": digest(args.base)},
        "export_sp": {"arquivo": input_label(args.export), "sha256": digest(args.export)},
        "sp_commit_codigo": SP_COMMIT,
        "sp_commit_arquivos_historicos": SP_DATA_COMMIT,
        "sp_scripts_sha256": {name: hashlib.sha256(git_bytes(args.sp_repo, f"{SP_COMMIT}:{name}")).hexdigest()
                              for name in ("depen.R", "dados_sem2.R")},
        "historicos_git_sha256": blobs,
        "registros_base_sp_2017_2025": len(rows), "registros_export_sp": len(exported),
        "id_nativo_repetido_no_ciclo": 0, "id_apresentacao_export_repetido": 0,
        "grupos_tres_nomes_modalidades_2021_2": len(triads) // 3,
        "limites": ["Contagens de cadastros não identificam pessoas únicas.",
                    "Nome-base e endereço são evidências de associação, sem deduplicação automática.",
                    "Rótulo nativo, nome e quesito 1.2 são preservados; suas diferenças não demonstram erro de classificação.",
                    "Exportação local não certifica a conexão de cada gráfico público atual."],
    }
    (args.out / "manifesto.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    status_after = subprocess.check_output(["git", "-C", str(args.sp_repo), "status", "--porcelain"])
    assert status_before == status_after, "SP working tree changed during audit"
    print(json.dumps({"output": str(args.out), "source_rows": len(rows),
                      "export_rows": len(exported), "unmatched": len(unmatched)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
