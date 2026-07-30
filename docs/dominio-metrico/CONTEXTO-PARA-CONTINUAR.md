# Contexto para continuar el trabajo métrico

Actualizado: 30 de julio de 2026

Este es el documento que debe leer primero un nuevo chat. Resume el estado operativo y
enlaza la documentación detallada; no sustituye las revisiones filológicas de cada forma.

## Estado actual

- Rama de trabajo: `develop`. `main` corresponde a la versión desplegada y debe
  permanecer estable hasta decidir la integración.
- `develop` y producción comparten Supabase. No se ha creado ni hace falta otro proyecto.
- El catálogo nuevo usa tablas aditivas y está separado del vocabulario métrico legado.
- La versión requerida del modelo es `42`.
- La última migración es
  `20260730107000_salidas_editoriales_irregular_verso_aislado.sql` y está aplicada.
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
2. Forma, familia, tradición, configuración, patrón, rasgo, denominación y relación son
   conceptos distintos. La antigua jerarquía padre/hijo no se reproduce automáticamente.
3. El criterio especializado incorporado por el IP para el corpus se conserva. La
   bibliografía académica documenta contrastes, pero no lo sustituye silenciosamente.
4. Las fuentes declaradas deben ser publicaciones bibliográficas autorizadas; una página
   web o un vídeo no constituyen por sí solos una fuente del catálogo.
5. Una configuración prototípica es opcional. Un cambio de identidad estructural puede
   crear otra forma; una alternativa coherente de la misma arquitectura es configuración,
   patrón, sección, repetición o rasgo según su nivel.
6. El editor debe responder lo mínimo. Los resultados únicos se derivan; solo se muestran
   alternativas con valor analítico y desviaciones reales.
7. Rige una convención de mundo cerrado: una secuencia guardada sin desviaciones cumple
   la norma y las elecciones realizadas. No se piden certeza, revisión ni pendiente.
8. Las alternativas admitidas no son desviaciones. Las desviaciones reutilizan metros,
   rimas, estructuras, repeticiones y rasgos normalizados.
9. Las formas reconocibles conservan su identidad aunque tengan excepciones localizadas.
   `Versificación irregular` y `Verso aislado` son salidas editoriales sin configuración,
   no formas comparables.
10. Una forma estructurada puede ser residual sin dejar de ser forma. La copla de pie
    quebrado residual no pertenece al mismo nivel ontológico que las dos salidas
    editoriales.
11. Las restricciones de longitud obligan a revisar rangos incompatibles: múltiplos de la
    unidad fija, ciclos repetibles, composiciones cerradas y estructuras calculadas.

## Cómo se registra una secuencia

```text
forma
+ configuración normativa
+ elecciones entre alternativas admitidas
+ unidades o secciones realizadas, cuando proceda
+ desviaciones localizadas
```

Si no existe una forma reconocible:

```text
salida editorial
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
- Las salidas residuales no compiten en el recorrido ordinario y aparecen únicamente
  cuando no queda una identificación más precisa.
- Si cambia el catálogo, la interfaz marca la prueba compilada como desactualizada y debe
  regenerarse.

## Trazabilidad y migración futura

- Cada término legado tiene una clasificación y uno o varios destinos documentados.
- Los UUID de origen se conservan cuando permiten una migración exacta.
- Los términos ambiguos no se asignarán por conjetura. Por ejemplo, la antigua raíz
  `romancillo` exige conocer si la secuencia es hexasílaba o heptasílaba.
- Los subtipos residuales de irregular por arte se fusionarán con Versificación irregular,
  conservando su información como observación o derivándola de las medidas disponibles.
- Antes de migrar las secuencias reales habrá que crear una auditoría de correspondencias,
  respaldar los datos y resolver explícitamente cada caso ambiguo.

## Documentos que debe consultar un nuevo chat

Leer solo lo necesario para la tarea:

1. [README del dominio](./README.md): índice y decisiones consolidadas.
2. [Arquitectura](./arquitectura-dominio-metrica.md): esquema relacional y reglas.
3. [Editor V2](./editor-secuencias-v2.md): aislamiento, persistencia y comportamiento.
4. [Contratos del registrador](./contratos-registrador-formas-revisadas.md): comportamiento
   mínimo de las formas revisadas.
5. [Cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md): única lista
   vigente de dudas.
6. La revisión específica de una forma, solo si la nueva tarea afecta a esa forma.

La [matriz de reclasificación](./matriz-reclasificacion-formas-metricas.md) y el
[informe de auditoría](./informe-auditoria-vocabulario-metrico.md) explican la
procedencia, pero no deben releerse para una tarea ordinaria.

## Siguiente fase prevista

1. El IP revisa nombres, definiciones, configuraciones y cuestiones pendientes desde el
   propio dashboard.
2. Se corrigen el catálogo y los contratos sin tocar todavía las secuencias reales.
3. Se recompila y valida el demarcador.
4. Cuando el catálogo esté aprobado y se coordine el trabajo editorial, se diseña y
   ejecuta la migración de las declaraciones existentes.
