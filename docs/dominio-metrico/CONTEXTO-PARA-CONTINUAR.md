# Contexto para continuar el trabajo métrico

Actualizado: 1 de agosto de 2026

Este es el documento que debe leer primero un nuevo chat. Resume el estado operativo y
enlaza la documentación detallada; no sustituye las revisiones filológicas de cada forma.

## Estado actual

- Rama de trabajo: `develop`. `main` corresponde a la versión desplegada y debe
  permanecer estable hasta decidir la integración.
- `develop` y producción comparten Supabase. No se ha creado ni hace falta otro proyecto.
- El catálogo nuevo usa tablas aditivas y está separado del vocabulario métrico legado.
- La versión requerida del modelo es `54`.
- La última migración es `20260801150000_estrofas_basicas_y_reutilizacion.sql` y está aplicada.
  La base habla ya el vocabulario de la ontología: arquitectura, esquema métrico, esquema
  de rima, variedad, tramo sin forma, grado de especificación. La arquitectura declara
  además la extensión de su unidad —`unidad_versos_min` y `unidad_versos_max`—, y ninguna
  sección existe ya para decir que la unidad se repite: cuántas unidades contiene el pasaje
  se deriva del rango. La unidad es la realización que no cuelga de ninguna otra y no
  realiza ninguna sección; las secciones describen su interior. No existen familias, la
  pertenencia a una tradición no se tipifica y las denominaciones pueden nombrar una
  variedad y declararse posteriores. Arquitecturas y esquemas siguen una misma convención de
  nombre y slug, registrada en
  [la revisión de nomenclatura](./historico/revision-nomenclatura.md). El catálogo tiene **27 formas y
  2 tramos sin forma**: la medida de toda forma isosilábica es arquitectura y ya no se
  pregunta, y lo que era una forma para decir «N unidades de esta otra» —doble sextilla,
  sexta rima, tercetos sin encadenar, pareados endecasílabos, copla manriqueña— vive en el
  nivel que le corresponde. Las formas con clasificación previa tienen ya su tradición; las
  restantes no la tienen porque no hay de dónde tomarla.
- `/dashboard/metrica` es el gestor permanente del catálogo y contiene también el editor
  V2 de prueba y la compilación del demarcador.
- **El catálogo de formas se publica en `/formas`** desde el 4 de agosto de 2026, generado
  del dato: cada forma con sus arquitecturas, esquemas, secciones, rasgos, denominaciones y
  lo que dicen las fuentes. Nace en `admin_ip` y se abre desde `/dashboard/publicacion`
  cambiando el `scope_minimo` de la sección `formas`. No lleva texto redactado: si algo se
  lee mal, está mal en el catálogo.
- El editor V2 escribe únicamente en tablas `*_editor_metrico`. No crea obras, no modifica
  las secuencias reales y no alimenta fichas, buscadores ni resúmenes públicos.
- **La anotación en sombra funciona** desde el 4 de agosto de 2026, en la pestaña
  «Anotación en sombra» de `/dashboard/metrica`. Una prueba puede señalar una secuencia real
  con `secuencias_editor_metrico.secuencia_id`, sin que la secuencia cambie nada:
  `obras_editor_metrico_v2` dice qué obras están abiertas, la vista
  `propuesta_metrica_secuencia` traduce cada `estrofa_tipo_id` a su forma y arquitectura
  —94,9 % de cobertura medida— y el formulario llega propuesto desde ahí, de modo que el
  editor revisa en vez de reanotar. El recuento de acuerdo entre modelos está en la misma
  pestaña; para ver una obra en los dos modelos se abre el editor de siempre en otra
  pestaña, no hay pantalla doble. Es la fase 0 de
  [el plan de migración](./plan-migracion-anotaciones.md).
  **Nada de esto se ha visto todavía en pantalla con datos reales.**
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

- El contrato vigente, la matemática de compatibilidad y el criterio de parada están en
  [Demarcador métrico](./demarcador-metrico.md).
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

1. [Ontología del verso español](./ontologia-verso-espanol.md): qué es el verso español y
   de qué está hecho. Describe posibilidades, no este corpus. Lectura previa a todo lo demás.
1bis. [La implementación de METADRAMA](./implementacion-metrica.md): qué parte se realiza,
   qué se restringe por el corpus y cómo se recoge el dato.
1ter. [README del dominio](./README.md): índice y decisiones consolidadas.
2. [Criterios de nivel](./criterios-de-nivel.md): en qué nivel se registra cada hecho
   métrico. De lectura obligada antes de formalizar o corregir una forma.
2bis. [Arquitectura técnica](./arquitectura-dominio-metrica.md): capas, proyecciones,
   integridad y permisos. No especifica tablas: para el esquema, volcar la base.
3. [Editor V2](./editor-secuencias-v2.md): aislamiento, persistencia y comportamiento.
4. [Contratos del registrador](./contratos-registrador-formas-revisadas.md): comportamiento
   mínimo de las formas revisadas.
5. [Cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md): única lista
   vigente de dudas filológicas.
5bis. [Equivalencias pendientes](./equivalencias-pendientes.md): los términos legados que
   todavía no declaran su destino en el catálogo. Es lo que hay que cerrar antes del backfill.
5bis-2. [Dónde vive la prosa del catálogo](./donde-vive-la-prosa.md): definición, descripción
   y nota son tres sitios para lo mismo. Anotado para auditar cuando se sumen las fuentes que
   faltan; hasta entonces no se toca.
5ter. [Cómo se migra una obra](./como-se-migra-una-obra.md): el procedimiento, escrito para
   poder explicárselo a quien anotó cada obra. Los informes por obra se generan con
   `npm run migracion:informe` y viven en [migracion/](./migracion/).
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

1. Migración estructural y de datos: **completas**. Sus cuatro bloques y la unidad
   envolvente están aplicados; el registro de qué se cambió y por qué está en
   [histórico](./historico/).
2. Vocabulario unificado: **completo**. Una escala de modalidad, un tipo de secuencia, el
   ámbito reducido a unidad y sección.
3. Contraste del catálogo por rasgos y no por nombres: **hecho**, y actuado. Lo que salió de
   ahí está en la [auditoría](./auditoria-catalogo.md), con lo aplicado marcado.
4. ~~Corregir los defectos del informe de conformidad.~~ **El
   [informe](./informe-conformidad-catalogo.md) no señala ninguno.** Lo que queda en
   [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md) son precisiones
   filológicas que el catálogo puede esperar sin quedar mal formado.
5. Crear la capa de desviaciones sobre las secuencias reales.
6. Recompilar el demarcador para que consuma la ontología en lugar de su vector fijo de
   rasgos.
7. Solo entonces, la [migración de las anotaciones](./plan-migracion-anotaciones.md).
