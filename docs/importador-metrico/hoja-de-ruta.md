# Hoja de ruta del importador métrico

El proyecto comienza con documentos y archivos de ensayo en `main`. El resultado del piloto debe
guiar la adaptación de la base compartida. Las etapas siguientes son un plan; no representan
funcionalidad implementada ni experimentos ya ejecutados.

## Etapas y condiciones de avance

| Etapa | Trabajo y resultado verificable | Condición de avance |
| --- | --- | --- |
| 1. Contrato del piloto | Ejemplos de transcripción, metadatos, identificación parcial, candidatas y trazabilidad | Distinguir fielmente la declaración editorial de sus interpretaciones |
| 2. Referencia de transcripción | Inventario y extracciones revisadas de las veinte obras fotografiadas, empezando por una muestra pequeña para ajustar el procedimiento | Cada extracción aceptada tiene revisión humana y conserva las incidencias de la fuente |
| 3. Correspondencias y prompt | Inventario de denominaciones, equivalencias revisadas, candidatas justificadas y prompt versionado | Conocer qué se resuelve, qué queda abierto y qué errores introduce el procedimiento |
| 4. Sensibilidad | Resultados reproducibles de degradación y límites por lagunas sistemáticas | Determinar qué preguntas pueden responderse y con qué condiciones de cobertura |
| 5. Modelo y contrato de análisis | Diseño del esquema común, procedencia, usos, promoción editorial y medidas con incertidumbre | Resolver con los casos reales las restricciones de integridad y los consumidores afectados |
| 6. Recorrido completo | Importar una obra real, revisar, guardar, calcular su perfil privado y asignarla para ampliación | Conservar evidencia, evitar duplicados y mantener el funcionamiento editorial existente |
| 7. Ampliación y resultados compartibles | Procesar más obras, revisar nuevos términos y seleccionar comparaciones | Resultados interpretables y trazables antes de incorporarlos a fichas completas |

Las etapas pueden solaparse: la extracción de las primeras obras permite empezar el inventario
terminológico y los ensayos del prompt sin esperar a cerrar las veinte. La normalización puede
seguir siendo parcial cuando el gold de transcripción ya esté terminado.

## Decisiones abiertas que conviene conversar

| Decisión | Qué necesita resolverse |
| --- | --- |
| Candidatas | Quién aprueba una correspondencia, qué evidencia la sostiene y cuándo la lista es exhaustiva o solo orientativa. No asignar pesos sin fundamento |
| Aceptación de la extracción | Quién revisa, qué confirma y cómo se registran una fila ilegible o una inconsistencia de la propia fuente |
| Fechas y autoría | Qué hacer con intervalos y propuestas alternativas; cómo seleccionar periodos y obras de autoría discutida sin fingir certeza |
| Disponibilidad en la plataforma | Qué ve cada rol y qué fichas pueden usarse para cada análisis, al margen de su publicación individual |
| Adopción por un editor | Cómo pasa una ficha mínima a trabajo detallado, conservando revisión pendiente, decisiones y procedencia |
| Ediciones y reimportaciones | Cómo reconocer una obra existente, elegir su base analítica y actualizarla sin sobrescribir trabajo ni contar dos veces la obra |
| Cálculo del referente | Si se resume por obra o por versos; excluir o incluir la obra de referencia de manera explícita; selección por periodo y cobertura |
| Publicación de comparaciones | Qué evidencia, tamaño de muestra y estabilidad permiten redactar una comparación, y qué incertidumbre se muestra |
| Archivos del piloto | Formato de intercambio, datos que se versionan y ubicación de fotografías y demás materiales externos |

La conversación ha establecido los principios de [metodología](./metodologia.md), pero estas
políticas operativas no están cerradas. Los campos y tablas se diseñarán después de probar los
casos; no se da por aprobada una migración por documentar una posibilidad.

## Evaluación del procedimiento

Se registrarán por separado los fallos de transcripción y las asignaciones incorrectas de catálogo,
los casos bien dejados pendientes y el tiempo humano necesario para obtener una obra revisada.
Maximizar la cantidad de términos resueltos no justifica inventar identificaciones.

Parte de los materiales se reservará para evaluar la versión del prompt y las reglas después de
ajustarlas con la muestra inicial. Se registrará qué obras sirvieron para ajustar cada versión y
cuáles para evaluarla. No se presupone tener que ensayar todos los proveedores de IA.

Antes de medir sensibilidad se definirá qué cambio sería relevante para cada pregunta. Se ensayarán
pérdidas aleatorias y concentradas por término, forma o periodo, además de errores plausibles
observados en la extracción. Los porcentajes de perturbación son parámetros experimentales, no
umbrales de aceptación ya acordados.

Los resultados distinguirán la precisión respecto a la declaración editorial, la cobertura de
normalización y la estabilidad de las medidas. Las fechas amplias y la selección del referente
deben poder examinarse sin atribuirles distribuciones probabilísticas no justificadas.

## Integración técnica en la base compartida

La orientación es una identidad común de obra, evidencia de fuente conservada, anotación de
profundidad variable y cálculos compartidos con cobertura explícita. El registro de importación
conserva el original; no constituye un segundo corpus que deba mantenerse a mano.

Antes de implementar se revisarán el esquema vivo y los consumidores de las anotaciones:
validación métrica, checklist editorial, asignaciones, perfiles, artefactos e índices. Se probará
que una identificación pendiente no se convierta en forma del catálogo, ausencia o conformidad
normativa, y que una candidata no se convierta en un hecho al generar un resumen.

El piloto permanecerá fuera de la base compartida. La futura implementación introducirá primero
los cambios compatibles necesarios y después sus lectores y escritores, con verificación de las
funciones SQL que cambien. Las sustituciones o retiradas se harán una vez que sus consumidores
estén adaptados. Se seguirán las copias, snapshots y reglas de migración del repositorio.

Trabajar en `main` es la opción elegida para convivir con las mejoras habituales. Se mantendrán
cambios pequeños y se revisarán las modificaciones existentes antes de editar archivos comunes.
Si un cambio concreto requiere detener temporalmente ediciones de datos o reconsiderar la rama,
se planteará por su impacto concreto; no se presupone para todo el proyecto.
