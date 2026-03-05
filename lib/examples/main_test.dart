import 'package:flutter/material.dart';
import 'package:omega_architecture/omega/bootstrap/omega_runtime.dart';
import 'package:omega_architecture/omega/omega_setup.dart';
import 'package:omega_architecture/omega_architecture.dart';

void main() {
  final runtime = OmegaRuntime.bootstrap(createOmegaConfig(OmegaChannel()));
  runApp(
    OmegaScope(
      channel: runtime.channel,
      flowManager: runtime.flowManager,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Omega Example",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(body: Center(child: Text("Omega Running"))),
    );
  }
}
