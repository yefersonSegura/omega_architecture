import * as vscode from "vscode";
import { spawn } from "child_process";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";
import {
    buildOmegaEnv,
    formatAiConfigurationSummary,
    runConfigureAiWizard,
} from "./ai_env";
import { OMEGA_ACTIONS } from "./omega_actions";
import { OmegaMenuTreeProvider } from "./omega_tree";

let outputChannel: vscode.OutputChannel;
let extContext: vscode.ExtensionContext;

function getWorkspaceRoot(): string | undefined {
    return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
}

/** CWD para spawn: proyecto abierto o home (omega ai doctor solo usa env). */
function getOmegaSpawnCwd(): string {
    return getWorkspaceRoot() ?? os.homedir();
}

/** Carpeta padre donde `flutter create` / `omega create app` generará el subproyecto. */
async function pickParentDirectoryForCreateApp(): Promise<string | undefined> {
    const choice = await vscode.window.showQuickPick(
        [
            {
                label: "$(folder-opened) Examinar…",
                description: "Elegir carpeta con el diálogo del sistema",
            },
            {
                label: "$(edit) Escribir ruta",
                description: "Carpeta padre que ya existe (ruta absoluta o relativa)",
            },
            {
                label: "$(new-folder) Crear carpeta",
                description: "Indica la ruta; se crean carpetas intermedias si no existen",
            },
        ],
        { title: "Carpeta padre del nuevo proyecto Flutter", placeHolder: "Examinar, escribir o crear" }
    );
    if (!choice) {
        return undefined;
    }

    if (choice.label.includes("Examinar")) {
        const uris = await vscode.window.showOpenDialog({
            canSelectFiles: false,
            canSelectFolders: true,
            canSelectMany: false,
            openLabel: "Carpeta padre",
        });
        return uris?.[0]?.fsPath;
    }

    if (choice.label.includes("Escribir ruta")) {
        const raw = await vscode.window.showInputBox({
            prompt: "Ruta de la carpeta padre (debe existir)",
            placeHolder: "Ej: C:\\dev o /home/user/proyectos",
        });
        if (!raw?.trim()) {
            return undefined;
        }
        const abs = path.resolve(raw.trim().replace(/^["']|["']$/g, ""));
        try {
            const st = fs.statSync(abs);
            if (!st.isDirectory()) {
                vscode.window.showErrorMessage("La ruta no es una carpeta.");
                return undefined;
            }
        } catch {
            vscode.window.showErrorMessage("La carpeta no existe. Usa «Crear carpeta» o revisa la ruta.");
            return undefined;
        }
        return abs;
    }

    if (choice.label.includes("Crear carpeta")) {
        const raw = await vscode.window.showInputBox({
            prompt: "Ruta completa de la carpeta padre (se creará con sus padres si hace falta)",
            placeHolder: "Ej: C:\\dev\\clientes\\nuevo",
        });
        if (!raw?.trim()) {
            return undefined;
        }
        const abs = path.resolve(raw.trim().replace(/^["']|["']$/g, ""));
        try {
            fs.mkdirSync(abs, { recursive: true });
        } catch (e) {
            vscode.window.showErrorMessage(`No se pudo crear la carpeta: ${String(e)}`);
            return undefined;
        }
        return abs;
    }

    return undefined;
}

/**
 * Ejecuta `omega ai doctor` y devuelve si la salida indica configuración válida.
 */
async function checkAiDoctorOutput(): Promise<{
    ok: boolean;
    output: string;
    spawnError?: string;
}> {
    const cwd = getOmegaSpawnCwd();
    const env = extContext
        ? await buildOmegaEnv(extContext)
        : { ...process.env };
    try {
        const combined = await vscode.window.withProgress(
            {
                location: vscode.ProgressLocation.Notification,
                title: "Omega: comprobando configuración de IA (omega ai doctor)…",
                cancellable: false,
            },
            () =>
                new Promise<string>((resolve, reject) => {
                    const chunks: Buffer[] = [];
                    const child = spawn("omega", ["ai", "doctor"], {
                        cwd,
                        shell: true,
                        env,
                    });
                    child.stdout?.on("data", (c) => chunks.push(Buffer.from(c)));
                    child.stderr?.on("data", (c) => chunks.push(Buffer.from(c)));
                    child.on("error", reject);
                    child.on("close", () =>
                        resolve(Buffer.concat(chunks).toString("utf8"))
                    );
                })
        );
        outputChannel.show(true);
        outputChannel.appendLine("\n$ omega ai doctor\n");
        outputChannel.appendLine(combined);
        const ok = combined.includes("AI base configuration looks good.");
        return { ok, output: combined };
    } catch (err) {
        const msg =
            (err as NodeJS.ErrnoException).code === "ENOENT"
                ? "No se encontró «omega» en el PATH."
                : String(err);
        return { ok: false, output: "", spawnError: msg };
    }
}

/**
 * Comprueba IA; si falla, muestra error (comandos genéricos con --provider-api).
 */
async function assertAiProviderReady(): Promise<boolean> {
    const { ok, spawnError } = await checkAiDoctorOutput();
    if (spawnError) {
        vscode.window.showErrorMessage(`Omega: ${spawnError}`);
        return false;
    }
    if (ok) {
        return true;
    }
    await vscode.window.showErrorMessage(
        "La configuración de IA no está lista. Define OMEGA_AI_ENABLED=true, proveedor (p. ej. openai|gemini) y la clave API. Revisa el canal «Omega Studio» o ejecuta el comando «IA: doctor».",
        { modal: false }
    );
    return false;
}

/**
 * Para **crear app con IA** (`--provider-api` y/o kickstart con API): si `omega ai doctor`
 * no pasa, ofrece abrir el asistente de credenciales y vuelve a comprobar.
 */
async function ensureAiReadyForCreateApp(): Promise<boolean> {
    let { ok, spawnError } = await checkAiDoctorOutput();
    if (spawnError) {
        vscode.window.showErrorMessage(`Omega: ${spawnError}`);
        return false;
    }
    if (ok) {
        return true;
    }

    const choice = await vscode.window.showWarningMessage(
        "Para crear la app con IA hace falta una configuración válida (OMEGA_AI_ENABLED, proveedor, clave API). ¿Quieres abrir el asistente para completar las credenciales?",
        { modal: false },
        "Configurar credenciales…",
        "Cancelar"
    );
    if (choice !== "Configurar credenciales…" || !extContext) {
        await vscode.window.showInformationMessage(
            "Puedes configurar IA después con el comando «Omega: IA — configurar OMEGA_AI_*…»."
        );
        return false;
    }

    await runConfigureAiWizard(extContext);

    const second = await checkAiDoctorOutput();
    if (second.spawnError) {
        vscode.window.showErrorMessage(`Omega: ${second.spawnError}`);
        return false;
    }
    if (second.ok) {
        void vscode.window.showInformationMessage(
            "Configuración de IA lista. Continuando con la creación de la app."
        );
        return true;
    }

    await vscode.window.showErrorMessage(
        "Tras configurar, «omega ai doctor» sigue sin indicar éxito. Revisa el canal Omega Studio o las variables del sistema."
    );
    return false;
}

function appendOutput(data: Buffer | string): void {
    const text = typeof data === "string" ? data : data.toString();
    if (text.length > 0) {
        outputChannel.append(text.endsWith("\n") ? text : text + "\n");
    }
}

async function runOmega(
    args: string[],
    progressTitle: string,
    cwd?: string
): Promise<void> {
    const root = cwd ?? getWorkspaceRoot();
    if (!root) {
        vscode.window.showErrorMessage(
            "Omega: abre una carpeta de workspace (raíz del proyecto Flutter)."
        );
        throw new Error("no workspace");
    }

    const env = extContext
        ? await buildOmegaEnv(extContext)
        : { ...process.env };

    outputChannel.show(true);
    const quoted = args.map((a) => (/\s/.test(a) ? JSON.stringify(a) : a)).join(" ");
    outputChannel.appendLine(`\n$ omega ${quoted}\n`);

    await vscode.window.withProgress(
        {
            location: vscode.ProgressLocation.Notification,
            title: progressTitle,
            cancellable: false,
        },
        () =>
            new Promise<void>((resolve, reject) => {
                const child = spawn("omega", args, {
                    cwd: root,
                    shell: true,
                    env,
                });

                let stderr = "";
                child.stdout?.on("data", (chunk) => appendOutput(chunk));
                child.stderr?.on("data", (chunk) => {
                    const s = chunk.toString();
                    stderr += s;
                    appendOutput(chunk);
                });

                child.on("error", (err) => {
                    const msg =
                        (err as NodeJS.ErrnoException).code === "ENOENT"
                            ? "No se encontró el comando «omega» en el PATH. Instálalo o usa «dart run omega_architecture:omega» desde la raíz del paquete."
                            : String(err);
                    vscode.window.showErrorMessage(`Omega: ${msg}`);
                    reject(err);
                });

                child.on("close", (code) => {
                    if (code === 0) {
                        vscode.window.showInformationMessage(`${progressTitle} · terminado`);
                        resolve();
                    } else {
                        const tail = stderr.trim().split("\n").slice(-3).join(" ");
                        vscode.window.showErrorMessage(
                            `Omega terminó con código ${code}${tail ? `: ${tail}` : ""}`
                        );
                        reject(new Error(`exit ${code}`));
                    }
                });
            })
    );
}

async function pickCoachOptions(): Promise<{ template: string; providerApi: boolean }> {
    const templatePick = await vscode.window.showQuickPick(
        [
            { label: "advanced", description: "Workflow, stateful, contratos, tests" },
            { label: "basic", description: "Scaffold mínimo" },
        ],
        { title: "Plantilla del coach", placeHolder: "advanced" }
    );
    const template = templatePick?.label ?? "advanced";

    const apiPick = await vscode.window.showQuickPick(
        [
            { label: "Sí", description: "Usar --provider-api (OpenAI u otro proveedor)" },
            { label: "No", description: "Sin API del proveedor" },
        ],
        { title: "¿Usar API del proveedor?", placeHolder: "Sí" }
    );
    const providerApi = apiPick?.label !== "No";

    return { template, providerApi };
}

async function pickJsonFile(title: string): Promise<string | undefined> {
    const uris = await vscode.window.showOpenDialog({
        canSelectMany: false,
        openLabel: title,
        filters: { JSON: ["json"], "Todos": ["*"] },
    });
    return uris?.[0]?.fsPath;
}

export function activate(context: vscode.ExtensionContext): void {
    extContext = context;
    outputChannel = vscode.window.createOutputChannel("Omega Studio");
    context.subscriptions.push(outputChannel);

    const configureAi = vscode.commands.registerCommand("omega.configureAi", async () => {
        await runConfigureAiWizard(context);
    });

    const showAiConfiguration = vscode.commands.registerCommand(
        "omega.showAiConfiguration",
        async () => {
            const text = await formatAiConfigurationSummary(context);
            outputChannel.show(true);
            outputChannel.appendLine("\n" + text + "\n");
            await vscode.window.showInformationMessage(
                "Configuración listada en el canal «Omega Studio».",
                "Abrir canal"
            ).then((sel) => {
                if (sel === "Abrir canal") {
                    outputChannel.show(true);
                }
            });
        }
    );

    context.subscriptions.push(configureAi, showAiConfiguration);

    const omegaTree = new OmegaMenuTreeProvider();
    context.subscriptions.push(
        vscode.window.registerTreeDataProvider("omega.sidebarMenu", omegaTree)
    );

    const generateModule = vscode.commands.registerCommand(
        "omega.generateModule",
        async () => {
            const moduleName = await vscode.window.showInputBox({
                prompt: "Nombre del módulo (ej. Delivery)",
                placeHolder: "PascalCase",
            });
            if (!moduleName) return;

            const description = await vscode.window.showInputBox({
                prompt: "¿Cómo quieres que sea la pantalla?",
                placeHolder: "Un dashboard con lista de pedidos y estado real...",
            });
            if (!description) return;

            const { template, providerApi } = await pickCoachOptions();
            if (providerApi && !(await assertAiProviderReady())) {
                return;
            }
            const feature = `${moduleName}: ${description}`;
            const args = ["ai", "coach", "module", feature, "--template", template];
            if (providerApi) args.push("--provider-api");

            try {
                await runOmega(args, `Diseñando módulo ${moduleName}…`);
            } catch {
                /* mensaje ya mostrado */
            }
        }
    );

    const editUiWithAi = vscode.commands.registerCommand(
        "omega.editUiWithAi",
        async (uri: vscode.Uri) => {
            const activeEditor = vscode.window.activeTextEditor;
            const filePath = uri?.fsPath || activeEditor?.document.fileName;

            if (!filePath || !filePath.endsWith("_page.dart")) {
                vscode.window.showErrorMessage(
                    "Abre un archivo de página Omega (*_page.dart)"
                );
                return;
            }

            const fileName = filePath.split(/[\\/]/).pop() || "";
            const moduleLower = fileName.replace("_page.dart", "");
            const moduleName =
                moduleLower.charAt(0).toUpperCase() + moduleLower.slice(1);

            const instruction = await vscode.window.showInputBox({
                prompt: `¿Qué cambios quieres en la pantalla de ${moduleName}?`,
                placeHolder: "Ej: Añade búsqueda y cambia el color del botón",
            });
            if (!instruction) return;

            const { template, providerApi } = await pickCoachOptions();
            if (providerApi && !(await assertAiProviderReady())) {
                return;
            }
            const feature = `${moduleName}: ${instruction}`;
            const args = ["ai", "coach", "redesign", feature, "--template", template];
            if (providerApi) args.push("--provider-api");

            try {
                await runOmega(args, `Rediseñando ${moduleName}…`);
            } catch {
                /* mensaje ya mostrado */
            }
        }
    );

    const runValidate = vscode.commands.registerCommand("omega.runValidate", async () => {
        try {
            await runOmega(["validate"], "Omega validate");
        } catch {
            /* ya notificado */
        }
    });

    const runDoctor = vscode.commands.registerCommand("omega.runDoctor", async () => {
        const pathArg = await vscode.window.showInputBox({
            prompt: "Ruta opcional desde la que buscar (por defecto raíz del workspace)",
            placeHolder: ". o example",
            value: ".",
        });
        if (pathArg === undefined) return;
        const args = pathArg.trim() === "" || pathArg.trim() === "." ? ["doctor"] : ["doctor", pathArg.trim()];
        try {
            await runOmega(args, "Omega doctor");
        } catch {
            /* ya notificado */
        }
    });

    const runInit = vscode.commands.registerCommand("omega.runInit", async () => {
        const force = await vscode.window.showQuickPick(
            [
                { label: "No", description: "Crear omega_setup.dart si no existe" },
                { label: "Sí (--force)", description: "Sobrescribir si ya existe" },
            ],
            { title: "¿Forzar sobrescritura?" }
        );
        if (!force) return;
        const args = force.label.startsWith("Sí") ? ["init", "--force"] : ["init"];
        try {
            await runOmega(args, "Omega init");
        } catch {
            /* ya notificado */
        }
    });

    const openDoc = vscode.commands.registerCommand("omega.openDoc", async () => {
        try {
            await runOmega(["doc"], "Omega doc");
        } catch {
            /* ya notificado */
        }
    });

    const openInspector = vscode.commands.registerCommand(
        "omega.openInspector",
        async () => {
            try {
                await runOmega(["inspector"], "Omega inspector");
            } catch {
                /* ya notificado */
            }
        }
    );

    const generateEcosystem = vscode.commands.registerCommand(
        "omega.generateEcosystem",
        async () => {
            const name = await vscode.window.showInputBox({
                prompt: "Nombre del ecosistema (PascalCase)",
                placeHolder: "Auth",
            });
            if (!name?.trim()) return;
            try {
                await runOmega(["g", "ecosystem", name.trim()], `Omega g ecosystem ${name.trim()}`);
            } catch {
                /* ya notificado */
            }
        }
    );

    const generateAgent = vscode.commands.registerCommand(
        "omega.generateAgent",
        async () => {
            const name = await vscode.window.showInputBox({
                prompt: "Nombre del agente (PascalCase)",
                placeHolder: "Orders",
            });
            if (!name?.trim()) return;
            try {
                await runOmega(["g", "agent", name.trim()], `Omega g agent ${name.trim()}`);
            } catch {
                /* ya notificado */
            }
        }
    );

    const generateFlow = vscode.commands.registerCommand(
        "omega.generateFlow",
        async () => {
            const name = await vscode.window.showInputBox({
                prompt: "Nombre del flow (PascalCase)",
                placeHolder: "Orders",
            });
            if (!name?.trim()) return;
            try {
                await runOmega(["g", "flow", name.trim()], `Omega g flow ${name.trim()}`);
            } catch {
                /* ya notificado */
            }
        }
    );

    const createApp = vscode.commands.registerCommand("omega.createApp", async () => {
        const cwd = await pickParentDirectoryForCreateApp();
        if (!cwd) {
            vscode.window.showWarningMessage(
                "Creación cancelada: indica la carpeta padre del proyecto."
            );
            return;
        }

        const appName = await vscode.window.showInputBox({
            prompt: "Nombre del proyecto Flutter (carpeta y paquete dentro de la carpeta padre)",
            placeHolder: "my_omega_app",
        });
        if (!appName?.trim()) {
            return;
        }

        const mode = await vscode.window.showQuickPick(
            [
                {
                    label: "Sin IA",
                    description:
                        "Mínimo: flutter create + dependencia + omega init (sin módulos ni kickstart)",
                },
                {
                    label: "Con IA",
                    description: "Kickstart con generación asistida (--kickstart + --provider-api)",
                },
            ],
            {
                title: "¿Generar el proyecto con IA?",
                placeHolder: "Sin IA o Con IA",
            }
        );
        if (!mode) {
            return;
        }

        const withAi = mode.label === "Con IA";
        if (withAi && !(await ensureAiReadyForCreateApp())) {
            return;
        }

        let kickstart: string | undefined;
        if (withAi) {
            const ks = await vscode.window.showInputBox({
                prompt: "Kickstart: describe el producto para la IA (pantallas, módulos, flujo)",
                placeHolder:
                    "Ej: login con email, home con lista de pedidos, perfil y ajustes",
            });
            if (ks === undefined) {
                return;
            }
            kickstart = ks.trim();
            if (!kickstart) {
                vscode.window.showWarningMessage(
                    "Con IA hace falta el kickstart; vuelve a intentar o elige «Sin IA»."
                );
                return;
            }
        }

        // Sin IA: solo `omega create app <nombre>` → CLI: flutter create, pub add omega, init,
        // main Omega mínimo; no --kickstart, no --provider-api, no generación de módulos por IA.
        const args = ["create", "app", appName.trim()];
        if (withAi && kickstart) {
            args.push("--kickstart", kickstart);
            args.push("--provider-api");
        }

        try {
            await runOmega(args, `Omega create app ${appName.trim()}`, cwd);
        } catch {
            /* ya notificado */
        }
    });

    const traceView = vscode.commands.registerCommand("omega.traceView", async () => {
        const file = await pickJsonFile("Archivo de trace JSON");
        if (!file) return;
        try {
            await runOmega(["trace", "view", file], "Omega trace view");
        } catch {
            /* ya notificado */
        }
    });

    const traceValidate = vscode.commands.registerCommand(
        "omega.traceValidate",
        async () => {
            const file = await pickJsonFile("Archivo de trace JSON");
            if (!file) return;
            try {
                await runOmega(["trace", "validate", file], "Omega trace validate");
            } catch {
                /* ya notificado */
            }
        }
    );

    const runAiDoctor = vscode.commands.registerCommand("omega.runAiDoctor", async () => {
        try {
            await runOmega(["ai", "doctor"], "Omega ai doctor");
        } catch {
            /* ya notificado */
        }
    });

    const runAiEnv = vscode.commands.registerCommand("omega.runAiEnv", async () => {
        try {
            await runOmega(["ai", "env"], "Omega ai env");
        } catch {
            /* ya notificado */
        }
    });

    const aiExplainTrace = vscode.commands.registerCommand(
        "omega.aiExplainTrace",
        async () => {
            const file = await pickJsonFile("Trace JSON para explain");
            if (!file) return;

            const useApi = await vscode.window.showQuickPick(
                [
                    { label: "No", description: "Solo offline / heurístico" },
                    { label: "Sí", description: "Añadir --provider-api" },
                ],
                { title: "¿Usar API del proveedor?" }
            );
            if (!useApi) return;

            if (useApi.label === "Sí" && !(await assertAiProviderReady())) {
                return;
            }

            const args = ["ai", "explain", file];
            if (useApi.label === "Sí") {
                args.push("--provider-api");
            }
            try {
                await runOmega(args, "Omega ai explain");
            } catch {
                /* ya notificado */
            }
        }
    );

    const aiCoachStart = vscode.commands.registerCommand("omega.aiCoachStart", async () => {
        const feature = await vscode.window.showInputBox({
            prompt: "Descripción de la funcionalidad (coach start)",
            placeHolder: "Onboarding con tres pasos y validación de email",
        });
        if (!feature?.trim()) return;

        const { template, providerApi } = await pickCoachOptions();
        if (providerApi && !(await assertAiProviderReady())) {
            return;
        }
        const args = ["ai", "coach", "start", feature.trim(), "--template", template];
        if (providerApi) args.push("--provider-api");

        try {
            await runOmega(args, "Omega ai coach start");
        } catch {
            /* ya notificado */
        }
    });

    const aiCoachAudit = vscode.commands.registerCommand("omega.aiCoachAudit", async () => {
        const feature = await vscode.window.showInputBox({
            prompt: "Ámbito a auditar (coach audit)",
            placeHolder: "Módulo Checkout o ruta lib/",
        });
        if (!feature?.trim()) return;

        const { template, providerApi } = await pickCoachOptions();
        if (providerApi && !(await assertAiProviderReady())) {
            return;
        }
        const args = ["ai", "coach", "audit", feature.trim(), "--template", template];
        if (providerApi) args.push("--provider-api");

        try {
            await runOmega(args, "Omega ai coach audit");
        } catch {
            /* ya notificado */
        }
    });

    const pickEntries = OMEGA_ACTIONS.map((a) => ({
        label: a.label,
        description: a.description,
        command: a.command,
    }));

    const pickCommand = vscode.commands.registerCommand("omega.pickCommand", async () => {
        const picked = await vscode.window.showQuickPick(pickEntries, {
            placeHolder: "Elige un comando Omega",
            matchOnDescription: true,
        });
        if (!picked) return;
        await vscode.commands.executeCommand(picked.command);
    });

    context.subscriptions.push(
        generateModule,
        editUiWithAi,
        runValidate,
        runDoctor,
        runInit,
        openDoc,
        openInspector,
        generateEcosystem,
        generateAgent,
        generateFlow,
        createApp,
        traceView,
        traceValidate,
        runAiDoctor,
        runAiEnv,
        aiExplainTrace,
        aiCoachStart,
        aiCoachAudit,
        pickCommand
    );
}
