<script lang="ts">
	import { sceneLoaderStore } from '$lib/stores/scene-loader';
</script>

{#if $sceneLoaderStore.visible}
	<div class="scene-loader-overlay" role="status" aria-live="polite" aria-busy="true">
		<div class="scene-loader-panel card">
			<div class="scene-loader-bars" aria-hidden="true">
				<span class="scene-loader-bar"></span>
				<span class="scene-loader-bar"></span>
				<span class="scene-loader-bar"></span>
			</div>
			<p class="scene-loader-note text-sm">{$sceneLoaderStore.message}</p>
		</div>
	</div>
{/if}
