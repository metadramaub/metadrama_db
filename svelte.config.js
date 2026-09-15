import adapter from '@sveltejs/adapter-auto';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	kit: {
		// El navegador integrado bloquea recursos servidos desde rutas que empiezan por `/.`.
		// Usar un directorio generado no oculto evita que falle la hidratación en desarrollo.
		outDir: 'svelte-kit',
		// adapter-auto only supports some environments, see https://svelte.dev/docs/kit/adapter-auto for a list.
		// If your environment is not supported, or you settled on a specific environment, switch out the adapter.
		// See https://svelte.dev/docs/kit/adapters for more information about adapters.
		adapter: adapter()
	}
};

export default config;
