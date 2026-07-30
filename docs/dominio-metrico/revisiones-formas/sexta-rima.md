# Sexta rima

Estado: revisada con los datos del proyecto y bibliografía · 30 de julio de 2026

## Decisión

Una forma y una configuración fija.

| Elemento | Valor |
| --- | --- |
| Forma | `sexta_rima` · estrofa |
| Configuración | `endecasilabica_consonante` |
| Extensión | 6 versos |
| Patrón métrico | `11-11-11-11-11-11` |
| Rima | consonante |
| Patrón de rima | `ABABCC` |

Los cuatro primeros versos alternan dos clases de rima y los dos últimos forman un
pareado. No se crean configuraciones ni rasgos adicionales.

## Registrador

El recorrido es:

```text
Sexta rima → guardar
```

Metro, rima, esquema y extensión son definitorios y se derivan del catálogo. Una tirada
de sextas rimas se registra como una secuencia cuyo rango debe ser múltiplo de seis. Las
unidades se derivan del rango y no se materializan porque el editor no debe responder
nada distinto en cada una.

Una realización que incumpla una posición se registra como desviación localizada, no
como configuración nueva.

## Demarcador

La forma se identifica por la conjunción de:

1. unidad de seis versos;
2. seis endecasílabos;
3. rima consonante;
4. esquema `ABABCC`.

El demarcador compila estas propiedades directamente de la configuración. No necesita
preguntas editoriales guardadas en la base.

## Relaciones

La sexta rima se relaciona como `subtipo_de` sexteto: fija como `ABABCC` una realización
endecasilábica que satisface su definición general. En el registrador y el demarcador se
elige siempre esta forma específica, no la salida residual sexteto.

No se crea relación con `sexteto_lira`: compartir seis versos o una parte del nombre no
basta para afirmar una relación ontológica.

## Trazabilidad

```text
sexta_rima → FORMA Sexta rima
           ├── PATRÓN MÉTRICO 11-11-11-11-11-11
           └── PATRÓN DE RIMA ABABCC
```

El UUID anterior se conserva como identidad de la forma y como origen del destino de
migración.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, p. 199: define la
sexta rima como un sexteto de seis endecasílabos con esquema `ABABCC`.

La referencia sustituye el marcador bibliográfico `****` del vocabulario anterior sin
alterar el criterio estructurado por el IP.

## Dudas para el IP

Ninguna imprescindible para registrar o demarcar la forma.
