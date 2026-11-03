# Traición acertada (rótulo del lote) — ensayo v0.15 del 3 de noviembre de 2026

Original intacto en `backups/importador-local/traicion-acertada-2026-11-03/respuesta-v0.15-original.json`.
No se facilita modelo efectivo ni servicio. Las dos fotografías del lote permiten cotejar
18 filas numeradas que cubren 1–2861, tres jornadas y seis filas de resumen. Los rangos y las
denominaciones de esas filas están bien transcritos en la respuesta recibida.

## Bloqueo y errores de extracción

- La nota 21 cita 914–1013, 1676–1725 y 2677–2861. La respuesta solo enlaza t19 y construye
  el intervalo continuo 914–2861. La validación rechaza ese localizador, que no está cubierto
  por las filas enlazadas. Deben conservarse las citas en el texto, con extremos null y enlaces
  recíprocos a las tres filas correspondientes.
- Añade una carta en prosa inicial que no aparece en ninguna foto. No se elimina mediante
  una equivalencia ni se fuerza una localización: es un objeto inventado por la IA.
- Las 18 incidencias aritméticas muestran igualdades correctas, no discrepancias reales.
- La nota 21 altera corchetes por letras (`[ababal`, `[aabbaj`), y no señala que el cuerpo
  continúa fuera del encuadre. Debe transcribir lo visible sin completar la continuación.
- El porcentaje 8,7 del resumen tiene llamada 22, pero no se conserva su nota ni se declara
  la ausencia de cuerpo visible en la fotografía.

La respuesta no debe importarse. Los nombres «octavas» siguen sin identificar según el criterio
vigente; no es un error de transcripción ni se infiere por ello Octava real o remate del terceto.

## Revisión candidata

0.16 preparada fuera del prompt activo. Quita el ejemplo concreto de prosa, refuerza la condición
de diferencia real antes de crear una incidencia y el enlace de cada intervalo de una nota.
Pendiente ensayo externo y [panel de regresiones](./control-regresiones-prompt.md).
