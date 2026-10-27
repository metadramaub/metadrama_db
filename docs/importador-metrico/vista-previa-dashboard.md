# Vista previa del importador en el dashboard

26 de octubre de 2026. El código incorpora `/dashboard/importador`, enlazado como **Importador
métrico · ensayo** en el menú de admin/IP. No guarda obras, no confirma importaciones ni incorpora
datos al corpus. No requiere aplicar el borrador SQL a Supabase.

## Qué permite probar

1. Copiar el prompt de extracción y pegar el JSON recibido de una IA, o cargar una de las cuatro
   obras del piloto. Se admiten extracción 0.1, ficha mínima 0.2 y su envoltorio de vista previa 0.2.
2. Preparar la vista y corregir título, autor, género, edición y fechas. Fuente de datación y
   fundamentos de autoría pueden quedar vacíos. Al cambiar el JSON se prepara otra vez, para no
   aplicar silenciosamente los metadatos de la obra anterior.
3. Elegir el autor en un único selector. Una coincidencia nominal exacta y única se preselecciona;
   el servidor comprueba su ID y obtiene su nombre vigente al comprobar los cambios.
4. Consultar una tabla por jornada con versos inicial/final, número de versos, denominación
   editorial, forma, notas y fuente. Los recuentos distinguen versos de secuencias propuestas. Se usan
   los estilos de campos del dashboard y ayudas puntuales `?`, sin citas del chat ni fundamentos
   extensos en la tabla. Se puede filtrar por forma sin resolver o por desviaciones. Se muestra la
   correspondencia de forma sin etiquetas «propuesta» o «revisada». Las posibilidades se muestran
   solo cuando no hay una correspondencia única; la arquitectura solo cuando se conoce.
5. Corregir errores y volver a comprobar. Los cambios pendientes dejan la vista anterior marcada
   como desactualizada. Una respuesta tardía no debe sobrescribir cambios escritos durante el envío.

Los avisos de título consultan las obras actuales; una coincidencia por título no prueba identidad
ni autoriza sobrescribir una ficha. No es todavía un sistema de detección de duplicados por
variantes de título o atribuciones.

## Datos y límites

Los autores, géneros y coincidencias de título se consultan con la sesión del visitante. Las
reglas y el catálogo métrico son referencias locales versionadas del piloto. El servidor comparte
el validador y normalizador con las CLI; no mantiene otras reglas
métricas en los componentes de pantalla.

Las decisiones particulares de desviaciones del piloto solo se aplican cuando coincide el
contenido de la extracción original, no porque un JSON declare el mismo `obra_ref`. El formulario
puede corregir metadatos conservando el original como procedencia. Las revisiones declaradas por
un JSON de ficha mínima no se acreditan como confirmaciones humanas realizadas desde esta pantalla.

El ensayo se limita por ahora a admin/IP tanto en la carga como en cada acción POST. No intenta
leer la columna futura de permisos individuales. El acceso de editores concretos se conectará
cuando exista la capacidad en la DB, manteniendo el acuerdo de que los importadores podrán
consultar todas las mínimas sin obtener acceso al laboratorio. No es un cambio de ese acuerdo.

## Edición de formas y secuencias

El botón **Editar** de cada secuencia abre un panel fuera de la tabla, con la denominación original
siempre visible. Permite seleccionar forma y arquitectura opcional, dejar la forma sin resolver
y añadir una nota breve. Las arquitecturas ofrecidas pertenecen a la forma elegida.

**Dividir** fija un corte dentro del ámbito original. Si hay varias partes, cambiar el último
verso de una ajusta el inicio de la siguiente. **Unir con la siguiente** reúne partes de la misma
fila original cuando tienen la misma forma y arquitectura; no elige entre dos identificaciones
distintas silenciosamente. Así puede representarse A → B → A como tres secuencias.

El remate se conserva únicamente en la parte final, con opción expresa de retirarlo. Las
desviaciones mantienen su localización: se rechaza cualquier corte que las atraviese. El servidor
reconstruye el origen, valida límites y catálogo y comprueba el contexto del remate. No acepta
campos de procedencia o aprobaciones añadidos al formulario de edición.

**Comprobar secuencias** aplica los cambios y actualiza la tabla solo tras la comprobación en
servidor. Si falla, conserva el panel para corregirlo y muestra la última tabla válida. Los cambios
ya comprobados viajan también al corregir metadatos. **Restablecer fila** vuelve al resultado
preparado desde la entrada. Preparar otra entrada descarta sus modificaciones anteriores.

Los cambios de edición viajan como datos temporales del formulario, sin una tabla nueva ni un
historial por secuencia. El resultado mínimo conserva la identificación final, el origen y la
nota particular; la regla deja de atribuirse cuando se elige otro destino. Dividir no certifica
automáticamente toda la segmentación. La entrada original permanece intacta.
Los rangos y su referencia común documentan la división sin generar una nota repetida en cada parte.

Los límites exteriores siguen siendo los de la fila original: corregir un error de transcripción
en esos límites requiere corregir el JSON y preparar otra vez. No se unen filas originales
distintas con una procedencia ficticia. Tampoco hay reimportación, promoción a completa ni confirmación.
El contrato 0.2 ya aplica los
[datos que se conservarán](./campos-minimos.md#qué-se-conserva-de-las-decisiones-y-dónde).
El siguiente bloque debe conectar confirmación, guardado y consumidores con las garantías descritas en
[persistencia local](./persistencia-local.md), antes de aplicar la migración definitiva.

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

La denominación «tercetos encadenados con serventesio final» se acepta como Terceto encadenado
con remate final de un verso (3+1). Los dos pasajes de El verdadero amante aportan 170 versos;
la Canción ocupa otros 67. Los recuentos internos de revisión de reglas siguen en los informes
del piloto: no representan una tarea de validación por versos para quien importa.

Para revisar el flujo en la aplicación, basta con abrir la ruta del dashboard con una cuenta
admin/IP. Conviene probar **Los locos de Valencia** para ver las desviaciones y **El verdadero
amante** para la Canción sin arquitectura y **El molino** para la letrilla sin resolver. La revisión que se pide ahora
es de claridad y comodidad: denominaciones, correspondencias y casos sin resolver,
advertencias y corrección de metadatos. No se solicita volver a aprobar los campos ya acordados.
