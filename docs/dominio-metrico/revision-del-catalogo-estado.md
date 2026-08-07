# Revisión del catálogo contra las fuentes · dónde vamos

Actualizado: 7 de agosto de 2026 · **16 formas revisadas de 28**

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
| Morley y Bruerton 1968, *Cronología de las comedias de Lope de Vega* | sus definiciones, ya en `.md` |
| Quilis 1969, *Métrica española* | `Quilis-1969-metrica-espanola.txt` |
| Navarro Tomás 1972, *Métrica española* | `Navarro-Tomas-1972-metrica-espanola.txt` |
| Domínguez Caparrós 2014, *Métrica española* | `Dominguez-Caparros-2014-metrica-espanola.txt` |
| Domínguez Caparrós 2016, *Diccionario de métrica española* | `Dominguez-Caparros-1999-diccionario-metrica.txt` |
| Jauralde Pou 2020, *Métrica española* | `Jauralde-Pou-2020-metrica-espanola.txt` |

**El fichero del Diccionario dice 1999 en su nombre y es la 3.ª edición de 2016.** El nombre
está mal; la fuente en la base es correcta.

El directorio `bibliografía/` está fuera de git. Si faltan los volcados se regeneran con
`pdftotext -layout -enc UTF-8`; el epub de Jauralde se extrajo descomprimiéndolo y limpiando
etiquetas. **`metrica-clasificacion.pdf` no sirve para esto**: es un artículo sobre repertorios
métricos, no un manual de definiciones.

**Morley y Bruerton describen a Lope**, no el Siglo de Oro entero, y el catálogo es
deliberadamente más amplio en varios puntos —la redondilla cruzada, la copla real—. Esa
diferencia se registra como afirmación propia; no es un desacuerdo que haya que ocultar.

La revisión de las seis fuentes es **exhaustiva, no selectiva**. Cada fuente que menciona una
forma recibe su propia afirmación, aunque repita sustancialmente lo dicho por otra. Las
diferencias, variantes y aspectos no formalizados se destacan en el resumen, pero la
coincidencia entre autores nunca es motivo para omitir una fuente. Una fuente solo queda fuera
de una forma cuando, después de revisar el pasaje y su contexto, no la trata.

Antes había once fuentes. Las otras cinco se retiraron porque no cumplían el criterio de
autoridad —publicación bibliográfica académica identificable—, y con ellas se fueron siete
afirmaciones que aún no se han recuperado en las seis autorizadas: villancico, redondilla
doble, zéjel, copla de pie quebrado, copla real y décima. **Eso sigue pendiente**, y se
resuelve al revisar cada una de esas formas.

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
| Novena | 4 | 4 | fuentes revisadas · separación y apertura aplazadas |
| Seguidilla | 1 | 1 | **pendiente** |
| Sexteto | 1 | 1 | **pendiente** |
| Sexteto-lira | 1 | 1 | **pendiente** |
| Sextilla | 1 | 1 | **pendiente** |
| Sextina (estrofa y composición) | 6 | 7 | revisada |
| Villancico | 1 | 1 | **pendiente** |
| Copla de pie quebrado | 6 | 6 | revisada |
| Copla real | 0 | 0 | **pendiente** |
| Zéjel | 0 | 0 | **pendiente** |
| Endecasílabo suelto | 1 | 1 | **pendiente · se deja para el final** |
| Versificación irregular | 1 | 1 | tramo sin forma |
| Verso aislado | 1 | 1 | tramo sin forma |

El endecasílabo suelto se dejó expresamente para el final por decisión del IP: es el más
problemático y conviene llegar a él con el resto resuelto. Los dos tramos sin forma no tienen
norma que contrastar; se revisan al final, con él.

### Orden sugerido para continuar

Las de estructura media primero, que son las más rápidas: **seguidilla**. Luego las
compuestas: **villancico, zéjel, canción petrarquista,
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

### Qué buscar en cada forma, además de las fuentes

1. **Definiciones que son decisiones del proyecto.** «El catálogo reconoce realizaciones de
   seis, siete y ocho sílabas» es una decisión, no una definición de la redondilla: su sitio es
   la descripción de cada arquitectura.
2. **Descripciones que repiten la definición** de su forma, palabra por palabra o casi.
3. **Razonamientos que solo viven en la ficha `.md`** y no en el dato. Si merecen sobrevivir,
   su sitio es el catálogo; si no, se van con la ficha.
4. **Dónde el proyecto se aparta de la bibliografía**, que merece afirmación propia.
5. **Las afirmaciones perdidas** con las cinco fuentes retiradas, si la forma es una de las
   seis afectadas.

### Lo que un cambio en el catálogo puede romper

| | Cómo se comprueba |
| --- | --- |
| **Catálogo público** `/formas` | Se genera del dato: cambia solo |
| **Demarcador** | Se compila del catálogo; subir `catalogo_metrico_estado.revision` lo marca desactualizado |
| **Editor V2** | Lee nombres de opciones y esquemas: un renombrado se ve ahí |
| **Equivalencias** | `select via, count(*) from propuesta_metrica_secuencia group by via` — deben seguir siendo 212 |
| **Respuestas propuestas** | `select count(*) from propuesta_elecciones_secuencia` — deben seguir siendo 91 |

**Y una regla que vale para todo**: no fiarse de las migraciones para saber qué hay. Consultar
siempre el catálogo en vivo y leer el esquema de las tablas antes de sacar conclusiones. Las
migraciones solo cuentan lo que pasó aquel día.

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

### Defectos del modelo aplazados

**Los esquemas abiertos necesitan una representación paramétrica general.** Las formas muy
estructuradas declaran medidas y rimas por posición; las más libres acaban repartiendo su
norma entre conjuntos permitidos, prosa y preguntas editoriales declaradas a mano. Cuando
termine la revisión filológica de las 27 formas, hay que comparar juntas todas estas formas
difíciles y diseñar restricciones computables —sin enumerar cada realización posible y sin
debilitar el modelo posicional de las formas fijas—. No se resolverá este problema adaptando
el modelo por separado a cada forma durante la revisión.

**La Novena general y la copla novena deben separarse al resolver ese modelo abierto.**
Caparrós y el *Diccionario* llaman novena a cualquier estrofa de nueve versos y niegan que
comparta necesariamente otra norma; Navarro Tomás y Jauralde caracterizan la copla novena
histórica como redondilla y quintilla, normalmente 4+5 y también 5+4. La copla novena tendrá
identidad de forma subordinada, no de arquitectura, y recibirá las dos arquitecturas actuales.
La separación no se aplica todavía porque falta decidir cómo hacer registrable y demarcable la
Novena general sin clasificar por defecto cualquier pasaje de nueve versos.

**La modalidad y la primacía necesitan una lectura transversal.** Al terminar la revisión de
las formas hay que comprobar que `principal` y los valores de modalidad —`definitoria`,
`preferente`, `admitida`, `excepcional`, etc.— significan y se usan igual en todo el catálogo,
y aclarar qué relación existe entre ambos mecanismos. No se normalizarán forma por forma.

**Hay que precisar qué hereda y qué puede restringir una reutilización.** El soneto reutiliza
el terceto aunque determina la rima de sus dos secciones, mientras el remate de la sextina
coincide con él en medida y extensión pero no en su norma consonante. Al cerrar la revisión
hay que auditar juntas todas las secciones reutilizadas y decidir si una composición puede
sobrescribir explícitamente parte de la arquitectura referenciada, si `Terceto` debe tener una
definición más amplia o si hace falta otra relación. No se corregirá un caso aislado antes de
resolver el significado general de la reutilización.

**La caja de las letras no es la clase de rima.**

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
- [historico/plan-revision-del-catalogo.md](./historico/plan-revision-del-catalogo.md) — el
  diario de la fase A, ya cerrada: la normalización de nombres y la corrección de la caja de la
  rima. Archivado; su método vigente está fundido en este documento.

Las fichas `.md` de `revisiones-formas/` **están en retirada**: quedan solo las de las formas
sin revisar, y cada una desaparece cuando su forma se absorbe en el catálogo. Una ficha que
sobreviva a su revisión es un documento que se quedará viejo.
