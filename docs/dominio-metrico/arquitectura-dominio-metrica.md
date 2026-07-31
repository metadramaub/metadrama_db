# Arquitectura técnica del dominio métrico

Estado: vigente · revisado el 30 de julio de 2026

Este documento describe **cómo se organiza técnicamente** el dominio métrico: qué capas
lo componen, quién consume sus datos, cómo se invalidan los derivados y qué garantías de
integridad y permisos rigen. No define los conceptos —eso corresponde a la ontología— ni
especifica las tablas, porque la fuente de verdad del esquema es la base de datos.

Documentos relacionados:

- [Meta-modelo métrico](./meta-modelo-metrico.md): qué tipos de entidad existen y qué
  reglas los gobiernan. La capa reutilizable.
- [La ontología métrica de METADRAMA](./ontologia-metrica.md): su aplicación a la métrica
  española y las decisiones del corpus.
- [Criterios de nivel](./criterios-de-nivel.md): en qué nivel se registra cada hecho.
- [Informe de conformidad](./informe-conformidad-catalogo.md): estado de los datos.
- [Contratos del registrador](./contratos-registrador-formas-revisadas.md).
- [Plan de migración de las anotaciones](./plan-migracion-anotaciones.md).
- [Histórico](./historico/): diagnóstico del vocabulario legado, matriz de
  reclasificación, propuesta inicial y especificación de tablas ya superada.

## 1 · Dónde está la verdad

| Pregunta | Fuente |
| --- | --- |
| Qué tablas y restricciones existen | La base de datos: `npx supabase db dump --linked -f esquema.sql` |
| Qué datos hay poblados y si son coherentes | `npm run audit:metrica` |
| Qué significa cada entidad | [Meta-modelo métrico](./meta-modelo-metrico.md) |
| Qué decidió el proyecto sobre la métrica española | [La ontología métrica](./ontologia-metrica.md) |
| En qué nivel se registra un hecho | [Criterios de nivel](./criterios-de-nivel.md) |
| Qué decidió el proyecto sobre una forma | Su ficha en [revisiones-formas](./revisiones-formas/) |
| Qué pregunta el editor en cada forma | [Contratos del registrador](./contratos-registrador-formas-revisadas.md) |

Ningún documento repite la especificación de columnas. Cuando lo hizo, quedó desfasado en
dos días: la versión anterior está en
[historico/especificacion-tablas-2026-07-28.md](./historico/especificacion-tablas-2026-07-28.md).

## 2 · Las tres capas

1. **Catálogo formal** — qué formas, arquitecturas, esquemas y rasgos reconoce el
   proyecto. Se edita en `/dashboard/metrica`.
2. **Anotación editorial** — qué se ha identificado u observado en una secuencia concreta.
   Hoy solo existe en las tablas de prueba `*_editor_metrico`; las secuencias reales
   siguen en el vocabulario legado.
3. **Proyecciones derivadas** — qué datos se publican, filtran, agregan o compilan. Son
   regenerables y declaran su procedencia.

La base normalizada es la fuente de verdad. El artefacto del demarcador, las fichas
públicas y las redes son proyecciones.

## 3 · Objetivos

- Representar como formas solo las identidades métricas asignables a una secuencia.
- Separar arquitecturas, esquemas, variedades y rasgos.
- Expresar alternativas y secuencias ordenadas de metros.
- Distinguir lo fijo, lo admitido, lo preferente, lo variable y lo desconocido.
- Mantener procedencia y estado de revisión.
- Permitir preguntas reproducibles y explicables en el demarcador.
- Producir filtros públicos semánticamente independientes.
- Permitir evolución futura sin convertir cada nuevo rasgo en una subforma.

## 4 · Lo que no se pretende

- Codificar todas las variantes históricas de la métrica española.
- Construir una ontología universal independiente de las necesidades de METADRAMA.
- Introducir un modelo generativo en la clasificación en tiempo real.
- Resolver mediante un único esquema todas las particularidades de verso, estrofa, serie
  y poema.

## 5 · Principios

1. **Una forma es asignable.** Si una entrada no posee identidad normativa, no puede
   registrarse como `tipo_registro = forma`.
2. **Una arquitectura es constante en la secuencia.** Lo que varía entre unidades vive en un esquema, una variedad o un rasgo.
3. **Una arquitectura formaliza el recipiente.** Dos arquitecturas de una forma no
   son automáticamente dos formas.
4. **Un esquema describe orden.** Los metros no se reducen a un conjunto sin posiciones.
5. **Un rasgo es transversal.** Puede aparecer en formas diferentes sin duplicarlas.
6. **La ausencia tiene estado.** No se interpreta `null` como herencia automática.
7. **Definición y observación son capas distintas.**
8. **Los datos derivados declaran su procedencia.**
9. **Las relaciones están tipadas.**
10. **La tradición es una dimensión histórica.** No transmite rasgos por herencia.
11. **La secuencia distingue norma, realización y diferencia.**
12. **La ontología se reutiliza.** Las observaciones apuntan a metros, rimas, estructuras
    y rasgos normalizados; no crean un vocabulario paralelo.
13. **La complejidad reside en el catálogo.** El editor de obras solo elige forma,
    arquitectura cuando proceda, alternativas observadas y diferencias reales.

## 6 · Convención de mundo cerrado

```text
realización efectiva =
    forma
    + arquitectura
    + elecciones entre alternativas admitidas
    + unidades o secciones realizadas
    + desviaciones registradas
```

La ausencia de una desviación significa conformidad con la norma y con las elecciones
registradas. No significa pendiente, desconocido ni falta de revisión. La ausencia de una
respuesta obligatoria, en cambio, impide guardar.

En consecuencia:

- no se crea una tabla de cobertura de revisión;
- no se pide certeza editorial;
- no se duplica en la secuencia lo que ya declara la arquitectura;
- los resultados únicos se derivan sin pregunta;
- las alternativas admitidas se registran solo mediante grupos declarados por el catálogo;
- si cambia una norma, las secuencias afectadas se adaptan o invalidan mediante una
  migración o regeneración técnica.

Cuando una secuencia no pueda describirse razonablemente desde una forma conocida, se usa
un tramo sin forma en lugar de acumular desviaciones sobre una forma que ya no resulta
reconocible.

## 7 · Estados semánticos

Para el catálogo, los rasgos opcionales y las restricciones adoptan estados explícitos:
`declarado`, `heredado` —solo durante compatibilidad o cuando exista una regla formal—,
`variable`, `no_fijo`, `no_aplica` y `desconocido`. La herencia no puede depender de que
un campo sea `null`. Estos estados describen el catálogo; no introducen certeza en el
formulario de secuencias.

## 8 · Capa de anotación

**Pendiente de implementar.** Hoy solo existe la versión de prueba con el sufijo
`editor_metrico`. El diseño previsto es:

- la secuencia declara forma y, cuando proceda, arquitectura;
- las unidades internas materializan las secciones realizadas con su rango;
- las elecciones guardan qué alternativa admitida apareció realmente;
- las observaciones localizan diferencias por rango y dimensión, reutilizando las mismas
  entidades normalizadas del catálogo.

Las observaciones no constituyen un vocabulario paralelo de irregularidades. Se apoyan en
la relación entre la realización y su norma: si la arquitectura espera ocho sílabas y el
editor registra siete, la hipometría se deriva. Los casos legados que solo afirman
hipometría conservan la relación cualitativa sin inventar la medida exacta.

Las caracterizaciones no métricas por rango —`cantado`, `prosa`, `laguna`— permanecen en
su dominio general. La interfaz puede presentarlas coordinadas con las métricas, pero cada
dominio conserva integridad referencial propia.

## 9 · Proyecciones y consumidores

### 9.1 · Administración del catálogo

`/dashboard/metrica` mantiene formas y sus arquitecturas; tradiciones,
denominaciones y relaciones; metros, esquemas métricos y de rima, secciones y
repeticiones; rasgos y valores; variedades; elecciones; y fuentes con sus
afirmaciones. El IP no edita filas ni JSON directamente. La vista de grafo es secundaria:
sirve para comprender y auditar, no como interfaz de escritura.

### 9.2 · Registrador de secuencias

Contrato mínimo: seleccionar forma; seleccionar arquitectura solo cuando existan
alternativas relevantes; responder únicamente los grupos de elección declarados;
completar unidades internas solo donde la estructura lo exige; añadir diferencias si las
hay.

El formulario es adaptativo. Una forma simple no muestra secciones, esquemas ya fijados ni
controles vacíos. La complejidad de la ontología solo se hace visible cuando la
realización que se registra es realmente compleja. Las preguntas proceden del catálogo,
no del componente.

### 9.3 · Fichas públicas y buscador

La proyección suministra forma canónica y etiqueta, arquitectura identificada, unidades
internas, rasgos publicables y clave estable de color. Las facetas se separan: formas,
tradiciones, metros, regímenes de rima, arquitecturas y rasgos. No se presenta
una lista combinada de formas y subtipos.

Para consultas eficientes pueden materializarse tablas de presencia por obra. Cada fila
derivada conserva su `origen` —observado o implicado— cuando la diferencia afecte al
significado del filtro.

### 9.4 · Laboratorio, autoría y datación

Los perfiles se calculan sobre formas canónicas; arquitecturas y rasgos son dimensiones
separadas. Esto evita que dos obras parezcan distintas solo porque una codificó un esquema
de rima como hijo y otra no.

La convención de mundo cerrado permite derivar distribución de formas y arquitecturas,
transiciones entre formas, frecuencia de rasgos, desviaciones por dimensión y su
concentración, y tasas sobre los versos de la secuencia. Estos rasgos pueden alimentar
modelos de atribución o datación, pero no garantizan una conclusión: hay que controlar
forma, género, extensión, cronología y dependencia entre secuencias de una misma obra, y
separar obras completas entre entrenamiento y prueba.

### 9.5 · Demarcador

Un compilador genera un artefacto versionado a partir de las formas y arquitecturas
disponibles, sus esquemas, el orden estructural de las secciones y los rasgos observables.
El artefacto incluye versión de esquema, revisión del catálogo, huella de la fuente,
candidatos, alternativas, procedencia de cada regla y fecha de publicación. La versión
pública solo cambia mediante una acción de publicación.

Las preguntas se ordenan por su capacidad de separar las candidatas restantes; solo se
pregunta lo observable; `No sé` conserva candidatas.

### 9.6 · Grafos, redes e interoperabilidad

PostgreSQL sigue siendo la fuente de verdad. Las relaciones tipadas permiten generar
grafos para navegación, auditoría de nodos huérfanos y ciclos, análisis de impacto y
visualización de derivaciones históricas. Las redes de similitud no se almacenan como
relaciones canónicas: se calculan y declaran su método. Para el tamaño del catálogo no
hace falta una base de grafos.

La interoperabilidad externa puede resolverse con `referencias_externas` —entidad local,
sistema, URI y tipo de equivalencia— para mapear a POSTDATA, TEI u otros repertorios y
exportar JSON-LD o RDF sin sustituir el modelo relacional.

## 10 · Datos derivados e invalidación

`catalogo_metrico_estado.revision` se incrementa con cada cambio del catálogo. Sirve para
saber con qué revisión se calculó un resumen, marcar como obsoletas las proyecciones
afectadas, recompilar el demarcador y comparar resultados antes y después de una decisión.

Los cambios puramente editoriales, como una etiqueta, se resuelven en lectura. Los cambios
semánticos deben invalidar las obras afectadas o ejecutar una regeneración controlada.

Pendiente: ninguna anotación registra todavía con qué revisión se guardó.

## 11 · Integridad

- `slug` único por entidad.
- No se eliminan físicamente formas ya utilizadas; se retiran.
- Una arquitectura solo pertenece a una forma.
- Una arquitectura asignada debe corresponder a la forma de la secuencia.
- Las posiciones de un esquema son únicas y consecutivas cuando el esquema es fijo.
- Las relaciones `subtipo_de` no pueden formar ciclos.
- Las unidades internas deben quedar dentro del rango de su secuencia.
- Los solapamientos se validan según el tipo de unidad, no mediante una prohibición
  universal.
- Una opción de elección pertenece a la arquitectura de su grupo o a la arquitectura
  reutilizada por su sección.
- Un esquema de rima observado se valida contra la extensión de la unidad.

Estas garantías están implementadas como restricciones y disparadores en la base, no en la
aplicación.

## 12 · Permisos y auditoría

- Público: lectura del catálogo publicado.
- Editor: lectura del catálogo y escritura de anotaciones dentro de sus capacidades.
- IP o rol autorizado: edición, revisión y aprobación del catálogo.
- Publicación del demarcador: acción privilegiada y auditada.

Todas las tablas del catálogo conservan `created_at`, `updated_at` y responsable. Para
decisiones críticas conviene un historial que permita reconstruir qué reglas estaban
vigentes cuando se generó un artefacto.
