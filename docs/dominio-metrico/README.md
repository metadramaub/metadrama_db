# Dominio métrico

Fecha de consolidación: 30 de julio de 2026

Esta carpeta reúne la ontología, los criterios y la arquitectura del dominio métrico de
METADRAMA, separado del vocabulario genérico del proyecto.

## Documentos

**Leer primero:** [Contexto para continuar el trabajo](./CONTEXTO-PARA-CONTINUAR.md).
Estado operativo, decisiones vigentes, fronteras de seguridad y ruta de lectura para
retomar el proyecto en otro chat.

**Trabajo en curso:** [Estado de la revisión del catálogo](./revision-del-catalogo-estado.md).
El catálogo se está contrastando forma por forma con seis monografías. Ese documento dice qué
está hecho, qué falta, con qué método y en qué orden.

**Demarcador:** [contrato, matemática y decisiones de producto](./demarcador-metrico.md).

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
   comprobables y las decisiones que corresponden al IP. **De lectura obligada antes de
   formalizar o corregir una forma.**

### El catálogo: cómo se revisa y cómo se comprueba

3. [Estado de la revisión del catálogo](./revision-del-catalogo-estado.md)
   El trabajo en curso: qué formas están contrastadas con las seis fuentes, cuáles faltan, el
   procedimiento y el orden. **La cuenta se lleva aquí y en ningún otro sitio.**

4. [Dónde vive la prosa del catálogo](./donde-vive-la-prosa.md)
   Los ocho criterios de redacción y qué se escribe en cada campo: definición, descripción,
   nota, afirmación de fuente.

5. [Informe de conformidad del catálogo](./informe-conformidad-catalogo.md)
   Estado de los datos poblados frente a los criterios de nivel. Se regenera con
   `npm run audit:metrica`.

6. [Contratos del registrador para formas revisadas](./contratos-registrador-formas-revisadas.md)
   Qué se deriva, qué pregunta el editor, qué se guarda y cómo se valida cada forma ya revisada.

### El registro y su migración

7. [Arquitectura técnica](./arquitectura-dominio-metrica.md)
   Capas, proyecciones, consumidores, invalidación de derivados, integridad y permisos.
   No especifica tablas: la fuente de verdad del esquema es la base de datos.

8. [Qué guarda el registro](./que-guarda-el-registro.md)
   Tres secuencias inventadas, fila a fila, para ver qué escribe cada tabla y qué se deriva
   después. Es donde se entiende la capa resuelta.

9. [Editor de secuencias métricas V2](./editor-secuencias-v2.md)
   Grupos de elección, escenarios aislados, persistencia de pruebas y contrato de la interfaz
   futura.

10. [Plan de migración de las anotaciones](./plan-migracion-anotaciones.md)
    Qué hay que hacer para llevar las declaraciones reales al catálogo nuevo, con sus
    condiciones previas y criterios de aceptación. No iniciado.

11. [Cómo se migra una obra](./como-se-migra-una-obra.md)
    El procedimiento obra por obra, escrito para poder explicárselo a quien la anotó. Los
    informes se generan con `npm run migracion:informe` y viven en [migracion/](./migracion/).

12. [Plan de desviaciones y caracterizaciones](./plan-desviaciones-y-caracterizaciones.md)
    Cierra el vocabulario de las desviaciones —cinco dimensiones, seis relaciones, tres
    invariantes— y reparte lo que hoy es «caracterización por rango» entre desviación, rasgo
    y caracterización real. Decidido, no ejecutado.

13. [Equivalencias pendientes](./equivalencias-pendientes.md)
    Los términos legados que todavía no declaran su destino en el catálogo. Es lo que hay que
    cerrar antes del backfill.

### Trabajo abierto y trazabilidad

14. [Decisiones de modelo](./decisiones-de-modelo.md)
    Andamiaje temporal: los porqués de las formas aún sin revisar. **Se vacía, no crece**;
    cada bloque desaparece cuando su forma se absorbe en el catálogo.

15. [Histórico](./historico/)
    Documentos del proceso que ya no describen el estado actual pero conservan trazabilidad y
    razonamiento: el vocabulario legado con sus 119 entradas, la matriz de reclasificación, la
    auditoría del catálogo —resuelta entera—, el plan de la fase A de la revisión, la propuesta
    conceptual inicial y la especificación de tablas superada.

16. [Revisiones de formas](./revisiones-formas/)
   Contraste forma por forma entre el criterio especializado del IP, la bibliografía y su
   traducción al catálogo.

   **Estas fichas están en retirada.** Desde el 5 de agosto de 2026 lo descriptivo vive en el
   catálogo y se lee en `/formas`, generado del dato: un `.md` paralelo solo puede quedarse
   viejo. A medida que una forma se revisa, su prosa se muda al dato, sus dudas resueltas se
   podan y su ficha se borra.

   **Cuáles quedan es lo que hay en la carpeta**, y no se lista aquí para que no se desajuste.
   El estado de la revisión —qué formas están hechas y cuáles faltan— vive en
   [revision-del-catalogo-estado.md](./revision-del-catalogo-estado.md).

   Y el [registro vivo de cuestiones para confirmar con el IP](./revisiones-formas/cuestiones-para-el-ip.md),
   que **no** se retira: es donde vive lo que sigue sin decidir.

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
declara, las familias han desaparecido y las tradiciones están pobladas.

Desde el 5 de agosto está en curso la **revisión del catálogo contra las fuentes**, que
contrasta cada forma con seis monografías y corrige el dato donde la bibliografía demuestra que
estaba mal. Va por 18 formas de 27, y su estado detallado está en
[revision-del-catalogo-estado.md](./revision-del-catalogo-estado.md).

Las declaraciones reales de las secuencias no se han migrado ni se consultan
desde el nuevo catálogo; ese cambio queda expresamente aplazado hasta que el
catálogo y el demarcador estén revisados.
