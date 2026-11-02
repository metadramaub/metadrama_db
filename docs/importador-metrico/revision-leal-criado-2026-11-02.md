# El leal criado: formato incompleto y continuidad de jornadas

La respuesta v0.8 aportada el 02-11-2026 omite notas_ref en 17 filas consecutivas, t12–t28.
Son 17 incumplimientos del mismo campo obligatorio, no 17 defectos distintos del esquema.
El validador los detecta correctamente. No se completa la entrada automáticamente ni se
sustituye por un JSON corregido a mano: el responsable relanzará el prompt.

El cotejo de las dos fotos revela además:

- La segunda foto empieza con la continuación del acto segundo, no con el tercero. Los
  vv. 1378–2248 siguen en jornada 2. ACTO TERCERO aparece antes de 2249–2392: la respuesta
  traslada prematuramente t12–t19 a jornada 3.
- La llamada 5 está en superíndice junto al recuento 130 de la fila 870–999. La respuesta
  crea la nota y la enlaza a t05, pero omite la reciprocidad en notas_ref de esa fila.
- La nota cita el intervalo 930–934 y, separadamente, la reanudación desde 935. La respuesta
  los une artificialmente como 930–935; el prompt ya exige conservar localizadores múltiples
  en texto sin inventar un intervalo único.

El prompt v0.9 insiste en las nueve claves de TODOS los objetos de tramos, manteniendo las
listas vacías incluso al pasar a otra imagen. Añade el caso de continuación antes de un título
dramático a media página y la búsqueda de llamadas en la columna de recuento. No cambia el
formato 0.1 ni relaja su validación. La versión queda pendiente de nueva ejecución real.

La respuesta original se conserva sin alteraciones en
`backups/importador-local/leal-criado-2026-11-02/respuesta-v0.8-original.json`.
Las equivalencias de «endecasílabos blancos» y «coplas reales», así como la quintilla insertada
de la nota 5, se revisarán después de obtener una extracción válida; no las resuelve este cambio
del prompt ni se da por revisada toda la tabla o su resumen.

La nueva respuesta v0.9 carga correctamente. Se incorporan las equivalencias de
«endecasílabos blancos» y «coplas reales». El pasaje 870–999 se conserva unido:
el corte sugerido por la nota produciría 60 + 5 + 65 versos y requiere cotejar el texto.
Véase [el caso pendiente](./casos-complejos-equivalencias.md).

Tras revisar de nuevo las fotos, la llamada 5 figura junto a 130 y la nota cita 930–934;
no hay evidencia para trasladarla a 1392–1866. A petición del responsable, el editor ofrece
«Dividir según la nota» y advierte previamente de los 65 versos finales incompatibles.
No se divide al preparar la importación ni se altera el JSON original. La propuesta usa
la declaración explícita de quintilla aislada y reanudación, corroborada por el localizador
y el enlace recíproco; las notas ambiguas requieren división manual. Si hay cambios locales,
remate, rasgos o desviaciones, no se reemplazan con esta propuesta: se conserva la vía manual.
