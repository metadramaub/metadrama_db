<script lang="ts">
	import Breadcrumb from '$lib/components/ui/Breadcrumb.svelte';
	import CatalogResultRow from '$lib/components/catalogo/CatalogResultRow.svelte';
	import MetricDistributionPie from '$lib/components/metrica/MetricDistributionPie.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import {
		buildPerfilSlices,
		fiabilidadDeVersos,
		prettyForma,
		type AutorPublicoObra,
		type AutorPublicoVinculo,
		type FiabilidadNivel
	} from '$lib/autores/perfil-autor';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	const autor = $derived(data.autor);
	const obras = $derived<AutorPublicoObra[]>(data.obras);
	const resumen = $derived(data.resumen);
	const formaLabels = $derived<Record<string, string>>(data.formaLabels ?? {});
	const formaParents = $derived<Record<string, string>>(data.formaParents ?? {});

	const variantesLabel = $derived((autor.variantes_nombre ?? []).join(' · '));

	type AuthorityLink = { label: string; href: string };
	const authorityLinks = $derived.by<AuthorityLink[]>(() => {
		const links: AuthorityLink[] = [];
		if (autor.viaf_id) links.push({ label: 'VIAF', href: `https://viaf.org/viaf/${autor.viaf_id}` });
		if (autor.wikidata_id)
			links.push({ label: 'Wikidata', href: `https://www.wikidata.org/wiki/${autor.wikidata_id}` });
		if (autor.bnedatos_id)
			links.push({ label: 'BNE', href: `https://datos.bne.es/resource/${autor.bnedatos_id}` });
		return links;
	});

	// Perfil agregado → donut (composición, no secuencia). Etiquetas vía vocabulario.
	const perfilSlices = $derived.by(() => buildPerfilSlices(resumen?.perfil_formas));
	const pieItems = $derived.by(() =>
		perfilSlices.map((slice) => ({
			forma: formaLabels[slice.slug] ?? slice.label,
			colorKey: slice.slug,
			versos: slice.versos,
			porcentaje: slice.pct
		}))
	);
	const colorByForma = $derived.by(() =>
		Object.fromEntries(perfilSlices.map((slice) => [slice.slug, slice.color]))
	);

	// Desglose forma raíz → formas hijas: "sequences" sintéticas desde perfil_formas_hijos
	// (cada hoja con su raíz como estrofa_forma_term), para que el pie reconstruya los
	// desplegables igual que la ficha de obra, sin secuencias reales.
	const hijosPerfil = $derived<Record<string, number>>(resumen?.perfil_formas_hijos ?? {});
	const pieSequences = $derived.by(() =>
		Object.entries(hijosPerfil)
			.filter(([, versos]) => versos > 0)
			.map(([childSlug, versos]) => {
				const rootSlug = formaParents[childSlug] ?? childSlug;
				return {
					estrofa_forma_term: formaLabels[rootSlug] ?? prettyForma(rootSlug),
					estrofa_tipo_term: formaLabels[childSlug] ?? prettyForma(childSlug),
					n_versos: versos
				};
			})
	);

	// Hover en la leyenda → resalta el trozo del pie (round-trip; solo afecta a ESTE pie).
	let hoveredForma = $state<string | null>(null);

	const fiabilidad = $derived<FiabilidadNivel | null>(
		resumen ? fiabilidadDeVersos(resumen.total_versos_autor) : null
	);
	const fiabilidadStyle: Record<FiabilidadNivel, string> = {
		baja: 'bg-amber-100 text-amber-800 border-amber-300',
		media: 'bg-sky-100 text-sky-800 border-sky-300',
		alta: 'bg-emerald-100 text-emerald-800 border-emerald-300'
	};
	const fiabilidadLabel: Record<FiabilidadNivel, string> = {
		baja: 'Fiabilidad baja',
		media: 'Fiabilidad media',
		alta: 'Fiabilidad alta'
	};

	function fmtNumeroEfectivo(value: number | null | undefined): string {
		if (value === null || value === undefined) return '—';
		return value.toLocaleString('es-ES', { maximumFractionDigits: 2 });
	}

	function ambitoLabel(v: AutorPublicoVinculo): string {
		return v.scope === 'jornada' ? `Jornada ${v.jornada_num ?? '?'}` : 'Obra completa';
	}
	function composicionLabel(v: AutorPublicoVinculo): string {
		return v.composicion_term === 'colaborada' ? 'en colaboración' : 'individual';
	}

	function initials(name: string): string {
		return name
			.split(/\s+/)
			.filter(Boolean)
			.slice(0, 2)
			.map((part) => part[0]?.toLocaleUpperCase('es-ES') ?? '')
			.join('');
	}

	// Filtro de texto + orden de las obras asociadas.
	let titleQuery = $state('');
	let sortBy = $state<'fecha' | 'titulo'>('fecha');

	// Clave de orden por título normalizado: reubica el artículo inicial al final
	// ("El Caballero de Olmedo" → ordena como "Caballero de Olmedo, El").
	function tituloSortKey(titulo: string): string {
		const m = titulo.match(/^(el|la|los|las|un|una|unos|unas|lo)\s+/i);
		return (m ? titulo.slice(m[0].length) : titulo).toLocaleLowerCase('es');
	}

	const filteredObras = $derived.by(() => {
		const q = titleQuery.trim().toLowerCase();
		const base = q ? obras.filter((obra) => obra.titulo.toLowerCase().includes(q)) : obras;
		const sorted = [...base];
		if (sortBy === 'titulo') {
			sorted.sort((a, b) => tituloSortKey(a.titulo).localeCompare(tituloSortKey(b.titulo), 'es'));
		} else {
			sorted.sort((a, b) => {
				const fa = a.fecha_inicio_trad ?? Number.POSITIVE_INFINITY;
				const fb = b.fecha_inicio_trad ?? Number.POSITIVE_INFINITY;
				return fa - fb || tituloSortKey(a.titulo).localeCompare(tituloSortKey(b.titulo), 'es');
			});
		}
		return sorted;
	});
</script>

<section class="space-y-6">
	<Breadcrumb
		items={[
			{ label: 'Autores', href: '/autores' },
			{ label: autor.nombre_completo, preserveCase: true }
		]}
	/>

	<header class="card overflow-hidden">
		<div class="grid gap-0 md:grid-cols-[16rem_minmax(0,1fr)]">
			<div class="aspect-[4/3] bg-[color:var(--muted)] md:aspect-auto md:min-h-64">
				{#if data.wikidata?.image}
					<img
						src={data.wikidata.image.url}
						alt={autor.nombre_completo}
						class="h-full w-full object-cover"
						loading="lazy"
						referrerpolicy="no-referrer"
					/>
				{:else}
					<div class="flex h-full w-full items-center justify-center text-4xl font-semibold text-[color:var(--muted-foreground)]">
						{initials(autor.nombre_completo)}
					</div>
				{/if}
			</div>

			<div class="flex min-w-0 flex-col justify-between gap-5 p-4 md:p-5">
				<div class="min-w-0">
					<h1 class="font-display text-3xl text-[color:var(--gray-900)] md:text-4xl">
						{autor.nombre_completo}
					</h1>
					{#if variantesLabel}
						<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{variantesLabel}</p>
					{/if}
					{#if data.wikidata?.birthDateLabel || data.wikidata?.deathDateLabel}
						<p class="mt-3 text-sm font-medium text-[color:var(--gray-700)]">
							{data.wikidata?.birthDateLabel ?? '?'} - {data.wikidata?.deathDateLabel ?? '?'}
						</p>
					{/if}
				</div>

				{#if authorityLinks.length > 0}
					<div class="flex flex-wrap items-center gap-2">
						{#each authorityLinks as link (link.label)}
							<a
								class="border border-[color:var(--border)] px-2 py-1 text-xs font-semibold text-[color:var(--muted-foreground)] transition-colors hover:text-[color:var(--foreground)]"
								href={link.href}
								target="_blank"
								rel="noreferrer"
							>
								{link.label} ↗
							</a>
						{/each}
					</div>
				{/if}
			</div>
		</div>
	</header>

	<!-- Perfil métrico -->
	{#if resumen}
		<section class="card p-4 md:p-5">
			<div class="flex flex-wrap items-center justify-between gap-3 border-b border-[color:var(--border)] pb-3">
				<h2 class="font-display text-xl">Perfil métrico</h2>
				{#if fiabilidad}
					<span class="inline-flex items-center gap-1.5">
						<span class={`border px-2 py-0.5 text-xs font-semibold ${fiabilidadStyle[fiabilidad]}`}>
							{fiabilidadLabel[fiabilidad]}
						</span>
						<FieldHelpTooltip
							label="Ayuda: fiabilidad"
							text="Indica cuánto material sostiene el perfil, por el número de versos atribuidos. Baja: poca obra, perfil orientativo. Alta: muchos versos, perfil robusto."
						/>
					</span>
				{/if}
			</div>

			<dl class="mt-4 grid gap-x-6 gap-y-4 text-sm sm:grid-cols-2 xl:grid-cols-4">
				<div>
					<dt class="flex items-center gap-1 text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
						Versos analizados
						<FieldHelpTooltip
							label="Ayuda: versos analizados"
							text="Total de versos que sostienen el perfil: solo obras y jornadas de autoría individual segura (un solo autor)."
						/>
					</dt>
					<dd class="mt-1 font-semibold">{resumen.total_versos_autor.toLocaleString('es-ES')} vv.</dd>
				</div>
				<div>
					<dt class="flex items-center gap-1 text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
						Base del perfil
						<FieldHelpTooltip
							label="Ayuda: base del perfil"
							text="Obras completas y jornadas sueltas (de obras en colaboración) de autoría individual segura sobre las que se calcula el perfil."
						/>
					</dt>
					<dd class="mt-1 font-semibold">
						{resumen.n_obras_completas}
						{resumen.n_obras_completas === 1 ? 'obra' : 'obras'}
						{#if resumen.n_jornadas_sueltas > 0}
							· {resumen.n_jornadas_sueltas}
							{resumen.n_jornadas_sueltas === 1 ? 'jornada' : 'jornadas'}
						{/if}
					</dd>
				</div>
				<div>
					<dt class="flex items-center gap-1 text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
						Diversidad típica por obra
						<FieldHelpTooltip
							label="Ayuda: diversidad típica por obra"
							text="Número efectivo de formas medio por obra completa: cómo de variada es, en promedio, una obra suya. Las jornadas sueltas no entran (serían muestra sesgada)."
						/>
					</dt>
					<dd class="mt-1 font-semibold">
						{fmtNumeroEfectivo(resumen.numero_efectivo_formas_medio)}
					</dd>
				</div>
				<div>
					<dt class="flex items-center gap-1 text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
						Diversidad del repertorio
						<FieldHelpTooltip
							label="Ayuda: diversidad del repertorio"
							text="Número efectivo de formas sobre todo el material agregado (obras y jornadas): cómo de variado es su repertorio total."
						/>
					</dt>
					<dd class="mt-1 font-semibold">
						{fmtNumeroEfectivo(resumen.numero_efectivo_formas_agregado)}
					</dd>
				</div>
			</dl>

			{#if pieItems.length > 0}
				<div class="mt-5">
					<MetricDistributionPie
						items={pieItems}
						colorByForma={colorByForma}
						valueMode="percent"
						title="Repertorio de formas"
						sequences={pieSequences}
						highlightedForma={hoveredForma}
						onHoverForma={(forma) => (hoveredForma = forma)}
					/>
				</div>
			{/if}

			<p class="mt-4 text-xs text-[color:var(--muted-foreground)]">
				El perfil agrega solo las obras y jornadas de autoría individual segura (un solo autor),
				ponderando por extensión. La <em>diversidad típica por obra</em> es la media por obra completa; la
				<em>diversidad del repertorio</em>, sobre el total agregado.
			</p>
		</section>
	{:else}
		<section class="card p-4 text-sm text-[color:var(--muted-foreground)]">
			Este autor todavía no tiene un perfil métrico agregado (sin obras de autoría individual segura
			con datos publicados).
		</section>
	{/if}

	<!-- Obras asociadas -->
	<section class="space-y-3">
		<div class="flex flex-wrap items-center justify-between gap-3">
			<h2 class="font-display text-xl">Obras asociadas</h2>
			{#if obras.length > 0}
				<div class="flex flex-wrap items-center gap-2">
					<select
						bind:value={sortBy}
						aria-label="Ordenar obras"
						class="border border-[color:var(--border)] bg-white px-2 py-1.5 text-sm"
					>
						<option value="fecha">Por fecha</option>
						<option value="titulo">Por título</option>
					</select>
					<input
						type="search"
						bind:value={titleQuery}
						placeholder="Filtrar por título…"
						aria-label="Filtrar obras por título"
						class="w-full max-w-[12rem] border border-[color:var(--border)] bg-white px-3 py-1.5 text-sm"
					/>
				</div>
			{/if}
		</div>

		{#if obras.length === 0}
			<p class="card p-4 text-sm text-[color:var(--muted-foreground)]">
				No hay obras asociadas visibles.
			</p>
		{:else if filteredObras.length === 0}
			<p class="card p-4 text-sm text-[color:var(--muted-foreground)]">
				Ninguna obra coincide con «{titleQuery}».
			</p>
		{:else}
			<div class="grid gap-2">
				{#each filteredObras as obra (obra.obra_id)}
					<CatalogResultRow
						obra={obra}
						canSeeAllPublished={data.canSeeAllPublished}
						showPerfilMetrico={true}
						formaLabels={formaLabels}
					>
						{#snippet titleBadges()}
							{#if obra.sostiene_perfil}
								<span
									class="border border-emerald-300 bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold text-emerald-800"
									title="Esta atribución alimenta el perfil métrico del autor"
								>
									Perfil métrico
								</span>
							{/if}
							{#each obra.vinculos as vinculo, i (i)}
								<span class="inline-flex items-center gap-1 border border-[color:var(--border)] bg-[color:var(--gray-50)] px-2 py-0.5 text-[11px]">
									<span class="font-semibold">{ambitoLabel(vinculo)}</span>
									<span class="text-[color:var(--muted-foreground)]">· {composicionLabel(vinculo)}</span>
									{#if !vinculo.unica_propuesta}
										<span class="text-amber-700">· una de varias propuestas</span>
									{/if}
								</span>
							{/each}
						{/snippet}
					</CatalogResultRow>
				{/each}
			</div>
		{/if}
	</section>
</section>
