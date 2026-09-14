# Instrucciones del verificador · pasada C, localización ciega

**Este texto se copia tal cual al despachar un lote de la pasada C.** Lo que cambia de un lote a
otro es solo el bloque «Tu fuente» y las rutas.

Modelo: Sonnet. Un agente por lote.

## Qué es esta pasada y por qué es a ciegas

La pasada A comprobó cada afirmación teniendo delante su localizador, y la B leyó el pasaje que ese
localizador señala. Las dos **empiezan por donde el catálogo dice que hay que mirar**, y esa es la
manera de no ver nunca que el sitio es otro: si el pasaje que encuentras se parece bastante a lo
que buscabas, lo das por bueno y sigues.

Aquí se hace al revés. **Recibes lo que la afirmación dice y no recibes dónde dice el catálogo que
lo dice.** Tu trabajo es encontrarlo tú, por tu cuenta, y decir dónde está. Después otro comparará
tu respuesta con el localizador que el catálogo declara; si aterrizas en otro sitio, el localizador
está mal.

**No juzgas la afirmación.** No dices si es correcta, ni si la fuente la matiza, ni si falta algo.
Solo dónde está lo que dice, y si está repartido en más de un sitio, en cuántos y en cuáles.

## Reglas inviolables

1. PROHIBIDO usar tu propio conocimiento de métrica española para decidir dónde debería estar algo.
   Se busca en el texto, no en la memoria.
2. **Busca cada aserción por separado.** Una afirmación puede fundir dos pasajes distantes, y es
   justo lo que esta pasada tiene que descubrir: si la primera mitad está en una página y la
   segunda en otra, se dicen las dos.
3. **Transcribe literalmente** el fragmento que sostiene cada aserción, con su contexto.
4. **La página se lee en el PDF, no se deduce del volcado.** Abre la hoja, lee el número impreso al
   pie y dilo. Un número que sale de un `.txt` es una inferencia de quien lo extrajo.
5. Si no encuentras algo, **dilo y di qué buscaste**: los términos, dónde y con qué. Que no lo
   encuentres es un resultado, no un fracaso, y puede significar que la aserción no está en el
   libro.
6. Si el mismo contenido aparece en dos sitios, se dicen los dos y cuál es el desarrollo principal.

## El PDF manda sobre el volcado

El `.txt` sirve para encontrar con `grep`; la página y la estructura se confirman en el PDF con
`pdftotext -enc UTF-8 -f N -l N "<ruta>" -`. La hoja del PDF no es la página impresa, y el desfase
no tiene por qué ser constante. Dos fuentes no tienen PDF y no lo necesitan: Morley y Bruerton —una
copia a mano fiel del capítulo V— y Jauralde Pou, que viene de un epub sin paginar, donde lo que se
localiza es el epígrafe.

## La salida

Un JSON en `dictamenes-c/<mismo nombre que el lote>`:

```json
{
  "fuente": "…",
  "lote": 1,
  "localizaciones": [
    {
      "id": "…",
      "sobre": "…",
      "aserciones": [
        {
          "que_dice": "la aserción, con tus palabras",
          "donde_esta": "página, § o epígrafe, como se cite esta fuente",
          "como_lo_comprobe": "hoja del PDF y número impreso al pie que leíste",
          "texto_original": "transcripción literal del fragmento"
        }
      ],
      "localizador_que_propongo": "el que cubriría la afirmación entera",
      "esta_repartida": false,
      "no_encontrado": "si algo no aparece: qué es y qué buscaste"
    }
  ]
}
```

Al terminar, di en tu respuesta final, para cada afirmación, **dónde está cada cosa** y si está
repartida en más de un sitio.
