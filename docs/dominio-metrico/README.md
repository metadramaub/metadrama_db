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

0bis. [El modelo métrico aplicado](./implementacion-metrica.md)
   Qué parte de esa ontología se realiza, qué se restringe por el corpus y cómo se recoge el
   dato: el catálogo, las preguntas del editor y el registro. Con arquetipos diagramados y la
   correspondencia con las tablas, las capas, los consumidores y las garantías de la base.
   Absorbió en agosto de 2026 la antigua «Arquitectura técnica». Con [diagrama](./implementacion-metrica.svg).

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

6ter. [Poda de la prosa que la ficha ya dibuja](./historico/poda-de-la-prosa.md) — **archivado**
   Propuesta frase a frase, generada del catálogo: qué prosa dejó de aportar cuando la ficha
   empezó a dibujar la estructura. Quedó cerrada en 0 de 191 el 13 de agosto de 2026 y pasó a
   `historico/`. Sigue siendo regenerable con `npm run poda:informe`, que reescribe el archivado.
   La revisión que continúa hoy no usa este informe: va **forma por forma**, con una migración
   por forma, porque un barrido global no permitía comprobar cada ficha antes de la siguiente.

### El registro y su migración

7. [Qué guarda el registro](./que-guarda-el-registro.md)
   Tres secuencias inventadas, fila a fila, para ver qué escribe cada tabla y qué se deriva
   después. Es donde se entiende la capa resuelta.

8. [Editor de secuencias métricas V2 · especificación histórica](./historico/editor-secuencias-v2-2026-08-11.md)
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
    **Por qué** algunos términos legados no declaran todavía su destino en el catálogo y qué
    decidió el IP sobre cada uno. Es lo que hay que cerrar antes del backfill.

13bis. [Estado de las equivalencias](./informe-equivalencias.md) · **generado**
    Cuántos términos declaran destino, cuáles no, cuánto se usa cada uno y cómo resuelve cada
    secuencia. No se edita: lo produce `npm run equivalencias:informe`.

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

Viven en un solo sitio: [las decisiones que gobiernan el modelo](./implementacion-metrica.md#las-decisiones-que-gobiernan-el-modelo).
Hasta el 10 de agosto de 2026 estaban repetidas aquí, en el documento del modelo aplicado y en
CONTEXTO, con redacciones que ya no coincidían.

## Estado

La fase aditiva y la primera revisión técnica del catálogo están implementadas en la
rama `develop`: esquema del catálogo, importación trazable de las 119 entradas, superficie de
trabajo en `/dashboard/metrica` y compilación de pruebas internas del demarcador. `/demarcador`
abre por defecto la última prueba compilada desde este catálogo; si el catálogo
cambia, la interfaz señala que debe actualizarse la prueba. La antigua ruta de
auditoría `/dashboard/demarcador` redirige a «Validación y demarcador». Las
migraciones deben aplicarse antes de abrir la nueva sección. Las decisiones que aún
requieren criterio del IP están reunidas en un único registro de cuestiones y no se
ocultan mediante arreglos temporales de exportación.

El catálogo público cubre formas y sus arquitecturas; tradiciones, denominaciones y relaciones;
metros, esquemas métricos y de rima, secciones, repeticiones y variedades; rasgos y valores
controlados; y fuentes con sus afirmaciones. El dashboard no lo edita: todos los cambios se
aplican por migración. La matriz de las 119 entradas se conserva como trazabilidad de importación:
sus pendientes no bloquean la validación ni el demarcador.

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
