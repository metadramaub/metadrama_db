export type VocabularyFieldConfig = {
	showParent: boolean;
	showLevel: boolean;
	showActive: boolean;
	showDefinition: boolean;
	showExample: boolean;
	showBibliography: boolean;
	showEquivalences: boolean;
	showPattern: boolean;
	showTipoForma: boolean;
	showTipoRima: boolean;
	showNaturalezaEstrofica: boolean;
	showTamanioUnidadEstrofica: boolean;
	showArteMetrico: boolean;
	showNumeroSilabas: boolean;
	showMetros: boolean;
};

const TECHNICAL_CATEGORIES = new Set(['estado', 'role_editor', 'tipo_comentario']);

const ESTROFA_FIELDS: VocabularyFieldConfig = {
	showParent: true,
	showLevel: true,
	showActive: true,
	showDefinition: true,
	showExample: true,
	showBibliography: true,
	showEquivalences: true,
	showPattern: true,
	showTipoForma: true,
	showTipoRima: true,
	showNaturalezaEstrofica: true,
	showTamanioUnidadEstrofica: true,
	showArteMetrico: true,
	showNumeroSilabas: false,
	showMetros: true
};

const GENERO_FIELDS: VocabularyFieldConfig = {
	showParent: false,
	showLevel: false,
	showActive: true,
	showDefinition: true,
	showExample: true,
	showBibliography: true,
	showEquivalences: true,
	showPattern: false,
	showTipoForma: false,
	showTipoRima: false,
	showNaturalezaEstrofica: false,
	showTamanioUnidadEstrofica: false,
	showArteMetrico: false,
	showNumeroSilabas: false,
	showMetros: false
};

const METRO_FIELDS: VocabularyFieldConfig = {
	showParent: false,
	showLevel: false,
	showActive: true,
	showDefinition: true,
	showExample: true,
	showBibliography: true,
	showEquivalences: true,
	showPattern: false,
	showTipoForma: false,
	showTipoRima: false,
	showNaturalezaEstrofica: false,
	showTamanioUnidadEstrofica: false,
	showArteMetrico: false,
	showNumeroSilabas: true,
	showMetros: false
};

const CARACTERIZACION_RANGO_FIELDS: VocabularyFieldConfig = {
	showParent: true,
	showLevel: true,
	showActive: true,
	showDefinition: true,
	showExample: true,
	showBibliography: true,
	showEquivalences: true,
	showPattern: false,
	showTipoForma: false,
	showTipoRima: false,
	showNaturalezaEstrofica: false,
	showTamanioUnidadEstrofica: false,
	showArteMetrico: false,
	showNumeroSilabas: false,
	showMetros: false
};

const TECHNICAL_FIELDS: VocabularyFieldConfig = {
	showParent: false,
	showLevel: false,
	showActive: true,
	showDefinition: true,
	showExample: false,
	showBibliography: false,
	showEquivalences: false,
	showPattern: false,
	showTipoForma: false,
	showTipoRima: false,
	showNaturalezaEstrofica: false,
	showTamanioUnidadEstrofica: false,
	showArteMetrico: false,
	showNumeroSilabas: false,
	showMetros: false
};

const LEGACY_FALLBACK_FIELDS: VocabularyFieldConfig = {
	showParent: true,
	showLevel: true,
	showActive: true,
	showDefinition: true,
	showExample: true,
	showBibliography: true,
	showEquivalences: true,
	showPattern: true,
	showTipoForma: false,
	showTipoRima: false,
	showNaturalezaEstrofica: false,
	showTamanioUnidadEstrofica: false,
	showArteMetrico: false,
	showNumeroSilabas: false,
	showMetros: false
};

export function getVocabularyFieldConfig(categoria: string): VocabularyFieldConfig {
	if (categoria === 'estrofa_tipo') return ESTROFA_FIELDS;
	if (categoria === 'genero') return GENERO_FIELDS;
	if (categoria === 'metro') return METRO_FIELDS;
	if (categoria === 'caracterizacion_rango') return CARACTERIZACION_RANGO_FIELDS;
	if (TECHNICAL_CATEGORIES.has(categoria)) return TECHNICAL_FIELDS;
	return LEGACY_FALLBACK_FIELDS;
}
