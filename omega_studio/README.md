# Omega Studio

Extensión para **Visual Studio Code** y editores compatibles que integra el CLI **Omega** del paquete [`omega_architecture`](https://pub.dev/packages/omega_architecture) en tu flujo de trabajo Flutter: ejecuta comandos desde la paleta, el menú contextual y un canal de salida dedicado, sin salir del IDE.

## Características

- **Proyecto:** validar `omega_setup`, doctor, init, abrir documentación local, abrir inspector.
- **Generación:** ecosistema (`g ecosystem`), agente, flow, crear app Flutter.
- **Trazas:** resumen y validación de traces.
- **IA:** doctor de entorno, explain trace, coach (start, audit, módulo, redesign de UI desde `.dart` / `_page.dart`).
- **Paleta:** comando “Ejecutar comando Omega…” para listar y lanzar acciones rápidamente.

## Requisitos

- Tener el ejecutable **`omega`** en el `PATH` (por ejemplo tras `dart pub global activate omega_architecture`), o usar el proyecto según la guía del paquete.
- Abrir la **carpeta raíz** del proyecto Flutter como workspace.

## Enlaces

- [Repositorio](https://github.com/yefersonSegura/omega_architecture)
- [Paquete en pub.dev](https://pub.dev/packages/omega_architecture)
- [Documentación (web)](https://yefersonsegura.com/projects/omega/index-en.html)

## Licencia

MIT — ver [LICENSE](LICENSE).
