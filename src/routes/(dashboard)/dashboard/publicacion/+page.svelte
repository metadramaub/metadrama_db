<script lang="ts">
	import type { PageData } from './$types';
	import type { PublicSection, SectionScope } from '$lib/secciones-publicas';

	let { data } = $props<{ data: PageData }>();

	const SCOPE_LABELS: Record<SectionScope, string> = {
		anon: 'Cualquiera (público)',
		authenticated: 'Solo con login',
		admin_ip: 'Solo admin/IP'
	};
	const SCOPE_ORDER: SectionScope[] = ['anon', 'authenticated', 'admin_ip'];

	function cloneSections(sections: PublicSection[]): PublicSection[] {
		return sections.map((section) => ({ ...section }));
	}

	function getInitialPaginas(): PublicSection[] {
		return cloneSections(data.paginas);
	}

	function getInitialCatalogo(): PublicSection[] {
		return cloneSections(data.catalogo);
	}

	function getInitialFicha(): PublicSection[] {
		return cloneSections(data.ficha);
	}

	let paginas = $state<PublicSection[]>(getInitialPaginas());
	let catalogo = $state<PublicSection[]>(getInitialCatalogo());
	let ficha = $state<PublicSection[]>(getInitialFicha());

	let status = $state<Record<string, 'idle' | 'saving' | 'saved' | 'error'>>({});
	let errors = $state<Record<string, string>>({});

	async function patchSeccion(seccion: PublicSection, patch: Partial<Pick<PublicSection, 'activa' | 'scope_minimo'>>) {
		status = { ...status, [seccion.seccion_id]: 'saving' };
		errors = { ...errors, [seccion.seccion_id]: '' };
		try {
			const resp = await fetch(`/api/secciones-publicas/${encodeURIComponent(seccion.seccion_id)}`, {
				method: 'PATCH',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify(patch)
			});
			if (!resp.ok) {
				const detail = await resp.json().catch(() => ({}));
				throw new Error(detail.message ?? `Error ${resp.status}`);
			}
			status = { ...status, [seccion.seccion_id]: 'saved' };
			setTimeout(() => {
				status = { ...status, [seccion.seccion_id]: 'idle' };
			}, 1500);
		} catch (err) {
			status = { ...status, [seccion.seccion_id]: 'error' };
			errors = {
				...errors,
				[seccion.seccion_id]: err instanceof Error ? err.message : 'Error desconocido'
			};
		}
	}

	function toggleActiva(seccion: PublicSection) {
		seccion.activa = !seccion.activa;
		patchSeccion(seccion, { activa: seccion.activa });
	}

	function changeScope(seccion: PublicSection, value: SectionScope) {
		seccion.scope_minimo = value;
		patchSeccion(seccion, { scope_minimo: value });
	}

	let recomputeStatus = $state<'idle' | 'running' | 'done' | 'error'>('idle');
	let recomputeMessage = $state('');

	type RecomputeAllResponse = {
		obrasResumen?: number | null;
		obrasPublicadas?: number | null;
		autoresPerfilMetrico?: number | null;
		autoresVinculadosPublicados?: number | null;
		obras?: number | null;
		autores?: number | null;
		message?: string;
	};

	function formatRecomputeMessage(body: RecomputeAllResponse): string {
		const obrasResumen = body.obrasResumen ?? body.obras ?? null;
		const autoresPerfilMetrico = body.autoresPerfilMetrico ?? body.autores ?? null;
		const parts: string[] = [];

		if (typeof obrasResumen === 'number') {
			parts.push(
				`${obrasResumen} resúmenes de obra${typeof body.obrasPublicadas === 'number' ? ` (${body.obrasPublicadas} obras publicadas)` : ''}`
			);
		}
		if (typeof autoresPerfilMetrico === 'number') {
			parts.push(`${autoresPerfilMetrico} perfiles métricos de autor`);
		}

		const base = parts.length > 0 ? `Datos públicos recalculados: ${parts.join(' y ')}.` : 'Datos públicos recalculados.';
		if (
			typeof body.autoresVinculadosPublicados === 'number' &&
			typeof autoresPerfilMetrico === 'number' &&
			body.autoresVinculadosPublicados > autoresPerfilMetrico
		) {
			return `${base} Hay ${body.autoresVinculadosPublicados} autores vinculados a obras publicadas; solo los autores con unidades métricas inequívocas generan perfil.`;
		}
		return base;
	}

	async function recomputeAll() {
		if (recomputeStatus === 'running') return;
		recomputeStatus = 'running';
		recomputeMessage = '';
		try {
			const resp = await fetch('/api/datos-publicos/recompute-all', { method: 'POST' });
			const body = await resp.json().catch(() => ({}));
			if (!resp.ok) {
				throw new Error(body.message ?? `Error ${resp.status}`);
			}
			recomputeStatus = 'done';
			recomputeMessage = formatRecomputeMessage(body as RecomputeAllResponse);
			setTimeout(() => {
				if (recomputeStatus === 'done') recomputeStatus = 'idle';
			}, 4000);
		} catch (err) {
			recomputeStatus = 'error';
			recomputeMessage = err instanceof Error ? err.message : 'Error desconocido';
		}
	}
</script>

{#snippet seccionRow(seccion: PublicSection)}
	<div class="flex flex-wrap items-center gap-4 border-b border-[color:var(--border)] py-3 last:border-b-0">
		<div class="min-w-0 flex-1">
			<div class="font-semibold text-[color:var(--gray-900)]">{seccion.label}</div>
			{#if seccion.descripcion}
				<div class="text-xs text-[color:var(--muted-foreground)]">{seccion.descripcion}</div>
			{/if}
			<div class="mt-0.5 text-[11px] text-[color:var(--muted-foreground)]">{seccion.seccion_id}</div>
		</div>

		<label class="flex items-center gap-2 text-sm">
			<input type="checkbox" checked={seccion.activa} onchange={() => toggleActiva(seccion)} />
			<span class={seccion.activa ? 'font-semibold text-emerald-700' : 'text-[color:var(--muted-foreground)]'}>
				{seccion.activa ? 'Activa' : 'Apagada'}
			</span>
		</label>

		<label class="flex items-center gap-2 text-sm">
			<span class="text-xs text-[color:var(--muted-foreground)]">Visible para:</span>
			<select
				class="border border-[color:var(--border)] px-2 py-1 text-sm"
				value={seccion.scope_minimo}
				disabled={!seccion.activa}
				onchange={(event) => changeScope(seccion, event.currentTarget.value as SectionScope)}
			>
				{#each SCOPE_ORDER as scope}
					<option value={scope}>{SCOPE_LABELS[scope]}</option>
				{/each}
			</select>
		</label>

		<div class="w-24 text-right text-xs">
			{#if status[seccion.seccion_id] === 'saving'}
				<span class="text-[color:var(--muted-foreground)]">Guardando...</span>
			{:else if status[seccion.seccion_id] === 'saved'}
				<span class="text-emerald-700">Guardado</span>
			{:else if status[seccion.seccion_id] === 'error'}
				<span class="text-red-600" title={errors[seccion.seccion_id]}>Error</span>
			{/if}
		</div>
	</div>
{/snippet}

<section class="space-y-6">
	<div>
		<h1 class="font-display text-3xl">Publicación</h1>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Enciende o apaga secciones de la zona pública y define quién puede verlas. Los cambios
			se aplican al instante. No afectan al muro de publicación: una obra sigue necesitando estar
			publicada y visible para aparecer en público.
		</p>
	</div>

	<div class="card p-4">
		<h2 class="font-display text-xl">Páginas</h2>
		<div class="mt-2">
			{#each paginas as seccion (seccion.seccion_id)}
				{@render seccionRow(seccion)}
			{/each}
		</div>
	</div>

	{#if catalogo.length > 0}
		<div class="card p-4">
			<h2 class="font-display text-xl">Catálogo</h2>
			<div class="mt-2">
				{#each catalogo as seccion (seccion.seccion_id)}
					{@render seccionRow(seccion)}
				{/each}
			</div>
		</div>
	{/if}

	<div class="card p-4">
		<h2 class="font-display text-xl">Secciones de la ficha de obra</h2>
		<div class="mt-2">
			{#each ficha as seccion (seccion.seccion_id)}
				{@render seccionRow(seccion)}
			{/each}
		</div>
	</div>

	<div class="card p-4">
		<h2 class="font-display text-xl">Datos métricos precomputados</h2>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Recalcula los datos métricos públicos (barcode, perfil de formas, filtros del catálogo) de
			<strong>todas las obras publicadas</strong> y, encadenado, los <strong>perfiles métricos de
			autor</strong>. Normalmente cada obra se actualiza con su propio botón al editarla (que también
			refresca a sus autores); usa esto para una reconstrucción global tras un cambio que afecte a
			todas (por ejemplo, renombrar formas en el vocabulario) o para poblar todo por primera vez.
		</p>
		<div class="mt-3 flex flex-wrap items-center gap-3">
			<button
				type="button"
				class="border border-[color:var(--border)] bg-[color:var(--gray-900)] px-3 py-2 text-sm text-white hover:opacity-90 disabled:opacity-50"
				disabled={recomputeStatus === 'running'}
				onclick={recomputeAll}
			>
				{recomputeStatus === 'running' ? 'Recalculando...' : 'Recalcular todos los datos públicos'}
			</button>
			{#if recomputeStatus === 'done'}
				<span class="text-sm text-emerald-700">{recomputeMessage}</span>
			{:else if recomputeStatus === 'error'}
				<span class="text-sm text-red-600">{recomputeMessage}</span>
			{/if}
		</div>
	</div>
</section>
