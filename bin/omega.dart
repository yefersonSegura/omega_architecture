import 'dart:io';

const String _version = "0.0.1";
const String _docUrl = "http://yefersonsegura.com/proyects/omega/";

void _openInBrowser(String urlOrPath) {
  if (Platform.isWindows) {
    Process.run("start", [urlOrPath], runInShell: true);
  } else if (Platform.isMacOS) {
    Process.run("open", [urlOrPath]);
  } else {
    Process.run("xdg-open", [urlOrPath]);
  }
}

void _openDoc() {
  _openInBrowser(_docUrl);
  print("Opening documentation: $_docUrl");
}

void _err(String message) {
  print("Error: $message");
}

String _absPath(String path) {
  return File(path).absolute.path;
}

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
    case "doc":
      _openDoc();
      return;

    case "init":
      OmegaInitCommand.run(args.length > 1 ? args.sublist(1) : []);
      break;

    case "g":
    case "generate":
    case "create":
      OmegaGenerateCommand.run(args.length > 1 ? args.sublist(1) : []);
      break;

    case "validate":
      OmegaValidateCommand.run(args.length > 1 ? args.sublist(1) : []);
      break;

    default:
      _err("Unknown command: $arg");
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
    "  doc                  Open the web documentation (official site in browser)",
  );
  print(
    "  init [--force]       Create lib/omega/omega_setup.dart (use --force to overwrite)",
  );
  print(
    "  g ecosystem <Name>    Generate agent, flow, behavior and page in the current directory",
  );
  print(
    "  g agent <Name>       Generate only agent + behavior in current directory",
  );
  print("  g flow <Name>        Generate only flow in current directory");
  print(
    "  validate             Check omega_setup.dart (structure, duplicate ids)",
  );
  print("");
  print("Options:");
  print("  -h, --help     Show this help");
  print("  -v, --version  Show version");
  print("");
  print("Examples:");
  print("  omega doc                 # open web documentation");
  print("  omega init");
  print("  omega init --force");
  print(
    "  omega g ecosystem Auth    # auth_agent, auth_flow, auth_behavior, auth_page",
  );
  print("  omega g agent Orders      # orders_agent, orders_behavior only");
  print("  omega g flow Orders       # orders_flow only");
  print("  omega validate");
  print("");
  print("  init / validate: run from app root (where pubspec.yaml is).");
  print(
    "  g ecosystem / agent / flow: run from the folder where you want the files.",
  );
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
      _err("No Flutter project found.");
      print("  Current directory: ${_absPath(cwd)}");
      print(
        "  Run from your app root (where pubspec.yaml is), then: omega init",
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
      _err("omega_setup.dart already exists.");
      print("  Path: ${_absPath(file.path)}");
      print("  Use --force to overwrite.");
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

    print("Omega setup created.");
    print("  Project root: ${_absPath(root)}");
    print("  File: ${_absPath(file.path)}");
  }
}

class OmegaGenerateCommand {
  static void run(List<String> args) {
    if (args.isEmpty) {
      _err("Missing generator and name.");
      print("  Usage: omega g <ecosystem|agent|flow> <Name>");
      return;
    }
    if (args.length < 2 && args[0] != "-h" && args[0] != "--help") {
      _err("Missing name for generator '${args[0]}'.");
      print("  Usage: omega g ${args[0]} <Name>");
      return;
    }
    if (args[0] == "-h" || args[0] == "--help") {
      print("Usage: omega g <ecosystem|agent|flow> <Name>");
      print("");
      print("  ecosystem <Name>  Agent, flow, behavior and page");
      print("  agent <Name>      Agent + behavior only");
      print("  flow <Name>      Flow only");
      return;
    }

    final type = args[0];
    final name = args[1];

    switch (type) {
      case "ecosystem":
        _createEcosystem(name);
        break;
      case "agent":
        _createAgentOnly(name);
        break;
      case "flow":
        _createFlowOnly(name);
        break;
      default:
        _err("Unknown generator: $type");
        print("  Available: ecosystem, agent, flow");
    }
  }

  static void _createEcosystem(String name) {
    // Crear en la ruta donde está abierta la terminal (CWD)
    final baseDir = Directory.current.absolute.path;
    String root;
    try {
      root = findProjectRoot();
    } catch (_) {
      _err("No Flutter project found.");
      print("  Current directory: ${_absPath(baseDir)}");
      print("  Run from your app root, then: omega init");
      return;
    }

    final lib = "$root/lib";
    final setupFile = File("$lib/omega/omega_setup.dart");
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      print("  Looked at: ${_absPath(setupFile.path)}");
      print("  Current directory: ${_absPath(baseDir)}");
      print("  Run from app root: omega init");
      return;
    }

    final ecoPath = "$baseDir/${name.toLowerCase()}";

    print("Creating in current directory: ${_absPath(baseDir)}");
    print("Ecosystem path: ${_absPath(ecoPath)}");

    Directory(ecoPath).createSync(recursive: true);
    Directory("$ecoPath/ui").createSync(recursive: true);

    final createdFiles = <String>[
      _createAgent(name, ecoPath),
      _createFlow(name, ecoPath),
      _createBehavior(name, ecoPath),
      _createPage(name, ecoPath),
    ];

    registerInOmegaSetup(
      name,
      ecoPath,
      root,
      registerAgent: true,
      registerFlow: true,
    );

    for (final path in createdFiles) {
      _formatFile(path);
    }

    print("Ecosystem $name created.");
    print("  Path: ${_absPath(ecoPath)}");
  }

  static void _createAgentOnly(String name) {
    // Crear en la ruta donde está abierta la terminal (CWD)
    final baseDir = Directory.current.absolute.path;
    String root;
    try {
      root = findProjectRoot();
    } catch (_) {
      _err("No Flutter project found.");
      print("  Current directory: ${_absPath(baseDir)}");
      print("  Run from your app root, then: omega init");
      return;
    }
    final setupFile = File("$root/lib/omega/omega_setup.dart");
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      print("  Looked at: ${_absPath(setupFile.path)}");
      print("  Run from app root: omega init");
      return;
    }
    final ecoPath = "$baseDir/${name.toLowerCase()}";
    print("Creating in current directory: ${_absPath(baseDir)}");
    Directory(ecoPath).createSync(recursive: true);
    final created = <String>[
      _createAgent(name, ecoPath),
      _createBehavior(name, ecoPath),
    ];
    registerInOmegaSetup(
      name,
      ecoPath,
      root,
      registerAgent: true,
      registerFlow: false,
    );
    for (final p in created) {
      _formatFile(p);
    }
    print("Agent $name created.");
    print("  Path: ${_absPath(ecoPath)}");
  }

  static void _createFlowOnly(String name) {
    // Crear en la ruta donde está abierta la terminal (CWD)
    final baseDir = Directory.current.absolute.path;
    String root;
    try {
      root = findProjectRoot();
    } catch (_) {
      _err("No Flutter project found.");
      print("  Current directory: ${_absPath(baseDir)}");
      print("  Run from your app root, then: omega init");
      return;
    }
    final setupFile = File("$root/lib/omega/omega_setup.dart");
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      print("  Looked at: ${_absPath(setupFile.path)}");
      print("  Run from app root: omega init");
      return;
    }
    final ecoPath = "$baseDir/${name.toLowerCase()}";
    print("Creating in current directory: ${_absPath(baseDir)}");
    Directory(ecoPath).createSync(recursive: true);
    final path = _createFlow(name, ecoPath);
    registerInOmegaSetup(
      name,
      ecoPath,
      root,
      registerAgent: false,
      registerFlow: true,
    );
    _formatFile(path);
    print("Flow $name created.");
    print("  Path: ${_absPath(ecoPath)}");
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
  final p = Directory(
    path,
  ).absolute.path.replaceAll("/", Platform.pathSeparator);
  return p.endsWith(Platform.pathSeparator) ? p.substring(0, p.length - 1) : p;
}

/// Ruta relativa desde [fromDir] hasta [toPath] para usar en imports (siempre con /).
String _relativePath(String fromDir, String toPath) {
  final sep = Platform.pathSeparator;
  final from = _normPath(fromDir).split(sep);
  final to = _normPath(toPath).split(sep);
  if (to.isEmpty || (to.length == 1 && to[0].isEmpty)) return ".";
  int i = 0;
  while (i < from.length &&
      i < to.length &&
      from[i].toLowerCase() == to[i].toLowerCase()) {
    i++;
  }
  final up = from.length - i;
  final rest = to.sublist(i);
  final parts = <String>[for (var j = 0; j < up; j++) "..", ...rest];
  return parts.join("/");
}

void registerInOmegaSetup(
  String name,
  String path,
  String projectRoot, {
  bool registerAgent = true,
  bool registerFlow = true,
}) {
  final lib = "$projectRoot/lib";
  final libNorm = _normPath(lib);
  final pathNorm = _normPath(path);
  final pkg = getPackageName(projectRoot);
  final setupFile = File("$lib/omega/omega_setup.dart");
  final setupDir = _normPath("$lib/omega");

  if (!setupFile.existsSync()) {
    _err("omega_setup.dart not found.");
    print("  Looked at: ${_absPath(setupFile.path)}");
    print("  Run from app root: omega init");
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
    if (relative.endsWith("/")) {
      relative = relative.substring(0, relative.length - 1);
    }
    agentImport = "import 'package:$pkg/$relative/${nameLower}_agent.dart';";
    flowImport = "import 'package:$pkg/$relative/${nameLower}_flow.dart';";
  } else {
    agentImport = "import '${_relativePath(setupDir, agentPath)}';";
    flowImport = "import '${_relativePath(setupDir, flowPath)}';";
  }

  final agentFile = nameLower + "_agent.dart";
  final flowFile = nameLower + "_flow.dart";
  final agentPattern = RegExp(
    "import\\s+['\"].*" + RegExp.escape(agentFile) + "['\"];\\s*",
  );
  final flowPattern = RegExp(
    "import\\s+['\"].*" + RegExp.escape(flowFile) + "['\"];\\s*",
  );
  // Solo quitar el import del artefacto que estamos registrando (no el del otro)
  if (registerAgent) content = content.replaceFirst(agentPattern, "");
  if (registerFlow) content = content.replaceFirst(flowPattern, "");

  final newImports = <String>[];
  if (registerAgent) newImports.add(agentImport);
  if (registerFlow) newImports.add(flowImport);
  if (newImports.isNotEmpty) {
    content = newImports.join("\n") + "\n" + content;
  }

  if (registerAgent && !content.contains("${pascal}Agent(channel)")) {
    content = content.replaceFirst(
      "<OmegaAgent>[",
      "<OmegaAgent>[\n      ${pascal}Agent(channel),",
    );
  }

  if (registerFlow) {
    if (!content.contains("flows:") || !content.contains("<OmegaFlow>")) {
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
  }

  setupFile.writeAsStringSync(content);

  final what = [
    if (registerAgent) "agent",
    if (registerFlow) "flow",
  ].join(", ");
  print("Registered $pascal ($what) in omega_setup.dart");
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

class OmegaValidateCommand {
  static void run(List<String> args) {
    String root;
    try {
      root = findProjectRoot();
    } catch (_) {
      _err("No Flutter project found.");
      print("  Current directory: ${_absPath(Directory.current.path)}");
      print("  Run from your app root (where pubspec.yaml is).");
      return;
    }

    final setupPath = "$root/lib/omega/omega_setup.dart";
    final setupFile = File(setupPath);
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      print("  Looked at: ${_absPath(setupPath)}");
      print("  Run: omega init");
      return;
    }

    final content = setupFile.readAsStringSync();
    var ok = true;

    if (!content.contains("createOmegaConfig")) {
      _err("omega_setup.dart must define createOmegaConfig(OmegaChannel).");
      print("  File: ${_absPath(setupPath)}");
      ok = false;
    }
    if (!content.contains("OmegaConfig")) {
      _err("omega_setup.dart must return OmegaConfig.");
      ok = false;
    }
    if (!content.contains("agents:")) {
      _err("OmegaConfig should have agents: list.");
      ok = false;
    }

    // Duplicate ids: find all XAgent(channel) and XFlow(channel)
    final agentReg = RegExp(r"(\w+)Agent\s*\(\s*channel\s*\)");
    final flowReg = RegExp(r"(\w+)Flow\s*\(\s*channel\s*\)");
    final agentMatches = agentReg.allMatches(content);
    final flowMatches = flowReg.allMatches(content);
    final agentNames = <String>[];
    final flowNames = <String>[];
    for (final m in agentMatches) {
      agentNames.add(m.group(1)!);
    }
    for (final m in flowMatches) {
      flowNames.add(m.group(1)!);
    }
    final duplicateAgents = _duplicates(agentNames);
    final duplicateFlows = _duplicates(flowNames);
    if (duplicateAgents.isNotEmpty) {
      _err("Duplicate agent registration: ${duplicateAgents.join(", ")}.");
      print("  Remove duplicate XAgent(channel) from omega_setup.dart.");
      ok = false;
    }
    if (duplicateFlows.isNotEmpty) {
      _err("Duplicate flow registration: ${duplicateFlows.join(", ")}.");
      print("  Remove duplicate XFlow(channel) from omega_setup.dart.");
      ok = false;
    }

    if (ok) {
      print("Valid.");
      print("  File: ${_absPath(setupPath)}");
      print("  Agents: ${agentNames.length}, Flows: ${flowNames.length}");
    }
  }

  static List<String> _duplicates(List<String> list) {
    final seen = <String>{};
    final dupes = <String>{};
    for (final x in list) {
      if (seen.contains(x)) {
        dupes.add(x);
      } else {
        seen.add(x);
      }
    }
    return dupes.toList()..sort();
  }
}
