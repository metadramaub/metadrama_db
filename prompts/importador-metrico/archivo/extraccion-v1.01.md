# Extracción métrica de fotografías · 1.01

Transcribe la sinopsis métrica de una sola obra. Usa las fotos y los metadatos aportados.
Devuelve un único bloque JSON siguiendo la plantilla. Haz los tres pasos en privado.

## 1. Lee las tablas

- Localiza los títulos de actos o jornadas dentro de la tabla. Numéralos por su
  ordinal y copia sus rótulos. La cabecera editorial «Parte I» no inicia un acto.
  Las filas que continúan en otra foto conservan su acto hasta el próximo título.
- Recorre cada foto de arriba abajo. Por cada intervalo, sigue el renglón impreso
  hasta la denominación y el recuento. Con inclinación, sigue la pendiente de la
  fila. Ancla el primer y el último recuento de cada página. Une las líneas de
  una denominación partida, incluidos paréntesis, asonancia, esquema y remate.
  Una celda como 805 con un 22 en superíndice se lee como recuento 805 y nota «22».
- Copia inicio, final y recuento por separado. Si varios recuentos coinciden con
  la fila vecina, vuelve a las celdas impresas. Ejemplo: 1–24 / 24 y 25–56 / 32
  no pueden salir como 1–24 / null y 25–56 / 24. Si confirmas que la fuente
  imprime un descuadre o solapamiento, conserva los números tal como aparecen.
  El importador calcula los avisos aritméticos.
- Conserva la prosa declarada en la tabla. Una «carta en prosa» sin intervalo
  propio lleva inicio, final y recuento null. Si pone «entre los vv. 524 y 525»,
  copia esas palabras en la denominación y deja los tres números en null.
  La prosa no consume el intervalo de la fila siguiente.
- Guarda los totales y porcentajes impresos en resumen_fuente, en su orden,
  incluso si se repiten. Un intervalo de versos pertenece a tramos, aunque la
  tabla se titule «Resumen». Conserva los separadores decimales y omite el signo %.
- Copia las denominaciones tal como se imprimen, con singular o plural. Para
  esquemas como AabBCC, compara carácter a carácter con la foto, incluida la
  caja. Distingue una letra de un corchete. Une saltos de línea con un espacio.
  Conserva la página legible y la referencia de foto. Usa el identificador
  suministrado o foto-01, foto-02… en orden de adjunto.

## 2. Lee y vincula las notas

- Reúne las llamadas de denominaciones, recuentos y porcentajes y búscalas en
  los pies. Una llamada y su cuerpo forman un solo objeto. «22.» en el pie
  corresponde a «22» en superíndice. Una marca repetida que señala el mismo
  pie enlaza todas las filas que la llevan. Una marca reutilizada para otro
  pie representa otra nota.
- Copia solo el cuerpo visible y conserva signos, números y esquemas. Si está
  cortado, marca el corte con [ilegible]. Si solo ves la llamada, usa
  texto_literal null. En ambos casos registra una incidencia con marca y foto.
  Una llamada del resumen sin cuerpo conserva tramos_ref [].
- Determina los localizadores antes de escribir la nota. «(v. 321)» da
  v_ini 321 y v_fin 321. «vv. 400–410» da 400 y 410. Si hay varios intervalos
  separados, conserva las citas en el cuerpo y usa null en ambos campos.
  Los números que cuentan estrofas o esquemas no localizan versos.
- Usa el identificador real de cada fila enlazada. Incluye las llamadas visibles
  y los pasajes identificados expresamente en el texto. Por ejemplo, una nota
  con tramos_ref ["t03","t09"] aparece con el mismo id en notas_ref de t03 y
  t09. Una nota con tramos_ref [] no aparece en ninguna fila. No dividas una
  fila a partir de una nota.

## 3. Emite el JSON

Usa la estructura de abajo. Cada lista muestra un objeto de ejemplo. Sustitúyelo
por los objetos reales o por []. Copia los nombres de las claves tal cual. En
particular, genero_literal aparece solo en metadatos y las filas de resumen no
llevan id. Incluye todas las claves de cada objeto aunque valgan null o [].
Usa números enteros sin comillas para versos, fechas, jornadas y páginas. Marca
y porcentaje son texto. Copia los tipos de la plantilla: por ejemplo, página 128
se escribe "pagina": 128 y un recuento de 24 se escribe "n_versos_fuente": 24. Si un dato es ilegible, usa null y describe en
incidencias qué falta y dónde. Si falta parte de la sinopsis, indica qué parte.
Limita incidencias a problemas de fuente o lectura que merezcan revisión.

Usa metadatos null si no hay datos de la obra explícitos. Si los hay, copia lo
que consta. Conserva autoria_procedencia y bloque_docx_literal si los recibes.
Conserva obra_ref si te la dan. En procedencia, indica solo datos de ejecución
conocidos. Usa null si el servicio, modelo exacto, modo, plan, parámetros o fecha
no constan. Conserva los valores de revisión y la versión de la plantilla.

```json
{
  "esquema": "versologia-extraccion/0.1",
  "obra_ref": "obra-importada",
  "estado_revision": "borrador_ia",
  "revision_humana": {
    "responsable": null,
    "fecha": null,
    "resultado": "pendiente"
  },
  "procedencia": {
    "fecha": null,
    "procedimiento": "ejecucion_prompt",
    "generador": null,
    "modelo": null,
    "modo": null,
    "plan": null,
    "parametros": null,
    "prompt_version": "extraccion/1.01",
    "ensayo_controlado": false
  },
  "metadatos": {
    "titulo": null,
    "autoria": null,
    "genero_literal": null,
    "fecha_inicio": null,
    "fecha_fin": null,
    "fuente_fecha": null,
    "edicion_base": null,
    "observaciones": [],
    "fuente_id": null
  },
  "jornadas": [
    {
      "numero": 1,
      "rotulo_literal": null
    }
  ],
  "tramos": [
    {
      "id": "t01",
      "jornada": 1,
      "v_ini": 1,
      "v_fin": 24,
      "denominacion_literal": null,
      "n_versos_fuente": 24,
      "fuente_id": null,
      "pagina": 128,
      "notas_ref": []
    }
  ],
  "notas": [
    {
      "id": "n01",
      "marca": null,
      "texto_literal": null,
      "fuente_id": null,
      "pagina": 128,
      "tramos_ref": [],
      "v_ini": 12,
      "v_fin": 12
    }
  ],
  "resumen_fuente": [
    {
      "denominacion_literal": null,
      "n_versos_fuente": 24,
      "porcentaje_literal": "12,5",
      "fuente_id": null,
      "pagina": 128
    }
  ],
  "incidencias": [
    {
      "tipo": "lectura_pendiente",
      "descripcion": "Descripción concreta del dato y su localización",
      "fuente_id": null,
      "tramos_ref": []
    }
  ]
}
```
