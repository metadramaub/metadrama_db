import { writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

const projectRef = process.env.SUPABASE_PROJECT_REF;

if (!projectRef) {
	console.error('SUPABASE_PROJECT_REF is required in environment to run db:types');
	process.exit(1);
}

const command = spawnSync(
	'npx',
	['supabase', 'gen', 'types', 'typescript', '--project-id', projectRef, '--schema', 'public'],
	{ encoding: 'utf-8', stdio: ['inherit', 'pipe', 'inherit'] }
);

if (command.status !== 0 || !command.stdout) {
	console.error('Failed to generate types from Supabase.');
	process.exit(command.status ?? 1);
}

writeFileSync('src/lib/types/database.types.ts', command.stdout);
console.log('Generated src/lib/types/database.types.ts');
