# Importador de esquemas métricos de ediciones críticas

Este proyecto permitirá incorporar a Versología fichas mínimas a partir de fotografías de las
sinopsis métricas de ediciones críticas. Su finalidad es construir un corpus fechado para estudiar
el perfil métrico de un autor y situar obras con ficha completa respecto a ese corpus. Las fichas
mínimas no se publicarán individualmente; sus datos podrán contribuir a comparaciones y agregados
publicables cuando la cobertura y la incertidumbre permitan sostenerlos.

Este directorio conserva el diseño y el procedimiento de trabajo. El 22 de octubre de 2026 se
preparó un [primer lote de cuatro extracciones](./piloto/informe-inicial.md), un prompt y propuestas
de equivalencia para cotejo humano. El responsable aceptó las cuatro transcripciones sin
correcciones: [registro y hashes](./piloto/revision-humana.json). **Todavía no hay importador del dashboard,
cambios de esquema ni experimentos de sensibilidad ejecutados.** Los archivos del piloto no
describen capacidades ya disponibles en la plataforma.

## Lectura y organización

| Documento | Contenido |
| --- | --- |
| [Metodología](./metodologia.md) | Acuerdos sobre fuentes, identificación, equivalencias, incertidumbre y comparabilidad |
| [Hoja de ruta](./hoja-de-ruta.md) | Etapas, resultados necesarios, decisiones abiertas e integración técnica |
| [Diseño de integración](./diseno-integracion.md) | Estructura compartida, tabla métrica mínima separada, contrato de análisis y resultados agregados para fichas completas |
| [Campos mínimos y conexiones](./campos-minimos.md) | Tipo mínimo sin nuevo estado editorial, permiso individual para importar, consulta compartida y propuesta visible en v2 |
| [Piloto](./piloto/README.md) | Materiales disponibles, referencias revisadas y procedimiento de los ensayos |
| [Validador local](./validador-local.md) | Herramienta ya disponible para comprobar salidas nuevas del prompt sin depender del gold |
| [Normalizador local](./normalizador-local.md) | Ensayo trazable sobre las cuatro transcripciones aceptadas; propuestas, candidatas y cobertura separadas |
| [Contraste de términos](./piloto/contraste-terminos.md) | Lectura de las seis fuentes del catálogo y límites de las correspondencias propuestas |

El pendiente activo se mantiene en [PENDIENTES](../PENDIENTES.md), la lista común del repositorio.
Estos documentos desarrollan el proyecto; no crean otra lista general de tareas. Cuando se tomen
decisiones, se actualiza la sección correspondiente y se conserva su razón en el historial de Git.
Las propuestas abiertas no se presentan como acuerdos.

## Alcance acordado

- La persona obtiene fotografías y metadatos, incluidas fechas y, si se dispone de ella, su fuente. Utiliza una IA externa
  con un prompt preparado y pega su resultado en el futuro importador del dashboard.
- El núcleo mínimo comprende identidad de la obra, autor, género obligatorio —Comedia para este
  lote—, edición base, fechas, jornadas y secuencias con rangos e identificación métrica hasta
  donde llegue la evidencia. Fuente de datación y fundamentos de autoría son opcionales.
- Se registra automáticamente quién importa y cuándo, sin asignarle por ello la ficha completa.
- Importan admin/IP y editores autorizados individualmente. Los importadores autorizados pueden
  consultar todas las fichas mínimas, propias y ajenas, viendo quién importó cada una. Eso no
  concede acceso al laboratorio, reservado a admin/IP.
- Mínima es un tipo de ficha, no un estado añadido al circuito editorial. Quien importa comprueba
  la vista previa y confirma el guardado, sin una segunda aprobación por otro usuario.
- Se acepta lo declarado por la edición base. Comprobar errores filológicos de las ediciones no
  forma parte del piloto. Sí se comprueban la fidelidad de la extracción y su interpretación en
  nuestro catálogo.
- Un cambio de forma implica un cambio de secuencia: A → B → A produce tres secuencias.
- Algunas declaraciones permiten identificar arquitectura o rasgos; otras solo forma. Lo que no
  se puede identificar queda pendiente, conservando la denominación de la edición.
- Personajes, sinopsis y caracterizaciones ajenas al análisis métrico quedan fuera del piloto.
- Al asignarse una obra mínima, el editor podrá consultar lo importado como referencia de la
  edición. Podrá conservar jornadas y secuencias para corregirlas o vaciarlas. Las propuestas
  métricas se mostrarán al abrir una secuencia, sin darlas por aprobadas en v2. Puede cambiar de edición.
- Se conserva el aporte mínimo durante la elaboración de la completa mediante una copia fija
  de la importación confirmada, incluida su estructura y metadatos. Al publicarse la completa, esta
  sustituye al aporte mínimo; conservar la importación como referencia no duplica su contribución.
- Se ensayarán los datos y las equivalencias antes de construir toda la infraestructura.

## Base técnica acordada y desarrollo pendiente

Se reutilizan obras, jornadas y secuencias. **La métrica mínima se guarda en una tabla aparte**,
sin forzar respuestas en las tablas v2 ni rebajar las validaciones del registrador detallado.
Se conserva además evidencia de fuente e importación. Una capa de lectura común permitirá definir
las medidas compartidas una sola vez, con cobertura explícita. El
[diseño de integración](./diseno-integracion.md) contrasta esta separación con el esquema vivo;
documentarlo no aplica migraciones.

Las cuatro obras permiten empezar ese diseño y las equivalencias presentes en la muestra. El
repertorio se ampliará con las veinte del piloto y los lotes siguientes, conservando lo desconocido.
No hace falta cerrar todas las correspondencias para avanzar en el diseño.

La profundidad de una ficha, su estado editorial, su verificación, su visibilidad y sus usos
analíticos son dimensiones distintas. El diseño debe permitir combinarlas sin duplicar corpora ni
introducir una excepción particular para cada pantalla.

El laboratorio podrá usar las mínimas confirmadas y se podrán seleccionar resultados agregados de
ese corpus para contrastar fichas completas. La privacidad individual no limita el corpus mínimo
a un uso exclusivamente privado; cada resultado difundible declarará su referente e incertidumbre.

## Forma de trabajo en el repositorio

Se trabaja en `main`, conforme a la preferencia del responsable del proyecto y a la práctica del
repositorio. Las mejoras habituales de la web continúan en esa misma rama. No se considera necesaria
una rama de larga duración para la documentación ni para el piloto con archivos locales.

Hay una sola base Supabase compartida. Una rama de Git no aísla sus datos, funciones ni esquema.
Durante el piloto se usarán archivos y cálculos locales; cualquier consulta necesaria al catálogo
será de solo lectura. Los ensayos de extracción y sensibilidad no escribirán en la base compartida.

La futura integración se dividirá en cambios pequeños y compatibles, evitando modificar a la vez
el editor, la persistencia y todos los consumidores. Antes de cambiar archivos se revisará el estado
del trabajo y, antes de una migración, el esquema vivo. Se respetarán las copias y verificaciones
exigidas por [CLAUDE.md](../../CLAUDE.md) y [README.md](../../README.md). Una migración aplicada no
se reescribe. Si una fase llegase a justificar otra rama, se conversará antes de cambiar esta forma
de trabajo; no se abrirá como requisito automático.

## Relación con el resto del proyecto

- [Dominio métrico](../dominio-metrico/README.md): catálogo y contratos de la anotación detallada.
- [Metodología del perfil](../metodologia-perfil-metrico.md): definición de las medidas existentes.
- [Comparativas del corpus](../plan-comparativas-corpus.md): laboratorio y selección de resultados
  para fichas. Sus universos deberán ampliarse de forma explícita al integrar el corpus mínimo.
- [Artefactos públicos](../arquitectura-artefactos-publicos.md): persistencia y permisos de las
  proyecciones. Un agregado autorizado no implica hacer consultables las fichas mínimas de origen.
- [Exportador del catálogo](../../scripts/variacion-simulacion/README.md): posible base para el
  vocabulario versionado que acompañará al prompt, sin inventar equivalencias ni probabilidades.
