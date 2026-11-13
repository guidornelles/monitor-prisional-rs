"""Prepara as três fontes auxiliares dos panoramas da candidata RS.

Requer Python com openpyxl. Use --baixar para consultar as APIs públicas do
IBGE e o portal do Inep ou reaproveite os arquivos oficiais no diretório de saída.
O denominador das taxas criminais segue na base existente do Censo 2022.
"""

import argparse
import csv
import io
import json
from collections import Counter
from hashlib import sha256
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import urlopen
from zipfile import ZipFile

from openpyxl import load_workbook


ANOS_POP = (1970, 1980, 1991, 2000, 2010, 2022)
ANOS_PIB = tuple(range(2010, 2024))
ANO_TDI = 2025
CABECALHO = (
    "Ano", "Recorte", "Município", "Município (IBGE)", "ID Município",
    "Nome Macrorregião",
)
BASE = Path(__file__).resolve().parents[2]
RAW = BASE / "data/raw/nacional"
SAIDA = BASE / "outputs/temp/candidata_2026-11-12/panoramas_historicos"
POP_2022_MUN = "ibge_populacao_municipios_rs_2022.csv"
REGIOES_ATUAIS = "ibge_municipios_regioes_rs.csv"


def url_sidra(tabela, anos, variavel, localidade, classificacao=None):
    periodos = "%7C".join(map(str, anos))
    filtros = {"localidades": localidade}
    if classificacao:
        filtros["classificacao"] = classificacao
    return (
        f"https://servicodados.ibge.gov.br/api/v3/agregados/{tabela}/"
        f"periodos/{periodos}/variaveis/{variavel}?{urlencode(filtros)}"
    )


def fontes_oficiais():
    urls = {}
    for tipo, localidade in (("mun", "N6[N3[43]]"), ("uf", "N3[43]")):
        urls[f"pop_202_{tipo}.json"] = url_sidra(202, ANOS_POP[:-1], 93, localidade, "1[0]|2[0]")
        urls[f"pib_5938_{tipo}.json"] = url_sidra(5938, ANOS_PIB, 37, localidade)
    urls["pop_4709_uf.json"] = url_sidra(4709, [2022], 93, "N3[43]")
    for abrangencia in ("MUNICIPIOS", "BRASIL_REGIOES_UFS"):
        arquivo = f"TDI_{ANO_TDI}_{abrangencia}.zip"
        urls[arquivo] = (
            "https://download.inep.gov.br/informacoes_estatisticas/"
            f"indicadores_educacionais/{ANO_TDI}/{arquivo}"
        )
    return urls


def csv_oficial(arquivo):
    with (RAW / arquivo).open(encoding="utf-8-sig", newline="") as stream:
        yield from csv.DictReader(stream)


def carregar_sidra(diretorio, arquivo, variavel, unidade):
    dados = json.loads((diretorio / arquivo).read_text(encoding="utf-8-sig"))
    tabela, = dados
    assert tabela["id"] == str(variavel) and tabela["unidade"] == unidade, arquivo
    resultado, = tabela["resultados"]
    assert all(c["categoria"] == {"0": "Total"} for c in resultado["classificacoes"]), arquivo
    for local in resultado["series"]:
        for ano, valor in local["serie"].items():
            if valor.isdigit():
                yield int(ano), local["localidade"]["id"], int(valor)
            else:
                assert valor in {"...", "..", "-", "X"}, (arquivo, local, valor)


def carregar_tdi(diretorio, abrangencia):
    with ZipFile(diretorio / f"TDI_{ANO_TDI}_{abrangencia}.zip") as zip_inep:
        nome_xlsx, = (nome for nome in zip_inep.namelist() if nome.endswith(".xlsx"))
        livro = load_workbook(io.BytesIO(zip_inep.read(nome_xlsx)), read_only=True, data_only=True)
    try:
        linhas = livro.active.iter_rows(min_row=9, values_only=True)
        cabecalho = next(linhas)
        for valores in linhas:
            linha = dict(zip(cabecalho, valores))
            if linha["NO_CATEGORIA"] != "Total" or linha["NO_DEPENDENCIA"] != "Total":
                continue
            if abrangencia == "MUNICIPIOS":
                if linha["SG_UF"] != "RS":
                    continue
                codigo = str(linha["CO_MUNICIPIO"])
            elif linha["UNIDGEO"] == "Rio Grande do Sul":
                codigo = "43"
            else:
                continue
            ano, valor = linha["NU_ANO_CENSO"], linha["FUN_CAT_0"]
            assert ano == ANO_TDI and isinstance(valor, (int, float)) and 0 <= valor <= 100, linha
            yield ano, codigo, valor
    finally:
        livro.close()


def escrever_csv(diretorio, nome, metrica, registros, localidades):
    with (diretorio / f"{nome}.csv").open("w", encoding="utf-8", newline="") as stream:
        escritor = csv.writer(stream)
        escritor.writerow((*CABECALHO, metrica))
        for ano, codigo, valor in sorted(registros):
            if codigo == "43":
                escritor.writerow((ano, "Estado", "Rio Grande do Sul", "", "", "", valor))
            else:
                nome_municipio, regiao = localidades[codigo]
                escritor.writerow((ano, "Município", f"{nome_municipio} (RS)", nome_municipio,
                                    codigo, regiao, valor))


def auditar(municipios, estado, anos, contagens, tolerancia):
    chaves = {(ano, codigo) for ano, codigo, _ in municipios}
    assert len(chaves) == len(municipios), "chave municipal duplicada"
    assert [ano for ano, codigo, _ in sorted(estado) if codigo == "43"] == list(anos), estado
    cobertura = Counter(ano for ano, _, _ in municipios)
    assert [cobertura[ano] for ano in anos] == contagens and len(cobertura) == len(anos), cobertura
    totais = Counter()
    for ano, _, valor in municipios:
        totais[ano] += valor
    if tolerancia is not None:
        assert all(abs(totais[ano] - valor) <= tolerancia for ano, _, valor in estado), (totais, estado)
    return {
        "municipios_por_ano": dict(sorted(cobertura.items())),
        "total_oficial_rs": {ano: valor for ano, _, valor in sorted(estado)},
        "soma_municipal": dict(sorted(totais.items())) if tolerancia is not None else None,
        "porto_alegre": {ano: valor for ano, codigo, valor in sorted(municipios) if codigo == "4314902"},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--saida", type=Path, default=SAIDA)
    parser.add_argument("--baixar", action="store_true")
    args = parser.parse_args()
    diretorio = args.saida
    diretorio.mkdir(parents=True, exist_ok=True)
    urls = fontes_oficiais()
    if args.baixar:
        for arquivo, url in urls.items():
            with urlopen(url, timeout=90) as resposta:
                (diretorio / arquivo).write_bytes(resposta.read())

    localidades = {
        linha["id_municipio"]: (linha["nome"], linha["nome_regiao_intermediaria"])
        for linha in csv_oficial(REGIOES_ATUAIS) if linha["id_municipio"]
    }
    assert len(localidades) == 497 and len({regiao for _, regiao in localidades.values()}) == 8

    pop_mun = list(carregar_sidra(diretorio, "pop_202_mun.json", 93, "Pessoas"))
    pop_uf = list(carregar_sidra(diretorio, "pop_202_uf.json", 93, "Pessoas"))
    for linha in csv_oficial(POP_2022_MUN):
        assert linha["Ano (Código)"] == "2022" and linha["Variável (Código)"] == "93", linha
        pop_mun.append((2022, linha["Município (Código)"], int(linha["Valor"])))
    pop_uf.extend(carregar_sidra(diretorio, "pop_4709_uf.json", 93, "Pessoas"))
    pib_mun = list(carregar_sidra(diretorio, "pib_5938_mun.json", 37, "Mil Reais"))
    pib_uf = list(carregar_sidra(diretorio, "pib_5938_uf.json", 37, "Mil Reais"))
    tdi_mun = list(carregar_tdi(diretorio, "MUNICIPIOS"))
    tdi_uf = list(carregar_tdi(diretorio, "BRASIL_REGIOES_UFS"))

    camadas = (
        ("populacao_historica", "População residente", pop_mun, pop_uf, ANOS_POP,
         [232, 232, 333, 467, 496, 497], 0),
        ("pib_historico", "PIB (mil R$ correntes)", pib_mun, pib_uf, ANOS_PIB,
         [496] * 3 + [497] * 11, 15),
        ("tdi_2025", "Distorção idade-série (%)", tdi_mun, tdi_uf, [ANO_TDI], [497], None),
    )
    auditoria = {}
    for nome, metrica, municipios, estado, anos, contagens, tolerancia in camadas:
        auditoria[nome] = auditar(municipios, estado, anos, contagens, tolerancia)
        escrever_csv(diretorio, nome, metrica, municipios + estado, localidades)
    arquivos_fonte = [diretorio / arquivo for arquivo in urls]
    arquivos_fonte.extend([RAW / POP_2022_MUN, RAW / REGIOES_ATUAIS])
    urls[POP_2022_MUN] = url_sidra(4709, [2022], 93, "N6[N3[43]]")
    urls[REGIOES_ATUAIS] = "https://servicodados.ibge.gov.br/api/v1/localidades/estados/43/municipios"
    manifesto = {
        "auditoria": auditoria,
        "fontes_oficiais": urls,
        "sha256_entradas": {arquivo.name: sha256(arquivo.read_bytes()).hexdigest()
                           for arquivo in arquivos_fonte},
    }
    (diretorio / "manifesto_panoramas.json").write_text(
        json.dumps(manifesto, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(auditoria, ensure_ascii=False))


if __name__ == "__main__":
    main()
