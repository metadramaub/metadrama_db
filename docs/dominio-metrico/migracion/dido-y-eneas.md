# Migración métrica · Dido y Eneas

Generado el 2026-08-04 por `npm run migracion:informe`. **No editar a mano:**
se regenera y se pierde lo escrito. Las decisiones van a
[equivalencias pendientes](../equivalencias-pendientes.md).

- **Editor asignado:** Gaston Gilabert
- **Secuencias métricas:** 24
- **Subtipos estróficos:** 61
- **Caracterizaciones por rango:** 7

## Qué hay que consultar

- **4 secuencias que pasan a ser 1.** El vocabulario viejo obligaba a
  partirlas porque el esquema cambiaba de estrofa a estrofa; en el modelo nuevo son una sola
  secuencia con varias unidades. Conviene confirmarlo antes de fundirlas.

Resolución: 16 directas · 8 con rasgo propio · 0 por ascendencia · 0 sin destino · 0 sin forma declarada.

## Secuencias que se funden en una

Cada tramo pasa a ser **una** secuencia con tantas unidades como tenía de secuencias, y lo
que las distinguía se conserva como respuesta de cada unidad. Es lo mismo que ya se hacía
con las quintillas.

**vv. 169–379** → Sexteto-lira · Heterométrica consonante — 4 secuencias en una, con ¿211 / 6? unidades de 6 versos

| Versos | v | Término actual | Pasa a ser |
| --- | ---: | --- | --- |
| 169–174 | 6 | `sexteto_lira_a2_AbaBcC` | unidad con su propia respuesta |
| 175–180 | 6 | `sexteto_lira_a1_aBaBcC` | unidad con su propia respuesta |
| 181–186 | 6 | `sexteto_lira_a3_abaBcC` | unidad con su propia respuesta |
| 187–379 | 193 | `sexteto_lira_a1_aBaBcC` | unidad con su propia respuesta |

> El tramo mide 211 versos y la unidad 6: no es múltiplo exacto, así que hay
> algo que revisar antes de fundirlo.

## Secuencias

| Versos | v | Término actual | Forma propuesta | Arquitectura | Además | Vía |
| --- | ---: | --- | --- | --- | --- | --- |
| 1–168 | 168 | `octava_real_regular` | Octava real | Endecasilábica consonante | — | directa |
| 169–174 | 6 | `sexteto_lira_a2_AbaBcC` | Sexteto-lira | Heterométrica consonante | — | directa |
| 175–180 | 6 | `sexteto_lira_a1_aBaBcC` | Sexteto-lira | Heterométrica consonante | — | directa |
| 181–186 | 6 | `sexteto_lira_a3_abaBcC` | Sexteto-lira | Heterométrica consonante | — | directa |
| 187–379 | 193 | `sexteto_lira_a1_aBaBcC` | Sexteto-lira | Heterométrica consonante | — | directa |
| 380–543 | 164 | `romance_o-e` | Romance | Octosílabo | Vocales de la asonancia = o-e | rasgo + forma del padre |
| 544–623 | 80 | `redondilla` | Redondilla | Octosilábica | — | directa |
| 624–771 | 148 | `romance_o-a` | Romance | Octosílabo | Vocales de la asonancia = o-a | rasgo + forma del padre |
| 772–943 | 172 | `redondilla` | Redondilla | Octosilábica | — | directa |
| 944–1045 | 102 | `romance_e-a` | Romance | Octosílabo | Vocales de la asonancia = e-a | rasgo + forma del padre |
| 1046–1095 | 50 | `quintilla` | Quintilla | Octosilábica consonante | — | directa |
| 1096–1223 | 128 | `romance_a-o` | Romance | Octosílabo | Vocales de la asonancia = a-o | rasgo + forma del padre |
| 1224–1303 | 80 | `quintilla` | Quintilla | Octosilábica consonante | — | directa |
| 1304–1494 | 191 | `redondilla_regular` | Redondilla | Octosilábica | — | directa |
| 1495–1574 | 80 | `decima_espinela` | Décima | Espinela | — | directa |
| 1575–1798 | 224 | `redondilla_regular` | Redondilla | Octosilábica | — | directa |
| 1799–1876 | 78 | `terceto_encadenado` | Terceto encadenado | Endecasilábico consonante | — | directa |
| 1877–2052 | 176 | `romance_e-e` | Romance | Octosílabo | Vocales de la asonancia = e-e | rasgo + forma del padre |
| 2053–2227 | 175 | `quintilla` | Quintilla | Octosilábica consonante | — | directa |
| 2228–2381 | 154 | `romance_e-o` | Romance | Octosílabo | Vocales de la asonancia = e-o | rasgo + forma del padre |
| 2382–2851 | 470 | `redondilla_regular` | Redondilla | Octosilábica | — | directa |
| 2852–2969 | 118 | `romance_a-a` | Romance | Octosílabo | Vocales de la asonancia = a-a | rasgo + forma del padre |
| 2970–3013 | 44 | `redondilla_regular` | Redondilla | Octosilábica | — | directa |
| 3014–3071 | 58 | `romance_e-a` | Romance | Octosílabo | Vocales de la asonancia = e-a | rasgo + forma del padre |

## Subtipos estróficos

Pasan a ser unidades y secciones del modelo nuevo. La correspondencia de término existe;
lo que hay que revisar es la estructura, no el nombre.

| Subtipo | Rangos |
| --- | ---: |
| `quintilla_1_ababa` | 57 |
| `quintilla_2_abbab` | 2 |
| `quintilla_3_abaab` | 2 |

## Caracterizaciones por rango

Buena parte de estas no son caracterizaciones sino **desviaciones**, y en el modelo nuevo
se registran como tales. Las de medida —hipometría e hipermetría— no conservan el número
de sílabas observado, así que hay que revisarlas con quien las anotó.

| Tipo | Rangos |
| --- | ---: |
| `cantado` | 4 |
| `rima_defectuosa` | 2 |
| `hipometrico` | 1 |

