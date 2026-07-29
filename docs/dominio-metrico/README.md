# Dominio métrico

Fecha de consolidación: 28 de julio de 2026

Esta carpeta reúne la auditoría, las decisiones conceptuales y la arquitectura propuestas para separar las formas métricas del vocabulario genérico de METADRAMA.

## Documentos

1. [Síntesis narrativa del nuevo dominio métrico](./sintesis-narrativa-dominio-metrico.md)
   Explicación general, con un lenguaje poco técnico, para presentar el problema, la propuesta y sus beneficios.

2. [Informe de auditoría del vocabulario métrico](./informe-auditoria-vocabulario-metrico.md)
   Diagnóstico de las 119 entradas actuales, contradicciones de datos y problemas de la jerarquía padre/hijo.

3. [Propuesta conceptual del dominio](./propuesta-dominio-metrica.md)
   Decisiones generales: formas, familias, tradiciones, configuraciones, elecciones de realización, desviaciones, demarcador y redes.

4. [Arquitectura del dominio métrico](./arquitectura-dominio-metrica.md)
   Modelo relacional, anotación editorial, migración, interfaces, proyecciones y criterios de aceptación.

5. [Editor de secuencias métricas V2](./editor-secuencias-v2.md)
   Grupos de elección, escenarios aislados, persistencia de pruebas y contrato de la interfaz futura.

6. [Contratos del registrador para formas revisadas](./contratos-registrador-formas-revisadas.md)
   Qué se deriva, qué pregunta el editor, qué se guarda y cómo se valida cada forma ya revisada.

7. [Matriz de reclasificación](./matriz-reclasificacion-formas-metricas.md)
   Destino preliminar de cada una de las 119 entradas del vocabulario actual.

8. [Ejemplos de formalización](./ejemplos-formalizacion-ontologia-metrica.md)
   Grafos y ejemplos de cómo se traducen formas y secuencias concretas a las tablas propuestas.

9. [Revisiones de formas](./revisiones-formas/)
   Contraste forma por forma entre el criterio especializado del IP, la bibliografía y su
   traducción al catálogo. Incluye la [quintilla](./revisiones-formas/quintilla.md), la
   revisión de [terceto y terceto encadenado](./revisiones-formas/tercetos.md), la
   [silva](./revisiones-formas/silva.md), la frontera entre
   [series endecasilábicas](./revisiones-formas/series-endecasilabicas.md), el
   [romance](./revisiones-formas/romance.md), el
   [soneto](./revisiones-formas/soneto.md), el
   [villancico](./revisiones-formas/villancico.md), el
   [zéjel](./revisiones-formas/zejel.md) y un
   [registro vivo de cuestiones para confirmar con el IP](./revisiones-formas/cuestiones-para-el-ip.md).

## Decisiones consolidadas

- Las formas métricas constituirán un dominio propio.
- Familia, tradición, configuración, patrón, rasgo y alias son conceptos diferentes.
- Las tradiciones documentadas son relaciones muchos-a-muchos, no padres estructurales.
- Las tradiciones solo se asignan con apoyo documental; los nombres precargados en la prueba inicial no constituyen afirmaciones bibliográficas.
- Una configuración prototípica es opcional. El alcance genérico `unidad` queda como residuo de importación y debe precisarse durante la revisión.
- El orden técnico se oculta salvo donde cambia el significado métrico: posiciones, secciones y repeticiones.
- Los patrones de rima separan su comportamiento computable de la etiqueta de esquema. El romance es el primer caso revisado: ciclo repetible `suelto + a` en una serie octosilábica.
- El criterio especializado del IP para el corpus se conserva cuando una preceptiva general difiere; la bibliografía documenta y permite revisar la divergencia, pero no la sobrescribe automáticamente.
- Las fuentes declaradas del catálogo son publicaciones bibliográficas académicas identificables, no páginas web ni vídeos. Una URL puede localizar una publicación digital, pero no constituye por sí sola la autoridad de la fuente.
- Los slugs de configuración describen la alternativa y no su condición de prototípica; el romance usa `octosilabico_asonante`. Los selectores de patrón solo aparecen cuando hay varias opciones reales.
- La estructura interna del verso y los enlaces de rima se formalizan en el catálogo.
- No se usan porcentajes artificiales para traducir «mayoría».
- La anotación de secuencias sigue el modelo `configuración normativa + diferencias`.
- Una secuencia guardada sin diferencias se considera conforme con la norma.
- No se piden al editor certeza ni estado de revisión.
- Las observaciones reutilizan metros, rimas, estructuras y rasgos normalizados.
- Las caracterizaciones no métricas por rango se conservan en su dominio general.
- El JSON del demarcador y las redes de similitud son artefactos regenerables.

## Estado

La primera fase aditiva está implementada en la rama `develop`: esquema del
catálogo, importación trazable de las 119 entradas, gestor permanente en
`/dashboard/metrica` y compilación de pruebas internas del demarcador. `/demarcador`
abre por defecto la última prueba compilada desde este catálogo; si el catálogo
cambia, la interfaz señala que debe actualizarse la prueba. La antigua ruta de
auditoría `/dashboard/demarcador` redirige a «Validación y demarcador». Las
migraciones deben aplicarse antes de abrir la nueva sección.

El gestor permanente cubre formas y configuraciones; familias, tradiciones,
alias y relaciones; modelos de verso, patrones métricos y de rima, secciones y
repeticiones; rasgos y valores controlados; y fuentes con sus afirmaciones. La
matriz de las 119 entradas se conserva como trazabilidad de importación: sus
pendientes no bloquean la validación ni el demarcador.

Las declaraciones reales de las secuencias no se han migrado ni se consultan
desde el nuevo catálogo; ese cambio queda expresamente aplazado hasta que el
catálogo y el demarcador estén revisados.
