<script lang="ts">
	import CitationCard from '$lib/components/public/CitationCard.svelte';
	import PublicPageHeader from '$lib/components/public/PublicPageHeader.svelte';

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

	const projectCitation =
		'Universitat de Barcelona, Teatro áureo en diacronía: estudio, edición y puesta en escena del verso clásico (PID2024-161619NA-I00). IP: Gaston Gilabert. Financiado por MICIU/AEI/10.13039/501100011033 y por FEDER, Unión Europea.';

	const projectBibtex = `@misc{teatro_aureo_diacronia_pid2024,
	  author = {{Universitat de Barcelona}},
	  title = {Teatro áureo en diacronía: estudio, edición y puesta en escena del verso clásico},
	  note = {Proyecto PID2024-161619NA-I00. IP: Gaston Gilabert. Financiado por MICIU/AEI/10.13039/501100011033 y por FEDER, Unión Europea}
}`;

	const projectRis = `TY  - GEN
AU  - Universitat de Barcelona
TI  - Teatro áureo en diacronía: estudio, edición y puesta en escena del verso clásico
N1  - Proyecto PID2024-161619NA-I00. IP: Gaston Gilabert. Financiado por MICIU/AEI/10.13039/501100011033 y por FEDER, Unión Europea
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

<section class="pb-16 pt-10 md:pb-24 md:pt-16">
	<PublicPageHeader
		eyebrow="VERSOLOGÍA"
		title="Cómo citarnos"
		description="Si utilizas Versología en tu investigación, cita el proyecto o el análisis consultado. De este modo contribuyes a reconocer el trabajo realizado y a apoyar la continuidad del proyecto."
	/>

	<div class="mt-12 grid items-stretch gap-6 lg:grid-cols-2">
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

		<div class="lg:col-span-2">
			<CitationCard
				title="Cómo citar el proyecto"
				citation={projectCitation}
				bibtex={projectBibtex}
				ris={projectRis}
				filename="teatro-aureo-diacronia-pid2024"
			>
				<p>
					Universitat de Barcelona, <em>Teatro áureo en diacronía: estudio, edición y puesta en
					escena del verso clásico</em> (PID2024-161619NA-I00). IP: Gaston Gilabert. Financiado
					por MICIU/AEI/10.13039/501100011033 y por FEDER, Unión Europea.
				</p>
			</CitationCard>
		</div>
	</div>

	<section class="mt-12 border-t border-[color:var(--border)] pt-8 md:mt-16 md:pt-10">
		<div class="grid gap-5 md:grid-cols-3">
			<h2 class="text-[10px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">
				USO Y REUTILIZACIÓN
			</h2>
			<div class="space-y-4 text-sm leading-7 text-[color:var(--gray-700)] md:col-span-2">
				<p>
					Los contenidos propios de Versología se publican bajo licencia
					<a
						href="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es"
						class="font-semibold text-[color:var(--primary)] underline decoration-1 underline-offset-2 hover:text-[color:var(--foreground)]"
						target="_blank"
						rel="noreferrer noopener">CC BY-NC-SA 4.0</a
					>. Al reutilizarlos, cita Versología y, cuando corresponda, la ficha o el análisis
					concreto; indica asimismo las modificaciones realizadas.
				</p>
				<p>
					Los textos de partida, imágenes y otros materiales de terceros conservan las condiciones
					de su procedencia. Consulta la información de cada ficha antes de reutilizarlos. Para
					conocer el alcance de los datos, los métodos y las prácticas de apertura del recurso,
					visita <a
						href="/proyecto/datos-ciencia-abierta"
						class="font-semibold text-[color:var(--primary)] underline decoration-1 underline-offset-2 hover:text-[color:var(--foreground)]"
					>Datos, métodos y ciencia abierta</a
					>.
				</p>
			</div>
		</div>
	</section>
</section>
