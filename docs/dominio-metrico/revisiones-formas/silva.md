# Silva

Fecha de revisión: 28 de julio de 2026

## Decisión de organización

`silva` se conserva como una única forma de nivel **serie**. Sus cuatro modalidades
heredadas se modelan como configuraciones porque comparten la arquitectura abierta y
no estrófica y solo cambian la distribución métrica o la organización de la rima.

No se crea una familia `silva`: duplicaría la función de la forma.

## Definición adoptada

> Serie métrica abierta y no estrófica que combina generalmente versos endecasílabos y
> heptasílabos —o, en alguna configuración, solo endecasílabos—, con rima consonante
> distribuida sin una organización estrófica fija y con posibilidad de dejar versos
> sueltos.

La redacción conserva la definición y las cuatro modalidades establecidas por el IP,
separa la norma general de sus configuraciones y elimina los porcentajes introducidos
artificialmente para traducir expresiones cualitativas.

## Configuraciones

No se establece una configuración principal: las cuatro alternativas son coordinadas.

### Silva de consonantes regular

- slug: `consonantes_regular`;
- metros: ciclo repetible `7 + 11`;
- rima: pareados consonantes `aA | bB | cC | …`;
- estructura: bloques repetibles de dos versos;
- versos sueltos: desviación respecto de la norma regular.

Las minúsculas representan heptasílabos y las mayúsculas endecasílabos. Las letras
identifican la rima: cada pareado estrena una clase y no mantiene enlaces con el siguiente.

### Silva de consonantes irregular

- slug: `consonantes_irregular`;
- metros permitidos: heptasílabo y endecasílabo, sin orden posicional fijo;
- rima: consonante;
- organización: predominio cualitativo de pareados;
- versos sueltos: admitidos.

No se convierte «predominio» en un porcentaje. El editor o el demarcador solo necesitan
reconocer si los pareados organizan de forma característica la serie.

### Silva libre

- slug: `libre`;
- metros permitidos: heptasílabo y endecasílabo, sin orden posicional fijo;
- rima: consonante libremente distribuida;
- organización: sin estructura normativa de pareados;
- versos sueltos: admitidos.

Se conserva la denominación del IP. La bibliografía moderna emplea también `silva libre`
con un alcance más amplio, por lo que el catálogo registra esa diferencia como contraste
terminológico sin sustituir la taxonomía específica del proyecto.

### Silva de endecasílabos

- slug: `endecasilabica`;
- metro: endecasílabo repetido;
- rima: predominio cualitativo de versos rimados;
- pareados: habituales, pero no sistemáticos;
- versos sueltos: admitidos.

Se eliminan los umbrales 50-98 % y 99-100 %. No pertenecen a la norma métrica ni deben
exigir cálculos al editor.

Esta configuración se distingue del endecasílabo suelto porque en este último predominan
los versos sin rima, y de los pareados endecasílabos porque allí los dísticos organizan
sistemáticamente la serie. La frontera completa se documenta en
[`series-endecasilabicas.md`](./series-endecasilabicas.md).

## Demarcación

La ruta mínima de identificación puede preguntar:

1. ¿Todos los versos son endecasílabos?
2. Si combina 7 y 11, ¿los versos se organizan principalmente en pareados?
3. Si hay pareados, ¿repiten siempre el orden heptasílabo + endecasílabo?

Cuando todos son endecasílabos, el demarcador añade únicamente las dos preguntas
cualitativas necesarias: si predominan los versos rimados y si la serie está organizada
sistemáticamente en pareados.

Estas preguntas distinguen las cuatro configuraciones mediante rasgos observables y no
solicitan porcentajes ni conocimientos especializados innecesarios.

Los patrones basados en restricciones se incluyen en el artefacto regenerable del
demarcador. Así, dos configuraciones con los mismos metros y tipo de rima siguen siendo
distinguibles por la función estructural de sus pareados y versos sueltos.

## Trazabilidad y datos actuales

Las denominaciones heredadas se conservan mediante `origen_termino_id`. `silva_libre`,
que todavía no tenía destino en la importación inicial, se enlaza expresamente con la
configuración `libre`.

En la comprobación realizada el 28 de julio de 2026 no había secuencias editoriales
asociadas a `silva` ni a sus cuatro modalidades heredadas.

## Cuestión pendiente para el IP

Confirmar si `silva libre` se usa deliberadamente con el alcance específico del corpus
—heptasílabos y endecasílabos, rima consonante libre y ausencia normativa de pareados— o
si se pretendía hacerla coincidir con la categoría moderna de mayor amplitud métrica y
frecuente ausencia de rima.

## Contraste bibliográfico

José Domínguez Caparrós, *Métrica española*, nueva edición corregida y aumentada
(Madrid: UNED, 2014), pp. 227-228, define la silva mediante la combinación asimétrica de
endecasílabos, o de endecasílabos y heptasílabos, con rima consonante libremente dispuesta
y posibilidad de versos sueltos. Señala además la silva de consonantes como modalidad
organizada en pareados o tercetos.

Isabel Paraíso, «Arcadio Pardo y la Teoría Métrica», *Rhythmica. Revista Española de
Métrica Comparada*, 20-21 (2023; publicado en 2024), pp. 137-150, DOI
10.5944/rhythmica.39977, documenta el alcance moderno de `silva libre`. Se utiliza
únicamente como contraste terminológico.
