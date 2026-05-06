### Adjuntos en comentarios internos (imagen/PDF, 1 por comentario, 8 MB)

#### Resumen
- Añadir adjunto opcional por comentario interno para que editor/revisor aporte contexto visual o documental.
- Soportar imágenes y PDF, con límite de 8 MB por archivo.
- Permitir en edición `reemplazar` o `quitar` el adjunto.
- Mostrar en lectura previa de comentarios: imagen embebida o enlace de apertura/descarga para PDF.
- Mantener limpieza manual del storage (sin automatización).

#### Cambios de implementación
- **Modelo de datos + Storage**
- Crear migración que añada en `comentarios_internos`: `adjunto_storage_path`, `adjunto_nombre_archivo`, `adjunto_mime_type`, `adjunto_size_bytes` (nullable).
- Añadir constraint “todo o nada” para metadatos del adjunto (si hay path, deben existir nombre/mime/tamaño y viceversa).
- Crear bucket `comentarios-internos` en Supabase Storage con acceso público (decisión cerrada).
- Definir path de objeto: `{user_id}/{obra_id}/{comentario_id}/{timestamp}_{filename_saneado}` para facilitar limpieza manual por obra/usuario.
- Añadir políticas de `storage.objects` para ese bucket:
- `insert/update`: usuario autenticado solo en su prefijo (`user_id` del path).
- `delete`: propietario del prefijo o `admin/ip` mediante `public.auth_is_admin_or_ip()`.

- **API/contratos**
- Ampliar endpoints de comentarios para aceptar `multipart/form-data` además de JSON legado.
- `POST` comentarios: permitir campo `adjunto` opcional; validar MIME y tamaño (8 MB) en servidor.
- `PATCH` comentario: soportar `adjunto` (reemplazo) y `quitar_adjunto=true` (eliminación).
- `DELETE` comentario: borrar también el archivo adjunto si existe.
- Normalizar respuesta de comentarios con un objeto `adjunto` (o `null`) para la UI:
- `url`, `nombre_archivo`, `mime_type`, `size_bytes`, `kind` (`image` | `pdf`).
- Actualizar tipos TS de comentario para incluir `adjunto`.
- Mantener reglas actuales de permisos/edición de comentarios (`estado` sigue solo lectura).

- **UI dashboard**
- En el panel de comentarios internos, añadir selector de archivo con `accept="image/*,application/pdf"` y texto de ayuda “máx. 8 MB”.
- En creación: enviar `FormData` cuando haya adjunto.
- En edición: mostrar adjunto actual y acciones `Reemplazar` / `Quitar`.
- En feed de comentarios:
- Si `kind=image`, render inline responsive.
- Si `kind=pdf`, mostrar enlace “Abrir/Descargar PDF”.

- **Guía y operación**
- Actualizar la guía editorial en el apartado de comentarios internos/revisión para documentar:
- qué se puede adjuntar (imagen/PDF),
- límite de 8 MB,
- un adjunto por comentario,
- edición con reemplazo/eliminación,
- limpieza manual en Supabase Storage cuando se acerque al límite.

#### Interfaces públicas/tipos afectados
- `comentarios_internos` incorpora metadatos de adjunto.
- Payload de comentarios (GET/POST/PATCH) añade `adjunto` estructurado.
- `POST/PATCH` comentarios aceptan `multipart/form-data` como formato oficial para adjuntos.

#### Plan de pruebas
- **Unitarias**
- Validación de adjuntos: acepta imágenes/PDF válidos <=8 MB, rechaza MIME no permitido y >8 MB.
- Parser de `multipart/form-data`: mapea correctamente texto/contexto/tipo y flags de quitar adjunto.
- **API**
- `POST` con imagen/PDF guarda metadatos y devuelve `adjunto.url`.
- `PATCH` reemplaza adjunto y actualiza metadatos.
- `PATCH` con `quitar_adjunto=true` limpia metadatos y borra objeto.
- `DELETE` comentario elimina también el adjunto.
- **UI**
- Render correcto de preview de imagen y enlace PDF.
- Flujo de creación y edición con adjunto funciona sin romper comentarios sin archivo.
- **Checks**
- `npm run check`
- `npm run test`

#### Supuestos y defaults cerrados
- Bucket de adjuntos **público permanente** (sin signed URLs).
- Máximo **1 adjunto por comentario**.
- Límite duro por archivo: **8 MB**.
- Limpieza de storage **manual**, sin cron ni automatización.
- Capacidad orientativa con 1 GB: ~128 archivos si todos pesan 8 MB; con media de 1.5 MB, ~680 archivos.
