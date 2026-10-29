# Despliegue del importador básico · 29 de octubre de 2026

Guardado y consulta publicados en la web real y en el Supabase compartido. La incorporación
de las básicas a los análisis sigue pendiente del productor combinado; este despliegue no la activa.

## Versión y copia previa

- Web: `257192af`, publicación de Vercel verificada como correcta.
- Migración aplicada: `20261029180000_importador_fichas_basicas.sql`, promovida de la candidata
  ensayada sin cambios en su SQL ejecutable. La prosa ya estaba corregida previamente.
- Backup completo previo, ignorado por Git:
  `backups/supabase/20261029-importador-despliegue-E1TlVQ/`.
  Contiene esquema, datos, roles, snapshot de las 145 obras y manifiesto con huellas.
  Las exportaciones se ejecutaron secuencialmente.
- Se ejecutó `recompute_all()` tras aplicar la migración. Los artefactos detallados V3 conservaron
  sus contenidos. No se volvió a recalcular al guardar la básica: aún no hay productor combinado.

## Verificación

117 pruebas de código, 89 comprobaciones PostgreSQL con la migración promovida, comprobación
de tipos y compilación de producción correctas. Ensayo sobre una copia reciente de 145 obras,
57 tablas y 163 claves foráneas: preservación de filas y salidas, fallo atómico, repetición,
pausa y recuperación previa a la primera importación. La recuperación ensayada no sirve como
reversión posterior al primer guardado: rechaza ejecutarse si ya hay importaciones.

El verificador de despliegue se ejecutó antes y después del primer guardado real:

```powershell
node scripts/importador-metrico/verificar-despliegue.mjs --salida backups/supabase/20261029-importador-despliegue-E1TlVQ/despues-importacion.json --antes backups/supabase/20261029-importador-despliegue-E1TlVQ/antes-importador.json
```

Resultado: filas anteriores intactas y artefactos detallados conservados; permisos y 16 políticas
restrictivas comprobados; básicas privadas y ausentes de los precomputados detallados.
Informes completos y evidencia visual quedan en el backup local, sin credenciales en Git.

## Primera importación real

Se confirmó **El molino**, del lote de transcripciones aceptadas por el responsable,
desde su sesión editorial real en la web publicada. No se sembraron usuarios ni obras sintéticas.

- Lope de Vega; datación **1585–1593**, conservando el rango de la entrada.
- **2992 versos, 21 secuencias y 3 jornadas**.
- Los dísticos finales declarados se conservan como rasgos; los 9 versos de «letrilla» permanecen
  sin forma resuelta. Las posibilidades de catálogo no se convierten en identificación.
- Importador: David Merino Recalde. La consulta conserva responsable y fecha del servidor.
- Reapertura mediante recarga y presencia en Fichas básicas verificadas en navegador.
- Tipo básico, sin visibilidad pública ni editor asignado, separado del listado editorial.
- Repetición exacta de la petición comprobada mediante la RPC, dentro de una transacción
  revertida y con el contexto del importador guardado: devuelve los mismos identificadores
  con `repetida=true`. Sigue existiendo una sola importación.

El siguiente bloque es adaptar los productores precomputados y sus consumidores según el
[plan aprobado](../importador-metrico/consultas-y-precomputacion.md) y el
[inventario de medidas](../inventario-medidas-analiticas.md), conservando cobertura, permisos
y una sola aportación por obra. La sustitución editorial y la reimportación siguen pendientes.
