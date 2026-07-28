# Series endecasilábicas: criterio de demarcación

Fecha de revisión: 28 de julio de 2026

## Decisión

El catálogo distingue tres formas de serie abierta exclusivamente endecasilábica mediante
dos rasgos cualitativos y observables:

| Forma | ¿Predominan los versos rimados? | ¿Los pareados organizan sistemáticamente la serie? |
| --- | --- | --- |
| Endecasílabo suelto | No | No |
| Silva de endecasílabos | Sí | No |
| Pareados endecasílabos | Sí | Sí |

Los antiguos umbrales del 50 %, 98 % y 99-100 % no se conservan como fronteras
ontológicas. Traducían de manera demasiado rígida expresiones como «predominan» o «en
su práctica totalidad» y obligarían al editor a realizar un cálculo innecesario. La
decisión editorial es cualitativa: debe reconocer qué organización caracteriza la serie.

## Endecasílabo suelto

Se define como una serie abierta de endecasílabos en la que predominan los versos
sueltos y las rimas son minoritarias. La configuración general importada se elimina por
redundante, porque las cinco realizaciones reconocidas cubren sus casos:

- `con_pareados_y_distico_final`;
- `con_pareados_sin_distico_final`;
- `puro_con_distico_final`;
- `puro_sin_distico_final`;
- `encadenado_interior`.

La presencia de pareados intercalados, el dístico final y el encadenamiento de una rima
final con el interior del verso siguiente se formalizan como restricciones de las
configuraciones. No alteran el rasgo común: los pareados no organizan sistemáticamente
el cuerpo de la serie.

## Silva de endecasílabos

Ocupa la franja intermedia. Predominan los versos rimados y los pareados son habituales,
pero no se suceden de manera sistemática durante toda la serie. Se admiten versos
sueltos. Esta formulación conserva la diferencia establecida por el IP sin convertir
«mayoría» en un porcentaje.

## Pareado y pareados endecasílabos

Se separan dos niveles que el vocabulario anterior había mezclado:

- `pareado`: estrofa o unidad de dos versos, de igual o diferente medida, unidos por
  rima consonante o asonante;
- `pareados_endecasilabos`: serie abierta de endecasílabos organizada sistemáticamente
  en dísticos consonantes sucesivos.

No son configuraciones de una misma forma porque una entrada describe una unidad cerrada
y la otra una serie. Ambas se relacionan mediante la familia estructural `pareados`, del
mismo modo que las unidades de terceto se relacionan con las series construidas a partir
de ellas.

## Comportamiento del demarcador

Las restricciones normalizadas alimentan dos preguntas sencillas:

1. ¿Predominan los versos rimados?
2. ¿La serie está organizada sistemáticamente en pareados?

No se muestra al usuario el vocabulario técnico de las restricciones ni se le pide un
porcentaje. El resto de la configuración —pareados intercalados, dístico final o
encadenamiento interior— solo se pregunta cuando todavía es necesario distinguir entre
las realizaciones del endecasílabo suelto.

## Trazabilidad y seguridad de la reclasificación

Las siete etiquetas heredadas comprobadas en esta revisión no están asociadas todavía a
ninguna secuencia editorial. La antigua entrada `pareado_endecasilabo` conserva su UUID
como forma nueva y su configuración mantiene `origen_termino_id`; las cinco
configuraciones de endecasílabo suelto conservan igualmente sus términos de origen.

## Contraste bibliográfico

José Domínguez Caparrós, *Métrica española*, nueva edición corregida y aumentada
(Madrid: UNED, 2014), p. 184, define el pareado o dístico como combinación de dos versos,
de igual o diferente medida, con rima consonante o asonante. Esta definición respalda
que la unidad `pareado` no se confunda con una serie de dísticos.

En pp. 232-233 describe el verso suelto, libre o blanco como una serie sin rima y señala
como realización más frecuente la serie de endecasílabos solos o con algún heptasílabo.
METADRAMA conserva el alcance más específico adoptado por el IP para el corpus y registra
la fuente como contraste, no como sustitución de ese criterio.
