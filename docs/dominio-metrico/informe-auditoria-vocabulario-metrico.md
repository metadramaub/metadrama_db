# Auditoría del vocabulario de formas métricas y su uso en el demarcador

Fecha de la auditoría: 28 de julio de 2026

Estado de los datos consultados: base remota, 119 términos activos; última actualización detectada: 20 de julio de 2026

Alcance: vocabulario `estrofa_tipo`, relaciones con `metro`, definiciones, jerarquía y campos estructurados

## Resumen ejecutivo

Se han revisado las 119 formas activas, sus 133 relaciones con metros y su organización en 31 raíces y 88 hijos. El problema no es únicamente que haya algunos valores equivocados. El árbol mezcla en un mismo nivel entidades de naturaleza diferente:

1. formas métricas reconocibles (`soneto`, `lira`, `romance`);
2. familias o agrupadores (`cancion_petrarquista`, `irregular`);
3. realizaciones de un esquema (`quintilla_1_ababa`, variantes del soneto);
4. rasgos transversales (`de_esdrujulos`, vocales concretas de la asonancia del romance);
5. decisiones editoriales o categorías residuales (`verso suelto`, `irregular`).

Esta mezcla explica buena parte del comportamiento anómalo del demarcador. El caso que motivó la revisión es representativo: `copla_real` declara únicamente metro 8, aunque su definición admite pies quebrados y su hija `copla_real_de_pie_quebrado` declara 4 + 8. El motor pregunta primero por familias usando solo el registro raíz; por eso una respuesta correcta para la variante descarta la familia antes de llegar a ella.

Hay además errores objetivos que pueden corregirse sin debate filológico:

- `redondilla_hexasilaba` está asociada a 7 sílabas;
- dos quintillas de cinco versos declaran tamaño 6;
- un sexteto-lira con patrón de seis posiciones declara tamaño 4;
- `sexteto_lira_de_esdrujulos` declara tamaño 5;
- `terceto_de_esdrujulos` declara tamaño 1;
- tres formas carecen de definición;
- el único campo bibliográfico no vacío contiene `****`.

La recomendación principal es no seguir añadiendo excepciones al árbol actual. Conviene separar la **forma canónica** de sus **rasgos y realizaciones**, declarar qué nodos son agrupadores y cuáles son seleccionables, y modelar metro y rima como alternativas ordenadas. El demarcador debe construirse después a partir de esas alternativas, no interpretar cada padre como si fuera una forma homogénea.

## 1. Método y límites

La auditoría ha combinado:

- lectura de las 119 fichas actuales, incluidas sus definiciones;
- controles automáticos de tamaño, patrón, metro, jerarquía, etiquetas y cobertura documental;
- comparación entre padres e hijos;
- contraste con manuales de métrica española y estudios académicos;
- comparación conceptual con PoeMetCa, ReMetCa, TEI Verse y POSTDATA.

No se ha considerado que una divergencia terminológica sea automáticamente un error. En métrica hay usos históricos amplios —por ejemplo, `redondilla` puede funcionar como hiperónimo en ciertos tratados— y clasificaciones creadas para un corpus concreto. El informe distingue:

- **error confirmado**: contradicción interna o valor imposible;
- **revisión filológica**: la decisión puede ser válida, pero necesita fuente y criterio explícito;
- **problema de modelo**: la información puede ser correcta, pero está almacenada en una entidad o campo inadecuados.

PoeMetCa y ReMetCa son repertorios de corpus, no autoridades normativas suficientes por sí solos. Resultan especialmente útiles para el modelado: PoeMetCa separa cantidad de versos, firma silábica, esquema y valores concretos de rima; ReMetCa combina un modelo relacional con TEI para admitir metadatos variables. TEI distingue estructura métrica convencional (`met`), realización (`real`) y esquema de rima (`rhyme`), con herencia explícita. POSTDATA distingue patrones de verso, estrofa y obra. Estas separaciones son más apropiadas para METADRAMA que el árbol monodimensional actual.

## 2. Estado cuantitativo

| Indicador | Resultado |
| --- | ---: |
| Formas activas | 119 |
| Raíces | 31 |
| Hijos | 88 |
| Relaciones con metros | 133 |
| Huérfanos jerárquicos | 0 |
| Sin etiqueta editorial | 77 |
| Identificadores no normalizados | 18 |
| Sin definición | 3 |
| Sin bibliografía | 118 |
| Con bibliografía válida | 0 |
| Sin ejemplo | 113 |
| Sin metro propio | 23 |
| Sin tipo de rima propio | 33 |
| Sin naturaleza estrófica propia | 43 |
| Sin tamaño fijo declarado | 52 |
| Sin patrón específico | 77 |

La falta de datos propios en un hijo no es necesariamente un error: puede expresar herencia. El problema es que `null` se usa simultáneamente para “hereda”, “desconocido”, “variable”, “no aplicable” y “no fijado”. Esos estados no son equivalentes.

## 3. Correcciones objetivas prioritarias

### P0 — valores que pueden corregirse tras una comprobación editorial mínima

| Forma | Dato actual | Problema | Corrección propuesta |
| --- | --- | --- | --- |
| [`redondilla_hexasilaba`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=7f1bcbaf-834e-4c6f-8190-2547a066a6df) | Metro: 7 | El término y la definición dicen “hexasílaba”. | Cambiar la relación a metro 6. |
| [`quintilla_5_aabba`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=e493cc23-0fc8-4fcf-9516-7e220ca77004) | Tamaño: 6; patrón: `aabba` | El patrón tiene cinco posiciones y es una quintilla. | Tamaño 5. |
| [`quintilla_7_ababb`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=e43a29b8-6756-4c3e-be01-5adffb4c9a13) | Tamaño: 6; patrón: `ababb` | El patrón tiene cinco posiciones y es una quintilla. | Tamaño 5. |
| [`sexteto_lira_c1_AabBcC`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=70db0ad6-00e1-4699-bb9b-659cbb6d886e) | Tamaño: 4; patrón: `AabBcC` | El patrón tiene seis posiciones. | Tamaño 6. |
| [`sexteto_lira_de_esdrujulos`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=c6e16938-cec7-4c3c-950e-7dbe1f600fa4) | Tamaño: 5 | Un sexteto-lira tiene seis versos; “esdrújulos” no altera el tamaño. | Tamaño 6 y trasladar el rasgo esdrújulo fuera del tipo de forma. |
| [`terceto_de_esdrujulos`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=baa17a25-a1db-407c-8d9d-9c7ee33e45aa) | Tamaño: 1 | Contradice el nombre, el padre y la definición. | Tamaño 3 si representa una unidad; si representa una serie, declarar otro nivel estructural. |
| [`pareado_endecasilabo`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=f44a79b4-46d1-47c1-87cf-50e2e4b72f08) | Definición vacía | La explicación se ha introducido erróneamente como equivalencia. | Moverla a definición y retirar el umbral 99–100 % salvo justificación bibliográfica expresa. |
| [`redondilla`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=1affe499-c92d-4cf0-a0f6-46c76a26f88f) | Definición vacía | La raíz es candidata del demarcador y no documenta el criterio. | Añadir definición y decidir si es forma canónica o agrupador histórico. |
| [`sexteto_lira_a3_abaBcC`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=d8fd022b-c275-46a7-a503-f0c205fd82ef) | Definición vacía | Es la única variante de la familia sin explicación. | Añadir definición o generar la descripción desde el patrón. |
| [`sexta_rima`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=df645af0-0ab3-43f1-b357-b58793d39c2b) | Bibliografía anterior: `****` | Resuelto en el catálogo métrico. | Sustituido por Domínguez Caparrós (2014, p. 199). |

### P0/P1 — datos incompletos que producen inferencias incorrectas

1. **Copla real.** La raíz declara solo 8 sílabas, pero su definición dice que puede incluir uno o dos pies quebrados y una hija declara 4 + 8. Si la raíz es un agrupador, no debe tener una única firma métrica. Debe admitir las alternativas `{8}` y `{4,8}`. La naturaleza estrófica falta tanto en la raíz como en `copla_real_de_pie_quebrado`.

2. **Sextilla de pie quebrado.** [`sextilla_de_pie_quebrado`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=e0e17a64-23d8-4bfb-9b74-3fd8ea9d9938) no declara metros y hereda actualmente 6 + 7 + 8 de `sextilla`. La forma canónica manriqueña emplea octosílabos y tetrasílabos en las posiciones tercera y sexta; otras coplas de pie quebrado admiten variaciones. Debe declararse el patrón métrico que METADRAMA pretende reconocer, no heredar el conjunto genérico.

3. **Sextilla sin quebrado.** [`sextilla_sin_quebrado`](http://localhost:5173/dashboard/vocabularios/estrofa_tipo?termino=b7426463-66e8-41af-bbd7-6106053e9b34) tampoco declara metro, arte ni naturaleza. Si “sin quebrado” significa isométrica, necesita una firma explícita o un estado “mismo metro en todos los versos”.

4. **Raíces con definición concreta y campos vacíos.** `decima`, `octava_real`, `soneto`, `terceto` y `sexteto_lira` describen en prosa rasgos fijos que no aparecen en sus campos estructurados. Esto no es herencia: son los padres quienes carecen de los datos que el demarcador usa en su primera fase.

## 4. Contradicciones y decisiones filológicas que requieren revisión

### 4.1. Redondilla y cuarteta

`redondilla_cruzada` se define como cuatro octosílabos consonantes `abab`. En la terminología moderna estricta, `abba` es redondilla y `abab` es cuarteta. Hay usos históricos amplios de “redondilla”, pero el vocabulario mezcla ese uso amplio con una entrada llamada `redondilla_regular` para `abba`. Para un editor y para el demarcador conviene:

- crear `cuarteta` para `abab`, o
- declarar que `redondilla` es una forma con realizaciones abrazada y cruzada. Esta
  recomendación preliminar quedó concretada después mediante una configuración simple
  con los patrones `abba` y `abab`; «Cuarteta» es la denominación equivalente del
  patrón cruzado, no otra forma.

No es aconsejable presentar `redondilla_cruzada` como término transparente sin una nota terminológica.

### 4.2. Quintilla canónica e irregular

La definición actual enumera ocho tipos, incluido `abbba`, y afirma expresamente que el tipo 8 contradice la norma. La descripción tradicional de la quintilla exige cinco versos, dos rimas consonantes, no más de dos rimas consecutivas, ausencia de pareado final y ningún verso suelto. Por tanto:

- `abbba` no debería figurar como octavo tipo canónico;
- puede mantenerse como `quintilla_irregular_abbba`, con evidencia de corpus;
- los siete esquemas regulares pueden almacenarse como patrones admitidos, no necesariamente como siete formas hijas.

### 4.3. Copla real, décima y duplicación padre/hijo

La bibliografía caracteriza la copla real principalmente como una unidad de diez versos compuesta por dos quintillas, con variedad de rimas. Esto respalda la pausa 5 + 5 como rasgo fuerte y desaconseja convertir cada esquema de rima en una forma distinta.

En `decima`, la raíz ya tiene metro 8 y patrón `abbaaccddc`, exactamente el patrón de `decima_espinela`. Además, ambas se dan mutuamente como equivalencias. Debe elegirse una política:

- **fusión:** `decima_espinela` como término canónico y `décima` como equivalente contextual;
- **familia:** `decima` como agrupador sin patrón fijo, con `decima_espinela` y `decima_aumentada` como hijos.

El estado actual afirma simultáneamente ambas soluciones.

### 4.4. Octava real y soneto

`octava_real` ya declara `ABABABCC`; `octava_real_regular` repite la misma forma y se da como equivalente de la raíz. Deben fusionarse o convertir la raíz en agrupador abstracto.

En el soneto, los esquemas de los tercetos son realizaciones legítimas, pero llamarlos formas hijas multiplica el vocabulario con información ya presente en `patron_especifico`. `soneto_de_esdrújulos` no es una forma estrófica distinta: el final esdrújulo es un rasgo prosódico transversal.

### 4.5. Silva libre

La definición actual de `silva_libre` la restringe a heptasílabos y endecasílabos, con
rima consonante y sin organización normativa en pareados. En la bibliografía moderna
citada por *Rhythmica*, “silva libre” designa una composición no estrófica de mayor
amplitud métrica que generalmente prescinde de la rima. Se decide conservar la
denominación establecida por el IP y documentar expresamente su alcance específico en
METADRAMA. Queda pendiente confirmar si esta diferencia terminológica es deliberada.

Los umbrales del 50 %, 98 % y 99 % usados para separar `endecasilabo_suelto`, `silva_de_endecasilabos` y `pareado_endecasilabo` fueron una formalización artificial de expresiones como «mayoría». Se decide no conservarlos como fronteras ontológicas ni pedir porcentajes al editor. La diferencia se expresará mediante rasgos cualitativos como predominio de rima o pareados cuando resulte destacable.

### 4.6. Coplas de pie quebrado

La categoría `copla_de_pie_quebrado` se define como residual: acepta lo que no sea sextilla de pie quebrado, manriqueña o doble sextilla alternativa. Sin embargo, su equivalencia dice “Sextilla de pie quebrado”. Ambas afirmaciones son incompatibles.

La bibliografía muestra que “copla de pie quebrado” es una familia históricamente variada y que la manriqueña es una realización canónica de doble sextilla `abc:abc:def:def`, con quebrados en posiciones regulares. Conviene una jerarquía explícita:

- `copla_de_pie_quebrado` — agrupador;
- `sextilla_de_pie_quebrado` — seis versos;
- `doble_sextilla_de_pie_quebrado` — doce versos;
- `copla_manriqueña` — patrón canónico;
- `otra_copla_de_pie_quebrado` — salida residual, si el corpus la necesita.

### 4.7. Seguidilla

Resuelto en el nuevo catálogo como una forma con dos configuraciones fijas: simple de
cuatro versos (`7-5-7-5`, `-a-a`) y compuesta de siete, que añade un estribillo
`5-7-5` con asonancia propia. El registrador deriva la norma y valida el rango según la
configuración.

### 4.8. Terceto

La raíz define tanto una unidad de tres versos como series encadenadas. `terceto_encadenado` se marca como `estrofa_cerrada`, aunque su propia definición habla de una estructura continua que enlaza tercetos. Deben separarse:

- tamaño de la unidad: 3;
- alcance de la composición: serie abierta o número variable de unidades;
- forma de cierre: verso, pareado o serventesio final.

### 4.9. Villancico y zéjel

Ambos se marcan como `estrofa_cerrada`, pero sus definiciones describen formas compuestas con estribillo, mudanza, vuelta y repetición. No son equivalentes a una estrofa simple de tamaño fijo. Necesitan un nivel `forma_compuesta_con_estribillo` y una representación de secciones.

### 4.10. Sextina

Resuelto en el nuevo catálogo como composición completa, no como estrofa de 39 versos.
La configuración clásica formaliza seis estrofas de seis versos y remate de tres; la
doble, doce estrofas y el mismo remate. La ausencia de rima convencional y la
permutación de seis palabras finales se conservan en dimensiones distintas.

## 5. Mezclas taxonómicas que conviene desmontar

### 5.1. Rasgos prosódicos convertidos en formas

Las variantes `*_de_esdrujulos` aparecen bajo canción, endecasílabo suelto, octava real, sexteto-lira, soneto y terceto. El final esdrújulo es una propiedad del verso o de la terminación, no una forma estrófica. Debe registrarse como caracterización transversal.

### 5.2. Vocales de la asonancia convertidas en subtipo de romance

Los 19 hijos de `romance` (`a-a`, `e-o`, `u-a`, etc.) describen las vocales concretas de la asonancia. No son 19 formas métricas. PoeMetCa separa precisamente el esquema de rima del valor concreto de las rimas. Se recomienda:

- conservar una sola forma `romance`;
- añadir un valor normalizado de `vocales_asonancia`;
- normalizar vocales tónicas y átonas sin incrustarlas en el identificador de la forma.

«Timbre» no era una denominación inventada para el proyecto: procede de la tradición métrica que habla de «ritmo de timbre» y «timbre de la rima». Sin embargo, PoeMetCa no denomina necesariamente así su campo, sino que separa esquema y valores concretos de rima. Para evitar ambigüedad en METADRAMA se adopta `vocales_asonancia` en el esquema y «Vocales de la asonancia» en la interfaz; «timbre» queda documentado como término técnico. Véase Clara I. Martínez Cantón, [estudio sobre tipología y funciones de la rima](https://oai.e-spacio.uned.es/server/api/core/bitstreams/81df07bc-7987-44ba-9971-10cf83ef1a73/content).

### 5.3. Esquemas de rima convertidos en hijos

Sucede en copla de arte mayor, quintilla, sexteto-lira y soneto. Si la única diferencia entre dos hijos es `patron_especifico`, la información debe residir normalmente en una tabla de patrones admitidos o en la realización de la secuencia, no en el vocabulario de formas.

Puede haber excepciones con nombre histórico asentado —por ejemplo, espinela o manriqueña—, pero deben justificarse por su lexicalización, no solo por poseer letras distintas.

### 5.4. Decisiones editoriales convertidas en formas

`irregular`, sus tres hijos por arte métrico y `verso suelto` son categorías necesarias para editar obras, pero no deben competir como formas normales en el demarcador. Se resuelven como salidas editoriales discriminadas:

- `Versificación irregular`: pasaje de dos o más versos sin forma reconocible;
- `Verso aislado`: exactamente un verso fuera de los segmentos contiguos.

El arte menor/mayor/mixto se conserva como observación heredada o se deriva de los
versos observados; no necesita tres términos estróficos. `Verso suelto` queda reservado
para sus significados métricos relativos a la rima.

### 5.5. `otras` como tipo de rima

Quince formas usan `otras`: canciones sin rima, endecasílabos sueltos, pareados, silvas y villancico. Se están mezclando al menos:

- ausencia de rima;
- rima parcial o minoritaria;
- rima mixta;
- rima consonante con versos sueltos;
- rima no determinada;
- procedimientos no convencionales.

La etiqueta no permite demarcar ni describir. Debe sustituirse por estados explícitos.

## 6. Propuesta de modelo

### 6.1. Entidades

1. **Forma métrica canónica**
   - nombre preferido;
   - equivalentes;
   - definición;
   - nivel estructural;
   - seleccionable / agrupador / residual;
   - procedencia histórica, si interesa.

2. **Patrón métrico**
   - secuencia ordenada de medidas: por ejemplo `[8, 8, 4, 8, 8, 4]`;
   - alternativas admitidas;
   - unidad a la que se aplica;
   - estructura interna del verso, con hemistiquios y cesura cuando proceda;
   - condición fija, preferente o variable.

3. **Patrón de rima**
   - esquema abstracto: `abcabc`;
   - tipo: consonante, asonante, sin rima, mixto, variable;
   - versos sueltos mediante `-` o `X`;
   - vocales de la asonancia en un campo independiente;
   - enlaces entre versos, unidades o secciones;
   - ámbito: estrofa, serie o composición.

4. **Estructura**
   - nivel: verso, estrofa, serie, poema o forma compuesta;
   - tamaño fijo, mínimo y máximo;
   - subunidades: 5 + 5, 6 × 6 + 3, cabeza/mudanza/vuelta/estribillo;
   - repetición de unidades.

5. **Rasgo transversal**
   - terminación esdrújula;
   - presencia de dístico final;
   - predominio cualitativo de versos rimados o pareados;
   - rima interna.

6. **Aserción y procedencia**
   - fuente;
   - página o localizador;
   - responsable;
   - fecha;
   - nivel de confianza para la aserción del catálogo, no para la anotación de secuencias;
   - nota editorial.

### 6.2. Estados de ausencia

Cada rasgo opcional debe distinguir al menos:

- `declarado`;
- `heredado`;
- `variable`;
- `no_fijo`;
- `no_aplica`;
- `desconocido`.

No es necesario duplicar físicamente todos los valores heredados, siempre que el estado y la resolución efectiva sean inequívocos. Para exportar el demarcador sí conviene materializar una instantánea con valores efectivos y procedencia.

### 6.3. Jerarquía

La relación padre/hijo actual debería complementarse con el tipo de relación:

- `subtipo_de`;
- `realizacion_de`;
- `patron_admitido_de`;
- `variante_prosodica_de`;
- `equivalente_de`;
- `agrupado_en`.

Con ello se evita que `soneto_de_esdrújulos` y un subtipo estructural aparezcan como relaciones semánticamente idénticas.

El origen español, italiano, provenzal u otro se representará en una dimensión propia de tradiciones y no como padre estructural. Una forma podrá mantener varias relaciones históricas —origen, adaptación, difusión o uso— sin heredar de ellas metro o rima.

### 6.4. Norma y diferencias en las secuencias

La anotación de obras utilizará un modelo de mundo cerrado:

```text
realización efectiva = configuración seleccionada + diferencias registradas
```

El editor no repetirá todos los rasgos de la configuración ni declarará certeza o estado de revisión. Si no registra una diferencia, se entiende que la secuencia cumple la norma. Las diferencias conservarán rango y dimensión:

- medida exacta, si se conoce, o relación menor/mayor que la norma;
- rima diferente de la esperada, sin exigir una terminación que no puede reconstruirse sin texto;
- estructura o repetición alterada;
- rasgo normalizado destacable.

Las caracterizaciones generales `cantado`, `prosa` y `laguna` pueden mantenerse por rango. `Hipométrico`, `hipermétrico`, `rima_defectuosa` y los finales acentuales se migrarán al dominio métrico normalizado.

## 7. Consecuencias para el demarcador

### 7.1. Firma de familia como disyunción

Una familia no debe combinar los valores de sus hijos en una sola bolsa ni limitarse a los valores de la raíz. Debe conservar **alternativas completas**.

Para `copla_real`:

- alternativa A: diez octosílabos;
- alternativa B: diez versos con octosílabos y pies quebrados, según el patrón admitido.

La respuesta “4 + 8” debe mantener viva la familia porque coincide con la alternativa B. Solo después se pregunta qué variante es.

### 7.2. Preguntas observables

Orden recomendado:

1. medidas de verso o patrón métrico básico;
2. tamaño o arquitectura visible;
3. régimen de rima;
4. organización en estrofa, serie o forma con estribillo;
5. patrón exacto, únicamente cuando separa variantes todavía compatibles.

No deben convertirse en preguntas principales:

- origen español/italiano;
- terminología histórica;
- porcentaje preciso de rimas;
- vocales concretas de la asonancia antes de identificar el romance;
- rasgos que exigen conocer de antemano el nombre de la forma.

### 7.3. Lógica de datos incompletos

`desconocido` no debe equivaler a coincidencia positiva. Se recomienda una lógica trivalente:

- compatible;
- incompatible;
- indeterminado por falta de datos.

Las candidatas indeterminadas pueden conservarse, pero con menor confianza y con un aviso de que faltan datos de fuente.

Esta lógica pertenece al diálogo del demarcador y a la información todavía no
declarada en el catálogo. No contradice la convención de mundo cerrado del
registro editorial: una vez guardadas la forma y su configuración en una
secuencia, la ausencia de una desviación significa que esa secuencia cumple la
norma en ese aspecto.

### 7.4. IA

No se recomienda introducir un modelo generativo en la decisión en tiempo real. La identificación debe ser reproducible y explicable. Un modelo puede ayudar fuera de línea a:

- detectar contradicciones entre definición y campos;
- proponer equivalencias;
- extraer candidatos de bibliografía;
- redactar preguntas para revisión humana.

La publicación de rasgos y reglas debe seguir siendo una decisión del IP y quedar versionada.

## 8. Revisión por familias

| Familia raíz | Nodos revisados | Diagnóstico y acción principal |
| --- | ---: | --- |
| `cancion_petrarquista` | 8 | Resuelto: una forma, tres configuraciones; tamaños y realización endecasílaba pasan a datos observados y esdrújulos a rasgo. |
| `copla_de_arte_mayor` | 4 | Mantener la forma y trasladar los tres esquemas a patrones admitidos. Completar naturaleza. |
| `copla_de_pie_quebrado` | 1 | Convertir en agrupador o residual explícito; eliminar la falsa equivalencia con sextilla. |
| `copla_real` | 3 | Mantener alternativas con y sin quebrado; firma familiar disyuntiva y naturaleza explícita. |
| `decima` | 3 | Resolver duplicación entre raíz y espinela; mantener aumentada como subtipo si se documenta. |
| `doble_sextilla` | 3 | Marcar la raíz como agrupador; manriqueña como subtipo lexicalizado; evitar duplicar “alternativa” y padre. |
| `endecasilabo_suelto` | 7 | Trasladar esdrújulos, dístico final y densidad de pareados a rasgos; documentar umbrales. |
| `irregular` | 4 | Resuelto como salida editorial; derivar o conservar como observación el arte menor/mayor/mixto. |
| `lira` | 1 | Resuelto en el nuevo catálogo: patrón métrico `7-11-7-7-11`, rima `aBabB`, fuente y denominaciones normalizadas. |
| `novena` | 3 | Resuelto: una forma, configuraciones 4 + 5 / 5 + 4 y reutilización de redondilla y quintilla como componentes. |
| `octava_real` | 3 | Resuelto: raíz y “regular” fusionadas; esdrújulos trasladados a rasgo transversal. |
| `pareado_de_arte_menor` | 3 | Los hijos por metro son derivables; sustituir rima `otras` por un régimen preciso. |
| `pareado_endecasilabo` | 1 | Resuelto en el nuevo catálogo: la tirada pasa a ser `pareados_endecasilabos`, forma de nivel serie, y `pareado` permanece como unidad de dos versos. |
| `quintilla` | 9 | Corregir tamaños; separar `abbba` como irregular; mover esquemas a patrones. |
| `redondilla` | 6 | Añadir definición; corregir hexasílaba; revisar cuarteta `abab`; separar doble redondilla. |
| `romance` | 20 | Mover los 19 valores de asonancia a un campo de rima; mantener una sola forma. |
| `romance_heroico` | 1 | Resuelto: configuración endecasílaba de romance; bibliografía añadida y `romance real` conservado como denominación equivalente del proyecto. |
| `romancillo` | 3 | Resuelto: 6 y 7 son configuraciones exactas de Romance; la raíz ambigua se retira y `endecha` queda pendiente de confirmación terminológica. |
| `seguidilla` | 1 | Resuelto: configuraciones simple de 4 versos y compuesta de 7, con patrones métricos, rima y secciones normalizados. |
| `sexta_rima` | 1 | Resuelto: seis endecasílabos consonantes `ABABCC` y fuente bibliográfica normalizada. |
| `sexteto` | 1 | Resuelto como forma residual positiva: seis versos de arte mayor consonantes, con medidas y esquema observados por unidad. |
| `sexteto_lira` | 9 | Resuelto: cinco patrones métricos, tres de rima, siete combinaciones admitidas y esdrújulos como rasgo. |
| `sextilla` | 3 | Declarar patrones métricos propios para con/sin quebrado; no heredar el conjunto genérico. |
| `sextina` | 1 | Resuelto: configuraciones de 39 y 75 versos, secciones, metro y permutación de palabras finales normalizados. |
| `silva` | 5 | Revisar “silva libre”, tipos de rima y umbrales de densidad; conservar subtipos solo con criterio documentado. |
| `soneto` | 6 | Resuelto en el nuevo catálogo: una forma, una configuración endecasílaba, cuatro patrones de rima y el final esdrújulo como rasgo transversal. |
| `terceto` | 5 | Corregir tamaño; distinguir unidad y serie encadenada; esdrújulos a rasgo. |
| `terceto_octosilabo` | 1 | Estructura coherente; añadir fuente y patrón de rima. |
| `verso suelto` | 1 | Resuelto como salida editorial `Verso aislado`; no es una forma estrófica. |
| `villancico` | 1 | Resuelto en el nuevo catálogo: dos configuraciones según la primera aparición del estribillo; copla y represa son secciones hermanas, con mudanza y enlace o vuelta dentro de la copla. |
| `zejel` | 1 | Modelar forma compuesta con estribillo, mudanza y vuelta. |

## 9. Plan de saneamiento recomendado

### Fase 1 — correcciones seguras

- corregir los seis tamaños/metros inequívocos;
- completar las tres definiciones vacías;
- sustituir `****`;
- añadir etiquetas a las 77 entradas;
- normalizar identificadores nuevos sin cambiar todavía los existentes usados como claves;
- añadir pruebas de coherencia patrón/tamaño y término/metro.

### Fase 2 — decisiones del IP

- aprobar la lista de nodos `agrupador`, `seleccionable` y `residual`;
- decidir qué patrones merecen nombre propio;
- revisar redondilla/cuarteta, quintilla `abbba`, silva libre y equivalencias;
- aprobar la política para décima/espinela y octava real/regular;
- documentar los umbrales de densidad de rima.

### Fase 3 — migración del modelo

- crear patrones métricos ordenados y alternativas;
- separar esquema y vocales concretas de la asonancia;
- separar rasgos transversales;
- introducir estados explícitos para valores ausentes;
- añadir procedencia por aserción;
- tipar las relaciones jerárquicas.

### Fase 4 — regeneración del demarcador

- producir un nuevo artefacto desde el modelo saneado;
- representar cada familia mediante alternativas de sus descendientes seleccionables;
- probar rutas objetivo: copla real con/sin quebrado, manriqueña, quintilla irregular, silvas, villancico y categorías residuales;
- publicar una versión únicamente tras revisión del IP.

## 10. Fuentes de contraste

### Manuales y repertorios

- José Domínguez Caparrós, *Métrica española*, UNED, 2014. [Ficha editorial de la UNED](https://portal.uned.es/portal/page?IdArticulo=0101036CT01A01&_dad=portal&_pageid=93%2C23377989).
- José Domínguez Caparrós, *Diccionario de métrica española*, Alianza. [Primeras páginas y datos editoriales](https://www.alianzaeditorial.es/primer_capitulo/diccionario-de-metrica-espanola.pdf).
- Antonio Quilis, *Métrica española*. [Ficha bibliográfica y contenido](https://books.google.com/books/about/M%C3%A9trica_espa%C3%B1ola.html?id=iWQ47NpnaK8C).
- Tomás Navarro Tomás, *Métrica española: reseña histórica y descriptiva*. [Ficha bibliográfica](https://books.google.com/books/about/M%C3%A9trica_Espa%C3%B1ola.html?id=BEZdAAAAMAAJ).
- Rudolf Baehr, *Manual de versificación española*. [Ficha en Dialnet](https://dialnet.unirioja.es/servlet/libro?codigo=135868).

### Proyectos y estándares digitales

- [PoeMetCa: Repertorio Métrico Digital de la Poesía Cancioneril del siglo XV](https://poemetca.linhd.uned.es/). Separa cantidad de versos, firma silábica, esquema y valores concretos de rima.
- Elena González-Blanco y José Luis Rodríguez, [“ReMetCa: A Proposal for Integrating RDBMS and TEI-Verse”](https://doi.org/10.4000/jtei.1274), *Journal of the Text Encoding Initiative*, 8, 2015.
- [TEI, `att.metrical`](https://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.metrical.html): distinción entre estructura convencional, realización y esquema de rima.
- [POSTDATA: red de ontologías](https://postdata.linhd.uned.es/results/network-of-ontologies/) y [vocabularios controlados](https://postdata.linhd.uned.es/controlled-vocabularies/): separación de patrones de verso, estrofa y obra.
- Clara I. Martínez Cantón, [“Poetriae y el *Arte de poesía castellana*: bases para la creación de un vocabulario común de métrica”](https://oai.e-spacio.uned.es/server/api/core/bitstreams/1637bd75-be5d-4fb4-8557-9844f9282654/content).

### Estudios usados para casos concretos

- Maximiano Trapero, [“La primera copla real en la poesía castellana”](https://dialnet.unirioja.es/descarga/articulo/6973171.pdf): estructura de doble quintilla y variabilidad de rimas.
- M.ª Victoria Utrera Torremocha, [“Métrica y poética en ‘Nocturno yanqui’, de Luis Cernuda”](https://revistas.uned.es/index.php/rhythmica/article/download/13137/12115/20081): historia y variantes de la copla de pie quebrado y forma manriqueña.
- [“Sobre las canciones del folklore musical en España”](https://www.cervantesvirtual.com/obra-visor/sobre-las-canciones-del-folklore-musical-en-espana/html/), Biblioteca Virtual Miguel de Cervantes: quintilla, seguidilla, romance y terceto octosilábico.
- José Enrique Martínez, [“Endecasílabos y decasílabos con acento anómalo en la poesía de Bonifaz Nuño”](https://revistas.uned.es/index.php/rhythmica/article/download/13050/12040/19924): definición moderna de silva libre.
- [“¿Con qué te lavas la cara…? Redondillas cortesanas y cuartetas folklóricas”](https://www.cervantesvirtual.com/obra-visor/con-que-te-lavas-la-cara-redondillas-cortesanas-y-cuartetas-folkloricas-1/html/): contraste entre `abba` y `abab`.

### Versificación y análisis computacional

- Petr Plecháč, Klemens Bobenhausen y Benjamin Hammerich, [“Versification and authorship attribution”](https://ojs.utlib.ee/index.php/smp/article/view/smp.2018.5.2.02): evaluación de rasgos de versificación como marcadores estilométricos en varias lenguas, incluida la poesía española.
- [*Versos y estructuras teatrales áureos*](https://ucrisportal.univie.ac.at/en/publications/versos-y-estructuras-teatrales-%C3%A1ureos-a-corpus-of-spanish-plays-w): corpus de teatro áureo con información dramática y métrica estructurada.

## Anexo A. Inventario jerárquico revisado

Este anexo registra la cobertura de las 119 entradas. Los nombres son los identificadores actuales, no propuestas de denominación.

- `cancion_petrarquista`: `cancion_de_15_versos`, `cancion_de_8_versos`, `cancion_de_9_versos`, `cancion_endecasilaba`, `cancion_regular_abCabCcdeeDfF`, `cancion_sin_rima`, `cancion_sin_rima_de_esdrujulos`.
- `copla_de_arte_mayor`: `copla_de_arte_mayor_tipo_1_ABBAACCA`, `copla_de_arte_mayor_tipo_2_ABBACDCD`, `copla_de_arte_mayor_tipo_3_ABABCDCD`.
- `copla_de_pie_quebrado`.
- `copla_real`: `copla_real_de_pie_quebrado`, `copla_real_sin_quebrado`.
- `decima`: `decima_aumentada`, `decima_espinela`.
- `doble_sextilla`: `copla_manriqueña`, `doble_sextilla_alternativa`.
- `endecasilabo_suelto`: `endecasilabo_suelto_con_pareados`, `endecasilabo_suelto_con_pareados_y_sin_distico_final`, `endecasilabo_suelto_de_esdrujulos`, `endecasilabo_suelto_encadenado`, `endecasilabo_suelto_puro`, `endecasilabo_suelto_puro_sin_distico_final`.
- `irregular`: `irregular_arte_mayor`, `irregular_arte_menor`, `irregular_mixto`.
- `lira`.
- `novena`: `novena_canonica`, `novena_invertida`.
- `octava_real`: `octava_real_de_esdrujulos`, `octava_real_regular`.
- `pareado_de_arte_menor`: `pareado_hexasilabo`, `pareado_octosilabo`.
- `pareado_endecasilabo`.
- `quintilla`: `quintilla_1_ababa`, `quintilla_2_abbab`, `quintilla_3_abaab`, `quintilla_4_aabab`, `quintilla_5_aabba`, `quintilla_6_abbaa`, `quintilla_7_ababb`, `quintilla_8_abbba`.
- `redondilla`: `redondilla_cruzada`, `redondilla_doble_abbaacca`, `redondilla_heptasilaba`, `redondilla_hexasilaba`, `redondilla_regular`.
- `romance`: `romance_a`, `romance_a-a`, `romance_a-e`, `romance_a-o`, `romance_e`, `romance_e-a`, `romance_e-e`, `romance_e-o`, `romance_i`, `romance_i-a`, `romance_i-e`, `romance_i-o`, `romance_o`, `romance_o-a`, `romance_o-e`, `romance_o-o`, `romance_u-a`, `romance_u-e`, `romance_u-o`.
- `romance_heroico`.
- `romancillo`: `romancillo_heptasilabo`, `romancillo_hexasilabo`.
- `seguidilla`.
- `sexta_rima`.
- `sexteto`.
- `sexteto_lira`: `sexteto_lira_a1_aBaBcC`, `sexteto_lira_a2_AbaBcC`, `sexteto_lira_a3_abaBcC`, `sexteto_lira_b1_abbacC`, `sexteto_lira_b2_AbbACC`, `sexteto_lira_c1_AabBcC`, `sexteto_lira_c2_AabBCC`, `sexteto_lira_de_esdrujulos`.
- `sextilla`: `sextilla_de_pie_quebrado`, `sextilla_sin_quebrado`.
- `sextina`.
- `silva`: `silva_de_consonantes_irregular`, `silva_de_consonantes_regular`, `silva_de_endecasilabos`, `silva_libre`.
- `soneto`: `soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE`, `soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE`, `soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE`, `soneto_de_esdrújulos`, `soneto_regular_ABBAABBACDCDCD`.
- `terceto`: `terceto_de_esdrujulos`, `terceto_encadenado`, `terceto_sin_encadenar_1_AXABYB`, `terceto_sin_encadenar_2_XAAYBB`.
- `terceto_octosilabo`.
- `verso suelto`.
- `villancico`.
- `zejel`.
