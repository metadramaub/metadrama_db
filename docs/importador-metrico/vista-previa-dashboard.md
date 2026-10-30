# Vista previa del importador en el dashboard

Actualizado el 29 de octubre de 2026. `/dashboard/importador` permite preparar, confirmar y
consultar fichas básicas en la web real, con las RPC instaladas en el Supabase compartido.
Se ha guardado y reabierto El molino: [registro del despliegue](../despliegues/2026-10-29-importador.md).
El guardado no activa todavía los análisis del corpus. El recorrido con Auth real local y navegador
ya se ha probado: véase la [auditoría de aislamiento](./auditoria-aislamiento.md).

Acuerdo del 30 de octubre: **Guardar ficha básica confirma también la segmentación mostrada**,
sin casilla ni revisión adicional. Se mantiene la forma sin identificar donde corresponda.
Los límites que la tocan no son pares evaluables para las comparaciones; no se cuentan como
ausencia ni se conectan sus vecinos. La vista previa permanece provisional hasta guardar.

## Qué permite probar

1. Copiar el prompt de extracción y pegar el JSON recibido de una IA, o cargar una de las cuatro
   obras del piloto. Se admiten extracción 0.1, ficha mínima 0.2 y su envoltorio de vista previa 0.2.
2. Preparar la vista y corregir título, autor, género, edición y fechas. Fuente de datación y
   fundamentos de autoría pueden quedar vacíos. Al cambiar el JSON se prepara otra vez, para no
   aplicar silenciosamente los metadatos de la obra anterior.
3. Elegir el autor en un único selector. Una coincidencia nominal exacta y única se preselecciona;
   el servidor comprueba su ID y obtiene su nombre vigente al comprobar los cambios.
4. Consultar una tabla por jornada con rango y número de versos, denominación editorial,
   forma y arquitectura, **Datos métricos**, **Notas** y fuente. Los recuentos distinguen versos de secuencias propuestas. Se usan
   los estilos de campos del dashboard y ayudas puntuales `?`, sin citas del chat ni fundamentos
   extensos en la tabla. Se puede filtrar por forma sin resolver o por desviaciones. Se muestra la
   correspondencia de forma sin etiquetas «propuesta» o «revisada». Las posibilidades se muestran
   solo cuando no hay una correspondencia única; la arquitectura solo cuando se conoce.
5. Corregir errores y volver a comprobar. Los cambios pendientes dejan la vista anterior marcada
   como desactualizada. Una respuesta tardía no debe sobrescribir cambios escritos durante el envío.

La forma y la arquitectura utilizan el mismo componente `FormaSecuencia` que la tabla de
secuencias de las fichas completas: forma destacada, arquitectura debajo en texto pequeño y
atenuado. El rango y su número de versos comparten celda, siguiendo esa misma tabla.
**Datos métricos** muestra nombres y valores de rasgos del catálogo, extensión del remate y
desviaciones con rango, dimensión, relación y metro observado cuando se conoce. **Notas** conserva
el texto de fuente o de revisión y los detalles literales sin normalizar, sin hacerlos pasar por
rasgos registrados. Muestra un extracto y utiliza el componente existente de notas emergentes
para leer el texto completo sin abrir el editor ni alargar las filas. La vista mínima no fabrica
unidades, esquemas de rima ni respuestas v2.

Con las RPC instaladas, los avisos buscan título y variantes normalizados, sin filtrar por autor;
muestran autoría y tipo de ficha. Hay que declarar «otra obra» para continuar o descartar si es la
misma. La identidad no se deduce de una coincidencia nominal. Al confirmar se reconstruyen los datos
en servidor y se vuelven a comprobar las coincidencias. Nunca se sobrescribe una obra existente.

## Datos y límites

Los autores, géneros y coincidencias de título se consultan con la sesión del visitante. Las
reglas y el catálogo métrico son referencias locales versionadas del piloto. El servidor comparte
el validador y normalizador con las CLI; no mantiene otras reglas
métricas en los componentes de pantalla.

Las decisiones particulares de desviaciones del piloto solo se aplican cuando coincide el
contenido de la extracción original, no porque un JSON declare el mismo `obra_ref`. El formulario
puede corregir metadatos conservando el original como procedencia. Las revisiones declaradas por
un JSON de ficha mínima no se acreditan como confirmaciones humanas realizadas desde esta pantalla.

Sin las RPC, el ensayo sigue limitado a admin/IP. Cuando están instaladas, la capacidad de sesión
autoriza también a editores específicos, tanto en la carga como en cada POST. Todos los importadores
ven las básicas propias y ajenas, con quién importó y cuándo; el permiso no abre el laboratorio.
El listado está en `/dashboard/importador/fichas`, enlazado desde el importador y Obras. La ficha
guardada es una consulta de su copia fija. Un editor asignado puede consultarla sin permiso de
importar; no puede escribirla mediante el editor detallado.

Para guardar hay que partir de la extracción original 0.1. Los formatos preparados sin original
siguen sirviendo para previsualizar, pero no para confirmar. Se conserva el mismo identificador de
petición al reintentar y se bloquea confirmar si quedan cambios sin comprobar.

## Edición de formas y secuencias

El lápiz abre el mismo modal que usa v2, con la denominación original visible. La vista habitual
ofrece forma y arquitectura opcional; permite dejar la forma sin resolver. Los datos incorporados
por la importación se muestran fuera de **Añadir datos**, siempre visibles y editables: rasgos,
remates, desviaciones y notas. **Añadir datos** permanece cerrado y sirve solo para incorporar otro
rasgo aplicable, un remate, una desviación documentada o una nota. Al añadirlo, su campo aparece
fuera del desplegable y recibe el foco. Las desviaciones se
registran con dimensión (metro o estructura), relación con la norma, versos y, si se conoce, metro
observado. No se aceptan notas de origen inventadas ni desviaciones fuera de su secuencia. Los
campos no aportados se mantienen sin especificar. No se despliega el cuestionario completo ni
se añaden ahora esquemas de rima.
**Añadir rasgo** permite escoger otro dato sin desplegar de entrada todos los campos vacíos.

Las reglas v0.7 convierten también «romance en -io» y «romance en á-e» al rasgo **Vocales de
asonancia**, valores `i-o` y `a-e`. Conservan las notaciones `-io` y `á-e` como literales. El valor
queda seleccionado al abrir el editor, con Añadir datos cerrado, y viaja como rasgo estructurado
en el documento mínimo y en su almacenamiento JSONB. No queda únicamente como texto de detalle.
Esto no supone conocer un esquema completo de rima.

«Endecasílabos sueltos con pareado final» conserva el rasgo **Dístico final → Presente**, admitido
por la arquitectura endecasilábica, dentro de la misma tirada. No se convierte en sección de remate.
El dato aparece al abrir el editor y se puede corregir o retirar. Si se divide la tirada, el dístico
queda solo en la parte final; no se permite cortarlo por la mitad ni separarlo como una secuencia
sin revisar antes el dato. Cambiar de forma no descarta silenciosamente los rasgos incompatibles:
hay que revisarlos. Esta correspondencia está incluida en las reglas v0.6.

**Dividir secuencia** abre un paso independiente: se escribe el **primer verso de la nueva
secuencia** y se muestran ambos rangos antes de crearla. Por ejemplo, 101 produce 1–100 y 101–532.
La parte nueva queda sin forma hasta que la persona elige una; no hereda una identificación
por haber dividido. Cada parte tiene identidad estable en pantalla y la forma nueva recibe el foco.
El corte se puede cancelar sin tocar la propuesta. Si hay varias partes, cambiar el último
verso de una ajusta el inicio de la siguiente. **Unir con la siguiente** reúne partes de la misma
fila original cuando tienen la misma forma y arquitectura; no elige entre dos identificaciones
distintas silenciosamente. Así puede representarse A → B → A como tres secuencias.

Los remates conocidos aparecen abiertos, con número de versos y reparto entre cuerpo y remate.
Se pueden añadir cuando el catálogo de referencia los admite, corregir o quitar el dato. Quitar
el dato no declara ausencia ni elimina versos. El cuerpo de los tercetos encadenados se contrasta
con la extensión de terceto conservada en el catálogo: 43 versos con remate de uno dejan 42 en
el cuerpo; sin ese dato aparece un aviso, sin cambiar la numeración ni bloquear la forma general.
Al dividir, el remate pasa a la parte final; se rechazan cortes que lo atraviesen o lo separen
solo como otra secuencia. Si esos versos pertenecen a otra forma, hay que revisar expresamente
el dato de remate. Si la primera
parte tiene un remate, se pide revisarlo antes de unirla para no perderlo silenciosamente. Las
desviaciones mantienen su localización: se rechaza cualquier corte que las atraviese. El servidor
reconstruye el origen, valida límites y catálogo y comprueba el contexto del remate. No acepta
campos de procedencia o aprobaciones añadidos al formulario de edición.

**Comprobar cambios**, en la cabecera del modal, aplica los cambios y actualiza la tabla solo tras la comprobación en
servidor. Si falla, conserva el modal para corregirlo y muestra la última tabla válida. Los cambios
ya comprobados viajan también al corregir metadatos. **Restablecer fila** vuelve al resultado
preparado desde la entrada. Preparar otra entrada descarta sus modificaciones anteriores.

Los cambios de edición viajan como datos temporales del formulario, sin una tabla nueva ni un
historial por secuencia. El resultado mínimo conserva la identificación final, el origen y la
nota particular; la regla deja de atribuirse cuando se elige otro destino. Dividir no certifica
automáticamente toda la segmentación. La entrada original permanece intacta.
Los rangos y su referencia común documentan la división sin generar una nota repetida en cada parte.

Los límites exteriores siguen siendo los de la fila original: corregir un error de transcripción
en esos límites requiere corregir el JSON y preparar otra vez. No se unen filas originales
distintas con una procedencia ficticia. Tampoco hay reimportación ni promoción a detallada.
El contrato 0.2 ya aplica los
[datos que se conservarán](./campos-minimos.md#qué-se-conserva-de-las-decisiones-y-dónde).
Confirmación y guardado están desplegados con las garantías descritas en
[persistencia local](./persistencia-local.md). El siguiente bloque es la precomputación combinada.

## Verificación y revisión del responsable

Se prueban el motor y las acciones con sesiones y respuestas DB simuladas, además del contrato
local anterior. Las acciones ejercitan autenticación previa, autor desde DB, fuentes vacías,
coincidencias, límites de entrada y ausencia de escrituras. La pantalla se ensayó en navegador
con el componente real y datos del piloto, mediante un servidor auxiliar local sin autenticación
ni conexión a Supabase. La revisión posterior del 26 de octubre también se ha ensayado en el
dashboard real con una sesión admin/IP ya abierta, consultando autores y títulos sin escrituras.

El 27 de octubre se comprobó también la edición en el dashboard real con sesión abierta:
división A → B → A, unión, ajuste de límites, conservación al corregir metadatos, rechazo de un
remate incompatible, cancelación sin perder cambios anteriores y restablecimiento del ejemplo.

El 28 de octubre se probó el nuevo modal compartido con v2 en el montaje visual aislado, con
los mismos componentes y motor de servidor: propuesta de corte, A → B → A, foco en la forma
nueva, reapertura, restablecimiento, retirada y adición de remates y rechazo de extensión
incompatible. Se añadieron pruebas de límites, remate y desviaciones. La sesión del dashboard
requería volver a introducir su contraseña; ese ensayo visual no acredita autenticación HTTP.

En la revisión posterior del 28 de octubre se comprobó el dashboard real con sesión abierta:
Dístico final / Presente en los endecasílabos, retirada y restablecimiento del dato, y registro de
la desviación estructural del v. 2666 de Los locos de Valencia desde su nota original. Se mantienen
el JSON original y la ausencia de guardados. El borrador SQL pasó además 54 comprobaciones reales
en PostgreSQL aislado, incluidas referencias de rasgos y contraste del texto de las desviaciones
con las notas originales.

El ajuste de esa misma revisión comprueba las asonancias declaradas como rasgos (`-io` → `i-o`,
`á-e` → `a-e`) en el motor, el guardado PostgreSQL aislado y la pantalla real. Con Añadir datos
cerrado se ven el dístico, la asonancia y las desviaciones ya incorporadas. Añadir un rasgo crea
su campo fuera del desplegable; dejarlo sin valor no fabrica un dato. El ensayo de persistencia
alcanza 55 comprobaciones, incluida la recuperación de las dos asonancias estructuradas.

La denominación «tercetos encadenados con serventesio final» se acepta como Terceto encadenado
con remate final de un verso (3+1). Los dos pasajes de El verdadero amante aportan 170 versos;
la Canción ocupa otros 67. Los recuentos internos de revisión de reglas siguen en los informes
del piloto: no representan una tarea de validación por versos para quien importa.

Para revisar el flujo en la aplicación, basta con abrir la ruta del dashboard con una cuenta
admin/IP. Conviene probar **Los locos de Valencia** para ver las desviaciones y **El verdadero
amante** para la Canción sin arquitectura y **El molino** para la letrilla sin resolver. La revisión que se pide ahora
es de claridad y comodidad: denominaciones, correspondencias y casos sin resolver,
advertencias y corrección de metadatos. No se solicita volver a aprobar los campos ya acordados.
