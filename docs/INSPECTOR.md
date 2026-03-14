# Cómo implementar el Inspector de Omega

El Inspector solo funciona en **modo debug** (`flutter run` sin `--release`). En release no se muestra ni ejecuta.

---

## 1. Overlay (panel en la app)

Panel flotante en una esquina. Siempre visible en debug.

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';

Widget build(BuildContext context) {
  final myContent = Scaffold(
    appBar: AppBar(title: Text('Mi App')),
    body: MyHomePage(),
  );

  if (kDebugMode) {
    return Stack(
      children: [
        myContent,
        Positioned(
          right: 0,
          top: 0,
          child: SafeArea(
            child: OmegaInspector(
              eventLimit: 25,
              initiallyCollapsed: true, // true = solo botón para expandir
            ),
          ),
        ),
      ],
    );
  }
  return myContent;
}
```

- **eventLimit:** número de eventos recientes que se muestran (por defecto 30).
- **initiallyCollapsed:** `true` muestra solo un botón; al pulsar se abre el panel.

---

## 2. Botón en la AppBar (OmegaInspectorLauncher)

Un botón que abre el Inspector en diálogo (desktop/móvil) o en ventana nueva (web).

```dart
AppBar(
  title: Text('Mi App'),
  actions: [
    if (kDebugMode) const OmegaInspectorLauncher(eventLimit: 25),
  ],
)
```

- **Web:** al pulsar se abre una nueva pestaña/ventana con el Inspector (BroadcastChannel).
- **Desktop/móvil:** se abre un `Dialog` con el Inspector dentro.

---

## 3. Servidor en el navegador (desktop/móvil)

En desktop o móvil puedes abrir el Inspector en el navegador (estilo Isar/DevTools). **En web no está disponible** (no hay `dart:io`). Si `openBrowser` es true (por defecto), se usa `url_launcher` para abrir la URL en el navegador del dispositivo (también en móvil).

```dart
void main() {
  final runtime = OmegaRuntime.bootstrap(createOmegaConfig);

  if (kDebugMode) {
    final port = await OmegaInspectorServer.start(
      runtime.channel,
      runtime.flowManager,
      port: 9292,
    );
    if (port != null) {
      // En consola ya se imprime: Omega Inspector: http://localhost:9292
      // Abre esa URL en el navegador.
    }
    // Si port == null (ej. en web), usa OmegaInspectorLauncher.
  }

  runApp(OmegaScope(
    channel: runtime.channel,
    flowManager: runtime.flowManager,
    child: MyApp(),
  ));
}
```

- **Desktop (Windows/macOS/Linux):** El servidor escucha en 127.0.0.1. Si `openBrowser: true` (por defecto), se abre el navegador **de la PC** con `http://127.0.0.1:9292` (url_launcher).
- **Móvil (Android/iOS):** El servidor escucha en todas las interfaces (0.0.0.0) para que la **PC** pueda conectarse. En la **consola de la PC** (donde ejecutaste `flutter run`) se imprime la URL con la IP del dispositivo, por ejemplo: `Omega Inspector (open in your PC browser, same WiFi): http://192.168.1.105:9292`. Abre esa URL en el navegador de tu computadora (teléfono y PC en la misma WiFi). No se abre el navegador del móvil.
- **Web:** `start()` devuelve `null` y en consola sale un mensaje indicando usar `OmegaInspectorLauncher`.

Para detener el servidor (opcional): `OmegaInspectorServer.stop();`

---

## Ejemplo completo (las tres opciones)

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';
// ... tus imports (OmegaRuntime, createOmegaConfig, etc.)

void main() {
  // Ventana separada en web: si la URL tiene ?omega_inspector=1, solo Inspector.
  if (Uri.base.queryParameters['omega_inspector'] == '1') {
    runApp(MaterialApp(
      home: const OmegaInspectorReceiver(),
    ));
    return;
  }

  final runtime = OmegaRuntime.bootstrap(createOmegaConfig);

  if (kDebugMode) {
    OmegaInspectorServer.start(runtime.channel, runtime.flowManager);
  }

  runApp(OmegaScope(
    channel: runtime.channel,
    flowManager: runtime.flowManager,
    initialFlowId: runtime.initialFlowId,
    child: MyApp(navigator: runtime.navigator),
  ));
}

class MyApp extends StatelessWidget {
  final OmegaNavigator navigator;

  const MyApp({super.key, required this.navigator});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigator.navigatorKey,
      home: _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final body = Scaffold(
      appBar: kDebugMode
          ? AppBar(
              title: Text('Mi App'),
              actions: const [OmegaInspectorLauncher()],
            )
          : null,
      body: Center(child: Text('Contenido')),
    );

    if (kDebugMode) {
      return Stack(
        children: [
          body,
          Positioned(
            right: 0,
            top: 0,
            child: SafeArea(
              child: OmegaInspector(eventLimit: 25, initiallyCollapsed: true),
            ),
          ),
        ],
      );
    }
    return body;
  }
}
```

---

## Si el Inspector no sale

1. **Ejecuta en debug:** `flutter run` (no `flutter run --release` ni `--profile`). El Inspector se oculta en release.
2. **Overlay:** si usas el `Stack` con `OmegaInspector`, en la esquina superior derecha debe aparecer un botón (colapsado) o el panel. Pulsa para expandir si está colapsado.
3. **Launcher:** el icono de bicho (bug) en la AppBar solo se muestra en debug. Pulsa para abrir el Inspector en diálogo o ventana nueva.
4. **Web:** el servidor no corre en web; en consola verás el mensaje del stub. Usa el botón de la AppBar (Launcher) para abrir el Inspector en otra ventana.
5. **Desktop/móvil + servidor:** tras `OmegaInspectorServer.start(...)` mira la consola; debe imprimir algo como `Omega Inspector: http://localhost:9292`. Abre esa URL en Chrome/Edge.
