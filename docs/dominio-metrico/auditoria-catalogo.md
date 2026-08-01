# Auditoría del catálogo métrico

Estado: **para revisar** · 1 de agosto de 2026

> Las correcciones de documentación ya están aplicadas; las de base de datos, no. El
> resumen final dice qué queda en cada sitio.

El [informe de conformidad](./informe-conformidad-catalogo.md) está en cero defectos, pero
solo comprueba las doce reglas que sabe comprobar. Esta auditoría mira lo que esas reglas no
alcanzan: si la implementación es coherente con la
[ontología](./ontologia-verso-espanol.md), si hay huecos, y si las fichas de forma dicen la
verdad sobre el catálogo.

Se ha contrastado el dato de la base contra la ontología, contra el
[vocabulario heredado](./historico/vocabulario-heredado.md) y contra la bibliografía del
repositorio. **No se ha modificado nada.**

Inventario en el momento de auditar: 25 formas y 2 tramos sin forma · 46 arquitecturas ·
50 esquemas métricos · 66 esquemas de rima · 57 secciones · 58 grupos de elección ·
358 opciones · 8 variedades · 16 denominaciones · 7 relaciones · 6 rasgos con 27 valores.

---

## A · El mismo hecho en dos niveles

Es el sexto de los errores que el modelo dice evitar, y el que más cuesta ver.

### A1 · «Todos los versos de la unidad miden lo mismo» se decía de dos maneras · **RESUELTO**

> Aplicado en `20260801100000_esquema_isosilabico_es_ciclo.sql`. Los diecinueve esquemas
> desarrollados pasan a ciclo de una posición: 111 filas menos y ningún esquema isosilábico
> declarado dos veces. La regla queda escrita en la implementación.

De las 22 arquitecturas isosilábicas con unidad cerrada, **19 lo declaran como secuencia
fija con una posición por verso** y **3 como secuencia repetible con una sola posición**:

| Arquitectura | Unidad | Cómo lo dice |
| --- | ---: | --- |
| `soneto · endecasilabico_consonante` | 14 | repetible · 1 posición |
| `sextina · clasica` | 39 | repetible · 1 posición |
| `sextina · doble` | 75 | repetible · 1 posición |
| `octava_real`, `decima_espinela`, `decima_aumentada`, `copla_real`, `novena` ×2, `quintilla`, `terceto`, `redondilla` ×4, `sextilla` ×3, `sexteto` ×3, `copla_de_arte_mayor` | 3–12 | fija · N posiciones |

**Regla decidida:** el tipo del esquema dice **si es un ciclo o una secuencia**, no cuántos
versos abarca. Un esquema isosilábico se declara con una posición repetida y la extensión la
sigue diciendo la arquitectura. `secuencia_fija` queda para los esquemas en que las medidas
cambian.

Se consideró la regla contraria —desarrollar cada verso— y se descartó por su precio: la
sextina doble habría necesitado setenta y cinco posiciones y un slug de doscientos
veinticuatro caracteres. Un identificador así es un accidente, no una clave.

No se tocan los ciclos heterométricos —`8-8-4` de la sextilla de pie quebrado, `7-5` de la
seguidilla, `7-11` del sexteto-lira—: el sexteto-lira tiene cinco esquemas y solo uno es
cíclico, así que declararlo distinto de sus hermanos empeoraría la comparación.

**La canción petrarquista no estaba mal.** Su sección «Estancia regular» ya apunta al esquema
de trece posiciones por `esquema_metrico_id`, y la sección «Estancia» de la arquitectura
variable hace lo mismo con el conjunto `7-11`. El esquema cuelga además de la arquitectura
porque la tabla lo exige, pero quien lo usa es la sección.

### A2 · El `grado` de una arquitectura se usaba con dos criterios · **RESUELTO**

> Aplicado en `20260801110000_vocabulario_unico.sql`, junto con la unificación completa que
> salió de aquí: cuatro escalas de normatividad pasan a una, dos de forma de la secuencia
> pasan a una, `ambito` baja de cinco valores a dos y `dimension` deja de decir `medida` en
> un sitio y `metro` en otro.

| Grado | Cuántas | Cuáles |
| --- | ---: | --- |
| `canonica` | 23 | soneto, terceto, quintilla, romance ×4, seguidilla ×2… |
| `admitida` | 18 | redondilla hepta y hexasilábica, silva ×3, sexteto ×2… |
| `fija` | 5 | octava real, espinela, aumentada, lira, redondilla doble |

El eje completo es `fija · canonica · admitida · rara · irregular_documentada`, y leído
entero es una escala de **autoridad normativa**: cuánta norma tiene esa realización dentro de
su forma. `fija` no está en esa escala: no dice cuánta autoridad tiene, dice que no admite
variación. Y eso es derivable —¿tiene preguntas estructurales o no?—.

El dato lo confirma. **24 arquitecturas no admiten ninguna variación estructural**, y de
ellas 5 son `fija`, 10 `canonica` y 9 `admitida`: no hay criterio, hay cinco casos marcados y
diecinueve idénticos sin marcar.

**Corrección decidida:** retirar `fija` y reasignar las cinco por su lugar en la forma.

| Arquitectura | Pasa a | Por qué |
| --- | --- | --- |
| octava real, espinela, aumentada, lira | `canonica` | única arquitectura de su forma |
| `redondilla · doble_enlazada` | `admitida` | no es la central; la octosilábica es la principal |

Que no admita variación se seguirá sabiendo, porque no tendrá preguntas.

### A3 · Las composiciones declaran su unidad, o no, según cuál

| Forma | Unidad declarada |
| --- | --- |
| `soneto` | 14–14 |
| `sextina` | 39–39 · 75–75 |
| `cancion_petrarquista` ×3, `villancico` ×2, `zejel` | **null** |

La diferencia es defendible —la extensión de un villancico no es fija— pero la convención
«null significa variable» no está escrita en ninguna parte y hace que la regla D4, que
comprueba que las secciones no contradigan la unidad, no pueda examinarlas.

---

## B · Huecos del modelo y de la validación

### B1 · Las secciones no tienen identificador legible

`estructuras_secciones` es la única entidad del catálogo sin `slug`. Todas las demás
—formas, arquitecturas, esquemas, rasgos, valores, variedades, metros— lo tienen.

Y `tipo_seccion` no sirve de sustituto porque **no es único**: la arquitectura
`villancico · estribillo_tras_primera_copla` tiene dos secciones `mudanza`, dos `copla` y dos
`enlace_vuelta`.

Se ve el efecto en las preguntas de medida que se acaban de crear:

```text
medida_mudanza          → «Mudanza»
medida_mudanza_2        → «Mudanza»
medida_enlace_vuelta    → «Enlace o vuelta»
medida_enlace_vuelta_2  → «Enlace o vuelta»
```

El `_2` lo generó la migración por orden de aparición. Si mañana se añade una sección
intermedia, el sufijo cambia de dueño en silencio.

También explica que las fichas del villancico y del zéjel se refieran a sus secciones por
`cabeza`, `mudanza`, `vuelta`, que no son slugs de nada.

**Las dos secciones repetidas del villancico no son un duplicado.** `estribillo_tras_primera_copla`
modela el villancico cuyo estribillo aparece después de la primera copla, así que el primer
ciclo es estructuralmente distinto de los siguientes:

```text
primer_ciclo                     ciclo_copla  (0..∞)
  copla                            copla
    mudanza                          mudanza
    enlace_vuelta                    enlace_vuelta
  estribillo (1.ª aparición)       represa (0..1)
```

Son secciones diferentes con padres diferentes. El modelo está bien; lo ambiguo es cómo se
nombran.

**Para qué sirve un slug.** Para la base, nada: el UUID basta. Sirve para que una migración
localice la fila sin incrustar un UUID, para que un documento la nombre sin ambigüedad, y
para que el catálogo sea comparable con otro si se exporta, porque un UUID solo vale en esta
base. La pregunta, por tanto, no es si todo lo necesita, sino si algo lo referencia desde
fuera de su fila. Las secciones sí: las apuntan las preguntas, las opciones, otras secciones
como padre, y las apuntarían las denominaciones.

### B2 · Las repeticiones tampoco tienen nombre ni slug

Diez filas en `repeticiones_metricas`, identificadas solo por UUID, `tipo` y `ambito`. Tres
de ellas son `villancico · estribillo_inicial · tipo=estribillo · ambito=seccion ·
fijeza=admitida` — **idénticas entre sí en todos los campos legibles**. Sin abrir la tabla de
opciones no hay manera de saber cuál es cuál.

### B3 · Una elección posicional puede señalar una posición que no existe

`copla_de_pie_quebrado` declara unidades de **5 a 12 versos** y ofrece 48 opciones que cubren
las **12 posiciones**. Nada impide responder «el verso 11 es tetrasílabo» en una copla de
cinco versos: `validar_posicion_opcion_eleccion_metrica` comprueba el alcance y la dimensión,
no que la posición quepa en la unidad.

Es la única forma con este riesgo, porque es la única con unidad variable y opciones
posicionales. La canción tiene posiciones hasta 20 y unidad `null`, así que ahí no hay contra
qué comprobar.

### B4 · Seis esquemas de rima no declaran su tipo

| Arquitectura | Esquema | Comentario |
| --- | --- | --- |
| `soneto · endecasilabico_consonante` | `abba` | Los cuartetos del soneto son consonantes |
| `villancico · estribillo_inicial` | `abba`, `abab` | Consonantes |
| `villancico · estribillo_tras_primera_copla` | `abba`, `abab` | Consonantes |
| `endecasilabo_suelto · endecasilabica` | `versos-sueltos` | Correcto: no hay rima que tipificar |

Los cinco primeros son omisiones, no decisiones. Los cuatro esquemas de tercetos del soneto
sí lo declaran; solo el de los cuartetos se quedó sin él.

### B5 · La canción petrarquista no tiene arquitectura principal

Es la única forma del catálogo con más de una arquitectura y ninguna marcada como principal.
El editor no tiene qué ofrecer por defecto.

### B6 · La seguidilla compuesta declara su metro dos veces

Su esquema propio es `7-5-7-5-5-7-5`, siete posiciones. Y su primera sección **reutiliza la
arquitectura `simple`**, que declara `7-5-7-5`. Las cuatro primeras posiciones están dichas
en dos sitios: si una cambiara, la otra no se enteraría.

Es el único caso de una sección que reutiliza otra arquitectura *y además* está cubierta por
el esquema métrico de la suya. La copla real y la novena, que también reutilizan, no declaran
esquema propio para esas posiciones… salvo que la copla real sí lo hace: su esquema
`8-8-8-8-8-8-8-8-8-8` cubre las diez posiciones y sus dos secciones reutilizan la quintilla.
**Son dos casos, no uno.**

---

## C · Las fichas de forma

Las 22 fichas cubren las 25 formas y los 2 tramos. No falta ninguna ni sobra ninguna. Lo que
falla es que muchas describen un estado anterior.

### C1 · Slugs de arquitectura obsoletos

La migración de nomenclatura renombró 52 arquitecturas y las fichas no se actualizaron:

| Ficha | Dice | Es |
| --- | --- | --- |
| canción petrarquista | `cuerpo_sin_rima_pareado_final` | `sin_rima_con_pareado_final` |
| décimas | `octosilabica_abbaaccddc` · `octosilabica_abbaaccddeed` | `octosilabica` en ambas formas |
| lira | `heptasilabica_endecasilabica_consonante` | `heptasilabica_endecasilabica` |
| romance · romance heroico · romancillo | `octosilabico_asonante` · `hexasilabico_romancillo` · `heptasilabico_romancillo` · `endecasilabico_heroico` | `octosilabico` · `hexasilabico` · `heptasilabico` · `endecasilabico` |
| seguidilla | `simple_7575_asonante` · `compuesta_7575575_asonante` | `simple` · `compuesta` |
| sextina | `clasica_6x6_mas_3` · `doble_12x6_mas_3` | `clasica` · `doble` |
| soneto | `endecasilabo_consonante` | `endecasilabico_consonante` |
| cuestiones para el IP | `novena_canonica` · `novena_invertida` | `redondilla_quintilla` · `quintilla_redondilla` |

### C2 · Nombres de tabla retirados

`patrones_rima` y `patron_rima` (hoy `esquemas_rima`) en novena, quintilla y soneto;
`combinaciones_patrones_configuracion` en sexteto-lira; `migracion_termino_destinos` en
novena; `forma_aliases` en redondilla. Todas retiradas o renombradas.

### C3 · Vocabulario antiguo en los ejemplos de registro

Las fichas de quintilla, soneto, villancico y zéjel muestran cómo quedaría un registro en las
tablas de producción y usan `secuencia_configuraciones`. Esas tablas todavía no existen, pero
el nombre arrastra «configuración», que es justo lo que se retiró del vocabulario.

### C4 · Dos fichas describen arquitecturas como si fueran formas

`romance-heroico.md` y `romancillo.md` están al mismo nivel que las fichas de forma, y hoy
describen **arquitecturas del romance**: `endecasilabico`, `hexasilabico`, `heptasilabico`.

Es el mismo caso que la sexta rima, cuya ficha se disolvió dentro de la del sexteto cuando
dejó de ser forma. Mantener estas dos separadas hace pensar que son formas del catálogo.

### C5 · Fechas y estados desactualizados

Once fichas siguen fechadas entre el 28 y el 30 de julio y describen decisiones anteriores a
los cambios de los días 30 y 31: décimas, lira, novena, octava real, quintilla, romance,
romance heroico, romancillo, seguidilla, sextina, soneto, sexteto-lira, villancico y zéjel.

---

## D · Contraste con la bibliografía

### D1 · El repertorio de la quintilla se contradice a sí mismo

El catálogo cierra ocho esquemas: `ababa`, `abbab`, `abaab`, `aabab`, `aabba`, `abbaa`,
`ababb` y `abbba` —este último marcado «Tipología 8 excepcional»—. La ficha ya pregunta al IP
por qué no está `aabaa`.

**Resuelto, y el repertorio es correcto.** El criterio no es el pareado final sino que
**ningún verso quede suelto**: con dos clases de rima sobre cinco posiciones, `aabaa` deja la
`b` sin pareja y por eso no es una quintilla. `abbaa` y `ababb` sí lo cumplen y solo son
infrecuentes; los ocho están ordenados de más a menos típico, y el octavo se marca
«excepcional» por eso.

El criterio queda escrito en la ficha y la pregunta al IP, cerrada.

### D2 · El terceto no contempla el monorrimo

El terceto tiene dos esquemas —`A-A` y `-AA`— que corresponden a los antiguos
`tercetos_sin_encadenar`. Falta la disposición en que los tres versos comparten rima, que la
tradición documenta. Puede ser una decisión de corpus, pero no está registrada como tal en
ninguna parte.

### D3 · El pareado ofrece metros que probablemente no le corresponden

Al abrirlo a «cualquier medida» recibió las nueve del catálogo × 2 posiciones = 18 opciones,
y entre ellas el **dodecasílabo compuesto 6+6**, que existe en el catálogo solo para la copla
de arte mayor. Un pareado de dodecasílabos compuestos es posible, pero conviene confirmar que
se quiere ofrecer.

### D4 · Nada se ha perdido del vocabulario heredado

El volcado de los 119 términos con su destino actual no deja ninguno sin traza. Los
movimientos posteriores —doble sextilla, sexta rima, tercetos sin encadenar, pareados
endecasílabos, copla manriqueña, pareado hexasílabo y octosílabo— están todos anotados en las
fichas correspondientes. La única pérdida real es de otro tipo y está en B1: los nombres que
la tradición da a **valores de rasgo**, como «silva libre», no tienen dónde vivir porque una
denominación no puede apuntar a un valor de rasgo.

---

## E · Documentos que conviene archivar

| Documento | Estado |
| --- | --- |
| `contrato-implementacion.md` | Fijaba qué cambiar antes de corregir datos en la migración estructural. **Aplicado y cerrado**: sus condiciones de seguridad son las únicas que siguen valiendo, y esas están en el contexto |
| `revision-nomenclatura.md` | Tabla de 193 filas, **aplicada**. Es registro histórico de qué se renombró y por qué |
| `contraste-estructural.md` | Su análisis está actuado: los vecindarios y los cambios de nivel llevaron a las decisiones de los días 30 y 31. Queda como instantánea |
| `sintesis-narrativa-dominio-metrico.md` | Presentaba el problema antes de resolverlo. Sigue siendo útil para explicar el proyecto, pero describe el vocabulario anterior como si fuera el presente |

Los cuatro pueden pasar a `historico/`, salvo la síntesis narrativa si se quiere conservar
como texto de presentación, en cuyo caso hay que reescribirla en pasado.

---

## Resumen

### Hecho en los documentos

- Slugs de arquitectura y nombres de tabla obsoletos, corregidos en todas las fichas (C1, C2).
- Fechas y estados, al día (C5).
- `romance-heroico.md` y `romancillo.md` disueltos dentro de `romance.md` (C4).
- El criterio del repertorio de la quintilla, escrito, y su pregunta al IP cerrada (D1).

### Decidido, pendiente de migración

| Qué | Dónde |
| --- | --- |
| ~~El tipo del esquema métrico~~ **aplicado** | A1 |
| ~~Se retira `fija`~~ **aplicado**, con la unificación de vocabularios | A2 |
| Declarar el tipo de rima de los cinco esquemas que no lo tienen | B4 |
| Marcar una arquitectura principal en la canción petrarquista | B5 |

### Pendiente de decisión tuya

1. Dar `slug` a secciones y repeticiones, o asumir el coste de no tenerlo (B1, B2).
2. Validar que una posición quepa en la unidad, para la copla de pie quebrado (B3).
3. Escribir la convención de unidad `null` en composiciones de extensión variable (A3).
4. Resolver la doble declaración de metro en la seguidilla compuesta y la copla real (B6).
5. Archivar los cuatro documentos de E.

### Pendiente del IP

6. Si el terceto monorrimo entra en el catálogo (D2).
7. Qué medidas debe ofrecer el pareado (D3).
8. Si «Romance heroico» debe registrarse como denominación.
