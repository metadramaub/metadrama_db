# Migración métrica · Dido y Eneas

Generado el 2026-08-27 por `npm run migracion:informe`. **No editar a mano:**
se regenera y se pierde lo escrito. El procedimiento está en
[cómo se migra una obra](../como-se-migra-una-obra.md) y las decisiones van a
[equivalencias pendientes](../equivalencias-pendientes.md).

- **Editor asignado:** Gaston Gilabert
- **Secuencias métricas:** 24
- **Subtipos estróficos:** 0
- **Caracterizaciones por rango:** 7

## Qué hay que consultar

- **1 secuencia(s) resueltas por ascendencia.** La forma y la arquitectura
  se heredan del término padre, pero las respuestas concretas —pareados, dístico final,
  encadenamiento— no se deducen y las tiene que confirmar quien anotó.
- **4 secuencias que pasan a ser 1.** El vocabulario viejo obligaba a
  partirlas porque el esquema cambiaba de estrofa a estrofa; en el modelo nuevo son una sola
  secuencia con varias unidades. Conviene confirmarlo antes de fundirlas.

Resolución: 15 directas · 8 con rasgo propio · 1 por ascendencia · 0 sin destino · 0 sin forma declarada · 0 con longitud por revisar.

## Secuencias que se funden en una

Cada tramo pasa a ser **una** secuencia con tantas unidades como tenía de secuencias, y lo
que las distinguía se conserva como respuesta de cada unidad. Es lo mismo que ya se hacía
con las quintillas.

**vv. 169–378** → Sexteto-lira · Heterométrica consonante — 4 secuencias en una, con 35 unidades de 6 versos

| Versos | v | Término actual | Pasa a ser |
| --- | ---: | --- | --- |
| 169–174 | 6 | `sexteto_lira_a2_AbaBcC` | unidad con variedad «A2 · AbaBcC» |
| 175–180 | 6 | `sexteto_lira_a1_aBaBcC` | unidad con variedad «A1 · aBaBcC» |
| 181–186 | 6 | `sexteto_lira_a3_abaBcC` | unidad con variedad «A3 · abaBcC» |
| 187–378 | 192 | `sexteto_lira_a1_aBaBcC` | unidad con variedad «A1 · aBaBcC» |

## Lo que hay que completar

**6 de 24 secuencias** llegan al editor con algo sin
responder. El resto se puede aceptar de un vistazo. Lo que falta aquí no lo arregla ninguna
equivalencia: es lectura del texto.

| Versos | Forma | Estrofas | Qué falta |
| --- | --- | ---: | --- |
| 1–168 | Octava real | 21 | Esquema de rima |
| 543–622 | Redondilla | 20 | Esquema de rima |
| 771–942 | Redondilla | 43 | Esquema de rima |
| 1045–1094 | Quintilla | 10 | Esquema de rima |
| 1223–1302 | Quintilla | 16 | Esquema de rima |
| 2053–2227 | Quintilla | 35 | Esquema de rima |

## Secuencias

**Todo lo que la obra tiene anotado de cada secuencia**, salvo la sinopsis y los comentarios
internos: así se puede recorrer la migración con el editor sin consultar la base. Los subtipos
y las caracterizaciones llevan su rango entre paréntesis cuando no ocupan la secuencia entera.

La columna **Propuesta** dice qué trae ya puesto el editor: lo *anotado* se miró verso a verso
en su día y se traslada tal cual; lo *derivado* se deduce del término legado y hay que revisarlo.

| # | Versos | v | Término actual | Forma propuesta | Arquitectura | Subtipos | Caracterizaciones | Estado | Propuesta | Vía |
| ---: | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1–168 | 168 | `octava_real_regular` | Octava real | Endecasilábica consonante | — | — | **falta:** Esquema de rima | — | por ascendencia (octava_real) |
| 2 | 169–174 | 6 | `sexteto_lira_a2_AbaBcC` | Sexteto-lira | Heterométrica consonante | — | — | lista | 1 derivada | directa |
| 3 | 175–180 | 6 | `sexteto_lira_a1_aBaBcC` | Sexteto-lira | Heterométrica consonante | — | — | lista | 1 derivada | directa |
| 4 | 181–186 | 6 | `sexteto_lira_a3_abaBcC` | Sexteto-lira | Heterométrica consonante | — | — | lista | 1 derivada | directa |
| 5 | 187–378 | 192 | `sexteto_lira_a1_aBaBcC` | Sexteto-lira | Heterométrica consonante | — | `hipometrico` (190–190) | lista | 32 derivadas | directa |
| 6 | 379–542 | 164 | `romance_o-e` | Romance | Octosilábica | — | — | lista | 1 derivada | rasgo + forma del padre |
| 7 | 543–622 | 80 | `redondilla` | Redondilla | Octosilábica | — | — | **falta:** Esquema de rima | — | directa |
| 8 | 623–770 | 148 | `romance_o-a` | Romance | Octosilábica | — | — | lista | 1 derivada | rasgo + forma del padre |
| 9 | 771–942 | 172 | `redondilla` | Redondilla | Octosilábica | — | — | **falta:** Esquema de rima | — | directa |
| 10 | 943–1044 | 102 | `romance_e-a` | Romance | Octosilábica | — | — | lista | 1 derivada | rasgo + forma del padre |
| 11 | 1045–1094 | 50 | `quintilla` | Quintilla | Octosilábica consonante | — | — | **falta:** Esquema de rima | — | directa |
| 12 | 1095–1222 | 128 | `romance_a-o` | Romance | Octosilábica | — | — | lista | 1 derivada | rasgo + forma del padre |
| 13 | 1223–1302 | 80 | `quintilla` | Quintilla | Octosilábica consonante | — | — | **falta:** Esquema de rima | — | directa |
| 14 | 1303–1494 | 192 | `redondilla_regular` | Redondilla | Octosilábica | — | — | lista | 48 derivadas | directa |
| 15 | 1495–1574 | 80 | `decima_espinela` | Décima | Espinela | — | — | lista | — | directa |
| 16 | 1575–1798 | 224 | `redondilla_regular` | Redondilla | Octosilábica | — | `rima_defectuosa` (1626–1626)<br>`rima_defectuosa` (1792–1792) | lista | 56 derivadas | directa |
| 17 | 1799–1876 | 78 | `terceto_encadenado` | Terceto encadenado | Endecasilábica consonante | — | — | lista | — | directa |
| 18 | 1877–2052 | 176 | `romance_e-e` | Romance | Octosilábica | — | — | lista | 1 derivada | rasgo + forma del padre |
| 19 | 2053–2227 | 175 | `quintilla` | Quintilla | Octosilábica consonante | — | — | **falta:** Esquema de rima | — | directa |
| 20 | 2228–2381 | 154 | `romance_e-o` | Romance | Octosilábica | — | `cantado` (2240–2243)<br>`cantado` (2248–2251)<br>`cantado` (2257–2260)<br>`cantado` (2264–2267) | lista | 1 derivada | rasgo + forma del padre |
| 21 | 2382–2853 | 472 | `redondilla_regular` | Redondilla | Octosilábica | — | — | lista | 118 derivadas | directa |
| 22 | 2854–2971 | 118 | `romance_a-a` | Romance | Octosilábica | — | — | lista | 1 derivada | rasgo + forma del padre |
| 23 | 2972–3015 | 44 | `redondilla_regular` | Redondilla | Octosilábica | — | — | lista | 11 derivadas | directa |
| 24 | 3016–3073 | 58 | `romance_e-a` | Romance | Octosilábica | — | — | lista | 1 derivada | rasgo + forma del padre |

## Caracterizaciones por rango

Buena parte de estas no son caracterizaciones sino **desviaciones**, y en el modelo nuevo
se registran como tales. Las de medida —hipometría e hipermetría— no conservan el número
de sílabas observado, así que hay que revisarlas con quien las anotó.

| Tipo | Rangos |
| --- | ---: |
| `cantado` | 4 |
| `rima_defectuosa` | 2 |
| `hipometrico` | 1 |

