# -*- coding: utf-8 -*-
"""Saca de los XML de ARTELOPE dos cosas distintas.

  txt/<AL>.txt        un verso por línea y nada más, que es lo que come libEscansion.
  lectura/<AL>.txt    la obra legible —hablantes, acotaciones y número de verso—, para
                      poder leerla y decidir dónde cortan los cuadros.

Los versos partidos entre dos personajes se reúnen en una sola línea: en el XML el
primer trozo lleva el número y los siguientes van sin él.
"""
import os, re, sys, html

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
from artelope_load import load

XML = os.path.join(BASE, 'xml')
TAG = re.compile(r'<(/?)(div1|div2|lg|l|sp|speaker|stage|head|p)\b([^>]*)>')
ATTR = re.compile(r'([a-zA-Z:]+)="([^"]*)"')


def texto_plano(fragmento):
    """Quita el marcado interno de un verso o una acotación y deja el texto."""
    fragmento = re.sub(r'<code[^>]*>.*?</code>', ' ', fragmento, flags=re.S)
    fragmento = re.sub(r'<[^>]+>', '', fragmento)
    return re.sub(r'\s+', ' ', html.unescape(fragmento)).strip()


def recorrer(t):
    """Devuelve la obra como una lista de sucesos en orden: acto, escena, acotación, verso."""
    cuerpo = t[t.find('<body'):]
    sucesos = []
    pos = 0
    hablante = None
    for m in TAG.finditer(cuerpo):
        cierre, tag, attrs = m.group(1), m.group(2), m.group(3)
        a = dict(ATTR.findall(attrs))
        if cierre:
            continue
        fin = cuerpo.find('</%s>' % tag, m.end())
        dentro = cuerpo[m.end():fin] if fin > 0 else ''
        if tag == 'div1':
            sucesos.append(('acto', a.get('n'), None))
        elif tag == 'div2':
            sucesos.append(('escena', a.get('n'), None))
        elif tag == 'speaker':
            hablante = texto_plano(dentro)
        elif tag == 'stage':
            sucesos.append(('acotacion', None, texto_plano(dentro)))
        elif tag == 'p':
            txt = texto_plano(dentro)
            if txt:
                sucesos.append(('prosa', None, txt))
        elif tag == 'l':
            txt = texto_plano(dentro)
            if 'n' in a:
                # (hablante, verso suelto para libEscansion, verso marcado para leer)
                sucesos.append(('verso', int(a['n']), (hablante, txt, txt)))
                hablante = None
            elif sucesos and sucesos[-1][0] == 'verso':
                # trozo final de un verso partido: se pega al anterior, sin perder de vista
                # quién lo dice, que para los cuadros importa
                anterior = sucesos[-1]
                h, limpio, marcado = anterior[2]
                suelto = ('%s: %s' % (hablante, txt)) if hablante else txt
                sucesos[-1] = ('verso', anterior[1],
                               (h, (limpio + ' ' + txt).strip(), (marcado + ' // ' + suelto).strip()))
                hablante = None
    return sucesos


def escribir(fichero):
    al = fichero.split('_')[0]
    sucesos = recorrer(load(os.path.join(XML, fichero)))

    versos = [s for s in sucesos if s[0] == 'verso']
    d_txt = os.path.join(BASE, 'txt')
    d_lec = os.path.join(BASE, 'lectura')
    os.makedirs(d_txt, exist_ok=True)
    os.makedirs(d_lec, exist_ok=True)

    with open(os.path.join(d_txt, al + '.txt'), 'w', encoding='utf-8') as f:
        for _, _, (_, limpio, _) in versos:
            f.write(limpio + '\n')

    with open(os.path.join(d_lec, al + '.txt'), 'w', encoding='utf-8') as f:
        for tipo, n, dato in sucesos:
            if tipo == 'acto':
                f.write('\n\n===== ACTO %s =====\n' % n)
            elif tipo == 'escena':
                f.write('\n--- escena %s ---\n' % n)
            elif tipo == 'acotacion':
                f.write('\n[ACOTACIÓN] %s\n' % dato)
            elif tipo == 'prosa':
                f.write('\n[PROSA] %s\n' % dato)
            else:
                hablante, _, marcado = dato
                if hablante:
                    f.write('\n%s\n' % hablante)
                f.write('%5d  %s\n' % (n, marcado))
    return al, len(versos)


if __name__ == '__main__':
    for f in sorted(os.listdir(XML)):
        if f.endswith('.xml'):
            print('%s  %d versos' % escribir(f))
