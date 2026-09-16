# Dominio métrico

Actualizado: 16 de septiembre de 2026

Esta carpeta reúne la ontología, los criterios, el modelo aplicado y los planes del dominio
métrico de Versología, separado del vocabulario genérico del proyecto.

> **El catálogo métrico está terminado.** Se revisó forma por forma en agosto de 2026 y se auditó
> contra sus seis fuentes en septiembre; lo que viene es **migrar las secuencias ya anotadas** desde
> el vocabulario legado. Lo que falta, de todo el proyecto, está en una sola lista:
> [PENDIENTES](../PENDIENTES.md).

**Por dónde empezar**, según la tarea —solo lo necesario, no la carpeta entera—:

| Si vas a… | Lee, en este orden |
| --- | --- |
| entender el dominio | [la ontología](./ontologia-verso-espanol.md) → [el modelo aplicado](./implementacion-metrica.md) |
| formalizar o corregir una forma | [criterios de nivel](./criterios-de-nivel.md) → [cómo se cambia el catálogo](./como-se-cambia-el-catalogo.md) → [dónde vive la prosa](./donde-vive-la-prosa.md) |
| añadir o corregir una afirmación de fuente | [las fuentes del catálogo](./fuentes-del-catalogo.md) → [cómo se cambia el catálogo](./como-se-cambia-el-catalogo.md) |
| tocar el editor V2 | `src/lib/components/metrica/editor-v2/` y sus pruebas; la persistencia, en [el modelo aplicado](./implementacion-metrica.md) |
| migrar las secuencias de una obra | [el plan](./plan-migracion-anotaciones.md) → [cómo se migra una obra](./como-se-migra-una-obra.md) → [equivalencias pendientes](./equivalencias-pendientes.md) |
| saber la razón filológica de una forma | primero [`/formas`](https://versologia.metadrama.org/formas), que se genera del dato; si hace falta el porqué, [cuestiones para el IP](./cuestiones-para-el-ip.md) |

**El estado no se escribe aquí**: cuántas formas hay, cuántas secuencias faltan o qué defectos
quedan se consultan en la base y con los informes de más abajo.

## Qué es el dominio

| Documento | Para qué |
| --- | --- |
| [Ontología del verso español](./ontologia-verso-espanol.md) · [diagrama](./ontologia-verso-espanol.svg) | Qué es el verso español y de qué está hecho: medida, ritmo, rima, agrupación, forma, y la relación entre norma y realización. Describe posibilidades, no este corpus. **Lectura previa a todo lo demás** |
| [El modelo métrico aplicado](./implementacion-metrica.md) · [diagrama](./implementacion-metrica.svg) | Qué parte de esa ontología se realiza aquí y cómo: las tablas, las capas, los consumidores, las garantías de la base y **las decisiones que lo gobiernan** |
| [Síntesis narrativa](./sintesis-narrativa-dominio-metrico.md) | El problema y la propuesta en pocas páginas y sin tecnicismos, para presentarlo |

## Cómo se decide y cómo se escribe

| Documento | Para qué |
| --- | --- |
| [Criterios de nivel](./criterios-de-nivel.md) | Ante un hecho observado, en qué nivel se registra: forma, arquitectura, esquema, variedad o rasgo. **De lectura obligada antes de formalizar o corregir una forma** |
| [Las fuentes del catálogo](./fuentes-del-catalogo.md) | Las seis monografías, por qué solo seis, dónde están los ficheros y cómo se cita cada una. **De lectura obligada antes de añadir o corregir una afirmación** |
| [Cómo se cambia el catálogo](./como-se-cambia-el-catalogo.md) | El método: por migración y nunca desde el dashboard. Auditar la forma entera contra la base, presentar las decisiones juntas, una sola migración con guardas que ejecuten lo que tocan, verificar la ficha. Con las reglas que costó aprender: cómo se retira algo, por qué una afirmación no se reutiliza entre formas y por qué que el auditor calle no prueba nada |
| [Dónde vive la prosa del catálogo](./donde-vive-la-prosa.md) | Los ocho criterios de redacción y qué se escribe en cada campo: definición, descripción, nota, afirmación |
| [Contratos del registrador](./contratos-del-registrador.md) | Qué tiene que cumplir el editor al anotar, sea cual sea la forma: de dónde salen las preguntas, el recorrido mínimo y qué cuenta como desviación. **Lo de cada forma en concreto lo genera `npm run audit:editor`** |
| [Cuestiones para el IP](./cuestiones-para-el-ip.md) | **Lo que sigue sin decidir y necesita criterio filológico**, forma por forma: qué admite cada una, hasta dónde llega su repertorio, si una realización documentada entra o se queda fuera |

## Lo que se comprueba solo

| Informe | Cómo se regenera |
| --- | --- |
| [Conformidad del catálogo](./informe-conformidad-catalogo.md) | `npm run audit:metrica` — D1–D16 contra la base viva |
| [Estado de las equivalencias](./informe-equivalencias.md) | `npm run equivalencias:informe` |
| [Informes por obra](./migracion/) | `npm run migracion:informe` |
| [Qué le pide el editor a cada forma](./informe-editor-v2.md) | `npm run audit:editor` — coste por forma y defectos del formulario |
| [Lo anotado frente al catálogo](./informe-anotaciones.md) | `npm run audit:anotaciones` — dónde un cambio del catálogo dejó una respuesta sin pregunta; `--comprobar` prueba las sondas |

Ninguno se edita a mano. `npm run audit:metrica` necesita Docker, porque vuelca la base.

## Lo que viene

| Documento | Para qué |
| --- | --- |
| [Plan de migración de las anotaciones](./plan-migracion-anotaciones.md) | El marco: condiciones previas, fases y criterios de aceptación. No iniciado |
| [Cómo se migra una obra](./como-se-migra-una-obra.md) | El procedimiento obra por obra, escrito para poder explicárselo a quien la anotó |
| [Equivalencias pendientes](./equivalencias-pendientes.md) | **Por qué** algunos términos legados no declaran todavía su destino, y qué decidió el IP sobre cada uno. Hay que cerrarlo antes del backfill |
| [Auditoría profunda contra las fuentes](../../scripts/auditoria-fuentes/) | Los catorce comandos que comprueban que cada afirmación diga lo que su libro dice. Cinco se pasan de vez en cuando; los demás solo dentro de una pasada de lectura. **Necesitan la bibliografía local** |
| [Plan de auditoría de las fuentes](./plan-auditoria-fuentes.md) | El método, por si hay que repetirlo: taxonomía de defectos, pasadas ciegas y errores sembrados para medir al auditor. **La auditoría terminó**; qué enseñó, en el [registro](./historico/auditoria-de-fuentes-2026-09.md) |
| [Demarcador métrico](./demarcador-metrico.md) | Contrato conceptual, matemática y decisiones de producto. Se actualiza cuando cambia el motor, no cuando cambia una forma |

## Histórico

[historico/](./historico/) — **nada de esa carpeta describe el estado actual.** Son documentos del
proceso que se conservan por su razonamiento y su trazabilidad. Los que más se consultan:

- [Revisión del catálogo, julio–agosto de 2026](./historico/revision-del-catalogo-2026-07-a-08.md) —
  el diario del contraste con las seis fuentes y **qué cambió en el modelo por el camino**.
- [Vocabulario heredado](./historico/vocabulario-heredado.md) — los 119 términos anteriores con sus
  definiciones, rasgos, subtipos y destino. **Es la referencia para comprobar si se perdió algo al
  migrar.**
- [El editor V2, el recorrido del formulario](./historico/editor-v2-recorrido-2026-08-a-09.md) —
  por qué el formulario pregunta lo que pregunta, incidencia a incidencia.
- [La precomputación y la ficha pública](./historico/ficha-publica-2026-09.md) — qué se probó en
  pantalla, qué se descartó y con qué razón.
- [Los tramos sin forma registran lo que se ve](./historico/f63-los-tramos-registran-lo-que-se-ve.md)
  — qué se le pregunta a un pasaje del que no se reconoce la norma, y por qué esas preguntas.
- [La respuesta se describe a sí misma](./historico/c20-la-respuesta-se-describe.md) — por qué una
  respuesta guardada apunta al dato y no a la pregunta que la ofreció.
- [Qué guarda el registro](./historico/que-guarda-el-registro-2026-08-01.md) — tres secuencias
  inventadas, fila a fila. Su método vale; sus nombres de tabla ya no.

## El catálogo, en la web

Se publica en [`/formas`](https://versologia.metadrama.org/formas), **generado del dato**: cada
forma con sus arquitecturas, esquemas, secciones, rasgos, denominaciones, relaciones y lo que
dicen las fuentes. No lleva texto redactado aparte: si algo se lee mal, está mal en el catálogo.
El dashboard no lo edita.
