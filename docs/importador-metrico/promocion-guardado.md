# Propuesta de despliegue del guardado básico

29 de octubre de 2026. **Preparada y ensayada en local; no aplicada a Supabase.**

## Resultado propuesto

Habilitar confirmar importaciones nuevas y consultar sus copias fijas. Admin/IP pueden importar;
los demás editores necesitan el permiso individual. Se mantienen las protecciones de fichas
detalladas y básicas ya descritas en la [auditoría de aislamiento](./auditoria-aislamiento.md).
Las básicas guardadas **todavía no aportarán datos a los análisis**: falta el productor combinado.

La [candidata SQL única](../../scripts/importador-metrico/promocion/importador-basico.sql) está
fuera de `supabase/migrations/`. Un despliegue habitual de la web no debe instalarla por accidente.
El [compilador](../../scripts/importador-metrico/compilar-promocion.mjs) reúne exactamente los cinco
SQL revisados en una sola transacción, sin sus COMMIT intermedios. No incluye la corrección de
prosa, datos del piloto, usuarios de prueba, importaciones ni un recálculo automático.

Cambios de esquema: dos columnas (`obras.tipo_ficha`, `editores.puede_importar_metrica`), dos tablas
de importación/métrica básica, extensión `pg_jsonschema`, funciones, políticas e índices de soporte
y los límites de aislamiento. Las obras existentes quedan como detalladas y los permisos
individuales nuevos empiezan desactivados. No se alteran sus anotaciones métricas.

El límite de espera de bloqueos es cinco segundos y el de ejecución de la candidata dos minutos.
Si falla una instrucción, también se revierten extensión, columnas, permisos y funciones. El aviso
de recarga a PostgREST se confirma al final, junto con el resto de la transacción.

## Contraste con la base actual

Se exportaron esquema y datos públicos recientes a `backups/importador-promocion-20261029/`,
ignorado por Git. El esquema coincide con el usado en el ensayo anterior. La base compartida no
tiene las columnas del importador ni `pg_jsonschema` instalado. La migración de prosa tampoco
figura como aplicada.

La copia de ensayo contiene **145 obras y 57 tablas originales**. Se restaura exclusivamente en
el contenedor sin red ni puertos `versologia-importador-pruebas`, con un esquema Auth mínimo y UUID
de soporte de claves foráneas; no se sirven esos datos mediante la web local de pruebas. La copia
de Supabase Auth del puerto 5190 sigue siendo sintética y distinta de este ensayo.

Estas exportaciones de ensayo no sustituyen la copia completa de seguridad previa al despliegue:
faltan los demás esquemas y roles. Esa copia se hará después de aprobar el despliegue y justo
antes de ejecutarlo, según README/CLAUDE, además del snapshot legible de obras.

## Pruebas de la candidata

El [ensayo reproducible](../../scripts/importador-metrico/ensayar-promocion.mjs) comprueba dos
escenarios: la base actual y la base con la corrección de prosa aplicada antes. En cada uno:

- Verifica las **163 claves foráneas** de la copia, después de restaurar el volcado con referencias
  circulares. No utiliza una copia con referencias rotas como evidencia.
- Compara recuentos y huellas de todas las filas de las 57 tablas. Excluye del cotejo únicamente
  las dos columnas nuevas, cuyos valores iniciales se comprueban aparte. Incluye anotaciones,
  metadatos y artefactos ya guardados.
- Compara las salidas de formas, unidades de autoría por obra/jornada, análisis y ficha base para
  las obras existentes. Compara también un recálculo completo antes/después, dentro de transacciones
  que revierten sus escrituras.
- Fuerza un error al final de la candidata y comprueba la reversión total del esquema y los datos.
- Aplica la candidata, la repite y comprueba que el segundo envío no modifica el esquema.
- Prueba pausar y reanudar nuevas confirmaciones, sin modificar ni borrar datos.
- Genera y ejecuta la recuperación previa a la primera importación. Comprueba funciones y sus
  permisos, políticas, columnas, restricciones, índices, triggers, datos y salidas restaurados.
- Comprueba que la recuperación rechaza ejecutarse si ya hay una importación.

Además, las **89 comprobaciones PostgreSQL del importador** se han ejecutado usando esta candidata
única y el esquema recién exportado: incluyen guardado, permisos, copia fija, concurrencia,
coincidencias y escrituras directas. No solo se ha probado concatenar los archivos.

El [informe de resultado](./piloto/ensayo-promocion-2026-10-29.json) registra las huellas del esquema,
datos, candidata y recuperaciones, sin incluir las anotaciones ni las identidades del equipo.
La huella de la candidata corresponde al SQL generado con finales de línea LF.

```powershell
node scripts/importador-metrico/generar-esquema-sql.mjs --comprobar
node scripts/importador-metrico/compilar-promocion.mjs --comprobar
node scripts/importador-metrico/probar-persistencia-local.mjs --esquema backups/importador-promocion-20261029/schema.sql --migracion scripts/importador-metrico/promocion/importador-basico.sql
node scripts/importador-metrico/ensayar-promocion.mjs --copia backups/importador-promocion-20261029
```

## Orden y aprobación

**Propuesta: corrección de prosa primero; importador después, como dos cambios separados.**
La candidata del importador funciona sobre ambos estados ensayados, pero la migración pendiente
de prosa redefine dos de sus constructores. Aplicarla después podría retirar esos límites.
Por eso no se propone instalar el importador y dejar que un `db push` posterior aplique aquella
migración antigua sin revisar el orden. La corrección de prosa conserva su archivo y su aprobación
independientes: preparar este paquete no la autoriza ni la aplica.

Secuencia prevista, una vez aprobado el alcance y el orden:

1. Contrastar otra vez las funciones/esquema si ha pasado tiempo o hubo otros cambios. Repetir el
   ensayo si cambió el esquema afectado. Elegir la recuperación correspondiente al estado previo.
2. Copia completa de esquema, datos y roles, y `snapshot:obras`; comprobar que los archivos no están
   vacíos. Conservar los ficheros de recuperación y sus huellas junto a esa copia.
3. Aplicar la prosa si está aprobada y aún pendiente; verificar su contrato v3 por separado.
4. Promover la candidata del importador a una migración con versión posterior, manteniendo el SQL
   ensayado. Aplicar solo las migraciones aprobadas y registrar su ejecución. No usar un `db push`
   genérico sin revisar todas las pendientes.
5. Recargar/verificar RPC y permisos; ejecutar el recálculo habitual de las detalladas, conforme a
   CLAUDE. El importador no cambia el universo analítico ni introduce básicas en esos productores.
6. Primera importación real controlada y acordada: comprobar autor, coincidencias, fechas y métrica;
   guardar una vez, reintentar y volver a abrir. Verificar que no aparece como ficha pública ni
   como ficha detallada pendiente. No cargar las cuentas ni las obras sintéticas del ensayo.

## Recuperación

**Si la candidata falla durante su ejecución:** la transacción se revierte. No se restaura toda
la base ni se vuelve a cargar el volcado. Corregir la causa y volver a comprobar antes de reintentar.

**Si ha confirmado pero todavía no hay importaciones:** el ensayo ha generado estos SQL locales:

- `backups/importador-promocion-20261029/recuperar-esquema-actual.sql`
- `backups/importador-promocion-20261029/recuperar-prosa-primero.sql`

Se elige el que corresponda a las funciones anteriores, no al gusto. Verifican sus huellas para
no sobrescribir cambios posteriores; bloquean la tabla de importaciones antes de comprobar que
está vacía. Rechazan la recuperación si hay importaciones o fichas básicas. Restauran las funciones
originales y retiran los objetos añadidos, sin `CASCADE` ni borrado de anotaciones. La reversión
del importador con prosa previa conserva la corrección de prosa.

**Si ya existen importaciones:** no desmontar tablas ni restaurar automáticamente el backup
completo, porque se podrían perder importaciones y trabajo editorial posterior. Usar la
[pausa de guardado](../../scripts/importador-metrico/promocion/pausar-guardado.sql), conservar las
copias y corregir hacia delante. La pausa retira EXECUTE de la confirmación para `authenticated`,
también admin/IP; mantiene las lecturas. Una pantalla ya abierta puede seguir mostrando el botón,
pero la DB rechaza nuevas confirmaciones. La
[reanudación](../../scripts/importador-metrico/promocion/reanudar-guardado.sql) se ejecuta solo
después de comprobar la corrección y con aprobación.

La aplicación y cualquiera de estas operaciones de recuperación en la base compartida requieren
autorización explícita. Hasta entonces todos los archivos permanecen como propuesta revisable.
