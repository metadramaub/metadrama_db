# Instrucciones del verificador · pasada D, descomposición en cláusulas

**Este texto se copia tal cual al despachar un lote de la pasada D.** Lo que cambia de un lote a
otro es solo el bloque «Tu fuente» y las rutas.

Modelo: Sonnet. Un agente por lote, seis afirmaciones por lote.

## Por qué existe esta pasada

Las afirmaciones de este lote **ya han pasado por tres lecturas** —una con el localizador delante,
una ciega sobre el pasaje y una de localización— y las tres las dieron por buenas. Además están
fuera del alcance de las cuatro comprobaciones mecánicas: **no comparten con su pasaje ni una tirada
de seis palabras seguidas**, porque parafrasean en vez de reutilizar el léxico de la fuente. Ninguna
máquina puede decir nada de ellas.

Lo que no ha funcionado hasta ahora es pedir un veredicto. Un lector que juzga el conjunto escribe
«omisión menor, no cambia la lectura» y sigue; y todo lo que esta auditoría ha encontrado de verdad
salió de comparar **cláusula a cláusula**, no de juzgar fichas enteras.

Por eso **aquí no hay veredicto**. No dices si la afirmación es conforme ni si tiene defectos. Haces
una tabla: cada aserción del resumen, con el fragmento del pasaje que la sostiene. Quien decida
después lo hará mirando tu tabla.

## Reglas inviolables

1. PROHIBIDO usar tu propio conocimiento de métrica española. Si algo no está en el fichero de la
   fuente, no existe. No des por buena una cláusula porque «suene correcta».
2. Toda cláusula sostenida lleva **transcripción literal** del pasaje. Sin transcripción no está
   sostenida.
3. Toda cláusula no sostenida lleva **qué buscaste**: los términos, dónde y con qué. Que no lo
   encuentres es un resultado; no decir qué buscaste, no.
4. **No corriges ni propones texto.** No es tu tarea, y el redactado lo aprueba una persona.
5. **No juzgas el localizador.** Otra pasada ya lo comprobó y el que recibes está confirmado.

## Lo que se te da y lo que tienes que leer

El lote te da, por afirmación: el **resumen del catálogo**, el **localizador ya confirmado** y las
**denominaciones** que el catálogo reconoce para esa forma. No te da el pasaje: lo abres tú.

**Lee el epígrafe o el § entero, no la frase citada.** Esta es la regla más importante de la pasada
y viene de un caso real:

> Una ficha decía que Navarro Tomás recoge «estribillos de dos a siete versos». El siete estaba
> allí, era cita correcta de una frase suya sobre un ejemplo de Góngora. **Diez líneas más abajo, en
> el mismo §**, escribe que los estribillos de sor Juana son «de muy diversa extensión entre dos y
> dieciséis versos». La ficha se quedó con el primer número que encontró y cerró el rango en menos
> de la mitad.

De ahí sale la regla dura:

> **Para cada número, rango, fecha o enumeración de la ficha: sigue leyendo hasta el final del
> epígrafe y anota el valor más amplio o más tardío que la fuente ofrezca.** No basta con encontrar
> el número que la ficha da.

Di en `hasta_donde_lei` qué has abarcado y si el epígrafe continuaba más allá.

## Las tres preguntas, por cláusula

Para cada aserción del resumen, y solo para ella:

1. **¿Está el dato?** ¿Hay en el pasaje algo que sostenga esta cláusula? Si no lo hay, la ficha está
   diciendo en voz de la fuente algo que la fuente no dice.
2. **¿Con la misma fuerza?** Si la fuente matiza —«suele», «generalmente», «puede», «rara vez»,
   «parece», «aunque»— y la cláusula afirma sin más, dilo y copia el giro exacto.
3. **¿Con la misma extensión?** Si la fuente da un rango más amplio, una lista más larga o una
   salvedad que la cláusula no recoge, dilo y copia el valor más amplio.

### Cómo se calibra

Esto importa tanto como lo anterior, porque una pasada diseñada para encontrar cosas encuentra cosas
que no están.

- **Una cláusula sostenida con otras palabras está sostenida.** Estas fichas parafrasean por
  construcción: que no compartan léxico con el pasaje es lo normal aquí, no un indicio. `está: "sí"`
  es la respuesta esperada en la mayoría de las cláusulas.
- Que el resumen condense, reordene o agrupe **no es nada**. Lo que se busca es que diga **más**,
  **más fuerte** o **más estrecho** que el pasaje.
- El catálogo usa su propia nomenclatura, que no es la de la fuente. Que la fuente no emplee nuestro
  nombre no prueba que no trate la forma: **busca todas las denominaciones que el lote te da**.
- Si dudas entre `sí` y `no`, pon `no` **y escribe qué buscaste**. Una duda documentada es útil; una
  afirmación sin fragmento, no.

## El original manda sobre el volcado

El `.txt` sirve para **encontrar** con `grep`. Lo que se lee y se transcribe es el original.

- `pdftotext -enc UTF-8 -f N -l N "<ruta>" -` vuelca la HOJA N del PDF, que **no es la página
  impresa**; el desfase no tiene por qué ser constante.
- **El epub de Jauralde Pou también es un original y se abre**: es un zip de XHTML y se lee con
  `zipfile`. No está paginado, así que se localiza por epígrafe, pero conserva la jerarquía de
  encabezados que el `.txt` aplana al volcar las versalitas como «E STROFAS DE OCHO VERSOS».
- La única fuente sin original consultable es Morley y Bruerton, y no lo necesita: la copia a mano
  del capítulo V es fiel y lleva marcas `[p. 38]` a `[p. 41]`.

## El eco

Cada lectura lleva un campo `eco` con **el resumen del catálogo copiado carácter por carácter** del
lote. No lo reescribas, no lo corrijas, no lo normalices: cópialo.

No es burocracia. Un verificador de la pasada A citó nuestro propio texto con una frase que la ficha
nunca tuvo y diagnosticó, con todo rigor, un defecto grave **contra un texto inexistente**. Un script
coteja tu `eco` con la base y **rechaza el dictamen entero si no coincide**.

## La salida

Un JSON en `dictamenes-d/<mismo nombre que el lote>`:

```json
{
  "fuente": "…",
  "lote": 1,
  "lecturas": [
    {
      "id": "…",
      "sobre": "…",
      "eco": "el resumen del catálogo, copiado carácter por carácter del lote",
      "hasta_donde_lei": "qué abarca lo que has leído y si el epígrafe seguía más allá",
      "clausulas": [
        {
          "clausula": "la aserción, recortada del resumen",
          "esta": "sí | no",
          "fragmento": "transcripción literal del pasaje que la sostiene (vacío solo si esta = no)",
          "que_busque": "obligatorio si esta = no: términos, dónde y con qué",
          "fuerza": "igual | la fuente matiza",
          "fuerza_detalle": "el giro exacto con que matiza, si matiza",
          "extension": "igual | la fuente abarca más | la fuente abarca menos",
          "extension_detalle": "el valor más amplio o más tardío que la fuente da, si difiere"
        }
      ]
    }
  ]
}
```

Divide el resumen en **todas** sus aserciones: si una frase afirma dos cosas, son dos cláusulas. Una
ficha de cincuenta palabras suele dar entre cuatro y ocho.

Al terminar, di en tu respuesta final, por afirmación, **solo las cláusulas con `esta: "no"`, con
`fuerza: "la fuente matiza"` o con `extension` distinta de `igual`**, y cuántas cláusulas has
revisado en total. Lo demás no hace falta repetirlo: está en el JSON.
