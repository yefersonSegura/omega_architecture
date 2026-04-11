import * as vscode from "vscode";
import {
    OMEGA_ACTIONS,
    OMEGA_CATEGORIES_ORDER,
    categoryTitle,
    type OmegaActionCategory,
    type OmegaActionEntry,
} from "./omega_actions";

type TreeNode = CategoryNode | ActionNode;

class CategoryNode {
    readonly kind = "category" as const;
    constructor(readonly id: OmegaActionCategory, readonly label: string) {}
}

class ActionNode {
    readonly kind = "action" as const;
    constructor(readonly action: OmegaActionEntry) {}
}

export class OmegaMenuTreeProvider implements vscode.TreeDataProvider<TreeNode> {
    private _onDidChange = new vscode.EventEmitter<TreeNode | undefined | void>();
    readonly onDidChangeTreeData = this._onDidChange.event;

    refresh(): void {
        this._onDidChange.fire();
    }

    getTreeItem(element: TreeNode): vscode.TreeItem {
        if (element.kind === "category") {
            const item = new vscode.TreeItem(
                element.label,
                vscode.TreeItemCollapsibleState.Collapsed
            );
            item.id = `omega-cat-${element.id}`;
            item.iconPath = new vscode.ThemeIcon("folder");
            return item;
        }
        const a = element.action;
        const item = new vscode.TreeItem(a.label, vscode.TreeItemCollapsibleState.None);
        item.id = `omega-act-${a.command}`;
        item.description = a.description;
        item.tooltip = `${a.label}\n${a.description}`;
        item.iconPath = new vscode.ThemeIcon("play");
        item.command = {
            command: a.command,
            title: a.label,
        };
        return item;
    }

    getChildren(element?: TreeNode): TreeNode[] {
        if (!element) {
            return OMEGA_CATEGORIES_ORDER.map(
                (id) => new CategoryNode(id, categoryTitle(id))
            );
        }
        if (element.kind === "category") {
            return OMEGA_ACTIONS.filter((a) => a.category === element.id).map(
                (a) => new ActionNode(a)
            );
        }
        return [];
    }
}
