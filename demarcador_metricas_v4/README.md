# Demarcador métrico v3

Esta versión añade una capa métrica más explícita a `estrofas.json` para distinguir presencia, predominio/exclusividad y patrón métrico.

Campos añadidos en cada entrada:

- `metrica.metros_posibles`: metros que pueden aparecer en la forma.
- `metrica.metro_principal`: metro principal cuando puede inferirse.
- `metrica.metro_exclusivo`: `true` si la forma es monométrica; `false` si combina metros; `null` si no puede determinarse.
- `metrica.patron_metrico`: patrón de medidas cuando es fijo o inferible.
- `metrica.regularidad_metrica`: fija, variable, fija_con_variacion, regular_por_estancias, etc.
- `metrica.confianza`: alta, media o baja.

También se replican en `rasgos` algunos campos para facilitar el filtrado: `metros_posibles`, `metro_principal`, `metro_exclusivo`, `metro_unico`, `patron_metrico`, `regularidad_metrica`.

Criterio de uso:

- Usar `metro_unico` para preguntas del tipo “¿todos o casi todos los versos son...?”.
- Usar `metros_posibles` para preguntas del tipo “¿aparecen...?”.
- Usar `patron_metrico` para alternancias fijas como seguidilla o lira.

La formalización es revisable. El CSV `revision_metrica_especialista.csv` está pensado para revisión filológica.


## Nota v4: grupos lógicos de preguntas

La versión v4 actualiza `preguntas.json` con metadatos de flujo para evitar preguntas incompatibles después de una respuesta afirmativa a `metro_unico_*`. Las preguntas de metro único declaran `grupo_excluyente: "metro_unico"` y bloquean preguntas generales de presencia o combinación métrica (`metro_contiene_*`, `metro_heptasilabo_endecasilabo`, `patron_7_5`). La presencia secundaria de metros deberá modelarse en el futuro con preguntas específicas, no con las preguntas generales de presencia.
