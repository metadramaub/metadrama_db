<script lang="ts">
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

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
</script>

<svelte:head>
	<title>Equipo · Versología</title>
	<meta
		name="description"
		content="Responsables y colaboradores de Versología, proyecto de MetaDrama."
	/>
</svelte:head>

<section class="pb-16 pt-10 md:pb-24 md:pt-16">
	<header class="max-w-3xl border-l-2 border-[color:var(--primary)] pl-5 md:pl-7">
		<p class="text-[10px] font-semibold tracking-[0.2em] text-[color:var(--primary)]">PROYECTO</p>
		<h1 class="font-display mt-3 text-4xl text-[color:var(--gray-900)] md:text-5xl">Equipo</h1>
		<p class="mt-4 max-w-2xl text-sm leading-7 text-[color:var(--muted-foreground)]">
			Responsables y colaboradores de Versología.
		</p>
	</header>

	<div class="mt-12 grid gap-4 lg:grid-cols-5">
		<article
			class="flex min-h-64 flex-col justify-between border border-[color:var(--gray-800)] bg-[color:var(--gray-900)] p-7 text-white md:p-9 lg:col-span-2"
		>
			<p class="text-[10px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">
				INVESTIGADOR PRINCIPAL
			</p>
			<h2 class="font-display max-w-xl text-3xl leading-tight md:text-4xl">Gaston Gilabert</h2>
		</article>

		<article
			class="flex min-h-64 flex-col justify-between border border-[color:var(--border)] bg-white p-7 md:p-9 lg:col-span-3"
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
							class="flex min-h-40 flex-col justify-between border border-[color:var(--border)] bg-white p-6"
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

								{#if persona.obras.length > 0}
									<div class="mt-6 border-t border-[color:var(--border)] pt-4">
										<p class="text-[10px] font-semibold tracking-[0.14em] text-[color:var(--gray-400)]">
											{fichasLabel(persona.total_obras)}
										</p>
										<ul class="mt-3 space-y-2">
											{#each persona.obras as obra (obra.slug)}
												<li>
													<a
														href={`/obras/${obra.slug}`}
														class="font-display text-base text-[color:var(--gray-900)] underline decoration-[color:var(--gray-300)] underline-offset-4 hover:decoration-[color:var(--primary)]"
													>
														{obra.titulo}
													</a>
												</li>
											{/each}
										</ul>
									</div>
								{/if}
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
