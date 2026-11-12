<script lang="ts">
	import MetadatosObra from './MetadatosObra.svelte';
	import type { PageData } from './$types';
	let { data }: { data: PageData } = $props();
</script>

<MetadatosObra {data} />
