<script lang="ts">
	import ArrowRight from 'lucide-svelte/icons/arrow-right';
	import MetricFormLabel from './MetricFormLabel.svelte';
	import type { MetricSequenceReference } from './metric-display.types';

	const props = $props<{
		anterior: MetricSequenceReference;
		siguiente: MetricSequenceReference;
		onOpen: (sequenceId: string) => void;
		colorByForma: Record<string, string>;
		className?: string;
	}>();
</script>

<div class={`grid grid-cols-[minmax(0,1fr)_1rem_minmax(0,1fr)] items-center gap-1.5 ${props.className ?? ''}`}>
	<button type="button" class="min-w-0 rounded px-1.5 py-1 text-left hover:bg-[color:var(--muted)]" onclick={() => props.onOpen(props.anterior.secuencia_id)}>
		<MetricFormLabel forma={props.anterior.forma} colorKey={props.anterior.colorKey} colorByForma={props.colorByForma} />
		<span class="ml-1 whitespace-nowrap text-[color:var(--muted-foreground)]">· vv. {props.anterior.v_ini}–{props.anterior.v_fin}</span>
	</button>
	<ArrowRight class="h-4 w-4 text-[color:var(--muted-foreground)]" aria-hidden="true" />
	<button type="button" class="min-w-0 rounded px-1.5 py-1 text-left hover:bg-[color:var(--muted)]" onclick={() => props.onOpen(props.siguiente.secuencia_id)}>
		<MetricFormLabel forma={props.siguiente.forma} colorKey={props.siguiente.colorKey} colorByForma={props.colorByForma} />
		<span class="ml-1 whitespace-nowrap text-[color:var(--muted-foreground)]">· vv. {props.siguiente.v_ini}–{props.siguiente.v_fin}</span>
	</button>
</div>
