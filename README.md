# Observability
## Project details and Services used
The application is deployed on **AWS** and utilizes **Terraform** to orchestrate the provisioning of multiple EC2 instances in different availability zones thereby creatinging a **highly available** architecture.

It employs **Terraform** as Infrastructure as Code (**IaC**) to automate the entire infrastructure stack and securely stores the state on an S3 remote backend, boosting efficiency and reducing operational overhead.

it leverages **Ansible** for the configuration and orchestration of the **static web hosting**, along with the observability and monitoring infrastructure across the multiple EC2 instances, ensuring smooth and efficient operations.

These observability and monitoring infrastructures:  ***Prometheus***, ***Grafana***, and ***Node Exporter*** are integrated to deliver real-time insights and performance metrics.

# Vscode extension.json

```json
{
    "recommendations": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "charliermarsh.ruff",
        "github.copilot",
        "tamasfe.even-better-toml",
        "aaron-bond.better-comments",
        "github.vscode-github-actions",
        "bierner.markdown-mermaid",
        "ms-vscode-remote.remote-containers",
    ]
}
```

# Vscode setting.json
## Folder setting
```json
{
    // Python settings
    "python.analysis.autoSearchPaths": true,
    "python.analysis.diagnosticSeverityOverrides": {
        "reportMissingImports": "none"
    },
    "python.analysis.extraPaths": [
        "${workspaceFolder}/src"
    ],
    "python.envFile": "${workspaceFolder}/.env",
    "python.terminal.activateEnvironment": true,
    "terminal.integrated.env.linux": {
        "PYTHONPATH": "${workspaceFolder}:${env:PYTHONPATH}"
    },
    "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
    // Test settings
    "python.testing.pytestEnabled": true,
    "python.testing.unittestEnabled": false,
    "python.testing.cwd": "${workspaceFolder}/tests",
    "python.testing.pytestPath": "${workspaceFolder}/.venv/bin/pytest",
    "python.testing.autoTestDiscoverOnSaveEnabled": true,
}
```

## User setting
```json
{
    // General settings
    "security.workspace.trust.untrustedFiles": "newWindow",
    "window.zoomLevel": 0,
    "window.commandCenter": false,
    "files.exclude": {
        ".git": true,
        "**/.git": false
    },
    "extensions.autoUpdate": "onlyEnabledExtensions",
    // Git settings
    "git.autofetch": true,
    "git.confirmSync": false,
    "git.enableSmartCommit": true,
    "git.showActionButton": {
        "commit": false,
        "publish": false,
        "sync": false
    },
    "github.copilot.enable": {
        "*": true,
        "plaintext": false,
        "scminput": false,
        "yaml": true
    },
    // Explorer settings
    "explorer.excludeGitIgnore": true,
    "explorer.autoReveal": true,
    "explorer.confirmDelete": false,
    "explorer.confirmDragAndDrop": false,
    // Workbench settings
    "workbench.colorTheme": "Default Dark+",
    "workbench.iconTheme": "ayu",
    "workbench.editor.enablePreview": false,
    "workbench.editor.tabSizing": "shrink",
    "workbench.settings.editor": "json",
    // Editor settings
    "ruff.importStrategy": "useBundled",
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnPaste": true,
    "editor.formatOnSave": true,
    "editor.formatOnSaveMode": "file",
    "editor.codeActionsOnSave": {
        "source.organizeImports": "always",
        "source.fixAll": "always"
    },
    // "pylint.args": [
    //     "--max-line-length=150"
    // ],
    "files.autoSave": "onFocusChange",
    "[json]": {
        "editor.defaultFormatter": "vscode.json-language-features"
    },
    "[jsonc]": {
        "editor.defaultFormatter": "vscode.json-language-features"
    },
    // Debug settings
    "debug.toolBarLocation": "docked",
    // Terminal settings
    "terminal.integrated.tabs.enabled": true,
    "terminal.integrated.tabs.hideCondition": "never",
    "terminal.integrated.tabs.location": "right",
    // Markdown settings
    "markdown.preview.scrollEditorWithPreview": true,
    "markdown.preview.scrollPreviewWithEditor": true
}
```
