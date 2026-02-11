/** @type {import('tailwindcss').Config} */
export default {
	content: ['./src/**/*.{html,js,svelte,ts}'],
	theme: {
		extend: {
			colors: {
				metadrama: {
					accent: '#CBA44A',
					gray: {
						50: '#fafafa',
						100: '#f5f5f5',
						200: '#e6e6e6',
						300: '#d3d3d3',
						400: '#a3a3a3',
						500: '#808080',
						600: '#535353',
						700: '#404040',
						800: '#272727',
						900: '#1a1a1a',
						950: '#0b0b0b'
					}
				}
			},
			fontFamily: {
				display: ['"Bona Nova"', 'serif'],
				sansUi: ['Inter', 'sans-serif']
			}
		}
	},
	plugins: []
};
