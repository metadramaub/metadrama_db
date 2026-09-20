import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vitest/config';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
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
