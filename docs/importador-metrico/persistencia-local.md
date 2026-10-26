# Guardado mínimo: borrador SQL y ensayo local

26 de octubre de 2026. **No aplicado a Supabase ni conectado al dashboard.** El SQL permanece
fuera de `supabase/migrations/` para que un despliegue habitual no lo aplique por accidente.

La [consulta de persistencia](../../scripts/importador-metrico/auditar-persistencia.sql) y su
[evidencia](./piloto/auditoria-persistencia-2026-10-26.json) recogen columnas, restricciones,
políticas, permisos y disparadores mediante SELECT. Además se exportó el esquema público real,
sin sus datos, a `backups/importador-local/schema-2026-10-26.sql`, ignorado por Git. Ese esquema
se restauró para ejecutar las funciones nuevas con los disparadores existentes.

## Qué guarda el borrador

Los [tres archivos SQL](../../scripts/importador-metrico/sql/01-almacenamiento.sql) se ejecutan
en orden: almacenamiento, esquemas de documentos y operación de guardado.

- `obras.tipo_ficha`: `completa` por defecto; `minima` para lo importado. Ningún estado nuevo.
- `editores.puede_importar_metrica`: desactivado por defecto. Admin/IP mantienen su acceso;
  pueden conceder la capacidad a un editor mediante una función específica.
- `importaciones_metricas`: extracción original, datos confirmados, autor y género resueltos,
  persona de la sesión, fecha del servidor y selección del referente mínimo. La copia confirmada
  no se modifica; la marca de uso queda separada del contenido inmutable.
- `metrica_minima_secuencias`: forma revisada y arquitectura opcionales, referencia a la importación
  y al bloque original. Candidatas, propuestas, notas y desviaciones se conservan dentro del
  documento de ese bloque, sin generar respuestas v2.

`guardar_ficha_minima(p_peticion, p_autor, p_datos, p_entrada_original)` crea en una sola
transacción la obra, su autoría tradicional individual, jornadas, secuencias, métrica mínima e
importación. No exige fundamentos textuales ni editor asignado. Selecciona género y categorías
del vocabulario, comprueba el autor seleccionado y los destinos métricos contra el catálogo.
Los nombres del documento deben coincidir con el autor elegido; todavía falta la interfaz de
reconocimiento y selección de autores. La numeración de jornadas y segmentos debe ser continua,
y cada segmento debe caber en una jornada y corresponder a su fila de origen.

La misma persona y clave de petición devuelven la misma importación al repetir el envío. Si
cambia su contenido, se rechaza. Dos sesiones concurrentes con esa clave crean una sola obra.
Otra clave con el mismo título y autor se bloquea para revisar la coincidencia. Esto no detecta
variantes de título, autorías alternativas ni obras anteriores sin atribución: esa detección y la
reimportación siguen pendientes. La operación actual solo crea obras nuevas.

El documento de extracción sigue siendo el original `borrador_ia`, aunque su transcripción se haya
aceptado después. La confirmación de guardado se registra aparte y no cambia propuestas métricas
en identificaciones revisadas. Se comprueban ambos formatos mediante `pg_jsonschema`, extensión
disponible pero todavía no instalada en el Supabase compartido. Los esquemas SQL se generan desde
los mismos contratos Zod mediante [generar-esquema-sql.mjs](../../scripts/importador-metrico/generar-esquema-sql.mjs).

La columna `sha256_jsonb` usa el texto que PostgreSQL produce al serializar el JSONB. **No es**
el `sha256_datos` canónico del contrato local ni el hash de los bytes del archivo original.
Sirve para comprobar la copia guardada; la idempotencia compara también el contenido JSONB.
Los hashes de procedencia se conservan, pero la DB no certifica archivos que no ha recibido.
El futuro endpoint deberá verificar las entradas y la referencia al catálogo vigente.

## Acceso que se ha probado

Las tablas nuevas solo conceden SELECT a usuarios autorizados; la escritura pasa por la función.
Un importador ve todas las importaciones, propias y ajenas. El editor asignado consulta la de su
obra aunque no pueda importar. No se añade acceso al laboratorio ni permiso para editar estructuras
ajenas. Una mínima no puede pasar a Publicado ni activar su visibilidad pública.

Las políticas existentes de obras permiten lecturas amplias y se combinan con OR. El borrador
añade un límite **restrictivo**, que sí se combina con AND, para las mínimas. Jornadas y secuencias
tienen el mismo límite, incluido el antiguo rol revisor. No se retiran políticas anteriores de las
completas. Esto no constituye aún una auditoría de todas las funciones SECURITY DEFINER ni de los
consumidores que usan credenciales de servicio: su adaptación sigue siendo necesaria antes de
desplegar el importador.

## Ensayo reproducible

Se utilizó PostgreSQL 17.6 en un contenedor sin red ni puertos publicados. La prueba crea una DB
temporal, restaura el esquema exportado e instala el borrador dos veces. Usa sesiones y editores
sintéticos, un autor de prueba y referencias del catálogo conservado en el piloto; no descarga
obras, personas ni anotaciones del equipo. `auth.uid()` se simula mediante el identificador de
sesión: se ejercitan los roles PostgreSQL, las RLS y las funciones, no la autenticación HTTP/JWT.
Al terminar, incluso si falla, elimina únicamente la DB temporal que ha creado.

```powershell
node scripts/importador-metrico/generar-esquema-sql.mjs --comprobar
node scripts/importador-metrico/probar-persistencia-local.mjs --esquema backups/importador-local/schema-2026-10-26.sql
```

El segundo comando requiere un contenedor `versologia-importador-pruebas` con la imagen
`public.ecr.aws/supabase/postgres:17.6.1.063`, iniciado sin red ni puertos y con PostgreSQL disponible.
Puede iniciarse con:

```powershell
docker run --detach --name versologia-importador-pruebas --network none --env POSTGRES_PASSWORD=prueba_local_importador --env PGPASSWORD=prueba_local_importador public.ecr.aws/supabase/postgres:17.6.1.063
```

Hay que esperar a que el contenedor esté saludable antes de ejecutar la prueba.
La contraseña local de ensayo no es una credencial de Supabase. El script no acepta una URL de DB,
no importa clientes remotos ni ejecuta `db push`. El volcado se obtiene aparte mediante el comando
de solo lectura documentado en el README del repositorio. No es una copia completa de seguridad.

Resultado: **49 comprobaciones correctas**, incluidas cuatro obras, 12 jornadas, 78 segmentos y
11.754 posiciones numeradas; 237 posiciones con forma revisada (Canción y Terceto encadenado),
sin arquitectura; rechazo de un supuesto remate de cuatro versos donde el catálogo admite uno;
ninguna anotación v2 fabricada; guardado
atómico con fallo de catálogo tardío; idempotencia y concurrencia; permisos de lectura compartida;
laboratorio cerrado a importadores; copia inmutable e independiente del borrado de estructura.

El 26 de octubre se repitió el ensayo tras revisar «tercetos encadenados con serventesio final».
La comprobación de detalles revisados aplica también `versos_min` y `versos_max` de la sección
del catálogo, tanto en JavaScript como en el borrador SQL. «Serventesio final» permanece como
literal; el dato aceptado es remate final de un verso dentro del Terceto encadenado (3+1).

## Límite de este bloque

La marca `usada_en_corpus` selecciona una copia mínima, pero los cálculos actuales todavía no la
consumen. Tampoco existe la sustitución al publicar la completa, la elección editorial entre
conservar y vaciar estructura, la reimportación ni la vista Fichas mínimas. No se debe aplicar
este borrador como si esos flujos estuvieran resueltos. Las migraciones definitivas deberán
acompañarse de lectores, permisos de servidor, adaptación de los consumidores y copias de seguridad
según las reglas del repositorio. El diseño de esos flujos ya está acordado en
[campos mínimos y conexiones](./campos-minimos.md); el trabajo restante está en
[PENDIENTES](../PENDIENTES.md).
