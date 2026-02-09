import js from '@eslint/js';
import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';

export default [
	{
		ignores: [
			'.svelte-kit/**',
			'build/**',
			'coverage/**',
			'node_modules/**',
			'**/*.svelte',
			'src/lib/types/database.types.ts'
		]
	},
	js.configs.recommended,
	{
		files: ['**/*.{ts,js,mjs,cjs}'],
		languageOptions: {
			parser: tsParser,
			parserOptions: {
				ecmaVersion: 'latest',
				sourceType: 'module'
			},
			globals: {
				console: 'readonly',
				process: 'readonly',
				setTimeout: 'readonly'
			}
		},
		plugins: {
			'@typescript-eslint': tsPlugin
		},
		rules: {
			'no-undef': 'off',
			'@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }]
		}
	}
];
