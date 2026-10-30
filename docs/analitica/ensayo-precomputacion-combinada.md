# Ensayo local de precomputación combinada

29 de octubre de 2026. Primera prueba ejecutable del
[plan de productores](../importador-metrico/consultas-y-precomputacion.md), con las definiciones
del [inventario general](../inventario-medidas-analiticas.md). Afecta al diseño analítico de
detalladas y básicas; no es una nueva funcionalidad del editor.

**Actualización del 30 de octubre:** ensayo 0.2. Guardar confirma la segmentación, sin casilla
adicional. El [nuevo informe](./ensayo-precomputacion-2026-10-30.json) sustituye la interpretación
del marcador provisional del primer ensayo. Las formas pendientes excluyen solo sus límites
de los pares evaluables, sin computar como ausencia ni conectar artificialmente sus vecinos.
Verificación del 30: 84 pruebas y comprobación de tipos correctas; recálculo de las 16 entradas
extraídas el día anterior, sin cambios en sus perfiles de formas. No se repitió PostgreSQL porque
Docker estaba apagado; no se modificó SQL ni se escribió en Supabase.

**Solo local.** No instala funciones en Supabase, no cambia sus artefactos ni conecta lectores
de la web. Las básicas reales siguen fuera de sus análisis. No valida científicamente una
comparación de autoría ni implementa todas las medidas del inventario.

## Recorrido ejecutado

1. Restaurar la copia previa al importador, con prosa ya corregida, en una base efímera de Docker
   sin red ni puertos. No se reutiliza una base de trabajo existente.
2. Aplicar allí la migración y guardar las cuatro entradas del piloto mediante la RPC real.
   Solo estas operaciones de preparación escriben en la copia local.
3. Extraer mediante SELECT las doce detalladas publicadas de esa copia y las cuatro importaciones.
   Para v2 se usan `formas_de_la_obra` y `perfil_metrico_unidades`; para básicas, `datos_confirmados`.
   No se recuperan formas del vocabulario legado ni de los resúmenes anteriores.
4. Elegir una fuente por identidad de obra, traducirla a una entrada común y precomputar archivos.
   No mezclar metadatos de un borrador con la métrica de una importación anterior.
5. Contrastar los recuentos conocidos de cada detallada con `perfil_formas_rango`, y los de cada
   básica con el piloto preparado. Comprobar que las obras y artefactos originales de la copia
   siguen intactos. Eliminar la base efímera creada para el ensayo.

```powershell
node scripts/analitica/ensayar-precomputacion.mjs --copia backups/supabase/20261029-importador-despliegue-E1TlVQ/ensayo --salida backups/analitica-ensayo-20261029
npx vitest run scripts/lib/analitica/aportaciones.test.mjs scripts/lib/importador-metrico/ficha-minima.test.mjs
```

Resultados: **80 pruebas de código**, 28 del núcleo analítico, y ensayo PostgreSQL completado.
Los perfiles conocidos de las **12 detalladas coinciden** con el productor vigente. Esto verifica
esos recuentos, no todas las medidas ni la integridad editorial de cada ficha. Las detalladas
publicadas de la copia son material de prueba, no un corpus para conclusiones literarias.
El [informe resumido](./ensayo-precomputacion-2026-10-29.json) no incluye identidades privadas.

## Contrato del ensayo

El núcleo está en `scripts/lib/analitica/aportaciones.mjs`, sin importarse en las páginas.
El extractor SQL es una entrada de ensayo, no una migración ni una nueva API pública.

- Una detallada publicada sustituye a la básica de la misma obra antes del agregado. No se agrupa
  por título ni se completan vacíos desde la otra fuente. Durante la elaboración, la copia básica
  seleccionada aporta su propia edición, datación y estructura.
- Se conservan autorías de obra y jornada. El referente recorta por sus rangos, rechaza solapamientos
  y no duplica obra y jornadas del mismo autor. Excluir la obra excluye todas sus jornadas.
- Los rangos deben cubrir el ámbito sin huecos ni solapes. Una fuente inválida se registra como
  excluida, no como una obra con cero versos. Las incidencias no se silencian.
- Se calculan extensión, perfil de formas, parte pendiente, cobertura de arquitecturas y diversidad
  exacta únicamente con clasificación completa. Aislados e irregularidad identificados cuentan
  como clases. Una Canción conocida sin arquitectura sigue contando como Canción.
- La proporción confirmada conserva toda la extensión como denominador. La proporción total
  desconocida es `null` con motivo. Un cero confirmado no demuestra ausencia exacta mientras
  queden versos por identificar. No hay imputaciones ni probabilidades.
- Las lagunas cuantificadas y atribuidas se mantienen en la extensión, con recuento separado de
  posiciones reconstruidas, deduplicadas por unión. Las adiciones tampoco se restan: el ajuste
  normativo no cambia las posiciones existentes de la fuente.
- Los límites provisionales aportan formas por rango, pero no un número definitivo de secuencias,
  densidad ni transiciones. Con límites confirmados se incluyen los cambios de jornada. Una forma
  pendiente no se salta para inventar una transición entre sus vecinas conocidas. Se aprovechan
  aperturas y cierres identificados aunque el interior esté pendiente.
- El referente descriptivo pondera por extensión. La cronología usa solapamiento inclusivo, sin
  convertir intervalos en fechas puntuales. Una fecha ausente impide ese filtro, pero no convierte
  la obra en cero ni la excluye de un perfil sin filtro cronológico.

Se generan archivos internos separados: fuentes extraídas, aportaciones traducidas, perfiles de
obra y referente de Lope, más informe y manifiesto. Este identifica versión, huellas de entradas
y código, y hashes del contenido y de los archivos. No hay manifiesto activo ni publicación.
El determinismo comprobado es sobre **la misma entrada extraída**; cada restauración local recibe
UUID nuevos al importar. Los archivos privados quedan en `backups/`, fuera de Git.

## Resultado del piloto

| Obra | Extensión | Forma pendiente | Filas de origen |
| --- | ---: | ---: | ---: |
| El molino | 2992 | 9 | 21 |
| El verdadero amante | 2878 | 0 | 19 |
| Los donaires de Matico | 2812 | 272 | 18 |
| Los locos de Valencia | 3072 | 0 | 20 |

El modelo básico **permite este perfil de formas**, manteniendo la información pendiente y sin
necesitar los campos editoriales ajenos a la métrica. Se conservan detalles y desviaciones en la
entrada, pero aún no se homologan todos los rasgos y realizaciones v2 para agregarlos.

Dos hallazgos requieren continuidad:

- El primer ensayo detectó el marcador provisional que se conservaba al guardar. Resuelto por
  el acuerdo del 30 de octubre: el propio guardado confirma los límites. El ensayo 0.2 aplica
  también esta interpretación a las copias anteriores sin reescribirlas. Los pares con forma
  pendiente no entran en el denominador evaluable de las transiciones.
- En siete detalladas publicadas de prueba hay once secuencias sin anotación v2. Se señala la
  discrepancia con la regla editorial de publicación íntegra. Sus posiciones quedan con forma
  pendiente, sin asignarles el vocabulario legado ni cambiar su estado. El diagnóstico detallado
  queda en los archivos privados. No se han corregido datos de la base real.

El referente de Lope de esta copia recibe solo las cuatro básicas: las autorías elegibles de las
detalladas de prueba no aportan a ese autor. La mezcla básica + detallada bajo un mismo autor se
verifica aparte mediante un control sintético con resultado conocido. No se presenta ese referente
de cuatro obras como el corpus de Lope ni como una comparación científica validada.

## Lo que aún no acredita

**Avance del 30 de octubre:** los adaptadores y los resúmenes de arquitectura, rasgos, remates,
esquemas, metro y desviaciones están implementados y probados en el [ensayo 0.3](./datos-comparables.md).
El párrafo siguiente identifica el alcance del primer ensayo; los detalles y límites actuales
figuran en ese nuevo documento. La integración con productores y lectores reales sigue pendiente.

Faltan los adaptadores y denominadores específicos de rasgos, rima, realizaciones, fenómenos y
cuadros; la distribución por obras con mediana/cuartiles; la comparación bajo identificación
parcial y el experimento de sensibilidad. La prosa se conserva como evidencia de localización:
este núcleo no mide su extensión ni trata el silencio como ausencia.

Después hay que integrar generación, invalidación, activación coherente y permisos en los
productores y consumidores reales. Este contrato no sustituye los contratos actuales. La prueba
no fija que el productor definitivo deba ejecutarse en Node en lugar de SQL: el comportamiento
y sus controles deben conservarse al integrarlo.

Ampliar a veinte obras probará variedad, extracción, equivalencias y corrección. No exige montar
antes todas las pantallas ni resolver ya la afinidad. El corpus y el experimento posteriores
serán necesarios para el artículo.
