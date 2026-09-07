# -*- coding: utf-8 -*-
"""Comprueba los cuadros de cada obra contra su texto.

Cuatro cosas, que son las que se le pueden pedir a una máquina:

  1. que los cuadros embaldosen la obra: sin huecos, sin solapes, del primer verso al último;
  2. que ninguno cruce un final de jornada, porque ahí siempre acaba cuadro;
  3. que en el verso donde corta haya de verdad una acotación de salida, salvo que el cuadro
     esté marcado como dudoso —es decir, que el vaciado se dedujera del reparto—;
  4. que ninguno de los que hablaban antes del corte siga hablando después. Un personaje que
     habla «(Dentro.)» no cuenta: está fuera del tablado.

Lo que no comprueba es lo único que importa de verdad —si el tablado se vacía—, que hay que
leerlo.
"""
import json, os, re, sys

BASE = os.path.dirname(os.path.abspath(__file__))
LEC = os.path.join(BASE, 'lectura')
CUA = os.path.join(BASE, 'cuadros')

SALIDA = re.compile(r'\b(vanse|vase|v[áa]yanse|v[áa]yase|[ée]ntranse|[ée]ntrense|[ée]ntrase|[ée]ntrese)\b', re.I)
VERSO = re.compile(r'\s*(\d+)\s{2}(.*)')
NOMBRE = re.compile(r'^[A-ZÁÉÍÓÚÑÜ][^a-z]*$')


def leer(al):
    """Del fichero legible: acotaciones y hablantes, ambos por número de verso."""
    acots, dice = {}, {}
    n, pendiente, dentro = 0, None, False
    for linea in open(os.path.join(LEC, al + '.txt'), encoding='utf-8'):
        m = VERSO.match(linea)
        if m:
            n = int(m.group(1))
            dice.setdefault(n, set())
            if not dentro:
                if pendiente:
                    dice[n].add(pendiente)
                for otro in re.findall(r'//\s*([^:]{1,25}):', m.group(2)):
                    dice[n].add(otro.strip())
            pendiente = None
        elif linea.startswith('[ACOTACIÓN]'):
            texto = re.sub(r'[\[\]]', '', linea[len('[ACOTACIÓN]'):]).strip()
            acots.setdefault(n, []).append(texto)
            dentro = bool(re.match(r'\(?\s*dentro', texto, re.I))
        elif linea.strip() and NOMBRE.match(linea.strip()):
            pendiente = linea.strip()
    return acots, dice


def revisar(al, jornadas, ultimo):
    cs = json.load(open(os.path.join(CUA, al + '.json'), encoding='utf-8'))['cuadros']
    acots, dice = leer(al)
    finales_jornada = {f for _, f in jornadas}
    fallos = []

    if cs[0]['v_ini'] != 1:
        fallos.append('el primer cuadro no empieza en el verso 1 sino en %d' % cs[0]['v_ini'])
    if cs[-1]['v_fin'] != ultimo:
        fallos.append('el último cuadro acaba en %d y la obra en %d' % (cs[-1]['v_fin'], ultimo))
    for a, b in zip(cs, cs[1:]):
        if b['v_ini'] != a['v_fin'] + 1:
            fallos.append('entre el cuadro %s (acaba en %d) y el %s (empieza en %d) queda hueco o solape'
                          % (a['numero'], a['v_fin'], b['numero'], b['v_ini']))
    for j, f in jornadas:
        if f not in {c['v_fin'] for c in cs}:
            fallos.append('el final de la jornada %s (v. %d) no cierra ningún cuadro' % (j, f))
        for c in cs:
            if c['v_ini'] <= f < c['v_fin']:
                fallos.append('el cuadro %s cruza el final de la jornada %s' % (c['numero'], j))

    for c in cs:
        if c['v_fin'] in finales_jornada:
            continue
        acotado = any(SALIDA.search(x) for x in acots.get(c['v_fin'], []))
        if not acotado and c.get('seguridad') != 'dudosa':
            fallos.append('el cuadro %s corta en el v. %d sin acotación de salida y no está marcado como dudoso'
                          % (c['numero'], c['v_fin']))
        if acotado and c.get('seguridad') == 'dudosa':
            pass  # dudoso por interpretación, no por falta de acotación: es legítimo

    for a, b in zip(cs, cs[1:]):
        if a['v_fin'] in finales_jornada:
            continue  # el corte lo impone la jornada, no el vaciado
        antes = set().union(*[dice.get(v, set()) for v in range(max(1, a['v_fin'] - 7), a['v_fin'] + 1)])
        despues = set().union(*[dice.get(v, set()) for v in range(b['v_ini'], b['v_ini'] + 8)])
        if antes & despues:
            fallos.append('en el corte del v. %d sigue hablando %s después de haberse ido'
                          % (a['v_fin'], ', '.join(sorted(antes & despues))))
    return cs, fallos


if __name__ == '__main__':
    todo = True
    for fichero in sorted(os.listdir(BASE)):
        if not fichero.endswith('.json') or not fichero.startswith('AL'):
            continue
        d = json.load(open(os.path.join(BASE, fichero), encoding='utf-8'))
        al = fichero.split('_')[0]
        if not os.path.exists(os.path.join(CUA, al + '.json')):
            continue
        jornadas = [(j['numero'], j['v_fin']) for j in d['jornadas']]
        cs, fallos = revisar(al, jornadas, d['obra']['total_versos'] and d['jornadas'][-1]['v_fin'])
        dudosos = sum(1 for c in cs if c.get('seguridad') == 'dudosa')
        print('%-9s %-36s %2d cuadros, %d dudosos' % (al, d['obra']['titulo'][:36], len(cs), dudosos))
        for f in fallos:
            print('   FALLO:', f)
            todo = False
    print('\n' + ('todo encaja' if todo else 'hay fallos'))
    sys.exit(0 if todo else 1)
