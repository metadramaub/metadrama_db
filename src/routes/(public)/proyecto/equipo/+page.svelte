<script lang="ts">
	import X from 'lucide-svelte/icons/x';
	import PublicPageHeader from '$lib/components/public/PublicPageHeader.svelte';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
	let colaboradorConFichas = $state<PageData['colaboradores'][number] | null>(null);

	function normalizeOrcid(value: string | null): string | null {
		const identifier = value
			?.trim()
			.replace(/^https?:\/\/(?:www\.)?orcid\.org\//i, '')
			.toUpperCase();

		return identifier && /^\d{4}-\d{4}-\d{4}-\d{3}[\dX]$/.test(identifier)
			? identifier
			: null;
	}

	function fichasLabel(total: number): string {
		return total === 1 ? '1 ficha publicada' : `${total} fichas publicadas`;
	}

	function closeFichaList() {
		colaboradorConFichas = null;
	}

	function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'Escape') closeFichaList();
	}
</script>

<svelte:window onkeydown={handleKeydown} />

<svelte:head>
	<title>Equipo · Versología</title>
	<meta
		name="description"
		content="Responsables y colaboradores de Versología, proyecto de METADRAMA."
	/>
</svelte:head>

<section class="pb-16 pt-10 md:pb-24 md:pt-16">
	<PublicPageHeader
		eyebrow="PROYECTO"
		title="Equipo"
		description="Responsables y colaboradores de Versología."
	/>

	<div class="mt-12 grid gap-4 lg:grid-cols-2">
		<article
			class="flex min-h-64 flex-col justify-between border border-[color:var(--gray-800)] bg-[color:var(--gray-900)] p-7 text-white md:p-9"
		>
			<p class="text-[10px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">
				INVESTIGADOR PRINCIPAL
			</p>
			<h2 class="font-display max-w-xl text-3xl leading-tight md:text-4xl">Gaston Gilabert</h2>
		</article>

		<article
			class="flex min-h-64 flex-col justify-between border border-[color:var(--border)] bg-white p-7 md:p-9"
		>
			<p class="text-[10px] font-semibold leading-5 tracking-[0.18em] text-[color:var(--primary)] lg:whitespace-nowrap">
				DESARROLLO Y COORDINACIÓN DE LA BASE DE DATOS
			</p>
			<h2 class="font-display text-3xl leading-tight text-[color:var(--gray-900)] md:text-4xl">
				David Merino Recalde
			</h2>
		</article>
	</div>

	<section class="mt-16 border-t border-[color:var(--border)] pt-10 md:mt-20 md:pt-12">
		<div class="grid gap-6 lg:grid-cols-3">
			<div>
				<p class="text-[10px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">
					EQUIPO EDITORIAL
				</p>
				<h2 class="font-display mt-3 text-3xl text-[color:var(--gray-900)]">Colaboradores</h2>
				<p class="mt-7 flex items-baseline gap-2 text-[color:var(--muted-foreground)]">
					<span class="font-display text-5xl leading-none text-[color:var(--gray-900)]">
						{data.colaboradores.length}
					</span>
					<span class="text-[10px] font-semibold tracking-[0.16em]">EN TOTAL</span>
				</p>
			</div>

			{#if data.colaboradores.length > 0}
				<ul class="collaborator-grid grid sm:grid-cols-2 lg:col-span-2">
					{#each data.colaboradores as persona, index (persona.nombre_completo)}
						{@const orcid = normalizeOrcid(persona.orcid)}
						<li
							class="flex h-48 flex-col justify-between border border-[color:var(--border)] bg-white p-6"
						>
							<span class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--gray-400)]">
								{String(index + 1).padStart(2, '0')}
							</span>
							<div>
								<div>
									<h3 class="font-display text-xl text-[color:var(--gray-900)]">
										{persona.nombre_completo}
									</h3>
									<div class="mt-3 h-5">
										{#if orcid}
											<a
												href={`https://orcid.org/${orcid}`}
												target="_blank"
												rel="noreferrer noopener"
												class="inline-flex text-[11px] font-semibold tracking-[0.08em] text-[color:var(--primary)] underline decoration-1 underline-offset-4 hover:text-[color:var(--foreground)]"
											>
												ORCID {orcid}
											</a>
										{/if}
									</div>
								</div>

								<div class="mt-6 border-t border-[color:var(--border)] pt-4">
									{#if persona.obras.length > 0}
										<button
											type="button"
											class="text-left text-[10px] font-semibold tracking-[0.14em] text-[color:var(--primary)] underline decoration-1 underline-offset-4 hover:text-[color:var(--foreground)]"
											onclick={() => (colaboradorConFichas = persona)}
										>
											{fichasLabel(persona.total_obras)}
										</button>
									{:else}
										<p class="text-[10px] font-semibold tracking-[0.14em] text-[color:var(--gray-400)]">
											{fichasLabel(0)}
										</p>
									{/if}
								</div>
							</div>
						</li>
					{/each}
				</ul>
			{:else}
				<p class="border border-[color:var(--border)] bg-white p-6 text-sm text-[color:var(--muted-foreground)]">
					No hay colaboradores publicados actualmente.
				</p>
			{/if}
		</div>
	</section>
</section>

{#if colaboradorConFichas}
	<div
		class="fixed inset-0 z-50 flex items-center justify-center bg-black/45 px-4 py-6"
		role="presentation"
		onclick={(event) => {
			if (event.currentTarget === event.target) closeFichaList();
		}}
	>
		<div
			class="max-h-full w-full max-w-lg overflow-y-auto border border-[color:var(--border)] bg-white shadow-xl"
			role="dialog"
			aria-modal="true"
			aria-labelledby="fichas-publicadas-title"
		>
			<header class="sticky top-0 flex items-start justify-between gap-5 border-b border-[color:var(--border)] bg-white px-5 py-4 sm:px-7">
				<div>
					<p class="text-[10px] font-semibold tracking-[0.16em] text-[color:var(--primary)]">
						FICHAS PUBLICADAS
					</p>
					<h2 id="fichas-publicadas-title" class="font-display mt-2 text-2xl text-[color:var(--gray-900)]">
						{colaboradorConFichas.nombre_completo}
					</h2>
				</div>
				<button
					type="button"
					class="inline-flex h-9 w-9 shrink-0 items-center justify-center border border-[color:var(--border)] text-[color:var(--muted-foreground)] transition-colors hover:border-[color:var(--gray-800)] hover:text-[color:var(--foreground)]"
					onclick={closeFichaList}
					aria-label="Cerrar fichas publicadas"
				>
					<X size={17} aria-hidden="true" />
				</button>
			</header>
			<ul class="divide-y divide-[color:var(--border)] p-5 sm:p-7">
				{#each colaboradorConFichas.obras as obra (obra.slug)}
					<li>
						<a
							href={`/obras/${obra.slug}`}
							class="block py-3 font-display text-lg text-[color:var(--gray-900)] underline decoration-[color:var(--gray-300)] underline-offset-4 hover:decoration-[color:var(--primary)]"
						>
							{obra.titulo}
						</a>
					</li>
				{/each}
			</ul>
		</div>
	</div>
{/if}

<style>
	.collaborator-grid > li:not(:first-child) {
		border-top: 0;
	}

	@media (min-width: 640px) {
		.collaborator-grid > li:nth-child(2) {
			border-top: 1px solid var(--border);
		}

		.collaborator-grid > li:nth-child(even) {
			border-left: 0;
		}
	}
</style>
