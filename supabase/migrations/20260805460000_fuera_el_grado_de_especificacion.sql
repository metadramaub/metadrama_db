-- Fuera el grado de especificación: la clasificación útil es el nivel estructural.
--
-- `formas_metricas.grado_especificacion` distinguía formas «generales» de «específicas». Su
-- propósito declarado, en el comentario de la propia columna, era que «el demarcador ofrece la
-- más específica que encaje». **Eso nunca se implementó**: el motor ordena las hipótesis por
-- puntuación y el grado solo viaja hasta la salida, donde se imprime.
--
-- Lo que hacía de verdad, comprobado uso por uso:
--
--   · Una regla de auditoría —una forma general no puede ser subtipo de una específica— que
--     **no puede dispararse**: no hay ninguna relación `subtipo_de` en el catálogo.
--   · Dos validaciones de la API que existen únicamente porque existe la columna.
--   · Una pista «· general» en el selector del editor V2, visible en 2 formas de 28.
--   · Una palabra en la cabecera de la ficha pública.
--
-- Y estaba mal poblada, que es lo que la hacía parecer inútil: el cuarteto, el terceto y el
-- pareado responden exactamente a la definición de forma general —definidas por rasgos amplios,
-- registradas de manera funcional— y figuraban como específicas.
--
-- Se retira en vez de repoblarla. **La clasificación que sirve es `nivel_estructural`** —verso,
-- estrofa, serie, composición—, que dice algo comprobable sobre la forma y que el demarcador sí
-- usa: decide si la extensión es libre o se cuenta por repeticiones de una unidad.
--
-- Una validación cambia de criterio y mejora. «Toda forma **específica** tiene al menos una
-- arquitectura activa» pasa a ser «toda forma **con norma** la tiene», y lo que excluye a las
-- dos que no la tienen —«Verso aislado» y «Versificación irregular»— es `tipo_registro =
-- 'sin_forma'`, que es su razón verdadera: un tramo sin forma no tiene norma por diseño.

begin;

alter table public.formas_metricas
	drop constraint if exists formas_metricas_grado_especificacion_check;

alter table public.formas_metricas
	drop column if exists grado_especificacion;

comment on column public.formas_metricas.nivel_estructural is
	'`verso`, `estrofa`, `serie` o `composicion`. Es la clasificación estructural del catálogo y la que el demarcador usa: en una serie la extensión es libre, y en una estrofa se cuenta por repeticiones de su unidad. Una estrofa se seria dentro de su propia forma —cuarenta versos de redondilla son diez redondillas—, así que una forma `serie` aparte solo se justifica cuando seriar cambia la estructura, es decir, cuando la rima cruza el límite de la unidad.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;
