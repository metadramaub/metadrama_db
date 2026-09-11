# Auditoría de las fuentes · nivel 0

Generado el 2026-09-11 con `npm run audit:fuentes`. **No se edita a mano.**

**Este script no dictamina.** Prepara el trabajo: sitúa cada afirmación en su volcado,
extrae el pasaje y dice de cuáles no ha sabido. Se intentó que juzgara y no sirve —cada
vez que «detectó» algo, el equivocado era él: veinticuatro acusaciones por leer la
paginación al revés, cinco entradas dadas por inexistentes que estaban ahí con la
autoridad entre paréntesis, ocho epígrafes de Jauralde que tampoco faltaban—. **Que una
afirmación resuelva no dice nada sobre si es cierta, y que no resuelva tampoco dice que
sea falsa.** Eso lo deciden los verificadores con el texto delante, que es la fase
siguiente del [plan](../plan-auditoria-fuentes.md).

De **267** afirmaciones resuelven su localizador **249**.

## Por fuente

| Fuente | Afirmaciones | Resuelven | Con aviso | Volcado |
| --- | ---: | ---: | ---: | --- |
| Morley y Bruerton 1968 | 36 | 35 | 1 | Copia a mano del capítulo V, confirmada fiel. Vale como original. |
| Quilis 1969 | 37 | 36 | 4 | Regenerado sin -layout el 11 de septiembre de 2026. Dos páginas impresas por hoja. |
| Navarro Tomás 1972 | 51 | 49 | 2 | El § está en el cuerpo y el índice mapea § → página impresa. |
| Domínguez Caparrós 2014 | 41 | 36 | 5 | Volcado paginado y a una columna. |
| Diccionario 2016 | 59 | 59 | 1 | El fichero dice 1999 en su nombre pero es la 3.ª edición de 2016. |
| Jauralde Pou 2020 | 43 | 34 | 9 | Viene de un epub sin paginar: no hay página que comprobar. |

## Lo que el verificador tendrá que resolver a mano

**22** afirmaciones llegan a la verificación con algo sin resolver.
No son defectos: son los casos en que el script no ha sabido situar el pasaje por sí
solo, y el verificador tendrá que buscarlo y **explicar por qué es esa página o esa
sección**.

| Fuente | Sobre | Localizador | Qué falta |
| --- | --- | --- | --- |
| Morley y Bruerton 1968 | Cuarteto | Cap. V | localizador no seguible: no da página, § ni epígrafe entrecomillado |
| Quilis 1969 | Endecha real | § 6.4.1, p. 163 | declara p. 163 y el pasaje cae en 145 |
| Quilis 1969 | Sexteto | § 5.4.5 | no resuelve ninguna de sus anclas: § 5.4.5 |
| Quilis 1969 | Sextina | § 5.4.5.1, p. 100 | declara p. 100 y el pasaje cae en 101 |
| Quilis 1969 | Sextina | § 6.3.4, pp. 167-168 | declara p. 167 y el pasaje cae en 129 |
| Navarro Tomás 1972 | Cuarteto-lira | s. v. «cuarteto alirado», recogido en el Diccionario | el localizador remite a Diccionario 2016; no resuelve ninguna de sus anclas: entrada «cuarteto alirado», epígrafe «cuarteto alirado» |
| Navarro Tomás 1972 | Novena | § «Novena, 4-5» y § «Copla de pie quebrado: Novena» | no resuelve ninguna de sus anclas: epígrafe «Novena, 4-5», epígrafe «Copla de pie quebrado: Novena» |
| Domínguez Caparrós 2014 | Oncena | Índice de estrofas | localizador no seguible: no da página, § ni epígrafe entrecomillado |
| Domínguez Caparrós 2014 | Redondilla enlazada | Índice de estrofas | localizador no seguible: no da página, § ni epígrafe entrecomillado |
| Domínguez Caparrós 2014 | Septeto-lira | Apartado de la canción alirada | localizador no seguible: no da página, § ni epígrafe entrecomillado |
| Domínguez Caparrós 2014 | Septilla enlazada | Índice de estrofas | localizador no seguible: no da página, § ni epígrafe entrecomillado |
| Domínguez Caparrós 2014 | Sextilla enlazada | Índice de estrofas | localizador no seguible: no da página, § ni epígrafe entrecomillado |
| Diccionario 2016 | Sextilla · Hexasílaba | Entrada «lay», p. 148 | declara p. 148 y el pasaje cae en 215 |
| Jauralde Pou 2020 | Copla castellana | Apartado «Octavillas y octavas» | no resuelve ninguna de sus anclas: epígrafe «Octavillas y octavas» |
| Jauralde Pou 2020 | Copla de arte menor | Apartado «Octavillas y octavas» | no resuelve ninguna de sus anclas: epígrafe «Octavillas y octavas» |
| Jauralde Pou 2020 | Copla manriqueña | Apartado «Coplas de pie quebrado» | no resuelve ninguna de sus anclas: epígrafe «Coplas de pie quebrado» |
| Jauralde Pou 2020 | Endecasílabo suelto | Apartados sobre la rima y el verso libre | localizador no seguible: no da página, § ni epígrafe entrecomillado |
| Jauralde Pou 2020 | Octava aguda | Apartado «Octavillas y octavas» | no resuelve ninguna de sus anclas: epígrafe «Octavillas y octavas» |
| Jauralde Pou 2020 | Oncena | Apartado «Oncena» | no resuelve ninguna de sus anclas: epígrafe «Oncena» |
| Jauralde Pou 2020 | Pareado | «Estrofas de dos versos» | no resuelve ninguna de sus anclas: epígrafe «Estrofas de dos versos» |
| Jauralde Pou 2020 | Septilla | Apartados «Copla mixta» y «Octavillas y octavas» | no resuelve ninguna de sus anclas: epígrafe «Copla mixta», epígrafe «Octavillas y octavas» |
| Jauralde Pou 2020 | Versificación irregular | Apartado sobre el verso libre | localizador no seguible: no da página, § ni epígrafe entrecomillado |

### Localizadores que nadie puede seguir

Esto sí es un defecto, y no hace falta leer la fuente para verlo: **«Índice de estrofas» o
«Apartado sobre el verso libre» nombran un sitio sin decir cuál.** No acusan a la
afirmación de ser falsa; impiden comprobarla, que para una sección titulada «Lo que dicen
las fuentes» es igual de grave.

- **Cuarteto** · Morley y Bruerton 1968 · «Cap. V»
- **Oncena** · Domínguez Caparrós 2014 · «Índice de estrofas»
- **Redondilla enlazada** · Domínguez Caparrós 2014 · «Índice de estrofas»
- **Septeto-lira** · Domínguez Caparrós 2014 · «Apartado de la canción alirada»
- **Septilla enlazada** · Domínguez Caparrós 2014 · «Índice de estrofas»
- **Sextilla enlazada** · Domínguez Caparrós 2014 · «Índice de estrofas»
- **Endecasílabo suelto** · Jauralde Pou 2020 · «Apartados sobre la rima y el verso libre»
- **Versificación irregular** · Jauralde Pou 2020 · «Apartado sobre el verso libre»

## Qué se extrajo

Un JSON por fuente en [`extractos/`](./extractos/), con el pasaje y su contexto para cada
afirmación que resuelve. Es lo único que ven los verificadores: **nunca el libro entero**.
