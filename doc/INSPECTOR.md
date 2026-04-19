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

## 3. Inspector en navegador (VM Service + web pública)

En **Android/iOS/desktop (VM)** ya no se levanta un servidor HTTP propio; el Inspector se sirve desde la web pública y se conecta a tu app a través del **Dart VM Service**.

```dart
void main() async {
  final runtime = OmegaRuntime.bootstrap(createOmegaConfig);

  if (kDebugMode && !kIsWeb) {
    await OmegaInspectorServer.start(
      runtime.channel,
      runtime.flowManager,
    );
    // En consola se imprime una URL como:
    //   https://yefersonsegura.github.io/omega_architecture/inspector.html#<VM-URL-encodeada>
    // Ábrela en el navegador del PC; la página se conecta sola.
  }

  runApp(OmegaScope(
    channel: runtime.channel,
    flowManager: runtime.flowManager,
    initialFlowId: runtime.initialFlowId,
    child: MyApp(),
  ));
}
```

- **VM (Android/iOS/desktop):** [OmegaInspectorServer.start] registra una extensión `ext.omega.inspector.getState` en el VM Service y obtiene la `serverUri`. En consola imprime una URL de la forma `https://yefersonsegura.github.io/omega_architecture/inspector.html#<encoded-VM-URL>`. Abre esa URL en el navegador del PC y el inspector online se conectará automáticamente; si prefieres, también puedes pegar la VM Service URL a mano.
- **CLI (`omega inspector`):** Ejecuta `dart run omega_architecture:omega inspector` para abrir `https://yefersonsegura.github.io/omega_architecture/inspector.html` directamente y luego pega el hash o la VM Service URL que imprime la app.
- **Web:** `OmegaInspectorServer.start` no hace nada en web (stub); usa **OmegaInspectorLauncher** para abrir una ventana remota con `OmegaInspectorReceiver`, que ahora comparte el mismo layout general (flows a la izquierda, events + detalles a la derecha).

Para detener (opcional): `OmegaInspectorServer.stop();`

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
5. **Desktop + servidor:** tras `OmegaInspectorServer.start(...)` en la consola sale la URL; ábrela en el navegador del PC.
6. **App en móvil, Inspector en el PC:** usa el flujo por **VM Service** (sin adb reverse). Al ejecutar la app en el dispositivo, en la consola se imprime la URL completa con hash (o la VM Service URL). En el PC abre esa URL o la página hospedada en `docs/public/inspector.html` desplegada en GitHub Pages; pega la VM Service URL si hace falta y pulsa Connect. Flutter ya reenvía el puerto del VM Service al host.
