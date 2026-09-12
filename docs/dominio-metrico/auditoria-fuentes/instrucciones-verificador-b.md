# Instrucciones del verificador · pasada B, a ciegas

**Este texto se copia tal cual al despachar un lote de la pasada B.** Lo que cambia de un lote a
otro es solo el bloque «Tu fuente» y las rutas.

Modelo: Sonnet. Un agente por lote, diez afirmaciones por lote.

## Qué es esta pasada y por qué es a ciegas

La pasada A comprobó cada afirmación del catálogo **teniéndola delante**. Eso caza lo que está mal
escrito, y se le escapa lo que está escrito de más: un resumen que suena bien, con todas sus citas
correctas, en el que la fuente decía «suele» y el catálogo dice «es». Ese defecto no se ve
comparando, porque comparar invita a confirmar.

Por eso aquí **no vas a ver lo que dice el catálogo**. Vas a la fuente, lees el pasaje y escribes tú
lo que la fuente dice de esa forma. Otro comparará después tu versión con la nuestra, y las
diferencias serán el hallazgo.

**No tienes que juzgar nada ni buscar defectos: no hay con qué compararlos.** Tu trabajo es
describir bien la fuente. Si lo haces con fidelidad, la comparación posterior hace el resto.

## Reglas inviolables

1. PROHIBIDO usar tu propio conocimiento de métrica española. Escribes lo que dice ese pasaje, no
   lo que sabes de la forma. Si la fuente calla algo que tú sabes, calla tú también.
2. Toda descripción va acompañada de **transcripción literal** del original.
3. **Recoge los matices con las palabras de la fuente.** Si dice «suele», «parece», «generalmente»,
   «rara vez», «es posible aunque no frecuente», esas palabras van en tu resumen. Son lo que esta
   pasada existe para rescatar.
4. **Recoge las enumeraciones enteras, hasta el punto.** Si da cuatro esquemas, van los cuatro. Si
   dice «admite A, B o C», van los tres. No cierres listas que la fuente deja abiertas con
   «etcétera» o puntos suspensivos.
5. Si el localizador no lleva al pasaje, dilo y busca dónde está de verdad. Que el localizador esté
   mal no te impide describir la fuente.
6. Si la fuente **no trata** esa forma, dilo, y di qué buscaste: todas las denominaciones, y dónde.

## El PDF manda sobre el volcado

El `.txt` sirve para encontrar con `grep`; la página y la estructura se confirman en el PDF con
`pdftotext -enc UTF-8 -f N -l N "<ruta>" -`. La hoja del PDF no es la página impresa, y el desfase
no tiene por qué ser constante. Dos fuentes no tienen PDF y no lo necesitan: Morley y Bruerton —una
copia a mano fiel del capítulo V— y Jauralde Pou, que viene de un epub sin paginar.

## La salida

Un JSON en `dictamenes-b/<mismo nombre que el lote>`:

```json
{
  "fuente": "…",
  "lote": 1,
  "lecturas": [
    {
      "id": "…",
      "sobre": "…",
      "localizador_declarado": "…",
      "el_localizador_lleva_al_pasaje": true,
      "donde_esta_de_verdad": "si el anterior es false, dónde está",
      "texto_original": "transcripción literal del pasaje entero relevante",
      "lo_que_dice_la_fuente": "tu descripción, con los matices y las enumeraciones completas",
      "no_trata_esta_forma": false,
      "que_busque": "si no la trata: qué denominaciones buscaste y dónde"
    }
  ]
}
```

Al terminar, resume en tu respuesta final **qué dice la fuente de cada forma, en una o dos frases**,
sin omitir los matices.
