# Revisión puntual de las notas del JSON métrico

Revisa el último JSON del chat. Conserva todos los valores de todos los campos
salvo las correcciones mecánicas de notas descritas aquí. No vuelvas a
transcribir las fotos ni reformules textos, rangos, denominaciones o avisos.

1. Si la misma nota aparece dos veces, una con cuerpo y otra vacía por haber
   registrado su llamada, conserva el objeto con cuerpo y su id. Añádele los
   enlaces de la copia vacía que pertenezcan a esa misma nota y borra la copia.
   Una misma marca puede representar notas distintas en diferentes páginas:
   solo elimina la copia si corresponde inequívocamente al mismo pie.
2. Para cada fila, rehaz `notas_ref` únicamente a partir de `notas[*].tramos_ref`:
   busca el id de la fila en cada nota y copia los ids que correspondan. Una
   nota con `tramos_ref: []` no se añade a ninguna fila.
3. Si el cuerpo de una nota identifica un único verso con «v.» y su número,
   copia ese número en ambos campos `v_ini` y `v_fin`. Si cita varios pasajes
   separados, deja ambos en `null`. No deduzcas un número a partir de la fila.

Devuelve el JSON completo en un solo bloque de código `json`, sin ningún otro
texto ni citas.
