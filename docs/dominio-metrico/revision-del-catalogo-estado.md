# Revisión del catálogo contra las fuentes · dónde vamos

Actualizado: 6 de agosto de 2026 · **12 formas revisadas de 28**

Este documento dice **en qué punto está la revisión del catálogo métrico y cómo se continúa**.
Es el único sitio donde se lleva la cuenta. Si retomas el trabajo, empieza aquí.

---

## Qué es esta revisión

El catálogo métrico se pobló importando el vocabulario legado del proyecto. Esa importación
trajo los datos, pero no su justificación: las definiciones eran de redacción propia y las
fuentes bibliográficas estaban sin contrastar o directamente ausentes.

La revisión consiste en **recorrer forma por forma y contrastarla con seis monografías**,
corrigiendo el dato cuando la bibliografía demuestra que estaba mal. No es una revisión de
estilo: en lo que va de proceso han aparecido errores de fondo —una serie registrada como
estrofa, rimas que afirmaban dos clases donde hay una, arquitecturas que faltaban—.

Al terminar, cada forma debe tener:

- una **definición** que sostenga lo que dice el dato;
- **afirmaciones de fuente** con localizador, una por cada cosa que la bibliografía dice;
- **arquitecturas, esquemas, rimas y rasgos** que respondan a los criterios de nivel;
- un **contrato del registrador**, es decir, qué se deriva y qué pregunta el editor;
- y su ficha `.md` **borrada**, porque el catálogo pasa a ser el documento vivo.

## Las seis fuentes, y por qué solo seis

| Fuente | Volcado en `bibliografía/txt/` |
| --- | --- |
| Morley y Bruerton 1968, *Cronología de las comedias de Lope de Vega* | no hay volcado |
| Quilis 1969, *Métrica española* | `Quilis-1969-metrica-espanola.txt` |
| Navarro Tomás 1972, *Métrica española* | `Navarro-Tomas-1972-metrica-espanola.txt` |
| Domínguez Caparrós 2014, *Métrica española* | `Dominguez-Caparros-2014-metrica-espanola.txt` |
| Domínguez Caparrós 2016, *Diccionario de métrica española* | `Dominguez-Caparros-1999-diccionario-metrica.txt` |
| Jauralde Pou 2020, *Métrica española* | `Jauralde-Pou-2020-metrica-espanola.txt` |

**El fichero del Diccionario dice 1999 en su nombre y es la 3.ª edición de 2016.** El nombre
está mal; la fuente en la base es correcta.

Antes había once fuentes. Las otras cinco se retiraron porque no cumplían el criterio de
autoridad —publicación bibliográfica académica identificable—, y con ellas se fueron siete
afirmaciones que aún no se han recuperado en las seis autorizadas: villancico, redondilla
doble, zéjel, copla de pie quebrado, copla real y décima. **Eso sigue pendiente.**

### Cómo se localiza un pasaje

`node scripts/lib/localizar.mjs <fichero> "<texto literal>"` devuelve la página. Funciona con
Caparrós 2014, el Diccionario y Quilis (que da pares, porque el PDF escaneó pliegos dobles).

**No funciona con Navarro Tomás ni con Jauralde.** El primero conserva 37 números de página en
todo el libro: se cita por `§` numerado. El segundo viene de un epub sin paginar: se cita por
el título de la sección. El Diccionario, alfabético, se cita `s. v. «entrada»`.

---

## Estado forma por forma

**Revisada** significa contrastada con las seis fuentes, prosa reescrita, ficha `.md` borrada.

| Forma | Fuentes | Afirmaciones | |
| --- | ---: | ---: | --- |
| Romance | 6 | 7 | revisada |
| Redondilla | 6 | 9 | revisada |
| Décima | 6 | 7 | revisada |
| Silva | 6 | 7 | revisada |
| Soneto | 6 | 7 | revisada |
| Quintilla | 6 | 6 | revisada |
| Lira | 6 | 6 | revisada |
| Octava real | 6 | 6 | revisada |
| Cuarteto | 6 | 7 | revisada |
| Pareado | 6 | 6 | revisada |
| Terceto encadenado | 5 | 5 | revisada |
| Endecha real | 5 | 12 | revisada |
| Terceto | 3 | 3 | revisada · las otras tres fuentes no lo tratan aparte |
| Canción petrarquista | 1 | 1 | **pendiente** |
| Copla de arte mayor | 1 | 1 | **pendiente** |
| Novena | 1 | 1 | **pendiente** |
| Seguidilla | 1 | 1 | **pendiente** |
| Sexteto | 1 | 1 | **pendiente** |
| Sexteto-lira | 1 | 1 | **pendiente** |
| Sextilla | 1 | 1 | **pendiente** |
| Sextina | 1 | 1 | **pendiente** |
| Villancico | 1 | 1 | **pendiente** |
| Copla de pie quebrado | 0 | 0 | **pendiente** |
| Copla real | 0 | 0 | **pendiente** |
| Zéjel | 0 | 0 | **pendiente** |
| Endecasílabo suelto | 1 | 1 | **pendiente · se deja para el final** |
| Versificación irregular | 1 | 1 | tramo sin forma |
| Verso aislado | 1 | 1 | tramo sin forma |

El endecasílabo suelto se dejó expresamente para el final por decisión del IP: es el más
problemático y conviene llegar a él con el resto resuelto. Los dos tramos sin forma no tienen
norma que contrastar; se revisan al final, con él.

### Orden sugerido para continuar

Las de estructura media primero, que son las más rápidas: **copla de pie quebrado, sextina,
novena, seguidilla**. Luego las compuestas: **villancico, zéjel, canción petrarquista,
sextilla, sexteto, sexteto-lira, copla real, copla de arte mayor**. Y al final el
**endecasílabo suelto** con los dos tramos sin forma.

---

## El procedimiento, forma por forma

1. **Leer el dato**, no la ficha: qué arquitecturas, esquemas, rimas, secciones, rasgos,
   denominaciones, relaciones y elecciones tiene hoy la forma.
2. **Buscar la forma en las seis fuentes** y leer los pasajes enteros, no la primera frase.
3. **Comparar y decidir**. Cuando la bibliografía contradice el dato, manda la bibliografía,
   salvo que el criterio del IP para el corpus sea deliberado y esté justificado.
4. **Escribir la migración**, con el razonamiento en la cabecera y una guarda al final que
   compruebe lo que acaba de escribirse.
5. **Aplicar** con `npm run db:push` y **verificar en vivo** consultando la base.
6. **Auditar** con `npm run audit:metrica` — introducir un defecto nuevo es fácil.
7. **Añadir la forma al contrato del registrador**, si no está: la auditoría lo comprueba.
8. **Borrar su ficha `.md`** y podar lo que quede resuelto en el registro de dudas.
9. **Commit**, en español, con el porqué en el cuerpo.

### Cómo consultar la base

`scripts/lib/consulta.mjs` exporta `query(sql)`. Desde un script del scratchpad hay que
importarlo con URL `file:///`, que en Windows es obligatorio para rutas absolutas.

### Criterios de la prosa

Están en [donde-vive-la-prosa.md](./donde-vive-la-prosa.md), son ocho y se aplican a todo lo
que se escribe en el catálogo. Los tres que más se olvidan:

- **Una afirmación de fuente dice lo que dice la fuente.** No opina sobre el catálogo ni
  explica qué hizo el proyecto con ese dato. Hay una guarda en migración que lo comprueba.
- **No se da por supuesto el contexto.** «Repite la definición del Diccionario» supone que el
  lector sabe que ese autor escribió un diccionario.
- **Los títulos de obra van en cursiva**, con Markdown: la prosa del catálogo lo admite y la
  ficha lo renderiza.

---

## Lo que esta revisión ha cambiado en el modelo

No estaba previsto, pero recorrer el catálogo destapó cosas del modelo. Todas aplicadas:

- **Bloque y sección no son lo mismo.** El bloque es la unidad de repetición y enlace —lo que
  cuenta `desplazamiento_bloque` y lo que separa `|`—; la sección es la parte con nombre, puede
  ser más fina que el bloque y existe aunque haya un solo bloque.
- **`tipo_alias` retirado.** Las denominaciones son nombres, sin más: no había manera
  defendible de clasificarlas.
- **`grado_especificacion` retirado.** Era andamiaje de un enfoque anterior del motor, nunca
  implementado. La clasificación que sirve es `nivel_estructural`.
- **Las relaciones entre formas se ven en la ficha pública**, que no las mostraba.
- **Una forma `serie` aparte solo se justifica cuando seriar cambia la estructura**, porque una
  estrofa ya se seria dentro de su propia forma.

### Y un defecto del modelo, abierto

`sincronizar_posiciones_esquema_rima_fijo` deriva las posiciones de la notación letra a letra y
**toma la caja por clase de rima**: de `-a-A` saca dos rimas donde hay una. La caja dice el arte
del verso, no con quién rima —la lira escribe `aBabB` y son dos rimas, no cuatro—. En la endecha
real hubo que corregirlo a mano. Volverá a pasar en cualquier rima entre arte menor y arte
mayor. Está anotado en [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md).

---

## Documentos que acompañan a esta revisión

- [criterios-de-nivel.md](./criterios-de-nivel.md) — **de lectura obligada** antes de decidir si
  algo es arquitectura, esquema, variedad o rasgo. Es lo que resuelve las dudas de fondo.
- [donde-vive-la-prosa.md](./donde-vive-la-prosa.md) — los ocho criterios de redacción.
- [contratos-registrador-formas-revisadas.md](./contratos-registrador-formas-revisadas.md) —
  qué deriva y qué pregunta el editor en cada forma revisada.
- [revisiones-formas/cuestiones-para-el-ip.md](./revisiones-formas/cuestiones-para-el-ip.md) —
  lo que sigue sin decidir. Se poda a medida que se resuelve.
- [informe-conformidad-catalogo.md](./informe-conformidad-catalogo.md) — se regenera con
  `npm run audit:metrica`.
- [plan-revision-del-catalogo.md](./plan-revision-del-catalogo.md) — el orden A/B/C/D y el
  registro de lo ya hecho en la fase A.

Las fichas `.md` de `revisiones-formas/` **están en retirada**: quedan solo las de las formas
sin revisar, y cada una desaparece cuando su forma se absorbe en el catálogo. Una ficha que
sobreviva a su revisión es un documento que se quedará viejo.
