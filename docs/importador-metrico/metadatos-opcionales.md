# Fotos con o sin metadatos · entrega del 31 de octubre de 2026

Implementados los tres pasos aprobados por David. El siguiente bloque es probar obras nuevas
del lote; esta entrega no ejecuta todavía esa evaluación ni integra la precomputación.

## Prompt del dashboard

El botón Copiar prompt utiliza `prompts/importador-metrico/extraccion-v0.5.md`. El intercambio
sigue siendo `versologia-extraccion/0.1`, compatible con el guardado existente.

- Basta adjuntar las fotografías. No se exige un DOCX, metadatos previos ni datos técnicos de ejecución.
- Si se facilitan metadatos, se conservan en el JSON. Si hay algunos, los restantes quedan en null;
  si no hay ninguno, el objeto metadatos puede ser null. La falta de fechas no se trata como fallo de lectura.
- Referencias locales de obra y fotos tienen valores por defecto coherentes si no se facilitan.
  No son identidades del catálogo ni sustituyen título/autor.
- Se mantienen el bloque JSON que protege los asteriscos, la lectura de columnas inclinadas,
  notas, recuentos y avisos de fuentes incompletas de la candidata v0.4.

La versión nueva aún no se ha evaluado con obras nuevas ni con otra llamada a una IA. Las pruebas
de modelos anteriores y sus límites siguen en `ajuste-prompt-2026-10-31.md`.

## Misma pantalla, sin pasos adicionales

Pegar y preparar muestra la tabla aunque falten título, autor, edición o fechas. Los campos
que vengan en el JSON se precargan; los demás se completan en el formulario. Se puede revisar
y editar la métrica antes o después de rellenarlos. Un aviso breve indica que faltan datos
obligatorios para guardar; no se añaden estados ni confirmaciones.

Comprobar cambios no exige que los campos de obra estén completos: también es la acción usada
por el modal para revisar una secuencia. Completar los metadatos conserva las ediciones comprobadas.
Las notas y el original siguen separados; rellenar el formulario no reescribe la extracción.

## Límites del guardado

La representación de borrador admite fechas null y textos vacíos solo en la preparación. La
validación métrica y las comprobaciones de estructura permanecen activas. No se inventan fechas,
títulos, autores ni ediciones provisionales para conseguir mostrar la tabla.

El contrato de ficha confirmada y la DB no cambian. No se emite huella ni se ofrece confirmar
con metadatos pendientes. La acción de confirmar reconstruye la vista y rechaza el POST incompleto;
la frontera de persistencia vuelve a exigir el esquema estricto antes de llamar a la RPC.
Crear una copia confirmada nunca acepta la opción de vista previa como relajación del contrato.
El autor sigue siendo un ID comprobado del catálogo. Fechas invertidas o inválidas se rechazan.

No se necesita migración ni se han cambiado datos de Supabase real.

## Verificación

200 pruebas dirigidas correctas, compilación de producción correcta y comprobación de tipos
sin errores ni avisos. La constante
SQL del esquema confirmado sigue coincidiendo, comprobada sin conexión ni escritura en DB.

Pruebas dirigidas: sin metadatos, precarga del piloto, edición previa a rellenarlos, conservación
posterior de cambios, POST forzado incompleto y rechazo antes de RPC aunque la huella coincida.
Se comprueba también que la creación de copia fija siga siendo estricta.

En navegador, con Persona de prueba 2 en `localhost:5190` y Supabase sintético:

1. Extracción existente de Los locos con metadatos=null: 20 secuencias visibles, sin botón Guardar.
2. Nota añadida a vv. 131–590, comprobada con título/fechas/edición vacíos: cambio aplicado y modal cerrado.
3. Metadatos completados: la nota se conserva y el botón Guardar se habilita. No se ejecuta el guardado.

Evidencia local en `backups/importador-local/flujo-metadatos-opcionales/`, fuera de Git.
