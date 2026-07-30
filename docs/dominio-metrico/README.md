# Dominio métrico

Fecha de consolidación: 30 de julio de 2026

Esta carpeta reúne la auditoría, las decisiones conceptuales y la arquitectura propuestas para separar las formas métricas del vocabulario genérico de METADRAMA.

## Documentos

**Leer primero:** [Contexto para continuar el trabajo](./CONTEXTO-PARA-CONTINUAR.md).
Estado operativo, decisiones vigentes, fronteras de seguridad y ruta de lectura para
retomar el proyecto en otro chat.

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
   [romance heroico](./revisiones-formas/romance-heroico.md), el
   [romancillo](./revisiones-formas/romancillo.md), el
   tratamiento de las [salidas editoriales](./revisiones-formas/salidas-editoriales.md), el
   [soneto](./revisiones-formas/soneto.md), el
   [villancico](./revisiones-formas/villancico.md), el
   [zéjel](./revisiones-formas/zejel.md), la
   [coplas y sextillas, incluida la copla real](./revisiones-formas/coplas-y-sextillas.md),
   las [décimas](./revisiones-formas/decimas.md), la
   [redondilla](./revisiones-formas/redondilla.md), la
   [octava real](./revisiones-formas/octava-real.md), la
   [novena](./revisiones-formas/novena.md), la
   [lira](./revisiones-formas/lira.md), el
   [sexteto-lira](./revisiones-formas/sexteto-lira.md), la
   [sexta rima](./revisiones-formas/sexta-rima.md), el
   [sexteto](./revisiones-formas/sexteto.md), la
   [seguidilla](./revisiones-formas/seguidilla.md), la
   [sextina](./revisiones-formas/sextina.md), la
   [canción petrarquista](./revisiones-formas/cancion-petrarquista.md) y un
   [registro vivo de cuestiones para confirmar con el IP](./revisiones-formas/cuestiones-para-el-ip.md).

## Decisiones consolidadas

- Las formas métricas constituirán un dominio propio.
- `formas_metricas` distingue expresamente las formas de las salidas editoriales
  mediante `tipo_registro`; estas últimas comparten el selector, pero no poseen
  configuraciones ni intervienen como formas en los análisis.
- Familia, tradición, configuración, patrón, rasgo y alias son conceptos diferentes.
- Las tradiciones documentadas son relaciones muchos-a-muchos, no padres estructurales.
- Las tradiciones solo se asignan con apoyo documental; los nombres precargados en la prueba inicial no constituyen afirmaciones bibliográficas.
- Una configuración prototípica es opcional. El alcance genérico `unidad` queda como residuo de importación y debe precisarse durante la revisión.
- El orden técnico se oculta salvo donde cambia el significado métrico: posiciones, secciones y repeticiones.
- Los patrones de rima separan su comportamiento computable de la etiqueta de esquema.
  Romance utiliza el ciclo repetible `suelto + a`; sus realizaciones de 6, 7, 8 y 11
  sílabas son configuraciones exactas de una misma forma.
- El criterio especializado del IP para el corpus se conserva cuando una preceptiva general difiere; la bibliografía documenta y permite revisar la divergencia, pero no la sobrescribe automáticamente.
- Las fuentes declaradas del catálogo son publicaciones bibliográficas académicas identificables, no páginas web ni vídeos. Una URL puede localizar una publicación digital, pero no constituye por sí sola la autoridad de la fuente.
- Los slugs de configuración describen la alternativa y no su condición de prototípica; el romance usa `octosilabico_asonante`. Los selectores de patrón solo aparecen cuando hay varias opciones reales.
- La estructura interna del verso y los enlaces de rima se formalizan en el catálogo.
- No se usan porcentajes artificiales para traducir «mayoría».
- La anotación de secuencias sigue el modelo `configuración normativa + diferencias`.
- Una secuencia guardada sin diferencias se considera conforme con la norma.
- No se piden al editor certeza ni estado de revisión.
- Las observaciones reutilizan metros, rimas, estructuras y rasgos normalizados.
- Las alternativas previstas por el catálogo se registran como elecciones, no como
  desviaciones. Las secciones y repeticiones solo se materializan cuando la forma las
  necesita.
- Las caracterizaciones no métricas por rango se conservan en su dominio general.
- Una forma reconocible con excepciones conserva su identidad y registra desviaciones;
  `Versificación irregular` y `Verso aislado` se reservan para tramos sin una forma
  reconocible.
- El JSON del demarcador y las redes de similitud son artefactos regenerables.

## Estado

La fase aditiva y la primera revisión técnica del catálogo están implementadas en la
rama `develop`: esquema del catálogo, importación trazable de las 119 entradas, gestor permanente en
`/dashboard/metrica` y compilación de pruebas internas del demarcador. `/demarcador`
abre por defecto la última prueba compilada desde este catálogo; si el catálogo
cambia, la interfaz señala que debe actualizarse la prueba. La antigua ruta de
auditoría `/dashboard/demarcador` redirige a «Validación y demarcador». Las
migraciones deben aplicarse antes de abrir la nueva sección. Las decisiones que aún
requieren criterio del IP están reunidas en un único registro de cuestiones y no se
ocultan mediante arreglos temporales de exportación.

El gestor permanente cubre formas y configuraciones; familias, tradiciones,
alias y relaciones; modelos de verso, patrones métricos y de rima, secciones y
repeticiones; rasgos y valores controlados; y fuentes con sus afirmaciones. La
matriz de las 119 entradas se conserva como trazabilidad de importación: sus
pendientes no bloquean la validación ni el demarcador.

Las declaraciones reales de las secuencias no se han migrado ni se consultan
desde el nuevo catálogo; ese cambio queda expresamente aplazado hasta que el
catálogo y el demarcador estén revisados.
