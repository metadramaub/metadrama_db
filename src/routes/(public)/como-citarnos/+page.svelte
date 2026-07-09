<script lang="ts">
	import CitationCard from '$lib/components/public/CitationCard.svelte';

	const siteCitation =
		'Gilabert, Gaston y David Merino Recalde, Versología: base de datos y herramientas de estilometría estrófica para el verso dramático [https://versologia.metadrama.org/], 2026.';

	const siteBibtex = `@misc{gilabert_merino_2026_versologia,
  author = {Gilabert, Gaston and Merino Recalde, David},
  title = {Versología: base de datos y herramientas de estilometría estrófica para el verso dramático},
  year = {2026},
  url = {https://versologia.metadrama.org/}
}`;

	const siteRis = `TY  - ELEC
AU  - Gilabert, Gaston
AU  - Merino Recalde, David
TI  - Versología: base de datos y herramientas de estilometría estrófica para el verso dramático
PY  - 2026
UR  - https://versologia.metadrama.org/
ER  -`;

	const analysisCitation =
		'González Mesas, Emma, «Análisis y estudio versológico de El mágico prodigioso», en Gaston Gilabert y David Merino Recalde, Versología: base de datos y herramientas de estilometría estrófica para el verso dramático [https://versologia.metadrama.org/], 2026.';

	const analysisBibtex = `@incollection{gonzalez_mesas_2026_magico_prodigioso,
  author = {González Mesas, Emma},
  title = {Análisis y estudio versológico de El mágico prodigioso},
  booktitle = {Versología: base de datos y herramientas de estilometría estrófica para el verso dramático},
  editor = {Gilabert, Gaston and Merino Recalde, David},
  year = {2026},
  url = {https://versologia.metadrama.org/}
}`;

	const analysisRis = `TY  - CHAP
AU  - González Mesas, Emma
A2  - Gilabert, Gaston
A2  - Merino Recalde, David
TI  - Análisis y estudio versológico de El mágico prodigioso
T2  - Versología: base de datos y herramientas de estilometría estrófica para el verso dramático
PY  - 2026
UR  - https://versologia.metadrama.org/
ER  -`;
</script>

<section>
	<h1 class="font-display text-3xl text-[color:var(--gray-900)]">CÓMO CITARNOS</h1>
	<p class="mt-3 max-w-2xl text-sm leading-6 text-[color:var(--muted-foreground)]">
		Si utilizas Versología en tu investigación, cita el proyecto o el análisis consultado. De
		este modo contribuyes a reconocer el trabajo realizado y a apoyar la continuidad del proyecto.
	</p>

	<div class="mt-8 grid items-stretch gap-6 lg:grid-cols-2">
		<CitationCard
			title="Cómo citar Versología"
			citation={siteCitation}
			bibtex={siteBibtex}
			ris={siteRis}
			filename="versologia-2026"
		>
			<p>
				Gilabert, Gaston y David Merino Recalde, <em>Versología: base de datos y herramientas
				de estilometría estrófica para el verso dramático</em> [<a
					href="https://versologia.metadrama.org/"
					class="text-[color:var(--primary)] underline decoration-1 underline-offset-2 hover:text-[color:var(--foreground)]"
				>https://versologia.metadrama.org/</a>], 2026.
			</p>
		</CitationCard>

		<CitationCard
			title="Cómo citar un análisis específico"
			description=""
			citation={analysisCitation}
			bibtex={analysisBibtex}
			ris={analysisRis}
			filename="analisis-el-magico-prodigioso-2026"
		>
			<p>
				González Mesas, Emma, «Análisis y estudio versológico de <em>El mágico
				prodigioso</em>», en Gaston Gilabert y David Merino Recalde, <em>Versología: base de
				datos y herramientas de estilometría estrófica para el verso dramático</em> [<a
					href="https://versologia.metadrama.org/"
					class="text-[color:var(--primary)] underline decoration-1 underline-offset-2 hover:text-[color:var(--foreground)]"
				>https://versologia.metadrama.org/</a>], 2026.
			</p>
		</CitationCard>
	</div>
</section>
