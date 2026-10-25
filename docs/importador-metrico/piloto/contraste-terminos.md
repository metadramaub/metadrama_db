# Contraste de los términos del primer lote

Estado a 22 de octubre de 2026: **pasajes relevantes consultados directamente en las seis
fuentes bibliográficas del catálogo**. La biblioteca se ha leído desde
`C:\Users\david\OneDrive - UAB\Investigacion\fuenteovejuna-data-sync\bibliografía`.
No se ha modificado ni se ha configurado su sincronización.

El [registro de evidencia](./bibliografia-contraste.json) identifica los originales por SHA-256,
con páginas impresas, páginas PDF y el archivo interno del EPUB cuando corresponde. Se usaron
los volcados para buscar, se leyeron las páginas pertinentes completas y se cotejaron visualmente
páginas clave del Diccionario, Quilis, Navarro Tomás y Morley y Bruerton. Jauralde se contrastó
con el EPUB original. La [consulta del catálogo vivo](./consulta-bibliografica-catalogo.json)
se conserva aparte: ya no es el único apoyo de este contraste. La referencia local se amplió,
solo mediante SELECT, para incluir Villancico, Zéjel y Romancillo.

Leer estos libros no equivale a una aprobación humana de las correspondencias ni a comprobar
la forma concreta de los pasajes teatrales. La regla de estancias fue después aprobada por el
responsable al nivel de forma, con remate declarado; las restantes siguen siendo propuestas.

## «Tercetos» en Los donaires de Matico

Dos filas, t01 y t09, abarcan 127 y 145 versos. La denominación no incluye «encadenados».
La hipótesis de distinguirlos por la omisión del adjetivo no tiene respaldo como regla universal:

- Domínguez Caparrós, *Diccionario* (2016), entrada «terceto», pp. 427-428, define directamente
  la serie encadenada y remite a ella desde «terceto encadenado». El «terceto independiente»
  tiene entrada aparte, p. 429. Se verificaron las pp. PDF 429-431 y la imagen de la p. 427.
- Quilis, § 5.4.2.1, pp. 92-93 (p. PDF 47, pliego doble), describe ambas posibilidades y considera
  los encadenados el caso más frecuente. También documenta el uso de independientes en Lope.
- Morley y Bruerton, cap. V, p. 40 (p. PDF 42), separan Terza rima y tercetos sin encadenar.
  Para estos últimos admiten ciertos cierres en pareado o cuarteto.

Por tanto, la omisión de «encadenados» puede ser abreviación o una diferencia de nomenclatura,
no una declaración de independencia. Compartir colección tampoco basta si cambian los editores.
El corpus mínimo conserva esta ambigüedad. Solo una correspondencia terminológica reutilizable
permitiría resolver otros usos de la etiqueta; no se exige consultar el texto de cada obra.

Indicio aritmético: 127 = 3 × 42 + 1 y 145 = 3 × 48 + 1, compatibles con cadenas rematadas.
No es una prueba de encadenamiento. Hay además una coincidencia específica en Morley y Bruerton,
p. 241 (p. PDF 243): describen dos pasajes de tercetos en *Matico*, con un máximo de 145 versos.
La ficha no explicita allí el patrón de rima; tampoco basta para resolver la correspondencia.

**Decisión del responsable:** mantener Terceto y Terceto encadenado como candidatas orientativas,
sin convertir la compatibilidad del módulo ni la frecuencia histórica en identificación. Identificar
un pasaje aislado no resuelve el uso terminológico de las demás sinopsis; el cotejo del texto no
es un requisito de este procedimiento.

## «Estancias con pareado final» en El verdadero amante

La relación de estancia con canción queda confirmada en las fuentes originales:

- *Diccionario*, entrada «estancia», pp. 163-164 (PDF 165-166): unidad estrófica de la canción
  italiana, con cierre frecuente en pareado y articulación no obligatoria en fronte, eslabón y sirima.
- Quilis, § 6.3.6, pp. 142-143 (PDF 72): composición en estancias, repetición de su patrón y envío.
- Navarro Tomás, § 108, pp. 205-206 (PDF 198-199): estrofa de canciones y églogas renacentistas,
  con variación de longitud y combinaciones.
- Domínguez Caparrós (2014), § 11.1.2, pp. 214-215 (PDF 211-212): describe estancias rimadas,
  sus pareados frecuentes y su repetición en la canción.
- Jauralde (2020), apartados «Canción» y «Estancias»: relación con la canción y patrones que
  pueden adoptar estructuras más rígidas o flexibles. El EPUB no ofrece paginación impresa estable.

**El pareado final no identifica Canción sin rima.** También aparece en estancias rimadas.
Morley y Bruerton distinguen explícitamente la canción rimada de la que carece de rima salvo
en el pareado final: cap. V, pp. 40-41, y estudio de las estrofas, pp. 175-178.

Hay una pista específica comprobada en la imagen de la p. 176 (PDF 178): sitúan
*El verdadero amante* bajo canción rimada de estancias mezcladas de 13, 13, 13, 14 y 15 versos,
y muestran sus rimas. Suman 68. La sinopsis fotografiada, t02, vv. 221-287, declara 67.
La coincidencia de obra orienta hacia Canción, pero no confirma que sea el mismo pasaje,
delimitación o texto base. No se cambia el recuento de nuestra edición ni se inventa una laguna.

**Decisión posterior del responsable:** normalizar «estancias con pareado final» como **Canción**,
sin arquitectura ni patrón específico. El pareado final se interpreta como **remate o envío**,
sección ya permitida en el modelo (comprobada por SELECT: sección raíz opcional de Canción).
Se conserva como detalle declarado sin construir todas las estancias ni dar por conocidos sus
límites internos. No se exige cotejar el texto: se adopta una correspondencia terminológica al
nivel que admite la fuente. La comparación de 67 y 68 versos queda como hallazgo bibliográfico,
sin condicionar esta normalización ni modificar la edición base.

## «Letrilla» en El molino

La denominación no determina una sola forma ni demuestra canto en los vv. 2880-2888:

- *Diccionario*, entrada «letrilla», pp. 216-217 (PDF 218-219): relación formal con villancico
  o romance; menciona también redondillas o quintillas dobles como estrofas, diferentes rimas,
  octosílabo o hexasílabo y estribillo. La propia entrada admite temas líricos y religiosos,
  además de los burlescos y satíricos. Se cotejó visualmente la p. 216.
- Quilis, § 6.3.1, pp. 124-125 (PDF 63): la aproxima al villancico y distingue su contenido
  satírico más que su forma. Se leyó el pliego doble y se comprobó su imagen.
- Navarro Tomás, § 146, pp. 236-237 (PDF 229-230): documenta letrillas que son zéjeles,
  villancicos octosílabos o hexasílabos y romancillos hexasílabos. Se comprobó la imagen de
  la p. 237. Es un contraejemplo directo a una equivalencia única letrilla → villancico.
- Jauralde, «Estrofas con estribillo», pasaje que comienza «En cuanto al término letrilla»,
  en `OEBPS/05_TEXTOS-9_split_005.xhtml`: reconoce la inespecificidad del nombre y su uso
  para romances, décimas y quintillas con estribillo, además de villancicos.

**Decisión del ensayo:** ofrecer Villancico, Zéjel, Romance y Romancillo como ejemplos
estructurales documentados que orientan la revisión. La lista no es exhaustiva: los ejemplos
de Jauralde bastan para mostrar que quedan otras posibilidades. No se ponderan ni se usan
para cerrar límites de un cálculo. Redondillas y quintillas pueden describir el cuerpo de
una composición: no se asignan automáticamente como forma de toda la letrilla.

No se afirma canto, métrica concreta, estribillo localizado ni carácter satírico en *El molino*.
La etiqueta y los nueve versos se conservan. Pasar de «sin candidatas» a una lista orientativa
**no aumenta la cobertura de formas identificadas**: el pasaje sigue sin una correspondencia única.

## Aplicación al piloto

Las reglas v0.4 incorporan las referencias y la decisión explícita sobre las estancias. La
aprobación procede del responsable, no de una autoevaluación bibliográfica de la IA. El lote
conserva 11.754 versos: **67 con forma Canción revisada**, 11.406 con destino único propuesto y
281 entre candidatas orientativas (272 de «tercetos» y 9 de «letrilla»). Las arquitecturas de
los 67 versos permanecen sin identificar. No se exige resolver las ambigüedades mirando el texto
ni se condiciona a ello el uso futuro de los datos que sí están identificados.

La aceptación de las cuatro transcripciones permanece intacta. Las dos desviaciones acordadas
de *Los locos* mantienen sus notas y rangos originales. Las actualizaciones son locales; no se
escribe en la DB, no se importa ninguna obra y no se modifica el catálogo.
