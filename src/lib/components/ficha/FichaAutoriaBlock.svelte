<script lang="ts">
	// Bloque de autoría de la ficha pública (reutilizable). Encapsula autoría
	// principal, autores no ambiguos, autoría por jornadas y fuentes de atribución.
	import { renderMarkdown } from '$lib/utils/markdown';
	import {
		collectUnambiguousPublicAuthors,
		formatPublicAutoriaGroup,
		formatPublicAutoriaProposal
	} from '$lib/utils/autoria-format';
	import type {
		PublicFichaAtribucionAutoria,
		PublicFichaAtribucionEvidencia,
		PublicFichaGrupoAutoria,
		PublicObraFichaPayload
	} from '$lib/types/public-ficha.types';

	const props = $props<{
		autoria: PublicObraFichaPayload['autoria'];
		showFuentes?: boolean;
	}>();

	type FuenteRow = PublicFichaAtribucionEvidencia & {
		atribucion_id: string;
		atribucion_label: string;
		jornada_id: string | null;
		jornada_num: number | null;
	};

	const grupos = $derived<PublicFichaGrupoAutoria[]>(props.autoria.grupos ?? []);
	const gruposGlobales = $derived(grupos.filter((g: PublicFichaGrupoAutoria) => !g.jornada_id));
	const gruposJornadas = $derived(
		grupos
			.filter((g: PublicFichaGrupoAutoria) => Boolean(g.jornada_id))
			.sort((a: PublicFichaGrupoAutoria, b: PublicFichaGrupoAutoria) => (a.jornada_num ?? 0) - (b.jornada_num ?? 0))
	);

	const autoriaPrincipalLabel = $derived.by(() => {
		const unambiguous = gruposGlobales.find((g: PublicFichaGrupoAutoria) => g.propuestas.length === 1);
		if (unambiguous) return formatPublicAutoriaGroup(unambiguous);
		if (gruposGlobales.length > 0) return formatPublicAutoriaGroup(gruposGlobales[0]);
		return '';
	});
	const autoresNoAmbiguos = $derived(collectUnambiguousPublicAuthors(gruposGlobales));

	const fuentes = $derived.by((): FuenteRow[] =>
		grupos
			.flatMap((g: PublicFichaGrupoAutoria) =>
				g.propuestas.flatMap((p: PublicFichaAtribucionAutoria) =>
					p.evidencias.map((e: PublicFichaAtribucionEvidencia) => ({
						...e,
						atribucion_id: p.atribucion_id,
						atribucion_label: formatPublicAutoriaProposal(p),
						jornada_id: g.jornada_id,
						jornada_num: g.jornada_num
					}))
				)
			)
			.filter((f: FuenteRow) => (f.fuente_autoria ?? '').trim().length > 0)
			.sort((a: FuenteRow, b: FuenteRow) => {
				const aS = a.jornada_id ? 1 : 0;
				const bS = b.jornada_id ? 1 : 0;
				if (aS !== bS) return aS - bS;
				return (a.jornada_num ?? 0) - (b.jornada_num ?? 0) || a.atribucion_id.localeCompare(b.atribucion_id);
			})
	);

	function scopeLabel(jornadaNum: number | null): string {
		return typeof jornadaNum === 'number' && Number.isFinite(jornadaNum)
			? `Jornada ${jornadaNum}`
			: 'Obra completa';
	}
</script>

<div class="mt-3 flex flex-wrap items-center gap-2 text-sm">
	<span class="font-semibold text-[color:var(--gray-900)]">Autoría:</span>
	{#if !autoriaPrincipalLabel && autoresNoAmbiguos.length === 0}
		<span class="text-[color:var(--muted-foreground)]">Autoría no identificada</span>
	{:else if autoresNoAmbiguos.length > 0 && !autoriaPrincipalLabel}
		{#each autoresNoAmbiguos as autor, index (autor.autor_id)}
			{#if index > 0}<span class="text-[color:var(--muted-foreground)]">·</span>{/if}
			<a class="underline-offset-2 hover:underline" href={`/autores/${autor.autor_id}`}>
				{autor.nombre_completo}
			</a>
		{/each}
	{:else}
		<span>{autoriaPrincipalLabel}</span>
	{/if}
</div>

{#if gruposJornadas.length > 0}
	<div class="mt-3 border-l-2 border-[color:var(--border)] pl-3 text-sm">
		<div class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
			Autoría por jornadas
		</div>
		<div class="mt-2 space-y-1">
			{#each gruposJornadas as grupo (grupo.grupo_atribucion_id)}
				<p>
					<span class="font-semibold">Jornada {grupo.jornada_num}:</span>
					{formatPublicAutoriaGroup(grupo)}
				</p>
			{/each}
		</div>
	</div>
{/if}

{#if props.showFuentes && fuentes.length > 0}
	<details class="mt-3 text-sm">
		<summary class="cursor-pointer text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
			Fuentes de autoría ({fuentes.length})
		</summary>
		<div class="mt-2 space-y-3 border-l-2 border-[color:var(--border)] pl-3">
			{#each fuentes as fuente (fuente.atribucion_evidencia_id)}
				<div class="space-y-1">
					<div class="text-xs text-[color:var(--muted-foreground)]">
						<span class="font-semibold text-[color:var(--foreground)]">{scopeLabel(fuente.jornada_num)}</span>
						<span>· {fuente.atribucion_label}</span>
					</div>
					<div class="space-y-1 text-sm leading-6">{@html renderMarkdown(fuente.fuente_autoria ?? '')}</div>
				</div>
			{/each}
		</div>
	</details>
{/if}
