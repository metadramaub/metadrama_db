# Aislamiento del primer guardado básico

29 de octubre de 2026. Código y borrador SQL probados en local. **No aplicado a Supabase compartido.**

Esta revisión cubre guardar, consultar y mantener separada una básica antes del productor combinado.
No activa su aportación analítica ni cambia los criterios del inventario general de medidas.

## Lectores y operaciones revisados

| Punto | Tratamiento de la básica en esta entrega |
| --- | --- |
| Vista previa y confirmación | Requieren capacidad de sesión; reconstrucción en servidor y nueva comprobación de coincidencias. La DB vuelve a validar datos, permiso e idempotencia |
| Fichas básicas | Todos los importadores ven todas; el editor asignado puede consultar la copia de su obra. Se muestran responsable y fecha |
| Listado normal de Obras | Solo detalladas; enlace separado a Fichas básicas |
| Contadores del inicio y Continuar edición | Solo detalladas, incluso si una básica tiene editor asignado |
| Cambios de estado y asignaciones en avisos | Las consultas de obras y sus contadores excluyen básicas. Una importación no aparece como una nueva ficha detallada pendiente |
| Gestión de editores y reparto | El inventario y los recuentos de encargos usan detalladas. La RPC de reparto rechaza básicas hasta disponer del paso explícito de elaboración |
| Editor detallado y API editorial | Las capacidades rechazan escritura, revisión y publicación de básicas. Abrir una básica permitida desde la ruta de obra conduce a su copia importada |
| Escritura SQL de obras, jornadas, cuadros y secuencias | Políticas restrictivas de INSERT/UPDATE/DELETE limitadas a detalladas. La función del importador puede crear su estructura inicial |
| Guardado v2 por RPC | `auth_puede_editar_obra` requiere detallada. Un trigger impide además insertar anotaciones v2 en básicas con las políticas generales de administración |
| Consulta SQL `formas_de_la_obra` | El lector v2 excluye básicas, aunque se invoque directamente y con privilegios. No devuelve sus rangos por la RPC pública |
| `perfil_metrico_unidades` | Mantiene unidades de autoría por obra o jornada, pero excluye básicas del productor detallado existente |
| Productores de resumen y artefacto por obra | Rechazan básicas antes de calcularlas como detalladas. No se escriben ceros editoriales ni artefactos de ficha básica con el productor antiguo |
| Constructores internos de ficha pública y análisis | Los constructores por obra incorporan el mismo límite. No basta con proteger la RPC exterior, porque el constructor también puede invocarse con privilegios |
| RPC exterior de ficha pública y comentarios | Conserva su filtro editorial de estado/visibilidad; una básica permanece en borrador técnico y devuelve ficha nula incluso con `include_hidden` |
| Artefactos e índices públicos existentes | Conservan sus lectores y permisos. Los índices parten de publicadas; las básicas no se publican. El importador no obtiene acceso a `corpus_comparativas` |
| Credencial de servicio en la aplicación | Su uso permanece en gestión de cuentas editoriales. El importador utiliza la sesión, no una credencial administrativa para saltarse sus permisos |

El límite de escritura de esta primera entrega es deliberado: asignar y empezar a elaborar una
detallada sobre una básica requiere el recorrido explícito acordado (conservar/corregir o vaciar
estructura, sin retirar aún la copia básica). No se habilita ese recorrido cambiando una columna.
No se reemplaza la normativa de acceso de las detalladas existentes.

## Pruebas ejecutadas

- **89 comprobaciones PostgreSQL:** esquema público exportado el 29 de octubre, datos sintéticos,
  instalación del borrador dos veces, RLS con roles reales, escrituras directas, RPC v2, reparto,
  constructores internos privilegiados, publicación, copia fija, homónimos e idempotencia concurrente.
- **25 comprobaciones HTTP con Supabase Auth local real:** contraseña → sesión y JWT → PostgREST →
  RPC/RLS. Siete perfiles sintéticos; admin/IP, importadores, editor sin capacidad e inactivo. Incluye
  retirar la capacidad mientras sigue vigente un JWT y restaurarla al finalizar.
- **Navegador:** acceso global con el `.env` habitual; inicio de sesión de importador sintético;
  carga de El molino; corrección de fecha final a 1592; comprobación, confirmación, recarga y consulta
  de la copia con 2992 versos, 21 secuencias y 3 jornadas. El dato original de la edición no cambia.
  Listado con responsable de las dos importaciones. Editor sin permiso: enlace ausente y ruta
  directa 403. Administración: básicas separadas del listado y de sus contadores editoriales.
- Pruebas de código: normalización y edición de vista previa, permisos, acciones de formulario,
  persistencia y contadores editoriales. El resultado se registra en el documento de persistencia.

Las pruebas usan el catálogo y las extracciones del piloto. No son una validación filológica de
nuevas equivalencias ni el experimento de incertidumbre para el artículo.

## Reproducir Auth y la web local

Se utiliza un proyecto de Supabase **independiente**, `versologia_importador_auth`, dentro de
`backups/importador-auth/`, ignorado por Git. API `127.0.0.1:55421`, DB `55422`, web `5190`.
No se copian los datos editoriales del equipo ni sus usuarios. El esquema se exporta aparte.

1. Copiar `supabase/config.toml` a `backups/importador-auth/supabase/config.toml`; cambiar
   `project_id` al nombre anterior, puertos `5432x` por `5542x` y `db.seed.sql_paths` a `[]`.
   No copiar migraciones, seeds, `.env` ni el enlace al proyecto remoto.
2. Arrancar los servicios locales desde ese directorio:

```powershell
npx supabase start --workdir backups/importador-auth --exclude edge-runtime,imgproxy,logflare,mailpit,postgres-meta,realtime,storage-api,studio,supavisor,vector --yes
npx supabase status --workdir backups/importador-auth --output json | Set-Content -Encoding utf8 backups/importador-auth/status.json
node scripts/importador-metrico/preparar-auth-local.mjs --esquema backups/prosa-correccion/public-schema.sql
node scripts/importador-metrico/probar-auth-local.mjs
node scripts/importador-metrico/iniciar-web-local.mjs
```

La preparación exige una DB sin tabla `obras` y verifica el proyecto del contenedor; no vacía ni
sobrescribe ensayos previos. Las herramientas HTTP y de arranque rechazan otra URL distinta del
loopback acordado. Credenciales aleatorias de las cuentas sintéticas en `backups/importador-auth/cuentas.json`;
no se imprimen ni se incluyen en Git. Las cuentas habituales no funcionan en la copia de prueba.
La contraseña global de la web se toma del `.env` habitual; el lanzador solo reemplaza la conexión
y las claves de Supabase por las locales, sin modificar el archivo ni otro servidor Vite.

Para detener esta copia conservando sus volúmenes: `npx supabase stop --workdir backups/importador-auth`.
El ensayo PostgreSQL sin Auth sigue usando su contenedor aislado sin red ni puertos.

## Antes de promover a la base compartida

La [propuesta de despliegue](./promocion-guardado.md) ya reúne candidata única, contraste del
esquema reciente, ensayo con los datos actuales y recuperaciones verificadas. Su aplicación sigue
pendiente de aprobación. Los pasos operativos previstos son los siguientes:

1. Exportar otra vez el esquema y contrastar las funciones y permisos con los probados, por si
   hubo cambios mientras se desarrolla la web. Las adaptaciones SQL fallan si cambian sus anclas;
   no se debe silenciar ese fallo.
2. Preparar una migración única transaccional a partir de los cinco borradores, con sus contratos
   generados, y ensayarla sobre ese esquema reciente. Resolver explícitamente el orden respecto a
   la migración de prosa pendiente: el importador no debe publicar ni aplicar esa corrección por accidente.
3. Presentar migración, alcance, pruebas y recuperación al responsable. Aún no hay un archivo de
   migración del importador que pueda entrar por un `db push` habitual.
4. Tras aprobación, copia completa y snapshot de obras según README/CLAUDE; aplicar solo lo
   aprobado y verificar con una importación real acordada, sin cargar las cuentas de ensayo.

La incorporación a análisis es otro bloque: productor común, selección de una fuente por obra,
documentos y permisos por consumidor, denominadores/cobertura, invalidación y sustitución al
publicar la detallada. Las funciones detalladas aisladas aquí no se convertirán en el productor
mixto añadiendo silenciosamente básicas a sus consultas. Se mantiene el
[plan de consultas y precomputación](./consultas-y-precomputacion.md).
