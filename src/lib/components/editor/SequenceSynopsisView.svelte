<script lang="ts">
	import ChevronDown from 'lucide-svelte/icons/chevron-down';
	import ChevronRight from 'lucide-svelte/icons/chevron-right';
	import type {
		SequenceSynopsisGroupItem,
		SequenceSynopsisJornadaGroup
	} from '$lib/components/editor/sequence-synopsis';
	import { renderMarkdown } from '$lib/utils/markdown';
	import { colorForForma } from '$lib/utils/metric-colors';
	import type { SequenceSynopsisCard } from '$lib/components/editor/sequence-synopsis';

	const props = $props<{
		groups: SequenceSynopsisJornadaGroup[];
		/** Mapa forma(slug) → color, compartido con barcode/pie. Opcional. */
		colorByForma?: Record<string, string>;
	}>();

	// Color del borde de una secuencia según su forma raíz: primero el mapa
	// compartido (mismos colores que barcode/pie), luego el fallback por gama.
	function cardBorderColor(card: SequenceSynopsisCard): string | null {
		if (!card.formaColorKey) return null;
		const mapped = props.colorByForma?.[card.formaColorKey];
		if (mapped) return mapped;
		return colorForForma({ slug: card.formaColorKey, tipoForma: card.formaTipoForma });
	}

	type NavItem = {
		key: string;
		label: string;
		rangeLabel: string | null;
		count: number;
		missingCount: number;
	};

	let collapsedGroups = $state<Record<string, boolean>>({});

	const navItems = $derived.by(() =>
		props.groups.map((group: SequenceSynopsisJornadaGroup, index: number): NavItem => ({
			key: groupKey(group, index),
			label: group.jornadaNum === null ? group.label : `Jornada ${group.jornadaNum}`,
			rangeLabel: group.rangeLabel,
			count: group.cards.length,
			missingCount: group.cards.filter((card) => !card.hasSynopsis).length
		}))
	);

	function groupKey(group: SequenceSynopsisJornadaGroup, index: number) {
		return group.jornadaId ?? `sin-jornada-${index}`;
	}

	function groupDomId(key: string) {
		return `sinopsis-${key}`;
	}

	function isCollapsed(key: string) {
		return collapsedGroups[key] === true;
	}

	function toggleGroup(key: string) {
		collapsedGroups = { ...collapsedGroups, [key]: !isCollapsed(key) };
	}

	function expandGroup(key: string) {
		if (!isCollapsed(key)) return;
		collapsedGroups = { ...collapsedGroups, [key]: false };
	}

	function setAllCollapsed(collapsed: boolean) {
		collapsedGroups = Object.fromEntries(navItems.map((item: NavItem) => [item.key, collapsed]));
	}

	function navigateToGroup(key: string) {
		expandGroup(key);
		requestAnimationFrame(() => {
			document.getElementById(groupDomId(key))?.scrollIntoView({
				block: 'start',
				behavior: 'smooth'
			});
		});
	}

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
		<div class="border-l-2 border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-2">
			<div class="flex flex-wrap items-baseline gap-x-2 gap-y-1 text-sm">
				<span class="text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">
					Inicia
				</span>
				<span class="font-semibold text-[color:var(--foreground)]">{item.cuadro.label}</span>
				{#if item.cuadro.rangeLabel}
					<span class="text-[color:var(--muted-foreground)]">{item.cuadro.rangeLabel}</span>
				{/if}
			</div>
		</div>
	{:else if item.type === 'cuadro_carryover'}
		<div class="border-l-2 border-dashed border-[color:var(--border)] bg-[color:var(--gray-50)]/70 px-3 py-1.5">
			<div class="flex flex-wrap items-baseline gap-x-2 gap-y-1 text-sm text-[color:var(--muted-foreground)]">
				<span class="text-xs font-semibold uppercase tracking-[0.08em]">Sigue</span>
				<span>{cuadroShortLabel(item.cuadro.cuadroNum)}</span>
				{#if item.cuadro.vFin !== null}
					<span>hasta v. {item.cuadro.vFin}</span>
				{/if}
			</div>
		</div>
	{:else}
		{@const borderColor = cardBorderColor(item.card)}
		<article
			class={`border-l-2 py-4 pl-4 ${
				borderColor
					? item.card.hasSynopsis
						? ''
						: 'border-dashed'
					: item.card.hasSynopsis
						? 'border-[color:var(--primary)]'
						: 'border-dashed border-[color:var(--border)]'
			}`}
			style={borderColor ? `border-left-color:${borderColor};` : undefined}
		>
			<header class="space-y-2 border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
				<div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-sm">
					<span class="font-semibold uppercase tracking-[0.06em] text-[color:var(--foreground)]">
						Secuencia {item.card.index}
					</span>
					<span class="font-medium text-[color:var(--muted-foreground)]">vv. {item.card.vIni}-{item.card.vFin}</span>
					<span class="font-medium">{item.card.estrofaLabel}</span>
					{#if item.card.nVersos !== null}
						<span class="text-xs text-[color:var(--muted-foreground)]">{item.card.nVersos} versos</span>
					{/if}
				</div>

				{#if item.card.spansMultipleCuadros}
					<div class="border-l-2 border-dashed border-[color:var(--border)] bg-white/70 px-3 py-1.5 text-xs text-[color:var(--muted-foreground)]">
						<div class="flex flex-wrap items-center gap-2">
							<span class="font-semibold uppercase tracking-[0.08em]">Cambia</span>
						{#if item.card.tramos[0]}
							<span>{cuadroShortLabel(item.card.tramos[0].cuadroNum)} {tramoEndText(item.card.tramos[0].vFin)}</span>
						{/if}
						{#if item.card.tramos[1]}
							<span>{tramoStartText(item.card.tramos[1].vIni)}, {cuadroShortLabel(item.card.tramos[1].cuadroNum)}</span>
						{/if}
						{#if item.card.tramos.length > 2}
							{#each item.card.tramos.slice(2) as tramo}
								<span>{cuadroShortLabel(tramo.cuadroNum)} / {tramo.vIni}-{tramo.vFin}</span>
							{/each}
						{/if}
						</div>
					</div>
				{/if}
			</header>

			<div class="mt-3 px-3">
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

{#if props.groups.length === 0}
	<div class="border border-dashed border-[color:var(--border)] p-6 text-sm text-[color:var(--muted-foreground)]">
		No hay secuencias registradas para construir la sinopsis completa.
	</div>
{:else}
	<div class="grid gap-6 lg:grid-cols-[14rem_minmax(0,1fr)]">
		<nav aria-label="Navegación de sinopsis métrica" class="lg:sticky lg:top-4 lg:self-start">
			<div class="border-y border-[color:var(--border)] py-3 lg:border-y-0 lg:border-r lg:pr-4">
				<div class="mb-3 flex flex-wrap gap-2">
					<button
						type="button"
						class="border border-[color:var(--border)] px-2 py-1 text-xs font-semibold text-[color:var(--foreground)] hover:bg-[color:var(--muted)]"
						onclick={() => setAllCollapsed(false)}
					>
						Expandir
					</button>
					<button
						type="button"
						class="border border-[color:var(--border)] px-2 py-1 text-xs font-semibold text-[color:var(--foreground)] hover:bg-[color:var(--muted)]"
						onclick={() => setAllCollapsed(true)}
					>
						Colapsar
					</button>
				</div>

				<div class="flex gap-2 overflow-x-auto pb-1 lg:block lg:space-y-1 lg:overflow-visible lg:pb-0">
					{#each navItems as item}
						<button
							type="button"
							class="min-w-fit border-l-2 border-transparent px-2 py-2 text-left text-sm hover:border-[color:var(--primary)] hover:bg-[color:var(--muted)] lg:block lg:w-full"
							onclick={() => navigateToGroup(item.key)}
						>
							<span class="block font-semibold">{item.label}</span>
							<span class="block text-xs text-[color:var(--muted-foreground)]">
								{item.count} secuencias
								{#if item.missingCount > 0}
									· {item.missingCount} sin sinopsis
								{/if}
							</span>
						</button>
					{/each}
				</div>
			</div>
		</nav>

		<div class="space-y-5">
			{#each props.groups as group, index}
				{@const key = groupKey(group, index)}
				{@const collapsed = isCollapsed(key)}
				<section id={groupDomId(key)} class="scroll-mt-6 border-t border-[color:var(--border)] pt-4">
					<header class="flex flex-wrap items-start justify-between gap-3">
						<button
							type="button"
							class="group flex min-w-0 items-start gap-2 text-left"
							aria-expanded={!collapsed}
							aria-controls={`${groupDomId(key)}-content`}
							onclick={() => toggleGroup(key)}
						>
							<span class="mt-1 inline-flex h-5 w-5 shrink-0 items-center justify-center border border-[color:var(--border)] text-[color:var(--muted-foreground)] group-hover:bg-[color:var(--muted)]">
								{#if collapsed}
									<ChevronRight size={14} aria-hidden="true" />
								{:else}
									<ChevronDown size={14} aria-hidden="true" />
								{/if}
							</span>
							<span class="min-w-0">
								<span class="block text-lg font-semibold">
									{group.jornadaNum === null ? group.label : `Jornada ${group.jornadaNum}`}
								</span>
								<span class="block text-sm text-[color:var(--muted-foreground)]">
									{#if group.rangeLabel}
										{group.rangeLabel} ·
									{/if}
									{group.cards.length} secuencias
								</span>
							</span>
						</button>
					</header>

					{#if !collapsed}
						<div id={`${groupDomId(key)}-content`} class="mt-4 space-y-1">
							{#each group.items as item (item.key)}
								{@render renderGroupItem(item)}
							{/each}
						</div>
					{/if}
				</section>
			{/each}
		</div>
	</div>
{/if}
