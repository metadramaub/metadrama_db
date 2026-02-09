/** @type {import('tailwindcss').Config} */
export default {
	content: ['./src/**/*.{html,js,svelte,ts}'],
	theme: {
		extend: {
			colors: {
				metadrama: {
					ink: '#132332',
					brand: '#8D1F2D',
					sand: '#F8F2E8',
					accent: '#2A556F'
				}
			},
			fontFamily: {
				serifDisplay: ['"Source Serif 4"', 'serif'],
				sansUi: ['"IBM Plex Sans"', 'sans-serif']
			}
		}
	},
	plugins: []
};
