# Plan de migración de las anotaciones métricas

Estado: vigente, no iniciado · 30 de julio de 2026

Este documento recoge lo que hay que hacer para llevar las declaraciones métricas reales
de las obras del vocabulario legado al catálogo nuevo. Estaba disperso en la arquitectura
y se separa aquí porque es la única parte del proyecto métrico que todavía no ha
empezado y que no debe empezar hasta que se cumplan sus condiciones previas.

**No se ejecutará** hasta que el IP haya presentado y corregido la ontología, el editor
V2 funcione como se espera con datos de prueba y el demarcador resulte útil. Hay editores
trabajando sobre los datos actuales y esa frontera no se adelanta.

## 1 · Situación de partida

Comprobado el 30 de julio de 2026 sobre la base enlazada:

- 246 secuencias métricas reales, todas apuntando a `vocabularios.estrofa_tipo_id`;
- 337 filas en `secuencias_subtipos_estrofa`;
- 225 caracterizaciones por rango;
- `secuencias_metricas` **no tiene todavía** `forma_metrica_id`;
- las tablas `*_editor_metrico` son de prueba y no alimentan nada público.

## 2 · Datos que deben preservarse

- filas de `secuencias_metricas`;
- obra, rango `v_ini`–`v_fin` y número de versos de cada secuencia;
- `estrofa_tipo_id` actual como evidencia de la clasificación realizada;
- subtipos o unidades internas y sus rangos;
- caracterizaciones métricas por rango;
- observaciones editoriales;
- relaciones necesarias para identificar autoría y contexto de la anotación;
- fechas y responsables disponibles.

Antes de modificar estos datos se hará una copia de seguridad y un inventario de uso por
UUID. Ninguna entrada utilizada se migrará mediante una regla genérica no revisada.

## 3 · Datos que pueden descartarse y regenerarse

- `obras_resumen` y `autores_resumen`;
- perfiles, tramos y facetas precomputadas;
- payloads de las fichas públicas de prueba;
- índices o artefactos del laboratorio derivados de esos resúmenes;
- versiones de prueba del demarcador que no estén publicadas como referencia.

La web no está abierta al público y las fichas actuales son de prueba. No hace falta
mantener compatibilidad de contenido con esas proyecciones: se reconstruirán desde el
modelo nuevo una vez validadas las anotaciones.

## 4 · Trazabilidad

`migracion_terminos_metricos` conserva un registro por `vocabularios.termino_id` con su
clasificación, decisión, certeza técnica y notas. `migracion_termino_destinos` permite
que un término legado produzca varios destinos, porque casos como
`soneto_de_esdrújulos` se transforman en una forma más un rasgo, no en un registro
equivalente.

Cuando una entrada sobreviva como forma canónica se reutiliza su UUID en
`formas_metricas`, lo que facilita el backfill. Las entradas transformadas en patrones o
rasgos conservan su UUID legado solo en la tabla de correspondencias.

Los términos ambiguos no se asignan por conjetura. La antigua raíz `romancillo`, por
ejemplo, exige saber si la secuencia es hexasílaba o heptasílaba, y esa decisión es
editorial.

## 5 · Auditoría obligatoria antes del backfill

Se generará un informe con:

- número de secuencias total y por `estrofa_tipo_id`;
- términos activos e inactivos realmente utilizados;
- secuencias que apuntan a raíces, hijos o entradas pendientes;
- número y rango de `secuencias_subtipos_estrofa`;
- caracterizaciones por rango relacionadas con métrica;
- correspondencia de `hipometrico`, `hipermetrico`, `rima_defectuosa` y finales
  acentuales con las observaciones normalizadas;
- referencias huérfanas o inconsistentes;
- obras afectadas por cada regla de reclasificación.

Ese informe será la línea base de aceptación.

## 6 · Fases

### Condición previa

El catálogo cumple los [criterios de nivel](./criterios-de-nivel.md) y el
[informe de conformidad](./informe-conformidad-catalogo.md) no tiene defectos abiertos.

La capa de observación real no se crea a ciegas: la fase 0 sirve para saber, con obras de
verdad, si el modelo aguanta antes de abrirle la puerta a `secuencias_metricas`.

### Fase 0 · Anotación en sombra

Decidida el 3 de agosto de 2026. Es el ensayo: anotar secuencias **reales** con el modelo
nuevo sin que producción se entere, para validar a la vez el editor, el catálogo y el mapa
de correspondencias.

**Cómo se conecta.** `secuencias_editor_metrico` gana una columna `secuencia_id` nullable
que apunta a `secuencias_metricas`. Todo el árbol nuevo —realizaciones, elecciones,
desviaciones— sigue colgando de la prueba, no de la secuencia. La secuencia real no cambia
ni una columna y **no sabe que la están anotando**. Se revierte borrando la columna.

Una prueba tiene entonces dos modos: cuelga de un escenario ficticio, como hasta ahora, o
señala una secuencia real. Nunca las dos cosas.

**Cómo se elige qué obra.** Un interruptor por obra, no por rol: solo las obras marcadas
abren el editor nuevo. Se eligen por las formas que traen —conviene que haya villancicos,
canciones y tercetos encadenados—, no por quién las anota. El selector enseña por eso los
términos legados de cada obra y cuántas de sus secuencias no tienen correspondencia.

Retirar una obra no borra lo anotado: deja de poder anotarse, nada más. El rango de una
anotación en sombra lo manda siempre la secuencia real —la sombra dice qué es ese pasaje, no
dónde empieza—, porque si además se moviera el contraste dejaría de comparar lo mismo.

**El editor no empieza en blanco.** Al abrir por primera vez una secuencia real, el
formulario se propone solo a partir de su `estrofa_tipo_id`, siguiendo el
`origen_termino_id` que cada entidad del catálogo declara. El editor no reanota: revisa una
propuesta y corrige. Eso cambia lo que se está probando, y a mejor: no solo la ergonomía
del formulario, sino **si el mapa de correspondencias acierta**, que es justamente lo que
hay que saber antes de migrar 260 secuencias de golpe.

**Cobertura medida el 3 de agosto.** De los 46 términos `estrofa_tipo` que las obras usan,
37 tienen origen declarado en el catálogo: **238 de 260 secuencias, el 91,5 %**. Quedan
nueve términos sin correspondencia —`endecasilabo_suelto_puro` (6 secuencias), `decima`
(5), tres `sexteto_lira_*`, dos pareados, `copla_real_de_pie_quebrado`— y tres secuencias
con `estrofa_tipo_id` nulo. Es una tarde de trabajo, no un proyecto.

> Las tablas `migracion_terminos_metricos` y `migracion_termino_destinos` **están vacías**:
> la matriz de importación se retiró en julio. El mapa vigente es `origen_termino_id`, y es
> el que hay que consultar.

**Qué se mira al final.** Un recuento agregado que responde la pregunta que decide el resto:
de las secuencias anotadas en los dos modelos, cuántas coinciden, cuántas difieren y
cuántas no tienen todavía correspondencia en el catálogo.

No se construye una pantalla de contraste lado a lado: para ver una obra en los dos modelos
se abre el editor de siempre en otra pestaña, que enseña el dato real y no una copia suya.
Lo que no se puede obtener así es el agregado —habría que contar a mano sobre 91 obras—, y
por eso es lo único que se implementa. Que «sin correspondencia» se cuente aparte y no como
desacuerdo es deliberado: es una pieza que falta en el catálogo, no una discrepancia entre
modelos, y mezclarlas haría parecer que la fase va peor de lo que va.

**Criterio de salida.** La fase 0 termina cuando ese contraste dice que el modelo nuevo
recoge sin pérdida lo que decía el viejo, y las diferencias que quedan son correcciones
deliberadas y no defectos del modelo. Solo entonces se abre la fase A.

### Fase A · Esquema de anotación

- crear la capa de observaciones y desviaciones sobre `secuencias_metricas`;
- añadir `forma_metrica_id` de manera aditiva, junto a `estrofa_tipo_id`;
- sellar cada anotación con la revisión del catálogo vigente.

### Fase B · Backfill

- migrar las asignaciones directas;
- transformar los hijos que eran patrones o rasgos;
- migrar `secuencias_subtipos_estrofa` a unidades y elecciones;
- migrar las irregularidades por rango a observaciones normalizadas sin inventar valores
  exactos: los casos que solo afirman hipometría o hipermetría conservan
  `menor_que_norma` o `mayor_que_norma` y dejan la medida sin determinar;
- conservar `cantado`, `prosa` y `laguna` en su dominio general;
- fusionar los subtipos residuales de irregular por arte con Versificación irregular,
  conservando su información como observación o derivándola de las medidas disponibles;
- producir informes de discrepancias.

### Fase C · Editor de obras

- sustituir el selector de vocabulario por el del dominio;
- eliminar la excepción específica de quintilla;
- mantener lectura de registros legados durante la transición.

### Fase D · Proyecciones públicas

- vaciar las proyecciones de prueba;
- rediseñar fichas, catálogo, autores y laboratorio;
- recalcular perfiles canónicos y generar facetas separadas;
- validar semánticamente las nuevas facetas.

### Fase E · Retirada

- hacer `estrofa_tipo` de solo lectura;
- retirar FKs y servicios legados sin consumidores;
- conservar tablas de correspondencia e historial;
- eliminar columnas métricas de `vocabularios` solo si ninguna otra categoría las usa.

## 7 · Criterios de aceptación

1. Igual número de secuencias antes y después.
2. Igualdad exacta de obra, `v_ini`, `v_fin` y `n_versos`.
3. Toda asignación legada puede trazarse hasta sus destinos nuevos.
4. Todos los subtipos internos conservan su rango como unidad o incidencia revisable.
5. Cada transformación compuesta conserva forma, configuración y rasgos.
6. Un verso legado marcado solo como hipométrico no recibe un número de sílabas inventado.
7. Una secuencia sin observaciones se interpreta como plenamente conforme con su norma.
8. Ninguna proyección pública consulta ya la jerarquía de `estrofa_tipo`.
9. Una restauración de la copia de seguridad ha quedado ensayada.

## 8 · Riesgos

| Riesgo | Mitigación |
| --- | --- |
| Reclasificar erróneamente una entrada usada | Matriz revisada, correspondencias y lectura dual |
| Perder anotaciones de hijos actuales | Copia de seguridad y auditoría de cada UUID usado |
| Inventar precisión en datos legados | Conservar relaciones cualitativas cuando no exista medida o rima exacta |
| Cambiar una norma y reinterpretar secuencias en silencio | Sellado de revisión e invalidación técnica de lo afectado |
| Duplicar fuentes de verdad | Definir por fase qué tablas admiten escritura |
| Migrar mientras hay editores trabajando | Coordinar el corte y evitar la escritura dual prolongada |
