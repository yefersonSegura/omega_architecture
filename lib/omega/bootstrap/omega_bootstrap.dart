import 'dart:io';

import 'package:flutter/foundation.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    _log("Omega CLI");
    _log("Commands:");
    _log("  omega init");
    _log("  omega create agent <name>");
    _log("  omega create flow <name>");
    return;
  }

  final command = args[0];

  switch (command) {
    case "init":
      OmegaInitCommand.run();
      break;

    case "create":
      OmegaCreateCommand.run(args);
      break;

    default:
      _log("Unknown command");
  }
}

/// Salida de diagnóstico; en release no imprime (evita [avoid_print] en producción).
void _log(String message) {
  debugPrint(message);
}

class OmegaInitCommand {
  static void run() {
    final dir = Directory("lib/omega");

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final file = File("lib/omega/omega_setup.dart");

    file.writeAsStringSync("""
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';

OmegaConfig createOmegaConfig() {
  return OmegaConfig(
    agents: [],
    flows: [],
    routes: [],
  );
}
""");

    _log("Omega setup created at lib/omega/omega_setup.dart");
  }
}

class OmegaCreateCommand {
  static void run(List<String> args) {
    if (args.length < 3) {
      _log("Usage: omega create agent <Name>");
      return;
    }

    final type = args[1];
    final name = args[2];

    switch (type) {
      case "agent":
        _createAgent(name);
        break;

      case "flow":
        _createFlow(name);
        break;
    }
  }

  static void _createAgent(String name) {
    final className = "${name}Agent";
    final file = File("lib/agents/${name.toLowerCase()}_agent.dart");

    file.createSync(recursive: true);

    file.writeAsStringSync("""
import 'package:omega_architecture/omega_architecture.dart';

class $className extends OmegaAgent {

  $className(OmegaChannel channel)
      : super(
          id: "$name",
          channel: channel,
          behavior: ${name}Behavior(),
        );

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) {}
}
""");

    _log("Agent created: ${file.path}");

    _registerAgent(className, name);
  }

  static void _createFlow(String name) {
    final className = "${name}Flow";
    final file = File("lib/flows/${name.toLowerCase()}_flow.dart");

    file.createSync(recursive: true);

    file.writeAsStringSync("""
import 'package:omega_architecture/omega_architecture.dart';

class $className extends OmegaFlow {

  $className(OmegaChannel channel)
      : super(id: "$name", channel: channel);

  @override
  void onIntent(OmegaIntent intent) {}

  @override
  void onEvent(OmegaEvent event) {}
}
""");

    _log("Flow created: ${file.path}");

    _registerFlow(className, name);
  }

  // ------------------------------------------------------
  // REGISTRAR AGENTE AUTOMÁTICAMENTE
  // ------------------------------------------------------

  static void _registerAgent(String className, String name) {
    final setupFile = File("lib/omega/omega_setup.dart");

    if (!setupFile.existsSync()) {
      _log("omega_setup.dart not found. Run omega init first.");
      return;
    }

    String content = setupFile.readAsStringSync();

    // agregar import
    if (!content.contains("agents/${name.toLowerCase()}_agent.dart")) {
      content =
          "import '../agents/${name.toLowerCase()}_agent.dart';\n$content";
    }

    // registrar en agents
    content = content.replaceFirst(
      "agents: [",
      "agents: [\n      $className(),",
    );

    setupFile.writeAsStringSync(content);

    _log("Agent registered in omega_setup.dart");
  }

  // ------------------------------------------------------
  // REGISTRAR FLOW AUTOMÁTICAMENTE
  // ------------------------------------------------------

  static void _registerFlow(String className, String name) {
    final setupFile = File("lib/omega/omega_setup.dart");

    if (!setupFile.existsSync()) {
      _log("omega_setup.dart not found. Run omega init first.");
      return;
    }

    String content = setupFile.readAsStringSync();

    // agregar import
    if (!content.contains("flows/${name.toLowerCase()}_flow.dart")) {
      content = "import '../flows/${name.toLowerCase()}_flow.dart';\n$content";
    }

    // registrar en flows
    content = content.replaceFirst("flows: [", "flows: [\n      $className(),");

    setupFile.writeAsStringSync(content);

    _log("Flow registered in omega_setup.dart");
  }
}
