import * as vscode from 'vscode';
import { exec } from 'child_process';

export function activate(context: vscode.ExtensionContext) {
    console.log('Omega Studio ya está activo');

    // Comando para generar un módulo con diseño
    let generateModule = vscode.commands.registerCommand('omega.generateModule', async () => {
        // 1. Pedir el nombre del módulo al usuario
        const moduleName = await vscode.window.showInputBox({
            prompt: "Nombre del módulo (ej. Delivery)",
            placeHolder: "PascalCase"
        });

        if (!moduleName) return;

        // 2. Pedir la descripción del diseño
        const description = await vscode.window.showInputBox({
            prompt: "¿Cómo quieres que sea la pantalla?",
            placeHolder: "Un dashboard con lista de pedidos y estado real..."
        });

        if (!description) return;

        // 3. Ejecutar el CLI de Omega
        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: `Diseñando módulo ${moduleName}...`,
            cancellable: false
        }, (progress) => {
            return new Promise((resolve, reject) => {
                const command = `omega ai coach module "${moduleName}: ${description}" --template advanced --provider-api`;
                
                exec(command, { cwd: vscode.workspace.rootPath }, (error, stdout, stderr) => {
                    if (error) {
                        vscode.window.showErrorMessage(`Error de Omega: ${stderr}`);
                        reject(error);
                    } else {
                        vscode.window.showInformationMessage(`¡Módulo ${moduleName} diseñado con éxito!`);
                        resolve(stdout);
                    }
                });
            });
        });
    });

    // Comando para rediseñar la pantalla actual
    let editUiWithAi = vscode.commands.registerCommand('omega.editUiWithAi', async (uri: vscode.Uri) => {
        // 1. Obtener el archivo activo si no se pasa por el menú contextual
        const activeEditor = vscode.window.activeTextEditor;
        const filePath = uri?.fsPath || activeEditor?.document.fileName;

        if (!filePath || !filePath.endsWith('_page.dart')) {
            vscode.window.showErrorMessage("Por favor, abre un archivo de página de Omega (*_page.dart)");
            return;
        }

        // 2. Extraer el nombre del módulo del nombre del archivo
        const fileName = filePath.split(/[\\\/]/).pop() || "";
        const moduleLower = fileName.replace('_page.dart', '');
        const moduleName = moduleLower.charAt(0).toUpperCase() + moduleLower.slice(1);

        // 3. Pedir los cambios al usuario
        const instruction = await vscode.window.showInputBox({
            prompt: `¿Qué cambios quieres en la pantalla de ${moduleName}?`,
            placeHolder: "Ej: Añade un campo de búsqueda y cambia el color del botón a azul"
        });

        if (!instruction) return;

        // 4. Ejecutar Omega AI Coach con auto-sanación
        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: `Rediseñando ${moduleName}...`,
            cancellable: false
        }, (progress) => {
            return new Promise((resolve, reject) => {
                // Usamos el nuevo comando 'redesign'
                const command = `omega ai coach redesign "${moduleName}: ${instruction}" --template advanced --provider-api`;
                
                const workspaceRoot = vscode.workspace.workspaceFolders?.[0].uri.fsPath;

                exec(command, { cwd: workspaceRoot }, (error, stdout, stderr) => {
                    if (error) {
                        vscode.window.showErrorMessage(`Error de diseño: ${stderr || stdout}`);
                        reject(error);
                    } else {
                        vscode.window.showInformationMessage(`¡Pantalla ${moduleName} actualizada!`);
                        resolve(stdout);
                    }
                });
            });
        });
    });

    context.subscriptions.push(generateModule, editUiWithAi);
}
