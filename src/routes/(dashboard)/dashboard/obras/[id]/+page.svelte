<script lang="ts">
	import { browser } from '$app/environment';
	import { invalidateAll } from '$app/navigation';
	import type { RealtimeChannel } from '@supabase/supabase-js';
	import { onDestroy, onMount } from 'svelte';
	import { get } from 'svelte/store';
	import type { PageData } from './$types';
	import type { Tables } from '$lib/types/database.types';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import DatosObraTab from '$lib/components/editor/DatosObraTab.svelte';
	import EstructuraTab from '$lib/components/editor/EstructuraTab.svelte';
	import SecuenciasTab from '$lib/components/editor/SecuenciasTab.svelte';
	import AutoriaTab from '$lib/components/editor/AutoriaTab.svelte';
	import AnalisisTab from '$lib/components/editor/AnalisisTab.svelte';
	import RevisionTab from '$lib/components/editor/RevisionTab.svelte';
	import { getSupabaseBrowserClient } from '$lib/services/supabase';
	import { currentObraStore, setConflict, setCurrentObra } from '$lib/stores/currentObra';
	import { pushToast } from '$lib/stores/toast';

	let { data } = $props<{ data: PageData }>();

	let currentTab = $state('datos');
	const tabs = [
		{ id: 'datos', label: 'Datos de la obra' },
		{ id: 'estructura', label: 'Estructura' },
		{ id: 'secuencias', label: 'Secuencias' },
		{ id: 'autoria', label: 'Autoría' },
		{ id: 'analisis', label: 'Análisis' },
		{ id: 'revision', label: 'Revisión' }
	];

	const vocabByCategory = $derived.by(() => {
		const grouped = new Map<string, Tables<'vocabularios'>[]>();
		for (const term of data.vocabularios as Tables<'vocabularios'>[]) {
			const existing = grouped.get(term.categoria) ?? [];
			existing.push(term as Tables<'vocabularios'>);
			grouped.set(term.categoria, existing);
		}
		grouped.forEach((items) =>
			items.sort(
				(a: Pick<Tables<'vocabularios'>, 'orden'>, b: Pick<Tables<'vocabularios'>, 'orden'>) =>
					(a.orden ?? 999) - (b.orden ?? 999)
			)
		);
		return grouped;
	});

	const generoOptions = $derived(vocabByCategory.get('genero') ?? []);
	const certezaOptions = $derived(vocabByCategory.get('certeza_editor') ?? []);
	const estadoRevisionOptions = $derived(vocabByCategory.get('estado_revision') ?? []);
	const estrofaOptions = $derived(vocabByCategory.get('estrofa_tipo') ?? []);
	const metroOptions = $derived(vocabByCategory.get('metro') ?? []);

	let channel: RealtimeChannel | null = null;
	const jornadaIds = $derived(
		new Set((data.jornadas as Tables<'jornadas'>[]).map((jornada) => jornada.jornada_id))
	);

	function onExternalChange(payload: { table: string; jornada_id?: string | null }) {
		const dirty = get(currentObraStore).dirty;
		if (payload.table === 'cuadros' && payload.jornada_id && !jornadaIds.has(payload.jornada_id)) {
			return;
		}
		if (dirty) {
			setConflict(true);
			pushToast('info', 'Otro editor guardó cambios; tu próximo guardado sobrescribirá.');
			return;
		}
		void invalidateAll();
	}

	onMount(() => {
		setCurrentObra(data.obra);
		if (!browser) return;
		const supabase = getSupabaseBrowserClient();
		channel = supabase
			.channel(`obra-${data.obra.obra_id}`)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'obras',
					filter: `obra_id=eq.${data.obra.obra_id}`
				},
				() => onExternalChange({ table: 'obras' })
			)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'jornadas',
					filter: `obra_id=eq.${data.obra.obra_id}`
				},
				() => onExternalChange({ table: 'jornadas' })
			)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'secuencias_metricas',
					filter: `obra_id=eq.${data.obra.obra_id}`
				},
				() => onExternalChange({ table: 'secuencias_metricas' })
			)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'cuadros'
				},
				(payload) =>
					onExternalChange({
						table: 'cuadros',
						jornada_id:
							(payload.new as { jornada_id?: string } | null)?.jornada_id ??
							(payload.old as { jornada_id?: string } | null)?.jornada_id ??
							null
					})
			)
			.subscribe();
	});

	onDestroy(() => {
		if (!channel) return;
		const supabase = getSupabaseBrowserClient();
		void supabase.removeChannel(channel);
		channel = null;
	});
</script>

<section>
	<div class="mb-4">
		<h1 class="text-3xl font-semibold">{data.obra.titulo}</h1>
		<p class="text-sm text-[color:var(--muted-foreground)]">
			Estado actual: {data.estadoTerm}. ID obra: {data.obra.obra_id}
		</p>
	</div>

	{#if $currentObraStore.conflict}
		<div class="mb-4 rounded-md border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900">
			Se detectaron cambios externos en esta obra.
		</div>
	{/if}

	<div class="mb-4">
		<Tabs tabs={tabs} active={currentTab} onChange={(tab) => (currentTab = tab)} />
	</div>

	{#if currentTab === 'datos'}
		<DatosObraTab obra={data.obra} generoOptions={generoOptions} />
	{:else if currentTab === 'estructura'}
		<EstructuraTab
			obraId={data.obra.obra_id}
			jornadasInitial={data.jornadas}
			cuadrosInitial={data.cuadros}
			certezaOptions={certezaOptions}
		/>
	{:else if currentTab === 'secuencias'}
		<SecuenciasTab
			obraId={data.obra.obra_id}
			secuenciasInitial={data.secuencias}
			secuenciasMetrosInitial={data.secuenciasMetros}
			estrofaOptions={estrofaOptions}
			metroOptions={metroOptions}
			estadoRevisionOptions={estadoRevisionOptions}
			certezaOptions={certezaOptions}
		/>
	{:else if currentTab === 'autoria'}
		<AutoriaTab />
	{:else if currentTab === 'analisis'}
		<AnalisisTab />
	{:else}
		<RevisionTab />
	{/if}
</section>
