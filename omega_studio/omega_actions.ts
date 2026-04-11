/** Lista única de acciones: paleta «Ejecutar comando Omega…» y vista lateral. */

export type OmegaActionCategory = "proyecto" | "generar" | "trazas" | "ia";

export type OmegaActionEntry = {
    category: OmegaActionCategory;
    label: string;
    description: string;
    command: string;
};

export const OMEGA_ACTIONS: OmegaActionEntry[] = [
    {
        category: "proyecto",
        label: "Validar (validate)",
        description: "omega validate",
        command: "omega.runValidate",
    },
    {
        category: "proyecto",
        label: "Doctor",
        description: "omega doctor [ruta]",
        command: "omega.runDoctor",
    },
    {
        category: "proyecto",
        label: "Init omega_setup",
        description: "omega init [--force]",
        command: "omega.runInit",
    },
    {
        category: "proyecto",
        label: "Abrir documentación (doc)",
        description: "omega doc",
        command: "omega.openDoc",
    },
    {
        category: "proyecto",
        label: "Abrir inspector (navegador)",
        description: "omega inspector",
        command: "omega.openInspector",
    },
    {
        category: "generar",
        label: "Generar ecosistema",
        description: "omega g ecosystem <Nombre>",
        command: "omega.generateEcosystem",
    },
    {
        category: "generar",
        label: "Generar agente",
        description: "omega g agent <Nombre>",
        command: "omega.generateAgent",
    },
    {
        category: "generar",
        label: "Generar flow",
        description: "omega g flow <Nombre>",
        command: "omega.generateFlow",
    },
    {
        category: "generar",
        label: "Crear app Flutter",
        description: "omega create app …",
        command: "omega.createApp",
    },
    {
        category: "trazas",
        label: "Trace: ver resumen",
        description: "omega trace view <archivo>",
        command: "omega.traceView",
    },
    {
        category: "trazas",
        label: "Trace: validar",
        description: "omega trace validate <archivo>",
        command: "omega.traceValidate",
    },
    {
        category: "ia",
        label: "IA: configurar (OMEGA_AI_*)",
        description: "Asistente + secretos en el editor",
        command: "omega.configureAi",
    },
    {
        category: "ia",
        label: "IA: ver configuración",
        description: "Listado en canal Omega Studio",
        command: "omega.showAiConfiguration",
    },
    {
        category: "ia",
        label: "IA: doctor",
        description: "omega ai doctor",
        command: "omega.runAiDoctor",
    },
    {
        category: "ia",
        label: "IA: variables de entorno",
        description: "omega ai env",
        command: "omega.runAiEnv",
    },
    {
        category: "ia",
        label: "IA: explain trace",
        description: "omega ai explain <archivo>",
        command: "omega.aiExplainTrace",
    },
    {
        category: "ia",
        label: "IA: coach start",
        description: "omega ai coach start …",
        command: "omega.aiCoachStart",
    },
    {
        category: "ia",
        label: "IA: coach audit",
        description: "omega ai coach audit …",
        command: "omega.aiCoachAudit",
    },
    {
        category: "ia",
        label: "IA: módulo con diseño",
        description: "omega ai coach module …",
        command: "omega.generateModule",
    },
    {
        category: "ia",
        label: "IA: rediseñar página",
        description: "omega ai coach redesign …",
        command: "omega.editUiWithAi",
    },
];

const CATEGORY_LABEL: Record<OmegaActionCategory, string> = {
    proyecto: "Proyecto",
    generar: "Generar",
    trazas: "Trazas",
    ia: "IA",
};

export function categoryTitle(cat: OmegaActionCategory): string {
    return CATEGORY_LABEL[cat];
}

export const OMEGA_CATEGORIES_ORDER: OmegaActionCategory[] = [
    "proyecto",
    "generar",
    "trazas",
    "ia",
];
