# Matriz preliminar de reclasificación del vocabulario métrico

Fecha: 28 de julio de 2026

Estado: propuesta para revisión del IP; no aplicada

Fuente: 119 entradas activas de `vocabularios.categoria = 'estrofa_tipo'` consultadas en la base remota el 28 de julio de 2026.

La matriz clasifica el catálogo, pero su aplicación debe cruzarse con el uso real. Las secuencias, rangos, subtipos internos y caracterizaciones declaradas en las obras son datos de investigación y deberán migrarse sin pérdida. Los resúmenes y fichas públicas actuales son proyecciones de prueba y podrán descartarse y regenerarse.

Documentos relacionados:

- [Auditoría del vocabulario actual](./informe-auditoria-vocabulario-metrico.md)
- [Propuesta conceptual](./propuesta-dominio-metrica.md)
- [Arquitectura del dominio métrico](./arquitectura-dominio-metrica.md)

## 1. Cómo leer la matriz

La clasificación se refiere al **destino principal** de cada entrada actual:

| Código | Destino | Significado |
| --- | --- | --- |
| `F` | Forma canónica | Identidad que puede asignarse a una secuencia. |
| `G` | Familia | Agrupador no asignable. |
| `C` | Configuración | Alternativa estructural o métrica de una forma. |
| `P` | Patrón | Esquema de rima o patrón formal, no forma independiente. |
| `R` | Rasgo o valor | Propiedad transversal o valor de una propiedad. |
| `A` | Alias o fusión | Entrada que debe integrarse en otra identidad. |
| `E` | Residual editorial | Salida necesaria para editar, excluida de la demarcación ordinaria. |
| `D` | Derivado o retirado | Entrada que no necesita persistir porque se calcula desde otros datos. |
| `?` | Decisión pendiente | No debe migrarse automáticamente antes de la revisión del IP. |

La certeza expresa confianza en la **reclasificación estructural**, no en todos los detalles filológicos de la ficha.

Una entrada puede producir varios registros. Por ejemplo, `soneto_de_esdrújulos` tiene como destino principal `R`, pero durante la migración de una secuencia deberá producir la forma `soneto` y el rasgo “mayoría de finales esdrújulos”.

### Distribución preliminar

| Destino | Entradas |
| --- | ---: |
| Formas canónicas (`F`) | 29 |
| Familias (`G`) | 1 |
| Configuraciones (`C`) | 28 |
| Patrones (`P`) | 25 |
| Rasgos o valores (`R`) | 25 |
| Alias o fusiones (`A`) | 2 |
| Residuales editoriales (`E`) | 2 |
| Derivadas o retiradas (`D`) | 3 |
| Decisiones pendientes (`?`) | 4 |
| **Total** | **119** |

Se han señalado 53 entradas para revisión expresa del IP. Esto no significa que las otras 66 puedan migrarse sin controles: todas deberán cruzarse con su uso en secuencias reales.

## 2. Canción petrarquista

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `cancion_petrarquista` | F | Conservar como forma compuesta; formalizar estancias y alternativas. | Alta | Sí |
| `cancion_de_15_versos` | C | Configuración de estancia de 15 versos. | Alta | No |
| `cancion_de_8_versos` | C | Configuración de estancia de 8 versos. | Alta | No |
| `cancion_de_9_versos` | C | Configuración de estancia de 9 versos. | Alta | No |
| `cancion_endecasilaba` | C | Configuración isométrica endecasílaba; revisar si está lexicalizada como subtipo. | Media | Sí |
| `cancion_regular_abCabCcdeeDfF` | P | Patrón de rima y metro admitido por una configuración regular. | Alta | No |
| `cancion_sin_rima` | ? | Decidir entre forma `cancion_libre` documentada o configuración sin rima. | Baja | Sí |
| `cancion_sin_rima_de_esdrujulos` | R | Forma de destino de `cancion_sin_rima` más rasgo esdrújulo. | Alta | Sí |

## 3. Copla de arte mayor

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `copla_de_arte_mayor` | F | Conservar como forma canónica. Corregir y formalizar el metro dodecasílabo. | Alta | Sí |
| `copla_de_arte_mayor_tipo_1_ABBAACCA` | P | Patrón de rima admitido `ABBAACCA`. | Alta | No |
| `copla_de_arte_mayor_tipo_2_ABBACDCD` | P | Patrón de rima admitido `ABBACDCD`. | Alta | No |
| `copla_de_arte_mayor_tipo_3_ABABCDCD` | P | Patrón de rima admitido `ABABCDCD`. | Alta | No |

## 4. Copla de pie quebrado

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `copla_de_pie_quebrado` | G | Familia de formas con pie quebrado; no usar como residual ni como equivalente de sextilla. | Media | Sí |

Debe decidirse si el proyecto necesita además una forma residual “otra copla de pie quebrado” para casos identificables como familia pero no como forma concreta.

## 5. Copla real

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `copla_real` | F | Conservar como forma canónica de diez versos y pausa 5 + 5. | Alta | Sí |
| `copla_real_de_pie_quebrado` | C | Configuración con patrón métrico ordenado que incluya quebrados. | Alta | Sí |
| `copla_real_sin_quebrado` | C | Configuración isométrica octosílaba; puede ser la configuración principal sin nombre público. | Alta | No |

## 6. Décima

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `decima` | ? | Decidir si será familia `decimas` o alias contextual de `decima_espinela`; el registro actual ya describe una espinela. | Baja | Sí |
| `decima_aumentada` | F | Candidata a forma canónica de doce versos, condicionada a fuente y uso en corpus. | Media | Sí |
| `decima_espinela` | F | Conservar como forma canónica con patrón `abbaaccddc`. | Alta | No |

No deben coexistir dos formas canónicas con la misma definición y patrón.

## 7. Doble sextilla

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `doble_sextilla` | F | Conservar como forma de doce versos; tipar su relación con la familia de pie quebrado. | Media | Sí |
| `copla_manriqueña` | F | Conservar como forma lexicalizada y relacionarla como subtipo de doble sextilla. | Alta | No |
| `doble_sextilla_alternativa` | C | Configuración no manriqueña de doble sextilla; sustituir “alternativa” por descripción positiva. | Alta | Sí |

## 8. Endecasílabo suelto

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `endecasilabo_suelto` | F | Conservar como serie métrica abierta. | Alta | Sí |
| `endecasilabo_suelto_con_pareados` | C | Configuración con pareados intercalados y dístico final. | Alta | Sí |
| `endecasilabo_suelto_con_pareados_y_sin_distico_final` | C | Configuración con pareados y sin dístico final. | Alta | Sí |
| `endecasilabo_suelto_de_esdrujulos` | R | Endecasílabo suelto más rasgo esdrújulo. | Alta | No |
| `endecasilabo_suelto_encadenado` | C | Configuración con rima interna encadenada; registrar además el rasgo correspondiente. | Media | Sí |
| `endecasilabo_suelto_puro` | C | Configuración sin pareados intercalados, con la política de cierre que se apruebe. | Alta | Sí |
| `endecasilabo_suelto_puro_sin_distico_final` | C | Configuración pura sin dístico final. | Alta | Sí |

Se retiran los umbrales porcentuales 50/98/99 usados para formalizar «mayoría». Las configuraciones declararán cualitativamente presencia, predominio o disposición de rimas y pareados; el editor solo registrará diferencias destacables respecto de esa norma.

## 9. Irregular

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `irregular` | E | Mantener como salida “forma regular no identificada”. | Alta | Sí |
| `irregular_arte_mayor` | D | Retirar como forma; derivar arte mayor de los metros observados. | Alta | No |
| `irregular_arte_menor` | D | Retirar como forma; derivar arte menor de los metros observados. | Alta | No |
| `irregular_mixto` | D | Retirar como forma; derivar mezcla de los metros observados. | Alta | No |

## 10. Lira

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `lira` | F | Conservar como forma canónica con patrón métrico y de rima ordenado. | Alta | No |

## 11. Novena

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `novena` | F | Conservar como forma de nueve versos. | Alta | Sí |
| `novena_canonica` | C | Configuración redondilla + quintilla. | Alta | No |
| `novena_invertida` | C | Configuración quintilla + redondilla. | Alta | No |

## 12. Octava real

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `octava_real` | F | Conservar como forma canónica. | Alta | No |
| `octava_real_de_esdrujulos` | R | Octava real más rasgo esdrújulo. | Alta | No |
| `octava_real_regular` | A | Fusionar con `octava_real`; el patrón `ABABABCC` será su configuración principal. | Alta | No |

## 13. Pareado

Se crea una forma canónica `pareado` para la unidad estrófica de dos versos. Las entradas
de arte menor, hexasílaba y octosílaba se convierten en configuraciones métricas. La
entrada endecasílaba se separa como forma de nivel serie porque describe una sucesión de
dísticos y no una única estrofa.

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `pareado_de_arte_menor` | C | Configuración de la nueva forma `pareado` con metro de arte menor. | Media | Sí |
| `pareado_hexasilabo` | C | Configuración hexasílaba de `pareado`. | Alta | No |
| `pareado_octosilabo` | C | Configuración octosílaba de `pareado`. | Alta | No |
| `pareado_endecasilabo` | F | Conservar como serie abierta de pareados endecasílabos; no confundir con la estrofa `pareado`. | Alta | Sí |

La frontera no se expresa mediante un umbral: una serie se identifica como
`pareados_endecasilabos` cuando los dísticos la organizan sistemáticamente. Si son
habituales pero no sistemáticos, puede corresponder a la silva de endecasílabos; si
predominan los versos sueltos, al endecasílabo suelto.

## 14. Quintilla

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `quintilla` | F | Conservar como forma canónica. | Alta | No |
| `quintilla_1_ababa` | P | Patrón admitido `ababa`. | Alta | No |
| `quintilla_2_abbab` | P | Patrón admitido `abbab`. | Alta | No |
| `quintilla_3_abaab` | P | Patrón admitido `abaab`. | Alta | No |
| `quintilla_4_aabab` | P | Patrón admitido `aabab`. | Alta | No |
| `quintilla_5_aabba` | P | Patrón admitido `aabba`; corregir tamaño 6 → 5 en origen. | Alta | No |
| `quintilla_6_abbaa` | P | Patrón admitido `abbaa`. | Alta | No |
| `quintilla_7_ababb` | P | Patrón admitido `ababb`; corregir tamaño 6 → 5 en origen. | Alta | No |
| `quintilla_8_abbba` | P | Patrón irregular documentado, no configuración canónica. | Alta | Sí |

Las unidades internas actuales de quintilla deberán migrarse a `unidades_metricas` asociadas al patrón correspondiente.

## 15. Redondilla y cuarteta

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `redondilla` | F | Conservar como forma; definir de manera expresa su sentido moderno o histórico. | Media | Sí |
| `redondilla_cruzada` | ? | Crear `cuarteta` como forma canónica o conservarla como configuración histórica documentada de redondilla. | Baja | Sí |
| `redondilla_doble_abbaacca` | F | Candidata a forma canónica `redondilla_doble`, con relación a redondilla. | Media | Sí |
| `redondilla_heptasilaba` | C | Configuración heptasílaba de redondilla. | Alta | No |
| `redondilla_hexasilaba` | C | Configuración hexasílaba; corregir la relación métrica de origen a 6. | Alta | No |
| `redondilla_regular` | A | Fusionar con `redondilla` si se adopta `abba` octosílabo como definición canónica. | Media | Sí |

## 16. Romance y vocales de la asonancia

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `romance` | F | Conservar como forma canónica. | Alta | No |
| `romance_a` | R | Valor normalizado de `vocales_asonancia`: vocal tónica final `á`. | Alta | Sí |
| `romance_a-a` | R | Valor `a-a` de `vocales_asonancia`. | Alta | No |
| `romance_a-e` | R | Valor `a-e` de `vocales_asonancia`. | Alta | No |
| `romance_a-o` | R | Valor `a-o` de `vocales_asonancia`. | Alta | No |
| `romance_e` | R | Valor normalizado de `vocales_asonancia`: vocal final `e`. | Alta | Sí |
| `romance_e-a` | R | Valor `e-a` de `vocales_asonancia`. | Alta | No |
| `romance_e-e` | R | Valor `e-e` de `vocales_asonancia`. | Alta | No |
| `romance_e-o` | R | Valor `e-o` de `vocales_asonancia`. | Alta | No |
| `romance_i` | R | Valor normalizado de `vocales_asonancia`: vocal tónica final `í`. | Alta | Sí |
| `romance_i-a` | R | Valor `i-a` de `vocales_asonancia`. | Alta | No |
| `romance_i-e` | R | Valor `i-e` de `vocales_asonancia`. | Alta | No |
| `romance_i-o` | R | Valor `i-o` de `vocales_asonancia`. | Alta | No |
| `romance_o` | R | Valor normalizado de `vocales_asonancia`: vocal tónica final `ó`. | Alta | Sí |
| `romance_o-a` | R | Valor `o-a` de `vocales_asonancia`. | Alta | No |
| `romance_o-e` | R | Valor `o-e` de `vocales_asonancia`. | Alta | No |
| `romance_o-o` | R | Valor `o-o` de `vocales_asonancia`. | Alta | No |
| `romance_u-a` | R | Valor `u-a` de `vocales_asonancia`. | Alta | No |
| `romance_u-e` | R | Valor `u-e` de `vocales_asonancia`. | Alta | No |
| `romance_u-o` | R | Valor `u-o` de `vocales_asonancia`. | Alta | No |

Los cuatro valores de una sola vocal necesitan una convención explícita que los diferencie de las secuencias de dos vocales y explique la normalización.

## 17. Romance heroico

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `romance_heroico` | F | Conservar como forma lexicalizada y relacionarla con romance. | Alta | No |

## 18. Romancillo

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `romancillo` | F | Conservar como forma canónica de serie asonantada de arte menor. | Alta | Sí |
| `romancillo_heptasilabo` | C | Configuración heptasílaba. | Alta | Sí |
| `romancillo_hexasilabo` | C | Configuración hexasílaba. | Alta | Sí |

Debe revisarse la equivalencia con `endecha`, porque no necesariamente puede aplicarse de forma indiferenciada a todas las configuraciones.

## 19. Seguidilla

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `seguidilla` | F | Conservar y crear configuraciones simple y compuesta; el tamaño no puede quedar fijado solo en 4. | Alta | Sí |

## 20. Sexta rima

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `sexta_rima` | F | Conservar como forma canónica; sustituir la bibliografía `****`. | Alta | No |

## 21. Sexteto

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `sexteto` | F | Conservar como forma abierta de seis versos de arte mayor. | Alta | Sí |

## 22. Sexteto-lira

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `sexteto_lira` | F | Conservar como forma canónica. | Alta | No |
| `sexteto_lira_a1_aBaBcC` | P | Patrón admitido `aBaBcC`. | Alta | No |
| `sexteto_lira_a2_AbaBcC` | P | Patrón admitido `AbaBcC`. | Alta | No |
| `sexteto_lira_a3_abaBcC` | P | Patrón admitido `abaBcC`; completar definición. | Alta | No |
| `sexteto_lira_b1_abbacC` | P | Patrón admitido `abbacC`. | Alta | No |
| `sexteto_lira_b2_AbbACC` | P | Patrón admitido `AbbACC`. | Alta | No |
| `sexteto_lira_c1_AabBcC` | P | Patrón admitido `AabBcC`; corregir tamaño 4 → 6. | Alta | No |
| `sexteto_lira_c2_AabBCC` | P | Patrón admitido `AabBCC`. | Alta | No |
| `sexteto_lira_de_esdrujulos` | R | Sexteto-lira más rasgo esdrújulo; corregir tamaño 5 → 6 mientras exista la entrada. | Alta | No |

## 23. Sextilla

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `sextilla` | F | Conservar como forma canónica de seis versos de arte menor. | Alta | Sí |
| `sextilla_de_pie_quebrado` | C | Configuración con patrón métrico ordenado; relacionar con familia de pie quebrado. | Alta | Sí |
| `sextilla_sin_quebrado` | C | Configuración isométrica; declarar sus medidas admitidas. | Alta | Sí |

## 24. Sextina

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `sextina` | F | Conservar como forma compuesta; formalizar 6 × 6 + 3 y la permutación de palabras finales. | Alta | Sí |

## 25. Silva

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `silva` | F | Conservar como serie métrica abierta. | Alta | Sí |
| `silva_de_consonantes_irregular` | C | Configuración con pareados de disposición irregular. | Media | Sí |
| `silva_de_consonantes_regular` | C | Configuración con pareados de disposición regular. | Media | Sí |
| `silva_de_endecasilabos` | C | Configuración endecasílaba; decidir si el uso del corpus justifica una forma lexicalizada. | Media | Sí |
| `silva_libre` | C | Configuración de silva con el nombre establecido por el IP; documentar su alcance específico frente al uso moderno de la denominación. | Alta | Sí |

No se conservarán porcentajes exactos de versos rimados o pareados. Las configuraciones utilizarán modalidades cualitativas y las secuencias solo registrarán diferencias respecto de ellas.

## 26. Soneto

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `soneto` | F | Conservar como forma canónica de composición. | Alta | No |
| `soneto_con_tercetos_de_rima_conclusiva_ABBAABBACDEDCE` | P | Patrón de rima admitido. | Alta | No |
| `soneto_con_tercetos_de_rima_nuclear_ABBAABBACDCEDE` | P | Patrón de rima admitido. | Alta | No |
| `soneto_con_tercetos_de_rima_paralela_ABBAABBACDECDE` | P | Patrón de rima admitido. | Alta | No |
| `soneto_de_esdrújulos` | R | Soneto más rasgo esdrújulo. | Alta | No |
| `soneto_regular_ABBAABBACDCDCD` | P | Patrón de rima preferente de la configuración endecasílaba; no forma independiente. | Alta | No |

## 27. Terceto

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `terceto` | F | Conservar como unidad de tres versos; retirar de su definición la mezcla con series completas. | Media | Sí |
| `terceto_de_esdrujulos` | R | Terceto más rasgo esdrújulo; corregir tamaño 1 → 3 mientras exista la entrada. | Alta | No |
| `terceto_encadenado` | F | Conservar como forma de serie abierta, diferenciada de la unidad terceto. | Alta | Sí |
| `terceto_sin_encadenar_1_AXABYB` | P | Trazar hacia el patrón «Verso central suelto» (`A-A | B-B | C-C | …`) de la forma `tercetos_sin_encadenar`. | Alta | No |
| `terceto_sin_encadenar_2_XAAYBB` | P | Trazar hacia el patrón «Primer verso suelto» (`-AA | -BB | -CC | …`) de la forma `tercetos_sin_encadenar`. | Alta | No |

## 28. Terceto octosílabo

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `terceto_octosilabo` | C | Configuración octosílaba de terceto encadenado, salvo que se documente como forma lexicalizada. | Media | Sí |

## 29. Verso suelto

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `verso suelto` | E | Mantener como categoría editorial residual para un verso aislado, fuera del catálogo de formas demarcables. | Alta | Sí |

Debe normalizarse el slug técnico aunque se conserve “Verso suelto” como etiqueta.

## 30. Villancico

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `villancico` | F | Conservar como forma compuesta con configuración estructural, secciones y repetición del estribillo. | Alta | Sí |

## 31. Zéjel

| Entrada actual | Destino | Resultado propuesto | Certeza | Revisión del IP |
| --- | :---: | --- | :---: | :---: |
| `zejel` | F | Conservar como forma compuesta; formalizar estribillo, mudanza y vuelta. | Alta | Sí |

## 32. Decisiones transversales ya adoptadas

Estas decisiones se aplican a todas las filas de la matriz:

1. Una secuencia guardada se interpreta mediante configuración normativa más diferencias registradas.
2. La ausencia de diferencias significa conformidad; no se añaden estados editoriales de certeza o revisión.
3. `Hipométrico` e `hipermétrico` se migran como relación menor/mayor que la medida esperada; la medida exacta solo se añade si existe.
4. `Rima defectuosa` se migra como «Rima diferente de la esperada» sin inventar un nuevo esquema o terminación.
5. `Mayoria_agudas` y `mayoria_esdrujulas` pasan a rasgos observados normalizados.
6. `Cantado`, `prosa` y `laguna` permanecen como caracterizaciones generales por rango.
7. Cuando las fuentes justifiquen una tradición española, italiana, provenzal u otra, se modelará como relación muchos-a-muchos y no como familia estructural heredable.
8. Los enlaces de rima entre unidades o secciones y la estructura interna de versos compuestos se modelan en el catálogo, sin pedirlos de nuevo al editor.

## 33. Decisiones agrupadas para el IP

### Decisiones que cambian identidades

1. `decima`: familia o fusión con espinela.
2. `redondilla_cruzada`: cuarteta o configuración histórica.
3. `redondilla_doble_abbaacca`: forma propia o configuración.
4. `cancion_sin_rima`: canción libre como forma o configuración.
5. `silva_libre`: redefinición, cambio de nombre o forma diferente.
6. Creación de una forma general `pareado`.
7. Alcance de la familia `copla_de_pie_quebrado`.

### Decisiones sobre configuraciones lexicalizadas

1. canción endecasílaba;
2. décima aumentada;
3. silva de endecasílabos;
4. romancillo heptasílabo y hexasílabo;
5. terceto octosílabo.

### Decisiones sobre salidas residuales

1. si `irregular` basta como salida;
2. si hace falta “otra copla de pie quebrado”;
3. si `verso suelto` pertenece al mismo selector o a una caracterización distinta.

## 34. Orden de revisión recomendado

1. Resolver las siete decisiones que cambian identidades.
2. Aprobar las formas residuales disponibles para el editor.
3. Revisar configuraciones lexicalizadas.
4. Aprobar en bloque las transformaciones evidentes de patrones de rima.
5. Aprobar en bloque los rasgos esdrújulos y valores de asonancia del romance.
6. Corregir los errores objetivos de origen.
7. Generar la correspondencia técnica por UUID.
8. Cruzar cada decisión con el número de secuencias y rangos reales que utiliza la entrada.

La matriz no debe convertirse todavía en una migración automática. Primero debe quedar revisada y cerrada como decisión editorial.
