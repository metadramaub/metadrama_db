# Cómo mantenemos la documentación

Estas directrices se aplican a todo el repositorio. Antes de crear un documento, consultar el
índice del área y buscar si el tema ya tiene una referencia vigente.

## Un sitio para cada información

- Cada área tiene un README breve: alcance, estado comprobado, enlaces por tarea y siguiente paso.
- Cada decisión tiene una referencia vigente. Los demás documentos enlazan a ella; no duplican
  listas de campos, acuerdos o estados. Actualizar esa referencia en el mismo cambio de código.
- Las tareas pendientes viven en [PENDIENTES](./PENDIENTES.md). Un plan explica dependencias y
  criterios de aceptación, pero no crea una segunda lista de seguimiento.
- Separar metodología, funcionamiento actual y arquitectura. Distinguir acuerdos, propuestas,
  implementación local y despliegue comprobado; no presentar un ensayo como funcionalidad disponible.
- El histórico conserva ensayos, decisiones superadas y registros fechados. No se ofrece como
  punto de entrada ni se actualiza para simular que describía el estado presente. Git conserva
  además las versiones anteriores: no hace falta un MD nuevo por cada sesión o pequeño arreglo.

## Datos, informes y evidencias

- Las reglas y referencias consumidas por la aplicación pertenecen a `data/` o al módulo dueño
  del dato, no a `docs/`. Los ejemplos de prueba se identifican expresamente como tales.
- Un informe generado declara su generador, sus entradas y cómo regenerarlo. Se corrige la
  fuente o el generador, nunca el informe a mano. Sus salidas tienen destinos estables.
- Conservar las respuestas originales de modelos sin corregirlas. La evaluación, la transcripción
  corregida y las incidencias de la edición son piezas separadas. Registrar versión del prompt,
  modelo observado, fotos y número de intento cuando consten; no inventar lo que falta.
- La evidencia necesaria para reproducir una conclusión debe quedar versionada si no contiene
  datos privados. `backups/` se reserva para copias de BD, credenciales, volcados privados y
  material voluminoso regenerable. Un enlace a un archivo ignorado no basta como evidencia durable.
- Evitar duplicar respuestas y prompts. Archivar una versión no cambia su contenido ni la convierte
  en referencia aceptada. No alterar archivos identificados por hash para corregir rutas de lectura.

## Antes de cerrar un cambio

1. Actualizar el índice del área y retirar referencias de estado desfasadas.
2. Consolidar documentos que describan la misma operación; archivar el razonamiento histórico útil.
3. Si se mueve un archivo, revisar enlaces, imports, scripts, pruebas y destinos de generadores.
4. Comprobar enlaces locales y ejecutar los generadores y pruebas afectados. No consultar ni
   modificar la base compartida solo para reorganizar documentos.
5. Indicar las limitaciones de la comprobación; no declarar un despliegue a partir de pruebas locales.

`npm run docs:comprobar` comprueba los destinos de enlaces locales del importador, sus prompts
y las instrucciones comunes. No comprueba anclas ni enlaces de red; no es una auditoría de
toda la documentación del repositorio. También contrasta los hashes de las transcripciones
aceptadas y de las respuestas históricas conservadas.

Los cambios pequeños amplían la referencia existente. Crear una carpeta o documento nuevo solo
si tiene un propósito distinto, un responsable lógico y un enlace desde su índice.
