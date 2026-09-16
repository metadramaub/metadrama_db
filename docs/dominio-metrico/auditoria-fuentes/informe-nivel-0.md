# Auditoría de las fuentes · nivel 0

Generado el 2026-09-16 con `npm run audit:fuentes`. **No se edita a mano.**

**Este script no dictamina.** Prepara el trabajo: sitúa cada afirmación en su volcado,
extrae el pasaje y dice de cuáles no ha sabido. Se intentó que juzgara y no sirve —cada
vez que «detectó» algo, el equivocado era él: veinticuatro acusaciones por leer la
paginación al revés, cinco entradas dadas por inexistentes que estaban ahí con la
autoridad entre paréntesis, ocho epígrafes de Jauralde que tampoco faltaban—. **Que una
afirmación resuelva no dice nada sobre si es cierta, y que no resuelva tampoco dice que
sea falsa.** Eso lo deciden los verificadores con el texto delante, que es la fase
siguiente del [plan](../plan-auditoria-fuentes.md).

De **306** afirmaciones resuelven su localizador **306**.

## Por fuente

| Fuente | Afirmaciones | Resuelven | Con aviso | Volcado |
| --- | ---: | ---: | ---: | --- |
| Morley y Bruerton 1968 | 45 | 45 | 17 | Copia a mano del capítulo V, con marcas [p. 38] a [p. 41]. Vale como original. |
| Quilis 1969 | 44 | 44 | 2 | Regenerado sin -layout el 11 de septiembre de 2026. Dos páginas impresas por hoja. |
| Navarro Tomás 1972 | 56 | 56 | 9 | El § está en el cuerpo y el índice mapea § → página impresa. |
| Domínguez Caparrós 2014 | 48 | 48 | 7 | Volcado paginado y a una columna. |
| Diccionario 2016 | 63 | 63 | 2 | El fichero dice 1999 en su nombre pero es la 3.ª edición de 2016. |
| Jauralde Pou 2020 | 50 | 50 | 0 | Viene de un epub sin paginar: no hay página que comprobar. |

## Lo que el verificador tendrá que resolver a mano

**37** afirmaciones llegan a la verificación con algo sin resolver.
No son defectos: son los casos en que el script no ha sabido situar el pasaje por sí
solo, y el verificador tendrá que buscarlo y **explicar por qué es esa página o esa
sección**.

| Fuente | Sobre | Localizador | Qué falta |
| --- | --- | --- | --- |
| Morley y Bruerton 1968 | Copla castellana | Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Copla de arte menor | Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Copla manriqueña | Cap. V, pp. 38-41, y epígrafe «Coplas de pie quebrado», p. 39 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Cuarteto-lira | Cap. V, pp. 38-41, y epígrafes «Liras» y «Canción (Canzone)», p. 40 | declara p. 38 y el pasaje cae en 40 |
| Morley y Bruerton 1968 | Décima-lira | Cap. V, pp. 38-41, y epígrafes «Liras» y «Canción (Canzone)», p. 40 | declara p. 38 y el pasaje cae en 40 |
| Morley y Bruerton 1968 | Novena | Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Novena-lira | Cap. V, pp. 38-41, y epígrafes «Liras» y «Canción (Canzone)», p. 40 | declara p. 38 y el pasaje cae en 40 |
| Morley y Bruerton 1968 | Octava-lira | Cap. V, pp. 38-41, y epígrafes «Liras» y «Canción (Canzone)», p. 40 | declara p. 38 y el pasaje cae en 40 |
| Morley y Bruerton 1968 | Oncena | Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Pareado | Cap. V, «Pareados», p. 39 | declara p. 39 y el pasaje cae en 41 |
| Morley y Bruerton 1968 | Septilla | Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Septilla enlazada | Cap. V, pp. 38-41, y epígrafe «Coplas de pie quebrado», p. 39 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Sextilla enlazada | Cap. V, pp. 38-41, y epígrafe «Coplas de pie quebrado», p. 39 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Sextina | Cap. V, pp. 38-41, y epígrafe «Sestina», p. 41 | declara p. 38 y el pasaje cae en 41 |
| Morley y Bruerton 1968 | Versificación irregular | Cap. V, pp. 38-41, y epígrafe «Coplas», p. 39 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Villancico | Cap. V, pp. 38-41; epígrafes «Coplas», p. 39, y «Canción (Canzone)», p. 40 | declara p. 38 y el pasaje cae en 39 |
| Morley y Bruerton 1968 | Zéjel | Cap. V, pp. 38-41; epígrafes «Coplas», p. 39, y «Canción (Canzone)», p. 40 | declara p. 38 y el pasaje cae en 39 |
| Quilis 1969 | Endecha real | § 6.4.1, p. 162 | declara p. 162 y el pasaje cae en 145 |
| Quilis 1969 | Sextina | § 5.4.5.1, p. 100 | declara p. 100 y el pasaje cae en 101 |
| Navarro Tomás 1972 | Copla real | § 66, pp. 131-132 | declara p. 131 y el pasaje cae en 130 |
| Navarro Tomás 1972 | Cuarteto-lira | § 505, «Índice de estrofas», p. 533 | declara p. 533 y el pasaje cae en 530 |
| Navarro Tomás 1972 | Estrofa sáfica | §§ 119 y 120, pp. 212-214, e «Índice de estrofas», p. 535 | declara p. 212 y el pasaje cae en 15 |
| Navarro Tomás 1972 | Quintilla | §§ 131 y 154, pp. 221 y 247 | declara p. 221 y el pasaje cae en 220 |
| Navarro Tomás 1972 | Redondilla | § 68, nota 18, p. 134 | declara p. 134 y el pasaje cae en 133 |
| Navarro Tomás 1972 | Seguidilla · Real | § 216, p. 293 | declara p. 293 y el pasaje cae en 292 |
| Navarro Tomás 1972 | Sextina | «Índice de estrofas», s. v. «Sextina», p. 535 | declara p. 535 y el pasaje cae en 35 |
| Navarro Tomás 1972 | Verso aislado | § 76, «Glosa», pp. 149-150 | declara p. 149 y el pasaje cae en 147 |
| Navarro Tomás 1972 | Zéjel | §§ 14, pp. 50-51; 92, pp. 168-169; y 211, pp. 286-287 | declara p. 50 y el pasaje cae en 49 |
| Domínguez Caparrós 2014 | Canción petrarquista | § 11.1.2, pp. 214-215 | declara p. 214 y el pasaje cae en 12 |
| Domínguez Caparrós 2014 | Pareado | § 10.2.1, p. 184 | declara p. 184 y el pasaje cae en 11 |
| Domínguez Caparrós 2014 | Redondilla | § 8.3.5, p. 138 | declara p. 138 y el pasaje cae en 11 |
| Domínguez Caparrós 2014 | Septeto-lira | §§ 10.2.3 y 10.2.6, pp. 190 y 199-200 | declara p. 190 y el pasaje cae en 12 |
| Domínguez Caparrós 2014 | Sexteto | § 10.2.5, pp. 197-199 | declara p. 197 y el pasaje cae en 12 |
| Domínguez Caparrós 2014 | Sextilla | pp. 196-198, y § 4.4, pp. 65-66 | declara p. 196 y el pasaje cae en 10 |
| Domínguez Caparrós 2014 | Encadenamiento consonante | § 10.2.2, p. 185 | declara p. 185 y el pasaje cae en 11 |
| Diccionario 2016 | Canción petrarquista | Entradas «canción a la italiana», pp. 61-63, «canción alirada», pp. 60-61, y «estancia», pp. 163-164 | declara p. 61 y el pasaje cae en 437 |
| Diccionario 2016 | Novena | Entrada «novena», p. 240 | declara p. 240 y el pasaje cae en 130 |

### Localizadores que nadie puede seguir

Esto sí es un defecto, y no hace falta leer la fuente para verlo: **«Índice de estrofas» o
«Apartado sobre el verso libre» nombran un sitio sin decir cuál.** No acusan a la
afirmación de ser falsa; impiden comprobarla, que para una sección titulada «Lo que dicen
las fuentes» es igual de grave.


## Qué se extrajo

Un JSON por fuente en [`extractos/`](./extractos/), con el pasaje y su contexto para cada
afirmación que resuelve. Es lo único que ven los verificadores: **nunca el libro entero**.
