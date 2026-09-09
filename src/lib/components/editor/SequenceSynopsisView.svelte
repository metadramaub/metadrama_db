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
	{@const borderColor = cardBorderColor(item.card)}
	<div class="flex items-stretch gap-2">
		<!-- **La banda dice dónde cambia el cuadro, y dónde cae el cambio.** Antes eran dos avisos
		     entre tarjetas —«inicia» y «sigue»— que elegían uno u otro según dónde hubiera acabado
		     la anterior: fallaba, y además mentía, porque el corte no cae entre dos tarjetas sino
		     dentro de una. Aquí se pinta a su altura real, que es un porcentaje de la propia
		     tarjeta y por eso vale igual con una sinopsis larga que con una vacía. -->
		{#if item.card.banda.length > 0}
			<span class="relative w-32 shrink-0 pr-4">
				<!-- **El cuadro se dice con palabras y se sitúa con una raya**, como en el esquema métrico.
				     La etiqueta va **a la altura del corte** y no arriba de la tarjeta, que es donde caía
				     antes: puesta arriba quedaba dentro del cuadro anterior. Y la raya es la misma en todo
				     el recorrido del cuadro, para que se lea que cubre todas esas secuencias; lo que marca
				     el corte es el travesaño. -->
				{#each item.card.banda as tramo, i (i)}
					{#if tramo.numero !== null}
						<span
							class="absolute right-1 w-px bg-[color:var(--gray-800)]"
							style={`top:${tramo.desde * 100}%;height:${tramo.alto * 100}%`}
							title={tramo.abre
								? `Cuadro ${tramo.numero}, desde el v. ${tramo.verso}`
								: `Cuadro ${tramo.numero}`}
						>
							{#if tramo.abre}
								<span class="absolute -left-[3px] top-0 h-px w-[7px] bg-[color:var(--gray-800)]"></span>
							{/if}
						</span>
					{/if}
					{#if tramo.abre && tramo.numero !== null}
						<span
							class="absolute right-4 flex flex-col items-end gap-[1px] whitespace-nowrap text-right"
							style={`top:${tramo.desde * 100}%`}
						>
							<span class="text-[0.6875rem] font-semibold uppercase tracking-[0.06em]">
								Cuadro {tramo.numero}
							</span>
							{#if tramo.verso !== null && tramo.verso !== item.card.vIni}
								<span class="text-[0.6875rem] tabular-nums text-[color:var(--muted-foreground)]">
									desde el v. {tramo.verso}
								</span>
							{/if}
						</span>
					{/if}
				{/each}
				{#if item.card.banda[item.card.banda.length - 1]?.numero !== null}
					<!-- **El hueco entre tarjetas también es cuadro.** Las tarjetas van separadas, así que
					     la línea se partía en cada secuencia y no se leía como una sola: este tramo salta
					     el hueco. Va en unidades absolutas y no en porcentaje, para no tocar la
					     proporción con la que se sitúa el corte dentro de la tarjeta. -->
					<span class="absolute right-1 h-1 w-px bg-[color:var(--gray-800)]" style="top:100%"></span>
				{/if}
			</span>
		{/if}
		<!-- La banda de color va gruesa: es lo que identifica la forma de un vistazo, y a dos
		     píxeles no se distinguía un azul de otro. -->
		<article
			class={`min-w-0 flex-1 border-l-[6px] py-4 pl-4 ${
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
	</div>
{/snippet}

{#if props.groups.length === 0}
	<div class="border border-dashed border-[color:var(--border)] p-6 text-sm text-[color:var(--muted-foreground)]">
		No hay secuencias registradas para construir la sinopsis completa.
	</div>
{:else}
	<div class="grid gap-6 lg:grid-cols-[14rem_minmax(0,1fr)]">
		<nav aria-label="Navegación de sinopsis" class="lg:sticky lg:top-4 lg:self-start">
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
