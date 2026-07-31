# Cuestiones para el IP

Actualizado: 31 de julio de 2026

Este archivo reúne solo decisiones pendientes. Las decisiones ya tomadas están en la
ficha de cada revisión.

## Los defectos del informe que esperan una decisión

El [informe de conformidad](../informe-conformidad-catalogo.md) señala **20 defectos**. Ni
uno solo puede corregirse sin decidir algo: todos tocan la norma de una forma o el nivel en
que vive un hecho métrico. Los que no dependían de una decisión editorial ya están
corregidos.

Esta es la correspondencia entre cada defecto y la decisión que lo desbloquea. Las
preguntas están desarrolladas en el apartado de cada forma, más abajo.

| Defecto | Cuántos | Qué hay que decidir |
| --- | ---: | --- |
| D9 · rasgos cualitativos como restricciones sin catalogar | 15 | Qué rasgos existen, qué valores admite cada uno y con qué modalidad interviene en cada arquitectura. Quince literales sueltos —`pareados_sistematicos`, `predominio_versos_sueltos`, `distico_final`…— esperan una taxonomía, no una traducción mecánica. |
| D12 · preguntas con alcance de secuencia | 4 | Si los tres esquemas de la copla de arte mayor pueden alternar dentro de una tirada; si las medidas del villancico y del zéjel forman repertorio cerrado. |
| D2b · arquitecturas sin ninguna declaración de rima | 1 | Qué rima declara el terceto encadenado octosílabo. |

Los quince primeros son en realidad **una sola decisión**: la taxonomía de rasgos
cualitativos. Sin ella, quince propiedades transversales siguen siendo literales sueltos
colgados de un esquema de rima.

Ninguno bloquea el registro: el editor funciona con el catálogo tal como está. Lo que
bloquean es la comparación entre formas, que es para lo que existe el informe.

## Quintilla

Véase [quintilla.md](./quintilla.md).

1. ¿Los ocho esquemas forman un repertorio cerrado o son los reconocidos hasta ahora?
2. ¿Por qué no se incluye `aabaa`?
3. ¿`abbaa` y `ababb`, con pareado final, son variedades ordinarias?
4. ¿La definición pública debe explicar la diferencia con la preceptiva general?

## Tercetos

Véase [tercetos.md](./tercetos.md).

1. ¿El terceto octosilábico conserva siempre el encadenamiento? Su arquitectura no declara
   hoy ninguna rima.
2. ¿Un verso excepcional sin rima es variante admitida o desviación?
3. ¿La repetición de una rima cuatro veces es variante o desviación?
4. ¿Cuántas unidades mínimas exige una serie encadenada?
5. ¿Los cierres en pareado o cuarteto de las antiguas series sin encadenar son canónicos?

Resuelto en el modelo: `tercetos_sin_encadenar` no era una forma sino una tirada de
tercetos. Sus dos disposiciones —`A-A`, con el verso central suelto, y `-AA`, con el
primero— son los dos esquemas de rima del terceto, y el editor elige entre ellas. El
encadenado sigue siendo forma aparte porque su rima cruza el límite de la unidad y la
secuencia entera es una sola unidad abierta.

## Silva

Véase [silva.md](./silva.md).

1. ¿`silva libre` tiene el alcance específico del corpus —7 y 11, consonancia libre— o
   el alcance moderno más amplio?

## Series endecasilábicas y pareado

Véase [series-endecasilabicas.md](./series-endecasilabicas.md).

1. ¿El pareado de arte menor admite rima asonante además de consonante? El vocabulario
   heredado dejó su tipo de rima como «otras» y el modelo lo conserva sin declarar; si la
   norma exige consonancia, basta con declararla.
2. ¿El arte mayor del pareado debe limitarse al endecasílabo o conviene mantener abierto el
   rango a dodecasílabos y alejandrinos, que hoy se ofrecen?

Resuelto en el modelo: el pareado es **cualquier dístico** —dos versos que riman entre sí,
sea cual sea su medida— y una forma general que puede formar series, como el terceto o el
sexteto. Quedan dos arquitecturas, arte menor y arte mayor, porque el arte es el corte que
la tradición hace y el que se corresponde con el régimen de rima. La medida exacta no es
arquitectura: el pareado no tiene repertorio cerrado de medidas, así que la declara el pasaje
y se pregunta por posición, lo que además permite registrar el dístico heterométrico.
`pareados_endecasilabos` era una tirada de pareados de arte mayor, y `pareado_hexasilabo` y
`pareado_octosilabo` eran dos medidas dentro del arte menor, no dos arquitecturas.

## Soneto

Véase [soneto.md](./soneto.md).

1. ¿`CDCDCD` debe seguir siendo el patrón preferente?
2. ¿`ABBA ABBA` es obligatorio para el corpus o se admite `ABAB ABAB`?
3. ¿Los cuatro esquemas de tercetos son un repertorio abierto o cerrado?
4. ¿Estrambote y sonetillo se incorporarán solo si aparecen en el corpus?

## Villancico

Véase [villancico.md](./villancico.md).

1. ¿La mudanza se presenta como una sección de cuatro versos o como dos mudanzas
   simétricas?
2. ¿El enlace o vuelta puede tener cualquier extensión desde un verso?
3. ¿`abba` y `abab` son esquemas cerrados o solo habituales?

Resuelto en el modelo: la ausencia de cabeza no se trata como omisión. Si el estribillo
aparece por primera vez después de la primera copla, se selecciona una arquitectura
propia; las apariciones posteriores se registran como represas y la implícita no crea
versos ficticios. Una sección final aislada solo se considera estribillo si existe
evidencia funcional.

## Zéjel

Véase [zejel.md](./zejel.md).

1. ¿Se admiten estribillos de uno y de dos versos o el zéjel estricto exige dístico?
2. ¿Una represa parcial es posibilidad admitida o desviación?
3. ¿Las medidas 6 y 8 forman un repertorio cerrado para el corpus?

## Copla real

Véase [coplas-y-sextillas.md](./coplas-y-sextillas.md).

1. ¿Los quebrados pueden ocupar cualquiera de las diez posiciones?
2. ¿Se admiten únicamente tetrasílabos o también pentasílabos?
3. ~~¿Las dos quintillas reutilizan el repertorio de ocho esquemas ya reconocido?~~
   **Resuelto: sí.** Cada sección declara la arquitectura de la quintilla con
   `arquitectura_referenciada_id` y sus opciones señalan los ocho esquemas de la quintilla.
4. ~~¿La arquitectura quebrada es admitida o canónica?~~ **Resuelto: es un rasgo, no una
   arquitectura.** Llevar quebrados no cambia la norma —diez octosílabos en dos
   quintillas—, así que las dos arquitecturas se han fundido en una y `pie_quebrado` queda
   como rasgo admitido.

## Coplas y sextillas

Véase [coplas-y-sextillas.md](./coplas-y-sextillas.md).

1. **Nada en el modelo distingue dos sextillas consecutivas de una doble sextilla.** Los
   versos, las medidas y el tipo de rima son los mismos; solo cambia si las rimas de la
   segunda mitad dependen de la primera. Hoy lo afirma el editor al elegir arquitectura.
   ¿Debe seguir siendo así o hay un criterio observable que lo decida?
2. ¿La sextilla de pie quebrado es exactamente `8-8-4-8-8-4`? La bibliografía documenta
   también sextillas heterométricas con otra distribución; si el corpus las trae, serían una
   arquitectura más.
3. ¿Las medidas 6, 7 y 8 forman un repertorio cerrado para la sextilla isométrica?
4. ¿Debe registrarse el esquema exacto de las dobles sextillas no manriqueñas?
5. ¿Los tres esquemas de copla de arte mayor son un repertorio cerrado?
6. ¿Copla de arte menor y copla castellana se incorporarán solo si aparecen en el
   corpus?

Resuelto en el modelo: la medida de la sextilla es arquitectura y no pregunta, porque es
isosilábica; la doble sextilla es su arquitectura de doce versos y no otra forma; y «copla
manriqueña» es la denominación del esquema `abcabc:defdef` de esa arquitectura, no una
forma. `copla_de_pie_quebrado` sigue siendo una forma general, registrable, de 5–12 versos,
para los casos que no encajan en una más específica, y sus quebrados se registran como
medida de una posición, no como doce casillas sueltas. El rasgo `pie_quebrado` permanece
separado y reutilizable.

## Décimas

Véase [decimas.md](./decimas.md).

1. ¿El linaje debe limitarse por ahora a copla real, décima espinela y décima
   aumentada?
2. ¿Se mantiene «Décima aumentada» como nombre público preferente?
3. ¿La definición pública de la espinela debe conservar la expresión «dos redondillas
   enlazadas por dos versos puente»?

Resuelto en el modelo: `decima` no es una forma. Lo que une a la espinela, la copla real y
la aumentada son relaciones tipadas —`sucede_historicamente_a` y `derivada_de`—, no una
pertenencia. La espinela y la aumentada son formas fijas sin preguntas propias en el
registrador.

## Redondilla

Véase [redondilla.md](./redondilla.md).

1. **¿Puede alternar `abba` y `abab` dentro de una misma tirada?** Si no puede, son dos
   arquitecturas más y la redondilla se registra sin ninguna pregunta. Mientras la duda
   siga abierta se mantiene como esquema elegido por unidad, que es la opción reversible:
   corregirlo después es reclasificar filas, mientras que haberlo tratado como
   arquitectura habría partido secuencias que no debían partirse.
2. ¿Debe incorporarse «octavilla» como denominación relacionada o resultaría
   demasiado amplia?

Resuelto en el modelo y aplicado en el dato: existe una única forma `redondilla`. Por su
isosilabismo, las medidas 6, 7 y 8 son tres arquitecturas y no una elección; la doble
enlazada es una cuarta, de ocho versos; «Cuarteta» es denominación **posterior** del esquema
cruzado, no equivalente, porque en el Siglo de Oro ambas disposiciones eran redondillas; la
hexasílaba se corrige a seis sílabas.

## Octava real

Véase [octava-real.md](./octava-real.md).

Sin decisiones imprescindibles pendientes. El catálogo mantiene el alcance
endecasilábico del proyecto y no incorpora automáticamente la octavilla real
excepcional documentada en la bibliografía.

## Novena

Véase [novena.md](./novena.md).

1. ¿Las rimas de redondilla y quintilla son siempre independientes o debe registrarse
   una clase compartida entre ambas secciones?
2. ¿Las ocho variedades actuales de quintilla se ofrecen dentro de toda novena?
3. ¿Las demás estrofas de nueve versos quedan fuera salvo que aparezcan en el corpus?

Resuelto en el modelo: `novena_canonica` y `novena_invertida` son arquitecturas de una
única forma; sus secciones reutilizan las arquitecturas de redondilla y quintilla sin
copiar sus esquemas.

## Sexteto-lira

Véase [sexteto-lira.md](./sexteto-lira.md).

1. ¿Las siete variedades son un repertorio cerrado, las reconocidas hasta ahora o
   medida y rima pueden combinarse libremente? Si aparecen otras parejas restringidas,
   se ampliarían las combinaciones; solo si ambos ejes son independientes se
   preguntarían por separado.
2. ¿A1 debe seguir presentándose como variedad habitual o preferente?
3. ¿Una tirada puede cambiar de variedad entre estrofas sin dejar de constituir una
   única secuencia?

## Sexteto

Véase [sexteto.md](./sexteto.md).

- No bloquea el registro actual: el proyecto lo delimita como seis versos de arte mayor
  consonantes, repartidos en tres arquitecturas por medida —11, 12 y 14—.
- Si el corpus documenta un sexteto que combine arte mayor y menor y no sea sexteto-lira,
  confirmar si debe ampliarse la forma o crearse otra.
- ¿Las medidas 11, 12 y 14 forman un repertorio cerrado?

Resuelto en el modelo: la sexta rima no es una forma sino una **variedad** de la
arquitectura endecasilábica del sexteto, con «Sexta rima» y «Sexteto clásico» como
denominaciones. No añade ninguna norma que la arquitectura no tenga ya: concreta una de sus
realizaciones y le pone nombre. El sexteto-lira, en cambio, no es ni arquitectura ni
variedad suya: su heterometría es principio constructivo y su genealogía va a la lira,
declarada como `sexteto_lira derivada_de lira`.

## Seguidilla

Véase [seguidilla.md](./seguidilla.md).

- No bloquea el registro actual: se distinguen las arquitecturas simple y compuesta
  con la norma asonante fijada por el proyecto.
- Si las oscilaciones métricas o las realizaciones consonantes fueran recurrentes en el
  corpus, confirmar si deben seguir siendo desviaciones o convertirse en opciones
  admitidas.

## Sextina

Véase [sextina.md](./sextina.md).

- No bloquea el registro: la definición del proyecto permite distinguir la clásica de
  la doble y ambas conservan la misma regla de permutación.
- Confirmar únicamente si debe fijarse el orden de las seis palabras dentro del remate.
  Por ahora se exige su presencia —tres interiores y tres finales— sin imponer parejas.

## Canción petrarquista

Véase [cancion-petrarquista.md](./cancion-petrarquista.md).

1. ¿La canción sin rima o canción libre debe seguir siendo arquitectura de la canción
   petrarquista o tiene identidad suficiente para ser forma?
2. ¿Debe exigirse siempre remate o envío en las canciones registradas?
3. ¿Se mantiene el mínimo de 5 versos por estancia fijado por el proyecto, pese al
   mínimo de 9 indicado por Domínguez Caparrós?

Resuelto en el modelo: 8, 9 y 15 son extensiones de estancia; una estancia solo
endecasílaba se obtiene eligiendo 11 sílabas en todas sus posiciones.

## Romance heroico

Véase [romance-heroico.md](./romance-heroico.md).

Sin cuestiones pendientes. Se modela como arquitectura endecasílaba de romance porque
conserva íntegramente su arquitectura y solo cambia la medida. `Romance real` se
mantiene como denominación equivalente conforme al criterio del IP.

## Romancillos

Véase [romancillo.md](./romancillo.md).

1. ¿`Endecha` y `Romance endecha` deben mantenerse como denominaciones equivalentes
   tanto del romancillo hexasílabo como del heptasílabo, según los datos actuales del
   IP, o reservarse para el heptasílabo?

Resuelto en el modelo: no se crea una forma Romancillo. Las realizaciones
de 6 y 7 sílabas son arquitecturas exactas de `romance`; la antigua raíz ambigua solo
obliga a revisar las secuencias heredadas que no permitan determinar su medida.

## Tramos sin forma

Véase [tramos-sin-forma.md](./tramos-sin-forma.md).

1. Confirmar si `Verso aislado` debe ser la etiqueta pública definitiva de la antigua
   entrada `verso suelto`.

Resuelto en el modelo: `Versificación irregular` y `Verso aislado` son salidas
editoriales, no formas. La primera exige dos o más versos y la segunda exactamente uno.
Una forma reconocible con excepciones se registra mediante desviaciones y no mediante
estas salidas.
