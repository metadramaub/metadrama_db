# Hoja de ruta del importador métrico

El proyecto trabaja con documentos y archivos de ensayo en `main`. Ya hay cuatro transcripciones aceptadas
y un [validador técnico local](./validador-local.md). El resultado del piloto debe guiar la adaptación
de la base compartida. Ya existe una vista previa de ensayo en el dashboard, sin guardado.
Las etapas siguientes no implican que esté integrado el recorrido completo ni que se hayan
ejecutado experimentos de sensibilidad del corpus.
La integración se rige por el [plan de consultas y precomputación](./consultas-y-precomputacion.md):
el corpus mixto se construye en los productores de artefactos y las pantallas conservan su lectura
de datos preparados. Antes de conectar el guardado se fija qué consumidores incluyen mínimas y
cuáles mantienen su universo actual; no se aplica un filtro general a todas las consultas.

## Siguiente entrega: guardar y volver a abrir una ficha básica

29 de octubre de 2026. El responsable aprueba los criterios del inventario general. Se vuelve
al recorrido del importador: **entrada → vista previa corregida → confirmación → consulta de la
ficha básica guardada**. La próxima entrega no incorpora conclusiones automáticas de afinidad.

La vista previa y el guardado SQL aislado existen, pero aún no están conectados. El trabajo técnico
inmediato es completar la separación de lectores/editorial y el contrato precomputado aprobado,
conectar confirmación con una validación de servidor y abrir la importación desde Fichas básicas.
La aportación al corpus se activa cuando el productor común y sus permisos estén comprobados;
guardar una ficha y que sus análisis estén actualizados son operaciones distintas.

La entrega debe demostrar que se guarda exactamente la revisión mostrada, se conserva la copia
fija aunque cambie la estructura de trabajo, no se duplica por repetir el envío y solo acceden
los usuarios previstos. Antes del primer guardado real deben estar adaptados los consumidores
que podrían tratar la básica como detallada o exponerla individualmente. Se probará en copia
aislada antes de promover el SQL definitivo a Supabase. No se aplica el borrador local tal cual.

**Alcance inicial aprobado:** crear obras nuevas; ante una coincidencia plausible con una
existente, mostrar un aviso y pedir resolver la identidad antes de guardar. **Una obra que ya existe
como detallada no admite una nueva importación básica**, aunque su detallada esté en borrador
o no sea visible. No se ofrece vincularle la importación ni crear otra obra por cambiar de edición,
título o identificación del autor. Una coincidencia de título por sí sola no establece identidad.
La comprobación se hará en servidor y en el guardado, no solo en la interfaz.

Precisado por el responsable: título y autor son señales de coincidencia, no una clave única de
obra. Se buscará por título normalizado y variantes disponibles; el autor ayuda a ordenar y
contextualizar los resultados, sin ocultar automáticamente coincidencias con otra atribución.
Incluso título y autor coincidentes pueden corresponder a obras distintas. El aviso mostrará
título, autoría y tipo de ficha, con dos salidas claras: **«Es otra obra: continuar»** para crear
una nueva, o **«Es la misma obra: descartar importación»**. La primera no permite sobrescribir
la existente ni adjuntarle la básica; declara que se trata de una identidad diferente.
La decisión sobre las coincidencias se conservará una vez por importación, sin categorías por
secuencia ni probabilidades. Al confirmar se comprobarán de nuevo las coincidencias; una nueva
coincidencia no revisada se mostrará antes de escribir. El borrador SQL que rechaza automáticamente
todo título/autor igual debe adaptarse para permitir homónimos explícitamente revisados.

Si la obra existente es básica, repetir la misma petición conserva la idempotencia; una corrección
o reimportación con otra petición requiere un recorrido explícito posterior, fuera de esta primera
entrega. Esto no retira la copia básica ya confirmada cuando empieza la elaboración de su detallada:
esa copia sigue como referente hasta publicarse la detallada, conforme al acuerdo anterior.

Tras ese recorrido se ampliarán las extracciones de cuatro a veinte y el repertorio de
equivalencias con los casos reales. No se espera tener todas las formas resueltas para guardar.
El protocolo científico se prepara aparte y su experimento se ejecutará con el corpus de Lope
reunido, según lo acordado; no se vuelve a exigir como condición previa de la primera importación.

## Etapas y condiciones de avance

| Etapa | Trabajo y resultado verificable | Condición de avance |
| --- | --- | --- |
| 1. Contrato del piloto | Ejemplos de transcripción, metadatos, identificación parcial, candidatas y trazabilidad | Distinguir fielmente la declaración editorial de sus interpretaciones |
| 2. Referencia de transcripción | Inventario y extracciones revisadas de las veinte obras fotografiadas, empezando por una muestra pequeña para ajustar el procedimiento | Cada extracción aceptada tiene revisión humana y conserva las incidencias de la fuente |
| 3. Correspondencias y prompt | Inventario de denominaciones, equivalencias revisadas, candidatas justificadas y prompt versionado; ampliar el repertorio con cada lote | Conocer qué se resuelve, qué queda abierto y qué errores introduce el procedimiento, sin exigir un repertorio exhaustivo |
| 4. Sensibilidad | Preparar protocolo reproducible y ejecutar degradación y escenarios tras reunir el corpus de Lope | Determinar qué preguntas pueden responderse; no bloquea el primer guardado seguro |
| 5. Modelo y lectura para cálculos | Obras/jornadas/secuencias compartidas, tabla de métrica mínima separada de v2, procedencia y análisis con incertidumbre | Resolver con los casos reales las restricciones de integridad y los consumidores afectados; este diseño puede avanzar con las cuatro obras |
| 6. Recorrido completo | Importar, confirmar y asignar; permitir corregir o vaciar la estructura y mostrar la propuesta importada en cada secuencia | Conservar el aporte mínimo mediante una copia fija durante la edición y sustituirlo por la completa al publicar, sin doble cómputo |
| 7. Ampliación y resultados compartibles | Procesar más obras, ampliar equivalencias y seleccionar agregados del corpus mínimo/completo para contrastar fichas completas | Resultados interpretables y trazables con cobertura y universo explícitos; privacidad de las fichas mínimas de origen |

Las etapas pueden solaparse: la extracción de las primeras obras permite empezar el inventario
terminológico y los ensayos del prompt sin esperar a cerrar las veinte. La normalización puede
seguir siendo parcial cuando el gold de transcripción ya esté terminado.
Las cuatro obras no cubren todas las formas, ni se espera que lo hagan: bastan para arrancar el
procedimiento y contrastar los primeros casos de almacenamiento. Las veinte ampliarán el repertorio
y la evaluación. El diseño técnico no queda condicionado a resolver todos sus términos.

El primer cotejo está aceptado y el validador general tiene pruebas con datos sintéticos y con
las cuatro extracciones. Ya hay un [primer ensayo de normalización](./piloto/informe-normalizacion.md)
que separa propuestas, candidatas e identificaciones revisadas. Los pasajes bibliográficos relevantes
ya están consultados directamente y documentados en el contraste de términos. Sigue revisar
las correspondencias reutilizables. Estancias → Canción está aceptada como forma con remate
declarado; «tercetos» y «letrilla» permanecen ambiguos sin exigir cotejo del texto dramático.
La aceptación de la transcripción no aprueba automáticamente las correspondencias ni
permite calcular todavía tolerancias empíricas del corpus.

## Acuerdos de funcionamiento y decisiones por concretar

El corpus de Lope es el objetivo de esta importación y servirá para el artículo científico de
presentación de Versología. Tras reunirlo se realizará el experimento de sensibilidad a datos
sin identificar, con un protocolo reproducible preparado antes de examinar sus resultados.
Los ámbitos usados como referencia del experimento deberán estar suficientemente identificados
para cada medida: reunir el corpus no elimina automáticamente su incertidumbre original.
El marco de volumen, cobertura y estabilidad está aceptado; el método comparativo y su validación
se desarrollan en el [inventario general de medidas](../inventario-medidas-analiticas.md).

| Decisión | Qué necesita resolverse |
| --- | --- |
| Candidatas | Quién aprueba una correspondencia, qué evidencia la sostiene y cuándo la lista es exhaustiva o solo orientativa. No asignar pesos sin fundamento |
| Aceptación de la extracción | Quien importa revisa y confirma el guardado, sin segundo validador. Representar las filas ilegibles y las inconsistencias de la fuente sin inventar datos |
| Fechas y autoría | Fechas obligatorias con fuente opcional; autor sin fundamentos obligatorios, priorizando obras no discutidas. Aceptado filtro por solapamiento («compatible con el periodo»), sin sustituir rangos por su año medio |
| Disponibilidad en la plataforma | Admin/IP y editores con permiso específico importan y consultan todas las mínimas, mostrando quién importó cada una. Laboratorio reservado a admin/IP; elegibilidad por medida y agregados seleccionados para fichas completas |
| Elaboración de la ficha completa | Elección entre conservar/corregir jornadas y secuencias o vaciarlas. Propuesta visible del importador sin aprobación automática en v2; copia mínima fija hasta publicar la completa |
| Tipo mínimo y presentación | Mínima como tipo, sin nuevo estado editorial. Importación en preparación → confirmación → ficha mínima; se propone una pestaña Fichas mínimas en Obras |
| Ediciones y reimportaciones | Aprobado: una detallada impide nueva importación básica en cualquier estado. Primera entrega solo crea obras nuevas; coincidencias se detienen y correcciones de básicas tendrán un recorrido explícito posterior |
| Cálculo del referente | Aceptados perfil agregado ponderado por versos, distribución por obras aparte y exclusión de la propia obra/jornadas. Mediana y Q1–Q3 como lectura principal entre obras, media accesible. Implementar selección y cobertura |
| Publicación de comparaciones | Qué evidencia, tamaño de muestra y estabilidad permiten redactar una comparación, y qué incertidumbre se muestra |
| Archivos del piloto | Formato de intercambio, datos que se versionan y ubicación de fotografías y demás materiales externos |

La conversación ha establecido los principios de [metodología](./metodologia.md), pero estas
políticas operativas no están cerradas. El [diseño de integración](./diseno-integracion.md) parte
de las decisiones ya tomadas y del esquema vivo; concretar sus campos y garantías no equivale a
aprobar ni aplicar una migración.
La propuesta de [campos mínimos](./campos-minimos.md) ya define el almacenamiento separado,
las referencias y los detalles parciales. La revisión del 26 de octubre sustituye el selector general
de versiones por una copia fija en la importación confirmada. Permite editar o vaciar las secuencias de
trabajo conservando el referente mínimo hasta publicar la completa. Su traducción a SQL y contratos
ejecutables deberá conservar esos casos y garantías.
El [primer contrato local](./contrato-local.md) ya comprueba los campos y produce vistas previas
de las cuatro obras. La copia fija y el contexto de permisos están probados con identidades
sintéticas. El [borrador SQL](./persistencia-local.md) ya ejecuta guardado transaccional, permisos RLS
e idempotencia concurrente en PostgreSQL aislado con el esquema real exportado. La conexión con
guardado desde sesiones HTTP y la sustitución en el corpus siguen pendientes, sin aplicar a Supabase.
La [vista previa del dashboard](./vista-previa-dashboard.md) ya permite pegar y comprobar la entrada,
revisar metadatos y consultar secuencias propuestas por jornadas, con acceso de ensayo para admin/IP
y sin escritura. El contrato 0.2 y el borrador SQL ya conservan original, resultado confirmado y reglas
utilizadas, sin estados de revisión ni fundamentos generales repetidos por secuencia. El siguiente paso
es conectar corrección y confirmación con el guardado y sus consumidores;
la revisión de todas las equivalencias no se traslada a quien importa.

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

Se reutilizan obras, jornadas y secuencias, con **una tabla separada para la métrica mínima** y
evidencia de fuente conservada. No se fuerza una anotación incompleta en las tablas v2. Una capa
común de lectura alimentará cálculos con cobertura explícita. El registro de importación conserva
el original; no constituye otro corpus de obras que deba mantenerse a mano.

Los datos mínimos confirmados podrán contribuir al laboratorio y a agregados seleccionados para
contrastar fichas completas. No se publicarán las fichas mínimas individuales ni se usará el estado
publicado como atajo para incluirlas en el referente.

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
