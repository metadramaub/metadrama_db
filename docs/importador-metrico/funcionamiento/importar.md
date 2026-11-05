# Importar y gestionar una ficha básica

## Extraer y preparar

1. Fotografiar la declaración métrica y todas sus notas. Enviar las imágenes de una sola obra
   a la IA con el [prompt correspondiente](../../../prompts/importador-metrico/README.md).
   Los metadatos pueden facilitarse con las fotos o rellenarse después; no se necesita un DOCX.
2. Pegar el JSON en el dashboard y pulsar **Preparar importación**. Hasta entonces no aparecen
   metadatos ni tablas. Cambiar el JSON oculta la preparación anterior hasta volver a prepararla.
3. Cotejar las filas con las fotos y completar los metadatos obligatorios para guardar. Los datos
   facilitados se precargan; los que faltan no impiden preparar y revisar la métrica.

La forma original y las notas de la edición se conservan. La tabla muestra lo que se registrará:
forma, arquitectura y datos estructurados adicionales, separados de los textos de notas y fuente.
No hay estados de «propuesta» o «revisada» que deba aprobar quien importa.

## Revisar la métrica

El lápiz al final de la fila permite cambiar la identificación, arquitectura, remates y datos
adicionales admitidos. Lo ya extraído debe quedar visible; «Añadir datos» es para incorporar
información que aún no está registrada. No se exige la exhaustividad de la ficha detallada.

- Un cambio de forma produce otra secuencia. Dividir requiere límites explícitos; la nota de
  la edición puede proponer un corte, pero no autoriza a inventar posiciones.
- Una forma sin resolver conserva su literal y extensión. No se asigna una arquitectura
  habitual ni un remate solo porque la longitud encaje. Una nota puede justificar más precisión.
- La prosa es presencia y localización entre versos, nunca extensión. Dos tramos consecutivos
  de la misma forma y jornada, separados por prosa no numerada, pueden formar una sola secuencia
  con esa caracterización. No se unen si hay incompatibilidades que requieren revisión.
- Las lagunas y adiciones declaradas se tienen en cuenta al comprobar la norma de la forma.
  Esta longitud de comprobación no reescribe la numeración de la edición.

## Comprobar y guardar

**Comprobar cambios** indica si ha terminado sin incidencias o cuántos avisos/errores hay;
las incidencias deben poder localizarse en sus filas. La comprobación se invalida al modificar
los datos. Incluye rangos, cobertura y norma métrica, pero no certifica la edición ni la lectura.
Un aviso de longitud no identifica por sí mismo la causa ni bloquea automáticamente todo guardado.

Si hay coincidencias de título/autor, se revisan antes de crear otra obra: un parecido no
identifica una obra. Una básica no sustituye una detallada. La confirmación reconstruye y valida
en el servidor, exige los metadatos completos y conserva el JSON original y la copia confirmada.
Quien importa confirma; no hay otro validador ni una casilla adicional de segmentación.

Los datos de ejecución de IA pueden corregirse en los metadatos. Modelo y modo son lo que
conste en la interfaz del servicio; no se presupone que el modelo conozca su identidad.
La corrección no modifica la respuesta original.

## Consultar y gestionar

Admin/IP y editores con permiso de importación pueden consultar todas las básicas y quién las
importó. Ese permiso no concede acceso al laboratorio. La tabla muestra formas pendientes,
avisos de longitud guardados e incidencias originales por separado. Una incidencia original
puede haberse corregido durante la preparación; no se presenta como error vigente sin comprobarlo.

La fecha de importación y la de modificación pertenecen a la copia básica. Las fechas no
acreditadas muestran «No consta». Consultar una copia no reaplica equivalencias ni la modifica.
La edición/reimportación general de copias confirmadas no está implementada. Admin/IP puede
eliminar una básica desde la papelera con confirmación de título y comprobaciones de servidor.

Campos y permisos: [referencia del modelo](../arquitectura/campos-minimos.md).
Seguimiento del piloto: [cómo regenerarlo](./seguimiento-e-informe-equivalencias.md).
Los ensayos y detalles de implementación anteriores están en el [histórico](../historico/README.md).
