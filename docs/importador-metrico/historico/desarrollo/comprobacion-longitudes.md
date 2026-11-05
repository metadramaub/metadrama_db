# Comprobación de longitudes métricas

Implementada el 02-11-2026 por petición del responsable para detectar posibles errores de
numeración en las declaraciones de las ediciones. No identifica formas por divisibilidad,
no corrige rangos y no sustituye el cotejo del texto.

## Criterio y referencia

Se reutiliza `isMetricLengthCompatible` del editor v2 y la API. Se exportan en solo lectura las
83 reglas de arquitecturas activas de `public.arquitecturas_reglas_longitud`, conservadas en
`piloto/reglas-longitud.json`; la consulta reproducible está en `scripts/importador-metrico/reglas-longitud.sql`.
No se añaden módulos de redondilla, quintilla, soneto, etc., escritos a mano en el importador.
La preparación incorpora el hash de esta referencia a su procedencia.

Con arquitectura elegida se usa su regla. Con solo la forma se contrastan todas sus arquitecturas
activas: basta una posibilidad compatible para no señalar un descuadre. Si una arquitectura aún
posible no tiene regla fija, no se afirma incompatibilidad. No se elige arquitectura por el módulo.
Una forma sin identificar no recibe un diagnóstico normativo. «Compatible» expresa solo el
resultado de esta comprobación aritmética, no que la clasificación o los versos sean correctos.

Las adiciones declaradas como estructura/sobra se descuentan mediante la misma unión de intervalos
que utiliza el editor, evitando contar dos veces posiciones solapadas. Las lagunas ya ocupan
posiciones en el rango: no se suman ni descuentan otra vez. Desviaciones de metro no alteran la
extensión normativa. Un remate declarado fija la extensión del cierre que se aparta del cuerpo;
no basta aceptar otro cierre opcional si contradice ese dato. Se avisa si una adición coincide
con el remate para evitar descontar dos veces el mismo verso.

## Presentación y alcance

El descuadre es un **aviso para revisar**, no un bloqueo automático: puede haber un error de
extracción, uno de numeración en la edición o una particularidad aún no anotada. El usuario
puede conservar lo que declara la fuente. Las validaciones existentes de estructura, referencias
y contexto de rasgos siguen siendo errores bloqueantes; no se relajan.

Los avisos aparecen en la fila, con resumen del número de secuencias afectadas y filtro
«Longitud a revisar». En el modal se recalculan al cambiar límites, forma, arquitectura, remate
o desviaciones. Al comprobar cambios se repite el cálculo en servidor sobre los datos editados,
y se vuelve a ejecutar al confirmar. No se confía en un diagnóstico enviado por el navegador.

Al abrir una copia guardada se muestran avisos con la referencia actual, sin reescribir el
original ni los datos confirmados. Los avisos son presentación derivada, no nuevos campos
persistidos ni respuestas métricas añadidas a la ficha. No requiere migración ni modifica DB.

Las formas abiertas o sin regla fija no muestran un falso «correcto» ni un descuadre por no
cumplir un módulo inexistente. La ayuda junto al filtro explica este límite.

## Comprobación

242 pruebas correctas entre el importador, el cálculo compartido y el renderizado de la tabla.
Cubren módulos de diversas formas, arquitectura sin especificar, mínimo de dos tercetos,
remate explícito, adiciones solapadas, lagunas numeradas, formas abiertas, conservación de los
datos, recálculo tras editar y lectura de una copia guardada sin modificación. El renderizado
comprueba resumen, aviso de fila y filtro con un rango incompatible y otro válido.
Comprobación de tipos sin errores ni avisos y compilación de producción correcta.
