import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vitest/config';

export default defineConfig({
	plugins: [
		sveltekit(),
		{
			name: 'versologia-cache-local',
			config(config, { command, mode }) {
				if (config.cacheDir) return;
				// Un servidor de prueba no debe sobrescribir las dependencias del Vite abierto.
				const instancia =
					command === 'build' ? 'build' : mode === 'test' ? 'test' : (config.server?.port ?? 5173);
				return { cacheDir: `node_modules/.vite/versologia-${instancia}` };
			}
		}
	],
	optimizeDeps: {
		// Los iconos se importan por subruta y muchos solo aparecen al abrir una ficha.
		exclude: ['lucide-svelte/icons'],
		include: ['@supabase/ssr', 'date-fns', 'date-fns/locale', 'lucide-svelte', 'zod']
	},
	ssr: {
		// Mantiene estable el runtime de Svelte durante el renderizado en desarrollo.
		optimizeDeps: { noDiscovery: true, exclude: ['svelte'] }
	},
	server: {
		fs: {
			// El editor del importador carga estas dos referencias desde el navegador.
			allow: [
				'data/importador-metrico/catalogo-referencia.json',
				'data/importador-metrico/reglas-longitud.json'
			]
		},
		// El puerto lo puede fijar quien arranca, con `PORT`, para poder levantar más de un servidor
		// a la vez. Sin esa variable, Vite elige el suyo de siempre.
		port: process.env.PORT ? Number(process.env.PORT) : undefined
	},
	test: {
		// Los guiones de `scripts/` no son la aplicación, pero los que leen lo que escribe una
		// persona —el Excel de la migración— sí necesitan prueba: ahí es donde se equivoca uno.
		include: ['src/**/*.test.ts', 'scripts/**/*.test.mjs'],
		environment: 'node',
		coverage: {
			provider: 'v8',
			reporter: ['text', 'html']
		}
	}
});
