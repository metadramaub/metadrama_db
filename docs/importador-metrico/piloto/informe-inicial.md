# Primer lote del piloto del importador

**Cuatro transcripciones aceptadas sin correcciones el 22 de octubre de 2026.** [Registro de aceptación y hashes](./revision-humana.json). La normalización sigue en revisión; no hay importación en Supabase.

Los datos proceden de lectura visual asistida de seis fotografías y de los bloques bibliográficos del DOCX. El prompt 0.1 queda preparado para ensayos posteriores; esta lectura no es una evaluación ciega ni una comparación entre proveedores.

| Obra | Fechas DOCX | Fotos | Filas fuente | Versos por rangos | Resumen impreso | Cotejo |
| --- | --- | --- | --- | --- | --- | --- |
| El molino | 1585–1593 | 2 | 21 | 2992 | recuentos compatibles | [Abrir tabla](./revision/el-molino.md) |
| El verdadero amante | 1591–1595 | 1 | 19 | 2878 | no aportado completo | [Abrir tabla](./revision/el-verdadero-amante.md) |
| Los donaires de Matico | 1589–1603 | 2 | 18 | 2812 | recuentos compatibles | [Abrir tabla](./revision/los-donaires-de-matico.md) |
| Los locos de Valencia | 1592–1595 | 1 | 20 | 3072 | no aportado completo | [Abrir tabla](./revision/los-locos-de-valencia.md) |

En conjunto: **78 filas y 11754 versos por rangos**, distribuidos en 17 denominaciones literales. Los resúmenes no se suman de nuevo.

## Qué está comprobado

Se han comprobado parseo y estructura, metadatos mínimos, referencias a fotos y notas, rangos inclusivos, continuidad, recuentos declarados y sumas de los dos resúmenes disponibles. Los términos y arquitecturas propuestos existen en la referencia acotada del catálogo vivo. Estos controles no certifican fidelidad visual ni validez filológica de las propuestas.

## Puntos concretos para revisar

- **El molino:** «letrilla», t20, vv. 2880–2888, 9 versos. Se conserva sin identificación de catálogo ni inferencia de canto. La página de la primera foto no es visible y permanece sin asignar.

- **Matico:** «tercetos», t01 y t09, 272 versos. Terceto y Terceto encadenado son candidatas orientativas, sin selección automática por la longitud.

- **El verdadero amante:** «estancias con pareado final», t02, 67 versos: Canción aceptada como forma, con remate en pareado declarado, sin arquitectura ni patrón de estancias. No se exige cotejar el texto. «Tercetos encadenados con serventesio final», t07 y t12, 170 versos: Terceto encadenado aceptado con remate final de un verso (3+1), sin arquitectura. Se conserva el literal editorial, sin otra forma ni otra secuencia.

- **Los locos de Valencia:** criterio acordado: n01 es desviación de metro en v. 2172; n02 es adición estructural en v. 2666. El tramo t16 conserva 133 versos, de los que 132 forman 33 redondillas; no se parte ni se inventa laguna. Ver [decisiones](./segmentacion.propuestas.json).

- **Porcentajes:** los recuentos de los resúmenes de Matico y El molino coinciden con los tramos. En Matico se conserva 2,5 % para 72 versos en octavas sobre 2812 versos; el cociente es aproximadamente 2,560 %. En El molino los porcentajes impresos suman 100,1 %. No se reescribe la fuente ni se interpreta esto como un error de extracción.

## Archivos y reproducción

- [Formato provisional](./formato-v0.1.md) y [prompt de extracción](../../../prompts/importador-metrico/extraccion-v0.1.md).

- [Fuentes y hashes](./fuentes.json), [inventario de términos](./inventario-terminos.md), [propuestas de equivalencia](./equivalencias.propuestas.json) y [propuesta de segmentación](./segmentacion.propuestas.json).

- [Referencia del catálogo](./catalogo-referencia.json), obtenida con [una consulta SELECT](../../../scripts/importador-metrico/catalogo-piloto.sql). No se utiliza como autoridad la exportación anterior del repositorio.

Desde la raíz del repo: `node scripts/importador-metrico/revisar-piloto.mjs` regenera tablas e inventario; `node scripts/importador-metrico/revisar-piloto.mjs --comprobar --verificar-fuentes` verifica sus contenidos y los originales sin escribir. Solo lee archivos locales y no conecta con Supabase.

El paso siguiente es revisar equivalencias y preparar la capa normalizada, conservando estas transcripciones como referencia. Una extracción fiel puede seguir teniendo identificación parcial.
