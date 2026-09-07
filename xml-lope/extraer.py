# -*- coding: utf-8 -*-
"""Extrae la estructura métrica de obras de ARTELOPE a JSON.

No guarda el texto dramático: solo numeración de versos, divisiones y etiquetas de estrofa.
"""
import os, re, sys, json, hashlib, collections

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from artelope_load import load

BASE = os.path.dirname(os.path.abspath(__file__))
TEXTS = os.path.join(BASE, 'xml')
STATS = os.path.join(BASE, 'estadisticas')  # ausente: solo 9 obras del repositorio lo traen
COMMIT = '95684795a842b63312aebdad83d1234c1d225b22'  # ARTELOPE, 2025-11-28

TAG = re.compile(r'<(/?)(div1|div2|lg|l|body)\b([^>]*)>')
ATTR = re.compile(r'([a-zA-Z:]+)="([^"]*)"')

# La licencia se declara dentro de cada teiHeader, en <availability>.
AVAIL = re.compile(r'<availability>(.*?)</availability>', re.S)


def limpia(s):
    return re.sub(r'\s+', ' ', s).strip()


def parse(texto):
    """Recorre el documento en orden y devuelve versos, actos y escenas."""
    versos = []          # (n, tipo_lg, acto, escena)
    actos = []           # (n, tipo_div)
    escenas = []         # (n, acto)
    pila_lg = []
    acto = escena = None
    acto_tipo = None
    en_body = False
    sin_lg = 0
    for m in TAG.finditer(texto):
        cierre, tag, attrs = m.group(1), m.group(2), m.group(3)
        a = dict(ATTR.findall(attrs))
        if tag == 'body':
            en_body = not cierre
            continue
        if not en_body:
            continue
        if tag == 'div1':
            if cierre:
                acto = None
            else:
                acto_tipo = a.get('type')
                acto = a.get('n')
                actos.append((acto, acto_tipo))
                escena = None
        elif tag == 'div2':
            escena = None if cierre else a.get('n')
            if not cierre:
                escenas.append((escena, acto))
        elif tag == 'lg':
            if cierre:
                if pila_lg:
                    pila_lg.pop()
            elif not attrs.rstrip().endswith('/'):
                pila_lg.append(a.get('type', ''))
        elif tag == 'l' and not cierre:
            if 'n' not in a:
                continue  # fragmento de verso partido: no cuenta como verso nuevo
            if not pila_lg:
                sin_lg += 1
            versos.append((int(a['n']), pila_lg[-1] if pila_lg else None, acto, escena))
    return versos, actos, escenas, acto_tipo, sin_lg


def rangos_por_clave(versos, idx):
    """Tramos consecutivos que comparten el valor de la posición idx."""
    tramos = []
    for n, tipo, acto, escena in versos:
        clave = (tipo, acto, escena)[idx]
        if tramos and tramos[-1][0] == clave and n >= tramos[-1][2]:
            tramos[-1][2] = n
        else:
            tramos.append([clave, n, n])
    return tramos


def extremos(versos, idx):
    """v_ini/v_fin de cada valor distinto (para actos y escenas)."""
    orden = []
    d = {}
    for n, tipo, acto, escena in versos:
        clave = (tipo, acto, escena)[idx]
        if clave is None:
            continue
        if clave not in d:
            d[clave] = [n, n]
            orden.append(clave)
        else:
            d[clave][1] = max(d[clave][1], n)
            d[clave][0] = min(d[clave][0], n)
    return [(k, d[k][0], d[k][1]) for k in orden]


def estadisticas(al):
    if not os.path.isdir(STATS):
        return None, None
    for f in os.listdir(STATS):
        if f.lstrip('_').startswith(al):
            t = load(os.path.join(STATS, f))
            tramos = []
            for m in re.finditer(r'<lineaEstudioMetrica>\s*<tipoEstrofa>(.*?)</tipoEstrofa>\s*<rango>(.*?)</rango>', t, re.S):
                nums = re.findall(r'\d+', m.group(2))
                if len(nums) != 2:
                    continue
                tramos.append((limpia(m.group(1)), int(nums[0]), int(nums[1])))
            return f, tramos
    return None, None


def extraer(fichero):
    ruta = os.path.join(TEXTS, fichero)
    t = load(ruta)
    al = fichero.split('_')[0]
    avisos = []

    if '�' in t or '뿯' in t:
        avisos.append(
            'El fichero de ARTELOPE ha perdido los caracteres acentuados: donde iba una vocal '
            'con tilde o una eñe hay un carácter de reemplazo. Afecta al título y al nombre del '
            'autor tal como los da el XML, no a la numeración de versos ni a las etiquetas de estrofa.'
        )

    def campo(patron, texto=t):
        m = re.search(patron, texto, re.S)
        return limpia(m.group(1)) if m else None

    titulo = campo(r'<titleStmt>.*?<title>(.*?)</title>')
    autor = campo(r'<author ana="fiable">(.*?)</author>') or campo(r'<author[^>]*>(.*?)</author>')
    # ARTELOPE declara la fiabilidad de la atribución en el propio <author>.
    m_ana = re.search(r'<author[^>]* ana="([^"]*)"', t)
    autoria = m_ana.group(1) if m_ana else None
    # La fecha de publicación del teiHeader es la de la edición digital, no la de la obra.
    fecha_digital = campo(r'<publicationStmt>.*?<date>(.*?)</date>')
    licencia = campo(r'<availability>(.*?)</availability>')
    if licencia:
        licencia = limpia(re.sub(r'<[^>]+>', ' ', licencia))
    extent = campo(r'<extent[^>]*>(.*?)</extent>')

    versos, actos, escenas, acto_tipo, sin_lg = parse(t)
    ns = [v[0] for v in versos]

    if not versos:
        avisos.append('No se ha encontrado ningún verso numerado en el cuerpo del documento.')
        return None

    # Numeración: huecos, repeticiones, desorden.
    dup = [n for n, c in collections.Counter(ns).items() if c > 1]
    if dup:
        avisos.append('Números de verso repetidos en el XML: %s.' % ', '.join(str(x) for x in sorted(dup)[:20]))
    huecos = sorted(set(range(ns[0], ns[-1] + 1)) - set(ns))
    cola = [h for h in huecos if len(ns) > 1 and h > ns[-2]]
    if huecos and len(cola) == len(huecos):
        avisos.append(
            'El último verso lleva mal el número: va del %d al %d, saltándose %d. El texto está '
            'entero; es una errata de un solo atributo, y el <extent> del encabezado la arrastra '
            'porque se calculó sobre el número mayor. No se corrige aquí.'
            % (ns[-2], ns[-1], len(huecos))
        )
        huecos = []
    elif huecos:
        avisos.append(
            'La numeración de ARTELOPE salta %d verso(s) que no existen en el fichero: %s. '
            'Los rangos se dan tal cual, sin renumerar.'
            % (len(huecos), ', '.join(str(x) for x in huecos[:20]) + ('…' if len(huecos) > 20 else ''))
        )
    if ns != sorted(ns):
        avisos.append('Los versos no aparecen en orden creciente de numeración en el documento.')
    if ns[0] != 1:
        avisos.append('La numeración no empieza en 1, sino en %d.' % ns[0])
    if sin_lg:
        avisos.append('%d verso(s) quedan fuera de cualquier <lg>, es decir, sin forma métrica asignada en la fuente.' % sin_lg)

    # extent declarado frente a versos contados
    if extent:
        m = re.search(r'(\d+)', extent)
        if m and int(m.group(1)) != len(ns):
            avisos.append(
                'El <extent> del teiHeader declara «%s» y el fichero trae %d versos numerados '
                '(último: %d).' % (extent, len(ns), ns[-1])
            )

    # Secuencias métricas: tramos seguidos con la misma etiqueta de <lg>.
    secuencias = []
    for tipo, ini, fin in rangos_por_clave(versos, 0):
        if tipo is None:
            nota = 'Versos que en el XML no caen dentro de ningún <lg>: ARTELOPE no les asigna forma.'
        elif tipo == '':
            nota = 'Versos dentro de un <lg> cuyo atributo type viene vacío.'
        else:
            nota = None
        secuencias.append({
            'v_ini': ini,
            'v_fin': fin,
            'forma_fuente': tipo if tipo else None,
            'metro_fuente': None,
            'esquema_rima_fuente': None,
            'notas': nota,
        })
    for s in secuencias:
        if s['forma_fuente'] in ('_solo_sangrado_', '_solo_sangrado_-'):
            s['notas'] = 'Etiqueta no métrica del XML: marca sangrado tipográfico, no una forma.'
            avisos.append('Aparece la etiqueta de <lg> «%s», que no nombra una forma métrica sino un sangrado.' % s['forma_fuente'])

    # Cierre de rangos: ni solapes ni huecos entre secuencias.
    for a, b in zip(secuencias, secuencias[1:]):
        salto = set(range(a['v_fin'] + 1, b['v_ini'])) - set(huecos)
        if b['v_ini'] <= a['v_fin']:
            avisos.append('Las secuencias %d-%d y %d-%d se solapan.' % (a['v_ini'], a['v_fin'], b['v_ini'], b['v_fin']))
        elif salto:
            avisos.append('Entre los versos %d y %d no hay ninguna secuencia métrica.' % (a['v_fin'], b['v_ini']))

    jornadas = [{'numero': int(n) if n and n.isdigit() else n, 'v_ini': i, 'v_fin': f}
                for n, i, f in extremos(versos, 1)]
    if acto_tipo and acto_tipo != 'jornada':
        avisos.append('ARTELOPE divide esta obra en «%s», no en «jornada»; se vuelca en el mismo campo.' % acto_tipo)

    esc = []
    for n, tipo, acto, escena in versos:
        if escena is None:
            continue
        if esc and esc[-1][0] == escena and esc[-1][1] == acto:
            esc[-1][3] = n
        else:
            esc.append([escena, acto, n, n])
    if esc:
        avisos.append(
            'El XML marca %d escenas (<div2 type="scene">), no cuadros: ARTELOPE no marca cuadros '
            'en ningún fichero del repositorio. Van en el campo «escenas»; «cuadros» queda vacío.' % len(esc)
        )

    # Contraste con el fichero de estadísticas, cuando lo hay.
    fstats, tramos = estadisticas(al)
    if tramos:
        propios = [s['v_ini'] for s in secuencias]
        ajenos = [i for _, i, f in tramos]
        if propios == ajenos:
            avisos.append(
                'Los %d tramos y sus versos de arranque coinciden con el <estudioMetrica> del fichero '
                'de estadísticas «%s». Los finales no: allí el rango se cierra en el primer verso de la '
                'última estrofa del tramo y deja huecos, y aquí se cierra en el último verso real.'
                % (len(tramos), fstats)
            )
        else:
            avisos.append(
                'Los tramos extraídos (%d, arrancando en %s…) no cuadran con el <estudioMetrica> del '
                'fichero «%s» (%d tramos, arrancando en %s…).'
                % (len(propios), propios[:3], fstats, len(ajenos), ajenos[:3])
            )

    return {
        'fuente': {
            'repositorio': 'ARTELOPE',
            'url': 'https://gitlab.com/artelope1/ARTELOPE',
            'commit': COMMIT,
            'fichero': 'XML-TEI Play-texts/' + fichero,
            'copia_local': 'xml-lope/xml/' + fichero,
            'codificacion': 'UTF-16LE, tal como lo publica ARTELOPE',
            'sha256': hashlib.sha256(open(ruta, 'rb').read()).hexdigest(),
            'texto_plano': 'xml-lope/txt/' + fichero.split('_')[0] + '.txt',
            'licencia': licencia,
        },
        'obra': {
            'titulo': titulo,
            'autor': autor,
            'fecha': None,  # ARTELOPE no data la obra en el XML
            'total_versos': len(ns),
            'genero': None,
            'autoria_fuente': autoria,
        },
        'jornadas': jornadas,
        'cuadros': [],
        'escenas': [{'jornada': int(a) if a and str(a).isdigit() else a,
                     'numero': int(n) if str(n).isdigit() else n, 'v_ini': i, 'v_fin': f}
                    for n, a, i, f in esc],
        'secuencias': secuencias,
        'personajes': {'donaire': None, 'sobrenaturales': None, 'eventos_sobrenaturales': None},
        'avisos': avisos,
    }


if __name__ == '__main__':
    for f in sys.argv[1:]:
        d = extraer(f)
        print(json.dumps(d, ensure_ascii=False, indent=2)[:1500])
        print('...secuencias:', len(d['secuencias']), 'avisos:', len(d['avisos']))
