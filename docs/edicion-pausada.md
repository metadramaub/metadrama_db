# La edición de obras está pausada

**Desde el 2 de septiembre de 2026.** Un editor entra al dashboard con normalidad y ve su lista de
obras; al abrir una, encuentra un aviso —«Edición pausada»— en vez del editor. El objetivo es que
el corpus anotado con el vocabulario legado **deje de crecer** mientras se prepara la migración al
dominio métrico nuevo. El administrador y el IP trabajan sin cambios.

## Dónde vive

En `main`, en la página de la obra
(`src/routes/(dashboard)/dashboard/obras/[id]/+page.svelte`), commit `fdf1d7d`:

```svelte
const edicionPausada = $derived(data.profile.roleTerm === 'editor');
```

envolviendo la página entera. **Solo está en `main`**, que es lo desplegado; en `develop` la página
sigue completa, porque ahí es donde se trabaja.

## Qué detiene, y qué no

**Detiene la pantalla, no la escritura.** No hay guarda en el servidor: los endpoints de
`/api/obras/[id]/**` siguen aceptando lo que un editor les mande, y las políticas de RLS no han
cambiado. Se aceptó así a propósito —«con que no puedan editar me vale»—: quien entra por la
interfaz no puede anotar, que es lo que hacía crecer el corpus.

**No toca la base**, y no debe hacerlo: `editores.activo` sigue en `true` para los catorce.
Desactivarlos parece el camino corto y no lo es —`activo` lo miran **61 políticas de RLS**, 45 de
ellas de escritura, pero también `secuencias_select_authenticated`—, así que un editor desactivado
**no ve sus obras**: el panel le sale vacío y el dashboard le dice «ACCESO PENDIENTE… no tiene
perfil asignado», que es falso.

## Cómo se levanta

Se retira el bloque de `main` y se despliega. No hay nada que deshacer en la base.

## Por qué

Que la ola de editores que entra **no anote nada más con el vocabulario legado**, y que lo que haya
que migrar esté cerrado y contado. Ver
[CONTEXTO-PARA-CONTINUAR](./dominio-metrico/CONTEXTO-PARA-CONTINUAR.md).
