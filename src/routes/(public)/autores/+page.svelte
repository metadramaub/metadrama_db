<script lang="ts">
	import {
		buildPerfilSlices,
		fiabilidadDeVersos,
		type AutorListadoItem,
		type FiabilidadNivel
	} from '$lib/autores/perfil-autor';
	import AuthorPortrait from '$lib/components/public/AuthorPortrait.svelte';
	import MiniMetricDonut from '$lib/components/metrica/MiniMetricDonut.svelte';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	const autores = $derived(data.autores as AutorListadoItem[]);
	// La prueba de fiabilidad queda disponible para reactivarla, pero no se muestra públicamente.
	const mostrarFiabilidad = false;
	let nameQuery = $state('');

	const filteredAutores = $derived.by(() => {
		const q = normalizeForSearch(nameQuery);
		if (!q) return autores;
		return autores.filter((autor) => normalizeForSearch(autor.nombre_completo).includes(q));
	});

	const fiabilidadDot: Record<FiabilidadNivel, string> = {
		baja: 'bg-amber-400',
		media: 'bg-sky-400',
		alta: 'bg-emerald-500'
	};

	function fmtNumeroEfectivo(value: number | null): string {
		if (value === null) return '—';
		return value.toLocaleString('es-ES', { maximumFractionDigits: 1 });
	}

	function normalizeForSearch(value: string): string {
		return value
			.normalize('NFD')
			.replace(/[\u0300-\u036f]/g, '')
			.toLocaleLowerCase('es-ES')
			.trim();
	}

</script>

<section class="space-y-6">
	<div class="flex flex-wrap items-end justify-between gap-4">
		<div>
			<h1 class="font-display text-3xl text-[color:var(--gray-900)]">Autores</h1>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Dramaturgos con perfil métrico agregado a partir de sus obras de autoría individual segura.
			</p>
		</div>

		<label class="w-full max-w-xs text-xs font-semibold text-[color:var(--muted-foreground)]">
			<span class="sr-only">Filtrar por nombre completo</span>
			<input
				type="search"
				bind:value={nameQuery}
				placeholder="Filtrar por nombre"
				aria-label="Filtrar autores por nombre completo"
				class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm font-normal text-[color:var(--foreground)] placeholder:text-[color:var(--muted-foreground)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)]"
			/>
		</label>
	</div>

	{#if autores.length === 0}
		<div class="card p-6 text-sm text-[color:var(--muted-foreground)]">
			Todavía no hay autores con perfil métrico publicado.
		</div>
	{:else if filteredAutores.length === 0}
		<div class="card p-6 text-sm text-[color:var(--muted-foreground)]">
			Ningún autor coincide con «{nameQuery}».
		</div>
	{:else}
		<ul class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
			{#each filteredAutores as autor (autor.slug)}
				{@const slices = buildPerfilSlices(autor.perfil_formas, data.formaLabels ?? {})}
				{@const fiabilidad = fiabilidadDeVersos(autor.total_versos_autor)}
				<li class="card overflow-hidden">
					<a class="block" href={`/autores/${autor.slug}`} aria-label={`Abrir perfil de ${autor.nombre_completo}`}>
						<div class="aspect-[4/3] bg-[color:var(--gray-100)]">
							<AuthorPortrait src={autor.imagen_wikidata?.url} alt={autor.nombre_completo} />
						</div>
					</a>

					<div class="p-4">
						<a
							class="font-display text-xl leading-tight text-[color:var(--gray-900)] underline-offset-2 hover:underline"
							href={`/autores/${autor.slug}`}
						>
							{autor.nombre_completo}
						</a>

						<div class="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-[color:var(--muted-foreground)]">
							<span>
								{autor.n_obras_completas}
								{autor.n_obras_completas === 1 ? 'obra' : 'obras'}
								{#if autor.n_jornadas_sueltas > 0}
									· {autor.n_jornadas_sueltas}
									{autor.n_jornadas_sueltas === 1 ? 'jornada' : 'jornadas'}
								{/if}
							</span>
							<span>{autor.total_versos_autor.toLocaleString('es-ES')} vv.</span>
							<span title="Diversidad del repertorio (número efectivo de formas agregado)">
								diversidad {fmtNumeroEfectivo(autor.numero_efectivo_formas_agregado)}
							</span>
							{#if mostrarFiabilidad}
								<span class="inline-flex items-center gap-1" title={`Fiabilidad ${fiabilidad}`}>
									<span class={`inline-block h-2 w-2 rounded-full ${fiabilidadDot[fiabilidad]}`}></span>
									{fiabilidad}
								</span>
							{/if}
						</div>

						<div class="mt-5">
							<MiniMetricDonut {slices} size="md" />
						</div>
					</div>
				</li>
			{/each}
		</ul>
	{/if}
</section>
