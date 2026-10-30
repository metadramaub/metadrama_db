# Punto de reanudación · 30 de octubre de 2026

Trabajo detenido por petición del responsable para apagar el ordenador. No aplicar migraciones.
Prioridad: importador operativo para colaboradores; después integrar la precomputación de ambos
orígenes. R2 se aplaza hasta necesitar espacio (ocupación indicada por el responsable: 12 %).
No añadir comparaciones a fichas públicas ni nuevas pantallas del laboratorio en esta entrega.

## Prueba de modelos gratuitos

El responsable facilitó una sesión de **Gemini gratuita**, abierta en el navegador del chat.
Se utiliza el modo visible **Automático**; el selector lo identifica como «Modelos de Gemini 3».
No se conoce el modelo exacto. El plan gratuito lo declaró el responsable; no se ha inspeccionado
su facturación. No se han usado API de pago ni creado cuentas. Falta una cuenta gratuita real de
ChatGPT para comparar en condiciones equivalentes.

Se envió el prompt existente `extraccion-v0.1.md` sin modificarlo entre casos, con las fotos JPEG
ya disponibles en `backups/importador-local/fotos-lectura-canto/` y solo los metadatos de la obra.
**Nunca se envió la tabla gold al modelo.** Conversación nueva para cada obra.

Archivos originales de entrada, respuesta y registro de ejecución:
`backups/importador-modelos/gemini-automatico-20261030/`, fuera de Git.

- Los locos de Valencia: respuesta capturada y evaluada. Conserva 20 filas y los textos de las
  dos notas. Marca de segunda nota vacía (gold: `**`); cambia «quintilla» por «quintillas» en una fila.
  El importador rechaza correctamente la marca vacía, pero muestra un error técnico poco legible.
- El verdadero amante: respuesta capturada y evaluada, 19 filas. Devuelve páginas como cadenas
  en vez de enteros. Revisar las demás diferencias del informe antes de atribuirlas a lectura.
- Los donaires de Matico: respuesta capturada al detener el trabajo, 18 filas. Pendiente evaluar.
- El molino: aún no se ha ejecutado en Gemini.

El evaluador nuevo y sus seis pruebas están en `scripts/lib/importador-metrico/evaluacion-modelos*`;
CLI `scripts/importador-metrico/evaluar-respuesta-modelo.mjs`. Las pruebas pasaron. Comparar contenido
y estructura por separado: un número entre comillas incumple el esquema, pero no necesariamente
es un error de lectura. El cotejo actual aún cuenta esa diferencia de tipo entre las diferencias
literales; precisarlo antes de redactar un ranking. No hay recomendación de modelo todavía.
Las cuatro obras son material de ajuste; reservar casos nuevos para evaluar el prompt final.

## Recorrido operativo

Se repitieron correctamente las **25 comprobaciones HTTP** con Auth real del Supabase sintético:
permisos individuales, consulta entre importadores, bloqueo de anónimos y editores sin permiso,
idempotencia, retirada de capacidad y separación del laboratorio.

Web de ensayo arrancada mediante `scripts/importador-metrico/iniciar-web-local.mjs`, puerto 5190.
Usar **http://localhost:5190**: `127.0.0.1:5190` comparte cookies por host con la instancia habitual
del usuario en `127.0.0.1:5188` y puede recibir una sesión de otro proyecto. No cerrar esa sesión
ni modificar sus cookies. El hostname `localhost` permitió entrar con la cuenta sintética 2.
Credenciales únicamente en `backups/importador-auth/cuentas.json`; no imprimirlas ni versionarlas.

Con ese editor autorizado se abrió el importador y se pegó la salida original de Gemini de
Los locos. Rechazo visible:
`Extracción con discrepancias técnicas: ... notas.1.marca ... Debe contener texto`.
No se corrigió ni guardó esa respuesta. Las obras reales de Supabase no se han modificado.

## Continuar

1. Evaluar Matico y ejecutar El molino con el mismo prompt en Gemini, conservando respuestas originales.
2. Mejorar la legibilidad de los errores del importador: no mostrar JSON técnico anidado.
   Se localizó el origen en `normalizarExtraccion` y su tratamiento en `vista-previa.ts`, pero
   **todavía no se ha editado** ese código.
3. Registrar correcciones y probar las salidas corregidas de principio a fin en la instancia local,
   incluyendo volver a abrir la copia guardada. Conservar fechas originales, sin sembrar pruebas reales.
4. Ajustar el prompt solo después de cerrar esta ronda, separando versiones y casos de evaluación.
5. Cerrar disponibilidad operativa antes de continuar con la integración de precomputación real.

No continuar inmediatamente las tareas: esperar a que el responsable retome el chat.
