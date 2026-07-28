# Propuesta para separar las formas métricas del vocabulario genérico

Fecha: 28 de julio de 2026

Estado: propuesta conceptual aprobada como punto de partida; no implementada

Documentos relacionados:

- [Auditoría del vocabulario métrico](./informe-auditoria-vocabulario-metrico.md)
- [Arquitectura del dominio métrico](./arquitectura-dominio-metrica.md)
- [Matriz de reclasificación](./matriz-reclasificacion-formas-metricas.md)

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

`formas_metricas` contendrá exclusivamente formas que puedan constituir una identificación editorial real: romance, quintilla, copla real, soneto, silva, etc.

Las agrupaciones de navegación y estudio se modelarán como `familias_metricas`. Una familia no tiene por qué ser seleccionable ni constituir una forma.

La pertenencia de una forma a una familia se expresará mediante una relación propia, no mediante un padre genérico. Cuando dos formas mantengan una relación semántica real, esta se tipará: `subtipo_de`, `variante_historica_de`, `relacionada_con`, etc.

### Configuraciones

Una forma podrá admitir una o varias configuraciones estructuradas. Por ejemplo, la copla real puede representarse mediante una configuración isométrica y otra con pie quebrado.

Una configuración podrá declarar:

- patrón métrico ordenado;
- tamaño fijo, mínimo, máximo o repetición;
- régimen y esquema de rima;
- secciones o subunidades;
- rasgos fijos, admitidos o preferentes.

Así, las alternativas no se funden en una bolsa de valores ni se convierten necesariamente en formas distintas.

### Rasgos transversales

Propiedades como final esdrújulo, pie quebrado, dístico final, rima interna, timbre asonante o irregularidad se registrarán como rasgos. Podrán caracterizar una configuración o una realización observada sin crear una nueva forma.

### Alias, relaciones y fuentes

El array actual de equivalencias se separará en:

- nombres alternativos o alias;
- relaciones semánticas entre formas.

La bibliografía se normalizará mediante fuentes y aserciones. Cada afirmación relevante podrá indicar su procedencia, responsable, fecha y grado de confianza.

## Caracterización editorial

La edición distinguirá:

1. forma identificada;
2. configuración, si puede reconocerse;
3. datos observados: metros, rima, esquema o arquitectura;
4. rasgos adicionales;
5. estado desconocido o no determinado.

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
