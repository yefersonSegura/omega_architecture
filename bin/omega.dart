import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String _version = "0.0.25";
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
  stdout.writeln("Opening documentation: $_docUrl");
}

void _err(String message) {
  stdout.writeln("Error: $message");
}

String _absPath(String path) {
  return File(path).absolute.path;
}

Future<void> main(List<String> args) async {
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
    stdout.writeln("omega $_version");
    return;
  }

  switch (arg) {
    case "inspector":
      OmegaInspectorCommand.run();
      return;

    case "doc":
      _openDoc();
      return;

    case "init":
      OmegaInitCommand.run(args.length > 1 ? args.sublist(1) : []);
      break;

    case "g":
    case "generate":
    case "create":
      if (args.length > 1 && args[1] == "app") {
        await OmegaCreateAppCommand.run(args.length > 2 ? args.sublist(2) : []);
        return;
      }
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

    case "ai":
      await OmegaAiCommand.run(args.length > 1 ? args.sublist(1) : []);
      return;

    default:
      _err("Unknown command: $arg");
      stdout.writeln("");
      printHelp();
  }
}

void printHelp() {
  stdout.writeln("");
  stdout.writeln("Ω Omega CLI");
  stdout.writeln("");
  stdout.writeln("Usage: omega <command> [options] [arguments]");
  stdout.writeln("");
  stdout.writeln("Commands:");
  stdout.writeln(
    "  doc                  Open the web documentation (official site in browser)",
  );
  stdout.writeln(
    "  create app <Name>    Create a new Flutter project with Omega pre-configured",
  );
  stdout.writeln(
    "  inspector            Open the local Omega Inspector HTML (desktop/mobile VM Service)",
  );
  stdout.writeln(
    "  init [--force]       Create lib/omega/omega_setup.dart (use --force to overwrite)",
  );
  stdout.writeln(
    "  g ecosystem <Name>    Generate agent, flow, behavior and page in the current directory",
  );
  stdout.writeln(
    "  g agent <Name>       Generate only agent + behavior in current directory",
  );
  stdout.writeln(
    "  g flow <Name>        Generate only flow in current directory",
  );
  stdout.writeln(
    "  validate             Check omega_setup.dart (structure, duplicate ids)",
  );
  stdout.writeln(
    "  trace [view|validate] [file]  Inspect or validate a recorded trace file (JSON)",
  );
  stdout.writeln(
    "  doctor [path]        Project health (path = start search from, e.g. example or .)",
  );
  stdout.writeln(
    "  ai <doctor|env|explain>  AI setup and offline trace explanation",
  );
  stdout.writeln("");
  stdout.writeln("Options:");
  stdout.writeln("  -h, --help     Show this help");
  stdout.writeln("  -v, --version  Show version");
  stdout.writeln("");
  stdout.writeln("Examples:");
  stdout.writeln("  omega doc                 # open web documentation");
  stdout.writeln(
    "  omega inspector           # open local inspector.html in browser",
  );
  stdout.writeln("  omega init");
  stdout.writeln(
    "  omega create app my_new_app --kickstart \"login, profile and settings\"",
  );
  stdout.writeln("  omega init --force");
  stdout.writeln(
    "  omega g ecosystem Auth    # auth_agent, auth_flow, auth_behavior, auth_page",
  );
  stdout.writeln(
    "  omega g agent Orders      # orders_agent, orders_behavior only",
  );
  stdout.writeln("  omega g flow Orders       # orders_flow only");
  stdout.writeln("  omega validate");
  stdout.writeln("  omega trace view trace.json    # summarize trace file");
  stdout.writeln("  omega trace validate trace.json # validate and exit 0/1");
  stdout.writeln(
    "  omega doctor                   # from app root, or: omega doctor example",
  );
  stdout.writeln(
    "  omega ai doctor                # check AI provider/api key setup",
  );
  stdout.writeln("  omega ai env                   # print env variable names");
  stdout.writeln(
    "  omega ai explain trace.json    # offline explanation from trace",
  );
  stdout.writeln(
    "  omega ai explain trace.json --provider-api   # try OpenAI then fallback",
  );
  stdout.writeln("");
  stdout.writeln(
    "  init / validate / doctor: run from app root (where pubspec.yaml is).",
  );
  stdout.writeln(
    "  g ecosystem / agent / flow: run from the folder where you want the files.",
  );
  stdout.writeln("");
}

class OmegaCreateAppCommand {
  static Future<void> run(List<String> args) async {
    if (args.isEmpty || args[0] == "-h" || args[0] == "--help") {
      stdout.writeln(
        'Usage: omega create app <name> [--kickstart "description"] [--provider-api]',
      );
      return;
    }

    final appName = args[0];
    final kickstart = OmegaAiCommand._optionValue(args, "--kickstart");
    final useProviderApi = args.contains("--provider-api");

    stdout.writeln(
      "🚀 ${_tr(en: "Creating new Omega app: $appName", es: "Creando nueva Omega app: $appName")}...",
    );

    // 1. Flutter Create
    final createRes = await runWithProgress<ProcessResult>(
      _tr(en: "Running flutter create", es: "Ejecutando flutter create"),
      () => Process.run("flutter", ["create", appName], runInShell: true),
    );

    if (createRes.exitCode != 0) {
      _err(
        "${_tr(en: "Failed to create Flutter project", es: "Fallo al crear el proyecto de Flutter")}: ${createRes.stderr}",
      );
      return;
    }

    final projectRoot = Directory(
      "${Directory.current.path}${Platform.pathSeparator}$appName",
    ).absolute.path;

    // 2. Add omega_architecture
    await runWithProgress<ProcessResult>(
      _tr(
        en: "Adding omega_architecture dependency",
        es: "Agregando dependencia omega_architecture",
      ),
      () => Process.run(
        "dart",
        ["pub", "add", "omega_architecture"],
        workingDirectory: projectRoot,
        runInShell: true,
      ),
    );

    // 3. Omega Init
    final originalCwd = Directory.current.path;
    Directory.current = projectRoot;
    try {
      stdout.writeln(
        "🛠️ ${_tr(en: "Initializing Omega architecture", es: "Inicializando arquitectura Omega")}...",
      );
      OmegaInitCommand.run([]);

      // 4. Setup modules with AI if requested
      String? firstModule;
      if (kickstart != null) {
        stdout.writeln(
          "🤖 ${_tr(en: "Kickstarting with AI: $kickstart", es: "Iniciando con IA: $kickstart")}...",
        );

        final modules = await runWithProgress<List<String>>(
          _tr(
            en: "Analyzing architecture needs",
            es: "Analizando necesidades de arquitectura",
          ),
          () async {
            if (useProviderApi) {
              final aiModules = await _providerSuggestModules(kickstart);
              if (aiModules != null) return aiModules;
            }
            return ["Home"]; // Fallback
          },
        );

        if (modules.isNotEmpty) {
          firstModule = modules.first;
        }

        for (final module in modules) {
          stdout.writeln(
            "🏗️ ${_tr(en: "Generating module: $module", es: "Generando modulo: $module")}...",
          );
          await OmegaAiCommand._coachModule(
            feature: module,
            template: "advanced",
            asJson: false,
            useProviderApi: useProviderApi,
            toTempFile: false,
          );
        }
      }

      // 5. Setup clean main.dart
      _setupCleanMain(projectRoot, appName, initialModule: firstModule);

      // 6. Setup clean widget_test.dart
      _setupCleanTest(projectRoot, appName);
    } finally {
      Directory.current = originalCwd;
    }

    stdout.writeln("\n✨ ${_tr(en: "App ready!", es: "App lista!")}");
    stdout.writeln("  cd $appName");
    stdout.writeln("  flutter run");
  }

  static void _setupCleanMain(
    String root,
    String appName, {
    String? initialModule,
  }) {
    final mainFile = File(
      "$root${Platform.pathSeparator}lib${Platform.pathSeparator}main.dart",
    );
    final initialFlowId = initialModule != null ? "'$initialModule'" : "null";
    mainFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_runtime.dart';
import 'omega/omega_setup.dart';

void main() {
  final runtime = OmegaRuntime.bootstrap(createOmegaConfig);
  runApp(
    OmegaScope(
      channel: runtime.channel,
      flowManager: runtime.flowManager,
      initialFlowId: $initialFlowId,
      child: OmegaApp(navigator: runtime.navigator),
    ),
  );
}

class OmegaApp extends StatelessWidget {
  final OmegaNavigator navigator;
  const OmegaApp({super.key, required this.navigator});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$appName',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorKey: navigator.navigatorKey,
      onGenerateRoute: navigator.onGenerateRoute,
    );
  }
}
''');
    _formatFile(mainFile.path);
  }

  static void _setupCleanTest(String root, String appName) {
    final testDir = Directory("$root${Platform.pathSeparator}test");
    if (!testDir.existsSync()) {
      testDir.createSync(recursive: true);
    }
    final testFile =
        File("${testDir.path}${Platform.pathSeparator}widget_test.dart");

    testFile.writeAsStringSync('''
import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'package:omega_architecture/omega/bootstrap/omega_runtime.dart';
import 'package:$appName/main.dart';
import 'package:$appName/omega/omega_setup.dart';

void main() {
  testWidgets('Omega smoke test', (WidgetTester tester) async {
    // This is a minimal smoke test for a project generated by Omega.
    // It boots the runtime and verifies the app can be pumped.
    final runtime = OmegaRuntime.bootstrap(createOmegaConfig);
    
    await tester.pumpWidget(
      OmegaScope(
        channel: runtime.channel,
        flowManager: runtime.flowManager,
        child: OmegaApp(navigator: runtime.navigator),
      ),
    );

    expect(find.byType(OmegaApp), findsOneWidget);
  });
}
''');
    _formatFile(testFile.path);
  }

  static Future<List<String>?> _providerSuggestModules(
    String description,
  ) async {
    final env = Platform.environment;
    if (env["OMEGA_AI_ENABLED"] != "true") return null;
    final provider = env["OMEGA_AI_PROVIDER"];
    if (provider != "openai") return null;
    final apiKey = env["OMEGA_AI_API_KEY"];
    if (apiKey == null || apiKey.isEmpty) return null;

    final model = env["OMEGA_AI_MODEL"] ?? "gpt-4o-mini";
    final baseUrl = env["OMEGA_AI_BASE_URL"] ?? "https://api.openai.com/v1";
    final endpoint =
        "${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions";

    final requestBody = {
      "model": model,
      "temperature": 0.3,
      "messages": [
        {
          "role": "system",
          "content":
              "You are Omega architecture planner. Return ONLY a comma-separated list of 2-4 core module names (PascalCase) needed for the app description. No extra text.",
        },
        {"role": "user", "content": "Description: $description"},
      ],
    };

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $apiKey");
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.write(jsonEncode(requestBody));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(body);
      final content = decoded["choices"][0]["message"]["content"].toString();
      return content
          .split(",")
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }
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
      stdout.writeln("  Current directory: ${_absPath(cwd)}");
      stdout.writeln(
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
      stdout.writeln("  Path: ${_absPath(file.path)}");
      stdout.writeln("  Use --force to overwrite.");
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

    stdout.writeln("Omega setup created.");
    stdout.writeln("  Project root: ${_absPath(root)}");
    stdout.writeln("  File: ${_absPath(file.path)}");
  }
}

class OmegaGenerateCommand {
  static void run(List<String> args) {
    if (args.isEmpty) {
      _err("Missing generator and name.");
      stdout.writeln("  Usage: omega g <ecosystem|agent|flow> <Name>");
      return;
    }
    if (args.length < 2 && args[0] != "-h" && args[0] != "--help") {
      _err("Missing name for generator '${args[0]}'.");
      stdout.writeln("  Usage: omega g ${args[0]} <Name>");
      return;
    }
    if (args[0] == "-h" || args[0] == "--help") {
      stdout.writeln("Usage: omega g <ecosystem|agent|flow> <Name>");
      stdout.writeln("");
      stdout.writeln("  ecosystem <Name>  Agent, flow, behavior and page");
      stdout.writeln("  agent <Name>      Agent + behavior only");
      stdout.writeln("  flow <Name>      Flow only");
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
        stdout.writeln("  Available: ecosystem, agent, flow");
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
      stdout.writeln("  Current directory: ${_absPath(baseDir)}");
      stdout.writeln("  Run from your app root, then: omega init");
      return;
    }

    final lib = "$root/lib";
    final setupFile = File("$lib/omega/omega_setup.dart");
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      stdout.writeln("  Looked at: ${_absPath(setupFile.path)}");
      stdout.writeln("  Current directory: ${_absPath(baseDir)}");
      stdout.writeln("  Run from app root: omega init");
      return;
    }

    final ecoPath = "$baseDir/${name.toLowerCase()}";

    stdout.writeln("Creating in current directory: ${_absPath(baseDir)}");
    stdout.writeln("Ecosystem path: ${_absPath(ecoPath)}");

    Directory(ecoPath).createSync(recursive: true);
    Directory("$ecoPath/ui").createSync(recursive: true);

    final createdFiles = <String>[
      _createAgent(name, ecoPath),
      _createFlow(name, ecoPath),
      _createBehavior(name, ecoPath),
      _createPage(name, ecoPath),
      _createEvents(name, ecoPath),
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

    stdout.writeln("Ecosystem $name created.");
    stdout.writeln("  Path: ${_absPath(ecoPath)}");
  }

  static void _createAgentOnly(String name) {
    // Crear en la ruta donde está abierta la terminal (CWD)
    final baseDir = Directory.current.absolute.path;
    String root;
    try {
      root = findProjectRoot();
    } catch (_) {
      _err("No Flutter project found.");
      stdout.writeln("  Current directory: ${_absPath(baseDir)}");
      stdout.writeln("  Run from your app root, then: omega init");
      return;
    }
    final setupFile = File("$root/lib/omega/omega_setup.dart");
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      stdout.writeln("  Looked at: ${_absPath(setupFile.path)}");
      stdout.writeln("  Run from app root: omega init");
      return;
    }
    final ecoPath = "$baseDir/${name.toLowerCase()}";
    stdout.writeln("Creating in current directory: ${_absPath(baseDir)}");
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
    stdout.writeln("Agent $name created.");
    stdout.writeln("  Path: ${_absPath(ecoPath)}");
  }

  static void _createFlowOnly(String name) {
    // Crear en la ruta donde está abierta la terminal (CWD)
    final baseDir = Directory.current.absolute.path;
    String root;
    try {
      root = findProjectRoot();
    } catch (_) {
      _err("No Flutter project found.");
      stdout.writeln("  Current directory: ${_absPath(baseDir)}");
      stdout.writeln("  Run from your app root, then: omega init");
      return;
    }
    final setupFile = File("$root/lib/omega/omega_setup.dart");
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      stdout.writeln("  Looked at: ${_absPath(setupFile.path)}");
      stdout.writeln("  Run from app root: omega init");
      return;
    }
    final ecoPath = "$baseDir/${name.toLowerCase()}";
    stdout.writeln("Creating in current directory: ${_absPath(baseDir)}");
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
    stdout.writeln("Flow $name created.");
    stdout.writeln("  Path: ${_absPath(ecoPath)}");
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

  static String _createEvents(String name, String base) {
    final pascal = toPascalCase(name);
    final file = File("$base/${name.toLowerCase()}_events.dart");

    file.writeAsStringSync('''
/// Eventos e intents del ecosistema $pascal.
/// Define aquí tus enums/clases que implementen OmegaEventName / OmegaIntentName
/// o tus eventos tipados (OmegaTypedEvent).
''');
    return file.path;
  }
}

void _formatFile(String path) {
  Process.runSync('dart', ['format', path]);
}

/// Open the online Omega Inspector (VM Service) in the default browser.
/// It uses the hosted page at http://yefersonsegura.com/projects/omega/inspector.html.
class OmegaInspectorCommand {
  static void run() {
    const url = "http://yefersonsegura.com/projects/omega/inspector.html";
    _openInBrowser(url);
    stdout.writeln("Opening Omega Inspector (online):");
    stdout.writeln("  $url");
    stdout.writeln("");
    stdout.writeln("Tip:");
    stdout.writeln(
      "  When running on a device, OmegaInspectorServer will print the same URL with a #<encoded-VM-URL> hash.",
    );
    stdout.writeln(
      "  You can either open that full URL directly, or paste the VM Service URL manually in the page.",
    );
  }
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
    stdout.writeln("  Looked at: ${_absPath(setupFile.path)}");
    stdout.writeln("  Run from app root: omega init");
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

  final agentFile = "${nameLower}_agent.dart";
  final flowFile = "${nameLower}_flow.dart";
  final agentPattern = RegExp(
    "import\\s+['\"].*${RegExp.escape(agentFile)}['\"];\\s*",
  );
  final flowPattern = RegExp(
    "import\\s+['\"].*${RegExp.escape(flowFile)}['\"];\\s*",
  );
  // Solo quitar el import del artefacto que estamos registrando (no el del otro)
  if (registerAgent) content = content.replaceFirst(agentPattern, "");
  if (registerFlow) content = content.replaceFirst(flowPattern, "");

  final newImports = <String>[];
  if (registerAgent) newImports.add(agentImport);
  if (registerFlow) newImports.add(flowImport);
  if (newImports.isNotEmpty) {
    content = '${newImports.join("\n")}\n$content';
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
  stdout.writeln("Registered $pascal ($what) in omega_setup.dart");
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
  if (startPath.endsWith(sep)) {
    startPath = startPath.substring(0, startPath.length - 1);
  }

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
    stdout.writeln("Directorio (bash): ${_absPath(getBashCwd())}");
    if (startFrom != null) {
      stdout.writeln(
        "Buscar desde: ${_absPath(Directory(startFrom).absolute.path)}",
      );
    }
    String root;
    try {
      root = findAppRoot(startFrom);
    } catch (_) {
      _err("No Flutter project found.");
      stdout.writeln("  Run from your app root (where pubspec.yaml is).");
      return;
    }

    final setupPath = "$root/lib/omega/omega_setup.dart";
    final setupFile = File(setupPath);
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      stdout.writeln("  Looked at: ${_absPath(setupPath)}");
      stdout.writeln("  Run: omega init");
      return;
    }

    final content = setupFile.readAsStringSync();
    var ok = true;

    if (!content.contains("createOmegaConfig")) {
      _err("omega_setup.dart must define createOmegaConfig(OmegaChannel).");
      stdout.writeln("  File: ${_absPath(setupPath)}");
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
      stdout.writeln(
        "  Remove duplicate XAgent(channel) from omega_setup.dart.",
      );
      ok = false;
    }
    if (duplicateFlows.isNotEmpty) {
      _err("Duplicate flow registration: ${duplicateFlows.join(", ")}.");
      stdout.writeln(
        "  Remove duplicate XFlow(channel) from omega_setup.dart.",
      );
      ok = false;
    }

    if (ok) {
      stdout.writeln("Valid.");
      stdout.writeln("  File: ${_absPath(setupPath)}");
      stdout.writeln(
        "  Agents: ${agentNames.length}, Flows: ${flowNames.length}",
      );
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
        stdout.writeln("  Usage: omega trace view <file.json>");
        return;
      }
      _traceView(args[1]);
      return;
    }
    if (sub == "validate") {
      if (args.length < 2) {
        _err("Missing trace file path.");
        stdout.writeln("  Usage: omega trace validate <file.json>");
        exit(1);
      }
      final ok = _traceValidate(args[1]);
      exit(ok ? 0 : 1);
    }
    _err("Unknown trace subcommand: $sub");
    stdout.writeln(
      "  Use: omega trace view <file> | omega trace validate <file>",
    );
  }

  static void _printTraceHelp() {
    stdout.writeln("Usage: omega trace <view|validate> <file.json>");
    stdout.writeln("");
    stdout.writeln(
      "  view <file>     Print summary of a recorded trace (events count, snapshot).",
    );
    stdout.writeln(
      "  validate <file> Check trace file structure; exit 0 if valid, 1 otherwise.",
    );
    stdout.writeln("");
    stdout.writeln(
      "Trace files are produced by saving OmegaRecordedSession.toJson() to disk",
    );
    stdout.writeln(
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
    stdout.writeln("Trace: ${_absPath(path)}");
    stdout.writeln("  Events: ${events.length}");
    stdout.writeln("  Initial snapshot: ${hasSnapshot ? "yes" : "no"}");
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
    stdout.writeln("Valid trace file.");
    stdout.writeln("  Path: ${_absPath(path)}");
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
    stdout.writeln("Directorio (bash): ${_absPath(bashCwd)}");
    if (startFrom != null) {
      stdout.writeln(
        "Buscar desde: ${_absPath(Directory(startFrom).absolute.path)}",
      );
    }
    String root;
    try {
      root = findAppRoot(startFrom);
    } catch (_) {
      _err("No Flutter project found.");
      stdout.writeln("  Run from your app root (where pubspec.yaml is).");
      return;
    }
    var ok = true;
    final setupPath = "$root/lib/omega/omega_setup.dart";
    final setupFile = File(setupPath);
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      stdout.writeln("  Looked at: ${_absPath(setupPath)}");
      stdout.writeln("  Run: omega init");
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
    stdout.writeln("Omega Doctor");
    stdout.writeln("  Setup: ${_absPath(setupPath)}");
    stdout.writeln("  Agents: ${agentIds.length}, Flows: ${flowIds.length}");
    if (!ok) {
      stdout.writeln("");
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
        stdout.writeln("");
        stdout.writeln("Optional (contracts):");
        for (final p in flowsWithoutContract) {
          stdout.writeln("  Flow without contract: ${_absPath(p)}");
        }
        for (final p in agentsWithoutContract) {
          stdout.writeln("  Agent without contract: ${_absPath(p)}");
        }
        stdout.writeln(
          "  Tip: add a contract getter for clearer semantics and debug warnings.",
        );
      }
    }
    stdout.writeln("");
    stdout.writeln("Health check passed.");
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

/// AI tooling bootstrap (no provider call yet).
/// Helps users configure environment variables in a safe, optional way.
class OmegaAiCommand {
  static Future<void> run(List<String> args) async {
    if (args.isEmpty || args[0] == "-h" || args[0] == "--help") {
      _printHelp();
      return;
    }

    final sub = args[0].toLowerCase();
    switch (sub) {
      case "doctor":
        _doctor();
        return;
      case "env":
        _env();
        return;
      case "explain":
        final explainArgs = args.sublist(1);
        final asJson = explainArgs.contains("--json");
        final useProviderApi = explainArgs.contains("--provider-api");
        final toTempFile = !explainArgs.contains("--stdout");
        final path = explainArgs.firstWhere(
          (a) => !a.startsWith("-"),
          orElse: () => "",
        );
        if (path.isEmpty) {
          _err("Missing trace file path.");
          stdout.writeln(
            "  Usage: omega ai explain <file.json> [--json] [--provider-api] [--stdout]",
          );
          return;
        }
        await _explain(
          path,
          asJson: asJson,
          useProviderApi: useProviderApi,
          toTempFile: toTempFile,
        );
        return;
      case "coach":
        await _coach(args.sublist(1));
        return;
      default:
        _err("Unknown ai subcommand: $sub");
        stdout.writeln(
          "  Use: omega ai doctor | omega ai env | omega ai explain <file> [--json] [--provider-api] [--stdout] | omega ai coach start \"<feature>\" [--json] [--provider-api] [--stdout]",
        );
    }
  }

  static void _printHelp() {
    stdout.writeln("Usage: omega ai <doctor|env|explain|coach>");
    stdout.writeln("");
    stdout.writeln(
      "  doctor   Check AI env setup (enabled/provider/model/base-url/key).",
    );
    stdout.writeln(
      "  env      Print supported AI env variable names and examples.",
    );
    stdout.writeln(
      "  explain  Explain a trace file using offline heuristics (no API cost).",
    );
    stdout.writeln("           Add --json for machine-readable output.");
    stdout.writeln(
      "           Add --provider-api to use configured OpenAI API.",
    );
    stdout.writeln(
      "           Writes to a temp file by default; add --stdout to print in console.",
    );
    stdout.writeln(
      "  coach    Guided coding assistant. First mode: coach start \"<feature>\".",
    );
    stdout.writeln("           Audit mode: coach audit \"<feature>\".");
    stdout.writeln("");
  }

  static void _doctor() {
    final env = Platform.environment;
    final enabled = _readBool(env["OMEGA_AI_ENABLED"], defaultValue: false);
    final provider = (env["OMEGA_AI_PROVIDER"] ?? "none").trim();
    final model = (env["OMEGA_AI_MODEL"] ?? "not-set").trim();
    final baseUrl = (env["OMEGA_AI_BASE_URL"] ?? "default-provider-url").trim();
    final key = env["OMEGA_AI_API_KEY"];

    final needsKey = provider != "none" && provider != "ollama";
    final hasKey = key != null && key.trim().isNotEmpty;

    stdout.writeln("Omega AI Doctor");
    stdout.writeln("  Enabled : $enabled");
    stdout.writeln("  Provider: $provider");
    stdout.writeln("  Model   : $model");
    stdout.writeln("  Base URL: $baseUrl");
    stdout.writeln("  API key : ${hasKey ? "configured" : "missing"}");
    stdout.writeln("");

    if (!enabled) {
      stdout.writeln("AI is disabled (default-safe mode).");
      stdout.writeln("Set OMEGA_AI_ENABLED=true to enable AI CLI commands.");
      return;
    }

    if (provider == "none") {
      _err("OMEGA_AI_PROVIDER is not set.");
      stdout.writeln("  Suggested: openai | anthropic | gemini | ollama");
      return;
    }

    if (needsKey && !hasKey) {
      _err("Provider '$provider' usually requires OMEGA_AI_API_KEY.");
      stdout.writeln("  Set your key and run: omega ai doctor");
      return;
    }

    stdout.writeln("AI base configuration looks good.");
    stdout.writeln(
      "Next step: wire a provider adapter in CLI commands (explain/suggest/gen).",
    );
  }

  static void _env() {
    stdout.writeln("Omega AI environment variables");
    stdout.writeln("");
    stdout.writeln("  OMEGA_AI_ENABLED   true|false (default: false)");
    stdout.writeln(
      "  OMEGA_AI_PROVIDER  openai | anthropic | gemini | ollama | none",
    );
    stdout.writeln(
      "  OMEGA_AI_API_KEY   provider API key (optional for ollama)",
    );
    stdout.writeln("  OMEGA_AI_MODEL     model id (provider specific)");
    stdout.writeln("  OMEGA_AI_BASE_URL  custom endpoint (optional)");
    stdout.writeln("");
    stdout.writeln("PowerShell example:");
    stdout.writeln('  setx OMEGA_AI_ENABLED "true"');
    stdout.writeln('  setx OMEGA_AI_PROVIDER "openai"');
    stdout.writeln('  setx OMEGA_AI_API_KEY "sk-..."');
    stdout.writeln('  setx OMEGA_AI_MODEL "gpt-4o-mini"');
    stdout.writeln("");
  }

  static Future<void> _explain(
    String path, {
    bool asJson = false,
    bool useProviderApi = false,
    bool toTempFile = false,
  }) async {
    final json = OmegaTraceCommand._loadTraceJson(path);
    if (json == null) return;
    if (!OmegaTraceCommand._isValidTraceStructure(json)) {
      _err(
        "Invalid trace structure (expected 'events' list and optional 'initialSnapshot').",
      );
      return;
    }

    final events = (json["events"] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (events.isEmpty) {
      final noEvents = _tr(
        en: "No events found.",
        es: "No se encontraron eventos.",
        pt: "Nenhum evento encontrado.",
        fr: "Aucun evenement trouve.",
        it: "Nessun evento trovato.",
        de: "Keine Ereignisse gefunden.",
      );
      if (asJson) {
        _emitAiOutput(
          content: jsonEncode({
            "trace": _absPath(path),
            "events": 0,
            "status": "empty",
            "diagnosis": [noEvents],
            "mode": "offline",
          }),
          toTempFile: toTempFile,
          kind: "explain",
          extension: "json",
        );
      } else {
        _emitAiOutput(
          content: _formatExplainMarkdown(
            mode: "offline",
            tracePath: _absPath(path),
            eventsCount: 0,
            firstEvent: "-",
            lastEvent: "-",
            top: const <MapEntry<String, int>>[],
            nsEntries: const <MapEntry<String, int>>[],
            diagnosis: [noEvents],
          ),
          toTempFile: toTempFile,
          kind: "explain",
          extension: "md",
        );
      }
      return;
    }

    final firstName = (events.first["name"] ?? "unknown").toString();
    final lastName = (events.last["name"] ?? "unknown").toString();
    final byName = <String, int>{};
    final byNamespace = <String, int>{};
    final suspicious = <Map<String, dynamic>>[];

    for (final e in events) {
      final name = (e["name"] ?? "unknown").toString();
      byName[name] = (byName[name] ?? 0) + 1;

      final namespace = (e["namespace"] ?? "global").toString();
      byNamespace[namespace] = (byNamespace[namespace] ?? 0) + 1;

      final lower = name.toLowerCase();
      if (lower.contains("error") ||
          lower.contains("fail") ||
          lower.contains("exception") ||
          lower.contains("timeout")) {
        suspicious.add(e);
      }
    }

    final topEvents = byName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = topEvents.take(3).toList();
    final repeated = top.where((x) => x.value >= 5).toList();
    final diagnosis = <String>[];

    final nsEntries = byNamespace.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (suspicious.isNotEmpty) {
      final sName = (suspicious.first["name"] ?? "unknown").toString();
      diagnosis.add(
        _tr(
          en: "Detected suspicious event(s) like '$sName' (error/fail/exception).",
          es: "Se detectaron eventos sospechosos como '$sName' (error/fail/exception).",
          pt: "Eventos suspeitos detectados como '$sName' (error/fail/exception).",
          fr: "Evenements suspects detectes comme '$sName' (error/fail/exception).",
          it: "Eventi sospetti rilevati come '$sName' (error/fail/exception).",
          de: "Verdaechtige Ereignisse erkannt wie '$sName' (error/fail/exception).",
        ),
      );
      diagnosis.add(
        _tr(
          en: "Review the first suspicious event and previous 3 events in timeline.",
          es: "Revisa el primer evento sospechoso y los 3 eventos anteriores en la linea de tiempo.",
          pt: "Revise o primeiro evento suspeito e os 3 eventos anteriores na linha do tempo.",
          fr: "Examinez le premier evenement suspect et les 3 evenements precedents dans la chronologie.",
          it: "Rivedi il primo evento sospetto e i 3 eventi precedenti nella timeline.",
          de: "Pruefe das erste verdaechtige Ereignis und die 3 vorherigen Ereignisse in der Timeline.",
        ),
      );
    } else if (repeated.isNotEmpty) {
      diagnosis.add(
        _tr(
          en: "Repeated events may indicate a loop/retry without stop condition.",
          es: "Eventos repetidos pueden indicar un ciclo/reintento sin condicion de salida.",
          pt: "Eventos repetidos podem indicar loop/repeticao sem condicao de parada.",
          fr: "Des evenements repetes peuvent indiquer une boucle/reessai sans condition d'arret.",
          it: "Eventi ripetuti possono indicare un ciclo/tentativo senza condizione di uscita.",
          de: "Wiederholte Ereignisse koennen auf eine Schleife/Wiederholung ohne Abbruchbedingung hinweisen.",
        ),
      );
      diagnosis.add(
        _tr(
          en: "Check guards in flow/agent for: ${repeated.map((x) => x.key).join(", ")}.",
          es: "Revisa las guardas en flow/agent para: ${repeated.map((x) => x.key).join(", ")}.",
          pt: "Verifique os guards em flow/agent para: ${repeated.map((x) => x.key).join(", ")}.",
          fr: "Verifiez les gardes dans flow/agent pour: ${repeated.map((x) => x.key).join(", ")}.",
          it: "Controlla le guardie in flow/agent per: ${repeated.map((x) => x.key).join(", ")}.",
          de: "Pruefe Guards in flow/agent fuer: ${repeated.map((x) => x.key).join(", ")}.",
        ),
      );
    } else {
      diagnosis.add(
        _tr(
          en: "No explicit error pattern detected; flow appears structurally healthy.",
          es: "No se detecto un patron de error explicito; el flow parece estructuralmente sano.",
          pt: "Nenhum padrao explicito de erro detectado; o flow parece estruturalmente saudavel.",
          fr: "Aucun schema d'erreur explicite detecte; le flow semble structurellement sain.",
          it: "Nessun pattern di errore esplicito rilevato; il flow sembra strutturalmente sano.",
          de: "Kein explizites Fehlermuster erkannt; der Flow wirkt strukturell stabil.",
        ),
      );
      diagnosis.add(
        _tr(
          en: "If behavior is wrong, validate contracts and business invariants.",
          es: "Si el comportamiento es incorrecto, valida contratos e invariantes de negocio.",
          pt: "Se o comportamento estiver errado, valide contratos e invariantes de negocio.",
          fr: "Si le comportement est incorrect, validez les contrats et invariants metier.",
          it: "Se il comportamento e errato, valida contratti e invarianti di business.",
          de: "Wenn das Verhalten falsch ist, pruefe Vertraege und Geschaeftsinvarianten.",
        ),
      );
    }

    var mode = "offline";
    if (useProviderApi) {
      final aiDiagnosis = await _runWithProgress<List<String>?>(
        _tr(
          en: "Consulting AI provider",
          es: "Consultando proveedor IA",
          pt: "Consultando provedor IA",
          fr: "Consultation du fournisseur IA",
          it: "Consultazione provider IA",
          de: "KI-Anbieter wird abgefragt",
        ),
        () => _providerExplain(events),
      );
      if (aiDiagnosis != null && aiDiagnosis.isNotEmpty) {
        diagnosis
          ..clear()
          ..addAll(aiDiagnosis);
        mode = "provider-api";
      }
    }

    if (asJson) {
      _emitAiOutput(
        content: jsonEncode({
          "trace": _absPath(path),
          "events": events.length,
          "firstEvent": firstName,
          "lastEvent": lastName,
          "topEvents": [
            for (final item in top) {"name": item.key, "count": item.value},
          ],
          "namespaces": [
            for (final item in nsEntries)
              {"name": item.key, "count": item.value},
          ],
          "diagnosis": diagnosis,
          "mode": mode,
        }),
        toTempFile: toTempFile,
        kind: "explain",
        extension: "json",
      );
      return;
    }

    final output = _formatExplainMarkdown(
      mode: mode,
      tracePath: _absPath(path),
      eventsCount: events.length,
      firstEvent: firstName,
      lastEvent: lastName,
      top: top,
      nsEntries: nsEntries,
      diagnosis: diagnosis,
    );
    _emitAiOutput(
      content: output,
      toTempFile: toTempFile,
      kind: "explain",
      extension: "md",
    );
  }

  static Future<void> _coach(List<String> args) async {
    if (args.isEmpty || args[0] == "-h" || args[0] == "--help") {
      stdout.writeln(
        'Usage: omega ai coach <start|audit|module> "<feature>" [--json] [--provider-api] [--stdout] [--template basic|advanced]',
      );
      stdout.writeln("");
      stdout.writeln(
        "  start   ${_tr(en: "Build a guided implementation plan for a feature.", es: "Construye un plan guiado de implementacion para una feature.", pt: "Cria um plano guiado de implementacao para uma feature.", fr: "Construit un plan guide d'implementation pour une fonctionnalite.", it: "Costruisce un piano guidato di implementazione per una feature.", de: "Erstellt einen gefuehrten Implementierungsplan fuer ein Feature.")}",
      );
      stdout.writeln(
        "  audit   ${_tr(en: "Audit current project gaps for a feature.", es: "Audita brechas actuales del proyecto para una feature.")}",
      );
      stdout.writeln(
        "  module  ${_tr(en: "Create a complete ecosystem module (AI-guided).", es: "Crea un modulo de ecosistema completo (guiado por IA).")}",
      );
      stdout.writeln(
        "          ${_tr(en: "Use --template advanced for workflow/stateful/contracts/tests scaffold.", es: "Usa --template advanced para scaffold con workflow/stateful/contratos/tests.")}",
      );
      return;
    }

    final action = args[0].toLowerCase();
    if (action != "start" && action != "audit" && action != "module") {
      _err("Unknown coach action: $action");
      stdout.writeln(
        "  Use: omega ai coach <start|audit|module> \"<feature>\" [--json] [--provider-api] [--stdout]",
      );
      return;
    }

    final rest = args.sublist(1);
    final asJson = rest.contains("--json");
    final useProviderApi = rest.contains("--provider-api");
    final toTempFile = !rest.contains("--stdout");
    final template = (_optionValue(rest, "--template") ?? "basic")
        .trim()
        .toLowerCase();
    if (template != "basic" && template != "advanced") {
      _err("Invalid template: $template");
      stdout.writeln("  Allowed: basic, advanced");
      return;
    }
    final feature = _collectPositionalArgs(
      rest,
      optionsWithValue: const ["--template"],
    ).join(" ").trim();
    if (feature.isEmpty) {
      _err(
        _tr(
          en: "Missing feature description.",
          es: "Falta la descripcion de la feature.",
          pt: "Falta a descricao da feature.",
          fr: "Description de fonctionnalite manquante.",
          it: "Descrizione della feature mancante.",
          de: "Feature-Beschreibung fehlt.",
        ),
      );
      stdout.writeln("  ${_tr(en: "Example", es: "Ejemplo")}:");
      stdout.writeln('  omega ai coach start "login con MFA"');
      stdout.writeln('  omega ai coach audit "login con MFA"');
      stdout.writeln('  omega ai coach module "login con MFA"');
      return;
    }

    if (action == "audit") {
      await _coachAudit(
        feature: feature,
        asJson: asJson,
        useProviderApi: useProviderApi,
        toTempFile: toTempFile,
      );
      return;
    }

    if (action == "module") {
      await _coachModule(
        feature: feature,
        template: template,
        asJson: asJson,
        useProviderApi: useProviderApi,
        toTempFile: toTempFile,
      );
      return;
    }

    final artifacts = _coachRequiredArtifacts(feature);
    final checks = _coachValidationChecks();
    final steps = _offlineCoachPlan(feature);
    final insights = <String>[];
    var mode = "offline";
    if (useProviderApi) {
      final providerSteps = await _runWithProgress<List<String>?>(
        _tr(
          en: "Consulting AI provider",
          es: "Consultando proveedor IA",
          pt: "Consultando provedor IA",
          fr: "Consultation du fournisseur IA",
          it: "Consultazione provider IA",
          de: "KI-Anbieter wird abgefragt",
        ),
        () => _providerCoachPlan(feature),
      );
      if (providerSteps != null && providerSteps.isNotEmpty) {
        insights.addAll(providerSteps);
        mode = "provider-api";
      }
    }

    if (asJson) {
      _emitAiOutput(
        content: jsonEncode({
          "mode": mode,
          "feature": feature,
          "coach": "start",
          "requiredArtifacts": artifacts,
          "steps": steps,
          "validationChecks": checks,
          "insights": insights,
        }),
        toTempFile: toTempFile,
        kind: "coach",
        extension: "json",
      );
      return;
    }

    final output = _formatCoachMarkdown(
      mode: mode,
      feature: feature,
      requiredArtifacts: artifacts,
      steps: steps,
      validationChecks: checks,
      insights: insights,
      nextCommand:
          "omega g ecosystem ${toPascalCase(feature.split(" ").first)}",
    );
    _emitAiOutput(
      content: output,
      toTempFile: toTempFile,
      kind: "coach",
      extension: "md",
    );
  }

  static List<String> _offlineCoachPlan(String feature) {
    return [
      _tr(
        en: "Define semantic intents/events for '$feature' (typed names or typed event classes).",
        es: "Define intents/eventos semanticos para '$feature' (nombres tipados o clases de evento tipado).",
      ),
      _tr(
        en: "Model the journey in a Flow (or OmegaWorkflowFlow if multi-step) with explicit expressions.",
        es: "Modela el journey en un Flow (u OmegaWorkflowFlow si es multi-paso) con expresiones explicitas.",
      ),
      _tr(
        en: "Create/reuse Agent + behavior rules for side effects, retries, and async boundaries.",
        es: "Crea/reutiliza Agent + reglas de behavior para efectos secundarios, reintentos y limites async.",
      ),
      _tr(
        en: "Wire routes/flow/agent in omega_setup.dart and keep UI constrained to intents + reactive state.",
        es: "Registra rutas/flow/agent en omega_setup.dart y limita la UI a intents + estado reactivo.",
      ),
      _tr(
        en: "Define flow/agent contracts to lock accepted intents/events and emitted expressions.",
        es: "Define contratos de flow/agent para fijar intents/eventos aceptados y expresiones emitidas.",
      ),
      _tr(
        en: "Create tests: happy path, failure path, and replay trace for regression.",
        es: "Crea pruebas: happy path, failure path y replay de traza para regresion.",
      ),
      _tr(
        en: "Run architecture checks: validate + doctor + ai explain on captured traces.",
        es: "Ejecuta validaciones de arquitectura: validate + doctor + ai explain sobre trazas capturadas.",
      ),
      _tr(
        en: "Document decisions: event naming, payload schema, invariants, and rollout plan.",
        es: "Documenta decisiones: naming de eventos, esquema de payload, invariantes y plan de despliegue.",
      ),
    ];
  }

  static List<String> _coachRequiredArtifacts(String feature) {
    final slug = feature.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "_");
    return [
      "Flow: ${slug}_flow.dart (or omega_workflow_flow usage)",
      "Agent: ${slug}_agent.dart + behavior",
      "Semantics: ${slug}_events.dart (intents/events, typed payloads)",
      "UI entry: ${slug}_page.dart (emit intents only)",
      "Setup wiring: omega_setup.dart (imports, routes, registrations)",
      "Contracts: OmegaFlowContract + OmegaAgentContract",
      "Tests: flow/agent + trace replay fixture",
      "Observability: trace export + ai explain report",
    ];
  }

  static List<String> _coachValidationChecks() {
    return [
      "dart run omega_architecture:omega validate",
      "dart run omega_architecture:omega doctor",
      "dart run omega_architecture:omega ai explain <trace.json> --json",
      "flutter test",
    ];
  }

  static void _applyAdvancedModuleTemplate({
    required String appRoot,
    required String modulePath,
    required String moduleName,
    Map<String, String>? customCode,
  }) {
    final lower = moduleName.toLowerCase();
    final agentPath = "$modulePath${Platform.pathSeparator}${lower}_agent.dart";
    final behaviorPath =
        "$modulePath${Platform.pathSeparator}${lower}_behavior.dart";
    final eventsPath =
        "$modulePath${Platform.pathSeparator}${lower}_events.dart";
    final flowPath = "$modulePath${Platform.pathSeparator}${lower}_flow.dart";
    final pagePath =
        "$modulePath${Platform.pathSeparator}ui${Platform.pathSeparator}${lower}_page.dart";
    final testPath =
        "$appRoot${Platform.pathSeparator}test${Platform.pathSeparator}${lower}_module_test.dart";

    if (customCode != null) {
      if (customCode.containsKey("events")) {
        File(eventsPath).writeAsStringSync(customCode["events"]!);
      }
      if (customCode.containsKey("behavior")) {
        File(behaviorPath).writeAsStringSync(customCode["behavior"]!);
      }
      if (customCode.containsKey("agent")) {
        File(agentPath).writeAsStringSync(customCode["agent"]!);
      }
      if (customCode.containsKey("flow")) {
        File(flowPath).writeAsStringSync(customCode["flow"]!);
      }
      if (customCode.containsKey("page")) {
        File(pagePath).writeAsStringSync(customCode["page"]!);
      }
    } else {
      // Default advanced template (already exists below)
      _writeDefaultAdvancedTemplate(
        moduleName: moduleName,
        lower: lower,
        eventsPath: eventsPath,
        behaviorPath: behaviorPath,
        agentPath: agentPath,
        flowPath: flowPath,
        pagePath: pagePath,
      );
    }

    final testDir = Directory("$appRoot${Platform.pathSeparator}test");
    if (!testDir.existsSync()) {
      testDir.createSync(recursive: true);
    }
    File(testPath).writeAsStringSync('''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('${moduleName} module scaffold compiles', () {
    expect(true, isTrue);
  });
}
''');

    for (final p in [
      eventsPath,
      behaviorPath,
      agentPath,
      flowPath,
      pagePath,
      testPath,
    ]) {
      _formatFile(p);
    }
  }

  static void _writeDefaultAdvancedTemplate({
    required String moduleName,
    required String lower,
    required String eventsPath,
    required String behaviorPath,
    required String agentPath,
    required String flowPath,
    required String pagePath,
  }) {
    File(eventsPath).writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';

enum ${moduleName}Intent implements OmegaIntentName {
  start,
  retry;

  @override
  String get name => '$lower.\${toString().split('.').last}';
}

enum ${moduleName}Event implements OmegaEventName {
  requested,
  succeeded,
  failed;

  @override
  String get name => '$lower.\${toString().split('.').last}';
}

class ${moduleName}RequestedEvent implements OmegaTypedEvent {
  const ${moduleName}RequestedEvent({required this.input});
  final String input;

  @override
  String get name => ${moduleName}Event.requested.name;
}

class ${moduleName}ViewState {
  const ${moduleName}ViewState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  ${moduleName}ViewState copyWith({bool? isLoading, String? error}) {
    return ${moduleName}ViewState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  static const idle = ${moduleName}ViewState();
}
''');

    File(behaviorPath).writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';
import '${lower}_events.dart';

class ${moduleName}Behavior extends OmegaAgentBehaviorEngine {
  ${moduleName}Behavior() {
    addRule(
      OmegaAgentBehaviorRule(
        condition: (ctx) => ctx.event?.name == ${moduleName}Event.requested.name,
        reaction: (ctx) => const OmegaAgentReaction('processRequest'),
      ),
    );
  }
}
''');

    File(agentPath).writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';
import '${lower}_behavior.dart';
import '${lower}_events.dart';

class ${moduleName}Agent extends OmegaStatefulAgent<${moduleName}ViewState> {
  ${moduleName}Agent(OmegaEventBus channel)
      : super(
          id: '$moduleName',
          channel: channel,
          behavior: ${moduleName}Behavior(),
          initialState: ${moduleName}ViewState.idle,
        );

  @override
  OmegaAgentContract? get contract => OmegaAgentContract(
    listenedEventNames: {${moduleName}Event.requested.name},
  );

  @override
  void onAction(String action, dynamic payload) {
    if (action == 'processRequest') {
      setViewState(viewState.copyWith(isLoading: true, error: null));
      setViewState(viewState.copyWith(isLoading: false));
      channel.emit(OmegaEvent.fromName(${moduleName}Event.succeeded));
    }
  }

  @override
  void onMessage(OmegaAgentMessage msg) {}
}
''');

    File(flowPath).writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';
import '${lower}_events.dart';

class ${moduleName}Flow extends OmegaWorkflowFlow {
  ${moduleName}Flow(OmegaEventBus channel)
      : super(id: '$moduleName', channel: channel) {
    defineStep('start', () => emitExpression('loading'));
    defineStep('done', () => completeWorkflow());
  }

  @override
  OmegaFlowContract? get contract => OmegaFlowContract(
    acceptedIntentNames: {${moduleName}Intent.start.name, ${moduleName}Intent.retry.name},
    listenedEventNames: {${moduleName}Event.succeeded.name, ${moduleName}Event.failed.name},
    emittedExpressionTypes: {'idle', 'loading', 'success', 'error', 'workflow.done'},
  );

  @override
  void onStart() {
    emitExpression('idle');
  }

  @override
  void onIntent(OmegaFlowContext ctx) {
    final intentName = ctx.intent?.name;
    if (intentName == ${moduleName}Intent.start.name) {
      channel.emitTyped(const ${moduleName}RequestedEvent(input: 'initial'));
      startAt('start');
    }
    if (intentName == ${moduleName}Intent.retry.name) {
      channel.emitTyped(const ${moduleName}RequestedEvent(input: 'retry'));
      next('start');
    }
  }

  @override
  void onEvent(OmegaFlowContext ctx) {
    final event = ctx.event;
    if (event?.name == ${moduleName}Event.succeeded.name) {
      emitExpression('success');
      next('done');
    }
    if (event?.name == ${moduleName}Event.failed.name) {
      emitExpression('error', payload: event?.payload);
      failStep('request.failed');
    }
  }
}
''');

    File(pagePath).writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';
import '../${lower}_events.dart';

class ${moduleName}Page extends StatelessWidget {
  const ${moduleName}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = OmegaScope.of(context);
    final flow = scope.flowManager.getFlow('$moduleName');
    if (flow == null) {
      return const Scaffold(
        body: Center(child: Text('Flow not registered in omega_setup.dart')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('$moduleName')),
      body: Center(
        child: StreamBuilder<OmegaFlowExpression>(
          stream: flow.expressions,
          builder: (context, snapshot) {
            final expr = snapshot.data;
            if (expr?.type == 'loading') {
              return const CircularProgressIndicator();
            }
            if (expr?.type == 'error') {
              final msg = expr?.payloadAs<String>() ?? 'Unknown error';
              return Text(msg);
            }
            return ElevatedButton(
              onPressed: () => scope.flowManager.handleIntent(
                OmegaIntent.fromName(${moduleName}Intent.start),
              ),
              child: const Text('Start'),
            );
          },
        ),
      ),
    );
  }
}
''');
  }

  static Future<Map<String, String>?> _providerGenerateModuleCode(
    String description,
    String moduleName,
  ) async {
    final env = Platform.environment;
    if (env["OMEGA_AI_ENABLED"] != "true") return null;
    final provider = env["OMEGA_AI_PROVIDER"];
    if (provider != "openai") return null;
    final apiKey = env["OMEGA_AI_API_KEY"];
    if (apiKey == null || apiKey.isEmpty) return null;

    final model = env["OMEGA_AI_MODEL"] ?? "gpt-4o-mini";
    final baseUrl = env["OMEGA_AI_BASE_URL"] ?? "https://api.openai.com/v1";
    final endpoint =
        "${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions";

    final lower = moduleName.toLowerCase();
    final prompt =
        """
Generate Dart code for an Omega Architecture module named '$moduleName' ($lower).
The app description is: '$description'.

Return a JSON object with these keys, containing the full code for each file:
- 'events': enum ${moduleName}Intent (start, etc), enum ${moduleName}Event, and class ${moduleName}ViewState (with copyWith and 'static const idle').
- 'behavior': class ${moduleName}Behavior extends OmegaAgentBehaviorEngine with rules for events.
- 'agent': class ${moduleName}Agent extends OmegaStatefulAgent<${moduleName}ViewState>. 
- 'flow': class ${moduleName}Flow extends OmegaWorkflowFlow handling business logic.
- 'page': class ${moduleName}Page (StatelessWidget) using StreamBuilder on flow.expressions and OmegaScope.

CRITICAL RULES:
1. NEVER use internal paths like 'package:omega_architecture/omega/core/...'.
2. ALWAYS use ONLY 'import 'package:omega_architecture/omega_architecture.dart';'.
3. Page file MUST import events via: "import '../${lower}_events.dart';"
4. Agent and Behavior files MUST import events via: "import '${lower}_events.dart';"
5. The ViewState class must be inside the 'events' file.
6. Use ONLY the following JSON structure: { "events": "...", "behavior": "...", "agent": "...", "flow": "...", "page": "..." }
7. NO extra markdown or conversational text. Return ONLY valid JSON.
""";

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $apiKey");
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.write(
        jsonEncode({
          "model": model,
          "temperature": 0.3,
          "messages": [
            {"role": "system", "content": "You are a code generator."},
            {"role": "user", "content": prompt},
          ],
          "response_format": {"type": "json_object"},
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(body);
      final content = decoded["choices"][0]["message"]["content"].toString();
      final moduleCode = jsonDecode(content);

      return Map<String, String>.from(moduleCode);
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static Future<void> _coachAudit({
    required String feature,
    required bool asJson,
    required bool useProviderApi,
    required bool toTempFile,
  }) async {
    String root;
    try {
      root = findAppRoot();
    } catch (_) {
      root = Directory.current.absolute.path;
    }
    final repoExampleSetup = File(
      "$root${Platform.pathSeparator}example${Platform.pathSeparator}lib${Platform.pathSeparator}omega${Platform.pathSeparator}omega_setup.dart",
    );
    final rootSetup = File(
      "$root${Platform.pathSeparator}lib${Platform.pathSeparator}omega${Platform.pathSeparator}omega_setup.dart",
    );
    if (!rootSetup.existsSync() && repoExampleSetup.existsSync()) {
      root = "$root${Platform.pathSeparator}example";
    }
    final libDir = Directory("$root/lib");
    final testDir = Directory("$root/test");
    final setupFile = File("$root/lib/omega/omega_setup.dart");
    final slug = feature.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "_");

    final flowPath = _findFeatureFile(libDir, "${slug}_flow.dart");
    final agentPath = _findFeatureFile(libDir, "${slug}_agent.dart");
    final behaviorPath = _findFeatureFile(libDir, "${slug}_behavior.dart");
    final eventsPath = _findFeatureFile(libDir, "${slug}_events.dart");
    final pagePath = _findFeatureFile(libDir, "${slug}_page.dart");

    final testMatches = _findFeatureFiles(
      testDir,
      RegExp("${RegExp.escape(slug)}.*\\.dart\$"),
    );

    final setupContent = setupFile.existsSync()
        ? setupFile.readAsStringSync()
        : "";
    final pascalBase = toPascalCase(slug);
    final hasFlowRegistration = setupContent.contains("${pascalBase}Flow(");
    final hasAgentRegistration = setupContent.contains("${pascalBase}Agent(");

    final gaps = <String>[];
    final findings = <String>[];
    findings.add("Audit root: ${_absPath(root)}");
    findings.add("Audit pattern: ${slug}_*.dart");

    void checkRequired(String label, String? path) {
      if (path == null) {
        gaps.add("Missing $label");
      } else {
        findings.add("$label: ${_absPath(path)}");
      }
    }

    checkRequired("Flow file", flowPath);
    checkRequired("Agent file", agentPath);
    checkRequired("Behavior file", behaviorPath);
    checkRequired("Events file", eventsPath);
    checkRequired("UI page file", pagePath);

    if (!setupFile.existsSync()) {
      gaps.add("Missing omega_setup.dart");
    } else {
      findings.add("Setup file: ${_absPath(setupFile.path)}");
      if (!hasFlowRegistration) {
        gaps.add("Flow is not registered in omega_setup.dart");
      }
      if (!hasAgentRegistration) {
        gaps.add("Agent is not registered in omega_setup.dart");
      }
    }

    if (testMatches.isEmpty) {
      gaps.add("No feature-focused tests found under /test");
    } else {
      findings.add("Tests found: ${testMatches.length}");
    }

    if (flowPath == null &&
        agentPath == null &&
        behaviorPath == null &&
        eventsPath == null &&
        pagePath == null) {
      findings.add(
        _tr(
          en: "No files matched '${slug}_*'. If your ecosystem uses a different base name (e.g. auth), run audit with that feature name.",
          es: "No hubo coincidencias con '${slug}_*'. Si tu ecosistema usa otro nombre base (por ejemplo auth), ejecuta el audit con ese nombre.",
        ),
      );
    }

    if (flowPath != null) {
      final flowContent = File(flowPath).readAsStringSync();
      if (!flowContent.contains("OmegaFlowContract") &&
          !flowContent.contains("contract")) {
        gaps.add("Flow contract appears missing");
      }
    }
    if (agentPath != null) {
      final agentContent = File(agentPath).readAsStringSync();
      if (!agentContent.contains("OmegaAgentContract") &&
          !agentContent.contains("contract")) {
        gaps.add("Agent contract appears missing");
      }
    }

    final score = (100 - (gaps.length * 12)).clamp(0, 100);
    final summary = gaps.isEmpty
        ? _tr(
            en: "Feature looks structurally healthy for Omega.",
            es: "La feature se ve estructuralmente saludable para Omega.",
          )
        : _tr(
            en: "Feature has architectural gaps to resolve.",
            es: "La feature tiene brechas arquitectonicas por resolver.",
          );

    final aiInsights = <String>[];
    var mode = "offline";
    if (useProviderApi) {
      final provider = await _runWithProgress<List<String>?>(
        _tr(en: "Consulting AI provider", es: "Consultando proveedor IA"),
        () => _providerAuditInsights(feature, gaps, findings),
      );
      if (provider != null && provider.isNotEmpty) {
        aiInsights.addAll(provider);
        mode = "provider-api";
      }
    }

    if (asJson) {
      _emitAiOutput(
        content: jsonEncode({
          "coach": "audit",
          "mode": mode,
          "feature": feature,
          "score": score,
          "summary": summary,
          "gaps": gaps,
          "findings": findings,
          "insights": aiInsights,
        }),
        toTempFile: toTempFile,
        kind: "coach_audit",
        extension: "json",
      );
      return;
    }

    _emitAiOutput(
      content: _formatCoachAuditMarkdown(
        mode: mode,
        feature: feature,
        score: score,
        summary: summary,
        gaps: gaps,
        findings: findings,
        insights: aiInsights,
      ),
      toTempFile: toTempFile,
      kind: "coach_audit",
      extension: "md",
    );
  }

  static Future<void> _coachModule({
    required String feature,
    required String template,
    required bool asJson,
    required bool useProviderApi,
    required bool toTempFile,
  }) async {
    final moduleName = toPascalCase(
      feature
          .replaceAll(RegExp(r"[^a-zA-Z0-9_ ]"), " ")
          .replaceAll(RegExp(r"\s+"), " ")
          .trim(),
    );
    final requiredArtifacts = _coachRequiredArtifacts(moduleName);
    final checks = _coachValidationChecks();
    final insights = <String>[];
    var mode = "offline";

    Map<String, String>? aiGeneratedCode;

    if (useProviderApi) {
      final providerSteps = await runWithProgress<List<String>?>(
        _tr(en: "Consulting AI provider", es: "Consultando proveedor IA"),
        () => _providerCoachPlan(feature),
      );
      if (providerSteps != null && providerSteps.isNotEmpty) {
        insights.addAll(providerSteps);
        mode = "provider-api";
      }

      final generated = await runWithProgress<Map<String, String>?>(
        _tr(
          en: "Generating custom logic with AI",
          es: "Generando lógica personalizada con IA",
        ),
        () => _providerGenerateModuleCode(feature, moduleName),
      );
      if (generated != null) {
        aiGeneratedCode = generated;
      }
    }

    String appRoot;
    try {
      appRoot = findAppRoot();
    } catch (_) {
      appRoot = Directory.current.absolute.path;
    }
    final appLib = Directory(
      "$appRoot${Platform.pathSeparator}lib",
    ).absolute.path;
    final setupPath =
        "$appRoot${Platform.pathSeparator}lib${Platform.pathSeparator}omega${Platform.pathSeparator}omega_setup.dart";
    final hasSetup = File(setupPath).existsSync();

    final modulePath =
        "$appLib${Platform.pathSeparator}${moduleName.toLowerCase()}";
    final expectedFiles = <String>[
      "$modulePath${Platform.pathSeparator}${moduleName.toLowerCase()}_agent.dart",
      "$modulePath${Platform.pathSeparator}${moduleName.toLowerCase()}_flow.dart",
      "$modulePath${Platform.pathSeparator}${moduleName.toLowerCase()}_behavior.dart",
      "$modulePath${Platform.pathSeparator}${moduleName.toLowerCase()}_events.dart",
      "$modulePath${Platform.pathSeparator}ui${Platform.pathSeparator}${moduleName.toLowerCase()}_page.dart",
    ];

    var created = false;
    final originalCwd = Directory.current.path;
    if (hasSetup) {
      await runWithProgress<void>(
        _tr(
          en: "Generating ecosystem module",
          es: "Generando modulo de ecosistema",
        ),
        () async {
          Directory.current = appLib;
          OmegaGenerateCommand._createEcosystem(moduleName);
        },
      );
      created = true;
      if (template == "advanced") {
        _applyAdvancedModuleTemplate(
          appRoot: appRoot,
          modulePath: modulePath,
          moduleName: moduleName,
          customCode: aiGeneratedCode,
        );
      }
    } else {
      insights.add(
        _tr(
          en: "Missing omega_setup.dart in app root; run omega init first in your app.",
          es: "Falta omega_setup.dart en la raiz de la app; ejecuta omega init primero en tu app.",
        ),
      );
    }
    Directory.current = originalCwd;

    final createdFiles = expectedFiles
        .where((p) => File(p).existsSync())
        .toList();
    final testFile =
        "$appRoot${Platform.pathSeparator}test${Platform.pathSeparator}${moduleName.toLowerCase()}_module_test.dart";
    if (File(testFile).existsSync()) {
      createdFiles.add(testFile);
    }

    if (asJson) {
      _emitAiOutput(
        content: jsonEncode({
          "coach": "module",
          "mode": mode,
          "feature": feature,
          "moduleName": moduleName,
          "template": template,
          "modulePath": _absPath(modulePath),
          "requiredArtifacts": requiredArtifacts,
          "created": created,
          "createdFiles": createdFiles.map(_absPath).toList(),
          "validationChecks": checks,
          "insights": insights,
        }),
        toTempFile: toTempFile,
        kind: "coach_module",
        extension: "json",
      );
      return;
    }

    final out = StringBuffer()
      ..writeln("# Omega AI Coach Module ($mode)")
      ..writeln("")
      ..writeln("- Feature: `$feature`")
      ..writeln("- Module name: `$moduleName`")
      ..writeln("- Template: `$template`")
      ..writeln("- Module path: `${_absPath(modulePath)}`")
      ..writeln("- Created: `${created ? "yes" : "no"}`")
      ..writeln("")
      ..writeln(
        "## ${_tr(en: "What Omega needs", es: "Lo que Omega necesita")}",
      );
    for (final item in requiredArtifacts) {
      out.writeln("- $item");
    }
    out
      ..writeln("")
      ..writeln("## ${_tr(en: "Created files", es: "Archivos creados")}");
    if (createdFiles.isEmpty) {
      out.writeln(
        "- ${_tr(en: "No files were created.", es: "No se crearon archivos.")}",
      );
    } else {
      for (final file in createdFiles) {
        out.writeln("- `${_absPath(file)}`");
      }
    }
    out
      ..writeln("")
      ..writeln(
        "## ${_tr(en: "Validation checks", es: "Checks de validacion")}",
      );
    for (final item in checks) {
      out.writeln("- `$item`");
    }
    if (insights.isNotEmpty) {
      out
        ..writeln("")
        ..writeln("## ${_tr(en: "AI insights", es: "Insights de IA")}");
      for (final i in insights) {
        out.writeln("- $i");
      }
    }
    _emitAiOutput(
      content: out.toString(),
      toTempFile: toTempFile,
      kind: "coach_module",
      extension: "md",
    );
  }

  static String? _findFeatureFile(Directory dir, String fileName) {
    final matches = _findFeatureFiles(dir, RegExp(RegExp.escape(fileName)));
    if (matches.isEmpty) return null;
    return matches.first;
  }

  static List<String> _findFeatureFiles(Directory dir, RegExp pattern) {
    if (!dir.existsSync()) return const <String>[];
    final matches = <String>[];
    for (final e in dir.listSync(recursive: true)) {
      if (e is File) {
        final parts = e.path.split(Platform.pathSeparator);
        final name = parts.isEmpty ? e.path : parts.last;
        if (pattern.hasMatch(name)) {
          matches.add(e.path);
        }
      }
    }
    matches.sort();
    return matches;
  }

  static Future<List<String>?> _providerCoachPlan(String feature) async {
    final env = Platform.environment;
    final enabled = _readBool(env["OMEGA_AI_ENABLED"], defaultValue: false);
    if (!enabled) return null;

    final provider = (env["OMEGA_AI_PROVIDER"] ?? "").trim().toLowerCase();
    if (provider != "openai") return null;

    final apiKey = (env["OMEGA_AI_API_KEY"] ?? "").trim();
    if (apiKey.isEmpty) return null;

    final model = (env["OMEGA_AI_MODEL"] ?? "gpt-4o-mini").trim();
    final targetLanguage = _preferredAiLanguage();
    final base = (env["OMEGA_AI_BASE_URL"] ?? "https://api.openai.com/v1")
        .trim();
    final endpoint = base.endsWith("/chat/completions")
        ? base
        : "${base.replaceAll(RegExp(r"/+$"), "")}/chat/completions";

    final requestBody = {
      "model": model,
      "temperature": 0.2,
      "messages": [
        {
          "role": "system",
          "content":
              "You are Omega coding coach. Respond strictly in $targetLanguage. Return 5-7 concise numbered steps with practical guidance for implementation.",
        },
        {
          "role": "user",
          "content":
              "Create a practical step-by-step coding guide in Omega architecture for this feature: '$feature'. Include flow, agent, intents/events, setup wiring, and testing.",
        },
      ],
    };

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $apiKey");
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final choices = decoded["choices"];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final message = first["message"];
      if (message is! Map) return null;
      final content = (message["content"] ?? "").toString().trim();
      if (content.isEmpty) return null;

      final lines = content
          .split("\n")
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map(
            (l) => l
                .replaceFirst(RegExp(r"^[-*•]\s*"), "")
                .replaceFirst(RegExp(r"^\d+[\.\)]\s*"), ""),
          )
          .where((l) => l.isNotEmpty)
          .take(8)
          .toList();
      return lines.isEmpty ? [content] : lines;
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static Future<List<String>?> _providerAuditInsights(
    String feature,
    List<String> gaps,
    List<String> findings,
  ) async {
    final env = Platform.environment;
    final enabled = _readBool(env["OMEGA_AI_ENABLED"], defaultValue: false);
    if (!enabled) return null;

    final provider = (env["OMEGA_AI_PROVIDER"] ?? "").trim().toLowerCase();
    if (provider != "openai") return null;

    final apiKey = (env["OMEGA_AI_API_KEY"] ?? "").trim();
    if (apiKey.isEmpty) return null;

    final model = (env["OMEGA_AI_MODEL"] ?? "gpt-4o-mini").trim();
    final targetLanguage = _preferredAiLanguage();
    final base = (env["OMEGA_AI_BASE_URL"] ?? "https://api.openai.com/v1")
        .trim();
    final endpoint = base.endsWith("/chat/completions")
        ? base
        : "${base.replaceAll(RegExp(r"/+$"), "")}/chat/completions";

    final requestBody = {
      "model": model,
      "temperature": 0.2,
      "messages": [
        {
          "role": "system",
          "content":
              "You are Omega architecture reviewer. Respond strictly in $targetLanguage with short actionable bullet points.",
        },
        {
          "role": "user",
          "content":
              "Feature: $feature\nCurrent findings: ${jsonEncode(findings)}\nCurrent gaps: ${jsonEncode(gaps)}\nReturn 3-6 prioritized actions to close gaps in Omega architecture.",
        },
      ],
    };

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $apiKey");
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final choices = decoded["choices"];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final message = first["message"];
      if (message is! Map) return null;
      final content = (message["content"] ?? "").toString().trim();
      if (content.isEmpty) return null;

      final lines = content
          .split("\n")
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map(
            (l) => l
                .replaceFirst(RegExp(r"^[-*•]\s*"), "")
                .replaceFirst(RegExp(r"^\d+[\.\)]\s*"), ""),
          )
          .where((l) => l.isNotEmpty)
          .take(8)
          .toList();
      return lines.isEmpty ? [content] : lines;
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static Future<List<String>?> _providerExplain(
    List<Map<String, dynamic>> events,
  ) async {
    final env = Platform.environment;
    final enabled = _readBool(env["OMEGA_AI_ENABLED"], defaultValue: false);
    if (!enabled) return null;

    final provider = (env["OMEGA_AI_PROVIDER"] ?? "").trim().toLowerCase();
    if (provider != "openai") return null;

    final apiKey = (env["OMEGA_AI_API_KEY"] ?? "").trim();
    if (apiKey.isEmpty) return null;

    final model = (env["OMEGA_AI_MODEL"] ?? "gpt-4o-mini").trim();
    final targetLanguage = _preferredAiLanguage();
    final base = (env["OMEGA_AI_BASE_URL"] ?? "https://api.openai.com/v1")
        .trim();
    final endpoint = base.endsWith("/chat/completions")
        ? base
        : "${base.replaceAll(RegExp(r"/+$"), "")}/chat/completions";

    final compactEvents = events
        .take(80)
        .map(
          (e) => {
            "name": (e["name"] ?? "unknown").toString(),
            "namespace": (e["namespace"] ?? "global").toString(),
            if (e["payload"] != null) "payload": e["payload"],
          },
        )
        .toList();

    final requestBody = {
      "model": model,
      "temperature": 0.2,
      "messages": [
        {
          "role": "system",
          "content":
              "You are Omega architecture assistant. Return concise diagnostics as plain bullet lines only. Respond strictly in $targetLanguage.",
        },
        {
          "role": "user",
          "content":
              "Analyze this Omega trace event sequence and return 2-4 short bullet points: root cause guess, risky pattern, and concrete next check. Do not use markdown styling.\n${jsonEncode(compactEvents)}",
        },
      ],
    };

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $apiKey");
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final choices = decoded["choices"];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final message = first["message"];
      if (message is! Map) return null;
      final content = (message["content"] ?? "").toString().trim();
      if (content.isEmpty) return null;

      final lines = content
          .split("\n")
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map(
            (l) => l
                .replaceFirst(RegExp(r"^[-*•]\s*"), "")
                .replaceFirst(RegExp(r"^\d+[\.\)]\s*"), ""),
          )
          .where((l) => l.isNotEmpty)
          .take(6)
          .toList();
      return lines.isEmpty ? [content] : lines;
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static bool _readBool(String? raw, {required bool defaultValue}) {
    if (raw == null) return defaultValue;
    final value = raw.trim().toLowerCase();
    if (value == "1" || value == "true" || value == "yes" || value == "on") {
      return true;
    }
    if (value == "0" || value == "false" || value == "no" || value == "off") {
      return false;
    }
    return defaultValue;
  }

  static String? _optionValue(List<String> args, String option) {
    final inline = args.firstWhere(
      (a) => a.startsWith("$option="),
      orElse: () => "",
    );
    if (inline.isNotEmpty) {
      return inline.substring(option.length + 1).trim();
    }
    final i = args.indexOf(option);
    if (i >= 0 && i + 1 < args.length && !args[i + 1].startsWith("-")) {
      return args[i + 1].trim();
    }
    return null;
  }

  static List<String> _collectPositionalArgs(
    List<String> args, {
    required List<String> optionsWithValue,
  }) {
    final result = <String>[];
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a.startsWith("-")) {
        if (optionsWithValue.contains(a) && i + 1 < args.length) {
          i++;
        }
        continue;
      }
      result.add(a);
    }
    return result;
  }

  static void _emitAiOutput({
    required String content,
    required bool toTempFile,
    required String kind,
    required String extension,
  }) {
    if (!toTempFile) {
      stdout.writeln(content);
      return;
    }

    final path = _writeTempAiFile(
      content: content,
      kind: kind,
      extension: extension,
    );
    stdout.writeln(
      _tr(
        en: "AI output saved to temporary file:",
        es: "Salida de IA guardada en archivo temporal:",
        pt: "Saida da IA salva em arquivo temporario:",
        fr: "Sortie IA enregistree dans un fichier temporaire:",
        it: "Output IA salvato in file temporaneo:",
        de: "KI-Ausgabe in temporaerer Datei gespeichert:",
      ),
    );
    stdout.writeln("  ${_absPath(path)}");
    try {
      _openInBrowser(path);
    } catch (_) {}
  }

  static String _writeTempAiFile({
    required String content,
    required String kind,
    required String extension,
  }) {
    String root;
    try {
      root = findProjectRoot();
    } catch (_) {
      root = Directory.current.absolute.path;
    }
    final dir = Directory("$root/.dart_tool/omega_ai_temp");
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File("${dir.path}/omega_ai_${kind}_$ts.$extension");
    file.writeAsStringSync(content);
    return file.path;
  }

  static String _formatExplainMarkdown({
    required String mode,
    required String tracePath,
    required int eventsCount,
    required String firstEvent,
    required String lastEvent,
    required List<MapEntry<String, int>> top,
    required List<MapEntry<String, int>> nsEntries,
    required List<String> diagnosis,
  }) {
    final b = StringBuffer();
    b.writeln("# Omega AI Explain ($mode)");
    b.writeln("");
    b.writeln("## ${_tr(en: "Summary", es: "Resumen")}");
    b.writeln("- Trace: `$tracePath`");
    b.writeln(
      "- ${_tr(en: "Events", es: "Eventos", pt: "Eventos", fr: "Evenements", it: "Eventi", de: "Ereignisse")}: `$eventsCount`",
    );
    b.writeln(
      "- ${_tr(en: "First event", es: "Primer evento", pt: "Primeiro evento", fr: "Premier evenement", it: "Primo evento", de: "Erstes Ereignis")}: `$firstEvent`",
    );
    b.writeln(
      "- ${_tr(en: "Last event", es: "Ultimo evento", pt: "Ultimo evento", fr: "Dernier evenement", it: "Ultimo evento", de: "Letztes Ereignis")}: `$lastEvent`",
    );
    b.writeln("");
    b.writeln(
      "## ${_tr(en: "Top events", es: "Eventos principales", pt: "Principais eventos", fr: "Evenements principaux", it: "Eventi principali", de: "Top-Ereignisse")}",
    );
    if (top.isEmpty) {
      b.writeln("- ${_tr(en: "No data", es: "Sin datos")}");
    } else {
      for (final item in top) {
        b.writeln("- `${item.key}`: ${item.value}");
      }
    }
    b.writeln("");
    b.writeln("## Namespaces");
    if (nsEntries.isEmpty) {
      b.writeln("- ${_tr(en: "No data", es: "Sin datos")}");
    } else {
      for (final item in nsEntries) {
        b.writeln("- `${item.key}`: ${item.value}");
      }
    }
    b.writeln("");
    b.writeln(
      "## ${_tr(en: "Heuristic diagnosis", es: "Diagnostico heuristico", pt: "Diagnostico heuristico", fr: "Diagnostic heuristique", it: "Diagnosi euristica", de: "Heuristische Diagnose")}",
    );
    for (final line in diagnosis) {
      b.writeln("- $line");
    }
    return b.toString();
  }

  static String _formatCoachMarkdown({
    required String mode,
    required String feature,
    required List<String> requiredArtifacts,
    required List<String> steps,
    required List<String> validationChecks,
    required List<String> insights,
    required String nextCommand,
  }) {
    final b = StringBuffer();
    b.writeln("# Omega AI Coach ($mode)");
    b.writeln("");
    b.writeln(
      "- ${_tr(en: "Feature", es: "Feature", pt: "Feature", fr: "Feature", it: "Feature", de: "Feature")}: `$feature`",
    );
    b.writeln("");
    b.writeln(
      "## ${_tr(en: "Guided steps", es: "Pasos guiados", pt: "Passos guiados", fr: "Etapes guidees", it: "Passi guidati", de: "Gefuehrte Schritte")}",
    );
    for (var i = 0; i < steps.length; i++) {
      b.writeln("${i + 1}. ${steps[i]}");
    }
    b.writeln("");
    b.writeln(
      "## ${_tr(en: "Required Omega artifacts", es: "Artefactos Omega requeridos")}",
    );
    for (final item in requiredArtifacts) {
      b.writeln("- $item");
    }
    b.writeln("");
    b.writeln("## ${_tr(en: "Validation checks", es: "Checks de validacion")}");
    for (final item in validationChecks) {
      b.writeln("- `$item`");
    }
    if (insights.isNotEmpty) {
      b.writeln("");
      b.writeln("## ${_tr(en: "AI insights", es: "Insights de IA")}");
      for (final item in insights) {
        b.writeln("- $item");
      }
    }
    b.writeln("");
    b.writeln(
      "## ${_tr(en: "Suggested next command", es: "Siguiente comando sugerido", pt: "Proximo comando sugerido", fr: "Prochaine commande suggeree", it: "Prossimo comando suggerito", de: "Empfohlener naechster Befehl")}",
    );
    b.writeln("`$nextCommand`");
    return b.toString();
  }

  static String _formatCoachAuditMarkdown({
    required String mode,
    required String feature,
    required int score,
    required String summary,
    required List<String> gaps,
    required List<String> findings,
    required List<String> insights,
  }) {
    final b = StringBuffer();
    b.writeln("# Omega AI Coach Audit ($mode)");
    b.writeln("");
    b.writeln("- Feature: `$feature`");
    b.writeln("- Score: `$score/100`");
    b.writeln("- Summary: $summary");
    b.writeln("");

    b.writeln("## Findings");
    if (findings.isEmpty) {
      b.writeln("- ${_tr(en: "No findings yet.", es: "Sin hallazgos aun.")}");
    } else {
      for (final item in findings) {
        b.writeln("- $item");
      }
    }
    b.writeln("");

    b.writeln("## Gaps");
    if (gaps.isEmpty) {
      b.writeln(
        "- ${_tr(en: "No gaps detected.", es: "No se detectaron brechas.")}",
      );
    } else {
      for (final item in gaps) {
        b.writeln("- $item");
      }
    }

    if (insights.isNotEmpty) {
      b.writeln("");
      b.writeln("## AI Insights");
      for (final item in insights) {
        b.writeln("- $item");
      }
    }

    return b.toString();
  }

  static Future<T> _runWithProgress<T>(
    String label,
    Future<T> Function() action,
  ) async {
    return runWithProgress<T>(label, action);
  }
}

String _tr({
  required String en,
  String? es,
  String? pt,
  String? fr,
  String? it,
  String? de,
}) {
  switch (_preferredLangCode()) {
    case "es":
      return es ?? en;
    case "pt":
      return pt ?? en;
    case "fr":
      return fr ?? en;
    case "it":
      return it ?? en;
    case "de":
      return de ?? en;
    default:
      return en;
  }
}

String _preferredLangCode() {
  final env = Platform.environment;
  final fromEnv = (env["OMEGA_AI_LANG"] ?? env["OMEGA_AI_LANGUAGE"] ?? "")
      .trim()
      .toLowerCase();
  if (fromEnv.isNotEmpty) {
    return fromEnv.split(RegExp(r"[-_]")).first;
  }
  final locale = Platform.localeName.toLowerCase().replaceAll("_", "-");
  return locale.split("-").first;
}

String _preferredAiLanguage() {
  final code = _preferredLangCode();
  switch (code) {
    case "es":
      return "Spanish";
    case "pt":
      return "Portuguese";
    case "fr":
      return "French";
    case "it":
      return "Italian";
    case "de":
      return "German";
    default:
      return "English";
  }
}

Future<T> runWithProgress<T>(String label, Future<T> Function() action) async {
  if (!stdout.hasTerminal) {
    return action();
  }

  var step = 0;
  late final Timer timer;
  stdout.write("$label.");
  timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
    step = (step + 1) % 4;
    final dots = "." * (step + 1);
    stdout.write("\r$label$dots   ");
  });

  try {
    final result = await action();
    stdout.write("\r${" " * (label.length + 8)}\r");
    stdout.writeln(
      _tr(
        en: "$label done.",
        es: "$label listo.",
        pt: "$label concluido.",
        fr: "$label termine.",
        it: "$label completato.",
        de: "$label abgeschlossen.",
      ),
    );
    return result;
  } finally {
    timer.cancel();
  }
}
