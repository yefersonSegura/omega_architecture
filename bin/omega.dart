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
  print(
    "  init [--force]     Create lib/omega/omega_setup.dart in your app (use --force to overwrite)",
  );
  print(
    "  g ecosystem <Name>  Generate agent, flow, behavior, page in the current directory",
  );
  print("");
  print("Options:");
  print("  -h, --help     Show this help");
  print("  -v, --version  Show version");
  print("");
  print("Examples:");
  print("  omega init");
  print("  omega init --force");
  print("  omega g ecosystem Auth   # creates auth/ in the folder where you run this");
  print("  omega generate ecosystem Orders");
  print("");
  print("  init: run from your app root (where pubspec.yaml is).");
  print("  g ecosystem: run from the folder where you want the ecosystem (e.g. lib/features).");
  print("");
}

class OmegaInitCommand {
  static void run(List<String> args) {
    final force = args.contains("--force");
    final cwd = Directory.current.absolute.path;
    String root;
    try {
      root = findProjectRoot();
    } catch (_) {
      print("No Flutter project found. Current directory: $cwd");
      print(
        "Open the terminal in your app root (where pubspec.yaml is), then run: omega init",
      );
      return;
    }
    final lib = "$root/lib";
    final omegaDir = Directory("$lib/omega");
    if (!omegaDir.existsSync()) {
      omegaDir.createSync(recursive: true);
    }

    final file = File("$lib/omega/omega_setup.dart");
    if (file.existsSync() && !force) {
      print("omega_setup.dart already exists at ${file.absolute.path}");
      print("Use --force to overwrite.");
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

    print("Project root: $root");
    print("Omega setup created at ${file.absolute.path}");
  }
}

class OmegaGenerateCommand {
  static void run(List<String> args) {
    if (args.isEmpty || args.length < 2) {
      print("Usage: omega g ecosystem <Name>");
      print("");
      print(
        "  ecosystem <Name>  Create agent, flow, behavior and page for ecosystem [Name]",
      );
      return;
    }
    if (args[0] == "-h" || args[0] == "--help") {
      print("Usage: omega g ecosystem <Name>");
      print("");
      print(
        "  ecosystem <Name>  Create agent, flow, behavior and page for ecosystem [Name]",
      );
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
    final cwd = Directory.current.absolute.path;
    String root;
    try {
      root = findProjectRoot();
    } catch (_) {
      print("No Flutter project found. Current directory: $cwd");
      print(
        "Open the terminal in your app root (where pubspec.yaml is) and run:",
      );
      print("  omega init");
      print("  omega g ecosystem $name");
      return;
    }

    final lib = "$root/lib";
    final setupFile = File("$lib/omega/omega_setup.dart");
    if (!setupFile.existsSync()) {
      print("omega_setup.dart not found.");
      print("  Looked at: ${setupFile.absolute.path}");
      print("  Current directory: $cwd");
      print("");
      print("Run from your app root (where pubspec.yaml is), then:");
      print("  omega init");
      print("  omega g ecosystem $name");
      return;
    }

    // Crear siempre en el directorio donde abriste la terminal (CWD)
    final base = cwd;
    final ecoPath = "$base/${name.toLowerCase()}";

    print("Creating in current directory: $base");
    print("Ecosystem path: $ecoPath");

    Directory(ecoPath).createSync(recursive: true);
    Directory("$ecoPath/ui").createSync(recursive: true);

    final createdFiles = <String>[
      _createAgent(name, ecoPath),
      _createFlow(name, ecoPath),
      _createBehavior(name, ecoPath),
      _createPage(name, ecoPath),
    ];

    registerInOmegaSetup(name, ecoPath, root);

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

/// Normaliza path para comparación (unificado y sin trailing separator).
String _normPath(String path) {
  final p = Directory(path).absolute.path.replaceAll("/", Platform.pathSeparator);
  return p.endsWith(Platform.pathSeparator) ? p.substring(0, p.length - 1) : p;
}

/// Ruta relativa desde [fromDir] hasta [toPath] para usar en imports (siempre con /).
String _relativePath(String fromDir, String toPath) {
  final sep = Platform.pathSeparator;
  final from = _normPath(fromDir).split(sep);
  final to = _normPath(toPath).split(sep);
  if (to.isEmpty || (to.length == 1 && to[0].isEmpty)) return ".";
  int i = 0;
  while (i < from.length && i < to.length && from[i].toLowerCase() == to[i].toLowerCase()) i++;
  final up = from.length - i;
  final rest = to.sublist(i);
  final parts = <String>[
    for (var j = 0; j < up; j++) "..",
    ...rest,
  ];
  return parts.join("/");
}

void registerInOmegaSetup(String name, String path, String projectRoot) {
  final lib = "$projectRoot/lib";
  final libNorm = _normPath(lib);
  final pathNorm = _normPath(path);
  final pkg = getPackageName(projectRoot);
  final setupFile = File("$lib/omega/omega_setup.dart");
  final setupDir = _normPath("$lib/omega");

  if (!setupFile.existsSync()) {
    print("Run omega init first. Looked at: ${setupFile.absolute.path}");
    return;
  }

  var content = setupFile.readAsStringSync();
  final pascal = toPascalCase(name);
  final nameLower = name.toLowerCase();
  final agentPath = "$pathNorm/${nameLower}_agent.dart";
  final flowPath = "$pathNorm/${nameLower}_flow.dart";

  final String agentImport;
  final String flowImport;
  if (pathNorm.toLowerCase().startsWith(libNorm.toLowerCase())) {
    var relative = pathNorm
        .substring(libNorm.length)
        .replaceAll(Platform.pathSeparator, "/")
        .replaceFirst(RegExp(r"^[/\\]"), "");
    if (relative.endsWith("/")) relative = relative.substring(0, relative.length - 1);
    agentImport = "import 'package:$pkg/$relative/${nameLower}_agent.dart';";
    flowImport = "import 'package:$pkg/$relative/${nameLower}_flow.dart';";
  } else {
    agentImport = "import '${_relativePath(setupDir, agentPath)}';";
    flowImport = "import '${_relativePath(setupDir, flowPath)}';";
  }

  // Refrescar path: quitar imports viejos de este ecosistema y poner los nuevos
  final agentFile = nameLower + "_agent.dart";
  final flowFile = nameLower + "_flow.dart";
  final agentPattern = RegExp("import\\s+['\"].*" + RegExp.escape(agentFile) + "['\"];\\s*");
  final flowPattern = RegExp("import\\s+['\"].*" + RegExp.escape(flowFile) + "['\"];\\s*");
  content = content.replaceFirst(agentPattern, "");
  content = content.replaceFirst(flowPattern, "");
  content = agentImport + "\n" + flowImport + "\n" + content;

  if (!content.contains("${pascal}Agent(channel)")) {
    content = content.replaceFirst(
      "<OmegaAgent>[",
      "<OmegaAgent>[\n      ${pascal}Agent(channel),",
    );
  }

  // Asegurar que exista flows en OmegaConfig y registrar el Flow
  if (!content.contains("flows:") || !content.contains("<OmegaFlow>")) {
    // omega_setup sin flows: añadir flows: <OmegaFlow>[XFlow(channel)] antes del cierre );
    content = content.replaceFirst(
      "]);",
      "],\n    flows: <OmegaFlow>[\n      ${pascal}Flow(channel),]\n  );",
    );
  } else if (!content.contains("${pascal}Flow(channel)")) {
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

String getPackageName([String? projectRoot]) {
  final root = projectRoot ?? findProjectRoot();
  final pubspec = File("$root/pubspec.yaml");

  final lines = pubspec.readAsLinesSync();

  for (var line in lines) {
    if (line.trim().startsWith("name:")) {
      return line.split(":")[1].trim();
    }
  }

  return "app";
}

