# Getting started

## Install the package

**Global CLI** (recommended so `omega` is on your PATH):

```bash
dart pub global activate omega_architecture
```

Bleeding edge from Git:

```bash
dart pub global activate --source git https://github.com/yefersonSegura/omega_architecture.git
```

Add Pub’s global `bin` to your **PATH** (Windows: `%LOCALAPPDATA%\Pub\Cache\bin` · macOS/Linux: `$HOME/.pub-cache/bin`).

## New application

```bash
omega create app my_app
cd my_app && flutter run
```

## Existing Flutter app

In `pubspec.yaml`:

```yaml
dependencies:
  omega_architecture: ^1.0.4
```

From the **app root** (where `pubspec.yaml` lives):

```bash
dart run omega_architecture:omega init
```

Then wire **`omega_setup.dart`**, flows, agents, and routes — see **[omega_setup](./omega-setup)** and **[Core concepts](./concepts)**.

## Learn the runtime

1. [Core concepts](./concepts)  
2. [Data flow](./data-flow)  
3. [Channel & events](./channel-events), [Intents & flows](./intents-flows-manager), [Agents](./agents-behaviors)  
4. [Navigation & routes](./navigation-router)  
5. [API reference](./api-reference) on pub.dev  

## Command not found?

See the **Troubleshooting** section in the [README](https://github.com/yefersonSegura/omega_architecture/blob/main/README.md#troubleshooting-omega-command-not-found) (PATH on Windows and Git Bash).
