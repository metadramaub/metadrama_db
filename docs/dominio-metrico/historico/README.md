# Histórico del dominio métrico

**Nada de esta carpeta describe el estado actual.** Son documentos del proceso que se
conservan por su razonamiento y su trazabilidad: explican por qué el modelo es como es y qué
había antes. Sus cifras, sus listas y sus «pendiente de hacer» son del día en que se
escribieron.

Para el estado vigente: [el contexto](../CONTEXTO-PARA-CONTINUAR.md), el
[índice del dominio](../README.md) y `npm run audit:metrica`.

## Qué hay aquí

### La revisión del catálogo, ya cerrada

Terminó el 21 de agosto de 2026 y estos cuatro documentos se archivaron ese día.

| Documento | Qué conserva |
| --- | --- |
| [revision-del-catalogo-2026-07-a-08.md](./revision-del-catalogo-2026-07-a-08.md) | El diario del contraste de las 28 fichas con las seis monografías, y sobre todo **qué cambió en el modelo por el camino**, cambio a cambio. Es la trazabilidad de esa fase |
| [cuestiones-por-forma-2026-08.md](./cuestiones-por-forma-2026-08.md) | Forma por forma, **el pasaje de la fuente y el razonamiento** con que se decidió cada cosa. Sus estados son del día en que se escribieron: lo que sigue abierto está en el contexto |
| [decisiones-de-modelo-por-forma-2026-08.md](./decisiones-de-modelo-por-forma-2026-08.md) | Andamiaje que se escribió para vaciarse: los porqués de cada forma antes de mudarse al catálogo. Lo vigente se lee en `/formas` |
| [poda-de-la-prosa.md](./poda-de-la-prosa.md) | La propuesta frase a frase de qué prosa dejó de aportar cuando la ficha empezó a dibujar la estructura. Cerrada en 0 de 191. Regenerable con `npm run poda:informe` |

### El editor V2 y el registro

| Documento | Qué conserva |
| --- | --- |
| [propuesta-editor-v2-2026-08-11.md](./propuesta-editor-v2-2026-08-11.md) | El diagnóstico que motivó la pantalla nueva: **por qué el formulario es como es** |
| [editor-secuencias-v2-2026-08-11.md](./editor-secuencias-v2-2026-08-11.md) | Cómo quedó el primer corte: grupos de elección, escenarios aislados y contrato de la interfaz |
| [que-guarda-el-registro-2026-08-01.md](./que-guarda-el-registro-2026-08-01.md) | Tres secuencias inventadas, fila a fila. **Su método vale; sus nombres de tabla ya no existen** |
| [informe-editor-v2-2026-08-10.md](./informe-editor-v2-2026-08-10.md) | Qué le pedía el editor a cada forma el 10 de agosto. Se regenera al día con `node scripts/audit-editor-v2.mjs` |
| [catalogo-publico-2026-08-12.md](./catalogo-publico-2026-08-12.md) | El razonamiento del día en que se rehízo la ficha pública dimensión a dimensión |

### El vocabulario legado y su reclasificación

| Documento | Qué conserva |
| --- | --- |
| [vocabulario-heredado.md](./vocabulario-heredado.md) | Los 119 términos anteriores con sus definiciones, rasgos, subtipos y destino. **Es la referencia para comprobar si se perdió algo al migrar** |
| [matriz-reclasificacion-formas-metricas.md](./matriz-reclasificacion-formas-metricas.md) | Entrada por entrada, en qué se convirtió cada uno de los 119 términos |
| [informe-auditoria-vocabulario-metrico.md](./informe-auditoria-vocabulario-metrico.md) | El diagnóstico que motivó todo: qué estaba mal en la jerarquía de padres e hijos |
| [contraste-estructural.md](./contraste-estructural.md) | Comparación del modelo viejo con el nuevo, estructura a estructura |

### El diseño del modelo

| Documento | Qué conserva |
| --- | --- |
| [propuesta-dominio-metrica.md](./propuesta-dominio-metrica.md) | La propuesta conceptual inicial |
| [especificacion-tablas-2026-07-28.md](./especificacion-tablas-2026-07-28.md) | Una especificación de columnas que quedó desfasada en dos días. **Se archivó por eso**: la fuente de verdad del esquema es la base |
| [contrato-implementacion.md](./contrato-implementacion.md) | Qué había que cambiar antes de tocar datos. Aplicado y cerrado |
| [ejemplos-formalizacion-ontologia-metrica.md](./ejemplos-formalizacion-ontologia-metrica.md) | Formas formalizadas a mano para probar si la ontología aguantaba |
| [revision-nomenclatura.md](./revision-nomenclatura.md) | La convención de nombres y slugs: adjetivo en `-ico`, minúsculas sin tildes, el nombre no repite el de la forma. **La convención sigue vigente**; lo archivado es el registro de cómo se aplicó |

### La revisión del catálogo

| Documento | Qué conserva |
| --- | --- |
| [auditoria-catalogo.md](./auditoria-catalogo.md) | Once defectos de coherencia entre implementación y ontología, **todos resueltos**. Vale por el razonamiento: por qué el mismo hecho no puede vivir en dos niveles, por qué `aabaa` no es una quintilla |
| [plan-revision-del-catalogo.md](./plan-revision-del-catalogo.md) | El diario de la fase A: la normalización de nombres y la corrección de la caja de la rima, con las once posiciones que estaban al revés. Y por qué el orden fue A → B/C → D |
