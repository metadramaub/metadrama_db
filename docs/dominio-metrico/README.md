# Dominio métrico

Fecha de consolidación: 30 de julio de 2026

Esta carpeta reúne la ontología, los criterios y la arquitectura del dominio métrico de
METADRAMA, separado del vocabulario genérico del proyecto.

## Documentos

**Leer primero:** [Contexto para continuar el trabajo](./CONTEXTO-PARA-CONTINUAR.md).
Estado operativo, decisiones vigentes, fronteras de seguridad y ruta de lectura para
retomar el proyecto en otro chat.

0. [Ontología del verso español](./ontologia-verso-espanol.md)
   Qué es el verso español y de qué está hecho: medida, ritmo, rima, agrupación, forma y la
   relación entre norma y realización. Describe posibilidades, no un corpus.
   **Lectura previa a todo lo demás.** Con [diagrama](./ontologia-verso-espanol.svg).

0bis. [La implementación de METADRAMA](./implementacion-metrica.md)
   Qué parte de esa ontología se realiza, qué se restringe por el corpus y cómo se recoge el
   dato: el catálogo, las preguntas del editor y el registro. Con arquetipos diagramados y la
   correspondencia con las tablas. Y su [diagrama](./implementacion-metrica.svg).

1. [Síntesis narrativa del nuevo dominio métrico](./sintesis-narrativa-dominio-metrico.md)
   Explicación general, con un lenguaje poco técnico, para presentar el problema, la propuesta y sus beneficios.

2. [Criterios de nivel](./criterios-de-nivel.md)
   Cómo se decide, ante un hecho observado, en qué nivel se registra. Incluye las reglas
   comprobables y las decisiones que corresponden al IP.

3. [Informe de conformidad del catálogo](./informe-conformidad-catalogo.md)
   Estado de los datos poblados frente a esos criterios. Se regenera con
   `npm run audit:metrica`.

3bis. [Auditoría del catálogo](./auditoria-catalogo.md)
   Lo que las reglas del informe no alcanzan: coherencia de la implementación con la
   ontología, huecos del modelo y estado de las fichas. Con lo aplicado marcado.

4. [Arquitectura técnica](./arquitectura-dominio-metrica.md)
   Capas, proyecciones, consumidores, invalidación de derivados, integridad y permisos.
   No especifica tablas: la fuente de verdad del esquema es la base de datos.

4bis. [Plan de migración de las anotaciones](./plan-migracion-anotaciones.md)
   Qué hay que hacer para llevar las declaraciones reales al catálogo nuevo, con sus
   condiciones previas y criterios de aceptación. No iniciado.

5. [Editor de secuencias métricas V2](./editor-secuencias-v2.md)
   Grupos de elección, escenarios aislados, persistencia de pruebas y contrato de la interfaz futura.

6. [Contratos del registrador para formas revisadas](./contratos-registrador-formas-revisadas.md)
   Qué se deriva, qué pregunta el editor, qué se guarda y cómo se valida cada forma ya revisada.

7. [Histórico](./historico/)
   Documentos del proceso que ya no describen el estado actual pero conservan
   trazabilidad y razonamiento: diagnóstico del vocabulario legado, matriz de
   reclasificación de las 119 entradas, propuesta conceptual inicial y especificación de
   tablas superada.

8. [Revisiones de formas](./revisiones-formas/)
   Contraste forma por forma entre el criterio especializado del IP, la bibliografía y su
   traducción al catálogo. Incluye la [quintilla](./revisiones-formas/quintilla.md), la
   revisión de [terceto y terceto encadenado](./revisiones-formas/tercetos.md), la
   [silva](./revisiones-formas/silva.md), la frontera entre
   [series endecasilábicas](./revisiones-formas/series-endecasilabicas.md), el
   [romance, con el romancillo y el heroico](./revisiones-formas/romance.md), el
   tratamiento de los [tramos sin forma](./revisiones-formas/tramos-sin-forma.md), el
   [soneto](./revisiones-formas/soneto.md), el
   [villancico](./revisiones-formas/villancico.md), el
   [zéjel](./revisiones-formas/zejel.md), la
   [coplas y sextillas, incluida la copla real](./revisiones-formas/coplas-y-sextillas.md),
   las [décimas](./revisiones-formas/decimas.md), la
   [redondilla](./revisiones-formas/redondilla.md), el
   [cuarteto](./revisiones-formas/cuarteto.md), la
   [endecha real](./revisiones-formas/endecha-real.md), la
   [octava real](./revisiones-formas/octava-real.md), la
   [novena](./revisiones-formas/novena.md), la
   [lira](./revisiones-formas/lira.md), el
   [sexteto-lira](./revisiones-formas/sexteto-lira.md), el
   [sexteto, con la sexta rima](./revisiones-formas/sexteto.md), la
   [seguidilla](./revisiones-formas/seguidilla.md), la
   [sextina](./revisiones-formas/sextina.md), la
   [canción petrarquista](./revisiones-formas/cancion-petrarquista.md) y un
   [registro vivo de cuestiones para confirmar con el IP](./revisiones-formas/cuestiones-para-el-ip.md).

## Decisiones consolidadas

- Las formas métricas constituyen un dominio propio.
- El nivel de cada hecho se decide con la pregunta de la variación: lo que puede cambiar
  dentro de una secuencia es esquema, variedad o rasgo; lo constante que no cambia el
  nombre es arquitectura; lo que obligaría a cortar la secuencia es otra forma.
- Forma, arquitectura, esquema métrico, esquema de rima, variedad, sección, repetición,
  rasgo, elección, denominación, tradición y relación son conceptos distintos.
- Las formas se distinguen de los tramos sin forma por su tipo de registro. Estos
  comparten el selector, pero no tienen norma ni intervienen como formas en los análisis.
- Tipo de registro y prioridad de identificación son ejes independientes: una forma
  estructurada puede ser de último recurso sin dejar de ser forma.
- El metro es una entidad del dominio, con sus sílabas y, si es compuesto, sus
  hemistiquios y su cesura. El arte mayor o menor se deriva, no se almacena.
- Las tradiciones son pertenencias muchos-a-muchos, sin herencia estructural. Proceden de
  la clasificación previa del proyecto, que es autoridad suficiente para asignarlas.
- No existe el concepto de familia: agrupar formas para contar es una categoría del
  estudio y se declara en la capa de proyección, no en la ontología.
- Los esquemas de rima separan su comportamiento computable de la notación legible.
  Romance usa el ciclo repetible `suelto + a`; sus realizaciones de 6, 7, 8 y 11 sílabas
  son arquitecturas exactas de una misma forma.
- Un componente ya formalizado se reutiliza; no se copia.
- El criterio especializado del IP para el corpus se conserva cuando una preceptiva general difiere; la bibliografía documenta y permite revisar la divergencia, pero no la sobrescribe automáticamente.
- Las fuentes declaradas del catálogo son publicaciones bibliográficas académicas identificables, no páginas web ni vídeos. Una URL puede localizar una publicación digital, pero no constituye por sí sola la autoridad de la fuente.
- El orden técnico se oculta salvo donde cambia el significado métrico: posiciones, secciones y repeticiones.
- No se usan porcentajes artificiales para traducir «mayoría»: el matiz vive en la
  modalidad con que un rasgo interviene en una arquitectura.
- La anotación de secuencias sigue el modelo `norma + elecciones + diferencias`.
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
- El ritmo acentual de los versos queda fuera del alcance del proyecto.
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

El gestor permanente cubre formas y sus arquitecturas; tradiciones, denominaciones y
relaciones; metros, esquemas métricos y de rima, secciones, repeticiones y variedades;
rasgos y valores controlados; elecciones; y fuentes con sus afirmaciones. La matriz de las
119 entradas se conserva como trazabilidad de importación: sus pendientes no bloquean la
validación ni el demarcador.

La ontología quedó revisada desde la base el 30 de julio de 2026 y la migración
estructural se completó el 31: la base habla ya los nombres definitivos de
[la implementación](./implementacion-metrica.md), el metro es una entidad del dominio, la unidad se
declara, las familias han desaparecido y las tradiciones están pobladas. Queda un hueco de
esquema —la respuesta que define la norma— y los defectos de datos del
[informe de conformidad](./informe-conformidad-catalogo.md), que necesitan al IP.

Las declaraciones reales de las secuencias no se han migrado ni se consultan
desde el nuevo catálogo; ese cambio queda expresamente aplazado hasta que el
catálogo y el demarcador estén revisados.
