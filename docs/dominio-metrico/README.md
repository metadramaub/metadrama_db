# Dominio métrico

Actualizado: 21 de agosto de 2026

Esta carpeta reúne la ontología, los criterios, el modelo aplicado y los planes del dominio
métrico de Versología, separado del vocabulario genérico del proyecto.

> **La revisión del catálogo terminó el 21 de agosto de 2026**, y con ella la de su prosa. Lo que
> viene son dos hitos: **migrar las secuencias ya anotadas** desde el vocabulario legado y **pasar
> el editor V2 a producción**. Lo que hay que despejar antes está inventariado y ordenado por
> urgencia en [qué queda pendiente](./CONTEXTO-PARA-CONTINUAR.md#qué-queda-pendiente).

**Leer primero:** [Contexto para continuar el trabajo](./CONTEXTO-PARA-CONTINUAR.md). Estado
operativo, qué queda por hacer, fronteras de seguridad y ruta de lectura para retomar el proyecto
en otro chat.

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
| [Dónde vive la prosa del catálogo](./donde-vive-la-prosa.md) | Los ocho criterios de redacción y qué se escribe en cada campo: definición, descripción, nota, afirmación |
| [Contratos del registrador](./contratos-registrador-formas-revisadas.md) | Qué deriva y qué pregunta el editor en cada forma. Lo lee `npm run audit:metrica` |

**Cómo se cambia el catálogo:** por migración, nunca desde el dashboard. El método —auditar la
forma entera contra la base, presentar las decisiones juntas, una sola migración con guardas que
ejecuten lo que tocan, y verificar la ficha— está en
[el contexto](./CONTEXTO-PARA-CONTINUAR.md#cómo-se-revisa-y-se-cambia-el-catálogo), con las reglas
que costó aprender: cómo se retira algo, por qué una afirmación no se reutiliza entre formas y por
qué que el auditor calle no prueba que la norma esté declarada.

## Lo que se comprueba solo

| Informe | Cómo se regenera |
| --- | --- |
| [Conformidad del catálogo](./informe-conformidad-catalogo.md) | `npm run audit:metrica` — D1–D16 contra la base viva |
| [Estado de las equivalencias](./informe-equivalencias.md) | `npm run equivalencias:informe` |
| [Informes por obra](./migracion/) | `npm run migracion:informe` |
| [Qué le pide el editor a cada forma](./informe-editor-v2.md) | `npm run audit:editor` — coste por forma y defectos del formulario |

Ninguno se edita a mano. `npm run audit:metrica` necesita Docker, porque vuelca la base.

## Lo que viene

| Documento | Para qué |
| --- | --- |
| [Plan de migración de las anotaciones](./plan-migracion-anotaciones.md) | El marco: condiciones previas, fases y criterios de aceptación. No iniciado |
| [Cómo se migra una obra](./como-se-migra-una-obra.md) | El procedimiento obra por obra, escrito para poder explicárselo a quien la anotó |
| [Equivalencias pendientes](./equivalencias-pendientes.md) | **Por qué** algunos términos legados no declaran todavía su destino, y qué decidió el IP sobre cada uno. Hay que cerrarlo antes del backfill |
| [Plan de desviaciones y caracterizaciones](./plan-desviaciones-y-caracterizaciones.md) | Cierra el vocabulario de las desviaciones y reparte lo que hoy es «caracterización por rango». Decidido, no ejecutado |
| [Demarcador métrico](./demarcador-metrico.md) | Contrato conceptual, matemática y decisiones de producto. Se actualiza cuando cambia el motor, no cuando cambia una forma |

## Histórico

[historico/](./historico/) — **nada de esa carpeta describe el estado actual.** Son documentos del
proceso que se conservan por su razonamiento y su trazabilidad. Los que más se consultan:

- [Revisión del catálogo, julio–agosto de 2026](./historico/revision-del-catalogo-2026-07-a-08.md) —
  el diario del contraste con las seis fuentes y **qué cambió en el modelo por el camino**.
- [Cuestiones por forma](./historico/cuestiones-por-forma-2026-08.md) — el pasaje de la fuente y el
  razonamiento con que se decidió cada cosa, forma por forma. Lo que sigue abierto se promovió al
  inventario de pendientes del contexto.
- [Vocabulario heredado](./historico/vocabulario-heredado.md) — los 119 términos anteriores con sus
  definiciones, rasgos, subtipos y destino. **Es la referencia para comprobar si se perdió algo al
  migrar.**
- [Qué guarda el registro](./historico/que-guarda-el-registro-2026-08-01.md) — tres secuencias
  inventadas, fila a fila. Su método vale; sus nombres de tabla ya no.

## El catálogo, en la web

Se publica en [`/formas`](https://versologia.metadrama.org/formas), **generado del dato**: cada
forma con sus arquitecturas, esquemas, secciones, rasgos, denominaciones, relaciones y lo que
dicen las fuentes. No lleva texto redactado aparte: si algo se lee mal, está mal en el catálogo.
El dashboard no lo edita.
