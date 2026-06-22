#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gera o PDF da Síntese de Indicadores (Monitor SP -> RS) reproduzindo o estilo
do PDF original (ReportLab, A4 paisagem, cabeçalhos verdes, links azuis).

Edições aplicadas nesta versão (jun/2026):
  - Ponto 5 (Recorte regional): reescrito.
  - Ponto 7 (Homicídios: vítimas x ocorrências): novo.

Uso: python3 gerar_sintese_pdf.py SAIDA.pdf
"""
import sys
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.platypus import (SimpleDocTemplate, Table, TableStyle, Paragraph,
                                Spacer, PageBreak)

GREEN = colors.HexColor("#274E15")   # cabeçalhos / título
LINKB = colors.HexColor("#1155CC")   # links
GRID  = colors.HexColor("#BFBFBF")   # gridlines
HEADTXT = colors.white

styles = getSampleStyleSheet()
def S(name, **kw):
    base = kw.pop("parent", styles["Normal"])
    return ParagraphStyle(name, parent=base, **kw)

st_title   = S("t", fontName="Helvetica-Bold", fontSize=15, leading=18, textColor=GREEN)
st_intro   = S("i", fontName="Helvetica", fontSize=7.5, leading=9.5, textColor=colors.HexColor("#444444"))
st_hcell   = S("hc", fontName="Helvetica-Bold", fontSize=7.5, leading=8.6, textColor=HEADTXT)
st_ind     = S("ind", fontName="Helvetica-Bold", fontSize=7.5, leading=8.6, textColor=colors.black)
st_cell    = S("c", fontName="Helvetica", fontSize=7.5, leading=8.6, textColor=colors.black)
st_link    = S("l", fontName="Helvetica", fontSize=7.5, leading=8.6, textColor=LINKB)
st_foot    = S("f", fontName="Helvetica", fontSize=7, leading=8.5, textColor=colors.black)
st_sechead = S("sh", fontName="Helvetica-Bold", fontSize=10, leading=13, textColor=GREEN,
               spaceBefore=4, spaceAfter=3)
st_point   = S("p", fontName="Helvetica", fontSize=8, leading=10.5, textColor=colors.black,
               spaceAfter=4)

def P(txt, s): return Paragraph(txt, s)

# ----- conteúdo da tabela (idêntico ao original) -----
HDR = ["Indicador (Monitor SP)", "Fonte (Monitor SP)", "Período (SP)",
       "Fonte(s) possível(is) no RS", "Abrangência territorial (RS)",
       "Cobertura e granularidade temporal (RS)", "Link — SSP-RS"]

# bloco: (a, b, c, [ (d, e, f, link_text, link_url), ... ])
def lk(t,u): return (t,u)
blocks = [
 ("Panorama Populacional","IBGE — Censos Demográficos","Decenal (desde a déc. de 1970)",
   [("IBGE — Censos (fonte nacional)","Municipal","Decenal","ibge.gov.br","https://www.ibge.gov.br")]),
 ("Panorama Econômico (PIB)","IBGE — PIB dos municípios","Anual, desde 2010",
   [("IBGE — PIB municípios (nacional)","Municipal","Desde 2010 · anual","ibge.gov.br","https://www.ibge.gov.br")]),
 ("Panorama de Saúde (tuberculose, hepatite, HIV e mortalidade)","DATASUS / Ministério da Saúde","Anual, desde 2018",
   [("DATASUS / Min. da Saúde (nacional)","Municipal","Desde 2018 · anual","datasus.saude.gov.br","https://datasus.saude.gov.br")]),
 ("Panorama Educacional (taxa de distorção idade-série)","INEP","Anual",
   [("INEP (nacional)","Municipal","Anual","gov.br/inep","https://www.gov.br/inep")]),
 ("Homicídio doloso","SSP-SP — ocorrências (Consultas)","Anual, desde 2001",
   [("Indicadores Criminais (tabela agregada)","Municipal","Desde 2002 · anual (mensal desde 2011)","ssp.rs.gov.br/indicadores-criminais","https://www.ssp.rs.gov.br/indicadores-criminais"),
    ("Microdados Mensais (Dados Abertos)","Municipal","Desde 2022 · diário","ssp.rs.gov.br/dados-abertos","https://www.ssp.rs.gov.br/dados-abertos")]),
 ("Estupro (todos os tipos, incl. vulnerável; ambos os sexos)","SSP-SP — ocorrências","Anual, desde 2001",
   [("Microdados Mensais — total, ambos os sexos (comparável a SP)","Municipal","Desde 2022 · diário","ssp.rs.gov.br/dados-abertos","https://www.ssp.rs.gov.br/dados-abertos"),
    ("Violência Contra a Mulher — recorte da Lei Maria da Penha (relações familiares/íntimas); ~metade do total","Municipal","Desde 2012 · anual (mensal desde 2018)","ssp.rs.gov.br/indicadores-da-violencia-contra-a-mulher","https://www.ssp.rs.gov.br/indicadores-da-violencia-contra-a-mulher")]),
 ("Roubo (categoria \"outros\": exclui veículo, banco, carga)","SSP-SP — ocorrências","Anual, desde 2001",
   [("Indicadores Criminais — \"Roubos\" (já exclui veículo; inclui banco/comércio)","Municipal","Desde 2002 · anual (mensal desde 2011)","ssp.rs.gov.br/indicadores-criminais","https://www.ssp.rs.gov.br/indicadores-criminais"),
    ("Microdados Mensais — reconstrução estrita do \"outros\"","Municipal","Desde 2022 · diário","ssp.rs.gov.br/dados-abertos","https://www.ssp.rs.gov.br/dados-abertos")]),
 ("Furto (categoria \"outros\": exclui veículo, banco)","SSP-SP — ocorrências","Anual, desde 2001",
   [("Indicadores Criminais — \"Furtos\" (exclui veículo; inclui abigeato e banco/comércio)","Municipal","Desde 2002 · anual (mensal desde 2011)","ssp.rs.gov.br/indicadores-criminais","https://www.ssp.rs.gov.br/indicadores-criminais"),
    ("Microdados Mensais — reconstrução estrita do \"outros\"","Municipal","Desde 2022 · diário","ssp.rs.gov.br/dados-abertos","https://www.ssp.rs.gov.br/dados-abertos")]),
 ("Armas de fogo apreendidas","SSP-SP — Dados de Produtividade","Anual, desde 2001",
   [("Indicadores de Atividade (PC + BM)","Estadual","Desde 2007 · mensal (soma PC+BM consistente a partir de 2017)","ssp.rs.gov.br/indicadores-de-atividade","https://www.ssp.rs.gov.br/indicadores-de-atividade"),
    ("Dados Abertos — Lei 15.610, Art. 6º, Inc. VII","Estadual","Desde 2021 · diário (registros com data)","ssp.rs.gov.br/dados-abertos","https://www.ssp.rs.gov.br/dados-abertos")]),
 ("Prisões efetuadas (Polícia Civil: flagrantes lavrados + mandados cumpridos)","SSP-SP — Dados de Produtividade","Anual, desde 2001",
   [("Dados Abertos — Lei 15.610, Inc. IX (flagrantes lavrados pela PC)","Municipal","Desde 2021 · diário (registros com data)","ssp.rs.gov.br/dados-abertos","https://www.ssp.rs.gov.br/dados-abertos"),
    ("Indicadores de Atividade (flagrantes + presos por mandados, PC)","Estadual","Desde 2007 · mensal (consistente a partir de 2017)","ssp.rs.gov.br/indicadores-de-atividade","https://www.ssp.rs.gov.br/indicadores-de-atividade")]),
 ("Dados Prisionais (SISDEPEN: capacidade/lotação, perfil, saúde, educação, trabalho, morbidade/mortalidade, etc.)","SISDEPEN / SENAPPEN","Semestral, desde 2017",
   [("SISDEPEN / SENAPPEN (fonte nacional)","Município + estabelecimento","Desde 2017 · semestral","gov.br/senappen","https://www.gov.br/senappen")]),
]

col_w = [95, 92, 70, 190, 62, 150, 111]  # soma 770pt (A4 paisagem, margens 36pt)

# monta linhas + spans
data = [[P(h, st_hcell) for h in HDR]]
spans = []
r = 1
for a,b,c,subs in blocks:
    n = len(subs)
    first = subs[0]
    row0 = [P(a, st_ind), P(b, st_cell), P(c, st_cell),
            P(first[0], st_cell), P(first[1], st_cell), P(first[2], st_cell),
            P('<link href="%s">%s</link>' % (first[4], first[3]), st_link)]
    data.append(row0)
    for k in range(1, n):
        s = subs[k]
        data.append(["","","",
                     P(s[0], st_cell), P(s[1], st_cell), P(s[2], st_cell),
                     P('<link href="%s">%s</link>' % (s[4], s[3]), st_link)])
    if n > 1:
        for col in (0,1,2):
            spans.append(("SPAN",(col,r),(col,r+n-1)))
    r += n

tbl = Table(data, colWidths=col_w, repeatRows=1)
ts = [
    ("BACKGROUND",(0,0),(-1,0), GREEN),
    ("VALIGN",(0,0),(-1,-1),"TOP"),
    ("GRID",(0,0),(-1,-1),0.5, GRID),
    ("LINEBELOW",(0,0),(-1,0),0.5, GREEN),
    ("TOPPADDING",(0,0),(-1,-1),1.8),
    ("BOTTOMPADDING",(0,0),(-1,-1),1.8),
    ("LEFTPADDING",(0,0),(-1,-1),4),
    ("RIGHTPADDING",(0,0),(-1,-1),4),
] + spans
tbl.setStyle(TableStyle(ts))

# ----- texto -----
TITLE = "Monitor do Sistema Prisional — síntese de indicadores e fontes equivalentes no RS"
INTRO = ("Para cada indicador do Monitor de SP: fonte e período usados em SP; fonte(s) "
         "correspondente(s) publicada(s) pela SSP-RS; abrangência territorial e cobertura/"
         "granularidade temporal de cada fonte no RS; e o link da página da SSP-RS. "
         "Documento de trabalho — junho/2026.")
FOOT = ("<b>Fontes:</b> elaborado por Guilherme Souza (2026) a partir da Nota Metodológica do "
        "Monitor do Sistema Prisional (NEV-USP), das páginas de estatísticas da SSP-RS "
        "(Indicadores Criminais, Dados Abertos – Lei 15.610, Indicadores da Violência Contra a "
        "Mulher, Indicadores de Atividade) e dos dicionários de dados oficiais. As equivalências "
        "criminais foram validadas por reconciliação dos microdados com as tabelas oficiais (2023 e 2024).")

points = [
 '<b>1. Estupro — qual fonte no comparativo SP↔RS?</b> O microdado Mensal traz o estupro total '
 '(ambos os sexos), comparável à definição de SP, mas só desde 2022. A série da Violência Contra '
 'a Mulher é mais longa (desde 2012), porém — conforme o Observatório da Violência Contra a Mulher '
 '(SSP-RS) — cobre o recorte da Lei Maria da Penha (relações familiares/íntimas), correspondendo a '
 '~metade do total (correlação municipal 0,99 com o microdado). <i>A confirmar na fonte primária do Observatório.</i>',
 '<b>2. Prisões no mapa.</b> Exibir no mapa apenas o componente de <i>flagrante</i> '
 '(municipalizado, Inc. IX), mantendo o total estadual completo (flagrantes + mandados)? Ou '
 'solicitar à SSP-RS o componente de mandados com município?',
 '<b>3. Roubo/furto "outros".</b> Usar a aproximação via tabela agregada (série desde 2002, mas '
 'inclui banco/comércio) ou a reconstrução estrita via microdado (idêntica à definição de SP, porém '
 'só desde 2022)?',
 '<b>4. Confirmar com a equipe de SP</b> a definição de "prisões efetuadas" (Polícia Civil: '
 'flagrantes lavrados + mandados cumpridos), conforme levantamento documental (Res. SSP-SP nº 160/2001).',
 # ---- ponto 5 reescrito ----
 '<b>5. Recorte regional.</b> Embora a Nota Metodológica do Monitor de SP fale em macrorregiões '
 'administrativas, as regiões exibidas no painel correspondem às 11 regiões geográficas '
 'intermediárias do estado de São Paulo, conforme o IBGE. O RS tem recortes próprios '
 '(RISP/COREDEs), não equivalentes. Definir se a comparação será municipal/estadual, tratando '
 '"região" à parte.',
 '<b>6. Base de comparação.</b> Comparar por <b>taxas (por 100 mil habitantes) e tendências</b>, '
 'não por números absolutos, exibindo a janela temporal válida de cada indicador.',
 # ---- ponto 7 novo ----
 '<b>7. Homicídios — vítimas ou ocorrências?</b> É possível contabilizar o homicídio doloso de '
 'duas formas: por número de vítimas ou por número de ocorrências. A Nota Metodológica do Monitor '
 'de SP indica ocorrências, mas os scripts e a visualização do DataStudio parecem indicar vítimas. '
 'Confirmar com a equipe de SP qual medida efetivamente alimenta o Monitor.',
]

NOTE_HEAD = 'Nota sobre a coluna "Cobertura e granularidade temporal"'
NOTE = ('A coluna mostra a <b>cobertura</b> (de que ano) e a <b>menor unidade de desagregação</b> '
        '(dia/mês/ano/semestre) — distinta da <b>frequência de publicação</b> (ex.: os Dados Abertos '
        'saem semestralmente, mas têm registros com data, desagregáveis por dia). Como o Monitor de '
        'SP usa dado <b>anual</b>, qualquer fonte do RS pode ser agregada à unidade temporal de SP; '
        'as restrições reais à comparação são o <b>ano de início</b> e a <b>abrangência territorial</b> '
        '(município × estadual).')

def build(path):
    doc = SimpleDocTemplate(path, pagesize=landscape(A4),
                            leftMargin=36, rightMargin=36, topMargin=30, bottomMargin=30,
                            title="Síntese de indicadores — Monitor SP/RS")
    story = [P(TITLE, st_title), Spacer(1,3), P(INTRO, st_intro), Spacer(1,8),
             tbl, Spacer(1,8), P(FOOT, st_foot),
             PageBreak(),
             P("Decisões e perguntas para o grupo", st_sechead)]
    story += [P(t, st_point) for t in points]
    story += [Spacer(1,8), P(NOTE_HEAD, st_sechead), P(NOTE, st_point)]
    doc.build(story)

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "Sintese_Indicadores_Monitor_SP_RS.pdf"
    build(out)
    print("OK ->", out)
