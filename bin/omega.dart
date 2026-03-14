import 'dart:convert';
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

    case "trace":
      OmegaTraceCommand.run(args.length > 1 ? args.sublist(1) : []);
      break;

    case "doctor":
      OmegaDoctorCommand.run(args.length > 1 ? args.sublist(1) : []);
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
  print(
    "  trace [view|validate] [file]  Inspect or validate a recorded trace file (JSON)",
  );
  print(
    "  doctor [path]        Project health (path = start search from, e.g. example or .)",
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
  print("  omega trace view trace.json    # summarize trace file");
  print("  omega trace validate trace.json # validate and exit 0/1");
  print(
    "  omega doctor                   # from app root, or: omega doctor example",
  );
  print("");
  print(
    "  init / validate / doctor: run from app root (where pubspec.yaml is).",
  );
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

/// Builds path with platform separator.
String _path(String dir, List<String> parts) {
  return dir + Platform.pathSeparator + parts.join(Platform.pathSeparator);
}

/// Directory where the bash/terminal was when the command was run (CWD).
String getBashCwd() => Directory.current.path;

/// Returns the package root (folder that contains bin/omega.dart) when running as omega CLI, or null.
String? _packageRootFromScript() {
  try {
    final uri = Platform.script;
    if (!uri.isScheme('file')) return null;
    String p = uri.path;
    if (Platform.isWindows && p.startsWith('/')) p = p.substring(1);
    final scriptFile = File(p);
    if (!scriptFile.existsSync()) return null;
    final binDir = scriptFile.parent.path;
    final parent = Directory(binDir).parent.path;
    final omegaDart = File(_path(binDir, ["omega.dart"]));
    if (omegaDart.existsSync()) return parent;
    return null;
  } catch (_) {
    return null;
  }
}

/// Finds the app root (directory with lib/omega/omega_setup.dart).
/// En un proyecto real no existe la carpeta "example"; la ruta por defecto es la del
/// proyecto que tiene el bash. "example" solo se usa como fallback en el repo del paquete.
///
/// 1) Enlistar primero: directorio del bash (getBashCwd) o [startFrom].
/// 2) Buscar setup desde ahí (omega/ aquí, o subir y subdirs).
/// 3) Fallbacks con example/ solo para el repo omega_architecture.
String findAppRoot([String? startFrom]) {
  final pubspecName = "pubspec.yaml";
  final sep = Platform.pathSeparator;
  final setupParts = ["lib", "omega", "omega_setup.dart"];

  // 1) Ruta por defecto: directorio del bash (proyecto real = donde está el usuario)
  final bashCwd = getBashCwd();
  String startPath = startFrom != null && startFrom.isNotEmpty
      ? Directory(startFrom).absolute.path
      : bashCwd;
  if (startPath.endsWith(sep))
    startPath = startPath.substring(0, startPath.length - 1);

  // 2) Buscar setup: si en este dir está la carpeta omega/ con omega_setup.dart (ej. bash en lib/)
  //    → app root = padre de este dir. Proyecto real: no se usa example.
  final omegaFolderHere = "$startPath${sep}omega${sep}omega_setup.dart";
  if (File(omegaFolderHere).existsSync()) {
    return Directory(startPath).parent.path;
  }

  // 3) Buscar: desde startPath hacia arriba y en subdirs (encuentra lib/omega/omega_setup.dart)
  var dir = Directory(startPath);
  while (true) {
    String dirPath = dir.path;
    if (dirPath.endsWith(sep)) {
      dirPath = dirPath.substring(0, dirPath.length - 1);
    }
    final pubspec = File(_path(dirPath, [pubspecName]));
    final setupFile = File(_path(dirPath, setupParts));
    if (pubspec.existsSync() && setupFile.existsSync()) return dirPath;
    if (pubspec.existsSync()) {
      try {
        for (final e in Directory(dirPath).listSync()) {
          if (e is Directory) {
            final sub = e.path.endsWith(sep)
                ? e.path.substring(0, e.path.length - 1)
                : e.path;
            if (File(_path(sub, [pubspecName])).existsSync() &&
                File(_path(sub, setupParts)).existsSync()) {
              return sub;
            }
            continue;
          }
        }
      } catch (_) {}
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  // Fallback A: raíz del proyecto (findProjectRoot) y sus subdirs. Proyecto real: suele encontrarse aquí.
  final root = findProjectRoot();
  String rootNorm = root.endsWith(sep)
      ? root.substring(0, root.length - 1)
      : root;
  if (File(_path(rootNorm, setupParts)).existsSync()) return rootNorm;
  try {
    for (final e in Directory(rootNorm).listSync()) {
      if (e is Directory) {
        final sub = e.path.endsWith(sep)
            ? e.path.substring(0, e.path.length - 1)
            : e.path;
        if (File(_path(sub, [pubspecName])).existsSync() &&
            File(_path(sub, setupParts)).existsSync()) {
          return sub;
        }
      }
    }
  } catch (_) {}

  // Fallback B: solo repo del paquete — "example" puede no existir en un proyecto real
  final bashDir = getBashCwd();
  String bashNorm = bashDir.endsWith(sep)
      ? bashDir.substring(0, bashDir.length - 1)
      : bashDir;
  final exampleUnderBash = "$bashNorm${sep}example";
  if (File(exampleUnderBash + sep + pubspecName).existsSync() &&
      File(
        "$exampleUnderBash${sep}lib${sep}omega${sep}omega_setup.dart",
      ).existsSync()) {
    return exampleUnderBash;
  }
  final packageRoot = _packageRootFromScript();
  if (packageRoot != null) {
    final examplePath = "$packageRoot${sep}example";
    if (File(_path(examplePath, [pubspecName])).existsSync() &&
        File(_path(examplePath, setupParts)).existsSync()) {
      return examplePath;
    }
  }

  return rootNorm;
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
    // Enlistar primero: directorio del bash (y opcional path)
    final startFrom = args.isNotEmpty && !args[0].startsWith("-")
        ? args[0]
        : null;
    print("Directorio (bash): ${_absPath(getBashCwd())}");
    if (startFrom != null) {
      print("Buscar desde: ${_absPath(Directory(startFrom).absolute.path)}");
    }
    String root;
    try {
      root = findAppRoot(startFrom);
    } catch (_) {
      _err("No Flutter project found.");
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
    final agentReg = RegExp(r"(\w+)Agent\s*\(\s*channel\s*[,\)]");
    final flowReg = RegExp(r"(\w+)Flow\s*\(\s*[^)]*channel[^)]*\)");
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

/// Trace file: JSON with optional [initialSnapshot] and [events] list.
/// Each event: { id, name, payload?, meta? }.
class OmegaTraceCommand {
  static void run(List<String> args) {
    if (args.isEmpty || args[0] == "-h" || args[0] == "--help") {
      _printTraceHelp();
      return;
    }
    final sub = args[0].toLowerCase();
    if (sub == "view") {
      if (args.length < 2) {
        _err("Missing trace file path.");
        print("  Usage: omega trace view <file.json>");
        return;
      }
      _traceView(args[1]);
      return;
    }
    if (sub == "validate") {
      if (args.length < 2) {
        _err("Missing trace file path.");
        print("  Usage: omega trace validate <file.json>");
        exit(1);
      }
      final ok = _traceValidate(args[1]);
      exit(ok ? 0 : 1);
    }
    _err("Unknown trace subcommand: $sub");
    print("  Use: omega trace view <file> | omega trace validate <file>");
  }

  static void _printTraceHelp() {
    print("Usage: omega trace <view|validate> <file.json>");
    print("");
    print(
      "  view <file>     Print summary of a recorded trace (events count, snapshot).",
    );
    print(
      "  validate <file> Check trace file structure; exit 0 if valid, 1 otherwise.",
    );
    print("");
    print(
      "Trace files are produced by saving OmegaRecordedSession.toJson() to disk",
    );
    print(
      "(e.g. from OmegaTimeTravelRecorder.stopRecording() and jsonEncode(session.toJson())).",
    );
  }

  static Map<String, dynamic>? _loadTraceJson(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      _err("File not found: ${_absPath(path)}");
      return null;
    }
    try {
      final content = file.readAsStringSync();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        _err("Trace file must be a JSON object.");
        return null;
      }
      return decoded;
    } catch (e) {
      _err("Invalid JSON: $e");
      return null;
    }
  }

  static bool _isValidTraceStructure(Map<String, dynamic> json) {
    if (!json.containsKey("events")) return false;
    final events = json["events"];
    if (events is! List) return false;
    for (final e in events) {
      if (e is! Map) return false;
      final m = Map<String, dynamic>.from(e);
      if (m["name"] == null) return false;
    }
    if (json.containsKey("initialSnapshot")) {
      final snap = json["initialSnapshot"];
      if (snap != null && snap is! Map) return false;
    }
    return true;
  }

  static void _traceView(String path) {
    final json = _loadTraceJson(path);
    if (json == null) return;
    if (!_isValidTraceStructure(json)) {
      _err(
        "Invalid trace structure (expected 'events' list and optional 'initialSnapshot').",
      );
      return;
    }
    final events = json["events"] as List;
    final hasSnapshot = json["initialSnapshot"] is Map;
    print("Trace: ${_absPath(path)}");
    print("  Events: ${events.length}");
    print("  Initial snapshot: ${hasSnapshot ? "yes" : "no"}");
  }

  static bool _traceValidate(String path) {
    final json = _loadTraceJson(path);
    if (json == null) return false;
    if (!_isValidTraceStructure(json)) {
      _err(
        "Invalid trace structure (expected 'events' list and optional 'initialSnapshot').",
      );
      return false;
    }
    print("Valid trace file.");
    print("  Path: ${_absPath(path)}");
    return true;
  }
}

/// Project health: validate setup + scan flows/agents for contract hints.
class OmegaDoctorCommand {
  static void run(List<String> args) {
    // Enlistar primero: directorio del bash (y opcional path como argumento)
    final startFrom = args.isNotEmpty && !args[0].startsWith("-")
        ? args[0]
        : null;
    final bashCwd = getBashCwd();
    print("Directorio (bash): ${_absPath(bashCwd)}");
    if (startFrom != null)
      print("Buscar desde: ${_absPath(Directory(startFrom).absolute.path)}");
    String root;
    try {
      root = findAppRoot(startFrom);
    } catch (_) {
      _err("No Flutter project found.");
      print("  Run from your app root (where pubspec.yaml is).");
      return;
    }
    var ok = true;
    final setupPath = "$root/lib/omega/omega_setup.dart";
    final setupFile = File(setupPath);
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      print("  Looked at: ${_absPath(setupPath)}");
      print("  Run: omega init");
      return;
    }
    final content = setupFile.readAsStringSync();
    if (!content.contains("createOmegaConfig")) {
      _err("omega_setup.dart must define createOmegaConfig(OmegaChannel).");
      ok = false;
    }
    if (!content.contains("OmegaConfig")) {
      _err("omega_setup.dart must return OmegaConfig.");
      ok = false;
    }
    final agentReg = RegExp(r"(\w+)Agent\s*\(\s*channel\s*[,\)]");
    final flowReg = RegExp(r"(\w+)Flow\s*\(\s*[^)]*channel[^)]*\)");
    final agentIds = agentReg
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();
    final flowIds = flowReg
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();
    final dupAgents = OmegaValidateCommand._duplicates(agentIds);
    final dupFlows = OmegaValidateCommand._duplicates(flowIds);
    if (dupAgents.isNotEmpty) {
      _err("Duplicate agent registration: ${dupAgents.join(", ")}.");
      ok = false;
    }
    if (dupFlows.isNotEmpty) {
      _err("Duplicate flow registration: ${dupFlows.join(", ")}.");
      ok = false;
    }
    print("Omega Doctor");
    print("  Setup: ${_absPath(setupPath)}");
    print("  Agents: ${agentIds.length}, Flows: ${flowIds.length}");
    if (!ok) {
      print("");
      _err("Fix the issues above and run omega doctor again.");
      return;
    }
    // 2) Optional: flows/agents without contract (exclude Behavior files = OmegaAgentBehaviorEngine)
    final libDir = Directory("$root/lib");
    if (libDir.existsSync()) {
      final flowFiles = _findDartFilesContaining(libDir, "extends OmegaFlow");
      final agentFilesRaw = _findDartFilesContaining(
        libDir,
        "extends OmegaAgent",
      );
      final agentFiles = agentFilesRaw.where((p) {
        try {
          return !File(
            p,
          ).readAsStringSync().contains("extends OmegaAgentBehavior");
        } catch (_) {
          return true;
        }
      }).toList();
      final flowsWithoutContract = _filesWithoutContract(
        flowFiles,
        "OmegaFlowContract",
      );
      final agentsWithoutContract = _filesWithoutContract(
        agentFiles,
        "OmegaAgentContract",
      );
      if (flowsWithoutContract.isNotEmpty || agentsWithoutContract.isNotEmpty) {
        print("");
        print("Optional (contracts):");
        for (final p in flowsWithoutContract) {
          print("  Flow without contract: ${_absPath(p)}");
        }
        for (final p in agentsWithoutContract) {
          print("  Agent without contract: ${_absPath(p)}");
        }
        print(
          "  Tip: add a contract getter for clearer semantics and debug warnings.",
        );
      }
    }
    print("");
    print("Health check passed.");
  }

  static List<String> _findDartFilesContaining(
    Directory dir,
    String substring,
  ) {
    final result = <String>[];
    for (final e in dir.listSync(recursive: true)) {
      if (e is File && e.path.endsWith(".dart")) {
        try {
          if (e.readAsStringSync().contains(substring)) {
            result.add(e.path);
          }
        } catch (_) {}
      }
    }
    return result;
  }

  static List<String> _filesWithoutContract(
    List<String> paths,
    String contractType,
  ) {
    final result = <String>[];
    for (final p in paths) {
      try {
        final content = File(p).readAsStringSync();
        if (!content.contains(contractType) && !content.contains("contract")) {
          result.add(p);
        }
      } catch (_) {}
    }
    return result;
  }
}
