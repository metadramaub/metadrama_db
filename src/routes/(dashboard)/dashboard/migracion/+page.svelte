<script lang="ts">
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	const esAdminIp = $derived(['admin', 'ip'].includes(data.profile.roleTerm));
</script>

<section class="space-y-4">
	<header>
		<h1 class="font-display text-3xl">MIGRACIÓN MÉTRICA</h1>
		<p class="mt-1 max-w-3xl text-sm text-[color:var(--muted-foreground)]">
			{esAdminIp
				? 'Los informes por obra de la migración al catálogo nuevo, uno por cada obra que aún tiene secuencias anotadas con el vocabulario anterior.'
				: 'Lo que hay que revisar para trasladar la anotación métrica de tus obras al catálogo nuevo.'}
		</p>
	</header>

	{#if data.informes.length === 0}
		<p class="card p-4 text-sm text-[color:var(--muted-foreground)]">
			No hay ningún informe de migración para ti. Si crees que debería haberlo, díselo a quien
			lleva la migración.
		</p>
	{:else}
		<ul class="grid gap-3 sm:grid-cols-2">
			{#each data.informes as informe (informe.slug)}
				<li class="card p-4">
					<a
						class="text-lg font-semibold underline-offset-2 hover:underline"
						href={`/dashboard/migracion/${informe.slug}`}
					>
						{informe.titulo}
					</a>
					{#if esAdminIp && informe.editor}
						<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">{informe.editor}</p>
					{/if}
					<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
						{informe.secuencias} secuencias · {informe.decidir} por decidir · {informe.responder}
						por responder · {informe.confirmar} por confirmar · {informe.desviaciones} desviaciones
					</p>
				</li>
			{/each}
		</ul>
		<p class="max-w-3xl text-sm text-[color:var(--muted-foreground)]">
			Cada informe explica qué se ha encontrado en la obra y qué hace falta preguntar. Las
			respuestas van en el Excel que acompaña al informe y llega por correo.
			{#if data.generado}
				Generados el {data.generado}.
			{/if}
		</p>
	{/if}
</section>
