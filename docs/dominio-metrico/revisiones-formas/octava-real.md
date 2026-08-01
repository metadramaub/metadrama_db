# Octava real

Estado: revisada · 1 de agosto de 2026

## Decisión

Una forma y una configuración fija. `octava_real_regular` no introduce una variante:
repite la definición de la raíz. `octava_real_de_esdrujulos` se transforma en un rasgo
transversal.

## Formalización

| Elemento | Valor |
| --- | --- |
| Forma | `octava_real` · estrofa |
| Configuración | `endecasilabica_consonante` |
| Extensión | 8 versos |
| Patrón métrico | ocho endecasílabos |
| Rima | consonante |
| Patrón de rima | `ABABABCC` |
| Rasgo admitido | `final_acentual = esdrujulo` |
| Denominaciones equivalentes | octava rima, octava heroica |

El patrón de rima se divide en una alternancia `ABABAB` y un pareado final `CC`, pero
ambas partes pertenecen a una única estrofa.

## Registrador

El recorrido ordinario es forma y guardar. Metro, rima, esquema y extensión se derivan.
Solo se marca «Mayoría de finales esdrújulos» cuando caracteriza la secuencia.

Una tirada de octavas se registra como una secuencia, no como una estrofa de extensión
arbitraria. El rango debe contener un múltiplo de ocho: 48 versos representan seis
octavas. El número de unidades se deriva del rango y no necesita filas adicionales si
ninguna propiedad cambia entre ellas.

## Demarcador

La octava real se identifica por ocho endecasílabos consonantes con `ABABABCC`. El final
esdrújulo no se pregunta para reconocer la forma porque es una especialización opcional.

## Trazabilidad

```text
octava_real                  → FORMA Octava real
├── octava_real_regular      → fusión; denominación histórica de traza
└── octava_real_de_esdrujulos → RASGO final_acentual = esdrujulo
```

La etiqueta redundante «Octava real regular» no es seleccionable. «Octava rima» y
«Octava heroica» sí se conservan como denominaciones equivalentes documentadas.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, p. 202: define la
octava real, octava rima o heroica como ocho endecasílabos de rima consonante
`ABABABCC`.

La misma fuente documenta excepcionalmente el esquema en octosílabos, pero el catálogo
no amplía por ello la forma: mantiene el alcance endecasilábico fijado por el proyecto.
