# Contexto para continuar el trabajo métrico

Actualizado: 31 de julio de 2026

Este es el documento que debe leer primero un nuevo chat. Resume el estado operativo y
enlaza la documentación detallada; no sustituye las revisiones filológicas de cada forma.

## Estado actual

- Rama de trabajo: `develop`. `main` corresponde a la versión desplegada y debe
  permanecer estable hasta decidir la integración.
- `develop` y producción comparten Supabase. No se ha creado ni hace falta otro proyecto.
- El catálogo nuevo usa tablas aditivas y está separado del vocabulario métrico legado.
- La versión requerida del modelo es `51`.
- La última migración es `20260731280000_disposicion_del_terceto.sql` y está aplicada.
  La base habla ya el vocabulario de la ontología: arquitectura, esquema métrico, esquema
  de rima, variedad, tramo sin forma, grado de especificación. La arquitectura declara
  además la extensión de su unidad —`unidad_versos_min` y `unidad_versos_max`—, y ninguna
  sección existe ya para decir que la unidad se repite: cuántas unidades contiene el pasaje
  se deriva del rango. La unidad es la realización que no cuelga de ninguna otra y no
  realiza ninguna sección; las secciones describen su interior. No existen familias, la
  pertenencia a una tradición no se tipifica y las denominaciones pueden nombrar una
  variedad y declararse posteriores. Arquitecturas y esquemas siguen una misma convención de
  nombre y slug, registrada en
  [la revisión de nomenclatura](./revision-nomenclatura.md). El catálogo tiene **25 formas y
  2 tramos sin forma**: la medida de toda forma isosilábica es arquitectura y ya no se
  pregunta, y lo que era una forma para decir «N unidades de esta otra» —doble sextilla,
  sexta rima, tercetos sin encadenar, pareados endecasílabos, copla manriqueña— vive en el
  nivel que le corresponde. Las formas con clasificación previa tienen ya su tradición; las
  restantes no la tienen porque no hay de dónde tomarla.
- `/dashboard/metrica` es el gestor permanente del catálogo y contiene también el editor
  V2 de prueba y la compilación del demarcador.
- El editor V2 escribe únicamente en tablas `*_editor_metrico`. No crea obras, no modifica
  las secuencias reales y no alimenta fichas, buscadores ni resúmenes públicos.
- Las declaraciones métricas existentes en las obras siguen usando el vocabulario legado.
  Su migración se hará más adelante, cuando el IP haya validado el catálogo y el
  demarcador. Hay editores trabajando y esta frontera no debe adelantarse.

## Decisiones que gobiernan el modelo

1. La base de datos es la fuente de verdad. El artefacto del demarcador, las fichas y las
   redes son proyecciones regenerables.
2. Forma, arquitectura, esquema, variedad, sección, repetición, rasgo, elección,
   denominación, tradición y relación son conceptos distintos. La antigua jerarquía
   padre/hijo no se reproduce automáticamente y no existe el concepto de familia.
3. El criterio especializado incorporado por el IP para el corpus se conserva. La
   bibliografía académica documenta contrastes, pero no lo sustituye silenciosamente.
4. Las fuentes declaradas deben ser publicaciones bibliográficas autorizadas; una página
   web o un vídeo no constituyen por sí solos una fuente del catálogo.
5. El nivel de cada hecho se decide preguntando si puede variar dentro de una misma
   secuencia. Una arquitectura prototípica es opcional.
6. El editor debe responder lo mínimo. Los resultados únicos se derivan; solo se muestran
   alternativas con valor analítico y desviaciones reales.
7. Rige una convención de mundo cerrado: una secuencia guardada sin desviaciones cumple
   la norma y las elecciones realizadas. No se piden certeza, revisión ni pendiente.
8. Las alternativas admitidas no son desviaciones. Las desviaciones reutilizan metros,
   rimas, estructuras, repeticiones y rasgos normalizados.
9. Las formas reconocibles conservan su identidad aunque tengan excepciones localizadas.
   `Versificación irregular` y `Verso aislado` son tramos sin forma, sin arquitectura,
   no formas comparables.
10. Una forma general no ha llegado a especializarse, pero es forma plena. La copla de pie
    quebrado y el sexteto son generales; eso no las equipara a los dos tramos sin
    forma.
11. Las restricciones de longitud obligan a revisar rangos incompatibles: múltiplos de la
    unidad fija, ciclos repetibles, composiciones cerradas y estructuras calculadas.

## Cómo se registra una secuencia

```text
forma
+ arquitectura
+ elecciones entre alternativas admitidas
+ realizaciones de la unidad y de sus secciones, cuando proceda
+ desviaciones localizadas
```

Cuántas unidades contiene la secuencia no se declara: se deriva del rango y de la extensión
que la arquitectura declara para su unidad.

Si no existe una forma reconocible:

```text
tramo sin forma
+ rango
+ observación opcional
```

Los detalles de cada forma ya revisada están resumidos en
[Contratos del registrador](./contratos-registrador-formas-revisadas.md). El editor debe
adaptarse a esos contratos y no contener reglas filológicas escritas únicamente en el
componente: las preguntas y posibilidades deben proceder del catálogo.

## Demarcador

- Se compila desde el catálogo nuevo, no desde el JSON legado.
- Las preguntas se ordenan por su capacidad de separar las candidatas restantes.
- Solo pregunta rasgos observables y razonables para el editor.
- `No sé` conserva candidatas; no afirma ni niega.
- Los tramos sin forma no compiten en el recorrido ordinario y aparecen únicamente
  cuando no queda una identificación más precisa.
- Si cambia el catálogo, la interfaz marca la prueba compilada como desactualizada y debe
  regenerarse.

## Trazabilidad y migración futura

El plan completo, con sus condiciones previas, fases y criterios de aceptación, está en
[plan-migracion-anotaciones.md](./plan-migracion-anotaciones.md). No se ejecutará hasta
que la ontología esté revisada, el editor V2 funcione como se espera y el demarcador
resulte útil.

## Documentos que debe consultar un nuevo chat

Leer solo lo necesario para la tarea:

1. [La ontología métrica](./ontologia-metrica.md): qué es cada entidad y por qué existe.
   Lectura previa a todo lo demás.
1bis. [README del dominio](./README.md): índice y decisiones consolidadas.
2. [Criterios de nivel](./criterios-de-nivel.md): en qué nivel se registra cada hecho
   métrico. De lectura obligada antes de formalizar o corregir una forma.
2bis. [Arquitectura técnica](./arquitectura-dominio-metrica.md): capas, proyecciones,
   integridad y permisos. No especifica tablas: para el esquema, volcar la base.
3. [Editor V2](./editor-secuencias-v2.md): aislamiento, persistencia y comportamiento.
4. [Contratos del registrador](./contratos-registrador-formas-revisadas.md): comportamiento
   mínimo de las formas revisadas.
5. [Cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md): única lista
   vigente de dudas.
6. La revisión específica de una forma, solo si la nueva tarea afecta a esa forma.

[El vocabulario heredado](./historico/vocabulario-heredado.md) conserva los 119 términos
anteriores con sus definiciones, rasgos, subtipos y destino actual. Es la referencia para
comprobar si se perdió información al migrar o si algo quedó en un nivel que no le toca. La
matriz de importación que lo revisaba en el panel se retiró: desde la importación las
decisiones han cambiado tanto que sus pendientes ya no describían nada actual.

La [matriz de reclasificación](./historico/matriz-reclasificacion-formas-metricas.md) y el
[informe de auditoría](./historico/informe-auditoria-vocabulario-metrico.md) explican la
procedencia, pero no deben releerse para una tarea ordinaria.

## Revisión del catálogo

El criterio de nivel está escrito en [criterios-de-nivel.md](./criterios-de-nivel.md) y
su cumplimiento se comprueba con `npm run audit:metrica`, que vuelca la base enlazada y
contrasta los datos poblados. El resultado vigente está en
[informe-conformidad-catalogo.md](./informe-conformidad-catalogo.md). El informe separa
los incumplimientos objetivos de las matrices que describen dónde vive cada dimensión;
estas últimas son el material de las decisiones pendientes del IP, no errores.

## Siguiente fase prevista

La ontología quedó revisada desde la base el 30 de julio de 2026. Queda por llevar esas
decisiones a la implementación:

1. Migración estructural: **completa**. Los cuatro bloques del
   [contrato de implementación](./contrato-implementacion.md) —renombrados, metro
   unificado, unidad explícita y limpieza— están aplicados, junto con la unidad envolvente
   que cerró el tercero.
2. Migración de datos: **completa**. Las tradiciones se poblaron desde `tipo_forma`;
   `patron_acentual` se retiró en el bloque B, y las familias, `tipo_relacion` y
   `es_principal` en el D.
3. Contrastar el catálogo por rasgos y no por nombres: el
   [contraste estructural](./contraste-estructural.md) reúne los vecindarios de formas, los
   cambios de nivel respecto del vocabulario heredado y las señales de que algo puede estar
   donde no le toca. Es material para el IP, y algunas de sus respuestas cierran defectos
   del informe.
4. Corregir los defectos del [informe de conformidad](./informe-conformidad-catalogo.md).
   Quedan 25 y **ninguno se puede corregir sin una decisión del IP**: el triaje, defecto por
   defecto, está en [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md).
4. Crear la capa de desviaciones sobre las secuencias reales.
5. Recompilar el demarcador para que consuma la ontología en lugar de su vector fijo de
   rasgos.
6. Solo entonces, la [migración de las anotaciones](./plan-migracion-anotaciones.md).
