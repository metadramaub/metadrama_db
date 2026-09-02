# La edición está cerrada a los editores

**Desde el 29 de agosto de 2026.** Se desactivaron los **14 editores** para que el corpus anotado con
el vocabulario legado **deje de crecer** mientras se prepara la migración al dominio métrico nuevo.
El administrador y el IP siguen activos y pueden trabajar con normalidad.

## Qué se hizo, exactamente

```sql
update public.editores ed
set activo = false
from public.vocabularios v
where v.termino_id = ed.role and lower(v.termino) = 'editor' and ed.activo;
```

No es una migración y **no debe convertirse en una**: es un estado operativo, no un cambio del
esquema ni del catálogo. Si viviera en `supabase/migrations/` se reaplicaría en cualquier entorno
nuevo y dejaría cerrada una base recién creada.

## Qué cierra, y qué no

`editores.activo` lo comprueban **61 políticas de RLS**, de las cuales **53 son de escritura**. Como
`develop` y `main` comparten el mismo Supabase, el cierre alcanza **a las dos ramas y a los dos
sistemas —el viejo y el nuevo— a la vez**, sin desplegar nada.

**Cierra también la lectura.** La política `secuencias_select_authenticated` mira `activo`, así que
un editor desactivado no ve sus obras: el panel le sale vacío, no en solo lectura. *Se asumió a
sabiendas —«si alguien justo entra y no ve sus obras, preguntará»— en vez de reescribir las 53
políticas de escritura una a una para distinguir leer de escribir.*

Sigue en pie `secuencias_select_assigned_reviewer`, que no mira `activo`: un revisor asignado
conserva su lectura por esa vía.

## Cómo se revierte

Los catorce estaban **todos activos** antes del cierre, así que la vuelta es simétrica y no hay que
recordar cuáles eran:

```sql
update public.editores ed
set activo = true
from public.vocabularios v
where v.termino_id = ed.role and lower(v.termino) = 'editor';
```

**Comprobar después** que quedan 14 editores activos, 1 admin y 1 IP.

## Por qué

El objetivo es que la ola de editores que entra **no anote nada más con el vocabulario legado**, y
que lo que haya que migrar esté cerrado y contado. Ver
[CONTEXTO-PARA-CONTINUAR](./dominio-metrico/CONTEXTO-PARA-CONTINUAR.md).
