# Materiales de la auditoría de las fuentes

Lo que producen y consumen los comandos de
[`scripts/auditoria-fuentes/`](../../../scripts/auditoria-fuentes/). **Nada de esta carpeta se edita
a mano.**

## La mitad que no entra en el repositorio

**Porque lleva texto de los libros**, que tienen dueño. Es la misma razón por la que la bibliografía
es solo local:

`extractos/` · `dictamenes/` `dictamenes-b/` `dictamenes-c/` `dictamenes-d/` · `lotes/` `lotes-b/`
`lotes-c/` `lotes-d/` · `piloto/` · `correcciones.md` · `cotejo.md` y `cotejo.json` ·
`muestra-humana.md` · `senales-mecanicas.md`

Se regeneran con sus comandos y no hacen falta hasta que se vuelva a auditar. **Si borras alguno,
pasa `npm run audit:fuentes` antes que nada**: los extractos son la entrada de todo lo demás.

*Excepción vigilada:* `fase-4-exhaustividad.md` **sí** está versionado y **sí** cita pasajes de los
seis libros. Está anotado como algo que decidir.

## La mitad versionada

No lleva texto ajeno: son identificadores, veredictos y recuentos.

| Fichero | Qué es |
| --- | --- |
| `instrucciones-verificador*.md` | Lo que se le dice a cada verificador, palabra por palabra. **Se relanza un lote con ese texto exacto** o deja de ser comparable |
| `decisiones.json` | El reparto en cubos de las 267 afirmaciones, con sus señales |
| `propuestas.json` · `senales-mecanicas.json` · `matriz-exhaustividad.*` | Salidas de los comandos, sin pasajes |
| `muestra-humana.json` | La muestra para repetir la auditoría desde fuera |
| `informe-nivel-0.md` · `senal-endurecimiento.md` | Informes que citan localizadores, no texto |
| `fase-4-exhaustividad.md` · `pasada-d-hallazgos.md` | Lo que encontraron la fase 4 y la pasada D |

## Dónde está el relato

Qué se hizo y qué enseñó:
[el registro](../historico/auditoria-de-fuentes-2026-09.md). El método:
[el plan](../plan-auditoria-fuentes.md). Lo que quedó abierto:
[PENDIENTES](../../PENDIENTES.md), bloque E.
