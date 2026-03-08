import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omega_architecture/omega/bootstrap/omega_runtime.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'omega/app_semantics.dart';
import 'omega/omega_setup.dart';

void main() {
  // Si se abre con ?omega_inspector=1 (p. ej. desde OmegaInspectorLauncher en web), mostrar solo el receiver.
  if (Uri.base.queryParameters['omega_inspector'] == '1') {
    runApp(MaterialApp(
      title: 'Omega Inspector',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const OmegaInspectorReceiver(),
    ));
    return;
  }
  final runtime = OmegaRuntime.bootstrap(createOmegaConfig);
  runApp(
    OmegaScope(
      channel: runtime.channel,
      flowManager: runtime.flowManager,
      initialFlowId: runtime.initialFlowId,
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
      home: const _RootHandler(),
    );
  }
}

class _RootHandler extends StatefulWidget {
  const _RootHandler();

  @override
  State<_RootHandler> createState() => _RootHandlerState();
}

class _RootHandlerState extends State<_RootHandler> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scope = OmegaScope.of(context);
      // 1) Activar el flow inicial (ej. authFlow)
      if (scope.initialFlowId != null) {
        scope.flowManager.switchTo(scope.initialFlowId!);
      }
      // 2) Navegar a la pantalla de login (nombres tipados: AppIntent / AppEvent)
      final intent = OmegaIntent.fromName(AppIntent.navigateLogin);
      scope.channel.emit(
        OmegaEvent.fromName(AppEvent.navigationIntent, payload: intent),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kDebugMode
          ? AppBar(
              title: const Text('Omega Example'),
              actions: const [OmegaInspectorLauncher()],
            )
          : null,
      body: const Center(child: Text("Omega Running")),
    );
  }
}
