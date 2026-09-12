# Comparativas del corpus: laboratorio primero, ficha después

Decisión de producto y datos cerrada el 12 de septiembre de 2026.

## Principio

El laboratorio es el lugar donde se descubren y se ponen a prueba comparaciones. La ficha pública
no es una versión reducida del laboratorio: solo debe incorporar las pocas referencias que ayuden a
entender una obra concreta. Por eso se separan tres capas:

1. `obra_analisis` conserva hechos compactos y agregados de una obra;
2. `corpus_comparativas` conserva el banco de trabajo transversal, con una fila compacta por obra y
   distribuciones ya calculadas;
3. una futura proyección pública por obra contendrá únicamente las comparaciones aprobadas para la
   ficha.

El alcance `publico` de `corpus_comparativas` nombra su **universo estadístico** —obras publicadas y
visibles—, no el permiso del documento. Las dos variantes del corpus son privadas por RLS y solo
admin/IP puede leerlas. Un visitante no debe poder descargar desde una ficha la matriz completa ni
los listados transversales usados por el laboratorio.

## Orden de trabajo

1. **Infraestructura:** materializar medidas generales y valores por obra en JSON, sin construir
   una columna nueva en `obras_resumen` por cada pregunta.
2. **Laboratorio privado:** sustituir su carga relacional actual por los artefactos y crear vistas
   exploratorias. Allí se comprobará qué medidas son estables, comprensibles y filológicamente
   útiles, con filtros por periodo, autoría, género y alcance cuando haya corpus suficiente.
3. **Selección editorial:** decidir para cada medida si tiene sentido en la ficha, cuál es su
   denominador y a partir de qué tamaño/cobertura puede redactarse.
4. **Proyección pública:** generar un documento pequeño por obra —clave prevista
   `obras/{id}/comparativas/publico.json`— que no contenga la matriz ni permita reconstruirla. Su
   contrato y su tipo se crearán cuando se cierre la primera selección, no antes.

Las 11 obras visibles actuales son datos de prueba generados. Sirven para validar cálculo,
permisos y visualización; no permiten presentar resultados como hallazgos sobre el teatro español.

## Banco de trabajo materializado

`corpus_comparativas` V2 ofrece:

- una fila por obra con identidad mínima, datación, género, autores, visibilidad, medidas escalares,
  perfil de formas, articulación dramática, enunciación, fenómenos y transiciones;
- media, cuartiles, mediana, extremos y tamaño de muestra para diversidad, densidad, longitud media
  de secuencia, número de formas y jornadas, tradición italiana, falta de forma anotada y relación
  entre cambios de cuadro y cambios de secuencia;
- por forma: prevalencia entre obras, peso proporcional —incluidos los ceros—, número de secuencias
  y longitud media cuando la forma está presente;
- por transición: prevalencia, ocurrencias totales y distribución de ocurrencias por obra con ceros;
- por fenómeno respondido: distribución de `Sí / (Sí + No)`, sin convertir lo no respondido en `No`;
- por tipo de enunciación: presencia anotada y distribución del porcentaje de versos;
- frecuencias de formas de apertura, cierre y pareja apertura–cierre de jornada.

Los hechos de arquitectura, esquemas, metros, rasgos, variedades y desviaciones siguen disponibles
en `obra_analisis`. No se agregan al corpus por adelantado: el laboratorio decidirá primero qué
pregunta concreta justifican y con qué unidad deben contarse.

## Qué ensayar en el laboratorio

- distribuciones y puntos por obra para cada medida, mostrando siempre `n` y cobertura;
- selección de una obra para ver qué rasgos explican su posición, sin convertirlos en una
  clasificación automática de «normal» o «rara»;
- perfiles de formas y tradición por periodo, autoría o género;
- transiciones por difusión entre obras y por intensidad dentro de las obras que las usan;
- relación entre cortes dramáticos y cortes métricos;
- fenómenos por secuencia y enunciación, separando ausencia, respuesta negativa y falta de dato;
- aperturas y cierres de jornada solo si aparecen patrones repetidos y no coincidencias aisladas;
- más adelante, arquitecturas y elecciones internas de las formas, una vez fijada su unidad de
  comparación.

## Selección prevista para la ficha

No habrá una pestaña independiente de comparativas. Serán una segunda línea de lectura dentro de
los gráficos existentes:

- **De un vistazo:** una única línea «Frente al corpus publicado» para diversidad y densidad; como
  máximo dos observaciones realmente distintivas sobre el peso de formas;
- **Transiciones:** al desplegar una transición, prevalencia entre obras y posición del recuento de
  la obra, antes de «Dónde ocurre»;
- **Cambios de cuadro:** comparar solo la proporción de cambios de cuadro que coinciden con un
  cambio de secuencia;
- **Localizar en la obra:** al elegir versos partidos, espacio, sobrenatural o intervenciones,
  comparar una vez la proporción positiva entre respuestas, antes de sus acordeones;
- **Enunciación:** para cada tipo presente, distinguir difusión entre obras e intensidad dentro de
  las obras donde aparece;
- **Aperturas y cierres:** como máximo una observación sobre un patrón repetido e infrecuente, nunca
  estadísticas en cada celda.

No se añadirán comparativas a la cabecera, `Esquema métrico`, sinopsis, observaciones, bibliografía ni
a cada gráfico por jornada. La ficha debe seguir explicando primero la obra, no el corpus.

## Reglas de lectura pública

- El referente es siempre el corpus publicado y visible, también cuando mira la ficha un admin. Una
  vista previa puede compararse con ese mismo corpus si lo declara expresamente, pero nunca entra en
  su propio denominador.
- En muestras pequeñas se muestran primero recuentos —«3 de 11 obras»— y después el porcentaje.
- Se usa el rango central `q1–q3`; no se afirma un percentil exacto si no se ha calculado un rango.
- La redacción será descriptiva: «dentro del rango central», «entre los valores altos», «poco
  extendida» o «máximo observado». No se deduce «típica», «rara» o una explicación causal.
- Si `minimo = maximo`, la comparación no diferencia obras y se omite o se dice que no hay variación.
- Toda cifra declara universo, `n`, fecha de generación y cobertura. Una falta de respuesta nunca se
  presenta como una respuesta negativa.
- La UI pública recibe cifras ya seleccionadas y redactables; no decide por sí sola qué es digno de
  destacar a partir de umbrales oportunistas.
