# Búsqueda preliminar de declaraciones de canto

29 de octubre de 2026. **Rastreo de materiales, no transcripción validada ni análisis de las obras.**

## Ámbito y método

Se buscaron indicaciones explícitas de canto en las cuatro extracciones aceptadas y se hizo un
rastreo por OCR de las 38 fotografías HEIC correspondientes a 20 obras del lote externo.
Las otras dieciséis obras siguen sin transcripción validada. No se consultó ni modificó Supabase.

Los originales permanecen en la carpeta aportada por el responsable. Se prepararon copias JPEG
de lectura con orientación de imagen y lado mayor máximo de 2400 píxeles. Se usaron Pillow y
pillow-heif 1.8.1 para la lectura, y Windows.Media.Ocr con idioma es-ES para el rastreo.
No se modificaron originales ni dependencias de la web. Las copias y el texto OCR permanecen
locales en `backups/importador-local/`; no se incorporan las fotografías al repositorio.

La búsqueda inicial de raíces de canto, música, canción y letrilla se complementó con una
comprobación de las palabras reconocidas usando normalización de acentos. El resumen por foto
con hashes de los originales se conserva en
[rastreo-canto-2026-10-29.json](./rastreo-canto-2026-10-29.json).

## Resultado y comprobación visual

- En las cuatro extracciones aceptadas no se localiza una declaración explícita de canto.
- Las 38 fotografías se procesaron sin errores; el OCR reconoció 2234 líneas.
- El rastreo no localizó indicaciones explícitas de canto o música. Este resultado negativo
  depende del reconocimiento OCR; no demuestra que las páginas carezcan de toda mención posible.
- Se localizaron «letrilla»/«letrillas» y «Canción» en cuatro fotografías, que sí se comprobaron
  visualmente:

| Obra y archivo | Lectura comprobada | Interpretación permitida |
| --- | --- | --- |
| El molino, `14_molino_2.HEIC`, p. 1562 | «letrilla» en la sinopsis y en el resumen; vv. 2880–2888 | Denominación de la fuente; no declaración de canto |
| Las ferias de Madrid, `15_ferias_madrid_1.HEIC` | El argumento menciona letrillas satíricas que los personajes piensan leer | No autoriza a registrar canto; tampoco demuestra ausencia global de canto |
| Las ferias de Madrid, `15_ferias_madrid_2.HEIC`, p. 1833 | Cuatro entradas de letrilla de tres versos: 2953–2955, 2960–2962, 2968–2970 y 2986–2988; total 12 en el resumen | Denominaciones y rangos visibles; no declaración de canto |
| Nacimiento de Ursón y Valentín, `23_nacimiento_Urson_y_valentin_2.HEIC`, p. 996 | «canción», vv. 2724–2749, 26 versos | Forma declarada; no declaración de canto |

La forma Canción tampoco prueba ejecución cantada. No se crean respuestas de canto a partir de
estos términos, no se establece una equivalencia métrica nueva y no se registran ausencias por
silencio de la fuente. Tampoco se incorporan los datos de Las ferias como nueva extracción aceptada.

Como hallazgo adicional, la p. 996 de Nacimiento de Ursón y Valentín declara «carta en prosa»
con una raya en lugar de rango de versos, antes de los vv. 1931–1954. Permite registrar presencia
de prosa si se confirma al preparar su extracción; no permite asignarle una cantidad de versos ni
un porcentaje de extensión inventado. Es un caso documental para revisar las unidades de D06.
También se comprobó visualmente `34_casamiento_muerte_1.HEIC`: declara un pasaje en prosa entre
los vv. 524–525, dentro de la entrada de octavas 469–556. Es una localización entre versos, no
dos versos en prosa. Ninguno de estos dos hallazgos cuantifica por sí solo la extensión de la prosa.

## Uso de este resultado

Sirve para responder qué se ha localizado en los materiales de prueba y para preparar ejemplos.
No basta para validar el recorrido de importación de una declaración positiva de canto. Si el
lote no aporta un ejemplo confirmado, ese recorrido se comprobará con un caso sintético rotulado
como tal o con otro ejemplo documental explícito, sin inventar canto en ninguna obra del lote.
