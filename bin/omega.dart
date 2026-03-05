import 'dart:io';

const String _version = "0.0.1";

void main(List<String> args) {
  if (args.isEmpty) {
    printHelp();
    return;
  }

  final arg = args[0];
  if (arg == "-h" || arg == "--help") {
    printHelp();
    return;
  }
  if (arg == "-v" || arg == "--version") {
    print("omega $_version");
    return;
  }

  switch (arg) {
    case "init":
      OmegaInitCommand.run(args.length > 1 ? args.sublist(1) : []);
      break;

    case "g":
    case "generate":
    case "create":
      OmegaGenerateCommand.run(args.length > 1 ? args.sublist(1) : []);
      break;

    default:
      print("Unknown command: $arg");
      print("");
      printHelp();
  }
}

void printHelp() {
  print("");
  print("Ω Omega CLI");
  print("");
  print("Usage: omega <command> [options] [arguments]");
  print("");
  print("Commands:");
  print("  init [--force]     Create lib/omega/omega_setup.dart in your app (use --force to overwrite)");
  print("  g ecosystem <Name>  Generate agent, flow, behavior, page; find omega_setup in your app and add them");
  print("");
  print("Options:");
  print("  -h, --help     Show this help");
  print("  -v, --version  Show version");
  print("");
  print("Examples:");
  print("  omega init");
  print("  omega init --force");
  print("  omega g ecosystem Auth");
  print("  omega generate ecosystem Orders");
  print("");
}

class OmegaInitCommand {
  static void run(List<String> args) {
    final force = args.contains("--force");
    final lib = getLibFolder();
    final omegaDir = Directory("$lib/omega");
    if (!omegaDir.existsSync()) {
      omegaDir.createSync(recursive: true);
    }

    final file = File("$lib/omega/omega_setup.dart");
    if (file.existsSync() && !force) {
      print("omega_setup.dart already exists. Use --force to overwrite.");
      return;
    }

    file.writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_config.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  return OmegaConfig(
    agents: <OmegaAgent>[],
    flows: <OmegaFlow>[],
    routes: [],
  );
}
''');

    _formatFile(file.path);

    print("Omega setup created at ${file.path}");
  }
}

class OmegaGenerateCommand {
  static void run(List<String> args) {
    if (args.isEmpty || args.length < 2) {
      print("Usage: omega g ecosystem <Name>");
      print("");
      print("  ecosystem <Name>  Create agent, flow, behavior and page for ecosystem [Name]");
      return;
    }
    if (args[0] == "-h" || args[0] == "--help") {
      print("Usage: omega g ecosystem <Name>");
      print("");
      print("  ecosystem <Name>  Create agent, flow, behavior and page for ecosystem [Name]");
      return;
    }

    final type = args[0];
    final name = args[1];

    if (type == "ecosystem") {
      _createEcosystem(name);
    } else {
      print("Unknown generator: $type");
      print("Available: ecosystem");
    }
  }

  static void _createEcosystem(String name) {
    final lib = getLibFolder();
    final setupFile = File("$lib/omega/omega_setup.dart");
    if (!setupFile.existsSync()) {
      print("Run 'omega init' first to create omega_setup.dart.");
      return;
    }

    final base = getGenerationBase();
    final ecoPath = "$base/${name.toLowerCase()}";

    Directory(ecoPath).createSync(recursive: true);
    Directory("$ecoPath/ui").createSync(recursive: true);

    final createdFiles = <String>[
      _createAgent(name, ecoPath),
      _createFlow(name, ecoPath),
      _createBehavior(name, ecoPath),
      _createPage(name, ecoPath),
    ];

    registerInOmegaSetup(name, ecoPath);

    for (final path in createdFiles) {
      _formatFile(path);
    }

    print("Ecosystem $name created at $ecoPath");
  }

  static String _createAgent(String name, String base) {
    final pascal = toPascalCase(name);
    final file = File("$base/${name.toLowerCase()}_agent.dart");

    file.writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';
import '${name.toLowerCase()}_behavior.dart';

class ${pascal}Agent extends OmegaAgent {

  ${pascal}Agent(OmegaChannel channel)
      : super(
          id: "$name",
          channel: channel,
          behavior: ${pascal}Behavior(),
        );

  @override
  void onMessage(OmegaAgentMessage msg) {}

  @override
  void onAction(String action, dynamic payload) {}
}
''');
    return file.path;
  }

  static String _createFlow(String name, String base) {
    final pascal = toPascalCase(name);
    final file = File("$base/${name.toLowerCase()}_flow.dart");

    file.writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';

class ${pascal}Flow extends OmegaFlow {

  ${pascal}Flow(OmegaChannel channel)
      : super(id: "$name", channel: channel);

  @override
  void onStart() {
    emitExpression("idle");
  }

  @override
  void onIntent(OmegaFlowContext ctx) {}

  @override
  void onEvent(OmegaFlowContext ctx) {}
}
''');
    return file.path;
  }

  static String _createBehavior(String name, String base) {
    final pascal = toPascalCase(name);
    final file = File("$base/${name.toLowerCase()}_behavior.dart");

    file.writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';

class ${pascal}Behavior extends OmegaAgentBehaviorEngine {

  @override
  OmegaAgentReaction? evaluate(OmegaAgentBehaviorContext ctx) {
    return null;
  }
}
''');
    return file.path;
  }

  static String _createPage(String name, String base) {
    final pascal = toPascalCase(name);
    final file = File("$base/ui/${name.toLowerCase()}_page.dart");

    file.writeAsStringSync('''
import 'package:flutter/material.dart';

class ${pascal}Page extends StatelessWidget {

  const ${pascal}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("$pascal Page")),
      body: const Center(
        child: Text("$pascal Ecosystem"),
      ),
    );
  }
}
''');
    return file.path;
  }
}

void _formatFile(String path) {
  Process.runSync('dart', ['format', path]);
}

void registerInOmegaSetup(String name, String path) {
  final lib = getLibFolder();
  final pkg = getPackageName();
  final setupFile = File("$lib/omega/omega_setup.dart");

  if (!setupFile.existsSync()) {
    print("Run omega init first.");
    return;
  }

  var content = setupFile.readAsStringSync();
  final pascal = toPascalCase(name);

  final relative = path.replaceFirst("$lib/", "");

  final agentImport =
      "import 'package:$pkg/$relative/${name.toLowerCase()}_agent.dart';";
  final flowImport =
      "import 'package:$pkg/$relative/${name.toLowerCase()}_flow.dart';";

  if (!content.contains(agentImport)) {
    content = agentImport + "\n" + content;
  }
  if (!content.contains(flowImport)) {
    content = flowImport + "\n" + content;
  }

  if (!content.contains("${pascal}Agent(channel)")) {
    content = content.replaceFirst(
      "<OmegaAgent>[",
      "<OmegaAgent>[\n      ${pascal}Agent(channel),",
    );
  }
  if (!content.contains("${pascal}Flow(channel)")) {
    content = content.replaceFirst(
      "<OmegaFlow>[",
      "<OmegaFlow>[\n      ${pascal}Flow(channel),",
    );
  }

  setupFile.writeAsStringSync(content);

  print("Registered $pascal (agent, flow) in omega_setup.dart");
}

String toPascalCase(String name) {
  return name
      .split(RegExp(r'(_| )'))
      .map((w) => w.isEmpty ? "" : w[0].toUpperCase() + w.substring(1))
      .join();
}

String findProjectRoot() {
  var dir = Directory.current;

  while (true) {
    final pubspec = File("${dir.path}/pubspec.yaml");

    if (pubspec.existsSync()) {
      return dir.path;
    }

    final parent = dir.parent;

    if (parent.path == dir.path) {
      throw Exception("Flutter project not found.");
    }

    dir = parent;
  }
}

String getLibFolder() {
  final root = findProjectRoot();
  return "$root/lib";
}

String getPackageName() {
  final root = findProjectRoot();
  final pubspec = File("$root/pubspec.yaml");

  final lines = pubspec.readAsLinesSync();

  for (var line in lines) {
    if (line.trim().startsWith("name:")) {
      return line.split(":")[1].trim();
    }
  }

  return "app";
}

String getGenerationBase() {
  final root = findProjectRoot();

  final lib = Directory("$root/lib").absolute.path;
  final current = Directory.current.absolute.path;

  if (current.startsWith(lib)) {
    return current;
  }

  return lib;
}
