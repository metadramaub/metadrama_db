import { writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const projectRef = process.env.SUPABASE_PROJECT_REF;
const supabaseCli = fileURLToPath(
	new URL('../node_modules/supabase/dist/supabase.js', import.meta.url)
);

if (!projectRef) {
	console.error('SUPABASE_PROJECT_REF is required in environment to run db:types');
	process.exit(1);
}

const command = spawnSync(
	process.execPath,
	[
		supabaseCli,
		'gen',
		'types',
		'typescript',
		'--project-id',
		projectRef,
		'--schema',
		'public'
	],
	{
		encoding: 'utf-8',
		stdio: ['inherit', 'pipe', 'inherit']
	}
);

if (command.status !== 0 || !command.stdout) {
	if (command.error) {
		console.error(command.error.message);
	}
	console.error('Failed to generate types from Supabase.');
	process.exit(command.status ?? 1);
}

writeFileSync('src/lib/types/database.types.ts', command.stdout);
console.log('Generated src/lib/types/database.types.ts');
