# Editor de secuencias métricas V2

Estado: primera versión de prueba en `develop`, aislada del editor de obras.

## Objetivo

Comprobar con casos reales si el catálogo genera un formulario breve, comprensible y
analíticamente útil antes de migrar las secuencias que están registrando los editores.

La prueba usa el mismo Supabase que producción, pero solo tablas nuevas. No crea obras, no
escribe en `secuencias_metricas`, no modifica `estrofa_tipo_id` y no alimenta fichas,
buscadores, resúmenes ni el checklist editorial.

## Fórmula de registro

```text
realización efectiva =
    forma
    + configuración
    + elecciones entre alternativas admitidas
    + unidades internas realizadas
    + desviaciones respecto de lo admitido
```

Una elección ordinaria no es una desviación. En el villancico, `abba` y `abab` son respuestas
posibles a la pregunta por la rima de la mudanza; una ruptura que no encaje en ninguna de
ellas sí se registra como desviación.

## Tablas del catálogo

### `grupos_eleccion_metrica`

Define una pregunta que interesa responder:

- configuración;
- texto y ayuda para el editor;
- dimensión;
- alcance en toda la secuencia o en cada unidad;
- sección a la que se aplica;
- cardinalidad mínima y máxima;
- posibilidad de aplicar la respuesta a todas las unidades equivalentes.

No se crea un grupo para un resultado único que pueda derivarse automáticamente.

### `opciones_eleccion_metrica`

Cada respuesta apunta mediante FK a un dato normalizado:

- metro;
- patrón métrico;
- patrón de rima;
- sección;
- patrón de repetición;
- rasgo o valor de rasgo.

Así se controla lo que puede elegir el editor sin duplicar la ontología ni guardar respuestas
textuales difíciles de analizar.

Una opción puede declarar además un efecto de formulario:

- materializar una sección cuando la respuesta implica versos presentes;
- derivar su extensión de otra sección ya registrada.

El efecto no sustituye el valor normalizado. «Repetición total», por ejemplo, sigue
apuntando a su patrón de repetición y puede hacer aparecer un estribillo cuyo número de
versos se calcula desde la cabeza.

## Tablas exclusivas de prueba

- `escenarios_editor_metrico`: sustituye temporalmente a una obra ficticia.
- `secuencias_editor_metrico`: rango, forma y configuración de cada prueba.
- `unidades_editor_metrico`: coplas, cabezas u otras secciones localizadas y enlazadas
  jerárquicamente mediante `unidad_padre_id`.
- `elecciones_editor_metrico`: respuesta general o por unidad.
- `desviaciones_editor_metrico`: diferencias localizadas respecto de lo admitido.

Todas tienen RLS para `admin` e `IP`. La función
`guardar_secuencia_editor_metrico_prueba` guarda cada secuencia con sus unidades, elecciones
y desviaciones en una transacción.

## Comportamiento del formulario

1. El editor elige forma.
2. Si solo existe una configuración, puede resolverse automáticamente; si hay varias, debe
   seleccionar una.
3. Se muestran únicamente los grupos activos de esa configuración.
4. Las preguntas generales se responden una vez.
5. Si la configuración no tiene estructura interna editable, no aparece ningún constructor
   de unidades.
6. En una forma compuesta, las secciones obligatorias y sus rangos se derivan; el editor solo
   añade secciones opcionales e indica longitudes variables.
7. Las preguntas con alcance por unidad aparecen en su sección exacta, no en el contenedor.
8. Una respuesta puede copiarse a todas las unidades equivalentes y después corregirse donde
   cambie.
9. El bloque de desviaciones permanece vacío por defecto.
10. Una pregunta obligatoria sin respuesta impide guardar.
11. La ausencia de desviaciones significa cumplimiento, no falta de revisión.
12. El rango inclusivo debe ser compatible con la extensión o el ciclo de la
    configuración. La comprobación se deriva del catálogo y se repite en la base de datos.

## Compatibilidad de longitud

La regla no se mantiene como una lista de nombres de formas. Se deriva, por este orden, del
número de versos de la configuración, de sus secciones exactas y de sus ciclos repetibles
de rima o medida.

| Caso | Regla derivada |
| --- | --- |
| Quintilla | múltiplo de 5 |
| Romance | múltiplo de 2 |
| Soneto | múltiplo de 14 |
| Terceto encadenado | grupos de 3 más el verso final de cierre |

El formulario calcula siempre `v_fin - v_ini + 1`. Un rango incompatible impide guardar y
pide revisar la anotación o la fuente. Si falta un verso en el testimonio, se incorpora la
posición necesaria al cómputo y se registra la laguna como desviación; la norma no se
desactiva para ese caso.

## Primer caso completo: villancico

La configuración `estructura_habitual` genera:

| Alcance | Dato |
| --- | --- |
| Secuencia | Medidas presentes: 6, 8 o ambas. |
| Cada mudanza | Patrón: `abba` o `abab`. |
| Cada copla | Enlace o vuelta como una sección opcional, sin una pregunta redundante de presencia. |
| Cada copla | Repetición total, parcial o implícita del estribillo. |

Al seleccionar el villancico se crea la primera copla con su mudanza obligatoria. La cabeza,
el enlace o vuelta solo aparece si el editor lo añade. Una repetición total o parcial
materializa el estribillo; la implícita no inventa un rango. Los rangos de la copla y de la
secuencia se recalculan desde las extensiones de sus partes.

## Segundo caso: soneto

La única configuración se selecciona automáticamente. El editor responde una sola
pregunta, «¿Qué esquema presentan los tercetos?», con los cuatro patrones reconocidos por
el catálogo. La elección se guarda como referencia normalizada; la estructura fija y la
compatibilidad con catorce versos se derivan.

En formas simples se mantiene el camino corto: forma, las pocas elecciones realmente
registrables y guardado. La complejidad del catálogo no se traslada al formulario.

## Paso futuro

Cuando el catálogo y la interfaz estén validados:

1. se auditarán las anotaciones reales;
2. se crearán las tablas definitivas enlazadas con `secuencias_metricas`;
3. se migrará `estrofa_tipo_id`, los subtipos y las irregularidades existentes;
4. el componente V2 sustituirá al selector legado;
5. las tablas de escenarios de prueba podrán retirarse sin afectar a las obras.
