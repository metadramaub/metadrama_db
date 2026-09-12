<script lang="ts">
	import MetricAnalysisHeading from './MetricAnalysisHeading.svelte';
	import MetricFormLabel from './MetricFormLabel.svelte';
	import MetricSequencePair from './MetricSequencePair.svelte';
	import type { MetricSequenceReference } from './metric-display.types';
	import ArrowRight from 'lucide-svelte/icons/arrow-right';
	import ChevronDown from 'lucide-svelte/icons/chevron-down';

	interface TransitionSummary {
		de: string;
		deColorKey: string;
		a: string;
		aColorKey: string;
		veces: number;
		ocurrencias: { anterior: MetricSequenceReference; siguiente: MetricSequenceReference }[];
	}

	const props = $props<{
		rows: TransitionSummary[];
		onOpen: (sequenceId: string) => void;
		colorByForma: Record<string, string>;
	}>();
	let selectedKey = $state<string | null>(null);
	const claveDe = (row: TransitionSummary) => `${row.deColorKey}:${row.aColorKey}`;
	const principales = $derived(props.rows.slice(0, 6));
	const restantes = $derived(props.rows.slice(6));
	const principalesIzquierda = $derived(principales.filter((_: TransitionSummary, index: number) => index % 2 === 0));
	const principalesDerecha = $derived(principales.filter((_: TransitionSummary, index: number) => index % 2 !== 0));
	const restantesIzquierda = $derived(restantes.filter((_: TransitionSummary, index: number) => index % 2 === 0));
	const restantesDerecha = $derived(restantes.filter((_: TransitionSummary, index: number) => index % 2 !== 0));
</script>

<section class="space-y-3" aria-labelledby="metric-transitions-title">
	<MetricAnalysisHeading
		id="metric-transitions-title"
		title="Qué forma sigue a cuál"
		description="Transiciones entre secuencias consecutivas, incluidos los pasos de una jornada a otra."
	/>

	<div class="overflow-hidden rounded-lg border border-[color:var(--border)] bg-white">
		<div class="grid items-start md:grid-cols-2 md:divide-x md:divide-[color:var(--border)]">
			<ol class="px-4">
				{#each principalesIzquierda as row (claveDe(row))}
					{@render fila(row)}
				{/each}
			</ol>
			<ol class="border-t border-[color:var(--border)] px-4 md:border-t-0">
				{#each principalesDerecha as row (claveDe(row))}
					{@render fila(row)}
				{/each}
			</ol>
		</div>

		{#if restantes.length > 0}
			<details class="group border-t border-[color:var(--border)]">
				<summary class="flex cursor-pointer list-none items-center gap-2 px-4 py-3 text-sm font-medium text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] [&::-webkit-details-marker]:hidden">
					<ChevronDown class="h-4 w-4 shrink-0 transition-transform group-open:rotate-180" aria-hidden="true" />
					Ver {restantes.length} {restantes.length === 1 ? 'transición menos frecuente' : 'transiciones menos frecuentes'}
				</summary>
				<div class="grid items-start border-t border-[color:var(--border)] md:grid-cols-2 md:divide-x md:divide-[color:var(--border)]">
					<ol class="px-4">
						{#each restantesIzquierda as row (claveDe(row))}
							{@render fila(row)}
						{/each}
					</ol>
					<ol class="border-t border-[color:var(--border)] px-4 md:border-t-0">
						{#each restantesDerecha as row (claveDe(row))}
							{@render fila(row)}
						{/each}
					</ol>
				</div>
			</details>
		{/if}
	</div>
</section>

{#snippet fila(row: TransitionSummary)}
	<li class="border-b border-[color:var(--border)] last:border-b-0">
		<button
			type="button"
			class="grid w-full grid-cols-[minmax(0,1fr)_1rem_minmax(0,1fr)_4.5rem] items-center gap-2 py-2.5 text-left text-sm hover:text-[color:var(--muted-foreground)]"
			aria-expanded={selectedKey === claveDe(row)}
			onclick={() => (selectedKey = selectedKey === claveDe(row) ? null : claveDe(row))}
		>
			<MetricFormLabel forma={row.de} colorKey={row.deColorKey} colorByForma={props.colorByForma} className="font-medium" />
			<ArrowRight class="h-4 w-4 text-[color:var(--muted-foreground)]" aria-hidden="true" />
			<MetricFormLabel forma={row.a} colorKey={row.aColorKey} colorByForma={props.colorByForma} className="font-medium" />
			<span class="text-right tabular-nums">
				<strong class="text-base font-bold text-[color:var(--gray-900)]">{row.veces}</strong>
				<span class="ml-1 text-xs text-[color:var(--muted-foreground)]">{row.veces === 1 ? 'vez' : 'veces'}</span>
			</span>
		</button>
		{#if selectedKey === claveDe(row)}
			{@render detalle(row)}
		{/if}
	</li>
{/snippet}

{#snippet detalle(row: TransitionSummary)}
	<div class="border-t border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-3">
		<h3 class="text-sm font-semibold">Dónde ocurre</h3>
		<ol class="mt-2 divide-y divide-[color:var(--border)]">
			{#each row.ocurrencias as ocurrencia (`${ocurrencia.anterior.secuencia_id}:${ocurrencia.siguiente.secuencia_id}`)}
				<li class="py-2 text-xs first:pt-0 last:pb-0">
					<MetricSequencePair anterior={ocurrencia.anterior} siguiente={ocurrencia.siguiente} onOpen={props.onOpen} colorByForma={props.colorByForma} />
				</li>
			{/each}
		</ol>
	</div>
{/snippet}
