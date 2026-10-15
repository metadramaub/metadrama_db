<script lang="ts">
	import ChevronRight from 'lucide-svelte/icons/chevron-right';
	import type { PublicFichaComentarioPublico } from '$lib/types/public-ficha.types';
	import { renderMarkdown } from '$lib/utils/markdown';
	import { agruparAclaracionesPublicas, type SecuenciaDeAclaracion } from './observaciones-publicas';

	const props = $props<{
		observaciones: string | null;
		comentarios: PublicFichaComentarioPublico[];
		secuencias: SecuenciaDeAclaracion[];
		canOpenSequence: (id: string) => boolean;
		onOpenSequence: (id: string) => void;
	}>();
	const generales = $derived((props.observaciones ?? '').trim());
	const grupos = $derived(agruparAclaracionesPublicas(props.comentarios, props.secuencias));
</script>

<section class="space-y-6 border-t border-[color:var(--border)] pt-4">
	<h2 class="text-lg font-semibold">Observaciones</h2>
	{#if generales || grupos.length > 0}
		<div class="divide-y divide-[color:var(--border)] border-y border-[color:var(--border)]">
			{#if generales}
				<article class="grid gap-4 py-5 md:grid-cols-[13rem_minmax(0,1fr)] md:gap-8">
					<header class="text-sm font-semibold">Toda la ficha</header>
					<div class="max-w-3xl border-l-2 border-[color:var(--border)] pl-3">
						<div class="space-y-2 text-sm leading-7">{@html renderMarkdown(generales)}</div>
					</div>
				</article>
			{/if}
			{#each grupos as grupo (grupo.secuenciaId ?? 'obra')}
				<article class="grid gap-4 py-5 md:grid-cols-[13rem_minmax(0,1fr)] md:gap-8">
					<header class="text-sm">
						{#if grupo.secuencia}
							{@const referencia = grupo.secuencia.v_ini === grupo.secuencia.v_fin
								? `v. ${grupo.secuencia.v_ini}`
								: `vv. ${grupo.secuencia.v_ini}–${grupo.secuencia.v_fin}`}
							{#if props.canOpenSequence(grupo.secuencia.secuencia_id)}
								<button
									type="button"
									class="inline-flex items-center gap-1 text-left font-semibold underline decoration-[color:var(--border)] underline-offset-4 transition-colors hover:decoration-current"
									onclick={() => props.onOpenSequence(grupo.secuencia!.secuencia_id)}
									aria-label={`Abrir secuencia, ${referencia}`}
								>
									{referencia}
									<ChevronRight size={14} aria-hidden="true" />
								</button>
							{:else}
								<p class="font-semibold">{referencia}</p>
							{/if}
							<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">{grupo.secuencia.forma_nombre}</p>
						{:else}
							<p class="font-semibold">{grupo.secuenciaId ? 'Secuencia' : 'Toda la ficha'}</p>
						{/if}
					</header>
					<div class="max-w-3xl space-y-5">
						{#each grupo.comentarios as comentario (comentario.comentario_id)}
							<div class="border-l-2 border-[color:var(--border)] pl-3">
								<div class="space-y-2 text-sm leading-7">{@html renderMarkdown(comentario.comentario)}</div>
							</div>
						{/each}
					</div>
				</article>
			{/each}
		</div>
	{/if}
	{#if !generales && grupos.length === 0}
		<p class="text-sm text-[color:var(--muted-foreground)]">Sin observaciones publicadas.</p>
	{/if}
</section>
