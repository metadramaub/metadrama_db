# Histórico del dominio métrico

**Nada de esta carpeta describe el estado actual.** Son documentos del proceso que se
conservan por su razonamiento y su trazabilidad: explican por qué el modelo es como es y qué
había antes. Sus cifras, sus listas y sus «pendiente de hacer» son del día en que se
escribieron.

Para el estado vigente: [el contexto](../CONTEXTO-PARA-CONTINUAR.md), el
[estado de la revisión](../revision-del-catalogo-estado.md) y `npm run audit:metrica`.

## Qué hay aquí

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
