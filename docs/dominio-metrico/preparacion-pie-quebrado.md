# Preparación de los cambios de pie quebrado

26 de octubre de 2026. Trabajo en `main`, con commits separados de los del importador.
No aplicado a la base enlazada.

## Qué revisar

- [Toda la prosa, antes y después](./prosa-pie-quebrado.md): definiciones, descripciones,
  notas, ayudas y afirmaciones de fuentes, con sus localizadores.
- [Migración preparada](./migraciones-pendientes/20261026090000_el_quebrado_conserva_su_disposicion.sql).
- [Revisión filológica inicial](./revision-pie-quebrado-2026-10.md).

El SQL está deliberadamente fuera de `supabase/migrations`: un `db push` del otro chat
no debe aplicar un cambio que necesita el control de disposiciones del formulario V2.
La prosa del SQL coincide con los bloques «Después» del documento de revisión.
Tras la revisión, la nota de la quintilla enumera las dos disposiciones sin instrucciones
de registro. Se retiran también las negritas de las definiciones, descripciones y fuentes
de todo el catálogo; las guardas mantienen los valores anteriores exactos.

## Paginación contrastada visualmente

Se abrieron imágenes de las páginas y se leyeron los números impresos. No se obtuvo
ninguna cita sumando o restando una constante al número del visor. El índice del archivo
sirvió exclusivamente para localizar y renderizar la imagen.

| Original | Folios impresos comprobados | Pasaje que fundamenta el cambio |
| --- | --- | --- |
| Navarro Tomás, *Métrica española* | 129–130 | § 65, copla castellana; el § 66 comienza ya en 130 |
| Navarro Tomás | 130–132 | § 66, copla real |
| Navarro Tomás | 132–133 | § 67, copla novena en el apartado de coplas mixtas |
| Navarro Tomás | 134 | § 68: octavas, novenas 4+5 y 5+4; nota 17 sobre carácter rítmico |
| Navarro Tomás | 135 | Copla real con dos o más quebrados y oncenas |
| Navarro Tomás | 217 | § 124, nota 20: quintilla quebrada en 2.º/5.º |
| Navarro Tomás | 221 y 247 | § 131 y § 154: quintilla de quebrado inicial y su uso |
| Quilis, *Métrica española* | 103–104 | § 5.4.5.4, sextilla; variante de Unamuno en 104 |
| Quilis | 108–109 | § 5.4.7.4: octavillas y ejemplo de cuatro rimas con sexto quebrado |
| Domínguez Caparrós, *Diccionario* | 86 y 88 | Definiciones de copla de arte menor y castellana |
| *Diccionario* | 91–92 | Categoría general y ejemplo de Álvarez Gato en 92 |
| *Diccionario* | 390–391 | Entrada de sextilla quebrada en 390 y ejemplo de Lucas Fernández en 391 |
| Domínguez Caparrós, *Métrica española* (2014) | 196–197 y 202 | Manriqueña y definición de copla castellana con posibles tetrasílabos |
| Morley y Bruerton | 39 | Cinco a doce versos, expresamente referido a Lope |

El EPUB de Jauralde no tiene paginación impresa estable: se mantiene la referencia por
epígrafes. Se leyó «Quintilla octosilábica», que documenta también el doble quiebro en
segundo y último verso. No se le ha inventado una página.

Las imágenes de comprobación y los volcados de ensayo son material local ignorado,
no se incorporan al repositorio. Las citas de las fuentes no cambian de edición.

## Correcciones de fuentes

Se revisaron las afirmaciones vigentes de las cinco formas afectadas, así como las de
copla de arte menor. Esta última ya admite varios quebrados y no necesita una corrección
de dato. La migración actualiza nueve afirmaciones en las cinco formas:

- **Copla castellana, Quilis:** era falsa la negación de un ejemplo de cuatro rimas
  independientes. El de Bías de la p. 109 es `abba:cddc`, con sexto quebrado.
- **Copla castellana, Navarro:** se incorpora el § 68 y se localiza el § 65 en 129–130.
- **Copla castellana, Diccionario:** se explicitan la licencia general y el ejemplo de
  Álvarez Gato, sin confundir su entrada con la de sextilla.
- **Copla real, Navarro:** se incorpora la documentación de dos o más quebrados; se
  corrige el alcance del § 66 a 130–132.
- **Novena, Navarro:** se describen expresamente los quebrados de los dos órdenes.
- **Quintilla, Navarro y Jauralde:** se incorpora el patrón de 2.º/5.º.
- **Sextilla, Quilis y Diccionario:** se explicitan Unamuno y Lucas Fernández con 2.º/5.º.

No se reescriben las afirmaciones que no necesitan cambios ni se atribuyen decisiones al IP.

## Qué necesita el formulario V2

### Lo que sigue saliendo del catálogo

En copla castellana, copla real y los dos órdenes de novena, el control existente de pie
quebrado ya muestra posiciones y medidas a partir de las opciones de la base. Cambian
los candidatos, los límites y las ayudas. No hace falta inventar un formulario por forma.

### Lo que sí requiere código

**Sextilla y quintilla necesitan elegir una disposición completa.** La rejilla actual
solo conoce «estos versos se pueden quebrar» y «elige hasta N». En la sextilla, esa
regla permitiría seleccionar 2.º y 6.º, aunque los patrones declarados son 3.º/6.º y
2.º/5.º. El problema no lo resuelve limitar el número de selecciones a dos.

La interacción propuesta es:

1. Sextilla: **Tercero y sexto / Segundo y quinto**.
2. Quintilla: **Sin quebrados / Inicial / Segundo y quinto**.
3. Elegida la disposición, se mide cada quebrado: **4 / 5 sílabas**. La rima sigue aparte.

No se guarda un campo redundante de «disposición»: las medidas con posición ya
identifican el patrón. Al reabrir una respuesta antigua, el formulario deduce el patrón
3.º/6.º de sus posiciones. Cambiar de patrón deja sin medir las posiciones nuevas; no
inventa tetrasílabos ni conserva medidas en posiciones incompatibles.

La adaptación afecta a tres puntos:

- **Control compartido:** `MetricPartialPositionField.svelte`, usado tanto en una unidad
  como en la respuesta común a varias (`MetricChoiceField` y `MetricFamilyControl`).
  Debe recibir las disposiciones desde el catálogo, sin una lista de formas codificada.
- **Lectura de la medida:** al dibujar versos y rellenar los octosílabos implícitos, debe
  usarse el esquema compatible con las respuestas, no el primero de la arquitectura.
  De lo contrario una sextilla 2.º/5.º podría conservar las barras cortas de 3.º/6.º.
- **Validación:** el borrador ya comprueba el patrón completo al terminar el guardado,
  después de insertar todas las medidas. Rechaza las mezclas incluso si se envían por API.

No es una reescritura de todo el registrador ni del formato de anotación. La parte que
falta es la selección y lectura de patrones en V2, con pruebas de respuesta común,
excepciones por unidad, reapertura de respuestas antiguas y cambio de patrón.
**Ese código de interfaz no está incluido todavía en esta preparación.**

## Ensayo de la migración

Se ejecuta con una copia del esquema y los datos en un contenedor dedicado, sin red ni
puertos publicados. El programa no importa clientes de Supabase ni escribe producción:

```powershell
node scripts/catalogo/probar-pie-quebrado.mjs --esquema <copia-esquema.sql> --datos <copia-datos.sql>
```

Comprueba que se conservan exactamente las anotaciones, realizaciones, elecciones y
desviaciones anteriores, que ninguna pierde su opción al resolverla con el catálogo nuevo,
los patrones antiguos y nuevos, el rechazo de híbridos, las alternativas de cuatro/cinco
sílabas, los candidatos de ambas novenas y las restricciones diferidas con rol autenticado.

**Resultado del ensayo:** todas esas comprobaciones pasan. Se ejecutó también el auditor
de conformidad sobre el catálogo aislado con las filas de la vista de opciones exportadas
para su lectura local: **0 defectos**. Esto comprueba el modelo del catálogo; no sustituye
las pruebas visuales y de interacción del V2, que todavía no se ha adaptado.

Antes de aplicar a producción faltan: revisar la prosa, completar y verificar el control V2,
probar la ficha pública y el recorrido completo de guardado, y repetir los auditores del
catálogo y las anotaciones contra el resultado. Solo entonces debe trasladarse el borrador
a `supabase/migrations` y desplegarlo junto con la interfaz.
