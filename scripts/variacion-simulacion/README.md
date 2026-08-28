# Exportación estructurada del catálogo métrico

Este directorio contiene un exportador de solo lectura que transforma el catálogo métrico vivo
en un JSON jerárquico y reutilizable. No añade reglas de simulación, pesos, frecuencias,
clasificaciones de complejidad ni correspondencias con categorías externas.

## Ejecución

```powershell
node scripts/variacion-simulacion/exportar.mjs
```

La salida predeterminada es
`docs/dominio-metrico/catalogo-metrico-estructurado.json`. Se puede indicar otra ruta como primer
argumento. El proyecto debe tener disponible la conexión al catálogo de Supabase.

El JSON registra la versión y la revisión del catálogo. Mientras esa revisión y el exportador no
cambien, la salida es reproducible.

## Qué exporta

Se incluyen todas las formas activas cuyo `tipo_registro` es `forma`. Para cada una se usa la
proyección pública `get_forma_metrica_publica_jerarquica`, la misma fuente estructurada que alimenta
las fichas del catálogo.

La salida se organiza así:

```text
forma
├── arquitecturas
│   ├── esquemas_metricos
│   │   ├── posiciones
│   │   └── opciones
│   ├── esquemas_rima
│   │   ├── posiciones y posiciones_resueltas
│   │   ├── enlaces
│   │   └── restricciones
│   ├── secciones, repeticiones y variedades
│   ├── rasgos
│   └── elecciones
│       └── opciones
├── denominaciones, relaciones y tradiciones
├── fuentes
│   └── afirmaciones
└── catalogos_referenciados
```

Los esquemas, posiciones, opciones, variedades, rasgos y demás entidades conservan sus campos
originales, incluidos UUID, `slug`, modalidad, texto explicativo y valores nulos. La única omisión
deliberada es `formas_metricas.orden`, un campo sin uso ni significado estable. Los órdenes internos
de arquitecturas, secciones y opciones sí se conservan. La anidación solo resuelve relaciones que
ya existen en el catálogo: no crea combinaciones cartesianas ni deduce nuevas posibilidades.

`catalogos_referenciados` conserva entidades auxiliares necesarias para interpretar referencias:
tipos de rima, definiciones de rasgos y valores, formas relacionadas y arquitecturas reutilizadas.

## Cómo interpretar los huecos

Un valor `null` o una lista vacía significa que el catálogo no declara información en ese nivel.
No significa que todas las posibilidades sean equiprobables, que solo haya una posibilidad ni que
las restantes sean imposibles. Del mismo modo, `modalidad` se copia literalmente cuando existe y
no se convierte en una frecuencia numérica.

El exportador tampoco genera todas las realizaciones concretas de un esquema abierto. Por ejemplo,
conserva las restricciones y opciones que lo describen, pero no inventa el conjunto de patrones que
podrían satisfacerlas.

## Alcance temporal

No se aplica un filtro cronológico automático. El catálogo cubre un periodo más amplio que el
Siglo de Oro y parte de la información histórica está expresada en las afirmaciones y en sus
fuentes, no en intervalos normalizados. El JSON conserva esa evidencia sin inferir inclusiones o
exclusiones. Si se necesita acotar el corpus a la segunda mitad del XVI y al XVII, conviene hacerlo
después mediante una selección curada y separada de esta exportación.
