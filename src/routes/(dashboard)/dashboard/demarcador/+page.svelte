<script lang="ts">
	import { untrack } from 'svelte';
	import type {
		FamiliaAuditoria,
		PoliticaFamiliaDemarcador,
		ResultadoAuditoria
	} from '$lib/demarcador/auditoria';
	import { pushToast } from '$lib/stores/toast';

	type AuditorPageData = {
		auditoria: ResultadoAuditoria;
		versiones: VersionDemarcador[];
	};

	let { data } = $props<{ data: AuditorPageData }>();

	type FiltroRevision = 'todas' | 'avisos' | 'sin_revisar';
	type CambioPolitica = {
		familia_id: string;
		politica: PoliticaFamiliaDemarcador;
	};
	type VersionDemarcador = {
		version_id: string;
		numero: number;
		estado: string;
		fuente_actualizada_en: string | null;
		total_familias: number;
		total_familias_variantes: number;
		total_variantes_demarcables: number;
		generado_en: string;
		publicado_en: string | null;
	};

	let busqueda = $state('');
	let filtro = $state<FiltroRevision>('todas');
	let guardandoPoliticas = $state(false);
	let errorGuardado = $state('');
	let politicasGuardadas = $state<Record<string, PoliticaFamiliaDemarcador>>({});
	let politicasBorrador = $state<Record<string, PoliticaFamiliaDemarcador | ''>>({});
	let versiones = $state<VersionDemarcador[]>(untrack(() => data.versiones));
	let generandoVersion = $state(false);
	let publicandoVersionId = $state<string | null>(null);
	let errorVersion = $state('');

	const familiasFiltradas = $derived.by(() => {
		const termino = busqueda.trim().toLocaleLowerCase('es');
		return data.auditoria.familias.filter((familia: FamiliaAuditoria) => {
			const coincideBusqueda =
				!termino ||
				familia.nombre.toLocaleLowerCase('es').includes(termino) ||
				familia.slug.toLocaleLowerCase('es').includes(termino) ||
				familia.hijos.some(
					(hijo: FamiliaAuditoria['hijos'][number]) =>
						hijo.nombre.toLocaleLowerCase('es').includes(termino) ||
						hijo.slug.toLocaleLowerCase('es').includes(termino)
				);
			if (!coincideBusqueda) return false;
			if (filtro === 'avisos') return familia.avisos.length > 0;
			if (filtro === 'sin_revisar') return !politicaGuardada(familia);
			return true;
		});
	});

	const resumenPoliticas = $derived.by(() => {
		const guardadas = data.auditoria.familias.filter(
			(familia: FamiliaAuditoria) => Boolean(politicaGuardada(familia))
		).length;
		return {
			guardadas,
			pendientes: data.auditoria.familias.length - guardadas
		};
	});

	const familiasModificadas = $derived.by(() =>
		data.auditoria.familias.filter(
			(familia: FamiliaAuditoria) =>
				Boolean(politicaBorrador(familia)) && estaModificada(familia)
		)
	);
	const versionPublicada = $derived(
		versiones.find((version) => version.estado === 'publicada') ?? null
	);
	const ultimaVersion = $derived(versiones[0] ?? null);

	function politicaLabel(politica: PoliticaFamiliaDemarcador | null): string {
		if (politica === 'familia') return 'Solo familia';
		if (politica === 'variantes') return 'Distinguir variantes';
		return 'Política pendiente';
	}

	function politicaGuardada(
		familia: FamiliaAuditoria
	): PoliticaFamiliaDemarcador | null {
		return politicasGuardadas[familia.id] ?? familia.politica;
	}

	function politicaBorrador(
		familia: FamiliaAuditoria
	): PoliticaFamiliaDemarcador | '' {
		return politicasBorrador[familia.id] ?? politicaGuardada(familia) ?? '';
	}

	function estaModificada(familia: FamiliaAuditoria): boolean {
		return politicaBorrador(familia) !== (politicaGuardada(familia) ?? '');
	}

	async function guardarPoliticas() {
		const cambios: CambioPolitica[] = familiasModificadas.map((familia: FamiliaAuditoria) => ({
			familia_id: familia.id,
			politica: politicaBorrador(familia) as PoliticaFamiliaDemarcador
		}));
		if (cambios.length === 0 || guardandoPoliticas) return;

		guardandoPoliticas = true;
		errorGuardado = '';
		try {
			const response = await fetch('/api/demarcador/familias', {
				method: 'PATCH',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({ configuraciones: cambios })
			});
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) {
				throw new Error(payload.message ?? 'No se pudieron guardar las políticas.');
			}
			politicasGuardadas = {
				...politicasGuardadas,
				...Object.fromEntries(
					cambios.map((cambio: CambioPolitica) => [cambio.familia_id, cambio.politica])
				)
			};
			pushToast(
				'success',
				cambios.length === 1
					? 'Se ha guardado 1 política.'
					: `Se han guardado ${cambios.length} políticas.`
			);
		} catch (error) {
			errorGuardado =
				error instanceof Error ? error.message : 'No se pudieron guardar las políticas.';
		} finally {
			guardandoPoliticas = false;
		}
	}

	async function generarVersion() {
		if (
			generandoVersion ||
			resumenPoliticas.pendientes > 0 ||
			familiasModificadas.length > 0
		) {
			return;
		}
		generandoVersion = true;
		errorVersion = '';
		try {
			const response = await fetch('/api/demarcador/versiones', { method: 'POST' });
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) {
				throw new Error(payload.message ?? 'No se pudo generar la vista previa.');
			}
			const version = payload.version as VersionDemarcador;
			versiones = [
				version,
				...versiones.filter((item) => item.version_id !== version.version_id)
			];
			pushToast(
				'success',
				payload.reutilizada
					? `La versión ${version.numero} ya estaba actualizada.`
					: `Se ha generado la versión ${version.numero}.`
			);
		} catch (error) {
			errorVersion =
				error instanceof Error ? error.message : 'No se pudo generar la vista previa.';
		} finally {
			generandoVersion = false;
		}
	}

	async function publicarVersion(version: VersionDemarcador) {
		if (publicandoVersionId || version.estado === 'publicada') return;
		if (
			!window.confirm(
				`¿Publicar la versión ${version.numero}? Sustituirá al demarcador público actual.`
			)
		) {
			return;
		}
		publicandoVersionId = version.version_id;
		errorVersion = '';
		try {
			const response = await fetch(
				`/api/demarcador/versiones/${version.version_id}/publicar`,
				{ method: 'POST' }
			);
			const payload = await response.json().catch(() => ({}));
			if (!response.ok) {
				throw new Error(payload.message ?? 'No se pudo publicar la versión.');
			}
			const publicada = payload.version as VersionDemarcador;
			versiones = versiones.map((item) => {
				if (item.version_id === publicada.version_id) return publicada;
				if (item.estado === 'publicada') return { ...item, estado: 'archivada' };
				return item;
			});
			pushToast('success', `Se ha publicado la versión ${publicada.numero}.`);
		} catch (error) {
			errorVersion =
				error instanceof Error ? error.message : 'No se pudo publicar la versión.';
		} finally {
			publicandoVersionId = null;
		}
	}
</script>

<svelte:head>
	<title>Auditor del demarcador | METADRAMA</title>
</svelte:head>

<section class="mx-auto w-full max-w-7xl space-y-6 px-4 py-6 sm:px-6 lg:px-8">
	<header class="space-y-2">
		<p class="text-xs font-semibold uppercase tracking-[0.16em] text-[color:var(--muted-foreground)]">
			Vocabularios métricos
		</p>
		<h1 class="text-2xl font-semibold tracking-tight text-[color:var(--foreground)] sm:text-3xl">
			Auditor del demarcador
		</h1>
		<p class="max-w-4xl text-sm leading-6 text-[color:var(--muted-foreground)]">
			Revisa qué familias pueden demarcarse como una sola forma y cuáles tienen variantes
			distinguibles. Las sugerencias se calculan desde los datos actuales, pero solo la política
			revisada por el IP se utiliza al generar una versión.
		</p>
	</header>

	<div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
		<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Familias raíz con hijos activos</p>
			<p class="mt-1 text-2xl font-semibold">{data.auditoria.resumen.familias}</p>
		</div>
		<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Con política guardada</p>
			<p class="mt-1 text-2xl font-semibold">{resumenPoliticas.guardadas}</p>
		</div>
		<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Con política pendiente</p>
			<p class="mt-1 text-2xl font-semibold">{resumenPoliticas.pendientes}</p>
		</div>
		<div class="border border-[color:var(--border)] bg-[color:var(--card)] p-4">
			<p class="text-xs text-[color:var(--muted-foreground)]">Con avisos en los datos</p>
			<p class="mt-1 text-2xl font-semibold">{data.auditoria.resumen.conAvisos}</p>
		</div>
	</div>
	<p class="-mt-3 text-xs text-[color:var(--muted-foreground)]">
		Guardar una política no resuelve ni oculta los avisos de la familia.
	</p>

	<div class="grid gap-3 border-y border-[color:var(--border)] py-4 lg:grid-cols-2">
		<div>
			<p class="text-sm font-medium">Solo familia</p>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				El demarcador termina en la forma raíz. Los hijos siguen visibles como información
				editorial, pero no se preguntan al usuario.
			</p>
		</div>
		<div>
			<p class="text-sm font-medium">Distinguir variantes</p>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Después de identificar la familia, se intenta precisar el hijo con sus diferencias
				declaradas. Los patrones específicos deben quedar para la fase final.
			</p>
		</div>
	</div>

	<section class="border border-[color:var(--border)] bg-[color:var(--card)] p-4 sm:p-5">
		<div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
			<div class="max-w-3xl">
				<p class="text-xs font-semibold uppercase tracking-[0.12em] text-[color:var(--muted-foreground)]">
					Versión precomputada
				</p>
				<h2 class="mt-1 text-lg font-semibold">Vista previa y publicación</h2>
				<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
					Generar crea una instantánea revisable desde los vocabularios y políticas guardados.
					El demarcador público solo cambia al publicar expresamente una versión.
				</p>
			</div>
			<button
				type="button"
				class="h-10 shrink-0 bg-[color:var(--foreground)] px-5 text-sm font-medium text-[color:var(--background)] disabled:cursor-not-allowed disabled:opacity-40"
				disabled={generandoVersion ||
					resumenPoliticas.pendientes > 0 ||
					familiasModificadas.length > 0}
				onclick={generarVersion}
			>
				{generandoVersion ? 'Generando…' : 'Generar vista previa'}
			</button>
		</div>

		{#if resumenPoliticas.pendientes > 0}
			<p class="mt-4 text-sm text-amber-800">
				No se puede generar: quedan {resumenPoliticas.pendientes} políticas pendientes.
			</p>
		{:else if familiasModificadas.length > 0}
			<p class="mt-4 text-sm text-amber-800">
				Guarda primero los cambios de política.
			</p>
		{/if}
		{#if errorVersion}
			<p class="mt-4 text-sm text-red-700">{errorVersion}</p>
		{/if}

		{#if ultimaVersion}
			<div class="mt-5 grid gap-4 border-t border-[color:var(--border)] pt-4 lg:grid-cols-[minmax(0,1fr)_auto]">
				<div>
					<div class="flex flex-wrap items-center gap-x-3 gap-y-1">
						<p class="font-medium">Versión {ultimaVersion.numero}</p>
						<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
							{ultimaVersion.estado}
						</span>
					</div>
					<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
						{ultimaVersion.total_familias} familias ·
						{ultimaVersion.total_familias_variantes} con variantes demarcables ·
						{ultimaVersion.total_variantes_demarcables} variantes
					</p>
					<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
						Generada {new Date(ultimaVersion.generado_en).toLocaleString('es-ES')}
						{#if versionPublicada}
							· Publicada actualmente: versión {versionPublicada.numero}
						{/if}
					</p>
				</div>
				<div class="flex flex-wrap gap-2">
					<a
						class="inline-flex h-10 items-center border border-[color:var(--border)] px-4 text-sm font-medium"
						href={`/demarcador?version=${ultimaVersion.version_id}`}
						target="_blank"
						rel="noreferrer"
					>
						Abrir vista previa
					</a>
					<button
						type="button"
						class="h-10 bg-[color:var(--foreground)] px-4 text-sm font-medium text-[color:var(--background)] disabled:cursor-not-allowed disabled:opacity-40"
						disabled={ultimaVersion.estado === 'publicada' || Boolean(publicandoVersionId)}
						onclick={() => publicarVersion(ultimaVersion)}
					>
						{publicandoVersionId === ultimaVersion.version_id
							? 'Publicando…'
							: ultimaVersion.estado === 'publicada'
								? 'Versión publicada'
								: 'Publicar versión'}
					</button>
				</div>
			</div>
		{:else}
			<p class="mt-5 border-t border-[color:var(--border)] pt-4 text-sm text-[color:var(--muted-foreground)]">
				Todavía no se ha generado ninguna versión.
			</p>
		{/if}
	</section>

	<div class="flex flex-col gap-3 sm:flex-row">
		<label class="flex-1">
			<span class="sr-only">Buscar familia o variante</span>
			<input
				class="h-10 w-full border border-[color:var(--border)] bg-[color:var(--background)] px-3 text-sm outline-none focus:border-[color:var(--foreground)]"
				type="search"
				placeholder="Buscar familia o variante"
				bind:value={busqueda}
			/>
		</label>
		<label>
			<span class="sr-only">Filtrar auditoría</span>
			<select
				class="h-10 min-w-48 border border-[color:var(--border)] bg-[color:var(--background)] px-3 text-sm"
				bind:value={filtro}
			>
				<option value="todas">Todas las familias</option>
				<option value="avisos">Con avisos de fuente</option>
				<option value="sin_revisar">Con política pendiente</option>
			</select>
		</label>
	</div>

	<div class="sticky bottom-4 z-10 flex flex-col gap-3 border border-[color:var(--border)] bg-[color:var(--background)] p-3 shadow-lg sm:flex-row sm:items-center sm:justify-between">
		<div>
			<p class="text-sm font-medium">
				{#if familiasModificadas.length === 0}
					No hay cambios sin guardar
				{:else if familiasModificadas.length === 1}
					1 política modificada sin guardar
				{:else}
					{familiasModificadas.length} políticas modificadas sin guardar
				{/if}
			</p>
			{#if errorGuardado}
				<p class="mt-1 text-sm text-red-700">{errorGuardado}</p>
			{:else if familiasModificadas.length > 0}
				<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
					Se guardarán juntas, incluidas las familias ocultas por el filtro.
				</p>
			{/if}
		</div>
		<button
			type="button"
			class="h-10 shrink-0 bg-[color:var(--foreground)] px-5 text-sm font-medium text-[color:var(--background)] transition-opacity disabled:cursor-not-allowed disabled:opacity-40"
			disabled={familiasModificadas.length === 0 || guardandoPoliticas}
			onclick={guardarPoliticas}
		>
			{guardandoPoliticas
				? 'Guardando…'
				: `Guardar cambios${familiasModificadas.length > 0 ? ` (${familiasModificadas.length})` : ''}`}
		</button>
	</div>

	<div class="space-y-4">
		{#each familiasFiltradas as familia (familia.id)}
			<article class="border border-[color:var(--border)] bg-[color:var(--card)]">
				<div class="grid gap-5 p-4 lg:grid-cols-[minmax(0,1fr)_20rem] lg:p-5">
					<div class="min-w-0 space-y-4">
						<div>
							<div class="flex flex-wrap items-baseline gap-x-3 gap-y-1">
								<h2 class="text-lg font-semibold">{familia.nombre}</h2>
								<span class="font-mono text-xs text-[color:var(--muted-foreground)]">
									{familia.slug}
								</span>
								<span class="text-xs text-[color:var(--muted-foreground)]">
									{familia.hijos.length}
									{familia.hijos.length === 1 ? 'variante' : 'variantes'}
								</span>
							</div>
							<p class="mt-2 text-sm leading-6 text-[color:var(--muted-foreground)]">
								<span class="font-medium text-[color:var(--foreground)]">
									Sugerencia: {politicaLabel(familia.sugerencia)}.
								</span>
								{familia.razonSugerencia}
							</p>
						</div>

						{#if familia.rasgosDiferenciadores.length > 0}
							<p class="text-sm">
								<span class="text-[color:var(--muted-foreground)]">Diferencias:</span>
								{familia.rasgosDiferenciadores.join(', ')}.
							</p>
						{/if}

						{#if familia.avisos.length > 0}
							<div class="space-y-2 border-l-2 border-amber-400 pl-3">
								<p class="text-xs font-semibold uppercase tracking-wide text-amber-800">
									Revisar en la fuente
								</p>
								<ul class="space-y-1 text-sm text-amber-950">
									{#each familia.avisos as aviso}
										<li>{aviso.mensaje}</li>
									{/each}
								</ul>
							</div>
						{/if}

						<details>
							<summary class="cursor-pointer text-sm font-medium">
								Ver datos de las variantes
							</summary>
							<div class="mt-3 overflow-x-auto">
								<table class="w-full min-w-[48rem] border-collapse text-left text-sm">
									<thead>
										<tr class="border-b border-[color:var(--border)] text-xs text-[color:var(--muted-foreground)]">
											<th class="px-2 py-2 font-medium">Variante</th>
											<th class="px-2 py-2 font-medium">Metro</th>
											<th class="px-2 py-2 font-medium">Rima</th>
											<th class="px-2 py-2 font-medium">Naturaleza</th>
											<th class="px-2 py-2 font-medium">Tamaño</th>
											<th class="px-2 py-2 font-medium">Patrón</th>
										</tr>
									</thead>
									<tbody>
										{#each familia.hijos as hijo}
											<tr class="border-b border-[color:var(--border)] last:border-0">
												<td class="px-2 py-2 align-top font-medium">
													{hijo.nombre}
													<a
														class="ml-1 text-xs font-normal underline decoration-dotted underline-offset-2"
														href={`/dashboard/vocabularios/estrofa_tipo?termino=${hijo.id}`}
													>
														editar
													</a>
												</td>
												{#each hijo.rasgos as rasgo}
													<td
														class={`px-2 py-2 align-top ${
															rasgo.demarcador ? 'font-medium text-[color:var(--foreground)]' : 'text-[color:var(--muted-foreground)]'
														}`}
													>
														{rasgo.valor}
														{#if rasgo.heredado}
															<span class="block text-[0.7rem] font-normal">heredado</span>
														{/if}
													</td>
												{/each}
											</tr>
										{/each}
									</tbody>
								</table>
							</div>
						</details>
					</div>

					<div class="space-y-3 border-t border-[color:var(--border)] pt-4 lg:border-l lg:border-t-0 lg:pl-5 lg:pt-0">
						<label class="block text-sm font-medium" for={`politica-${familia.id}`}>
							Política revisada
						</label>
						<select
							id={`politica-${familia.id}`}
							class="h-10 w-full border border-[color:var(--border)] bg-[color:var(--background)] px-3 text-sm disabled:opacity-60"
							value={politicaBorrador(familia)}
							disabled={guardandoPoliticas}
							onchange={(event) => {
								politicasBorrador = {
									...politicasBorrador,
									[familia.id]: event.currentTarget.value as PoliticaFamiliaDemarcador | ''
								};
							}}
						>
							<option value="" disabled>Política pendiente</option>
							<option value="familia">Solo familia</option>
							<option value="variantes">Distinguir variantes</option>
						</select>
						<p
							class={`text-xs ${
								estaModificada(familia)
									? 'font-medium text-amber-800'
									: 'text-[color:var(--muted-foreground)]'
							}`}
						>
							{estaModificada(familia)
								? 'Cambio sin guardar'
								: politicaGuardada(familia)
									? 'Política guardada'
									: 'Política pendiente'}
						</p>
						<a
							class="block text-center text-sm underline decoration-dotted underline-offset-4"
							href={`/dashboard/vocabularios/estrofa_tipo?termino=${familia.id}`}
						>
							Editar familia en vocabularios
						</a>
					</div>
				</div>
			</article>
		{:else}
			<p class="border border-dashed border-[color:var(--border)] px-4 py-10 text-center text-sm text-[color:var(--muted-foreground)]">
				No hay familias que coincidan con este filtro.
			</p>
		{/each}
	</div>
</section>
