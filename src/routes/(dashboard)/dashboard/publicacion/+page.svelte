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

	type RecomputeKind = 'obra' | 'autor' | 'finalize';
	type RecomputePlanItem = { id: string; label: string };
	type RecomputePlanResponse = { obras?: RecomputePlanItem[]; autores?: RecomputePlanItem[] };
	type RecomputeFailure = {
		kind: RecomputeKind;
		id: string;
		label: string;
		message: string;
	};

	let recomputeStatus = $state<'idle' | 'running' | 'done' | 'partial' | 'error'>('idle');
	let recomputeMessage = $state('');
	let recomputeFailures = $state<RecomputeFailure[]>([]);
	let recomputeProgress = $state({ obrasDone: 0, obrasTotal: 0, autoresDone: 0, autoresTotal: 0 });

	async function requestRecompute(action: 'plan' | RecomputeKind, payload: Record<string, string> = {}) {
		const response = await fetch('/api/datos-publicos/recompute-all', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ action, ...payload })
		});
		const body = await response.json().catch(() => ({}));
		if (!response.ok) {
			throw new Error(body.message ?? `Error ${response.status}`);
		}
		return body as RecomputePlanResponse;
	}

	function registerFailure(failure: RecomputeFailure) {
		recomputeFailures = [...recomputeFailures, failure];
	}

	function advanceProgress(kind: Exclude<RecomputeKind, 'finalize'>) {
		if (kind === 'obra') {
			recomputeProgress = { ...recomputeProgress, obrasDone: recomputeProgress.obrasDone + 1 };
			return;
		}
		recomputeProgress = { ...recomputeProgress, autoresDone: recomputeProgress.autoresDone + 1 };
	}

	async function processItems(items: RecomputePlanItem[], kind: Exclude<RecomputeKind, 'finalize'>) {
		for (const item of items) {
			try {
				await requestRecompute(kind, kind === 'obra' ? { obraId: item.id } : { autorId: item.id });
			} catch (error) {
				registerFailure({
					kind,
					id: item.id,
					label: item.label,
					message: error instanceof Error ? error.message : 'Error desconocido'
				});
			} finally {
				advanceProgress(kind);
			}
		}
	}

	async function finalizeRecompute() {
		try {
			await requestRecompute('finalize');
		} catch (error) {
			registerFailure({
				kind: 'finalize',
				id: 'finalize',
				label: 'Limpieza final de perfiles de autor',
				message: error instanceof Error ? error.message : 'Error desconocido'
			});
		}
	}

	function finishRecompute() {
		recomputeStatus = recomputeFailures.length > 0 ? 'partial' : 'done';
		recomputeMessage =
			recomputeFailures.length > 0
				? `Proceso terminado con ${recomputeFailures.length} incidencia${recomputeFailures.length === 1 ? '' : 's'}.`
				: 'Datos públicos actualizados.';
	}

	async function recomputeAll() {
		if (recomputeStatus === 'running') return;
		recomputeStatus = 'running';
		recomputeMessage = 'Preparando el plan de recálculo…';
		recomputeFailures = [];
		recomputeProgress = { obrasDone: 0, obrasTotal: 0, autoresDone: 0, autoresTotal: 0 };

		try {
			const plan = await requestRecompute('plan');
			const obras = Array.isArray(plan.obras) ? plan.obras : [];
			const autores = Array.isArray(plan.autores) ? plan.autores : [];
			recomputeProgress = { obrasDone: 0, obrasTotal: obras.length, autoresDone: 0, autoresTotal: autores.length };
			recomputeMessage = '';
			await processItems(obras, 'obra');
			await processItems(autores, 'autor');
			await finalizeRecompute();
			finishRecompute();
		} catch (error) {
			recomputeStatus = 'error';
			recomputeMessage = error instanceof Error ? error.message : 'No se pudo preparar el recálculo.';
		}
	}

	async function retryFailures() {
		if (recomputeStatus === 'running' || recomputeFailures.length === 0) return;
		const pendingRetries = [...recomputeFailures];
		recomputeStatus = 'running';
		recomputeMessage = `Reintentando ${pendingRetries.length} incidencia${pendingRetries.length === 1 ? '' : 's'}…`;
		recomputeFailures = [];

		for (const failure of pendingRetries) {
			try {
				if (failure.kind === 'obra') {
					await requestRecompute('obra', { obraId: failure.id });
				} else if (failure.kind === 'autor') {
					await requestRecompute('autor', { autorId: failure.id });
				} else {
					await requestRecompute('finalize');
				}
			} catch (error) {
				registerFailure({
					...failure,
					message: error instanceof Error ? error.message : 'Error desconocido'
				});
			}
		}
		finishRecompute();
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
			Reconstruye los datos métricos públicos de todas las obras publicadas y, después, los perfiles
			métricos de autor. Cada elemento se guarda por separado: si uno falla, los anteriores permanecen
			actualizados y se puede reintentar solo ese elemento. Para una obra concreta, usa su botón de
			actualización individual.
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
			{#if recomputeFailures.length > 0 && recomputeStatus !== 'running'}
				<button
					type="button"
					class="border border-[color:var(--border)] px-3 py-2 text-sm text-[color:var(--gray-900)] hover:bg-[color:var(--gray-50)]"
					onclick={retryFailures}
				>
					Reintentar fallidos
				</button>
			{/if}
			{#if recomputeStatus === 'done'}
				<span class="text-sm text-emerald-700">{recomputeMessage}</span>
			{:else if recomputeStatus === 'partial' || recomputeStatus === 'error'}
				<span class="text-sm text-red-600">{recomputeMessage}</span>
			{/if}
		</div>
		{#if recomputeStatus === 'running' || recomputeStatus === 'done' || recomputeStatus === 'partial'}
			<p class="mt-3 text-sm text-[color:var(--muted-foreground)]">
				Obras {recomputeProgress.obrasDone}/{recomputeProgress.obrasTotal} · Autores
				{recomputeProgress.autoresDone}/{recomputeProgress.autoresTotal}
			</p>
		{/if}
		{#if recomputeStatus === 'running' && recomputeMessage}
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{recomputeMessage}</p>
		{/if}
		{#if recomputeFailures.length > 0}
			<ul class="mt-3 space-y-1 border-t border-[color:var(--border)] pt-3 text-sm text-red-700">
				{#each recomputeFailures as failure (`${failure.kind}-${failure.id}`)}
					<li><strong>{failure.label}:</strong> {failure.message}</li>
				{/each}
			</ul>
		{/if}
	</div>
</section>
