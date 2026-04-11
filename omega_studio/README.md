# Omega Studio

Extensión para **Visual Studio Code** y editores compatibles que integra el CLI **Omega** del paquete [`omega_architecture`](https://pub.dev/packages/omega_architecture) en tu flujo de trabajo Flutter: **icono «Ω» en la barra de actividades** (vista *Comandos* con menú por categorías), paleta de comandos, menú contextual del explorador y canal de salida.

## Características

- **Proyecto:** validar `omega_setup`, doctor, init, abrir documentación (`doc`) e inspector en el navegador (`inspector`).
- **Crear app Flutter:** **carpeta padre** (examinar, escribir ruta existente o **crear** carpeta con `mkdir -p`) → **nombre del proyecto** → **sin / con IA** → si es con IA: validación `omega ai doctor` y luego **kickstart**. **Sin IA** solo invoca `omega create app` con el nombre, **sin** `--kickstart` ni `--provider-api`: el CLI hace `flutter create`, añade `omega_architecture`, `omega init` y un `main` mínimo (sin módulos generados por IA).
- **Generación:** ecosistema (`g ecosystem`), agente, flow.
- **Trazas:** resumen y validación de traces.
- **IA:** **configurar** variables `OMEGA_*` desde un asistente (claves en almacén seguro del editor) y **ver configuración** en el canal de salida (claves enmascaradas). Doctor, explain trace y coach (start, audit, módulo, redesign). Con **API del proveedor**, antes se ejecuta `omega ai doctor` y solo continúa si la configuración es válida. También puedes editar valores en **Ajustes → Omega Studio**.
- **Paleta:** comando “Ejecutar comando Omega…” para listar y lanzar acciones rápidamente.

## Requisitos

- Tener el ejecutable **`omega`** en el `PATH` (por ejemplo tras `dart pub global activate omega_architecture`), o usar el proyecto según la guía del paquete.
- Abrir la **carpeta raíz** del proyecto Flutter como workspace.

## Enlaces

- [Repositorio](https://github.com/yefersonSegura/omega_architecture)
- [Paquete en pub.dev](https://pub.dev/packages/omega_architecture)
- [Documentación oficial (web)](https://yefersonsegura.com/projects/omega/)

## Licencia

MIT — ver [LICENSE](LICENSE).
