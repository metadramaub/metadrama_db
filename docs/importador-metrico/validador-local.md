# Validador local de extracciones

El validador técnico permite ensayar salidas nuevas del prompt sin depender del gold.
Comprueba el intercambio provisional 0.1 y produce diagnósticos sin modificar las entradas. Funciona
con datos sintéticos y con los borradores existentes; no necesita fotografías ni equivalencias
aprobadas. Está implementado como herramienta local, sin conexión con Supabase ni cambios en la web.

## Uso desde la raíz del repositorio

```powershell
node scripts/importador-metrico/validar-extraccion.mjs docs/importador-metrico/piloto/extracciones/los-locos-de-valencia.json --fuentes docs/importador-metrico/piloto/fuentes.json --rango-esperado 1:3072
```

El resultado enumera errores, advertencias, pendientes e información y calcula la extensión de los
rangos conocidos. `--json` produce el informe estructurado para otra herramienta. El archivo `-`
lee el JSON desde stdin. No se guardan informes automáticamente ni se siguen rutas de fotografías
que aparezcan en las entradas o el manifiesto.

```powershell
node scripts/importador-metrico/validar-extraccion.mjs --esquema
node scripts/importador-metrico/validar-extraccion.mjs --ayuda
```

`--esquema` imprime JSON Schema para ayudar a producir el formato. El núcleo añade comprobaciones
de referencias, fechas existentes y coherencia que no quedan expresadas íntegramente por ese esquema.
La entrada debe ser un objeto JSON completo, sin prosa ni cercas Markdown. Se tolera un BOM inicial;
no se rescata silenciosamente un objeto de una respuesta más amplia. No se convierten cadenas a
números, no se limpian denominaciones y no se eliminan campos desconocidos para aparentar validez.

## Qué significa cada diagnóstico

| Nivel | Casos | Efecto |
| --- | --- | --- |
| Error | JSON inválido, tipos erróneos, IDs duplicados, referencias inexistentes o fotografía de otra obra | La entrada o su contexto necesitan corrección técnica |
| Advertencia | Rangos invertidos, huecos, solapamientos, recuentos discrepantes, fechas invertidas o páginas incompatibles | Se conservan los datos para cotejo; el validador no decide cuál es correcto |
| Pendiente | Cotejo humano, etiqueta o rango ilegibles, metadatos ausentes, fuentes no contrastadas | Se conserva la información disponible sin inventar lo que falta |
| Información | Recuento de fuente no aportado, extremos no contrastados, alcance desconocido del resumen | Explica qué se ha podido comprobar y qué no se presume |

Un código de salida `0` significa que no hay errores ni advertencias técnicas. **Puede seguir
habiendo datos pendientes y siempre queda pendiente la revisión humana.** `1` indica errores de
formato, referencias o lectura; `2`, advertencias para cotejar; `64`, uso incorrecto de la CLI.
Estos códigos no son estados editoriales ni deciden la elegibilidad para el corpus.

El formato 0.1 representa borradores de extracción con `revision_humana` pendiente. El validador
rechaza una promoción a gold dentro de ese intercambio y nunca escribe una validación humana.
En el piloto la aceptación se conserva aparte, en `piloto/revision-humana.json`, vinculada por hash
a la extracción original. El validador genérico sigue comprobando la salida inicial; el normalizador
del piloto contrasta además ese registro antes de generar derivados. La futura persistencia de
revisiones en la plataforma no queda resuelta por estos formatos locales.

## Precauciones incorporadas al cálculo

- Una etiqueta desconocida como «letrilla» es texto de fuente válido. No se consulta un catálogo
  para sustituirla, descartarla o inferir canto. No se aplican las propuestas del piloto.
- Los rangos de un verso son válidos. Las notas se enlazan y localizan, pero no generan particiones.
- Un extremo o una denominación ilegibles pueden ser `null`. La suma de rangos conocidos no se
  presenta como extensión completa si faltan rangos. Cero no equivale a desconocido.
- Se distinguen suma de longitudes y unión de intervalos, de modo que los solapamientos no aumentan
  los versos cubiertos. Se detectan también solapamientos anidados, sin enumerar cada verso.
- Sin `--rango-esperado inicio:fin` no se presupone que las fotos empiecen en 1 ni incluyan el final.
  Un hueco entre rangos conocidos se señala como provisional si hay otras filas sin rango.
- Un resumen aportado puede ser parcial. Solo `--resumen-completo` permite contrastar su suma
  contra una cobertura continua, completamente transcrita y sin duplicados. No se deducen
  equivalencias entre las etiquetas del resumen y las de los tramos.
- Los porcentajes impresos se conservan. Que su suma sea 100,1 por redondeo no dispara una
  corrección automática. Un porcentaje individual superior a 100 se señala para cotejo.
- Las fechas se conservan como intervalo; no se imputan años centrales ni probabilidades.
- `--fuentes` contrasta IDs, pertenencia a la obra y páginas conocidas, no el contenido de las fotos.
  La verificación SHA-256 de originales continúa en el comprobador específico del piloto.

El informe calcula hechos técnicos sobre rangos. No mide incertidumbre de identificación, no
estima tolerancias del corpus y no comprueba si una declaración métrica es filológicamente correcta.
Esas tareas siguen la [metodología del proyecto](./metodologia.md) y requieren otras referencias.

## Código y comprobaciones

- [Núcleo reutilizable](../../scripts/lib/importador-metrico/validacion.mjs): esquema de Zod,
  validación de objetos/texto y diagnósticos, sin acceso al sistema ni a la red.
- [CLI](../../scripts/importador-metrico/validar-extraccion.mjs): lectura de archivo/stdin y salida
  humana o JSON. No escribe en la entrada ni accede a las fotos.
- [Pruebas](../../scripts/lib/importador-metrico/validacion.test.mjs): casos sintéticos con errores
  conocidos, compatibilidad mecánica de los cuatro borradores y uso real de la CLI.

```powershell
npx vitest run scripts/lib/importador-metrico/validacion.test.mjs
node scripts/importador-metrico/revisar-piloto.mjs --comprobar --verificar-fuentes
```

El comprobador específico del primer lote continúa contrastando sus resúmenes editoriales y los
derivados guardados. No se ha reemplazado por el validador general, porque incluye expectativas
propias de esas cuatro obras que no deben imponerse a toda salida del prompt.
