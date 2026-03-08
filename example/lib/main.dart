import 'package:flutter/material.dart';
import 'package:omega_architecture/omega/bootstrap/omega_runtime.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'omega/omega_setup.dart';

void main() {
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
      if (scope.initialFlowId != null) {
        scope.flowManager.switchTo(scope.initialFlowId!);
      }
      final intent = OmegaIntent(id: "goLogin", name: "navigate.login");
      scope.channel.emit(
        OmegaEvent(
          id: "nav:${DateTime.now().millisecondsSinceEpoch}",
          name: "navigation.intent",
          payload: intent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Omega Running")));
  }
}
