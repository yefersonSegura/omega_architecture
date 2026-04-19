import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'omega/omega_setup.dart';

void main() async {
  // Web: si se abre con ?omega_inspector=1, mostrar solo el receiver en una ventana aparte.
  if (kIsWeb && Uri.base.queryParameters['omega_inspector'] == '1') {
    runApp(
      MaterialApp(
        title: 'Omega Inspector',
        theme: ThemeData(primarySwatch: Colors.orange),
        home: const OmegaInspectorReceiver(),
      ),
    );
    return;
  }

  final runtime = OmegaRuntime.bootstrap(createOmegaConfig);
  // Inspector (solo debug, no web):
  // VM (desktop/móvil) → imprime la URL pública del inspector
  // https://yefersonsegura.github.io/omega_architecture/inspector.html#<VM-URL-encodeada> para abrirlo en el navegador.
  if (kDebugMode && !kIsWeb) {
    await OmegaInspectorServer.start(runtime.channel, runtime.flowManager);
  }

  runApp(
    OmegaScope(
      channel: runtime.channel,
      flowManager: runtime.flowManager,
      initialFlowId: runtime.initialFlowId,
      initialNavigationIntent: runtime.initialNavigationIntent,
      child: MyApp(navigator: runtime.navigator),
    ),
  );
}

class MyApp extends StatelessWidget {
  final OmegaNavigator navigator;

  const MyApp({super.key, required this.navigator});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigator.navigatorKey,
      title: "Omega Example",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OmegaInitialRoute(
        child: const RootHandler(showInspector: true),
      ),
    );
  }
}
