# Propuesta para separar las formas métricas del vocabulario genérico

Fecha: 28 de julio de 2026

Estado: propuesta conceptual aprobada como punto de partida; no implementada

Documentos relacionados:

- [Auditoría del vocabulario métrico](./informe-auditoria-vocabulario-metrico.md)
- [Arquitectura del dominio métrico](./arquitectura-dominio-metrica.md)
- [Matriz de reclasificación](./matriz-reclasificacion-formas-metricas.md)
- [Ejemplos de formalización](./ejemplos-formalizacion-ontologia-metrica.md)

## Decisión propuesta

Las formas métricas deben salir de `vocabularios` y constituir un dominio propio. La solución no consiste en copiar sin más las 119 entradas actuales a una tabla `formas_metricas`, porque eso trasladaría a otro lugar los mismos problemas. Hay que separar:

1. el catálogo que define qué formas existen;
2. las configuraciones o realizaciones que admite cada forma;
3. los rasgos transversales;
4. las observaciones realizadas por los editores en las secuencias;
5. las proyecciones derivadas para fichas, búsqueda, laboratorio y demarcador.

`vocabularios` seguirá siendo adecuado para listas controladas sencillas, como estados o roles. Una forma métrica, en cambio, es una entidad de dominio con identidad, estructura, alternativas, relaciones semánticas, fuentes y reglas.

## Por qué el modelo actual no debe prolongarse

La tabla genérica acumula campos que solo tienen sentido para determinadas categorías: patrón, tipo de rima, naturaleza estrófica, tamaño, arte y número de sílabas. Al mismo tiempo, la única relación estructural disponible es `termino_padre_id`.

Como consecuencia, padre e hijo expresan actualmente relaciones diferentes:

- familia y miembro;
- forma y subtipo;
- forma y esquema de rima;
- forma y rasgo prosódico;
- término general y equivalente;
- categoría editorial y especialización derivable.

La aplicación ha incorporado esa ambigüedad como lógica de negocio:

- las secuencias guardan un `estrofa_tipo_id`;
- los hijos suelen ser seleccionables como si fueran formas;
- las quintillas son una excepción y registran los hijos por rangos internos;
- los resúmenes públicos colapsan los hijos al padre;
- el catálogo presenta formas y subtipos en una misma faceta;
- el demarcador interpreta raíces como familias e hijos como variantes.

Añadir más campos o excepciones agravaría el acoplamiento.

## Separación conceptual

### Catálogo

`formas_metricas` contendrá formas que puedan constituir una identificación editorial
real: romance, quintilla, copla real, soneto, silva, etc. Las dos salidas necesarias
para operar desde el mismo selector se conservarán en la tabla mediante el discriminador
`tipo_registro = salida_editorial`: no se tratarán como formas, no tendrán
configuraciones y se excluirán del análisis comparativo.

Las agrupaciones de navegación y estudio se modelarán como `familias_metricas`. Una familia no tiene por qué ser seleccionable ni constituir una forma.

La pertenencia de una forma a una familia se expresará mediante una relación propia, no mediante un padre genérico. Cuando dos formas mantengan una relación semántica real, esta se tipará: `subtipo_de`, `variante_historica_de`, `relacionada_con`, etc.

Las tradiciones históricas que estén respaldadas por fuentes no se tratarán como padres estructurales. Se modelarán mediante `tradiciones_metricas` y una relación muchos-a-muchos con las formas que permita distinguir origen, adaptación, difusión y uso. En la interfaz podrán presentarse como agrupaciones, pero no transmitirán por herencia metro, rima ni arquitectura. Etiquetas como «española», «italiana» o «provenzal» son ejemplos posibles, no categorías que deban crearse o asignarse de antemano.

### Configuraciones

Una forma podrá admitir una o varias configuraciones estructuradas. Por ejemplo, la copla real puede representarse mediante una configuración isométrica y otra con pie quebrado.

Una configuración podrá declarar:

- patrón métrico ordenado;
- tamaño fijo, mínimo, máximo o repetición;
- estructura interna del verso, como hemistiquios y cesura;
- régimen y esquema de rima;
- correspondencias de rima entre versos, unidades o secciones;
- secciones o subunidades;
- repeticiones de palabras, versos o estribillos;
- rasgos fijos, admitidos o preferentes.

Así, las alternativas no se funden en una bolsa de valores ni se convierten necesariamente en formas distintas.

El modelo debe poder expresar también reglas estructurales como el encadenamiento `ABA | BCB | CDC`, la relación entre vuelta y estribillo o las restricciones combinatorias de la quintilla. No se traducirán expresiones cualitativas como «mayoría» a porcentajes artificialmente precisos: se conservarán como rasgos definitorios, habituales o destacables.

### Rasgos transversales

Propiedades como final esdrújulo, pie quebrado, dístico final o rima interna se registrarán como rasgos. Podrán caracterizar una configuración o una realización observada sin crear una nueva forma.

Las vocales concretas de una asonancia se conservarán, cuando proceda, como un valor normalizado de la rima y no como identidad de una forma. En la interfaz se utilizará «Vocales de la asonancia»; «timbre» quedará como término técnico documentado, no como etiqueta obligatoria para los editores.

No toda diferencia respecto de una forma es un rasgo. `Hipométrico`, por ejemplo, puede derivarse de comparar una medida observada con la esperada; una ruptura de rima es una relación con el patrón normativo. Las dimensiones centrales —medida, rima, estructura y repetición— conservarán modelos propios y no se forzarán a un EAV de rasgos.

### Alias, relaciones y fuentes

El array actual de equivalencias se separará en:

- nombres alternativos o alias;
- relaciones semánticas entre formas.

La bibliografía se normalizará mediante fuentes y aserciones. Cada afirmación relevante podrá indicar su procedencia, responsable, fecha y grado de confianza.

## Caracterización editorial

La caracterización distinguirá **norma, realización y diferencias**:

1. el editor selecciona la forma;
2. selecciona una configuración solo cuando haya alternativas relevantes;
3. responde los grupos de elección que el catálogo haya declarado útiles;
4. localiza unidades internas cuando una respuesta pueda variar entre ellas;
5. registra únicamente dónde la secuencia difiere de la configuración y de las alternativas admitidas.

Se adopta un modelo de mundo cerrado para las secuencias guardadas: lo no registrado como
desviación se interpreta como cumplimiento de la configuración y de las elecciones
realizadas. Una pregunta obligatoria sin respuesta sí impide guardar. No habrá campos
editoriales de certeza, revisión o pendiente. La caracterización se realiza de una vez y la
complejidad formal reside en el catálogo, no en el formulario de la obra.

Una diferencia podrá localizarse por `v_ini` y `v_fin` y reutilizará las entidades normalizadas:

- la medida exacta observada, si se conoce; en caso contrario, la relación `menor_que_norma` o `mayor_que_norma`;
- una relación cualitativa con la rima esperada —falta, aparición no esperada, cambio de régimen o ruptura de encadenamiento— sin exigir una nueva rima que el corpus no permite reconstruir;
- un rasgo y valor del catálogo cuando la observación sea realmente un rasgo;
- una alteración de estructura o repetición mediante su dimensión específica.

Las caracterizaciones por rango que no pertenecen al dominio métrico, como `cantado`, `prosa` o `laguna`, podrán mantenerse en su mecanismo general. Las irregularidades métricas se migrarán al nuevo modelo de observaciones y no constituirán un segundo vocabulario paralelo.

Los actuales subtipos internos de quintilla representan mejor unidades o realizaciones con distintos patrones de rima que formas nuevas. Deben evolucionar hacia unidades métricas internas asociadas a una configuración o patrón.

## Búsqueda, fichas y laboratorio

Las superficies públicas futuras deberán utilizar facetas independientes:

- forma canónica;
- familia;
- metro observado;
- régimen de rima;
- arquitectura;
- configuración;
- rasgos.

Los datos derivados distinguirán entre:

- observación directa;
- consecuencia necesaria de la forma identificada;
- posibilidad admitida por la forma.

Bajo la convención de mundo cerrado, la ausencia de una diferencia en una secuencia guardada equivale a conformidad con la norma. Si la norma del catálogo cambia, la adaptación o invalidación se resolverá mediante migración o regeneración técnica, no mediante una nueva carga de trabajo para el editor.

No debe afirmarse que una obra contiene todos los metros permitidos por una forma si no se han observado. Las proyecciones públicas y analíticas podrán seguir precomputándose, pero se regenerarán desde el nuevo dominio normalizado.

Las fichas y los resúmenes públicos actuales son datos de prueba y la web todavía no está abierta. Por tanto, no constituyen un contrato que deba conservarse durante la migración: se podrán descartar y regenerar. Sí son datos reales y deben preservarse estrictamente las secuencias, los rangos y las caracterizaciones métricas ya declaradas en cada obra.

## Demarcador

El demarcador se generará desde configuraciones revisadas y aprobadas. No consultará todo el modelo relacional durante cada respuesta:

1. se editan los datos normalizados;
2. se aprueban las formas y configuraciones demarcables;
3. se compila un artefacto JSON;
4. se publica una versión concreta.

El JSON será un producto regenerable y versionado, no la fuente manual de verdad.

Las candidatas serán formas seleccionables. Las familias organizarán la búsqueda y las configuraciones aportarán las alternativas. Las preguntas podrán ordenarse según su capacidad discriminatoria entre las candidatas todavía compatibles.

El demarcador preguntará por rasgos complejos solo si son observables para el editor y discriminan entre las candidatas restantes. No preguntará por porcentajes exactos, procedencia histórica ni detalles ya inferibles de las respuestas anteriores. Siempre conservará una salida «No sé».

## Administración e interfaces

El catálogo métrico tendrá una administración propia, separada del editor genérico de vocabularios. El IP trabajará con formas, configuraciones, familias, tradiciones, patrones, relaciones y fuentes mediante editores específicos; no tendrá que editar directamente las tablas.

El editor de obras verá una superficie mucho más pequeña:

1. forma;
2. configuración, si es necesaria;
3. bloque opcional «Diferencias respecto de la forma»;
4. otras caracterizaciones por rango no métricas.

Las opciones de diferencia se calcularán desde la configuración seleccionada, de modo que no se muestre todo el catálogo en cada secuencia.

## Grafos, interoperabilidad y análisis

PostgreSQL seguirá siendo la fuente de verdad. A partir de sus relaciones podrán generarse grafos para:

- navegar familias, tradiciones y relaciones históricas;
- detectar nodos huérfanos, ciclos o configuraciones contradictorias;
- visualizar el impacto de un cambio;
- construir redes derivadas de similitud o difusión;
- explicar la ontología en publicaciones.

No se necesita una base de datos de grafos para el tamaño actual. Las redes de similitud serán resultados analíticos, no relaciones canónicas almacenadas como verdad.

La interoperabilidad con TEI, POSTDATA, PoeMetCa o ReMetCa podrá apoyarse en identificadores estables y referencias externas tipadas. El modelo relacional podrá exportarse como JSON-LD o RDF sin convertir esos formatos en la fuente de edición.

La separación entre norma y diferencias también permitirá generar variables para estudios de autoría, datación y evolución métrica: distribución de formas, configuraciones, transiciones, rasgos y tasas de desviación. El valor analítico dependerá de la consistencia del protocolo y del volumen del corpus; sin texto, describirá el comportamiento métrico anotado, no los rasgos léxicos o fonéticos completos.

## Soluciones descartadas

No se recomienda:

- añadir solamente una tabla 1:1 de detalles métricos enlazada a `vocabularios`;
- copiar las 119 entradas sin reclasificarlas;
- trasladar sin cambios la jerarquía padre/hijo;
- usar un único JSONB para todos los datos relevantes;
- mantener `null` como mezcla de heredado, variable, desconocido y no aplicable;
- realizar una migración destructiva en un solo despliegue.

## Estrategia general

La migración debe ser aditiva:

1. clasificar las 119 entradas actuales;
2. someter la matriz a revisión del IP;
3. crear las nuevas tablas sin cambiar consumidores;
4. conservar una correspondencia entre cada UUID anterior y su destino;
5. migrar y comprobar, sin pérdida, las secuencias, rangos y caracterizaciones existentes;
6. cambiar el editor;
7. reconstruir desde cero los resúmenes, filtros y datos de laboratorio;
8. regenerar el demarcador;
9. retirar el modelo anterior cuando exista paridad comprobada.

La dificultad principal no es crear las tablas, sino acordar el significado de cada entrada y transformar sin pérdida las anotaciones ya realizadas.
