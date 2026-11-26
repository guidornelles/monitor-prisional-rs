"""Pacote Vega WIDE isolado: path relativo, precisão global e bbox municipal.

Quantiza primeiro as coordenadas ABSOLUTAS em uma grade global. Os deltas são
inteiros dessa grade, sem arredondamento acumulado. Mantém todos os vértices,
inclusive repetições e fechamento, partes e anéis da malha validada. Não executa
DDL nem altera as versões anteriores ou a candidata principal.
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
import re
import statistics
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "outputs/temp/mapa_criminal_ibge_teste_2026-11-23"
OUT = ROOT / "outputs/auditoria/otimizacao_vega_2026-11-25"
GEO_HASH = "41e6480c9c63110eb7ee435866a4f9e9bb178f89c3fca33c680b8fdd89db7644"
FACTS_HASH = "256f9b413c910d35f0d3489fdace9f0f85e2f1f543da3399cb105938eb4b0881"
NUM_TOKEN = re.compile(r"[-+]?(?:\d*\.\d+|\d+)")
PATH_TOKEN = re.compile(r"[mz]|[-+]?(?:\d*\.\d+|\d+)")
BASE = "project-721a905d-46bc-4160-939.monitor_rs_mapa_teste_20261123"
PRECISION = 4
GRID = 10 ** PRECISION


def require(ok, message):
    if not ok:
        raise AssertionError(message)


def parts(geometry):
    require(geometry["type"] in ("Polygon", "MultiPolygon"), "Geometria não poligonal")
    return [geometry["coordinates"]] if geometry["type"] == "Polygon" else geometry["coordinates"]


def project(point):
    lon, lat = point[:2]
    require(math.isfinite(lon) and math.isfinite(lat), "Coordenada não finita")
    lat = math.radians(max(-85, min(85, lat)))
    return math.radians(lon)*1000, -math.log(math.tan(math.pi/4+lat/2))*1000


def area2(ring):
    return sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(ring,ring[1:]))


def qnumber(value):
    """Inteiro na grade global -> SVG sem expoente ou zeros supérfluos."""
    sign = "-" if value < 0 else ""
    value = abs(value)
    integer, fraction = divmod(value,GRID)
    if not fraction:
        return sign+str(integer)
    return sign+(str(integer) if integer else "")+"."+f"{fraction:0{PRECISION}d}".rstrip("0")


def pack_numbers(values):
    result = ""
    for value in values:
        token = qnumber(value)
        # Sinal negativo separa números no SVG; positivo precisa de separador.
        result += (" " if result and not token.startswith("-") else "")+token
    return result


def decode_relative(path):
    """Parser independente da codificação; reconstrói inteiros absolutos."""
    tokens = PATH_TOKEN.findall(path)
    require("".join(tokens) == re.sub(r"[ ,]", "", path), "Token SVG não reconhecido")
    current = (0,0)
    rings = []
    i = 0
    while i < len(tokens):
        require(tokens[i] == "m", "Esperado início de anel m")
        i += 1
        ring = []
        while i < len(tokens) and tokens[i] != "z":
            require(i+1 < len(tokens) and tokens[i+1] not in ("m","z"), "Par SVG incompleto")
            # Decimal do token é exato na grade; conversão arredondada remove
            # somente a aproximação binária do float do parser.
            delta = (round(float(tokens[i])*GRID), round(float(tokens[i+1])*GRID))
            current = (current[0]+delta[0],current[1]+delta[1])
            ring.append(current)
            i += 2
        require(i < len(tokens) and tokens[i] == "z" and len(ring)>=4, "Anel SVG não fechado")
        require(ring[0] == ring[-1], "Coordenada de fechamento não preservada")
        current = ring[0]
        rings.append(ring)
        i += 1
    return rings


def write_json(path, value):
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")


def validate_geos(wkts, rscript, output):
    program = r'''
.libPaths(c("C:/Users/guilh/GitHub/MonitorPrisionalRS/renv/library/windows/R-4.5/x86_64-w64-mingw32", "C:/Users/guilh/AppData/Local/R/win-library/4.5", .libPaths()))
suppressPackageStartupMessages(library(sf))
input <- jsonlite::fromJSON(commandArgs(trailingOnly=TRUE)[[1]])
g <- sf::st_as_sfc(input$wkt)
reason <- sf::st_is_valid(g,reason=TRUE)
bad <- which(is.na(reason) | reason != "Valid Geometry")
result <- list(total=length(g),invalidas=length(bad),razoes=as.list(reason[bad]),ids=as.list(input$id_municipio[bad]),geos=sf::sf_extSoftVersion()[["GEOS"]])
cat(jsonlite::toJSON(result,auto_unbox=TRUE,digits=NA))
'''
    # Arquivos evitam problemas do Rscript no Windows com -e multilinha e stdin
    # muito longo. A entrada é derivada e fica isolada na pasta de auditoria.
    helper=output/"validar_quantizacao_geos.R"
    helper.write_text(program,encoding="utf-8")
    input_path=output/"geometrias_quantizadas_wkt.json"
    write_json(input_path,wkts)
    executed = subprocess.run([str(rscript),"--vanilla",str(helper),str(input_path)],text=True,capture_output=True,timeout=180)
    require(executed.returncode == 0, "Falha no validador GEOS: returncode="+str(executed.returncode)+" stdout="+executed.stdout[-1000:]+" stderr="+executed.stderr[-1500:])
    try:
        result = json.loads(executed.stdout)
    except json.JSONDecodeError as error:
        raise AssertionError("Saída GEOS inesperada: "+executed.stdout[-1000:]) from error
    result["stderr"] = executed.stderr
    return result


def main():
    global PRECISION, GRID
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output",type=Path,default=OUT)
    parser.add_argument("--rscript",type=Path,default=Path("C:/Program Files/R/R-4.5.3/bin/Rscript.exe"))
    parser.add_argument("--precision",type=int,choices=(3,4,5,6),default=4,
        help="Casas globais; três casas geraram três inválidas no experimento inicial.")
    args=parser.parse_args()
    PRECISION=args.precision;GRID=10**PRECISION
    out=args.output.resolve();out.mkdir(parents=True,exist_ok=True)
    geo_file=SOURCE/"geo_municipios_rs_2022.geojson";facts_file=SOURCE/"fatos_criminais.csv"
    require(hashlib.sha256(geo_file.read_bytes()).hexdigest()==GEO_HASH,"Malha diferente da edição validada")
    require(hashlib.sha256(facts_file.read_bytes()).hexdigest()==FACTS_HASH,"Fatos diferentes da edição validada")
    features=json.loads(geo_file.read_text(encoding="utf-8"))["features"]
    require(len(features)==497,"Esperados 497 municípios")
    projected={}
    original_vertices=0
    for feature in features:
        for polygon in parts(feature["geometry"]):
            for ring in polygon:
                require(len(ring)>=4 and ring[0][:2]==ring[-1][:2],"Anel original aberto")
                for point in ring:
                    original_vertices+=1;key=tuple(point[:2])
                    if key not in projected:projected[key]=project(point)
    require(original_vertices==619347,"Número original de vértices divergente")
    xs=[p[0] for p in projected.values()];ys=[p[1] for p in projected.values()]
    xmin,ymin,xmax,ymax=min(xs),min(ys),max(xs),max(ys)
    pad=max(xmax-xmin,ymax-ymin)*.045
    scale=min(1000/(xmax-xmin+2*pad),1000/(ymax-ymin+2*pad))
    dx=(1000-(xmax-xmin+2*pad)*scale)/2-(xmin-pad)*scale
    dy=(1000-(ymax-ymin+2*pad)*scale)/2-(ymin-pad)*scale
    cache={};max_error=0
    for key,(x,y) in projected.items():
        raw=(x*scale+dx,y*scale+dy)
        q=(round(raw[0]*GRID),round(raw[1]*GRID))
        require(0<=q[0]<=1000*GRID and 0<=q[1]<=1000*GRID,"Coordenada fora do canvas")
        cache[key]=q
        max_error=max(max_error,math.dist(raw,(q[0]/GRID,q[1]/GRID)))

    rows=[];stats=[];wkts=[];total_vertices=total_parts=total_rings=total_holes=0
    collapsed_adjacent=0;orientation_bad=[];all_outside_signs=set()
    for feature in features:
        ident=feature["properties"]["id_municipio"]
        current=(0,0);chunks=[];rings_expected=[];city_coords=[];polygon_wkt=[]
        city_parts=city_rings=city_holes=city_vertices=0
        for polygon in parts(feature["geometry"]):
            city_parts+=1;city_holes+=len(polygon)-1;ring_wkts=[];outer_sign=None
            for ring_index,ring in enumerate(polygon):
                qring=[cache[tuple(p[:2])] for p in ring]
                rings_expected.append(qring);city_coords.extend(qring)
                city_vertices+=len(qring);city_rings+=1
                values=[]
                for q in qring:
                    values.extend((q[0]-current[0],q[1]-current[1]));current=q
                chunks.append("m"+pack_numbers(values)+"z")
                current=qring[0]
                ring_wkts.append("("+",".join(qnumber(x)+" "+qnumber(y) for x,y in qring)+")")
                signed=area2(qring);require(signed!=0,f"Anel degenerado ao quantizar: {ident}")
                sign=1 if signed>0 else -1
                if ring_index==0:outer_sign=sign;all_outside_signs.add(sign)
                elif sign==outer_sign:orientation_bad.append((ident,ring_index))
                collapsed_adjacent+=sum(a==b and original_a[:2]!=original_b[:2] for a,b,original_a,original_b in zip(qring,qring[1:],ring,ring[1:]))
            polygon_wkt.append("("+",".join(ring_wkts)+")")
        path="".join(chunks)
        require(decode_relative(path)==rings_expected,f"Round-trip SVG relativo divergiu: {ident}")
        require(len(NUM_TOKEN.findall(path))//2==city_vertices,"Número de pontos do path divergente")
        bbox=(min(p[0] for p in city_coords)/GRID,min(p[1] for p in city_coords)/GRID,max(p[0] for p in city_coords)/GRID,max(p[1] for p in city_coords)/GRID)
        rows.append(dict(id_municipio=ident,geometria_svg=path,bbox_xmin=bbox[0],bbox_ymin=bbox[1],bbox_xmax=bbox[2],bbox_ymax=bbox[3]))
        stats.append(dict(id_municipio=ident,nome=feature["properties"]["nome"],vertices=city_vertices,partes=city_parts,aneis=city_rings,furos=city_holes,bytes_svg=len(path)))
        wkts.append(dict(id_municipio=ident,wkt="MULTIPOLYGON("+",".join(polygon_wkt)+")"))
        total_vertices+=city_vertices;total_parts+=city_parts;total_rings+=city_rings;total_holes+=city_holes
    require(total_vertices==619347 and total_parts==503 and total_rings==504 and total_holes==1,"Partes/anéis/vértices divergiram")
    require(not orientation_bad,"Orientação de furo não preservada")
    require(len({row["id_municipio"] for row in rows})==497,"IDs repetidos")
    csv_path=out/"geometrias_svg_compactas.csv"
    with csv_path.open("w",encoding="utf-8",newline="") as stream:
        writer=csv.DictWriter(stream,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    schema=[dict(name=name,type="STRING" if name in ("id_municipio","geometria_svg") else "FLOAT",mode="REQUIRED") for name in rows[0]]
    write_json(out/"schema_geometrias_svg_compactas_bigquery.json",schema)
    with (out/"contagens_geometrias.csv").open("w",encoding="utf-8",newline="") as stream:
        writer=csv.DictWriter(stream,fieldnames=list(stats[0]));writer.writeheader();writer.writerows(sorted(stats,key=lambda r:r["bytes_svg"],reverse=True))
    csv.field_size_limit(10_000_000)
    with csv_path.open(encoding="utf-8",newline="") as stream:reread=list(csv.DictReader(stream))
    require(len(reread)==497 and all(a["geometria_svg"]==b["geometria_svg"] for a,b in zip(reread,rows,strict=True)),"Releitura CSV divergente")
    write_json(out/"validade_geos.json",dict(status="pendente",nota="CSV exportado e round-trip SVG aprovado; ainda aguardar o resultado GEOS antes de aprovar a representação."))
    geos=validate_geos(wkts,args.rscript,out)
    write_json(out/"validade_geos.json",geos)
    require(geos["invalidas"]==0,"Geometrias inválidas após quantização; ver validade_geos.json")

    with facts_file.open(encoding="utf-8-sig",newline="") as stream:facts=list(csv.DictReader(stream))
    pair=[r for r in facts if r["ano"] in ("2022","2025")]
    maxima={indicator:max(float(r["taxa"]) for r in pair if r["indicador"]==indicator) for indicator in {r["indicador"] for r in pair}}
    wide={}
    for row in pair:wide.setdefault((row["id_municipio"],row["indicador"]),{})[int(row["ano"])]=row
    require(len(pair)==5964 and len(wide)==2982,"Grade WIDE divergente")
    local_wide=[];geo_by_id={r["id_municipio"]:r for r in rows}
    for (ident,indicator),year_rows in wide.items():
        require(set(year_rows)=={2022,2025},"Par anual incompleto")
        a,b=year_rows[2022],year_rows[2025]
        require(a["nome"]==b["nome"] and a["regiao"]==b["regiao"] and a["populacao"]==b["populacao"],"Cadastro ou denominador mudou entre anos")
        local_wide.append(dict(id_municipio=ident,nome=a["nome"],regiao=a["regiao"],indicador=indicator,taxa_2022=float(a["taxa"]),taxa_2025=float(b["taxa"]),quantidade_2022=int(a["quantidade"]),quantidade_2025=int(b["quantidade"]),populacao=int(a["populacao"]),taxa_maxima_comum=maxima[indicator]))
    with (out/"controle_wide_local.csv").open("w",encoding="utf-8",newline="") as stream:
        writer=csv.DictWriter(stream,fieldnames=list(local_wide[0]));writer.writeheader();writer.writerows(local_wide)
    payloads=[]
    for indicator in sorted(maxima):
        sample=[{**r,**geo_by_id[r["id_municipio"]]} for r in local_wide if r["indicador"]==indicator]
        require(len(sample)==497,"Payload não contém 497 municípios")
        encoded=json.dumps(sample,ensure_ascii=False,separators=(",",":")).encode()
        payloads.append(dict(indicador=indicator,linhas=497,bytes_array_json_estimado=len(encoded),bytes_gzip_estimado=len(gzip.compress(encoded,mtime=0)),taxa_maxima_comum=maxima[indicator]))
    payload=csv_path.read_bytes();sizes=[row["bytes_svg"] for row in stats]
    metric_factor=6378137/1000/scale
    manifest=dict(
        gerado_utc=datetime.now(timezone.utc).isoformat(),fonte_geo=str(geo_file.relative_to(ROOT)),fonte_geo_sha256=GEO_HASH,
        fonte_fatos=str(facts_file.relative_to(ROOT)),fonte_fatos_sha256=FACTS_HASH,
        csv_sha256=hashlib.sha256(payload).hexdigest(),municipios=497,vertices=total_vertices,partes=total_parts,aneis=total_rings,furos=total_holes,
        simplificacao=False,reordenacao=False,precisao_casas=PRECISION,comandos="m com pares implícitos de l, z por anel; deltas em inteiros da grade absoluta comum",
        coordenadas_unicas_origem=len(cache),repeticoes_compartilhadas_ou_fechamentos=original_vertices-len(cache),
        vertices_distintos_adjacentes_coincidentes_apos_quantizacao=collapsed_adjacent,
        canvas=dict(width=1000,height=1000,bbox_global=[min(r["bbox_xmin"] for r in rows),min(r["bbox_ymin"] for r in rows),max(r["bbox_xmax"] for r in rows),max(r["bbox_ymax"] for r in rows)]),
        transformacao=dict(projecao="Mesma Mercator do protótipo; Y SVG cresce para baixo",escala=scale,offset_x=dx,offset_y=dy,padding_fracao=.045),
        erro_arredondamento=dict(maximo_svg=max_error,limite_svg=math.sqrt(2)*.5/GRID,maximo_metros_plano_mercator=max_error*metric_factor,limite_metros_plano_mercator=math.sqrt(2)*.5/GRID*metric_factor,nota="Erro numérico de exibição; não é precisão posicional da malha."),
        validade_geos=geos,orientacao=dict(sinais_exteriores=sorted(all_outside_signs),furos_opostos=True),
        tamanho=dict(csv_bytes=len(payload),csv_gzip_estimado_bytes=len(gzip.compress(payload,mtime=0)),soma_bytes_svg=sum(sizes),maximo_bytes_svg=max(sizes),mediana_bytes_svg=statistics.median(sizes)),
        wide=dict(linhas_total=2982,linhas_por_indicador=497,anos=[2022,2025],maximos_antes_filtros=maxima,payloads_estimados=payloads),
        notas=["Todos os pontos são preservados, inclusive deltas zero; não há simplificação.","Quantização global antes dos deltas evita acumulação de erro e mantém divisas compartilhadas na mesma grade.","O experimento global de três casas gerou três self-intersections, registrado em validade_geos_precisao_3.json; a versão aprovada usa a precisão global indicada neste manifesto.","Bboxes municipais referem-se às coordenadas SVG finais; não a latitude/longitude.","A view WIDE retorna uma geometria por município/indicador, reutilizada pelos dois painéis anuais.","O filtro antigo ano=2022 OR ano=2025 deve ser removido: a view WIDE não possui dimensão ano.","O pacote é isolado; nenhuma tabela/view foi publicada por este script."])
    write_json(out/"manifesto_compactacao.json",manifest)
    print(json.dumps(dict(status="preparado",municipios=497,vertices=total_vertices,geos_invalidas=geos["invalidas"],bytes_csv=len(payload),bytes_paths=sum(sizes),maximo_bytes_path=max(sizes),erro_maximo_metros_mercator=max_error*metric_factor,payload_wide_exemplo=payloads[0]),ensure_ascii=False))


if __name__=="__main__":main()
