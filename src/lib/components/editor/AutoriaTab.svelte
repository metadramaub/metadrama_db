<script lang="ts">
	import { onDestroy } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, setDirty, setSaving } from '$lib/stores/currentObra';
	import type { Tables } from '$lib/types/database.types';

	type Mode = 'obra_completa' | 'por_jornadas' | 'rango_personalizado';
	type JornadaAssignment = {
		jornada_id: string;
		autor_ids: string[];
		notas: string;
	};
	type CustomRange = {
		temp_id: string;
		v_ini: number;
		v_fin: number;
		autor_ids: string[];
		notas: string;
	};

	const props = $props<{
		obraId: string;
		obra: Tables<'obras'>;
		jornadas: Tables<'jornadas'>[];
		rangosInitial: Tables<'rangos'>[];
		rangosAutoresInitial: Tables<'rangos_autores'>[];
		autoresInitial: Array<Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'nombre_normalizado'>>;
	}>();
	type AutorOption = (typeof props.autoresInitial)[number];
	type JornadaOption = (typeof props.jornadas)[number];

	let rangos = $state([...props.rangosInitial]);
	let rangosAutores = $state([...props.rangosAutoresInitial]);
	const initialMode = inferMode(props.rangosInitial);
	let mode = $state<Mode>(initialMode);
	let urlInforme = $state(props.obra.url_informe_autoria ?? '');
	let authorSearch = $state('');
	let savingNow = $state(false);
	let timer: ReturnType<typeof setTimeout> | null = null;

	let obraCompleta = $state({
		autor_ids: [] as string[],
		notas: ''
	});
	let jornadaAssignments = $state<JornadaAssignment[]>([]);
	let customRanges = $state<CustomRange[]>([]);

	initializeForms(props.rangosInitial, props.rangosAutoresInitial, initialMode);

	const filteredAutores = $derived.by(() => {
		const term = authorSearch.trim().toLowerCase();
		if (!term) return props.autoresInitial;
		return props.autoresInitial.filter((autor: AutorOption) =>
			autor.nombre_completo.toLowerCase().includes(term)
		);
	});

	const jornadaMap = $derived(
		new Map(
			props.jornadas.map((jornada: JornadaOption) => [
				jornada.jornada_id,
				`Jornada ${jornada.jornada_num} (vv. ${jornada.v_ini}-${jornada.v_fin})`
			])
		)
	);

	function inferMode(rangosInput: Tables<'rangos'>[]): Mode {
		if (rangosInput.length === 0) return 'obra_completa';
		if (rangosInput.length === 1 && rangosInput[0].v_ini === 1) {
			if (!props.obra.total_versos || rangosInput[0].v_fin === props.obra.total_versos) {
				return 'obra_completa';
			}
		}
		if (props.jornadas.length > 0 && rangosInput.length === props.jornadas.length) {
			const signatures = new Set(rangosInput.map((rango) => `${rango.v_ini}:${rango.v_fin}`));
			if (
				props.jornadas.every((jornada: JornadaOption) =>
					signatures.has(`${jornada.v_ini}:${jornada.v_fin}`)
				)
			) {
				return 'por_jornadas';
			}
		}
		return 'rango_personalizado';
	}

	function getAuthorIdsByRange(
		rangosAutoresInput: Tables<'rangos_autores'>[]
	): Map<string, string[]> {
		const map = new Map<string, string[]>();
		for (const row of rangosAutoresInput) {
			const current = map.get(row.rango_id) ?? [];
			if (!current.includes(row.autor_id)) {
				current.push(row.autor_id);
			}
			map.set(row.rango_id, current);
		}
		return map;
	}

	function initializeForms(
		rangosInput: Tables<'rangos'>[],
		rangosAutoresInput: Tables<'rangos_autores'>[],
		nextMode: Mode
	) {
		const authorIdsByRange = getAuthorIdsByRange(rangosAutoresInput);
		const sortedRanges = [...rangosInput].sort((a, b) => a.v_ini - b.v_ini);
		const firstRange = sortedRanges[0];

		obraCompleta = {
			autor_ids: firstRange ? [...(authorIdsByRange.get(firstRange.rango_id) ?? [])] : [],
			notas: firstRange?.notas ?? ''
		};

		jornadaAssignments = props.jornadas.map((jornada: JornadaOption) => {
			const match = sortedRanges.find(
				(range) => range.v_ini === jornada.v_ini && range.v_fin === jornada.v_fin
			);
			return {
				jornada_id: jornada.jornada_id,
				autor_ids: match ? [...(authorIdsByRange.get(match.rango_id) ?? [])] : [],
				notas: match?.notas ?? ''
			};
		});

		customRanges = sortedRanges.map((range) => ({
			temp_id: range.rango_id,
			v_ini: range.v_ini,
			v_fin: range.v_fin,
			autor_ids: [...(authorIdsByRange.get(range.rango_id) ?? [])],
			notas: range.notas ?? ''
		}));

		mode = nextMode;
	}

	function queueSave() {
		setDirty(true);
		if (timer) clearTimeout(timer);
		timer = setTimeout(() => void save(), 10_000);
	}

	function readMultiSelectValues(select: HTMLSelectElement): string[] {
		return Array.from(select.selectedOptions).map((option) => option.value);
	}

	function setMode(nextMode: Mode) {
		mode = nextMode;
		queueSave();
	}

	function setObraCompletaAuthors(select: HTMLSelectElement) {
		obraCompleta = {
			...obraCompleta,
			autor_ids: readMultiSelectValues(select)
		};
		queueSave();
	}

	function setJornadaAuthors(jornadaId: string, select: HTMLSelectElement) {
		const values = readMultiSelectValues(select);
		jornadaAssignments = jornadaAssignments.map((item) =>
			item.jornada_id === jornadaId ? { ...item, autor_ids: values } : item
		);
		queueSave();
	}

	function setCustomRangeAuthors(tempId: string, select: HTMLSelectElement) {
		const values = readMultiSelectValues(select);
		customRanges = customRanges.map((item) =>
			item.temp_id === tempId ? { ...item, autor_ids: values } : item
		);
		queueSave();
	}

	function updateJornadaNotas(jornadaId: string, notas: string) {
		jornadaAssignments = jornadaAssignments.map((item) =>
			item.jornada_id === jornadaId ? { ...item, notas } : item
		);
		queueSave();
	}

	function updateCustomRange(tempId: string, patch: Partial<CustomRange>) {
		customRanges = customRanges.map((item) =>
			item.temp_id === tempId ? { ...item, ...patch } : item
		);
		queueSave();
	}

	function addCustomRange() {
		const sorted = [...customRanges].sort((a, b) => a.v_ini - b.v_ini);
		const nextStart = (sorted.at(-1)?.v_fin ?? 0) + 1;
		customRanges = [
			...customRanges,
			{ temp_id: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`, v_ini: nextStart, v_fin: nextStart + 10, autor_ids: [], notas: '' }
		];
		queueSave();
	}

	function removeCustomRange(tempId: string) {
		customRanges = customRanges.filter((item) => item.temp_id !== tempId);
		queueSave();
	}

	function buildPayload() {
		const normalizedUrl = urlInforme.trim() || null;
		if (mode === 'obra_completa') {
			return {
				mode,
				url_informe_autoria: normalizedUrl,
				autor_ids: obraCompleta.autor_ids,
				notas: obraCompleta.notas.trim() || null
			};
		}

		if (mode === 'por_jornadas') {
			return {
				mode,
				url_informe_autoria: normalizedUrl,
				items: jornadaAssignments.map((item) => ({
					jornada_id: item.jornada_id,
					autor_ids: item.autor_ids,
					notas: item.notas.trim() || null
				}))
			};
		}

		return {
			mode,
			url_informe_autoria: normalizedUrl,
			items: customRanges.map((item) => ({
				v_ini: Number(item.v_ini),
				v_fin: Number(item.v_fin),
				autor_ids: item.autor_ids,
				notas: item.notas.trim() || null
			}))
		};
	}

	function validateClientPayload() {
		if (mode === 'obra_completa') {
			if (obraCompleta.autor_ids.length === 0) {
				return 'Selecciona al menos un autor para la obra completa.';
			}
			return null;
		}

		if (mode === 'por_jornadas') {
			for (const jornada of jornadaAssignments) {
				if (jornada.autor_ids.length === 0) {
					return `Faltan autores en ${jornadaMap.get(jornada.jornada_id) ?? 'una jornada'}.`;
				}
			}
			return null;
		}

		if (customRanges.length === 0) {
			return 'Debes definir al menos un rango personalizado.';
		}
		for (const range of customRanges) {
			if (!Number.isFinite(range.v_ini) || !Number.isFinite(range.v_fin) || range.v_ini >= range.v_fin) {
				return 'Hay rangos con versos invalidos.';
			}
			if (range.autor_ids.length === 0) {
				return 'Todos los rangos deben tener al menos un autor.';
			}
		}
		const sorted = [...customRanges].sort((a, b) => a.v_ini - b.v_ini);
		for (let i = 1; i < sorted.length; i += 1) {
			if (sorted[i].v_ini <= sorted[i - 1].v_fin) {
				return 'Hay rangos solapados. Ajusta los versos para continuar.';
			}
		}
		return null;
	}

	function applyServerState(payload: {
		rangos: Tables<'rangos'>[];
		rangosAutores: Tables<'rangos_autores'>[];
		obra: { url_informe_autoria: string | null };
		mode: Mode;
	}) {
		rangos = [...payload.rangos];
		rangosAutores = [...payload.rangosAutores];
		urlInforme = payload.obra.url_informe_autoria ?? '';
		initializeForms(rangos, rangosAutores, payload.mode);
	}

	async function save() {
		if (savingNow) return;
		const clientError = validateClientPayload();
		if (clientError) {
			pushToast('error', clientError);
			setSaving(false);
			return;
		}

		savingNow = true;
		setSaving(true);
		const response = await fetch(`/api/obras/${props.obraId}/autoria`, {
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(buildPayload())
		});
		savingNow = false;

		if (!response.ok) {
			setSaving(false);
			const body = await response.json().catch(() => ({}));
			const detail = Array.isArray(body?.details) ? body.details[0]?.message : null;
			pushToast('error', detail ?? body.message ?? 'No se pudo guardar la autoria.');
			return;
		}

		const payload = await response.json();
		applyServerState({
			rangos: payload.rangos,
			rangosAutores: payload.rangosAutores,
			obra: payload.obra,
			mode: payload.mode
		});
		markSaved();
		pushToast('success', 'Autoria guardada');
	}

	onDestroy(() => {
		if (timer) clearTimeout(timer);
	});
</script>

<section class="space-y-4">
	<div class="card p-4">
		<div class="mb-3 flex flex-wrap items-center justify-between gap-3">
			<div>
				<h2 class="text-xl font-semibold">Autoria</h2>
				<p class="text-sm text-[color:var(--muted-foreground)]">
					Define como se distribuye la autoria de la obra.
				</p>
			</div>
			<Button onclick={save} disabled={savingNow}>{savingNow ? 'Guardando...' : 'Guardar ahora'}</Button>
		</div>

		<div class="grid gap-2 sm:grid-cols-3">
			<label class="flex items-center gap-2 rounded-md border border-[color:var(--border)] bg-white p-3 text-sm">
				<input type="radio" name="autoria-mode" checked={mode === 'obra_completa'} onchange={() => setMode('obra_completa')} />
				Obra completa
			</label>
			<label class="flex items-center gap-2 rounded-md border border-[color:var(--border)] bg-white p-3 text-sm">
				<input type="radio" name="autoria-mode" checked={mode === 'por_jornadas'} onchange={() => setMode('por_jornadas')} />
				Por jornadas
			</label>
			<label class="flex items-center gap-2 rounded-md border border-[color:var(--border)] bg-white p-3 text-sm">
				<input
					type="radio"
					name="autoria-mode"
					checked={mode === 'rango_personalizado'}
					onchange={() => setMode('rango_personalizado')}
				/>
				Rango personalizado
			</label>
		</div>

		<label class="mt-4 block text-sm">
			<span class="mb-1 block">URL informe ETSO</span>
			<input
				type="url"
				class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				value={urlInforme}
				oninput={(event) => {
					urlInforme = event.currentTarget.value;
					queueSave();
				}}
			/>
		</label>
	</div>

	<div class="card p-4">
		<div class="mb-3 flex items-center justify-between gap-2">
			<h3 class="text-lg font-semibold">Autores</h3>
			<input
				class="rounded-md border border-[color:var(--border)] px-3 py-2 text-sm"
				placeholder="Filtrar autores"
				value={authorSearch}
				oninput={(event) => (authorSearch = event.currentTarget.value)}
			/>
		</div>

		{#if mode === 'obra_completa'}
			<div class="space-y-3">
				<label class="block text-sm">
					<span class="mb-1 block">Autores de la obra</span>
					<select
						multiple
						size="8"
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						onchange={(event) => setObraCompletaAuthors(event.currentTarget as HTMLSelectElement)}
					>
						{#each filteredAutores as autor}
							<option value={autor.autor_id} selected={obraCompleta.autor_ids.includes(autor.autor_id)}>{autor.nombre_completo}</option>
						{/each}
					</select>
				</label>

				<label class="block text-sm">
					<span class="mb-1 block">Notas</span>
					<textarea
						rows={3}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						value={obraCompleta.notas}
						oninput={(event) => {
							obraCompleta = { ...obraCompleta, notas: event.currentTarget.value };
							queueSave();
						}}
					></textarea>
				</label>
			</div>
		{:else if mode === 'por_jornadas'}
			<div class="space-y-3">
				{#each jornadaAssignments as assignment}
					<article class="rounded-md border border-[color:var(--border)] bg-white p-3">
						<div class="mb-2 text-sm font-medium">{jornadaMap.get(assignment.jornada_id) ?? assignment.jornada_id}</div>
						<div class="grid gap-3 md:grid-cols-2">
							<label class="block text-sm">
								<span class="mb-1 block">Autores</span>
								<select
									multiple
									size="7"
									class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
									onchange={(event) =>
										setJornadaAuthors(assignment.jornada_id, event.currentTarget as HTMLSelectElement)}
								>
									{#each filteredAutores as autor}
										<option value={autor.autor_id} selected={assignment.autor_ids.includes(autor.autor_id)}>
											{autor.nombre_completo}
										</option>
									{/each}
								</select>
							</label>
							<label class="block text-sm">
								<span class="mb-1 block">Notas</span>
								<textarea
									rows={3}
									class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
									value={assignment.notas}
									oninput={(event) => updateJornadaNotas(assignment.jornada_id, event.currentTarget.value)}
								></textarea>
							</label>
						</div>
					</article>
				{/each}
			</div>
		{:else}
			<div class="space-y-3">
				<div class="flex justify-end">
					<Button variant="secondary" onclick={addCustomRange}>Anadir rango</Button>
				</div>
				{#if customRanges.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">No hay rangos definidos.</p>
				{:else}
					{#each customRanges as range}
						<article class="rounded-md border border-[color:var(--border)] bg-white p-3">
							<div class="mb-3 flex justify-between gap-2">
								<div class="grid w-full grid-cols-2 gap-2 sm:grid-cols-4">
									<label class="text-sm">
										<span class="mb-1 block">V_ini</span>
										<input
											type="number"
											class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
											value={range.v_ini}
											oninput={(event) => updateCustomRange(range.temp_id, { v_ini: Number(event.currentTarget.value) })}
										/>
									</label>
									<label class="text-sm">
										<span class="mb-1 block">V_fin</span>
										<input
											type="number"
											class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
											value={range.v_fin}
											oninput={(event) => updateCustomRange(range.temp_id, { v_fin: Number(event.currentTarget.value) })}
										/>
									</label>
								</div>
								<Button variant="danger" onclick={() => removeCustomRange(range.temp_id)}>Eliminar</Button>
							</div>

							<div class="grid gap-3 md:grid-cols-2">
								<label class="block text-sm">
									<span class="mb-1 block">Autores</span>
									<select
										multiple
										size="7"
										class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
										onchange={(event) =>
											setCustomRangeAuthors(range.temp_id, event.currentTarget as HTMLSelectElement)}
									>
										{#each filteredAutores as autor}
											<option value={autor.autor_id} selected={range.autor_ids.includes(autor.autor_id)}>
												{autor.nombre_completo}
											</option>
										{/each}
									</select>
								</label>
								<label class="block text-sm">
									<span class="mb-1 block">Notas</span>
									<textarea
										rows={3}
										class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
										value={range.notas}
										oninput={(event) => updateCustomRange(range.temp_id, { notas: event.currentTarget.value })}
									></textarea>
								</label>
							</div>
						</article>
					{/each}
				{/if}
			</div>
		{/if}
	</div>
</section>
