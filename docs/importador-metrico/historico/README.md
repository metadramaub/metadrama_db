# Proceso histórico del importador

Estos documentos conservan lo probado, propuesto y decidido durante el desarrollo.
Sus estados y próximos pasos corresponden al momento del ensayo; para trabajar hoy, consultar
[el índice vigente](../README.md). No se mantienen como especificaciones actuales.

- `desarrollo/`: ensayos locales, diseños iniciales, estados fechados y ajustes de interfaz.
- [Control de regresiones](./desarrollo/control-regresiones-prompt.md): resultados de 0.16–0.27 y las alternativas 1.x.
- `revisiones-obras/`: cotejos e incidencias de las obras del piloto.
- `piloto-inicial/`: índice de la primera preparación del lote.
- `equivalencias/`: referencias generadas de versiones anteriores de las reglas.

Los prompts antiguos se conservan en [su archivo](../../../prompts/importador-metrico/archivo/).
Los registros de despliegue siguen en `docs/despliegues/`, que es su lugar común en el proyecto.

`revisar-piloto.mjs` conserva las comprobaciones del inventario inicial. Sus restricciones de
unicidad de literales preceden a las reglas condicionadas por notas y obras: actualmente puede
señalarlas como duplicadas. No usarlo como criterio de aceptación del vocabulario actual. Para
verificar las entradas y derivados vigentes se usan el validador, el normalizador, la preparación
y `npm run importador:informes -- --comprobar`, con sus pruebas automatizadas.
