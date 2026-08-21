# Las fuentes del catálogo

Estado: **vigente** · las seis monografías con las que se contrastó el catálogo entero

Cada afirmación del catálogo métrico cuelga de una de estas seis y solo de estas seis. Este
documento dice cuáles son, por qué solo seis, dónde están los ficheros y cómo se localiza un
pasaje para citarlo. Se separó de
[la revisión del catálogo](./historico/revision-del-catalogo-2026-07-a-08.md) —hoy archivada—
porque el proceso terminó y esto no: gobierna cualquier afirmación que se añada de aquí en
adelante.

## Las seis

| Fuente | Volcado en `bibliografía/txt/` |
| --- | --- |
| Morley y Bruerton 1968, _Cronología de las comedias de Lope de Vega_ | sus definiciones, ya en `.md` |
| Quilis 1969, _Métrica española_ | `Quilis-1969-metrica-espanola.txt` |
| Navarro Tomás 1972, _Métrica española_ | `Navarro-Tomas-1972-metrica-espanola.txt` |
| Domínguez Caparrós 2014, _Métrica española_ | `Dominguez-Caparros-2014-metrica-espanola.txt` |
| Domínguez Caparrós 2016, _Diccionario de métrica española_ | `Dominguez-Caparros-1999-diccionario-metrica.txt` |
| Jauralde Pou 2020, _Métrica española_ | `Jauralde-Pou-2020-metrica-espanola.txt` |

**El fichero del Diccionario dice 1999 en su nombre pero es la 3.ª edición de 2016.** El nombre
refiere a la edición original.

**El de Morley y Bruerton es `definiciones_Morley&Bruerton.md`**, en `.md` y sin sus apellidos al
principio: las búsquedas por `.txt` no lo encuentran y ya se dio dos veces por ausente cuando
estaba ahí.

El directorio `bibliografía/` está fuera de git. Si faltan los volcados se regeneran con
`pdftotext -layout -enc UTF-8`; el epub de Jauralde se extrajo descomprimiéndolo y limpiando
etiquetas. **`metrica-clasificacion.pdf` no sirve para esto**: es un artículo sobre repertorios
métricos, no un manual de definiciones.

## Por qué solo seis

Antes había once. Las otras cinco se retiraron porque no cumplían el criterio de autoridad:
**publicación bibliográfica académica identificable**. Las tres formas que se quedaron sin
respaldo al retirarlas —décima, copla de pie quebrado y villancico— lo recuperaron contrastando
las seis autorizadas, y la copla real y el zéjel se rehicieron desde cero afirmaciones el 8 de
agosto de 2026.

**Morley y Bruerton describen a Lope**, no el Siglo de Oro entero, y el catálogo es
deliberadamente más amplio en varios puntos —la redondilla cruzada, la copla real—. Esa
diferencia se registra como afirmación propia; no es un desacuerdo que haya que ocultar. Su
repertorio tampoco tiene ninguna forma con estribillo ni ninguna estrofa de nueve versos, y lo
que no encaja lo reúnen bajo «coplas»: eso también se registra, porque un silencio suyo dice
algo.

## La regla de exhaustividad

La revisión de las seis fuentes es **exhaustiva, no selectiva**. Cada fuente que menciona una
forma recibe su propia afirmación, aunque repita sustancialmente lo dicho por otra. Las
diferencias, variantes y aspectos no formalizados se destacan en el resumen, pero la coincidencia
entre autores nunca es motivo para omitir una fuente. **Una fuente solo queda fuera de una forma
cuando, después de revisar el pasaje y su contexto, no la trata** — y entonces conviene decir que
no la trata, que es un dato.

Una afirmación pertenece a **una sola forma**: no se reutiliza el mismo texto en varias. Si dos
formas comparten un rasgo, cada una cita el pasaje que le toca.

Y la nota da el dato; **quién lo dice va en la afirmación**, no en la nota. Ver
[dónde vive la prosa](./donde-vive-la-prosa.md).

## Cómo se localiza un pasaje

`node scripts/lib/localizar.mjs <fichero> "<texto literal>"` devuelve la página. Funciona con
Caparrós 2014, el Diccionario y Quilis (que da pares, porque el PDF escaneó pliegos dobles).

**No funciona con Navarro Tomás ni con Jauralde.** El primero conserva 37 números de página en
todo el libro: se cita por `§` numerado. El segundo viene de un epub sin paginar: se cita por el
título de la sección. El Diccionario, alfabético, se cita `s. v. «entrada»`. Morley y Bruerton se
citan por capítulo y epígrafe.
