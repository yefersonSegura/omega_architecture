import * as vscode from "vscode";

export const SECRET_OPENAI = "omega.ai.openaiApiKey";
export const SECRET_GEMINI = "omega.ai.geminiApiKey";

/**
 * Entorno para `spawn('omega', …)`: hereda el proceso y, si está activada la inyección,
 * aplica omegaStudio.ai.* y secretos (claves API).
 */
export async function buildOmegaEnv(
    context: vscode.ExtensionContext
): Promise<NodeJS.ProcessEnv> {
    const env = { ...process.env };
    const cfg = vscode.workspace.getConfiguration("omegaStudio");
    if (!cfg.get<boolean>("ai.injectEnvironment")) {
        return env;
    }
    env.OMEGA_AI_ENABLED = cfg.get<boolean>("ai.enabled") ? "true" : "false";
    const provider = (cfg.get<string>("ai.provider") ?? "none").trim();
    env.OMEGA_AI_PROVIDER = provider || "none";
    const model = (cfg.get<string>("ai.model") ?? "").trim();
    if (model.length > 0) {
        env.OMEGA_AI_MODEL = model;
    }
    const baseUrl = (cfg.get<string>("ai.baseUrl") ?? "").trim();
    if (baseUrl.length > 0) {
        env.OMEGA_AI_BASE_URL = baseUrl;
    }
    const okey = await context.secrets.get(SECRET_OPENAI);
    if (okey) {
        env.OMEGA_AI_API_KEY = okey;
    }
    const gkey = await context.secrets.get(SECRET_GEMINI);
    if (gkey) {
        env.OMEGA_AI_GEMINI_API_KEY = gkey;
    }
    return env;
}

function maskKey(s: string): string {
    if (s.length <= 4) {
        return "****";
    }
    return `****…${s.slice(-4)} (${s.length} caracteres)`;
}

export async function formatAiConfigurationSummary(
    context: vscode.ExtensionContext
): Promise<string> {
    const cfg = vscode.workspace.getConfiguration("omegaStudio");
    const inject = cfg.get<boolean>("ai.injectEnvironment");
    const lines: string[] = [];
    lines.push("=== Omega Studio — configuración de IA (OMEGA_AI_*) ===");
    lines.push(
        `Inyectar desde la extensión: ${inject ? "sí" : "no"} (omegaStudio.ai.injectEnvironment)`
    );
    if (!inject) {
        lines.push("El CLI «omega» usa solo variables del sistema / terminal integrado.");
        lines.push(
            "Activa la inyección en Ajustes → Omega Studio, o ejecuta «Omega: IA — configurar…»."
        );
        return lines.join("\n");
    }
    lines.push(`OMEGA_AI_ENABLED: ${cfg.get<boolean>("ai.enabled") ? "true" : "false"}`);
    lines.push(`OMEGA_AI_PROVIDER: ${cfg.get<string>("ai.provider") ?? "none"}`);
    const model = (cfg.get<string>("ai.model") ?? "").trim();
    lines.push(`OMEGA_AI_MODEL: ${model.length > 0 ? model : "(vacío)"}`);
    const bu = (cfg.get<string>("ai.baseUrl") ?? "").trim();
    lines.push(`OMEGA_AI_BASE_URL: ${bu.length > 0 ? bu : "(vacío)"}`);
    const ok = await context.secrets.get(SECRET_OPENAI);
    lines.push(`OMEGA_AI_API_KEY: ${ok ? maskKey(ok) : "(no guardada en la extensión)"}`);
    const gk = await context.secrets.get(SECRET_GEMINI);
    lines.push(
        `OMEGA_AI_GEMINI_API_KEY: ${gk ? maskKey(gk) : "(no guardada en la extensión)"}`
    );
    lines.push("");
    lines.push(
        "Las claves están en el almacén seguro del editor (SecretStorage), no en archivos del repo."
    );
    return lines.join("\n");
}

export async function runConfigureAiWizard(
    context: vscode.ExtensionContext
): Promise<void> {
    const cfg = vscode.workspace.getConfiguration("omegaStudio");
    const tgt = vscode.ConfigurationTarget.Global;

    const inject = await vscode.window.showQuickPick(
        [
            {
                label: "Sí",
                description: "Inyectar OMEGA_AI_* al ejecutar omega desde Omega Studio",
            },
            { label: "No", description: "No modificar el entorno del proceso omega" },
        ],
        { title: "¿Usar variables de IA definidas en Omega Studio?" }
    );
    if (!inject) {
        return;
    }
    await cfg.update("ai.injectEnvironment", inject.label === "Sí", tgt);

    if (inject.label === "No") {
        void vscode.window.showInformationMessage(
            "Omega Studio: inyección de IA desactivada."
        );
        return;
    }

    const en = await vscode.window.showQuickPick(
        [
            { label: "Sí", description: "OMEGA_AI_ENABLED=true" },
            { label: "No", description: "OMEGA_AI_ENABLED=false" },
        ],
        { title: "¿Habilitar IA en el CLI Omega?" }
    );
    if (!en) {
        return;
    }
    await cfg.update("ai.enabled", en.label === "Sí", tgt);

    const prov = await vscode.window.showQuickPick(
        [
            { label: "none", description: "Sin proveedor remoto" },
            { label: "openai", description: "OpenAI" },
            { label: "gemini", description: "Google Gemini" },
            { label: "ollama", description: "Ollama local" },
            { label: "anthropic", description: "Anthropic (si el CLI lo usa)" },
        ],
        { title: "Proveedor (OMEGA_AI_PROVIDER)" }
    );
    if (!prov) {
        return;
    }
    await cfg.update("ai.provider", prov.label, tgt);

    const model = await vscode.window.showInputBox({
        title: "Modelo (OMEGA_AI_MODEL)",
        prompt: "Ej: gpt-4o-mini, gemini-2.5-flash. Vacío para omitir.",
        placeHolder: "gpt-4o-mini",
    });
    if (model === undefined) {
        return;
    }
    await cfg.update("ai.model", model.trim(), tgt);

    const baseUrl = await vscode.window.showInputBox({
        title: "Base URL opcional (OMEGA_AI_BASE_URL)",
        prompt: "Solo si usas endpoint OpenAI-compatible personalizado. Vacío para omitir.",
        placeHolder: "https://api.openai.com/v1",
    });
    if (baseUrl === undefined) {
        return;
    }
    await cfg.update("ai.baseUrl", baseUrl.trim(), tgt);

    const keyAction = await vscode.window.showQuickPick(
        [
            {
                label: "Establecer OMEGA_AI_API_KEY",
                description: "OpenAI u otra clave compatible",
            },
            {
                label: "Establecer OMEGA_AI_GEMINI_API_KEY",
                description: "Google AI Studio (Gemini)",
            },
            { label: "No cambiar claves", description: "Dejar secretos como están" },
            { label: "Borrar todas las claves guardadas", description: "" },
        ],
        { title: "Claves API (almacén seguro del editor)" }
    );
    if (!keyAction) {
        return;
    }
    if (keyAction.label.startsWith("Establecer OMEGA_AI_API_KEY")) {
        const k = await vscode.window.showInputBox({
            prompt: "Pega OMEGA_AI_API_KEY",
            password: true,
            ignoreFocusOut: true,
        });
        if (k !== undefined && k.length > 0) {
            await context.secrets.store(SECRET_OPENAI, k);
        }
    } else if (keyAction.label.startsWith("Establecer OMEGA_AI_GEMINI")) {
        const k = await vscode.window.showInputBox({
            prompt: "Pega OMEGA_AI_GEMINI_API_KEY",
            password: true,
            ignoreFocusOut: true,
        });
        if (k !== undefined && k.length > 0) {
            await context.secrets.store(SECRET_GEMINI, k);
        }
    } else if (keyAction.label.startsWith("Borrar")) {
        await context.secrets.delete(SECRET_OPENAI);
        await context.secrets.delete(SECRET_GEMINI);
        void vscode.window.showInformationMessage(
            "Claves API de Omega Studio borradas del almacén seguro."
        );
    }

    void vscode.window.showInformationMessage(
        "Configuración de IA guardada. Usa «Omega: IA — ver configuración» para revisarla."
    );
}
