import type {
	PublicFichaAtribucionAutoria,
	PublicFichaAutor,
	PublicFichaGrupoAutoria
} from '$lib/types/public-ficha.types';

function joinNames(names: string[]): string {
	if (names.length === 0) return '';
	if (names.length === 1) return names[0];
	if (names.length === 2) return `${names[0]} y ${names[1]}`;
	return `${names.slice(0, -1).join(', ')} y ${names[names.length - 1]}`;
}

export function formatPublicAuthorList(authors: PublicFichaAutor[]): string {
	return joinNames(authors.map((author) => author.nombre_completo));
}

export function formatPublicAutoriaProposal(proposal: PublicFichaAtribucionAutoria): string {
	if (proposal.composicion_autoria_term === 'desconocida') return 'autoría desconocida';
	const authorText = formatPublicAuthorList(proposal.autores);
	if (!authorText) return 'autoría no identificada';
	if (proposal.composicion_autoria_term === 'colaborada') return `colaboración de ${authorText}`;
	return authorText;
}

export function formatPublicAutoriaGroup(group: PublicFichaGrupoAutoria): string {
	if (group.propuestas.length === 0) return 'Autoría no identificada';
	if (group.propuestas.length === 1) return formatPublicAutoriaProposal(group.propuestas[0]);
	return `Autoría en discusión: ${group.propuestas.map(formatPublicAutoriaProposal).join(', o ')}`;
}

export function collectUnambiguousPublicAuthors(groups: PublicFichaGrupoAutoria[]): PublicFichaAutor[] {
	const seen = new Set<string>();
	const authors: PublicFichaAutor[] = [];
	for (const group of groups) {
		if (group.propuestas.length !== 1) continue;
		for (const author of group.propuestas[0].autores) {
			if (seen.has(author.autor_id)) continue;
			seen.add(author.autor_id);
			authors.push(author);
		}
	}
	return authors;
}
