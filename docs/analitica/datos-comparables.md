# Datos métricos adicionales comparables

30 de octubre de 2026. Implementado y ejecutado en el ensayo local **0.3**, después del
[primer perfil común](./ensayo-precomputacion-combinada.md). No modifica la base compartida,
las copias importadas ni los análisis de la web. No añade preguntas al importador.

La forma sigue siendo el núcleo común. Los datos adicionales se aprovechan donde existen,
sin exigirlos para incluir una básica en el perfil de formas ni completar arquitecturas por
su frecuencia habitual. Una equivalencia revisada podrá aportar arquitectura; que sea la más
frecuente no permite asignarla automáticamente.

## Qué se traduce

| Dato | Básica | Detallada v2 |
| --- | --- | --- |
| Arquitectura | Identificación explícita de la secuencia | Cabecera y rangos con arquitectura realizada diferente; sin duplicar posiciones |
| Rasgos | `rasgo_slug` y `valor_slug`, incluida la asonancia | Elección resuelta al rasgo/valor o respuesta de texto controlado, número o booleano |
| Remate | Sección final con número de versos | Realización efectiva de una sección de tipo remate, con su rango |
| Metro observado | Medida de una desviación documentada | Elecciones de metro y medida observada de desviaciones |
| Esquemas métricos y rima | El contrato básico 0.2 no tiene campos autónomos de esquema; los literales se conservan como texto | Esquemas elegidos y disposiciones libres anotadas, conservando mayúsculas de rima |
| Repeticiones y variedades | Cuando corresponda un rasgo explícito, se conserva como tal; no se inventa otro destino | Elección de repetición o de combinación con identidad y contexto de catálogo |
| Desviaciones | Metro y estructura, con relación, rango y medida conocida | Todas las dimensiones admitidas por v2 y sus valores observados |

No se transforma un literal en una respuesta. «Romance en -io» ya interpretado como
`vocales_asonancia / i-o` aporta el rasgo; un literal sin normalizar permanece como texto.
Un dístico final registrado como rasgo no se transforma en una sección de remate.
Los remates 3+1 de tercetos conservan **un** verso de remate.

La información normativa de una arquitectura no equivale a una observación. No se cuentan
versos de 7 y 11 porque una silva admita ambas medidas. Una sección de remate definida en el
catálogo, pero sin realización registrada, tampoco produce por sí sola un remate observado.

## Ámbito, recuento y cobertura

Cada dato conserva forma, arquitectura, dimensión, propiedad, valor y ámbito: secuencia,
realización, sección descrita, posición de unidad o rango. Un dato por posición no se atribuye
a toda la secuencia. Dos esquemas homónimos de arquitecturas diferentes permanecen separados.
Una referencia rota genera incidencia, nunca una etiqueta inventada. El ensayo exige cero
incidencias de traducción antes de declararse correcto.

- La cobertura indica secuencias con evidencia, ausencias comprobadas y secuencias sin dato.
  El silencio de la básica no se convierte en ausencia. En detalladas publicadas con anotación
  v2, una lista vacía de desviaciones conserva el cero analizado; una secuencia sin v2 no.
- Las presencias por secuencia se deduplican aunque se repitan en varias realizaciones. Se
  conservan las evidencias individuales para no perder el detalle.
- La proporción entre secuencias con dato es descriptiva de ese subconjunto, no una prevalencia
  de toda la obra. No se reparte lo desconocido. Los valores pueden coexistir: no se fuerza
  que formen categorías mutuamente excluyentes.
- Se conserva la escala de recuento del rasgo. Para escala por verso se preparan numerador,
  denominador y proporción sobre las **posiciones de los ámbitos anotados**, deduplicadas por
  unión. No se sustituye ese cálculo por una proporción por secuencias ni se interpreta como
  número de versos que efectivamente riman. Sin rango cuantificable el resultado es nulo.
- Remates y desviaciones tienen extensión documentada por unión de rangos. Un solape no se
  cuenta dos veces. En las lagunas esa extensión sigue identificada como reconstruida por la
  relación `falta`; no se suma otra vez al total ni se retira del perfil de su forma.
- Los perfiles de arquitectura mantienen la extensión de su forma como denominador, con
  cobertura independiente. Una realización intercalada sustituye la arquitectura de cabecera
  en su rango. Un conflicto se deja pendiente y señalado, sin doble cómputo.

En el referente de un autor se conserva la selección de una fuente por obra y la exclusión de
la obra contrastada. La autoría por jornada recorta arquitectura y posiciones. Los datos
adicionales cuyo ámbito completo no puede atribuirse a esa parte se dejan fuera del recuento
positivo; no se convierten en ausencia. El resultado declara si analiza secuencias enteras o
las partes atribuidas de ellas. Las referencias de secuencia incluyen la obra para evitar
colisiones entre nombres locales de importaciones diferentes.

## Verificación ejecutada

**109 pruebas** del núcleo analítico y del contrato básico. Incluyen equivalencia básica/v2,
rasgos por secuencia y por verso, cero y falso explícitos, arquitectura intercalada, rima libre
y de catálogo, posiciones, remates, desviaciones, referencias rotas y recorte de autoría.

Se volvió a ejecutar PostgreSQL en Docker aislado sobre la copia con **12 detalladas y cuatro
básicas**: ninguna elección quedó sin traducir, los perfiles conocidos de formas coinciden con
el productor vigente y las fuentes y artefactos previos permanecen intactos. La repetición del
cálculo sobre la misma extracción es determinista. Las detalladas de esa copia son fichas de
prueba; no validan un hallazgo literario. Las once secuencias sin v2 ya señaladas siguen siendo
una incidencia editorial separada de la traducción de elecciones existentes.

El [informe resumido](./datos-comparables-2026-10-30.json) recoge los datos del piloto:

- *El molino*: dístico final en dos secuencias.
- *El verdadero amante*: dístico final en tres, asonancia i-o en una, remate de Canción de dos
  versos y dos remates 3+1 de tercetos, de un verso cada uno.
- *Los locos de Valencia*: asonancia a-e, desviación al heptasílabo y adición estructural.
- *Los donaires de Matico*: sin datos adicionales estructurados; no se convierten en ceros.

## Código y reproducción

`scripts/lib/analitica/datos-comparables.mjs` traduce y prepara los datos. El extractor SQL
local resuelve las referencias desde el catálogo de la misma copia, no desde listas de nombres
supuestos. El manifiesto incorpora también la huella del nuevo módulo.

```powershell
npx vitest run scripts/lib/analitica scripts/lib/importador-metrico/ficha-minima.test.mjs
node scripts/analitica/ensayar-precomputacion.mjs --copia backups/supabase/20261029-importador-despliegue-E1TlVQ/ensayo --salida backups/analitica-datos-comparables-20261030
```

Las entradas, documentos completos y manifiesto permanecen en `backups/`, fuera de Git.
No se ha ampliado el formato de anotación básica ni aplicado una migración. Los futuros casos
que requieran nuevos campos estructurados necesitarán una ampliación explícita de su contrato;
no se resolverán escondiendo datos en notas ni atribuyéndoles un valor estadístico.

Este bloque prepara los datos y sus resúmenes seguros. Sigue pendiente conectar el productor
definitivo, su invalidación, activación coherente y permisos con los lectores de la web. También
siguen pendientes las distribuciones por obras, el método de afinidad bajo identificación
parcial y el experimento de sensibilidad. Los fenómenos y caracterizaciones ajenos al contrato
básico no se rellenan desde estas anotaciones métricas.
