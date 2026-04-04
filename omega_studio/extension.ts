import * as vscode from "vscode";
import { spawn } from "child_process";

let outputChannel: vscode.OutputChannel;

function getWorkspaceRoot(): string | undefined {
    return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
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
                    env: process.env,
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
    outputChannel = vscode.window.createOutputChannel("Omega Studio");
    context.subscriptions.push(outputChannel);

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
        const appName = await vscode.window.showInputBox({
            prompt: "Nombre de la app Flutter",
            placeHolder: "my_omega_app",
        });
        if (!appName?.trim()) return;

        const kickstart = await vscode.window.showInputBox({
            prompt: 'Kickstart opcional (descripción para IA), vacío para omitir',
            placeHolder: 'login, perfil y ajustes',
        });

        const useApi = await vscode.window.showQuickPick(
            [
                { label: "No", description: "Sin --provider-api" },
                { label: "Sí", description: "Añadir --provider-api" },
            ],
            { title: "¿Usar API del proveedor en create app?" }
        );
        if (!useApi) return;

        const args = ["create", "app", appName.trim()];
        if (kickstart?.trim()) {
            args.push("--kickstart", kickstart.trim());
        }
        if (useApi.label === "Sí") {
            args.push("--provider-api");
        }

        const parent = await vscode.window.showOpenDialog({
            canSelectFiles: false,
            canSelectFolders: true,
            canSelectMany: false,
            openLabel: "Carpeta padre donde crear el proyecto",
        });
        const cwd = parent?.[0]?.fsPath;
        if (!cwd) {
            vscode.window.showWarningMessage("Create app cancelado: elige la carpeta padre.");
            return;
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
        const args = ["ai", "coach", "audit", feature.trim(), "--template", template];
        if (providerApi) args.push("--provider-api");

        try {
            await runOmega(args, "Omega ai coach audit");
        } catch {
            /* ya notificado */
        }
    });

    type PickEntry = { label: string; description: string; command: string };

    const pickEntries: PickEntry[] = [
        { label: "Validar (validate)", description: "omega validate", command: "omega.runValidate" },
        { label: "Doctor", description: "omega doctor [ruta]", command: "omega.runDoctor" },
        { label: "Init omega_setup", description: "omega init [--force]", command: "omega.runInit" },
        { label: "Abrir documentación (doc)", description: "omega doc", command: "omega.openDoc" },
        { label: "Inspector local", description: "omega inspector", command: "omega.openInspector" },
        { label: "Generar ecosistema", description: "omega g ecosystem <Nombre>", command: "omega.generateEcosystem" },
        { label: "Generar agente", description: "omega g agent <Nombre>", command: "omega.generateAgent" },
        { label: "Generar flow", description: "omega g flow <Nombre>", command: "omega.generateFlow" },
        { label: "Crear app Flutter", description: "omega create app …", command: "omega.createApp" },
        { label: "Trace: ver resumen", description: "omega trace view <archivo>", command: "omega.traceView" },
        { label: "Trace: validar", description: "omega trace validate <archivo>", command: "omega.traceValidate" },
        { label: "IA: doctor", description: "omega ai doctor", command: "omega.runAiDoctor" },
        { label: "IA: variables de entorno", description: "omega ai env", command: "omega.runAiEnv" },
        { label: "IA: explain trace", description: "omega ai explain <archivo>", command: "omega.aiExplainTrace" },
        { label: "IA: coach start", description: "omega ai coach start …", command: "omega.aiCoachStart" },
        { label: "IA: coach audit", description: "omega ai coach audit …", command: "omega.aiCoachAudit" },
        { label: "IA: módulo con diseño", description: "omega ai coach module …", command: "omega.generateModule" },
        { label: "IA: rediseñar página", description: "omega ai coach redesign …", command: "omega.editUiWithAi" },
    ];

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
