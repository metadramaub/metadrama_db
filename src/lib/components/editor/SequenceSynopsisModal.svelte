<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';
	import type {
		SequenceSynopsisGroupItem,
		SequenceSynopsisJornadaGroup
	} from '$lib/components/editor/sequence-synopsis';
	import { renderMarkdown } from '$lib/utils/markdown';

	const props = $props<{
		open: boolean;
		groups: SequenceSynopsisJornadaGroup[];
		totalSequences: number;
		missingSynopsisCount: number;
		showSavedVersionNote?: boolean;
		onClose: () => void;
	}>();

	$effect(() => {
		if (!props.open) return;
		const handleEscape = (event: KeyboardEvent) => {
			if (event.key !== 'Escape') return;
			props.onClose();
		};

		document.addEventListener('keydown', handleEscape);
		return () => {
			document.removeEventListener('keydown', handleEscape);
		};
	});

	function cuadroShortLabel(cuadroNum: number | null) {
		return cuadroNum === null ? 'Sin cuadro' : `Cuadro ${cuadroNum}`;
	}

	function tramoEndText(vFin: number) {
		return `hasta v. ${vFin}`;
	}

	function tramoStartText(vIni: number) {
		return `desde v. ${vIni}`;
	}
</script>

{#snippet renderGroupItem(item: SequenceSynopsisGroupItem)}
	{#if item.type === 'cuadro_divider'}
		<div class="rounded-md border border-sky-200 bg-sky-50 px-4 py-3">
			<div class="flex flex-wrap items-center gap-2">
				<span class="text-xs font-semibold uppercase tracking-[0.08em] text-sky-700">INICIA</span>
				<span class="text-sm font-semibold text-sky-950">{item.cuadro.label}</span>
				{#if item.cuadro.rangeLabel}
					<span class="text-sm text-sky-800">{item.cuadro.rangeLabel}</span>
				{/if}
			</div>
		</div>
	{:else if item.type === 'cuadro_carryover'}
		<div class="rounded-md border border-sky-100 bg-sky-50/60 px-3 py-2">
			<div class="flex flex-wrap items-center gap-2">
				<span class="text-xs font-semibold uppercase tracking-[0.08em] text-sky-700">SIGUE</span>
				<span class="text-sm font-medium text-sky-900">{cuadroShortLabel(item.cuadro.cuadroNum)}</span>
				{#if item.cuadro.vFin !== null}
					<span class="text-sm text-sky-800">hasta v. {item.cuadro.vFin}</span>
				{/if}
			</div>
		</div>
	{:else}
		<article
			class={`card overflow-hidden border ${
				item.card.hasSynopsis
					? 'border-[color:var(--border)] bg-white'
					: 'border-dashed border-[color:var(--border)] bg-[color:var(--gray-50)]'
			}`}
		>
			<div class="border-b border-[color:var(--border)] bg-[color:var(--muted)] px-4 py-3">
				<div class="flex flex-wrap items-center gap-x-3 gap-y-2 text-sm">
					<span class="rounded-full border border-[color:var(--border)] bg-white px-2 py-1 text-xs font-semibold">
						Secuencia {item.card.index}
					</span>
					<span class="font-medium">vv. {item.card.vIni}-{item.card.vFin}</span>
					<span class="text-[color:var(--foreground)]">{item.card.estrofaLabel}</span>
					{#if item.card.nVersos !== null}
						<span class="text-[color:var(--muted-foreground)]">
							{item.card.nVersos} versos
						</span>
					{/if}
				</div>

				{#if item.card.spansMultipleCuadros}
					<div class="mt-3 rounded-md border border-sky-200 bg-sky-50 px-3 py-3 shadow-sm">
						<div class="flex flex-wrap items-center gap-2 text-sm text-sky-950">
							<span class="text-xs font-semibold uppercase tracking-[0.08em] text-sky-700">CAMBIA</span>
							{#if item.card.tramos[0]}
								<span class="rounded-full border border-sky-200 bg-white px-2 py-1 text-xs font-medium text-sky-900">
									{cuadroShortLabel(item.card.tramos[0].cuadroNum)} {tramoEndText(item.card.tramos[0].vFin)}
								</span>
							{/if}
							{#if item.card.tramos[1]}
								<span class="rounded-full border border-sky-200 bg-white px-2 py-1 text-xs font-medium text-sky-900">
									{tramoStartText(item.card.tramos[1].vIni)}, {cuadroShortLabel(item.card.tramos[1].cuadroNum)}
								</span>
							{/if}
							{#if item.card.tramos.length > 2}
								{#each item.card.tramos.slice(2) as tramo}
									<span class="rounded-full border border-sky-200 bg-white px-2 py-1 text-xs font-medium text-sky-900">
										{cuadroShortLabel(tramo.cuadroNum)} / {tramo.vIni}-{tramo.vFin}
									</span>
								{/each}
							{/if}
						</div>
					</div>
				{/if}
			</div>

			<div class="px-4 py-4">
				{#if item.card.hasSynopsis}
					<div class="space-y-2 text-sm leading-7">
						{@html renderMarkdown(item.card.sinopsis ?? '')}
					</div>
				{:else}
					<p class="text-sm italic text-[color:var(--muted-foreground)]">
						Sin sinopsis argumental.
					</p>
				{/if}
			</div>
		</article>
	{/if}
{/snippet}

{#if props.open}
	<div class="fixed inset-0 z-[120]">
		<button
			type="button"
			class="absolute inset-0 bg-black/45"
			aria-label="Cerrar lectura corrida de sinopsis"
			onclick={props.onClose}
		></button>

		<div class="absolute inset-x-4 top-4 bottom-4 overflow-y-auto border border-[color:var(--border)] bg-[color:var(--gray-50)] shadow-2xl md:inset-x-10 lg:inset-x-20">
			<div class="sticky top-0 z-20 border-b border-[color:var(--border)] bg-white px-5 py-4">
				<div class="flex flex-wrap items-start justify-between gap-3">
					<div class="space-y-2">
						<div>
							<h2 class="text-xl font-semibold">Lectura corrida de sinopsis</h2>
							<p class="text-sm text-[color:var(--muted-foreground)]">
								{props.totalSequences} secuencias
								{#if props.missingSynopsisCount > 0}
									· {props.missingSynopsisCount} sin sinopsis
								{/if}
							</p>
						</div>

						{#if props.showSavedVersionNote}
							<p class="max-w-3xl rounded-md border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-sm text-[color:var(--muted-foreground)]">
								La lectura corrida refleja la ultima version guardada. La secuencia abierta tiene cambios aun no guardados.
							</p>
						{/if}
					</div>

					<Button variant="secondary" onclick={props.onClose}>Cerrar</Button>
				</div>
			</div>

			<div class="px-5 py-5">
				{#if props.groups.length === 0}
					<div class="card border-dashed p-6 text-sm text-[color:var(--muted-foreground)]">
						No hay secuencias registradas para construir la lectura corrida.
					</div>
				{:else}
					<div class="space-y-8">
						{#each props.groups as group}
							<section class="space-y-4">
								<div class="rounded-md border border-[color:var(--primary)] bg-[color:var(--primary)] px-4 py-4 shadow-sm">
									<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
										{#if group.jornadaNum !== null}
											<span class="text-xs font-semibold uppercase tracking-[0.1em] text-[color:var(--primary-foreground)]">
												JORNADA
											</span>
											<span class="text-2xl font-semibold leading-none text-[color:var(--primary-foreground)]">
												{group.jornadaNum}
											</span>
										{:else}
											<span class="text-xl font-semibold text-[color:var(--primary-foreground)]">
												{group.label}
											</span>
										{/if}
										{#if group.rangeLabel}
											<span class="text-sm text-[color:var(--primary-foreground)]">
												{group.rangeLabel}
											</span>
										{/if}
									</div>
								</div>

								<div class="space-y-4">
									{#each group.items as item (item.key)}
										{@render renderGroupItem(item)}
									{/each}
								</div>
							</section>
						{/each}
					</div>
				{/if}
			</div>
		</div>
	</div>
{/if}
