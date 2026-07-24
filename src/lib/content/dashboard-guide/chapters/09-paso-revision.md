La pestaña **Revisión** te sirve para cerrar el ciclo de la obra.

## Qué haces aquí

- revisar las comprobaciones necesarias y las recomendaciones editoriales;
- dejar o responder comentarios internos;
- actualizar el estado de la obra cuando tu rol lo permita.

Las **comprobaciones necesarias** revisan:

- que estén completos el título, el género y la edición base;
- que exista una estructura, que cada jornada tenga cuadros y que no haya numeraciones duplicadas;
- que existan secuencias y que no conserven campos en `Pendiente`;
- que los rangos sean coherentes;
- que exista al menos una propuesta de autoría documentada. Una autoría disputada también es válida si sus propuestas están correctamente registradas.

Las **recomendaciones editoriales** recuerdan revisar las sinopsis de las secuencias, las observaciones, la bibliografía y la asignación del responsable de edición. Orientan la revisión, pero no bloquean el cambio de estado.

Si una comprobación está pendiente, el botón **Revisar** abre directamente la pestaña donde puede corregirse.

## Estados y transiciones

Como editor asignado a una obra, puedes mover estos estados:

- `borrador` → `vista_previa` (para revisar la ficha pública).
- `vista_previa` → `borrador` (para volver a editar).
- `vista_previa` → `listo_para_publicar` (cuando la revisión está cerrada).
- `listo_para_publicar` → `borrador` (si necesitas retomar la edición).

> [!NOTE]
> Publicar la obra (hacerla visible al público) y otras transiciones no listadas quedan reservadas a los roles `admin` e `IP`.

> [!TIP]
> Todo el contenido de la obra debe quedar completo antes de pasarla a revisión. Antes de terminar, revisa las dudas abiertas: si una decisión sigue siendo discutible, deja un comentario interno en el punto exacto que deba revisarse.

El checklist también comprueba los rangos de jornadas, cuadros y secuencias. Si encuentra solapamientos o cuadros fuera de su jornada, muestra el número de incoherencias. Pulsa **Revisar** para abrir **Estructura** o **Secuencias**, donde se detallan los rangos afectados y se señalan en rojo. Las opciones `vista_previa`, `listo_para_publicar` y `publicado` quedan deshabilitadas mientras exista cualquier comprobación necesaria pendiente.

Los rangos solo pueden corregirse en `borrador`. Si la obra ya está en otro estado, devuélvela primero a `borrador`, ajusta los elementos señalados en rojo y vuelve después a la pestaña **Revisión**.
