# Contrato local de ficha mínima

Primer contrato ejecutable preparado el 26 de octubre de 2026 a partir de los
[campos acordados](./campos-minimos.md). Se puede ensayar con las cuatro obras sin acceder a la DB.
El [informe del contrato](./piloto/informe-contrato-minimo.md) enlaza sus vistas previas.

**No hay todavía guardado en Supabase, pantalla de dashboard ni permisos aplicados en RLS.**
Las vistas del piloto no son confirmaciones humanas ni nuevas aprobaciones de equivalencias.

## Qué comprueba

El [módulo](../../scripts/lib/importador-metrico/ficha-minima.mjs) define
`versologia-ficha-minima/0.1`, con referencias locales del piloto. No es un cuerpo aceptado por
la API de obras ni resuelve todavía el nombre de autor a un UUID de Supabase.

- Exige título, autor, género seleccionado, edición y fechas. Fuente de datación y fundamentos
  de autoría admiten `null` o ausencia; no los rellena con una fuente supuesta.
- Comprueba que fechas, jornadas y bloques tengan orden y rangos válidos. Las particiones deben
  ser continuas y cada bloque estar dentro de una jornada. Una cifra ilegible no pasa como cero.
- No admite estado editorial, editor asignado, visibilidad pública ni autor de confirmación
  dentro de los datos pegados. La identidad de quien confirma llega en un contexto separado.
- Distingue identificación revisada, propuesta única y candidatas. Una forma puede estar revisada
  con arquitectura desconocida o con candidatas de arquitectura, sin perder su cobertura de forma.
- Comprueba destinos en las referencias conservadas del catálogo: formas, arquitecturas,
  géneros, metros observados y remates de Canción y Terceto encadenado. No utiliza una arquitectura principal por defecto.
- Conserva los detalles pendientes de asonancia o dístico sin convertirlos en respuestas
  confirmadas. Admite los remates revisados y las desviaciones de metro y estructura del piloto.
  «Serventesio final» se conserva literalmente y se interpreta como remate de un verso del
  Terceto encadenado, sin crear otra forma. Comprueba los límites de extensión de sección cuando
  el catálogo de referencia los declara.
- Conserva los versos añadidos en la extensión del pasaje. No genera unidades ni certifica
  conformidad estrófica mediante divisiones de longitud.

`validarFichaMinima()` devuelve errores y avisos. Una identificación pendiente o una partición
todavía provisional son avisos y limitan los análisis disponibles; no se transforman en nuevas
formas ni en un paso editorial obligatorio de validación.

La primera versión cubre los datos y detalles presentes en este lote. Otros detalles, faltas sin
localización o sistemas de numeración diferentes deben representarse antes de ampliar el guardado;
no se aceptan silenciosamente con campos inventados.

## Copia fija y permisos: ensayo del mecanismo

`crearCopiaConfirmada()` produce un objeto independiente con `datos_confirmados`, quién confirma,
cuándo y una huella SHA-256 del contenido. Ordena las claves al calcular la huella, de modo que
reordenarlas al almacenar JSONB no la cambie. Cambiar datos sí cambia la huella.

La función copia y congela recursivamente sus datos. Las pruebas cambian edición y fechas y vacían
jornadas y secuencias de trabajo: la copia conserva el contenido original. Esto ensaya el mecanismo
de conservación; la inmutabilidad en la DB requerirá el guardado y sus garantías SQL.

El contexto de confirmación exige una cuenta activa. Admin/IP no necesitan concesión adicional;
un editor necesita el permiso individual de importación. No se exige asignación de obra ni acceso
al laboratorio. Se prueba con identidades sintéticas, sin simular una confirmación del piloto real.

En la futura ruta, ese contexto debe construirse en servidor desde la sesión y los permisos reales,
no desde el cuerpo de la petición. **Estas funciones no sustituyen autenticación ni RLS.**
Consultar todas las mínimas, conceder el permiso y sustituir el aporte al publicar siguen pendientes
de integración; no se presentan como capacidades implementadas por estas pruebas locales.

## Resumen cuantitativo

`resumirFichaMinima()` calcula extensión numerada, cobertura de forma y arquitectura y peso de
cada forma revisada sobre el total. Las propuestas y candidatas permanecen en la parte pendiente.
No renormaliza los 237 versos identificados del lote (67 de Canción y 170 de Terceto encadenado)
como si cubrieran las cuatro obras completas.

Los bloques actuales proceden de filas editoriales y conservan segmentación provisional. El resumen
no presenta su cantidad como número confirmado de secuencias métricas ni calcula transiciones.
Tampoco calcula todavía límites probabilísticos, similitud, tolerancias o aptitud universal del corpus.

## Reproducir las vistas previas

```powershell
node scripts/importador-metrico/preparar-piloto.mjs
node scripts/importador-metrico/preparar-piloto.mjs --comprobar
```

La [CLI](../../scripts/importador-metrico/preparar-piloto.mjs) verifica la transcripción aceptada
contra su hash y las entradas de normalización contra sus referencias. Selecciona explícitamente
el género del lote, usa las referencias locales conservadas y genera cuatro JSON, cuatro vistas
Markdown, un informe y el [JSON Schema](./piloto/ficha-minima.schema.json).

Las opciones `--confirmar` y `--aplicar` no existen: la CLI las rechaza antes de generar archivos.
El modo `--comprobar` verifica los diez derivados sin escribir. No ejecuta la función de confirmación,
no asigna usuarios reales y no convierte los resultados locales en fichas de la plataforma.

JSON Schema expresa campos y tipos; las reglas entre rangos, entidades y contexto se comprueban
en el módulo. No basta con validar contra el esquema JSON para aceptar una importación.

## Verificación y conexión pendiente

```powershell
npx vitest run scripts/lib/importador-metrico/ficha-minima.test.mjs scripts/lib/importador-metrico/normalizacion.test.mjs scripts/lib/importador-metrico/validacion.test.mjs
```

La batería de contratos tiene 112 pruebas: 46 de ficha mínima y 66 de extracción y normalización. Incluye obligatorios/opcionales,
referencias incoherentes, huecos y solapamientos, candidatas, detalles pendientes, las desviaciones,
permisos sintéticos, independencia de la copia y reproducción de los derivados.

El [borrador de persistencia](./persistencia-local.md) ya ensaya el guardado transaccional y los
permisos de DB en PostgreSQL aislado, con el esquema real exportado y datos sintéticos del piloto.
La integración deberá completar el reconocimiento de identidades contra el catálogo vigente,
verificar los originales en servidor y conectar las garantías de guardado y permisos a la aplicación.
Después se conectarán las vistas del dashboard y el cálculo de corpus con la copia seleccionada,
manteniéndola hasta que la sustituya la ficha completa publicada. El trabajo que falta se mantiene
en [PENDIENTES](../PENDIENTES.md).
