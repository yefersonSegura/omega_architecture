import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String _version = "0.0.33";
const String _docUrl = "https://yefersonsegura.com/proyects/omega/";

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

/// Outcome of programmatic checks after AI module JSON is applied.
class _OmegaPostGenResult {
  _OmegaPostGenResult({required this.errors, required this.warnings});
  final List<String> errors;
  final List<String> warnings;
  bool get isOk => errors.isEmpty;
}

/// Shared OpenAI + Google Gemini (AI Studio) transport. Same [system] / [user] prompts; same text/JSON output handling.
class _OmegaAiRemote {
  static String? _providerNorm() {
    final p = (Platform.environment["OMEGA_AI_PROVIDER"] ?? "")
        .trim()
        .toLowerCase();
    return p.isEmpty ? null : p;
  }

  static bool _enabled() {
    final v = Platform.environment["OMEGA_AI_ENABLED"]?.trim().toLowerCase();
    return v == "true" || v == "1" || v == "yes";
  }

  static bool isRemoteProvider(String? p) => p == "openai" || p == "gemini";

  /// API key: for `gemini`, prefers [OMEGA_AI_GEMINI_API_KEY] then [OMEGA_AI_API_KEY]. For `openai`, [OMEGA_AI_API_KEY].
  static String effectiveApiKey() {
    final env = Platform.environment;
    final p = _providerNorm() ?? "";
    if (p == "gemini") {
      final g = (env["OMEGA_AI_GEMINI_API_KEY"] ?? "").trim();
      if (g.isNotEmpty) return g;
    }
    return (env["OMEGA_AI_API_KEY"] ?? "").trim();
  }

  static bool canCallRemote() {
    if (!_enabled()) return false;
    final p = _providerNorm();
    if (!isRemoteProvider(p)) return false;
    return effectiveApiKey().isNotEmpty;
  }

  static String _openaiModel() =>
      (Platform.environment["OMEGA_AI_MODEL"] ?? "gpt-4o-mini").trim();
  static String _openaiBase() =>
      (Platform.environment["OMEGA_AI_BASE_URL"] ?? "https://api.openai.com/v1")
          .trim();

  static String _geminiModel() =>
      (Platform.environment["OMEGA_AI_MODEL"] ?? "gemini-2.5-flash").trim();
  static String _geminiApiVersion() =>
      (Platform.environment["OMEGA_AI_GEMINI_API_VERSION"] ?? "v1beta").trim();

  static String stripCodeFences(String raw) {
    var s = raw.trim();
    if (s.contains("```json")) {
      final start = s.indexOf("```json") + 7;
      final end = s.lastIndexOf("```");
      if (end > start) s = s.substring(start, end).trim();
    } else if (s.contains("```")) {
      final start = s.indexOf("```") + 3;
      final end = s.lastIndexOf("```");
      if (end > start) s = s.substring(start, end).trim();
    }
    return s;
  }

  /// Makes AI-returned JSON decodable when the model pastes Dart into string values:
  /// - JSON allows `\"`, `\\`, `\/`, `\b`, `\f`, `\n`, `\r`, `\t`, `\uXXXX` only after `\`.
  /// - **Invalid** escapes (`\$`, `\ `, `\e`, trailing `\` before closing `"`, etc.) break
  /// [jsonDecode]; this pass **doubles the backslash** so the payload becomes a literal `\`
  /// plus the following character in the decoded Dart string (same idea as the old `\$` fix).
  ///
  /// Only treats escapes **inside** JSON `"..."` strings so `{` `}` outside strings are untouched.
  static String sanitizeAiJsonTextForDecode(String text) {
    final out = StringBuffer();
    var inString = false;
    var i = 0;
    while (i < text.length) {
      final c = text.codeUnitAt(i);
      if (!inString) {
        if (c == 0x22) {
          inString = true;
        }
        out.writeCharCode(c);
        i++;
        continue;
      }
      if (c == 0x22) {
        if (_jsonQuoteEscapedByBackslash(text, i)) {
          out.writeCharCode(c);
          i++;
          continue;
        }
        inString = false;
        out.writeCharCode(c);
        i++;
        continue;
      }
      if (c != 0x5c) {
        out.writeCharCode(c);
        i++;
        continue;
      }
      if (i + 1 >= text.length) {
        out.write(r'\\');
        i++;
        break;
      }
      final n = text.codeUnitAt(i + 1);
      if (n == 0x75 && _jsonUnicodeEscapeOk(text, i + 2)) {
        out.write(text.substring(i, i + 6));
        i += 6;
        continue;
      }
      if (n == 0x22 ||
          n == 0x5c ||
          n == 0x2f ||
          n == 0x62 ||
          n == 0x66 ||
          n == 0x6e ||
          n == 0x72 ||
          n == 0x74) {
        out.writeCharCode(c);
        out.writeCharCode(n);
        i += 2;
        continue;
      }
      out.write(r'\\');
      out.writeCharCode(n);
      i += 2;
    }
    return out.toString();
  }

  static bool _jsonQuoteEscapedByBackslash(String text, int quoteIndex) {
    var count = 0;
    for (var j = quoteIndex - 1; j >= 0 && text.codeUnitAt(j) == 0x5c; j--) {
      count++;
    }
    return count.isOdd;
  }

  static bool _jsonUnicodeEscapeOk(String text, int hexStart) {
    if (hexStart + 4 > text.length) return false;
    for (var k = 0; k < 4; k++) {
      if (!_jsonHexDigit(text.codeUnitAt(hexStart + k))) {
        return false;
      }
    }
    return true;
  }

  static bool _jsonHexDigit(int u) {
    if (u >= 0x30 && u <= 0x39) return true;
    if (u >= 0x41 && u <= 0x46) return true;
    if (u >= 0x61 && u <= 0x66) return true;
    return false;
  }

  static String? _extractOpenAiContent(dynamic decoded) {
    if (decoded is! Map) return null;
    final choices = decoded["choices"];
    if (choices is! List || choices.isEmpty) return null;
    final first = choices.first;
    if (first is! Map) return null;
    final message = first["message"];
    if (message is! Map) return null;
    final raw = message["content"];
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is List) {
      final buf = StringBuffer();
      for (final part in raw) {
        if (part is Map && part["text"] != null) {
          buf.write(part["text"]);
        } else {
          buf.write(part.toString());
        }
      }
      final t = buf.toString().trim();
      return t.isEmpty ? null : t;
    }
    return raw.toString();
  }

  static String? _extractGeminiText(dynamic decoded) {
    if (decoded is! Map) return null;
    final candidates = decoded["candidates"];
    if (candidates is! List || candidates.isEmpty) return null;
    final c0 = candidates.first;
    if (c0 is! Map) return null;
    final content = c0["content"];
    if (content is! Map) return null;
    final parts = content["parts"];
    if (parts is! List || parts.isEmpty) return null;
    final buf = StringBuffer();
    for (final p in parts) {
      if (p is Map && p["text"] != null) buf.write(p["text"]);
    }
    final t = buf.toString().trim();
    return t.isEmpty ? null : t;
  }

  /// One assistant text response, or null. [jsonObject] maps to OpenAI `response_format` / Gemini `responseMimeType: application/json`.
  static Future<String?> completeChat({
    required String system,
    required String user,
    double temperature = 0.2,
    bool jsonObject = false,
    Duration timeout = const Duration(seconds: 60),
    bool silentErrors = false,
  }) async {
    if (!canCallRemote()) return null;
    final p = _providerNorm()!;
    final apiKey = effectiveApiKey();

    if (p == "gemini") {
      return _geminiGenerate(
        apiKey: apiKey,
        system: system,
        user: user,
        temperature: temperature,
        jsonObject: jsonObject,
        timeout: timeout,
        silentErrors: silentErrors,
      );
    }
    return _openaiChat(
      apiKey: apiKey,
      system: system,
      user: user,
      temperature: temperature,
      jsonObject: jsonObject,
      timeout: timeout,
      silentErrors: silentErrors,
    );
  }

  static Future<String?> _openaiChat({
    required String apiKey,
    required String system,
    required String user,
    required double temperature,
    required bool jsonObject,
    required Duration timeout,
    required bool silentErrors,
  }) async {
    final model = _openaiModel();
    final base = _openaiBase();
    final endpoint = base.endsWith("/chat/completions")
        ? base
        : "${base.replaceAll(RegExp(r'/+$'), '')}/chat/completions";

    final body = <String, dynamic>{
      "model": model,
      "temperature": temperature,
      "messages": [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
      ],
    };
    if (jsonObject) {
      body["response_format"] = {"type": "json_object"};
    }

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = timeout;
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.set(HttpHeaders.authorizationHeader, "Bearer $apiKey");
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        "application/json; charset=utf-8",
      );
      final bytes = utf8.encode(jsonEncode(body));
      request.contentLength = bytes.length;
      request.add(bytes);

      final response = await request.close().timeout(timeout);
      final respBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (!silentErrors) {
          _err("AI (openai) HTTP ${response.statusCode}: $respBody");
        }
        return null;
      }
      final decoded = jsonDecode(respBody);
      return _extractOpenAiContent(decoded);
    } catch (e) {
      if (!silentErrors) {
        _err("AI (openai) error: $e");
      }
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static Future<String?> _geminiGenerate({
    required String apiKey,
    required String system,
    required String user,
    required double temperature,
    required bool jsonObject,
    required Duration timeout,
    required bool silentErrors,
  }) async {
    var modelId = _geminiModel().replaceFirst(RegExp(r'^models/'), "");
    final version = _geminiApiVersion();
    final uri = Uri.parse(
      "https://generativelanguage.googleapis.com/$version/models/$modelId:generateContent",
    ).replace(queryParameters: {"key": apiKey});

    final generationConfig = <String, dynamic>{"temperature": temperature};
    if (jsonObject) {
      generationConfig["responseMimeType"] = "application/json";
    }

    final body = <String, dynamic>{
      "systemInstruction": {
        "parts": [
          {"text": system},
        ],
      },
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": user},
          ],
        },
      ],
      "generationConfig": generationConfig,
    };

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = timeout;
      final request = await client.postUrl(uri);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        "application/json; charset=utf-8",
      );
      final bytes = utf8.encode(jsonEncode(body));
      request.contentLength = bytes.length;
      request.add(bytes);

      final response = await request.close().timeout(timeout);
      final respBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (!silentErrors) {
          _err("AI (gemini) HTTP ${response.statusCode}: $respBody");
        }
        return null;
      }
      return _extractGeminiText(jsonDecode(respBody));
    } catch (e) {
      if (!silentErrors) {
        _err("AI (gemini) error: $e");
      }
      return null;
    } finally {
      client?.close(force: true);
    }
  }
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
    "  init [--force]       Create lib/omega/omega_setup.dart, app_semantics.dart, app_runtime_ids.dart (or add missing files if setup exists; --force overwrites setup only)",
  );
  stdout.writeln(
    "  g ecosystem <Name>    Generate agent, flow, behavior and page in the current directory",
  );
  stdout.writeln(
    "  g agent <Name>       Agent + behavior; updates AppAgentId in app_runtime_ids.dart",
  );
  stdout.writeln(
    "  g flow <Name>        Flow only; updates AppFlowId in app_runtime_ids.dart (needs *_agent.dart)",
  );
  stdout.writeln(
    "  validate             Check omega_setup.dart (structure, duplicates, routes vs *Page agent, login/home cold start when Auth + multi-route)",
  );
  stdout.writeln(
    "  trace [view|validate] [file]  Inspect or validate a recorded trace file (JSON)",
  );
  stdout.writeln(
    "  doctor [path]        Project health (path = start search from, e.g. example or .)",
  );
  stdout.writeln(
    "  ai <doctor|env|explain>  Omi / assistant setup and offline trace explanation",
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
    "  omega g agent Orders      # + AppAgentId.Orders in app_runtime_ids.dart",
  );
  stdout.writeln(
    "  omega g flow Orders       # + AppFlowId.Orders (agent must exist)",
  );
  stdout.writeln("  omega validate");
  stdout.writeln("  omega trace view trace.json    # summarize trace file");
  stdout.writeln("  omega trace validate trace.json # validate and exit 0/1");
  stdout.writeln(
    "  omega doctor                   # from app root, or: omega doctor example",
  );
  stdout.writeln(
    "  omega ai doctor                # check Omi / assistant env (provider, key, model)",
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
      stdout.writeln(
        "  With --provider-api: adds intl + equatable to pubspec for Omi-generated modules/heal.",
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
    final addRes = await runWithProgress<ProcessResult>(
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
    if (addRes.exitCode != 0) {
      _err(
        "${_tr(en: "pub add omega_architecture failed", es: "Fallo pub add omega_architecture")}: ${addRes.stderr}",
      );
      return;
    }

    await runWithProgress<ProcessResult>(
      _tr(en: "Running pub get", es: "Ejecutando pub get"),
      () => Process.run(
        "dart",
        ["pub", "get"],
        workingDirectory: projectRoot,
        runInShell: true,
      ),
    );

    // 2b. Optional deps when using remote AI (--provider-api): models often emit intl/DateFormat or Equatable.
    if (useProviderApi) {
      final extrasRes = await runWithProgress<ProcessResult>(
        _tr(
          en: "Adding intl & equatable (Omi often needs them in generated code)",
          es: "Agregando intl y equatable (Omi suele necesitarlos en código generado)",
        ),
        () => Process.run(
          "dart",
          ["pub", "add", "intl", "equatable"],
          workingDirectory: projectRoot,
          runInShell: true,
        ),
      );
      if (extrasRes.exitCode != 0) {
        _err(
          "${_tr(en: "pub add intl equatable failed", es: "Fallo pub add intl equatable")}: ${extrasRes.stderr}",
        );
        return;
      }
      await runWithProgress<ProcessResult>(
        _tr(en: "Running pub get", es: "Ejecutando pub get"),
        () => Process.run(
          "dart",
          ["pub", "get"],
          workingDirectory: projectRoot,
          runInShell: true,
        ),
      );
    }

    // 3. Omega Init
    final originalCwd = Directory.current.path;
    Directory.current = projectRoot;
    try {
      stdout.writeln(
        "🛠️ ${_tr(en: "Initializing Omega architecture", es: "Inicializando arquitectura Omega")}...",
      );
      OmegaInitCommand.run([]);

      // 4. Setup modules with AI if requested
      if (kickstart != null) {
        stdout.writeln(
          "✨ ${_tr(en: "Omi is kickstarting your app: $kickstart", es: "Omi arranca tu app: $kickstart")}...",
        );

        final modules = await runWithProgress<List<String>>(
          _tr(
            en: "Omi suggests modules for this product",
            es: "Omi propone módulos para este producto",
          ),
          () async {
            if (useProviderApi) {
              final aiModules = await _providerSuggestModules(kickstart);
              if (aiModules != null) return aiModules;
            }
            return ["Home"]; // Fallback
          },
        );

        for (final module in modules) {
          stdout.writeln(
            "🏗️ ${_tr(en: "Generating module: $module", es: "Generando modulo: $module")}...",
          );
          final coachOk = await OmegaAiCommand._coachModule(
            feature: module,
            productContext: kickstart,
            template: "advanced",
            asJson: false,
            useProviderApi: useProviderApi,
            toTempFile: false,
            runPostValidate: false,
          );
          if (!coachOk) {
            _err(
              _tr(
                en: "Kickstart stopped: Omi could not generate this module. Fix provider/key/model or run without --provider-api.",
                es: "Kickstart detenido: Omi no pudo generar este módulo. Corrige proveedor/clave/modelo o ejecuta sin --provider-api.",
              ),
            );
            return;
          }
        }
      }

      await runWithProgress<ProcessResult>(
        _tr(
          en: "Refreshing pub after Omega files",
          es: "Actualizando pub tras archivos Omega",
        ),
        () => Process.run(
          "dart",
          ["pub", "get"],
          workingDirectory: projectRoot,
          runInShell: true,
        ),
      );

      // 5. Setup clean main.dart
      _setupCleanMain(projectRoot, appName);

      // 6. Setup clean widget_test.dart
      _setupCleanTest(projectRoot, appName);

      // 7. Final Self-Healing / Verification
      await _selfHealProject(projectRoot, useProviderApi);
    } finally {
      Directory.current = originalCwd;
    }

    stdout.writeln("");
    stdout.writeln(
      _tr(
        en: "Running omega validate (OmegaConfig + cold start checks)...",
        es: "Ejecutando omega validate (OmegaConfig + comprobaciones de arranque)...",
      ),
    );
    OmegaValidateCommand.validateProjectRoot(projectRoot);

    stdout.writeln("\n✨ ${_tr(en: "App ready!", es: "App lista!")}");
    stdout.writeln("  cd $appName");
    stdout.writeln("  flutter run");
  }

  static void _setupCleanMain(String root, String appName) {
    // Usamos el directorio actual para mayor robustez en la ruta
    final libDir = Directory(
      "${Directory.current.path}${Platform.pathSeparator}lib",
    );
    if (!libDir.existsSync()) libDir.createSync(recursive: true);
    final mainFile = File("${libDir.path}${Platform.pathSeparator}main.dart");

    if (mainFile.existsSync()) mainFile.deleteSync();

    mainFile.writeAsStringSync('''
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'omega/omega_setup.dart';

void main() async {
  if (kIsWeb && Uri.base.queryParameters['omega_inspector'] == '1') {
    runApp(
      MaterialApp(
        title: 'Omega Inspector',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
        home: const OmegaInspectorReceiver(),
      ),
    );
    return;
  }

  final runtime = OmegaRuntime.bootstrap(createOmegaConfig);
  if (kDebugMode && !kIsWeb) {
    await OmegaInspectorServer.start(runtime.channel, runtime.flowManager);
  }

  runApp(
    OmegaScope(
      channel: runtime.channel,
      flowManager: runtime.flowManager,
      initialFlowId: runtime.initialFlowId,
      initialNavigationIntent: runtime.initialNavigationIntent,
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
      home: OmegaInitialRoute(
        child: const RootHandler(showInspector: true),
      ),
    );
  }
}
''');
    _formatFile(mainFile.path);
  }

  static void _setupCleanTest(String root, String appName) {
    // Usamos el directorio actual si estamos ya dentro del proyecto,
    // o el root proporcionado. Aseguramos que la ruta sea robusta.
    final testDir = Directory(
      "${Directory.current.path}${Platform.pathSeparator}test",
    );
    if (!testDir.existsSync()) {
      testDir.createSync(recursive: true);
    }
    final testFile = File(
      "${testDir.path}${Platform.pathSeparator}widget_test.dart",
    );

    // Forzamos la sobreescritura completa
    if (testFile.existsSync()) {
      testFile.deleteSync();
    }

    testFile.writeAsStringSync('''
import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';
import 'package:$appName/main.dart';
import 'package:$appName/omega/omega_setup.dart';

void main() {
  testWidgets('Omega smoke test', (WidgetTester tester) async {
    // This is a minimal smoke test for a project generated by Omega.
    // It boots the runtime and verifies the app can be pumped.
    final runtime = OmegaRuntime.bootstrap(
      (OmegaChannel channel) => createOmegaConfig(channel),
    );

    await tester.pumpWidget(
      OmegaScope(
        channel: runtime.channel,
        flowManager: runtime.flowManager,
        initialFlowId: runtime.initialFlowId,
        initialNavigationIntent: runtime.initialNavigationIntent,
        child: OmegaApp(navigator: runtime.navigator),
      ),
    );

    expect(find.byType(OmegaApp), findsOneWidget);
  });
}
''');
    _formatFile(testFile.path);
  }

  /// Full stdout+stderr from `dart analyze --format=machine`, split into non-empty lines.
  static List<String> _analyzeMachineLines(ProcessResult r) {
    final combined = "${r.stdout}\n${r.stderr}";
    return combined
        .split("\n")
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// Severity `ERROR` lines only (not WARNING/INFO). `dart analyze` can exit != 0 with warnings only.
  static List<String> _extractAnalyzerErrors(Iterable<String> lines) =>
      lines.where((l) => l.startsWith("ERROR|")).toList();

  static Future<ProcessResult> _dartAnalyzeMachine(String root) => Process.run(
    "dart",
    ["analyze", "--format=machine"],
    workingDirectory: root,
    runInShell: true,
  );

  static void _printMachineErrors(Iterable<String> errorLines, {int max = 12}) {
    for (final e in errorLines.take(max)) {
      final parts = e.split("|");
      if (parts.length > 7) {
        stdout.writeln("  - ${parts[3]}:${parts[4]} -> ${parts[7]}");
      } else {
        stdout.writeln("  - $e");
      }
    }
  }

  static void _writeAiFixedFiles(String root, Map<String, String> fixedFiles) {
    final rootNorm = root.replaceAll("\\", "/");
    for (final entry in fixedFiles.entries) {
      File targetFile;
      if (File(entry.key).isAbsolute) {
        targetFile = File(entry.key);
      } else {
        targetFile = File(
          "$root${Platform.pathSeparator}${entry.key.replaceAll("/", Platform.pathSeparator)}",
        );
      }
      var body = entry.value;
      if (targetFile.path.endsWith(".dart")) {
        body = _omegaDedupeDuplicateImportLines(body);
      }
      targetFile.writeAsStringSync(body);
      _formatFile(targetFile.path);
      final rel = targetFile.absolute.path.replaceAll("\\", "/");
      final short = rel.startsWith(rootNorm)
          ? rel.substring(rootNorm.length).replaceFirst(RegExp(r"^/"), "")
          : entry.key;
      stdout.writeln("  ✨ ${_tr(en: "Updated", es: "Actualizado")}: $short");
    }
  }

  static Future<void> _selfHealProject(String root, bool useAi) async {
    stdout.writeln(
      "\n🔍 ${_tr(en: "Verifying project health...", es: "Verificando salud del proyecto...")}",
    );

    // 1. Pub get
    await runWithProgress<ProcessResult>(
      _tr(en: "Running pub get", es: "Ejecutando pub get"),
      () => Process.run(
        "dart",
        ["pub", "get"],
        workingDirectory: root,
        runInShell: true,
      ),
    );

    // 2. Analyze (stdout + stderr: some SDK versions differ)
    final analyzeRes = await runWithProgress<ProcessResult>(
      _tr(
        en: "Analyzing project for errors",
        es: "Analizando proyecto en busca de errores",
      ),
      () => _dartAnalyzeMachine(root),
    );

    if (analyzeRes.exitCode == 0) {
      stdout.writeln(
        "✅ ${_tr(en: "Project is clean and compiles.", es: "El proyecto está limpio y compila.")}",
      );
      return;
    }

    final lines = _analyzeMachineLines(analyzeRes);
    final errors = _extractAnalyzerErrors(lines);

    if (errors.isEmpty) {
      final warnCount = lines.where((l) => l.startsWith("WARNING|")).length;
      stdout.writeln(
        "✅ ${_tr(en: "No analyzer errors (only warnings or infos; exit code ${analyzeRes.exitCode}).", es: "Sin errores del analizador (solo advertencias o infos; código de salida ${analyzeRes.exitCode}).")}",
      );
      if (warnCount > 0) {
        stdout.writeln(
          "   ${_tr(en: "Warnings: $warnCount", es: "Advertencias: $warnCount")}",
        );
      }
      return;
    }

    stdout.writeln(
      "⚠️ ${_tr(en: "Found ${errors.length} analyzer error(s). Attempting fix...", es: "Se encontraron ${errors.length} error(es) del analizador. Intentando corrección...")}",
    );

    var workingErrors = errors;
    if (_omegaTryDeterministicOmegaSetupHeal(root)) {
      stdout.writeln(
        "⚡ ${_tr(en: "Applied deterministic fixes to lib/omega/omega_setup.dart; re-running dart analyze.", es: "Correcciones deterministas en lib/omega/omega_setup.dart; ejecutando dart analyze de nuevo.")}",
      );
      final afterDet = await runWithProgress<ProcessResult>(
        _tr(en: "Re-analyzing after setup fixes", es: "Re-analisis tras correcciones de setup"),
        () => _dartAnalyzeMachine(root),
      );
      if (afterDet.exitCode == 0) {
        stdout.writeln(
          "✅ ${_tr(en: "Deterministic setup fixes cleared all analyzer errors.", es: "Las correcciones deterministas en omega_setup eliminaron todos los errores del analizador.")}",
        );
        return;
      }
      final detLines = _analyzeMachineLines(afterDet);
      workingErrors = _extractAnalyzerErrors(detLines);
      if (workingErrors.isEmpty) {
        stdout.writeln(
          "✅ ${_tr(en: "No analyzer errors after deterministic fixes (non-zero exit may be warnings only).", es: "Sin errores del analizador tras correcciones deterministas (código distinto de 0 puede ser advertencias).")}",
        );
        return;
      }
      stdout.writeln(
        "⚠️ ${_tr(en: "${workingErrors.length} analyzer error(s) remain after deterministic fixes.", es: "Quedan ${workingErrors.length} error(es) del analizador tras las correcciones deterministas.")}",
      );
    }

    final env = Platform.environment;
    final aiEnabled = OmegaAiCommand._readBool(
      env["OMEGA_AI_ENABLED"],
      defaultValue: false,
    );

    if (!useAi || !aiEnabled) {
      stdout.writeln(
        "❌ ${_tr(en: "Omi cannot heal this project (assistant disabled). Fix manually:", es: "Omi no puede sanar el proyecto (asistente desactivado). Corrige manualmente:")}",
      );
      _printMachineErrors(workingErrors);
      return;
    }

    final providerLc = (env["OMEGA_AI_PROVIDER"] ?? "").trim().toLowerCase();
    if (providerLc != "openai" && providerLc != "gemini") {
      stdout.writeln(
        "❌ ${_tr(en: "Omi self-heal requires OMEGA_AI_PROVIDER=openai or gemini.", es: "La sanación con Omi requiere OMEGA_AI_PROVIDER=openai o gemini.")}",
      );
      _printMachineErrors(workingErrors);
      return;
    }

    if (_OmegaAiRemote.effectiveApiKey().isEmpty) {
      stdout.writeln(
        "❌ ${_tr(en: "No API key for the assistant (OMEGA_AI_API_KEY, or OMEGA_AI_GEMINI_API_KEY when using gemini). Omi cannot auto-fix.", es: "Falta clave API del asistente (OMEGA_AI_API_KEY, u OMEGA_AI_GEMINI_API_KEY con gemini). Omi no puede corregir solo.")}",
      );
      _printMachineErrors(workingErrors);
      return;
    }

    final maxPasses = int.tryParse(env["OMEGA_AI_HEAL_MAX_PASSES"] ?? "") ?? 3;
    var currentErrors = workingErrors;

    for (var pass = 0; pass < maxPasses; pass++) {
      if (pass > 0) {
        stdout.writeln(
          "🔁 ${_tr(en: "Re-check: errors remain — Omi tries another pass", es: "Revisión: aún hay errores — Omi intenta otra pasada")} (${pass + 1}/$maxPasses)...",
        );
      }

      final pubAdded = await _omegaHealTryPubAddMissingPackages(
        root,
        currentErrors,
      );
      if (pubAdded) {
        await runWithProgress<ProcessResult>(
          _tr(
            en: "Running pub get after heal pub add",
            es: "Ejecutando pub get tras pub add en sanación",
          ),
          () => Process.run(
            "dart",
            ["pub", "get"],
            workingDirectory: root,
            runInShell: true,
          ),
        );
        final afterPub = await _dartAnalyzeMachine(root);
        if (afterPub.exitCode == 0) {
          stdout.writeln(
            "✅ ${_tr(en: "Project healed successfully (pub add cleared errors)!", es: "¡Proyecto sanado (pub add resolvió errores)!")}",
          );
          return;
        }
        currentErrors = _extractAnalyzerErrors(_analyzeMachineLines(afterPub));
        if (currentErrors.isEmpty) {
          stdout.writeln(
            "✅ ${_tr(en: "No analyzer errors after pub add (non-zero exit may be warnings only).", es: "Sin errores del analizador tras pub add (código distinto de 0 puede ser advertencias).")}",
          );
          return;
        }
      }

      final fixedFiles = await runWithProgress<Map<String, String>?>(
        _tr(
          en: "Omi is fixing analyzer / compile errors",
          es: "Omi corrige errores del analizador / compilación",
        ),
        () => _providerFixErrors(root, currentErrors),
      );

      if (fixedFiles == null || fixedFiles.isEmpty) {
        stdout.writeln(
          "❌ ${_tr(en: "Omi got no usable fixes from the assistant.", es: "Omi no recibió correcciones utilizables del asistente.")}",
        );
        _printMachineErrors(currentErrors);
        return;
      }

      stdout.writeln(
        "🔍 ${_tr(en: "Applying fixes...", es: "Aplicando correcciones...")}",
      );
      _writeAiFixedFiles(root, fixedFiles);

      stdout.writeln(
        "🔍 ${_tr(en: "Re-verifying with dart analyze...", es: "Re-verificando con dart analyze...")}",
      );
      final secondAnalyze = await _dartAnalyzeMachine(root);

      if (secondAnalyze.exitCode == 0) {
        stdout.writeln(
          "✅ ${_tr(en: "Project healed successfully!", es: "¡Proyecto sanado correctamente!")}",
        );
        return;
      }

      final afterLines = _analyzeMachineLines(secondAnalyze);
      currentErrors = _extractAnalyzerErrors(afterLines);
      if (currentErrors.isEmpty) {
        stdout.writeln(
          "✅ ${_tr(en: "No analyzer errors after fix (non-zero exit may be warnings only).", es: "Sin errores del analizador tras la corrección (código distinto de 0 puede ser por advertencias).")}",
        );
        return;
      }
    }

    stdout.writeln(
      "❌ ${_tr(en: "Omi could not clear all errors after $maxPasses pass(es). Remaining:", es: "Omi no eliminó todos los errores tras $maxPasses pase(s). Restantes:")}",
    );
    _printMachineErrors(currentErrors);
  }

  /// `dart analyze --format=machine` paths may be absolute (Windows) or `lib/...`.
  static String _normalizeAnalyzerPathToProjectRelative(
    String pathFromError,
    String root,
  ) {
    var p = pathFromError.replaceAll("\\", "/");
    final r = root.replaceAll("\\", "/");
    final rLower = r.toLowerCase();
    final pLower = p.toLowerCase();
    if (pLower.startsWith(rLower)) {
      return p.substring(r.length).replaceFirst(RegExp(r"^/"), "");
    }
    final idx = p.indexOf("/lib/");
    if (idx >= 0) {
      return p.substring(idx + 1);
    }
    final tIdx = p.indexOf("/test/");
    if (tIdx >= 0) {
      return p.substring(tIdx + 1);
    }
    return p;
  }

  /// Ensures `lib/<module>/<module>_events.dart` is sent to the heal model when any error
  /// lives under `lib/<module>/` — fixes "isn't a type" for ViewState / typed events defined there.
  static void _omegaHealIncludeModuleEventsFiles(
    String root,
    List<String> errors,
    Set<String> filesToFix,
  ) {
    final seenFolders = <String>{};
    for (final errLine in errors) {
      final parts = errLine.split("|");
      if (parts.length <= 4) continue;
      final rel = _normalizeAnalyzerPathToProjectRelative(parts[3], root);
      if (!rel.startsWith("lib/")) continue;
      final segs = rel.split("/");
      if (segs.length < 3) continue;
      final folder = segs[1];
      if (folder == "omega") continue;
      if (!seenFolders.add(folder)) continue;
      final eventsRel = "lib/$folder/${folder}_events.dart";
      final fsPath =
          "$root${Platform.pathSeparator}${eventsRel.replaceAll("/", Platform.pathSeparator)}";
      if (File(fsPath).existsSync()) {
        filesToFix.add(eventsRel);
      }
    }
  }

  /// Parses analyzer output for missing `package:...` URIs and runs `dart pub add` when enabled.
  /// Returns true if any package was added (caller should run pub get + re-analyze).
  static Future<bool> _omegaHealTryPubAddMissingPackages(
    String root,
    List<String> errors,
  ) async {
    final allowPubAdd = OmegaAiCommand._readBool(
      Platform.environment["OMEGA_AI_HEAL_PUB_ADD"],
      defaultValue: true,
    );
    if (!allowPubAdd) return false;

    final pubFile = File("$root${Platform.pathSeparator}pubspec.yaml");
    if (!pubFile.existsSync()) return false;

    String pubText;
    try {
      pubText = pubFile.readAsStringSync();
    } catch (_) {
      return false;
    }
    final existing = _parsePubspecDependencyNames(
      pubText,
    ).map((n) => n.toLowerCase()).toSet();

    final toAdd = <String>{};
    final uriRe = RegExp(r"package:([a-zA-Z0-9_]+)/");
    for (final e in errors) {
      final lower = e.toLowerCase();
      if (!lower.contains("target of uri doesn't exist") &&
          !lower.contains("couldn't find package") &&
          !lower.contains("uri hasn't been generated") &&
          !lower.contains("uri has not been generated")) {
        continue;
      }
      for (final m in uriRe.allMatches(e)) {
        final pkg = m.group(1)!;
        if (pkg == "flutter" ||
            pkg == "sky_engine" ||
            pkg == "omega_architecture") {
          continue;
        }
        if (existing.contains(pkg.toLowerCase())) continue;
        toAdd.add(pkg);
      }
    }

    if (toAdd.isEmpty) return false;

    var any = false;
    for (final pkg in toAdd) {
      stdout.writeln(
        "📦 ${_tr(en: "Heal: adding missing dependency: $pkg", es: "Sanación: agregando dependencia faltante: $pkg")}",
      );
      final res = await Process.run(
        "dart",
        ["pub", "add", pkg],
        workingDirectory: root,
        runInShell: true,
      );
      if (res.exitCode == 0) {
        any = true;
        existing.add(pkg.toLowerCase());
      } else {
        stdout.writeln(
          "   ${_tr(en: "pub add failed for $pkg", es: "pub add falló para $pkg")}: ${res.stderr}",
        );
      }
    }
    return any;
  }

  /// Dependency names under `dependencies:` for heal prompts (no version resolution).
  static List<String> _parsePubspecDependencyNames(String yamlText) {
    final lines = yamlText.split("\n");
    final names = <String>[];
    var inDeps = false;
    for (final line in lines) {
      if (line.startsWith("dependencies:")) {
        inDeps = true;
        continue;
      }
      if (!inDeps) continue;
      final trimmedLeft = line.trimLeft();
      if (trimmedLeft.isEmpty || trimmedLeft.startsWith("#")) continue;
      if (!line.startsWith(" ")) {
        break;
      }
      final m = RegExp(r"^\s{2}([a-zA-Z0-9_]+)\s*:").firstMatch(line);
      if (m != null) {
        names.add(m.group(1)!);
      }
    }
    return names;
  }

  static String _omegaHealPubspecDependenciesBlock(String root) {
    final f = File("$root${Platform.pathSeparator}pubspec.yaml");
    if (!f.existsSync()) return "";
    try {
      final names = _parsePubspecDependencyNames(f.readAsStringSync());
      if (names.isEmpty) return "";
      return "\nPROJECT PUBSPEC dependencies (only these packages may be imported besides Dart/Flutter SDK; if code uses equatable/intl/etc. and they are absent, remove those imports and rewrite):\n${names.join(", ")}\n";
    } catch (_) {
      return "";
    }
  }

  static Future<Map<String, String>?> _providerFixErrors(
    String root,
    List<String> errors,
  ) async {
    if (!_OmegaAiRemote.canCallRemote()) return null;

    final errorContext = StringBuffer();
    final filesToFix = <String>{};
    final errCountByFile = <String, int>{};
    final errDetailByFile = <String, List<String>>{};

    for (final errLine in errors) {
      final parts = errLine.split("|");
      if (parts.length > 7) {
        final rel = _normalizeAnalyzerPathToProjectRelative(parts[3], root);
        final detail = "L${parts[4]}: ${parts[7]}";
        if (rel.startsWith("lib/") || rel.startsWith("test/")) {
          filesToFix.add(rel);
          errCountByFile[rel] = (errCountByFile[rel] ?? 0) + 1;
          errDetailByFile.putIfAbsent(rel, () => []).add(detail);
        }
      }
    }

    if (filesToFix.isEmpty) return null;

    _omegaHealIncludeModuleEventsFiles(root, errors, filesToFix);

    final envHeal = Platform.environment;
    final maxFiles =
        int.tryParse(envHeal["OMEGA_AI_HEAL_MAX_FILES"] ?? "")?.clamp(4, 60) ??
        28;
    final maxChars =
        int.tryParse(envHeal["OMEGA_AI_HEAL_MAX_CONTEXT_CHARS"] ?? "") ??
        90000;

    final sortedRel = filesToFix.toList()
      ..sort((a, b) {
        final ca = errCountByFile[a] ?? 0;
        final cb = errCountByFile[b] ?? 0;
        if (cb != ca) return cb.compareTo(ca);
        return a.compareTo(b);
      });

    errorContext.writeln(
      "SUMMARY (by file, most errors first): ${sortedRel.map((p) => '$p(${errCountByFile[p] ?? 0})').join(', ')}",
    );
    for (final rel in sortedRel.take(12)) {
      final lines = errDetailByFile[rel];
      if (lines == null || lines.isEmpty) continue;
      errorContext.writeln("— $rel:");
      for (final d in lines.take(10)) {
        errorContext.writeln("  $d");
      }
    }

    final filesContent = StringBuffer();
    for (final relPosix in sortedRel.take(maxFiles)) {
      if (filesContent.length > maxChars) break;
      final localPath =
          "$root${Platform.pathSeparator}${relPosix.replaceAll("/", Platform.pathSeparator)}";
      final file = File(localPath);
      if (file.existsSync()) {
        filesContent.writeln("--- FILE: $relPosix ---");
        filesContent.writeln(file.readAsStringSync());
      }
    }

    final healGroundTruth =
        await OmegaAiCommand._omegaAiBuildPackageGroundTruthBlock(
          pageOnly: false,
          compactForHeal: true,
        );
    if (healGroundTruth.isNotEmpty) {
      stdout.writeln(
        "  ${_tr(en: "Omi heal: attached package examples (${healGroundTruth.length} chars)", es: "Sanación Omi: ejemplos del paquete (${healGroundTruth.length} caracteres)")}",
      );
    }
    final healContextBlock = healGroundTruth.isEmpty
        ? ""
        : "\n$healGroundTruth\n";

    final setupHealPath =
        "$root${Platform.pathSeparator}lib${Platform.pathSeparator}omega${Platform.pathSeparator}omega_setup.dart";
    final setupHealFile = File(setupHealPath);
    var routeAgentHealHints = "";
    if (setupHealFile.existsSync()) {
      try {
        final mis = OmegaValidateCommand.collectRouteAgentMismatches(
          root,
          setupHealFile.readAsStringSync(),
        );
        if (mis.isNotEmpty) {
          routeAgentHealHints =
              "\nVALIDATOR (lib/**/*_page.dart requires agent) — apply to omega_setup.dart:\n"
              "${mis.map((m) => "- $m").join("\n")}\n";
        }
      } catch (_) {}
    }
    final agentParamError = errors.any(
      (e) =>
          e.contains("named parameter 'agent'") ||
          e.contains('named parameter "agent"') ||
          e.contains("parameter 'agent' is required"),
    );
    final omegaSetupAgentHealRecipe = agentParamError
        ? """

HEAL RECIPE — analyzer says missing required named parameter `agent` (usually in lib/omega/omega_setup.dart):
- A *Page widget constructor has `required SomeAgent agent`. You MUST NOT use `const ThatPage()` or `ThatPage()` without arguments.
- In createOmegaConfig(OmegaChannel channel): (1) import the agent Dart file; (2) add `final myModuleAgent = MyModuleAgent(channel);` or `MyModuleAgent(channel: channel);` if ctor uses named channel (read *_agent.dart); (3) put `myModuleAgent` in `agents: <OmegaAgent>[..., myModuleAgent]` once; (4) set route `builder: (context) => ThatPage(agent: myModuleAgent)` (same variable reference). Match Page class name ↔ Agent class name (e.g. ProductCatalogPage ↔ ProductCatalogAgent).
- If *Module*Flow has `required this.agent` / passes agent to [OmegaFlow.uiScopeAgent]: use the SAME `myModuleAgent` variable in `flows: [..., MyModuleFlow(channel: channel, agent: myModuleAgent)]` — do not omit `myModuleAgent` from the `agents:` list.
"""
        : "";

    final flowContextFakeApiError = errors.any(
      (e) =>
          e.contains("getAgentViewState") ||
          e.contains("isn't defined for the type 'OmegaFlowContext'"),
    );
    final omegaFlowContextHealRecipe = flowContextFakeApiError
        ? """

HEAL RECIPE — OmegaFlowContext has no getAgentViewState (and no agent API):
- Replace with data from ctx.intent: use flowManager.handleIntent(OmegaIntent.fromName(UserAuthIntent.start, payload: UserAuthCredentials(email: e, password: p))) from the UI, then in onIntent: final creds = ctx.intent?.payloadAs<UserAuthCredentials>(); channel.emitTyped(UserAuthRequestedEvent(email: creds?.email ?? '', password: creds?.password ?? '')); OR store fields in ctx.memory on prior intents.
- Compare intents with intent?.name == UserAuthIntent.start.name, not intent == UserAuthIntent.start.
"""
        : "";

    final omegaSetupUndefinedFlowAgentError = errors.any((e) {
      if (!e.contains("omega_setup.dart")) return false;
      if (!e.contains("isn't defined") && !e.contains("undefined_function")) {
        return false;
      }
      return e.contains("Flow") ||
          e.contains("Agent") ||
          RegExp(r"'\w+Flow'").hasMatch(e) ||
          RegExp(r"'\w+Agent'").hasMatch(e);
    });
    final omegaSetupFlowAgentImportRecipe = omegaSetupUndefinedFlowAgentError
        ? """

HEAL RECIPE — lib/omega/omega_setup.dart: "The function 'SomeFlow' isn't defined" / undefined Flow or Agent (InvalidType):
- Flow and Agent are CLASSES in other files — Dart reports "function isn't defined" when the import is missing or the name is wrong.
- Add imports at the top (path from lib/omega/omega_setup.dart): e.g. module `news` in lib/news/ → `import '../news/news_flow.dart';` … OR `import 'package:THE_EXACT_PUBSPEC_NAME/news/news_flow.dart';` where THE_EXACT_PUBSPEC_NAME is the `name:` field from this project's pubspec.yaml (see APP PUBSPEC block in the heal prompt when present — never invent delivery_app-style names).
- In `flows: <OmegaFlow>[...]` each entry must be a CONSTRUCTOR CALL: `NewsFlow(channel)` or `NewsFlow(channel.namespace('news'))` — exactly matching the constructor in news_flow.dart. NEVER put bare `NewsFlow` without `(...)` in the list; NEVER call Flow like a top-level function.
- In `agents: <OmegaAgent>[...]` same: `NewsAgent(channel)` (or named args per *_agent.dart).
- If the symbol name does not match the class in the file (e.g. NewsFlow vs NewFlow), rename to match the class declared in *_flow.dart.
"""
        : "";

    final navigationEnumHealError = errors.any(
      (e) =>
          e.contains("navigationIntent") ||
          e.contains("constant named 'navigation") ||
          (e.contains("There's no constant named") &&
              e.contains("navigation") &&
              e.contains("Event")),
    );
    final navigationEnumHealRecipe = navigationEnumHealError
        ? """

HEAL RECIPE — navigationIntent missing on module Event enum:
- OmegaEvent.fromName(??? , payload: OmegaIntent.fromName(...)) for [OmegaNavigator] requires an OmegaEventName whose string is exactly navigation.intent. Add member `navigationIntent` with `OmegaEventNameDottedCamel` on your *Event enum, OR import `omega/app_semantics.dart` and use `AppEvent.navigationIntent`. Inner payload: real enum case (e.g. UserAuthIntent.navigateRegister) whose `.name` matches the route (navigate.*).
"""
        : "";

    final undefinedEventEnumHealError = errors.any(
      (e) =>
          (e.contains("undefined_enum_constant") ||
              e.contains("There's no constant named")) &&
          (e.contains("Event") || e.contains("_event")),
    );
    final undefinedEventEnumHealRecipe = undefinedEventEnumHealError
        ? """

HEAL RECIPE — no constant named 'X' in '*Event' (or agent.emit misuse):
- Every MyModuleEvent.foo must exist on the enum in *_events.dart*. Add the case with the correct wire string, OR change the UI/agent to use existing cases (requested, succeeded, failed, navigationIntent).
- OmegaAgent.emit first parameter is String: use emit(MyEvent.requested.name, payload: ...) NOT emit(MyEvent.requested) and NOT emit(MyEvent.inventedCase). From pages, prefer scope.channel.emit(OmegaEvent.fromName(MyEvent.requested, payload: ...)) so behavior rules using ctx.event?.name match.
"""
        : "";

    final pubspecDepsHint = _omegaHealPubspecDependenciesBlock(root);
    var appPubspecHealHint = "";
    try {
      final n = getPackageName(root);
      if (n.isNotEmpty) {
        appPubspecHealHint =
            "\nAPP PUBSPEC `name:` for this project: **$n** — any `import 'package:.../omega/` or `package:.../<feature>/` under lib/ MUST use `package:$n/` exactly. Do not invent a package id from the product name (e.g. delivery_app).\n";
      }
    } catch (_) {}

    final missingOptionalPackageHealError = errors.any((e) {
      final s = e.toLowerCase();
      return (s.contains("target of uri doesn't exist") ||
              s.contains("couldn't find package")) &&
          (s.contains("equatable") ||
              s.contains("intl") ||
              s.contains("intl.dart"));
    });
    final inventedOmegaViewStateHealError = errors.any(
      (e) =>
          e.contains("OmegaViewState") ||
          (e.contains("can only extend other classes") &&
              e.contains("_events.dart")) ||
          (e.contains("can only mix in mixins and classes") &&
              e.contains("_events.dart")),
    );
    final viewStateStreamHealError = errors.any(
      (e) => e.contains("viewStateStream") && e.contains("isn't defined"),
    );
    final optionalPackagesAndStateHealRecipe =
        (missingOptionalPackageHealError ||
            inventedOmegaViewStateHealError ||
            viewStateStreamHealError)
        ? """

HEAL RECIPE — optional pub packages + invented Omega types (common AI mistakes):
- package:equatable / Equatable: If URI missing or mixin errors in *_events.dart*, REMOVE `import 'package:equatable/equatable.dart';`, remove `extends Equatable`, `with EquatableMixin`, `@immutable` workarounds. Use plain `class MyViewState { final ...; const MyViewState(...); copyWith(...) }` like the omega CLI template — no third-party equality in events files.
- package:intl / DateFormat: If URI missing, REMOVE intl import. Replace DateFormat with simple formatting: e.g. `\${date.year}-\${date.month.toString().padLeft(2,'0')}-\${date.day.toString().padLeft(2,'0')}` or `date.toLocal().toString()` — do NOT add intl to pubspec in JSON output (user may add it later manually).
- OmegaViewState: type DOES NOT EXIST in omega_architecture. Replace `class X extends OmegaViewState` with plain `class X` (module view state) matching OmegaStatefulAgent<MyViewState>.
- viewStateStream undefined: use `stateStream` on OmegaStatefulAgent (same stream). Replace `.viewStateStream` → `.stateStream`. Ensure *Agent extends OmegaStatefulAgent<TState>.
"""
        : "";

    final missingModuleTypesHealError = errors.any((e) {
      final viewOrEvent =
          e.contains("ViewState") ||
          e.contains("ImageCaptured") ||
          e.contains("ImageProcessed") ||
          RegExp(r"The name '\w+Event'").hasMatch(e) ||
          RegExp(r"'[^']+Event' isn't a type").hasMatch(e);
      if (!viewOrEvent) return false;
      return e.contains("isn't a type") ||
          e.contains("Undefined name") ||
          e.contains("isn't defined for the type");
    });
    final missingModuleTypesHealRecipe = missingModuleTypesHealError
        ? """

HEAL RECIPE — missing module ViewState / typed events (analyzer: name isn't a type / isn't a type argument):
- The module’s `lib/<folder>/<folder>_events.dart` is the single place to define: (1) `enum …Intent` / `enum …Event` implementing OmegaIntentName / OmegaEventName, (2) **plain** `class …ViewState` with every field the Page and Agent reference (`isLoading`, `error`, `imagePath`, `recognitionResult`, …), `copyWith`, and `static const idle = …ViewState(…);` for `OmegaStatefulAgent` initialState — NEVER extend OmegaViewState (type does not exist).
- For each missing `…ImageCapturedEvent` / `…ProcessedEvent` / similar: add `class … implements OmegaTypedEvent { const …({…}); @override String get name => …Event.<matchingEnum>.name; … }` and add the enum case to `…Event` if needed.
- In *_agent.dart*: **never** write `this.SomeEvent(...)` or `agent.SomeEvent(...)` as if it were a method — the error "The method 'SomeEvent' isn't defined for the type '…Agent'" means that mistake. Use `channel.emitTyped(SomeEvent(...))` or `channel.emit(OmegaEvent.fromName(…Event.case, payload: …))`.
- Wire imports: *_agent.dart*, *_behavior.dart*, *_flow.dart*, *_page.dart* must `import '…/<folder>_events.dart'` (correct relative path). Return the FULL updated *_events.dart* in JSON whenever you add types.
"""
        : "";

    final fakePayloadInterfaceHealError = errors.any(
      (e) =>
          e.contains("OmegaIntentPayload") || e.contains("OmegaEventPayload"),
    );
    final fakePayloadInterfaceHealRecipe = fakePayloadInterfaceHealError
        ? """

HEAL RECIPE — invented Omega “payload” marker types (undefined class / bad implements):
- Remove `implements OmegaIntentPayload`, `implements OmegaEventPayload`, or both from any DTO used as `payload:` on `OmegaIntent.fromName` / `OmegaEvent.fromName`. **Those types are not in** package:omega_architecture — only **extension** APIs (`payloadAs<T>()`) exist on [OmegaIntent] / [OmegaEvent].
- Keep the class as plain `final` fields + const ctor; flows use `ctx.intent?.payloadAs<YourDto>()` / `ctx.event?.payloadAs<YourDto>()`.
"""
        : "";

    final nullableReceiverHealError = errors.any(
      (e) =>
          e.contains("can't be unconditionally accessed") ||
          e.contains("unchecked_use_of_nullable_value"),
    );
    final nullableReceiverHealRecipe = nullableReceiverHealError
        ? """

HEAL RECIPE — nullable state in UI (`can't be unconditionally accessed` / unchecked_use_of_nullable_value):
- In `OmegaAgentBuilder` / `StreamBuilder` callbacks, if `state` is `T?`, first guard: `if (state == null) return const SizedBox.shrink();` (or `CircularProgressIndicator`), then use `state!` or `final s = state!;` and only then read `s.isLoading`, `s.error`, etc.
"""
        : "";

    final prompt =
        """
You fix a Flutter app that uses the published package omega_architecture (not local lib copies).

${OmegaAiCommand._omegaAiConceptualArchitecture}

${OmegaAiCommand._omegaAiOmegaSourceOfTruth}
HEAL: change only what the analyzer and the sources above require — do not refactor toward invented APIs.
HEAL — phased mindset: prefer the smallest coherent fix per file (imports / missing types / one wiring bug) instead of rewriting large unrelated regions “all at once” unless errors demand it.

ANALYZER ERRORS:
${errorContext.toString()}

AFFECTED FILE CONTENTS:
${filesContent.toString()}
$routeAgentHealHints
$omegaSetupAgentHealRecipe
$omegaFlowContextHealRecipe
$omegaSetupFlowAgentImportRecipe
$navigationEnumHealRecipe
$undefinedEventEnumHealRecipe
$optionalPackagesAndStateHealRecipe
$missingModuleTypesHealRecipe
$fakePayloadInterfaceHealRecipe
$nullableReceiverHealRecipe
$pubspecDepsHint$appPubspecHealHint
HEAL — PUB: The CLI may run `dart pub add <pkg>` before this call when analyzer reports missing package: URIs (unless OMEGA_AI_HEAL_PUB_ADD=false). After that, PROJECT PUBSPEC lists those packages — you MAY import them. Prefer removing unused imports over leaving broken URIs.
$healContextBlock
CRITICAL — IMPORTS (this fixes Undefined class OmegaAgent, OmegaEventBus, OmegaFlow, OmegaIntentName, etc.):
- LANGUAGE: output valid Dart (Flutter) only — never Kotlin, Swift, TypeScript, or pseudocode in file bodies.
- Any Dart file under lib/ that uses Omega types MUST start with:
  import 'package:omega_architecture/omega_architecture.dart';
- Screens also need: import 'package:flutter/material.dart';
- Sibling module files: import 'name_events.dart' or import '../name_events.dart' from ui/
- If ui/*_page.dart declares a field or parameter of type MyModuleAgent (e.g. OrderManagementAgent), it MUST import that class: import '../my_module_agent.dart'; (same folder depth as events — mirror example/lib/auth/ui/auth_page.dart which imports ../auth_agent.dart).
- NEVER use: package:omega_architecture/omega/... internal paths.
- If a file has ZERO omega import but uses Omega*, add the package import as the first import.
- Do NOT add imports for package:equatable, package:intl, or other packages unless they appear under dependencies in the PROJECT PUBSPEC block below. Prefer deleting those imports and rewriting code with plain Dart.
- NEVER duplicate the same import line (e.g. two identical `import 'package:apponly/foo/ui/foo_page.dart';`). In lib/omega/omega_setup.dart and every file: at most ONE line per exact import URI + modifiers (show/hide/deferred). Re-read the file you output and remove repeats.

RULES:
1. Return ONE JSON object: keys = project-relative paths with forward slashes (e.g. "lib/omega/omega_setup.dart"), values = FULL fixed file content as strings.
2. Include every file you changed; you may include only files that need edits.
3. Preserve public API names (classes, flow ids) unless the error requires a fix.
4. omega_setup.dart: if you output it, ensure **no duplicate** `OmegaRoute(id: 'SameId', ...)` entries, **no duplicate** same agent variable in `agents:`, and **no duplicate** identical `*Flow(...)` constructor lines — keep one registration per module/route.

OMEGA API (concise — full master checklist omitted here; follow roles + rules below + PACKAGE GROUND TRUTH):
${OmegaAiCommand._omegaAiRolesFlowAgentBehavior}
${OmegaAiCommand._omegaAiHealPromptCompactOmega}
${OmegaAiCommand._omegaAiOmegaChannelEvents}
${OmegaAiCommand._omegaAiNavigationChannelEmit}
${OmegaAiCommand._omegaAiMainDartEntry}
${OmegaAiCommand._omegaAiAgentUiStateListening}
${OmegaAiCommand._omegaAiFlowActivatorAndFlowManager}
${OmegaAiCommand._omegaAiScreenEntryDataLoad}
- String literals: valid UTF-8; fix mojibake or use plain ASCII mock text where needed.

Return only JSON. No markdown fences.
""";

    const healSystem =
        "Output one JSON object only: keys = project-relative paths, values = full fixed Dart file contents. Fix Flutter + omega_architecture analyzer errors using ONLY the user message (IMPORTS, OMEGA API blocks, PACKAGE GROUND TRUTH, affected files). Do not invent Omega APIs, scope members, or package imports — mirror attached examples. Align FLOW_ID, behavior actionIds with agent switch strings, flow contracts, app_runtime_ids enums, omega_setup ctor calls and imports. package:omega_architecture where Omega types are used. No duplicate import lines. No invalid JSON string escapes (single backslash before dollar).";

    final healTimeoutSec =
        (int.tryParse(envHeal["OMEGA_AI_HEAL_TIMEOUT_SEC"] ?? "") ?? 120)
            .clamp(45, 300);

    final rawContent = await _OmegaAiRemote.completeChat(
      system: healSystem,
      user: prompt,
      temperature: 0.15,
      jsonObject: true,
      timeout: Duration(seconds: healTimeoutSec),
    );
    if (rawContent == null || rawContent.isEmpty) return null;

    try {
      final jsonText = _OmegaAiRemote.sanitizeAiJsonTextForDecode(
        _OmegaAiRemote.stripCodeFences(rawContent),
      );
      final fixedFiles = jsonDecode(jsonText);
      if (fixedFiles is! Map) return null;

      final result = <String, String>{};
      for (final entry in fixedFiles.entries) {
        final relPath = entry.key
            .toString()
            .replaceAll("\\", "/")
            .replaceFirst(RegExp(r"^/"), "");
        if (!relPath.startsWith("lib/") && !relPath.startsWith("test/")) {
          continue;
        }
        result["$root${Platform.pathSeparator}${relPath.replaceAll("/", Platform.pathSeparator)}"] =
            entry.value.toString();
      }
      return result.isEmpty ? null : result;
    } catch (e) {
      _err("Omi heal parse/IO error: $e");
      return null;
    }
  }

  static Future<List<String>?> _providerSuggestModules(
    String description,
  ) async {
    if (!_OmegaAiRemote.canCallRemote()) return null;

    const system =
        "You are Omega architecture planner. Return ONLY a comma-separated list of 2-4 core module names (PascalCase) needed for the app description. For user-facing apps, **always** include an **Auth** or **Login** module (cold start / sign-in) and a **Home** or **MainShell** module (post-login screen with global navigation to the rest of the app). No extra text.";
    final content = await _OmegaAiRemote.completeChat(
      system: system,
      user: "Description: $description",
      temperature: 0.3,
      jsonObject: false,
      timeout: const Duration(seconds: 25),
      silentErrors: true,
    );
    if (content == null || content.isEmpty) return null;
    return content
        .split(",")
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

/// Default [AppEvent] / [AppIntent] for greenfield apps (`omega init`).
String _defaultAppSemanticsDartSource() => '''
import 'package:omega_architecture/omega_architecture.dart';

/// App-wide events: camelCase members → dotted wire names ([OmegaEventNameDottedCamel]).
enum AppEvent with OmegaEventNameDottedCamel implements OmegaEventName {
  navigationIntent,
}

/// App-wide intents: e.g. [navigateLogin] → `navigate.login`, [navigateHome] → `navigate.home`.
enum AppIntent with OmegaIntentNameDottedCamel implements OmegaIntentName {
  navigateLogin,
  navigateHome,
}
''';

/// Typed [OmegaFlowId] / [OmegaAgentId] for greenfield apps (`omega init`).
/// `omega g ecosystem <Name>` appends enum members; remove the placeholder when unused.
String _defaultAppRuntimeIdsDartSource() => '''
// Typed ids for [OmegaFlow] / [OmegaAgent] `super(id: ...)`.
// `omega g ecosystem <Name>` appends cases here.
// ignore_for_file: constant_identifier_names

import 'package:omega_architecture/omega_architecture.dart';

/// Same string as each flow `super(id: ...)` (see [OmegaFlowIdEnumWire]).
enum AppFlowId with OmegaFlowIdEnumWire implements OmegaFlowId {
  /// Remove when you add real flow ids, or keep unused.
  placeholder,
}

/// Same string as each agent `super(id: ...)` (see [OmegaAgentIdEnumWire]).
enum AppAgentId with OmegaAgentIdEnumWire implements OmegaAgentId {
  placeholder,
}
''';

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

    final setupFile = File("$lib/omega/omega_setup.dart");
    final semanticsFile = File("$lib/omega/app_semantics.dart");
    final runtimeIdsFile = File("$lib/omega/app_runtime_ids.dart");

    if (setupFile.existsSync() && !force) {
      if (!semanticsFile.existsSync() || !runtimeIdsFile.existsSync()) {
        if (!semanticsFile.existsSync()) {
          semanticsFile.writeAsStringSync(_defaultAppSemanticsDartSource());
          _formatFile(semanticsFile.path);
          stdout.writeln("Created lib/omega/app_semantics.dart");
          stdout.writeln("  Path: ${_absPath(semanticsFile.path)}");
        }
        if (!runtimeIdsFile.existsSync()) {
          runtimeIdsFile.writeAsStringSync(_defaultAppRuntimeIdsDartSource());
          _formatFile(runtimeIdsFile.path);
          stdout.writeln("Created lib/omega/app_runtime_ids.dart");
          stdout.writeln("  Path: ${_absPath(runtimeIdsFile.path)}");
        }
        stdout.writeln("  Project root: ${_absPath(root)}");
        stdout.writeln(
          "  omega_setup.dart was already present; import new files as needed.",
        );
        return;
      }
      _err("omega_setup.dart already exists.");
      stdout.writeln("  Path: ${_absPath(setupFile.path)}");
      stdout.writeln("  Use --force to overwrite.");
      return;
    }

    setupFile.writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';

OmegaConfig createOmegaConfig(OmegaChannel channel) {
  return OmegaConfig(
    agents: <OmegaAgent>[],
    flows: <OmegaFlow>[],
    routes: <OmegaRoute>[],
  );
}
''');

    _formatFile(setupFile.path);

    var createdSemantics = false;
    if (!semanticsFile.existsSync()) {
      semanticsFile.writeAsStringSync(_defaultAppSemanticsDartSource());
      _formatFile(semanticsFile.path);
      createdSemantics = true;
    }

    var createdRuntimeIds = false;
    if (!runtimeIdsFile.existsSync()) {
      runtimeIdsFile.writeAsStringSync(_defaultAppRuntimeIdsDartSource());
      _formatFile(runtimeIdsFile.path);
      createdRuntimeIds = true;
    }

    stdout.writeln("Omega setup created.");
    stdout.writeln("  Project root: ${_absPath(root)}");
    stdout.writeln("  File: ${_absPath(setupFile.path)}");
    if (createdSemantics) {
      stdout.writeln("  File: ${_absPath(semanticsFile.path)}");
    } else {
      stdout.writeln(
        "  app_semantics.dart already present: ${_absPath(semanticsFile.path)}",
      );
    }
    if (createdRuntimeIds) {
      stdout.writeln("  File: ${_absPath(runtimeIdsFile.path)}");
    } else {
      stdout.writeln(
        "  app_runtime_ids.dart already present: ${_absPath(runtimeIdsFile.path)}",
      );
    }
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
      stdout.writeln(
        "  agent <Name>      Agent + behavior; merges AppAgentId in app_runtime_ids.dart",
      );
      stdout.writeln(
        "  flow <Name>       Flow only; merges AppFlowId (requires existing *_agent.dart)",
      );
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
    // Crear en la ruta donde está abierta la terminal (CWD); desde la raíz del proyecto,
    // ejecuta `cd lib` antes si quieres el módulo bajo lib/ (Omega Studio hace eso por ti).
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
    final pkg = getPackageName(root);
    final rtMember = _runtimeIdEnumMember(name);
    final idsFile = File("$root/lib/omega/app_runtime_ids.dart");
    if (!idsFile.existsSync()) {
      _err("app_runtime_ids.dart not found.");
      stdout.writeln("  Expected: ${_absPath(idsFile.path)}");
      stdout.writeln("  Run from app root: omega init");
      return;
    }

    stdout.writeln("Creating in current directory: ${_absPath(baseDir)}");
    stdout.writeln("Ecosystem path: ${_absPath(ecoPath)}");

    Directory(ecoPath).createSync(recursive: true);
    Directory("$ecoPath/ui").createSync(recursive: true);

    _mergeAppRuntimeIds(root, rtMember, includeFlow: true, includeAgent: true);

    final createdFiles = <String>[
      idsFile.path,
      _createAgent(name, ecoPath, packageName: pkg, runtimeMember: rtMember),
      _createFlow(name, ecoPath, packageName: pkg, runtimeMember: rtMember),
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
    stdout.writeln("  Updated: ${_absPath(idsFile.path)}");
  }

  /// Valid [Enum.name] for [AppFlowId]/[AppAgentId] (matches `super(id: ...)` wire).
  static String _runtimeIdEnumMember(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return 'Module';
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      final isAlnum = RegExp(r'[A-Za-z0-9]').hasMatch(c);
      if (i == 0) {
        if (c == r'$' || RegExp(r'[A-Za-z_]').hasMatch(c)) {
          buf.write(c);
        } else if (RegExp(r'[0-9]').hasMatch(c)) {
          buf.write('_');
          buf.write(c);
        } else {
          buf.write('_');
        }
      } else {
        if (isAlnum || c == r'$' || c == '_') {
          buf.write(c);
        } else {
          buf.write('_');
        }
      }
    }
    var out = buf.toString();
    if (out.isEmpty) return 'Module';
    return out;
  }

  static int? _indexOfMatchingClosingBrace(String s, int openBraceIndex) {
    var depth = 0;
    for (var i = openBraceIndex; i < s.length; i++) {
      final c = s[i];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }
    return null;
  }

  /// Inserts [member] as a new enum value if missing (body between `{` and matching `}`).
  static String _upsertEnumMember(
    String content,
    String enumHeader,
    String member,
  ) {
    final start = content.indexOf(enumHeader);
    if (start == -1) {
      return content;
    }
    final open = content.indexOf('{', start);
    if (open == -1) {
      return content;
    }
    final close = _indexOfMatchingClosingBrace(content, open);
    if (close == null) {
      return content;
    }
    final body = content.substring(open + 1, close);
    if (RegExp(
      r'^\s*' + RegExp.escape(member) + r'\s*,',
      multiLine: true,
    ).hasMatch(body)) {
      return content;
    }
    final newBody = body.trim().isEmpty
        ? '\n  $member,\n'
        : '${body.trimRight()}\n  $member,\n';
    return content.substring(0, open + 1) + newBody + content.substring(close);
  }

  /// Appends [member] to [AppFlowId] / [AppAgentId] in `lib/omega/app_runtime_ids.dart` (from `omega init`).
  /// Use [includeFlow] / [includeAgent] for `g flow` / `g agent` (single-enum updates).
  static void _mergeAppRuntimeIds(
    String projectRoot,
    String member, {
    bool includeFlow = true,
    bool includeAgent = true,
  }) {
    final f = File("$projectRoot/lib/omega/app_runtime_ids.dart");
    var text = f.readAsStringSync();
    if (includeFlow) {
      text = _upsertEnumMember(
        text,
        'enum AppFlowId with OmegaFlowIdEnumWire implements OmegaFlowId {',
        member,
      );
    }
    if (includeAgent) {
      text = _upsertEnumMember(
        text,
        'enum AppAgentId with OmegaAgentIdEnumWire implements OmegaAgentId {',
        member,
      );
    }
    f.writeAsStringSync(text);
  }

  static void _createAgentOnly(String name) {
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
    final idsFile = File("$root/lib/omega/app_runtime_ids.dart");
    if (!idsFile.existsSync()) {
      _err("app_runtime_ids.dart not found.");
      stdout.writeln("  Expected: ${_absPath(idsFile.path)}");
      stdout.writeln("  Run from app root: omega init");
      return;
    }
    final pkg = getPackageName(root);
    final rtMember = _runtimeIdEnumMember(name);
    final ecoPath = "$baseDir/${name.toLowerCase()}";
    stdout.writeln("Creating in current directory: ${_absPath(baseDir)}");
    Directory(ecoPath).createSync(recursive: true);
    _mergeAppRuntimeIds(root, rtMember, includeFlow: false, includeAgent: true);
    final created = <String>[
      idsFile.path,
      _createAgent(name, ecoPath, packageName: pkg, runtimeMember: rtMember),
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
    stdout.writeln("  Updated: ${_absPath(idsFile.path)}");
  }

  static void _createFlowOnly(String name) {
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
    final idsFile = File("$root/lib/omega/app_runtime_ids.dart");
    if (!idsFile.existsSync()) {
      _err("app_runtime_ids.dart not found.");
      stdout.writeln("  Expected: ${_absPath(idsFile.path)}");
      stdout.writeln("  Run from app root: omega init");
      return;
    }
    final pkg = getPackageName(root);
    final rtMember = _runtimeIdEnumMember(name);
    final ecoPath = "$baseDir/${name.toLowerCase()}";
    stdout.writeln("Creating in current directory: ${_absPath(baseDir)}");
    Directory(ecoPath).createSync(recursive: true);
    _mergeAppRuntimeIds(root, rtMember, includeFlow: true, includeAgent: false);
    final path = _createFlow(
      name,
      ecoPath,
      packageName: pkg,
      runtimeMember: rtMember,
    );
    registerInOmegaSetup(
      name,
      ecoPath,
      root,
      registerAgent: false,
      registerFlow: true,
    );
    _formatFile(idsFile.path);
    _formatFile(path);
    stdout.writeln("Flow $name created.");
    stdout.writeln("  Path: ${_absPath(ecoPath)}");
    stdout.writeln("  Updated: ${_absPath(idsFile.path)}");
  }

  static String _createAgent(
    String name,
    String base, {
    String? packageName,
    String? runtimeMember,
  }) {
    final pascal = toPascalCase(name);
    final file = File("$base/${name.toLowerCase()}_agent.dart");
    final typed =
        packageName != null &&
        packageName.isNotEmpty &&
        runtimeMember != null &&
        runtimeMember.isNotEmpty;
    final idsImport = typed
        ? "import 'package:$packageName/omega/app_runtime_ids.dart';\n"
        : '';
    final idLine = typed
        ? '          id: AppAgentId.$runtimeMember.id,'
        : '          id: "$name",';

    file.writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';
${idsImport}import '${name.toLowerCase()}_behavior.dart';

class ${pascal}Agent extends OmegaAgent {

  ${pascal}Agent(OmegaChannel channel)
      : super(
$idLine
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

  static String _createFlow(
    String name,
    String base, {
    String? packageName,
    String? runtimeMember,
  }) {
    final pascal = toPascalCase(name);
    final file = File("$base/${name.toLowerCase()}_flow.dart");
    final typed =
        packageName != null &&
        packageName.isNotEmpty &&
        runtimeMember != null &&
        runtimeMember.isNotEmpty;
    final idsImport = typed
        ? "import 'package:$packageName/omega/app_runtime_ids.dart';\n"
        : '';
    final superLine = typed
        ? '      : super(id: AppFlowId.$runtimeMember.id);'
        : '      : super(id: "$name");';

    file.writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';
${idsImport}import '${name.toLowerCase()}_agent.dart';

class ${pascal}Flow extends OmegaFlow {

  ${pascal}Flow({required super.channel, required this.agent})
$superLine

  final ${pascal}Agent agent;

  @override
  OmegaAgent? get uiScopeAgent => agent;

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

/// `ShoppingCart` -> `shoppingCartAgent` for a single shared instance in [omega_setup.dart].
String _omegaAgentInstanceVarName(String pascal) {
  if (pascal.isEmpty) return "moduleAgent";
  return "${pascal[0].toLowerCase()}${pascal.substring(1)}Agent";
}

bool _omegaPageDartRequiresAgentField(String pageSource) {
  if (pageSource.isEmpty) return false;
  if (RegExp(r"required\s+\w*Agent\s+agent\b").hasMatch(pageSource)) {
    return true;
  }
  // Typical AI/template pattern: `required this.agent` with `final FooAgent agent;`
  if (RegExp(r"required\s+this\.agent\b").hasMatch(pageSource)) return true;
  if (RegExp(r"\bfinal\s+\w+Agent\s+agent\s*;").hasMatch(pageSource)) {
    return true;
  }
  return false;
}

/// True when [*Module*Flow] takes the module agent in its constructor (`required this.agent`
/// or `required ModuleAgent agent`) so [omega_setup] must use one shared variable in
/// `agents:` and `ModuleFlow(channel: channel, agent: thatVar)`.
bool _omegaFlowDartRequiresSharedAgent(String flowSource, String pascal) {
  if (flowSource.isEmpty) return false;
  if (!flowSource.contains('class ${pascal}Flow')) return false;
  if (RegExp(r'required\s+this\.agent\b').hasMatch(flowSource)) return true;
  if (RegExp(
    r'required\s+' + RegExp.escape('${pascal}Agent') + r'\s+agent\b',
  ).hasMatch(flowSource)) {
    return true;
  }
  return false;
}

/// When [Page] gained `required agent` after the first [registerInOmegaSetup] pass
/// (e.g. AI overwrote the scaffold), rewrite `const FooPage()` / `FooPage()` routes.
String _omegaUpgradeOmegaRouteForAgent(
  String content,
  String pascal,
  String agentVar,
) {
  final id = RegExp.escape(pascal);
  final page = RegExp.escape("${pascal}Page");
  final re = RegExp(
    r"OmegaRoute\s*\(\s*id:\s*'" +
        id +
        r"'\s*,\s*builder\s*:\s*\(([^)]*)\)\s*=>\s*(?:const\s+)?\s*" +
        page +
        r"\s*\(\s*([^)]*)\)\s*\)",
    multiLine: true,
  );
  return content.replaceAllMapped(re, (m) {
    final builderParam = m[1]!;
    final insidePage = m[2]!.trim();
    if (insidePage.contains('agent:')) return m[0]!;
    if (insidePage.isNotEmpty) return m[0]!;
    return "OmegaRoute(id: '$pascal', builder: ($builderParam) => "
        "${pascal}Page(agent: $agentVar))";
  });
}

/// Drops duplicate `import` / `export` lines (identical after [String.trim]). Safe for
/// AI heal output and [omega_setup.dart] (models often repeat the same import twice).
String _omegaDedupeDuplicateImportLines(String content) {
  final lines = content.split("\n");
  final seen = <String>{};
  final out = <String>[];
  for (final line in lines) {
    final left = line.trimLeft();
    if (left.startsWith("import ") || left.startsWith("export ")) {
      final key = line.trim();
      if (seen.contains(key)) continue;
      seen.add(key);
    }
    out.add(line);
  }
  return out.join("\n");
}

/// Collapses 2+ blank lines between consecutive `final … = …Agent(...);` lines in
/// omega_setup (avoids huge gaps when [registerInOmegaSetup] prepends a new final).
String _omegaNormalizeOmegaSetupAgentFinalSpacing(String content) {
  var s = content;
  s = s.replaceAllMapped(
    RegExp(
      r'(\b\w+Agent\s*\([^)]*\)\s*;\s*)\n{2,}(\s*final\s+\w+\s*=\s*\w+Agent\s*\()',
      multiLine: true,
    ),
    (m) => '${m[1]}\n${m[2]}',
  );
  return s;
}

/// Inserts a `final …Agent` line after `{` of `createOmegaConfig` without an extra
/// blank line before existing `final` lines (fixes `\n$decl\n\n  final` duplication).
String _omegaInsertCreateOmegaConfigAgentDecl(String content, String decl) {
  final anchor = content.indexOf("OmegaConfig createOmegaConfig");
  if (anchor < 0) return content;
  final brace = content.indexOf("{", anchor);
  if (brace < 0) return content;
  var tail = content.substring(brace + 1);
  // Collapse leading newlines before the first `final` so we don't get `\n$decl\n\n  final`.
  while (tail.startsWith('\n')) {
    final after = tail.substring(1);
    if (!after.trimLeft().startsWith('final ')) break;
    tail = after;
  }
  if (tail.trimLeft().startsWith('final ') && !tail.startsWith('\n')) {
    tail = '\n$tail';
  }
  return "${content.substring(0, brace + 1)}\n$decl\n$tail";
}

/// First constructor `ClassName(` after `class ClassName`: if the parameter list
/// starts with `{`, assume a named bus arg — use `channel: channel` at call sites.
/// Otherwise use positional `channel` (matches example [AuthAgent], [AuthFlow]).
String _omegaEventBusArgListForClass(String dartSource, String className) {
  final classMatch = RegExp(
    r"class\s+" + RegExp.escape(className) + r"\b",
  ).firstMatch(dartSource);
  if (classMatch == null) return "channel";
  final tail = dartSource.substring(classMatch.end);
  final ctorMatch = RegExp(
    r"\b" + RegExp.escape(className) + r"\s*\(",
  ).firstMatch(tail);
  if (ctorMatch == null) return "channel";
  final afterParen = tail.substring(ctorMatch.end);
  for (var i = 0; i < afterParen.length; i++) {
    final c = afterParen.codeUnitAt(i);
    if (c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D) continue;
    if (c == 0x7B /* { */ ) return "channel: channel";
    return "channel";
  }
  return "channel";
}

bool _omegaSetupHasAgentChannelConstruction(String content, String pascal) {
  final name = "${pascal}Agent";
  return RegExp(
    r"\b" + RegExp.escape(name) + r"\s*\(\s*(?:channel\s*:\s*)?channel\s*\)",
  ).hasMatch(content);
}

bool _omegaSetupHasFlowChannelConstruction(String content, String pascal) {
  final name = "${pascal}Flow";
  // Any constructor call, including UserInterfaceFlow(channel: channel, agent: x).
  return RegExp(r"\b" + RegExp.escape(name) + r"\s*\(").hasMatch(content);
}

/// Normalizes `agents:` list: drops duplicate bare refs (any order), and removes
/// `FooAgent(channel)` when `final fooAgent = FooAgent` / bare `fooAgent` already covers it.
String _omegaDedupeOmegaSetupAgentsList(String content) {
  String dedupeInner(String inner, String fullSetup) {
    final seenBare = <String>{};
    final out = <String>[];
    for (final raw in inner.split(',')) {
      var seg = raw.trim();
      if (seg.isEmpty) continue;
      if (RegExp(r'^\w+$').hasMatch(seg)) {
        if (seenBare.contains(seg)) continue;
        seenBare.add(seg);
        out.add(seg);
        continue;
      }
      final ctor = RegExp(r'^(\w+)Agent\s*\(([^)]*)\)\s*$').firstMatch(seg);
      if (ctor != null) {
        final pascal = ctor.group(1)!;
        final varName = _omegaAgentInstanceVarName(pascal);
        final hasFinal = RegExp(
          r'\bfinal\s+' + RegExp.escape(varName) + r'\s*=\s*' + RegExp.escape(pascal) + r'Agent\s*\(',
        ).hasMatch(fullSetup);
        if (seenBare.contains(varName) || hasFinal) continue;
      }
      out.add(seg);
    }
    if (out.isEmpty) return inner;
    return '\n      ${out.join(',\n      ')}\n    ';
  }

  var out = content.replaceFirstMapped(
    RegExp(r'(agents:\s*<OmegaAgent>\s*\[)([\s\S]*?)(\]\s*[,)])', multiLine: true),
    (m) => '${m[1]}${dedupeInner(m.group(2)!, content)}${m[3]}',
  );
  if (out == content) {
    out = content.replaceFirstMapped(
      RegExp(r'(agents:\s*\[)([\s\S]*?)(\]\s*[,)])', multiLine: true),
      (m) => '${m[1]}${dedupeInner(m.group(2)!, content)}${m[3]}',
    );
  }
  return out;
}

/// Stricter than [OmegaValidateCommand.validateProjectRoot] heuristics: only auto-patch cold
/// start when `navigate.login` can work (**route id `login`**) and the shell is multi-route.
bool _omegaSetupQualifiesForColdStartAutoPatch(String content) {
  if (RegExp(r'\binitialFlowId\s*:').hasMatch(content) &&
      RegExp(r'\binitialNavigationIntent\s*:').hasMatch(content)) {
    return false;
  }
  final routesBlock = RegExp(
    r'routes:\s*<OmegaRoute>\s*\[([\s\S]*?)\]\s*[,)]',
    multiLine: true,
  ).firstMatch(content);
  final routeIdReg = RegExp(
    r'''OmegaRoute(?:\.typed<[^>]+>)?\(\s*id:\s*['"]([^'"]+)['"]''',
  );
  final routeIds = <String>[];
  if (routesBlock != null) {
    final inner = routesBlock.group(1)!;
    for (final m in routeIdReg.allMatches(inner)) {
      routeIds.add(m.group(1)!);
    }
  }
  final hasLoginRoute = routeIds.any((id) => id == 'login');
  if (!hasLoginRoute) return false;
  if (routeIds.length < 2) return false;

  final looksAuthApp =
      content.contains('AuthFlow(') ||
      content.contains('AuthAgent(') ||
      routeIds.any((id) => id == 'Auth' || id.toLowerCase() == 'auth');
  return looksAuthApp;
}

/// Reads `AuthFlow` / `super(id: …)` when possible so [initialFlowId] matches the real flow.
String _omegaInferAuthInitialFlowIdExpr(String projectRoot, String setupContent) {
  if (setupContent.contains('AppFlowId.authFlow')) {
    return 'AppFlowId.authFlow.id';
  }
  final candidates = <String>[
    _path(projectRoot, ['lib', 'auth', 'auth_flow.dart']),
    _path(projectRoot, ['lib', 'Auth', 'auth_flow.dart']),
  ];
  for (final p in candidates) {
    final f = File(p);
    if (!f.existsSync()) continue;
    try {
      final text = f.readAsStringSync();
      final mEnum = RegExp(
        r'super\s*\(\s*id:\s*(AppFlowId\.\w+\.id)\s*',
        multiLine: true,
      ).firstMatch(text);
      if (mEnum != null) return mEnum.group(1)!;
      final mStr = RegExp(
        r"super\s*\(\s*id:\s*'([^']+)'\s*",
        multiLine: true,
      ).firstMatch(text);
      if (mStr != null) return "'${mStr.group(1)}'";
    } catch (_) {}
  }
  return "'authFlow'";
}

/// Inserts [initialFlowId] + [initialNavigationIntent] when the setup qualifies (see
/// [_omegaSetupQualifiesForColdStartAutoPatch]) so `AppIntent.navigateLogin` is valid.
String _omegaPatchOmegaSetupColdStart(
  String content,
  String pkg,
  String projectRoot,
) {
  if (!_omegaSetupQualifiesForColdStartAutoPatch(content)) return content;
  var s = content;
  final semanticsImportRe = RegExp(
    "import\\s+['\"]package:${RegExp.escape(pkg)}/omega/app_semantics\\.dart['\"]",
  );
  final semanticsAnyRe = RegExp(
    "import\\s+['\"].*app_semantics\\.dart['\"]",
  );
  if (!semanticsImportRe.hasMatch(s) && !semanticsAnyRe.hasMatch(s)) {
    s = "import 'package:$pkg/omega/app_semantics.dart';\n$s";
  }
  final flowExpr = _omegaInferAuthInitialFlowIdExpr(projectRoot, s);
  if (flowExpr.contains('AppFlowId.')) {
    final runtimeImportRe = RegExp(
      "import\\s+['\"]package:${RegExp.escape(pkg)}/omega/app_runtime_ids\\.dart['\"]",
    );
    final runtimeAnyRe = RegExp(
      "import\\s+['\"].*app_runtime_ids\\.dart['\"]",
    );
    if (!runtimeImportRe.hasMatch(s) && !runtimeAnyRe.hasMatch(s)) {
      s = "import 'package:$pkg/omega/app_runtime_ids.dart';\n$s";
    }
  }
  final needFlow = !RegExp(r'\binitialFlowId\s*:').hasMatch(s);
  final needNav =
      !RegExp(r'\binitialNavigationIntent\s*:').hasMatch(s);
  if (!needFlow && !needNav) return s;
  final flowLine =
      needFlow ? '    initialFlowId: $flowExpr,\n' : '';
  final navLine = needNav
      ? '    initialNavigationIntent: OmegaIntent.fromName(AppIntent.navigateLogin),\n'
      : '';
  if (RegExp(r'return\s+OmegaConfig\s*\(\s*\n').hasMatch(s)) {
    s = s.replaceFirstMapped(
      RegExp(r'return\s+OmegaConfig\s*\(\s*\n'),
      (m) => '${m[0]}$flowLine$navLine',
    );
  } else {
    s = s.replaceFirstMapped(
      RegExp(r'return\s+OmegaConfig\s*\(\s*'),
      (m) => '${m[0]}\n$flowLine$navLine',
    );
  }
  return s;
}

/// Applies the same deterministic `omega_setup.dart` fixes as [registerInOmegaSetup] (dedupe
/// `agents:`, cold-start fields). Returns `true` if the file was rewritten.
bool _omegaTryDeterministicOmegaSetupHeal(String root) {
  final setupPath = _path(root, ["lib", "omega", "omega_setup.dart"]);
  final f = File(setupPath);
  if (!f.existsSync()) return false;
  try {
    final pkg = getPackageName(root);
    var c = f.readAsStringSync();
    final before = c;
    c = _omegaDedupeOmegaSetupAgentsList(c);
    c = _omegaPatchOmegaSetupColdStart(c, pkg, root);
    c = _omegaDedupeDuplicateImportLines(c);
    c = _omegaNormalizeOmegaSetupAgentFinalSpacing(c);
    if (c == before) return false;
    f.writeAsStringSync(c);
    _formatFile(setupPath);
    return true;
  } catch (_) {
    return false;
  }
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
  final agentVar = _omegaAgentInstanceVarName(pascal);
  final pagePath =
      "$pathNorm${Platform.pathSeparator}ui${Platform.pathSeparator}${nameLower}_page.dart";
  var pageNeedsAgent = false;
  if (File(pagePath).existsSync()) {
    pageNeedsAgent = _omegaPageDartRequiresAgentField(
      File(pagePath).readAsStringSync(),
    );
  }
  final agentPath = "$pathNorm/${nameLower}_agent.dart";
  final flowPath = "$pathNorm/${nameLower}_flow.dart";

  var agentChannelArgs = "channel";
  final agentFileForCtor = File(agentPath);
  if (agentFileForCtor.existsSync()) {
    try {
      agentChannelArgs = _omegaEventBusArgListForClass(
        agentFileForCtor.readAsStringSync(),
        "${pascal}Agent",
      );
    } catch (_) {}
  }
  var flowChannelArgs = "channel";
  final flowFileForCtor = File(flowPath);
  var flowNeedsSharedAgent = false;
  if (flowFileForCtor.existsSync()) {
    try {
      final flowSrc = flowFileForCtor.readAsStringSync();
      flowNeedsSharedAgent = _omegaFlowDartRequiresSharedAgent(flowSrc, pascal);
      flowChannelArgs = _omegaEventBusArgListForClass(flowSrc, "${pascal}Flow");
    } catch (_) {}
  }
  if (flowNeedsSharedAgent) {
    flowChannelArgs = "channel: channel, agent: $agentVar";
  }
  final registerAgentEffective =
      registerAgent || (registerFlow && flowNeedsSharedAgent);

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
  final pagePattern = RegExp(
    "import\\s+['\"].*${RegExp.escape("${nameLower}_page.dart")}['\"];\\s*",
  );
  // Quita todas las líneas de import de este módulo (generación remota / doble register pueden duplicar).
  if (registerAgentEffective) {
    while (agentPattern.hasMatch(content)) {
      content = content.replaceFirst(agentPattern, "");
    }
  }
  if (registerFlow) {
    while (flowPattern.hasMatch(content)) {
      content = content.replaceFirst(flowPattern, "");
    }
    while (pagePattern.hasMatch(content)) {
      content = content.replaceFirst(pagePattern, "");
    }
  }

  final newImports = <String>[];
  if (registerAgentEffective) newImports.add(agentImport);
  if (registerFlow) {
    newImports.add(flowImport);
    // Añadimos el import de la página para la ruta
    if (pathNorm.toLowerCase().startsWith(libNorm.toLowerCase())) {
      var relative = pathNorm
          .substring(libNorm.length)
          .replaceAll(Platform.pathSeparator, "/")
          .replaceFirst(RegExp(r"^[/\\]"), "");
      if (relative.endsWith("/")) {
        relative = relative.substring(0, relative.length - 1);
      }
      newImports.add(
        "import 'package:$pkg/$relative/ui/${nameLower}_page.dart';",
      );
    }
  }
  if (newImports.isNotEmpty) {
    content = '${newImports.join("\n")}\n$content';
  }

  if (registerAgentEffective && (pageNeedsAgent || flowNeedsSharedAgent)) {
    final decl = "  final $agentVar = ${pascal}Agent($agentChannelArgs);";
    if (!content.contains(decl)) {
      content = _omegaInsertCreateOmegaConfigAgentDecl(content, decl);
    }
  }

  // First pass may have added `PascalAgent(channel),` before the page required agent.
  if (registerAgentEffective && (pageNeedsAgent || flowNeedsSharedAgent)) {
    final inlineRe = RegExp(
      r"\n(\s*)" + RegExp.escape(pascal) + r"Agent\s*\([^)]*\)\s*,",
    );
    if (inlineRe.hasMatch(content)) {
      content = content.replaceFirstMapped(
        inlineRe,
        (m) => "\n${m[1]}$agentVar,",
      );
    }
  }

  if ((pageNeedsAgent || flowNeedsSharedAgent) &&
      registerFlow &&
      !registerAgent) {
    stdout.writeln(
      "⚠️ ${_tr(en: "$pascal needs a shared agent in omega_setup — add import + final $agentVar + list it in agents: and pass it to ${pascal}Flow(..., agent: $agentVar). Page may also need agent: $agentVar on the route.", es: "$pascal requiere el mismo agente en omega_setup: import + final $agentVar + en agents: y ${pascal}Flow(..., agent: $agentVar). La página puede necesitar agent: $agentVar en la ruta.")}",
    );
  }

  if (registerAgentEffective) {
    if (pageNeedsAgent || flowNeedsSharedAgent) {
      if (!content.contains("$agentVar,")) {
        if (content.contains("agents: <OmegaAgent>[")) {
          content = content.replaceFirst(
            "agents: <OmegaAgent>[",
            "agents: <OmegaAgent>[\n      $agentVar,",
          );
        } else if (content.contains("agents: [")) {
          content = content.replaceFirst(
            "agents: [",
            "agents: [\n      $agentVar,",
          );
        }
      }
    } else if (!_omegaSetupHasAgentChannelConstruction(content, pascal) &&
        !flowNeedsSharedAgent) {
      if (content.contains("agents: <OmegaAgent>[")) {
        content = content.replaceFirst(
          "agents: <OmegaAgent>[",
          "agents: <OmegaAgent>[\n      ${pascal}Agent($agentChannelArgs),",
        );
      } else if (content.contains("agents: [")) {
        content = content.replaceFirst(
          "agents: [",
          "agents: [\n      ${pascal}Agent($agentChannelArgs),",
        );
      }
    }
  }

  if (registerFlow) {
    if (content.contains("flows: <OmegaFlow>[")) {
      if (!_omegaSetupHasFlowChannelConstruction(content, pascal)) {
        content = content.replaceFirst(
          "flows: <OmegaFlow>[",
          "flows: <OmegaFlow>[\n      ${pascal}Flow($flowChannelArgs),",
        );
      }
    } else if (content.contains("flows: [")) {
      if (!_omegaSetupHasFlowChannelConstruction(content, pascal)) {
        content = content.replaceFirst(
          "flows: [",
          "flows: [\n      ${pascal}Flow($flowChannelArgs),",
        );
      }
    } else {
      // Si no existe la sección flows, la añadimos antes del cierre de OmegaConfig
      content = content.replaceFirst(
        ");",
        "  flows: <OmegaFlow>[\n      ${pascal}Flow($flowChannelArgs),\n    ],\n  );",
      );
    }

    // Registrar ruta por defecto para el nuevo módulo
    if (!content.contains("OmegaRoute(id: '$pascal'")) {
      final routeEntry = pageNeedsAgent && registerAgentEffective
          ? "      OmegaRoute(id: '$pascal', builder: (context) => ${pascal}Page(agent: $agentVar)),"
          : "      OmegaRoute(id: '$pascal', builder: (context) => const ${pascal}Page()),";
      if (content.contains("routes: <OmegaRoute>[")) {
        content = content.replaceFirst(
          "routes: <OmegaRoute>[",
          "routes: <OmegaRoute>[\n$routeEntry",
        );
      } else if (content.contains("routes: []")) {
        content = content.replaceFirst(
          "routes: []",
          "routes: <OmegaRoute>[\n$routeEntry\n    ]",
        );
      } else if (content.contains("routes: [")) {
        content = content.replaceFirst("routes: [", "routes: [\n$routeEntry");
      } else {
        content = content.replaceFirst(
          "OmegaConfig(",
          "OmegaConfig(\n    routes: <OmegaRoute>[\n$routeEntry\n    ],",
        );
      }
    }
  }

  if (registerAgentEffective && pageNeedsAgent) {
    content = _omegaUpgradeOmegaRouteForAgent(content, pascal, agentVar);
  }

  content = _omegaDedupeOmegaSetupAgentsList(content);
  content = _omegaPatchOmegaSetupColdStart(content, pkg, projectRoot);
  content = _omegaDedupeDuplicateImportLines(content);
  content = _omegaNormalizeOmegaSetupAgentFinalSpacing(content);

  setupFile.writeAsStringSync(content);
  _formatFile(setupFile.path);

  final what = [
    if (registerAgentEffective) "agent",
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

    if (!validateProjectRoot(root)) exit(1);
  }

  /// Validates [root] (Flutter app with `lib/omega/omega_setup.dart`): structure, duplicates, login/home cold start hints, route vs *Page agent wiring. Prints messages; does not [exit] — returns `false` on failure.
  static bool validateProjectRoot(String root) {
    final setupPath = "$root/lib/omega/omega_setup.dart";
    final setupFile = File(setupPath);
    if (!setupFile.existsSync()) {
      _err("omega_setup.dart not found.");
      stdout.writeln("  Looked at: ${_absPath(setupPath)}");
      stdout.writeln("  Run: omega init");
      return false;
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

    // Duplicates: scope to agents:/flows:/routes: list bodies (AI often repeats variable or id:).
    final agentsBlock = RegExp(
      r'agents:\s*<OmegaAgent>\s*\[([\s\S]*?)\]\s*[,)]',
      multiLine: true,
    ).firstMatch(content);
    final flowsBlock = RegExp(
      r'flows:\s*<OmegaFlow>\s*\[([\s\S]*?)\]\s*[,)]',
      multiLine: true,
    ).firstMatch(content);
    final routesBlock = RegExp(
      r'routes:\s*<OmegaRoute>\s*\[([\s\S]*?)\]\s*[,)]',
      multiLine: true,
    ).firstMatch(content);

    final agentCtorReg = RegExp(
      r"(\w+)Agent\s*\(\s*(?:channel\s*:\s*)?channel\s*[,\)]",
    );
    final flowCtorReg = RegExp(r"(\w+)Flow\s*\(\s*[^)]*channel[^)]*\)");
    final routeIdReg = RegExp(
      r'''OmegaRoute(?:\.typed<[^>]+>)?\(\s*id:\s*['"]([^'"]+)['"]''',
    );

    final agentNames = <String>[];
    final flowNames = <String>[];
    final routeIds = <String>[];

    if (agentsBlock != null) {
      final inner = agentsBlock.group(1)!;
      for (final m in agentCtorReg.allMatches(inner)) {
        agentNames.add(m.group(1)!);
      }
      final agentListRefs = _omegaSetupListCommaEntries(inner);
      final dupAgentRefs = _duplicates(agentListRefs);
      if (dupAgentRefs.isNotEmpty) {
        _err(
          "Duplicate entries in agents: list: ${dupAgentRefs.join(", ")}.",
        );
        stdout.writeln(
          "  Each agent variable must appear once in agents: <OmegaAgent>[...] "
          "(e.g. remove the second orderManagementAgent).",
        );
        ok = false;
      }
    }
    if (flowsBlock != null) {
      final inner = flowsBlock.group(1)!;
      for (final m in flowCtorReg.allMatches(inner)) {
        flowNames.add(m.group(1)!);
      }
    }
    if (routesBlock != null) {
      final inner = routesBlock.group(1)!;
      for (final m in routeIdReg.allMatches(inner)) {
        routeIds.add(m.group(1)!);
      }
    }

    final duplicateAgents = _duplicates(agentNames);
    final duplicateFlows = _duplicates(flowNames);
    final duplicateRouteIds = _duplicates(routeIds);

    if (duplicateAgents.isNotEmpty) {
      _err("Duplicate *Agent(channel) constructor in agents: block: ${duplicateAgents.join(", ")}.");
      stdout.writeln(
        "  Only one `FooAgent(channel)` per module inside agents: <OmegaAgent>[...].",
      );
      ok = false;
    }
    if (duplicateFlows.isNotEmpty) {
      _err("Duplicate *Flow(...) in flows: block: ${duplicateFlows.join(", ")}.");
      stdout.writeln(
        "  Only one `FooFlow(...)` registration per flow id inside flows: <OmegaFlow>[...].",
      );
      ok = false;
    }
    if (duplicateRouteIds.isNotEmpty) {
      _err("Duplicate OmegaRoute id: ${duplicateRouteIds.join(", ")}.");
      stdout.writeln(
        "  Each OmegaRoute(id: ...) must be unique — matches navigate.* / OmegaNavigator lookup.",
      );
      ok = false;
    }

    // Login + home cold start: catches common AI mistakes (missing OmegaConfig fields, wrong route ids).
    final looksAuthApp = content.contains('AuthFlow(') ||
        content.contains('AuthAgent(') ||
        routeIds.any(
          (id) =>
              id.toLowerCase().contains('auth') ||
              id.toLowerCase() == 'login',
        ) ||
        agentNames.any((n) => n.toLowerCase() == 'auth');
    final looksMultiModule =
        routeIds.length >= 2 || agentNames.length >= 2;
    if (looksAuthApp && looksMultiModule) {
      if (!RegExp(r'\binitialFlowId\s*:').hasMatch(content)) {
        _err(
          "OmegaConfig missing initialFlowId: — with Auth + multiple modules/routes, set it to the login/auth flow id (same as AuthFlow super(id: ...)).",
        );
        ok = false;
      }
      if (!RegExp(r'\binitialNavigationIntent\s*:').hasMatch(content)) {
        _err(
          "OmegaConfig missing initialNavigationIntent: — set e.g. OmegaIntent.fromName(AppIntent.navigateLogin) so the first screen is login (see example/lib/omega/omega_setup.dart).",
        );
        ok = false;
      }
      if (content.contains('AppIntent.navigateLogin')) {
        final hasLoginRoute = routeIds.any((id) => id == 'login');
        if (!hasLoginRoute) {
          _err(
            "Using AppIntent.navigateLogin requires OmegaRoute(id: 'login', ...) — navigator strips the navigate. prefix (WRONG: id: 'Auth' for login).",
          );
          ok = false;
        }
      }
      if (content.contains('AppIntent.navigateHome')) {
        final hasHomeRoute = routeIds.any((id) => id == 'home');
        if (!hasHomeRoute) {
          _err(
            "Using AppIntent.navigateHome requires OmegaRoute(id: 'home', ...) (lowercase id matches wire navigate.home).",
          );
          ok = false;
        }
      }
    }

    final routeAgentIssues = collectRouteAgentMismatches(root, content);
    if (routeAgentIssues.isNotEmpty) {
      ok = false;
      for (final msg in routeAgentIssues) {
        _err(msg);
      }
    }

    if (ok) {
      stdout.writeln("Valid.");
      stdout.writeln("  File: ${_absPath(setupPath)}");
      stdout.writeln(
        "  Agents: ${agentNames.length}, Flows: ${flowNames.length}, Routes: ${routeIds.length}",
      );
    } else {
      stdout.writeln("");
      stdout.writeln("Validate failed.");
    }
    return ok;
  }

  /// Scans `lib/**.dart` for `*Page` classes whose constructor has `required …Agent agent`.
  static Map<String, bool> _libPagesRequiringAgent(String libRoot) {
    final map = <String, bool>{};
    final dir = Directory(libRoot);
    if (!dir.existsSync()) return map;
    for (final e in dir.listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith("_page.dart")) continue;
      try {
        final text = e.readAsStringSync();
        final cm = RegExp(r"class\s+(\w+)\s+extends").firstMatch(text);
        if (cm == null) continue;
        final cls = cm.group(1)!;
        if (_omegaPageDartRequiresAgentField(text)) {
          map[cls] = true;
        }
      } catch (_) {}
    }
    return map;
  }

  /// Detects [omega_setup.dart] calls like `FooPage()` or `const FooPage()` when [FooPage] requires [agent].
  static List<String> collectRouteAgentMismatches(
    String projectRoot,
    String setupContent,
  ) {
    final pageNeedsAgent = _libPagesRequiringAgent("$projectRoot/lib");
    final issues = <String>[];
    for (final m in RegExp(
      r"(\w+Page)\s*\(\s*([^)]*)\)",
    ).allMatches(setupContent)) {
      final pageName = m.group(1)!;
      final args = m.group(2)!.trim();
      if (pageNeedsAgent[pageName] != true) continue;
      if (args.contains("agent:")) continue;
      final pascal = pageName.endsWith("Page")
          ? pageName.substring(0, pageName.length - 4)
          : pageName;
      final hintVar = _omegaAgentInstanceVarName(pascal);
      issues.add(
        "Route/widget call $pageName(...) has no `agent:` but $pageName requires a *Agent. "
        "In createOmegaConfig add e.g. `final $hintVar = ${pascal}Agent(channel);` — or "
        "`${pascal}Agent(channel: channel);` if the agent constructor uses `{required OmegaEventBus channel}` — "
        "list $hintVar in agents, and use `OmegaRoute(..., builder: (c) => $pageName(agent: $hintVar))` "
        "(do not use const $pageName()).",
      );
    }
    return issues;
  }

  /// Comma-split entries in `agents:` / `flows:` list inner text; keeps only **single-token**
  /// references (e.g. `orderManagementAgent`) so duplicate variable lines are detected.
  static List<String> _omegaSetupListCommaEntries(String inner) {
    final out = <String>[];
    for (final part in inner.split(',')) {
      var t = part.trim();
      final c = t.indexOf('//');
      if (c >= 0) {
        t = t.substring(0, c).trim();
      }
      if (t.isEmpty) continue;
      if (RegExp(r'^\w+$').hasMatch(t)) {
        out.add(t);
      }
    }
    return out;
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
    final agentReg = RegExp(
      r"(\w+)Agent\s*\(\s*(?:channel\s*:\s*)?channel\s*[,\)]",
    );
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
    final routeAgentDoctorIssues =
        OmegaValidateCommand.collectRouteAgentMismatches(root, content);
    if (routeAgentDoctorIssues.isNotEmpty) {
      ok = false;
      for (final msg in routeAgentDoctorIssues) {
        _err(msg);
      }
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

/// CLI AI entrypoints (`omega ai doctor|env|coach|…`) and **all remote LLM prompt fragments** used when
/// generating or healing Dart with OpenAI/Gemini.
///
/// **Why so many `static const String` blocks:** each `_omegaAi*` fragment targets one failure mode
/// (invented `getAgent`, wrong `OmegaIntent.fromName` arguments, Provider-style builders, fake
/// `OmegaFlowActivator` callbacks). They are composed into user/system prompts in
/// [_providerGenerateModuleCode], [_providerFixErrors], etc. — keep them **small**, **non-overlapping**,
/// and aligned with real APIs under `lib/omega/` and `example/lib/`.
///
/// **Conceptual layer for the model:** [_omegaAiConceptualArchitecture] explains how scope, channel,
/// flow manager, and agents relate so the LLM does not improvise “service locator” patterns.
class OmegaAiCommand {
  /// **User prompt:** mental model of Omega (scope vs channel vs flows vs agents). Reduces invented APIs.
  static const String _omegaAiConceptualArchitecture = r'''
CONCEPT — how Omega is wired (read first; avoids inventing APIs from other frameworks):
- **OmegaScope** is intentionally minimal: **`channel`**, **`flowManager`**, **`initialFlowId`**, optional **`initialNavigationIntent`** (for [OmegaInitialRoute]). It is **not** a service locator: there is **no** `agentManager`, **no** `getAgent`, **no** `repositories` on scope. Anything else your app needs (HTTP clients, DB, extra repos) lives in **your** classes and is passed through **constructors** from `createOmegaConfig` / routes / flow fields — never “discovered” via a fake scope API.
- **Two lanes from the UI:** (1) **`flowManager.handleIntent(OmegaIntent.fromName(...))`** — delivers to **running** [OmegaFlow]s and optional intent-handlers; good for **wizard / flow steps** that the flow’s `onIntent` handles. (2) **`channel.emit(OmegaEvent.fromName(...))` / `emitTyped(...)`** — **broadcast**; **agents** (behavior → `onAction`) and **flows** (`onEvent`) listen here; **OmegaNavigator** listens for **`navigation.intent`**. Domain “load list / refresh” tied to `ctx.event` belongs here, not only `handleIntent`.
- **Where agents come from:** one shared **instance per module** registered in [OmegaConfig] and wired into **flows** (`agent:` ctor) and/or **routes** (`OmegaAgentScope`, or `required this.agent` on the page). Widgets use **`OmegaAgentBuilder(agent: …)`** or **`OmegaScopedAgentBuilder`** (two-arg builder). You **cannot** obtain an agent by string id from `flowManager` or `OmegaScope` — those methods do not exist by design.
- **Why invention fails:** every method you add in generated code must already exist on a type from **`package:omega_architecture/omega_architecture.dart`**. If you cannot point to it in PACKAGE GROUND TRUTH or that export, **do not emit it** — mirror `example/lib/auth/*` + `omega_setup.dart` instead.
''';

  /// **User prompt:** hard “only these sources” rule so the model does not invent internal package paths.
  static const String _omegaAiOmegaSourceOfTruth = r'''
SOURCE OF TRUTH — do not invent:
- Use ONLY: (1) public API from `package:omega_architecture/omega_architecture.dart`, (2) the Omega rules/checklist/templates in this prompt, (3) PACKAGE GROUND TRUTH (attached example Dart and, if present, package doc excerpts). Never `package:omega_architecture/omega/...` internal paths or types/widgets not shown in those sources.
- If something is not spelled out here, mirror the closest attached example (e.g. auth_*, omega_setup) structurally instead of improvising new Omega patterns, getters on scope, or agent APIs.
- No extra architecture layers (BLoC/Riverpod/GetX/etc.) in generated Omega module code unless the user explicitly asked. Deliver the smallest coherent solution that compiles and matches the instruction — no speculative packages or features.
''';

  /// **User prompt:** Material 3 / layout quality bar for generated `page` strings (not structural Omega API).
  static const String _omegaAiUiDesignStandards = r'''
UI DESIGN EXCELLENCE (ship-quality — treat this screen as a real product, not a tutorial):
- Goal: the best layout you can produce in one file — clear hierarchy, generous spacing, cohesive Material 3, and a credible real-app feel.
- Hierarchy: AppBar or in-body title; optional subtitle; group content (Cards, sections) with SizedBox height between groups; avoid a flat column of undifferentiated widgets.
- Material 3: Theme.of(context).colorScheme and textTheme (headlineMedium, titleLarge, bodyLarge, labelLarge); FilledButton primary, OutlinedButton/TextButton secondary; TextField/TextFormField with InputDecoration (label, hint, prefixIcon where useful); Cards with consistent margin and clipBehavior if needed.
- Layout: SafeArea when content touches edges; SingleChildScrollView for vertical overflow; on wide screens center the main column with ConstrainedBox(maxWidth: 480–560) so forms do not stretch edge-to-edge.
- Visual polish: meaningful Icons; Chips for tags/filters; Divider between sections; subtle borders or tonal surfaces (surfaceContainer*) from colorScheme where it improves scanability.
- States: loading — centered CircularProgressIndicator or a compact skeleton-style placeholder (shimmer not required); error — Icon + Text + optional FilledButton.tonal/FilledButton for retry; success — the full designed UI (not a stub).
- Domain hints: Login — email + password fields, optional logo/header, primary sign-in, secondary links as TextButton; Dashboard — metric Cards, lists, avatars or leading icons; Settings — SwitchListTile / ListTile groups.
- Accessibility: tooltips on icon-only actions; error text with sufficient contrast; comfortable tap targets (min ~48 logical pixels).
- Copy: all user-visible strings in the same language as the user’s instruction.
- FORBIDDEN: a screen that is only one button and one Text, bare Center(Text), "TODO UI", or Lorem ipsum as main content.
''';

  /// **User prompt:** first-load / empty-list fixes. Conceptually: `handleIntent` ≠ bus; agents see **channel** events.
  static const String _omegaAiScreenEntryDataLoad = r'''
SCREEN ENTRY — lists, grids, catalogs, dashboard data (must not stay empty until the user taps a button unless the spec says so):
- [OmegaFlowManager.handleIntent] only delivers to flows in [running] state. Call [flowManager.activate(flowId)] or [switchTo(flowId)] with the SAME id as the Flow’s super(id: ...), OR wrap the screen with [OmegaFlowActivator](flowId: ...) so users need not write activate in [didChangeDependencies].
- If the screen shows data from [OmegaAgentBuilder] / agent viewState lists: something must fire the FIRST load when the route opens. Choose ONE coherent chain and implement it in generated flow + agent + page:
  (A) Intent kickoff: in State.didChangeDependencies (or initState + addPostFrameCallback if you avoid context before ready), use a bool guard e.g. _entryKickApplied so you run only once: activate(flowId), then flowManager.handleIntent(OmegaIntent.fromName(MyIntent.start)) IF the flow’s onIntent for start emits channel events / starts steps that lead to the agent loading (same pattern as flow onIntent emitting MyEvent.requested).
  (B) Event kickoff: if the agent behavior matches ctx.event?.name == MyEvent.requested (or similar) and NOT ctx.intent for load, then on entry emit once: scope.channel.emit(OmegaEvent.fromName(MyEvent.requested)) or emitTyped(MyRequestedEvent(...)). handleIntent alone will NOT trigger that rule.
  (C) Flow onStart only: acceptable if onStart() itself emits the same events / intents the agent or next step needs — then the page must still ensure the flow is running (activate/switchTo) when this route opens.
- WRONG: StreamBuilder + OmegaAgentBuilder showing an empty list forever because nothing ever emitted start / requested after navigation.
- RIGHT: One clear “on open” path documented in reasoning: which of (A)(B)(C) you used and which enum (.requested vs .start) matches the behavior rules.
''';

  /// **User prompt:** concrete ctor/method allowlist for activator + manager + scope; models often invent callbacks/`getAgent`.
  static const String _omegaAiFlowActivatorAndFlowManager = r'''
OMEGA — OmegaFlowActivator + OmegaFlowManager (exact API from package — never invent parameters or manager methods):
- **OmegaFlowActivator** (`omega_flow_activator.dart`): constructor allows ONLY `key`, **`flowId`** ([String] or [OmegaFlowId] e.g. `AppFlowId.myModule`), **`child`** ([Widget]), optional **`useSwitchTo`** (bool — default calls [activate]; if true calls [switchTo]). Implementation runs [activate]/[switchTo] once inside [didChangeDependencies]. **FORBIDDEN:** `onActivate`, `onReady`, `onFlowReady`, `builder`, or any callback that receives [OmegaFlowManager] — those parameters **do not exist**. WRONG: `OmegaFlowActivator(flowId: x, onActivate: (fm) { ... }, child: ...)`.
- **OmegaFlowManager** (`omega_flow_manager.dart`): UI/flow integration uses **`registerFlow`**, **`getFlow`** / **`getFlowFlexible`**, **`activate`**, **`activateExclusive`**, **`switchTo`**, **`handleIntent`**, optional **`registerIntentHandler`** / **`clearIntentHandlers`**, snapshot APIs (`getFlowSnapshot`, `getAppSnapshot`, `restoreFromSnapshot`), **`registeredFlowIds`**, **`activeFlowId`**, **`channel`**. **FORBIDDEN:** **`getAgent`**, **`getAgent<T>`**, **`agents`**, **`findAgent`**, or any API that returns an [OmegaAgent] from the manager — **not in the package**. Agents are registered in [OmegaConfig.agents], held on flow fields, and exposed to widgets via [OmegaAgentScope] / [OmegaFlow.uiScopeAgent] + [OmegaScopedAgentBuilder] or [OmegaAgentBuilder(agent: ...)].
- **Never** `flowManager.getAgent(...).viewStateStream` or similar. To react to agent loading: use [OmegaScopedAgentBuilder]/[OmegaAgentBuilder] and read `state.isLoading`, or `StreamBuilder` on `agent.stateStream` with `initialData: agent.viewState` when you already have an `agent` reference (see `_omegaAiAgentUiStateListening`).
- **OmegaScope** (`omega_scope.dart`): **`channel`**, **`flowManager`**, **`initialFlowId`**, optional **`initialNavigationIntent`**. **FORBIDDEN (invented — does not compile):** `scope.agentManager`, **`scope.agentManager.getAgent('ModuleName')`**, `scope.getAgent<T>(...)`, or any “registry” on scope. WRONG: `_buildProfileForm(context, state, scope.agentManager.getAgent('UserManagement') as UserManagementAgent)`. RIGHT: pass `UserManagementAgent` via `required this.agent` on the page + [OmegaAgentBuilder], or [OmegaAgentScope] + [OmegaScopedAgentBuilder], or [OmegaFlowExpressionBuilder] + flow [uiScopeAgent] (see package examples).
''';

  /// **User prompt:** bus = `OmegaEvent` only; typed payloads via `payloadAs`; explains why `event is MyTypedEvent` fails.
  static const String _omegaAiOmegaChannelEvents = r'''
OMEGA CHANNEL EVENTS (Stream<OmegaEvent>, flow onEvent ctx.event, agent listeners):
- Listing / loading / refresh: if your module starts work when an event appears on the bus (e.g. product.catalog.requested, orders.refresh), the button must emit that event: scope.channel.emit(OmegaEvent.fromName(MyEvent.requested)) or emitTyped(MyRequestedEvent(...)). Agents never see handleIntent — they see channel.events. Using only handleIntent when behavior uses ctx.event?.name == MyEvent.requested.name will not load data.
- Every emission on the bus is an OmegaEvent (id, name, payload, namespace). It is NOT an instance of your `class FooEvent implements OmegaTypedEvent`.
- emitTyped(ShoppingCartAddProductEvent(...)) builds OmegaEvent(name: event.name, payload: that same instance). Listeners must unwrap:
  final add = event.payloadAs<ShoppingCartAddProductEvent>();
  if (add != null) { ... add.product ... }
  Or filter by name then unwrap: if (event.name == ShoppingCartEvent.productAdded.name) { final add = event.payloadAs<ShoppingCartAddProductEvent>(); ... }
- WRONG (no promotion / product getter on OmegaEvent): if (event is ShoppingCartAddProductEvent) { event.product } — OmegaTypedEvent classes are not subtypes of OmegaEvent, so `event` stays OmegaEvent.
- OmegaIntent is separate: use ctx.intent?.payloadAs<YourPayload>() in flows (see example/lib/auth/auth_flow.dart).
- Extension: import omega_architecture.dart — OmegaEventPayloadExtension.payloadAs<T>() on OmegaEvent.

OMEGAEVENT / OMEGAINTENT — required id:
- OmegaEvent( and OmegaIntent( direct constructors require BOTH id: and name: (see package). channel.emit(OmegaEvent(name: 'x')) without id fails analysis.
- Preferred: OmegaEvent.fromName(MyEventEnum.foo, payload: ...) and OmegaIntent.fromName(MyIntentEnum.bar, payload: ...) — factories generate id unless you pass id: explicitly.
- FORBIDDEN (analyzer: abstract class can't be instantiated): OmegaEventName('navigation.intent') or OmegaIntentName('navigate.register') — [OmegaEventName] and [OmegaIntentName] are abstract contracts only. You MUST pass a concrete enum value, e.g. OmegaEvent.fromName(AppEvent.navigationIntent, payload: OmegaIntent.fromName(AppIntent.navigateLogin)).
- **`lib/omega/app_semantics.dart` (AppEvent / AppIntent)** — **canonical = same as modules:** `enum AppEvent with OmegaEventNameDottedCamel implements OmegaEventName { navigationIntent, … }` and `enum AppIntent with OmegaIntentNameDottedCamel implements OmegaIntentName { navigateLogin, navigateHome, … }` — **camelCase members only**; `.name` is the dotted wire ([OmegaIntentNameDottedCamel] / [OmegaEventNameDottedCamel]). **Mirror** `example/lib/omega/app_semantics.dart` and `_defaultAppSemanticsDartSource` (`omega init`). **FORBIDDEN in greenfield / CLI / AI output:** `enum AppEvent implements OmegaEventName { navigationIntent('navigation.intent'); const AppEvent(this.name); @override final String name; }` (and the same for `AppIntent` with string literals per case) — duplicates wires the mixin already derives and drifts from validate / navigator rules.
- **Feature `lib/<module>/*_events.dart`:** same — **`with OmegaIntentNameDottedCamel` / `with OmegaEventNameDottedCamel` only**; never hand-wired per-case string constructors there.
- NAVIGATION WRAP (OmegaNavigator): the OUTER event passed to OmegaEvent.fromName MUST have .name == `navigation.intent` exactly. [OmegaFlowManager.wireNavigator] only reacts to that name (or navigate.*). WRONG: `UserAuthEvent.navigationIntent` if UserAuthEvent has no such enum constant — analyzer: "no constant named 'navigationIntent'". FIX: (1) Add `navigationIntent` with `OmegaEventNameDottedCamel` (wire `navigation.intent`), OR (2) import `app_semantics.dart` and use `AppEvent.navigationIntent`. Do NOT invent MyModuleEvent.navigation without defining it.
- Inside an OmegaAgent subclass, prefer emit(someEvent.name, payload: ...) (inherited helper builds OmegaEvent with id) instead of hand-building OmegaEvent( without id.
''';

  /// **User prompt:** navigator listens for `navigation.intent`; inner `OmegaIntent.fromName` must use **enum**, not string wire.
  static const String _omegaAiNavigationChannelEmit = r'''
OMEGA — NAVIGATION FROM A BUTTON (channel + OmegaNavigator — copy this shape, do not invent):
- **Canonical emit (app-wide routes):** import `../omega/app_semantics.dart` or `package:<APP_NAME>/omega/app_semantics.dart` (APP_NAME = pubspec `name:`). Then:
  `OmegaScope.of(context).channel.emit(OmegaEvent.fromName(AppEvent.navigationIntent, payload: OmegaIntent.fromName(AppIntent.navigateHome)));`
  Replace `navigateHome` with another **`AppIntent` enum constant** you added in `app_semantics.dart` (camelCase member → dotted `navigate.*` wire matching your `OmegaRoute` ids). **Never** pass a raw wire string to `OmegaIntent.fromName`.
- **Outer event:** MUST resolve to wire name **`navigation.intent`** exactly — use **`AppEvent.navigationIntent`** unless the feature’s own `*Event` enum defines `navigationIntent` with `OmegaEventNameDottedCamel` to the same wire.
- **Inner intent:** **`OmegaIntent.fromName(AppIntent.someMember)`** — argument is always an **enum value** implementing [OmegaIntentName]. **FORBIDDEN:** `OmegaIntent.fromName('navigate.home')`, `OmegaIntent.fromName("navigate.x")`, `OmegaIntent.fromName(\`navigate.home\`)`, or comments saying “placeholder string” — those are **not valid Dart** for this API and will not type-check.
- **FORBIDDEN:** `OmegaIntent.fromName(MyIntent.start.name)` or any `.name` as the first argument — pass **`MyIntent.start`** (the enum constant), not a String.
- **Module outer + app inner:** only if you intentionally wrap with your module’s `*Event.navigationIntent`; inner payload is still `OmegaIntent.fromName(AppIntent....)` with a real `AppIntent` case.
- **Startup screen:** `OmegaConfig.initialFlowId` activates a flow only; it does **not** push an `OmegaRoute`. Set **`OmegaConfig.initialNavigationIntent:`** `OmegaIntent.fromName(AppIntent.navigateLogin)` (wire must match `OmegaRoute(id: ...)`), put **`initialNavigationIntent: runtime.initialNavigationIntent`** on **[OmegaScope]**, and set **`MaterialApp.home: OmegaInitialRoute(child: ...)`** (reads intent from scope — package example + `omega create app` template). Use **`OmegaInitialNavigationEmitter`** only when you must pass `intent:` explicitly without scope.
- **AppIntent enum spelling ↔ analyzer (no invented members):** `OmegaIntent.fromName(AppIntent.xxx)` only compiles if **`xxx` exists** on `AppIntent` in `lib/omega/app_semantics.dart`. WRONG: `AppIntent.navigateOrderDetails` when the enum has `navigateOrderDetail` (singular) or `navigateDeliveryDetail` — the analyzer error *There's no constant named …* means you mistyped or never added the case. **Add the member first**, then use the **exact** identifier everywhere (flows, agents, pages). Do not mix plural `…Details` and singular `…Detail`.
- **AppIntent wire ↔ `OmegaRoute.id` (navigator contract):** [OmegaNavigator] takes `intent.name`, strips the `navigate.` prefix, and looks up **`OmegaRoute(id: <that remainder>)`**. With [OmegaIntentNameDottedCamel], camelCase splits into dotted segments, lowercased — e.g. member `navigateDeliveryDetail` → wire `navigate.delivery.detail` → route id **`delivery.detail`**. WRONG: emitting `AppIntent.navigateDeliveryDetail` but registering `OmegaRoute(id: 'DeliveryDetail', …)` — cold navigation fails. When you add `AppIntent.navigateFooBar`, you MUST add **`OmegaRoute(id: 'foo.bar', …)`** (the exact post-`navigate.` segment) in `omega_setup.dart` (or document it for the human if JSON omits setup).
''';

  /// **User prompt:** canonical `lib/main.dart` — mirror **example/lib/main.dart** (PACKAGE GROUND TRUTH).
  static const String _omegaAiMainDartEntry = r'''
OMEGA — lib/main.dart (entrypoint — copy package example/lib/main.dart line-for-line structure; do not invent):
- **Imports:** `package:flutter/foundation.dart`, `package:flutter/material.dart`, `package:omega_architecture/omega_architecture.dart`, `import 'omega/omega_setup.dart';` (relative from `lib/main.dart`). **FORBIDDEN:** `package:omega_architecture/omega/...` internal paths.
- **main() async:** (1) If `kIsWeb && Uri.base.queryParameters['omega_inspector'] == '1'`, `runApp(MaterialApp(..., home: const OmegaInspectorReceiver())); return;` (2) `final runtime = OmegaRuntime.bootstrap(createOmegaConfig);` where `createOmegaConfig` is `OmegaConfig Function(OmegaChannel)` from `omega_setup.dart`. (3) Optional VM inspector: `if (kDebugMode && !kIsWeb) { await OmegaInspectorServer.start(runtime.channel, runtime.flowManager); }` (4) `runApp(OmegaScope(channel: runtime.channel, flowManager: runtime.flowManager, initialFlowId: runtime.initialFlowId, initialNavigationIntent: runtime.initialNavigationIntent, child: MyApp(navigator: runtime.navigator)));`
- **OmegaScope cold start (do not skip):** **`initialFlowId: runtime.initialFlowId`** and **`initialNavigationIntent: runtime.initialNavigationIntent`** are **both required** whenever the app uses **`MaterialApp(home: OmegaInitialRoute(...))`** (standard shell). **FORBIDDEN:** any **string literal** on `OmegaScope` for `initialFlowId` (e.g. `'Auth'`, `'authFlow'`, `'Home'`) — those must come **only** from `OmegaConfig` via `OmegaRuntime` so they stay aligned with `createOmegaConfig`. **FORBIDDEN:** omitting **`initialNavigationIntent`** on `OmegaScope` while using `OmegaInitialRoute` (first route is undefined).
- **MyApp:** `StatelessWidget` with `final OmegaNavigator navigator`; `MaterialApp(navigatorKey: navigator.navigatorKey, title: ..., theme: ..., home: OmegaInitialRoute(child: const RootHandler(showInspector: true)));` — **`OmegaInitialRoute`** reads startup navigation from **[OmegaScope.initialNavigationIntent]** (set from `runtime`); do **not** pass `OmegaIntent?` through `MyApp` constructors. **`RootHandler`** (exported from `omega_architecture`) wraps **[OmegaFlowActivator]** + debug AppBar; use **`showInspector: true`** when you want **[OmegaInspectorLauncher]** on web in debug. Use **`RootHandler(wrapWithScaffold: false)`** when each route provides its own `Scaffold`.
- **FORBIDDEN:** `MaterialApp` with only `initialRoute: '/'` / `routes: {'/': ...}` as the sole Omega shell — registered [OmegaRoute] ids are not `/`. Use `home:` + [OmegaNavigator] + [OmegaInitialRoute].
- **FORBIDDEN:** hand-rolled `_RootHandler` + `WidgetsBinding.instance.addPostFrameCallback` to emit the first `navigation.intent` if [OmegaConfig.initialNavigationIntent] + [OmegaInitialRoute] already define startup navigation (duplicate or races).
''';

  /// **User prompt:** `viewState` + streams drive rebuilds; typedef is `(context, state)` — not Provider’s multi-arg builders.
  static const String _omegaAiAgentUiStateListening = r'''
OMEGA — UI LISTENS TO AGENT STATE (read before any OmegaAgentBuilder / OmegaScopedAgentBuilder):
- **Where state lives:** [OmegaStatefulAgent] keeps typed UI data in [viewState] (T). The agent updates the UI by calling [setViewState(next)] from [onAction] or async helpers — not by returning widgets.
- **How Flutter rebuilds:** the package subscribes to [stateStream] / [viewStateStream] (same broadcast stream). [OmegaAgentBuilder] and [OmegaScopedAgentBuilder] listen and call [setState] when [viewState] changes. You do not wire StreamBuilder manually unless you choose the advanced path below.
- **Builder typedef (package law):** `OmegaAgentWidgetBuilder<TState>` = `Widget Function(BuildContext context, TState state)` — **exactly two parameters: context + state only.** The agent is passed on the **widget** ctor: `OmegaAgentBuilder<MyAgent, MyViewState>(agent: widget.agent, builder: (context, state) => ...)`. There is **no** `agent` parameter inside the builder closure, **no** `Widget? child`, **no** third/fourth arguments.
- **OmegaScopedAgentBuilder<TAgent, TState>:** uses the **same** two-parameter builder `(context, state)`. It resolves `TAgent` from [OmegaAgentScope] (route) or from [OmegaFlow.uiScopeAgent] when [OmegaFlowExpressionBuilder] wraps the subtree in scope. WRONG (does not match the package): `(context, MyAgent agent, MyViewState viewState)`, `(context, agent, state, child)`, or any Consumer/Selector-style signature copied from Riverpod/Provider.
- **Advanced (optional):** `StreamBuilder<MyViewState>(stream: agent.stateStream, initialData: agent.viewState, ...)` — remember broadcast streams may not replay; read [viewState] first if you need the current snapshot before the first event.
- **FORBIDDEN:** inventing `context.watch<SomeAgent>()`, extra builder parameters, or “pass the agent into the builder” — the API is fixed in `omega_agent_builder.dart`; mirror `example/lib/auth/ui/auth_page.dart` for classic [OmegaAgentBuilder] with `widget.agent`.
- **FORBIDDEN:** `scope.agentManager`, `scope.agentManager.getAgent(...)`, or any agent lookup on [OmegaScope] — [OmegaScope] has **no** agentManager; that API is not in `omega_architecture`.
''';

  /// **User prompt:** separation of concerns — flow orchestrates, behavior maps context→actionId, agent executes async work.
  static const String _omegaAiRolesFlowAgentBehavior = r'''
OMEGA ROLES — Flow vs Agent vs Behavior (do not merge into one class):
- Flow (OmegaFlow / OmegaWorkflowFlow): Orchestrates one feature or screen journey. Receives flowManager.handleIntent → onIntent; receives channel events → onEvent. Publishes OmegaFlowExpression for UI (StreamBuilder on flow.expressions). May emit channel events to ask agents or trigger navigation. Think: steps, wizard, “where is this feature in the process”. Registered in OmegaConfig; UI uses flowManager.getFlow(flowId) or getFlowFlexible(flowId) with the same id as super(id: ...) in the flow class. Optional override `OmegaAgent? get uiScopeAgent => ...` when the page uses `OmegaFlowExpressionBuilder` + `OmegaScopedAgentBuilder` without wrapping the route in `OmegaAgentScope` — same agent reference as in `OmegaConfig.agents`. **Other ctor params** (offline queue, repos) are **not** agents: inject from `createOmegaConfig` once; see example `OrdersFlow` + `offlineQueue`.
- Agent (OmegaAgent / OmegaStatefulAgent): Listens to the event bus; OmegaAgentBehaviorEngine maps matching intents/events to action ids; the agent runs onAction (async OK, APIs, channel.emit results). OmegaStatefulAgent adds viewState + setViewState for OmegaAgentBuilder. Agents do not replace flows: often the flow coordinates and the agent does side-effect work (load data, call backend).
- Behavior (*_behavior.dart*, OmegaAgentBehaviorEngine): Declarative rules only — condition(ctx) → OmegaAgentReaction(actionId, payload). No async, no HTTP, no setViewState. First matching rule wins. The agent implements onAction for each actionId. Keeps the routing table (behavior) separate from execution (agent).
''';

  /// **User prompt:** workflow steps + `emitExpression`/`failStep` signatures; flow context has no agent shortcuts.
  static const String _omegaAiOmegaWorkflowFlow = r'''
OMEGA WORKFLOW FLOW (OmegaWorkflowFlow — omega_workflow_flow.dart):
- Constructor: MUST pass both `id` and `channel` to `super` — e.g. `MyFlow(OmegaEventBus channel) : super(id: 'MyFlow', channel: channel);` OR `MyFlow({required super.channel}) : super(id: 'MyFlow');` (never omit `channel`).
- **defineStep — exact typedef (package law):** `typedef OmegaWorkflowStepHandler = FutureOr<void> Function();` → **`defineStep(String id, void Function() handler)`** — the handler takes **ZERO arguments**. RIGHT: `defineStep('start', () { emitExpression('idle'); });` or `defineStep('work', () async { ... });`. **FORBIDDEN:** `defineStep('start', (OmegaFlowContext ctx) { ... })`, `(ctx) { ... }`, or any parameter on the step closure — **does not compile**; [OmegaFlowContext] exists **only** in [onIntent] / [onEvent], not inside step handlers.
- **Where to use ctx:** ONLY in `@override void onIntent(OmegaFlowContext ctx)` and `@override void onEvent(OmegaFlowContext ctx)`. From there call `startAt('stepId')` / `next('stepId')` / `failStep` / `channel.emit` / `emitTyped` — step handlers use **no** ctx; they may call `emitExpression`, `next`, `completeWorkflow`, `failStep`, `channel`, etc. on `this`.
- **Avoid double UI emits:** WRONG pattern: in `onEvent` call `emitExpression('success', payload: ...)` **and** `next('success')` when the `'success'` step handler **also** calls `emitExpression('success')` — you duplicate the same expression type. RIGHT: either (A) `onEvent` only `next('success')` / `next('failure')` and put **all** user-facing `emitExpression` for that transition **inside** the step handler, OR (B) emit once from `onEvent` and make the target step only `completeWorkflow()` / cleanup **without** re-emitting the same `type` string.
- [defineStep] only registers handlers — nothing runs until [startAt]('stepId') or [next]('stepId') from [onStart], [onIntent], or [onEvent]. Typical [onStart]: `startAt('start');` (optional `emitExpression` before if you need an initial UI type).
- Base class provides **default empty** [onIntent] / [onEvent]; **override** when you need intents/events (same rules as [OmegaFlow]).
- OmegaFlowContext exposes ONLY: [event], [intent], [memory]. FORBIDDEN (undefined): ctx.getAgentViewState, ctx.getAgent, any read of OmegaStatefulAgent.viewState from the flow. Put credentials or form data in the intent payload (payloadAs<T>()) or in memory / channel events.
- When you override onEvent(OmegaFlowContext ctx): ctx.event is OmegaEvent? (single object). Use event?.name, event?.payload, event?.payloadAs<T>(). There is no overload that takes two positional event arguments.
- When you override onIntent: compare with intent?.name == MyIntent.start.name (not intent == MyIntent.start — [OmegaIntent] is not the enum).
- emitExpression(String type, {dynamic payload}) — payload is a NAMED parameter only: emitExpression('error', payload: event?.payload).
- failStep(String code, {String? message}) — only ONE positional argument (the code). WRONG: failStep('start', ctx.event?.payload). RIGHT: failStep('start', message: ctx.event?.payloadAs<OmegaFailure>()?.message ?? ctx.event?.payload?.toString()).
- next(String stepId) and startAt(String stepId): one positional step id each; each emits `workflow.step` then runs the handler (which usually calls emitExpression for UI types like `loading`/`success`/`error` and may call next/completeWorkflow).
- Contract [emittedExpressionTypes] must include `workflow.step`, `workflow.error`, `workflow.done` plus any custom types you pass to emitExpression (e.g. `idle`, `loading`).
''';

  /// **User prompt:** behavior vs agent split + `emit`/`onAction`/`addRule` details; blocks BLoC-style behavior bodies.
  static const String _omegaAiAgentBehaviorApi = r'''
OMEGA AGENT + BEHAVIOR — read the real API before coding (same package):
- Canonical examples: example/lib/auth/auth_behavior.dart (rules) + example/lib/auth/auth_agent.dart (onAction, setViewState, emit). Generated code must follow that split — not a single fixed "requested → loadMock" pattern; that was only an illustration.

OmegaAgentBehaviorEngine (*_behavior.dart*) — architecture, not a recipe count:
- Valid shape: (1) constructor calling addRule(OmegaAgentBehaviorRule(...)) one or MANY times — each rule is one condition → one OmegaAgentReaction(actionId, payload: ...). First matching rule wins (registration order matters). (2) OR override evaluate(OmegaAgentBehaviorContext ctx) and return the first matching reaction yourself.
- API detail: addRule has exactly ONE positional argument — the rule object. WRONG (does not compile): addRule(condition: (ctx) => ..., reaction: (ctx) => ...). RIGHT: addRule(OmegaAgentBehaviorRule(condition: (ctx) => ..., reaction: (ctx) => OmegaAgentReaction('actionId', payload: ...)));
- Conditions are whatever the module needs: ctx.event?.name == MyEvent.x.name, ctx.intent?.name == MyIntent.y.name, boolean combinations (|| / &&), ctx.intent?.payload is String (or other runtime checks), typed payloads via ctx.event?.payloadAs<MyTypedEvent>() / ctx.intent?.payloadAs<...>() when applicable. Different features ⇒ different rules and different actionIds.
- Multi-rule style (order/admin modules): one rule for "start or retry or refresh" intents → same reaction (e.g. load list); another rule for a specific intent with payload guard (&& ctx.intent?.payload is String) → reaction with payload passed to onAction; another rule when ctx.event?.name matches a domain event → reaction whose payload is built from ctx.event?.payloadAs<MyShippedEvent>()?.field.
- Reactions stay small: string action id + optional payload for the agent. No business/async in the behavior file.

OmegaStatefulAgent (*_agent.dart*):
- Base [OmegaAgent] exposes Map<String, dynamic> state — loose key/value bag for behavior rules if needed; it is NOT your typed UI model and has no copyWith for that.
- Typed screen state lives in viewState (TState) + setViewState(next). Reactive stream: [stateStream] and [viewStateStream] are the same (not a generic agent.stream). [OmegaAgentBuilder] / [OmegaScopedAgentBuilder] subscribe and rebuild the subtree when viewState changes — the **builder** is always `Widget Function(BuildContext, TState)` only (agent passed on the widget ctor for OmegaAgentBuilder; scoped builder resolves agent from scope). Broadcast: new listeners do not receive the current viewState until the next setViewState — if awaiting firstWhere(!isLoading), check viewState first when already idle.
- When TState has copyWith, use: setViewState(viewState.copyWith(...)) — read the current snapshot from viewState, never from state for UI fields.
- Optional lookup in a List field of viewState (e.g. cart lines, orders): prefer indexWhere + null if missing, or a small loop — do NOT use firstWhere with orElse: () => null as SomeType? (unsafe cast, bad style).
- WRONG: state.copyWith(...) — Map does not define copyWith; the analyzer reports copyWith on Map.
- onAction(String action, dynamic payload): switch/if on action for every actionId emitted by the behavior (there may be many). Async, mocks, setViewState, channel.emit belong here (or private helpers called from onAction).
- FORBIDDEN in switch(action): `case SomeEnum.someCase.name` — [Enum.name] is not a compile-time constant, so the analyzer reports const_eval_extension_method / invalid case. Use STRING LITERALS that match [OmegaAgentReaction] ids (example auth_agent: case "doLogin": / case "doLogout":). If you keep an ActionId enum for documentation, compare outside switch: `if (action == ActionId.loadFeed.name) { ... }` or still use case 'loadFeed': in switch.

OmegaAgent.emit (omega_agent.dart — also inherited on your *Agent):
- Signature: void emit(String name, {dynamic payload}) — first argument MUST be a String (event name), NOT an enum value object.
- CORRECT: emit(MediaUploadEvent.requested.name, payload: file) or emit(MyEvent.succeeded.name, payload: result).
- WRONG: emit(MediaUploadEvent.selectImage) — type error (enum is not String) and models invent selectImage/submit/retry on *Event when only requested/succeeded/failed exist. Add new cases to *_events.dart* first, then use .name, OR reuse existing enum cases / literal strings that behavior rules already match.
- From *Page* widgets: prefer scope.channel.emit(OmegaEvent.fromName(MediaUploadEvent.requested, payload: ...)) or flowManager.handleIntent so behavior sees ctx.event; if calling agent.emit from UI, same rule: string name only — agent.emit(MediaUploadEvent.requested.name, ...).

FORBIDDEN in behavior (breaks Omega): Stream / async* / yield, handleEvent, mutating view state, importing/using OmegaAgentMessage, msg.type (OmegaAgentMessage belongs only in onMessage on the agent; fields: from, to, action, payload — use msg.action there).

OmegaAgentMessage (only in *_agent.dart* onMessage): compare msg.action. There is NO .type on OmegaAgentMessage.
''';

  /// **User prompt:** per-file contract (MASTER CHECKLIST); main cross-artifact coherence guard for full modules.
  static const String _omegaAiCompleteArtifactGuide = r'''
OMEGA — MASTER CHECKLIST BY FILE (read as a contract between five artifacts + omega_setup):

GLOBAL INVARIANT — ONE MODULE ID FOR THE FLOW/ROUTE:
- Pick one flow id used everywhere (string or `enum AppFlowId with OmegaFlowIdEnumWire` + `.id` / pass enum to [OmegaFlowActivator]). MUST match: (1) Flow `super(id: ...)`, (2) Page `getFlow(...)` / [OmegaFlowManager.getFlowFlexible], [OmegaFlowActivator](flowId:), (3) `OmegaRoute(id: ...)`. Same idea for agents with [OmegaAgentId]. Wrong ids ⇒ "Flow not registered" or silent no-op.
- **Typed ids (`lib/omega/app_runtime_ids.dart`):** After `omega init`, apps have `AppFlowId` / `AppAgentId` enums (see [OmegaFlowIdEnumWire] / [OmegaAgentIdEnumWire]). Prefer `super(id: AppFlowId.MyModule.id)` / `super(id: AppAgentId.MyModule.id)` with `import 'package:THE_EXACT_PUBSPEC_NAME/omega/app_runtime_ids.dart';` where THE_EXACT_PUBSPEC_NAME is the **literal** `name:` from this app's pubspec (module-generation prompts include it as **PROJECT PUBSPEC NAME** — copy that string exactly, never a marketing slug). Wire string must match the enum member. **CLI:** `omega g ecosystem <Name>` merges **both** enums; `omega g agent <Name>` merges **AppAgentId** only; `omega g flow <Name>` merges **AppFlowId** only (agent file must already exist). If you emit JSON for an app that already has this file, add the new `MyModule` member to **both** enums when you add a full module, or only the relevant enum for agent-only / flow-only stubs — never leave `AppAgentId.Foo` in code without `Foo` listed in the enum body.

━━ 0) lib/omega/app_runtime_ids.dart — TYPED FLOW/AGENT WIRE IDS (when present) ━━
- Purpose: single source of truth for `super(id: ...)` strings on flows and agents; keeps [OmegaFlowExpressionBuilder] / [getFlowFlexible] aligned with analyzer-friendly enums.
- Typical imports in feature files: `import 'package:THE_EXACT_PUBSPEC_NAME/omega/app_runtime_ids.dart';` (same spelling as pubspec `name:` / **PROJECT PUBSPEC NAME** in the user prompt).
- Agent ctor: `: super(id: AppAgentId.<Module>.id, channel: channel, behavior: ...)` (same `<Module>` identifier the CLI would add — PascalCase / sanitized from the module folder name).
- Flow ctor: `: super(id: AppFlowId.<Module>.id, channel: channel)` (or `required super.channel` pattern — match existing app flows).
- If the target project has **no** `app_runtime_ids.dart` (legacy), raw strings `super(id: 'MyModule')` are still valid; when the file exists, prefer enums over duplicate string literals.
- **AI / JSON fixes:** If analyzer reports undefined `AppAgentId.X` or `AppFlowId.X`, either add `X,` to the corresponding enum in `lib/omega/app_runtime_ids.dart` or change the feature file to use a string id that matches an existing enum member — do not mix a typed reference with a missing enum value.

━━ 1) *_events.dart — NAMES + PAYLOAD TYPES + VIEW MODEL ━━
Purpose: Declare every wire name the rest of the module may use; no business logic.
Must include:
- `import 'package:omega_architecture/omega_architecture.dart';` first.
- **`enum <Module>Intent with OmegaIntentNameDottedCamel implements OmegaIntentName { ... }` — REQUIRED shape for this file:** only camelCase member names (no string args per case). Wire = lowercased dotted split from camelCase (e.g. `${lower}Start` → `$lower.start`, `loginRequested` → `login.requested`). Same for **Event** with `OmegaEventNameDottedCamel`.
- `enum <Module>Event with OmegaEventNameDottedCamel implements OmegaEventName { ... }` — include member `navigationIntent` (wire `navigation.intent`) if this module emits navigator payloads; add `${lower}Requested`, etc., as camelCase members.
- **FORBIDDEN in `*_events.dart` (feature modules):** hand-wired “BLoC style” enums — `enum FooIntent implements OmegaIntentName { bar('a.b'); const FooIntent(this.name); @override final String name; }` / the same for `OmegaEventName`. That pattern is **not** the Omega template anywhere you control greenfield code.
- **`lib/omega/app_semantics.dart`:** **same REQUIRED shape** as modules — `enum AppEvent with OmegaEventNameDottedCamel implements OmegaEventName { … }`, `enum AppIntent with OmegaIntentNameDottedCamel implements OmegaIntentName { … }` (see **example/lib/omega/app_semantics.dart**). **FORBIDDEN:** `AppIntent.navigateLogin('navigate.login')` + `const AppIntent(this.name); @override final String name;` on app-wide enums in generated apps — use **`navigateLogin,`** (identifier only) so wire stays `navigate.login` via the mixin.
- Optional `class ... implements OmegaTypedEvent { @override String get name => <Module>Event.xxx.name; ... }` for emitTyped / payloadAs flows.
- Plain `class <Module>ViewState { final ...; copyWith; static const idle ... }` — NOT OmegaViewState; NOT package types for UI state.
- Optional row/DTO classes (lists in UI).
Cross-file rules:
- Every `OmegaEvent.fromName(<Module>Event.foo)` / `OmegaIntent.fromName(<Module>Intent.bar)` must reference enum cases defined HERE.
- App-wide `AppEvent` / `AppIntent`: import shared `app_semantics.dart`; do NOT duplicate those enums in this file.
Forbidden: implements OmegaEvent/OmegaIntent on enums; OmegaEventName(...); OmegaViewState; equatable-only imports to “fix” analyzer.

━━ 2) *_behavior.dart — DECLARATIVE ROUTING TO THE AGENT ━━
Purpose: When the bus delivers an event OR a context with intent, decide which agent action runs.
Must include:
- `import 'package:omega_architecture/omega_architecture.dart';` + `import '<lower>_events.dart';` (+ app_semantics if rules reference AppEvent/AppIntent).
- `class <Module>Behavior extends OmegaAgentBehaviorEngine` with constructor calling `addRule(OmegaAgentBehaviorRule(condition: (ctx) => ..., reaction: (ctx) => OmegaAgentReaction('actionId', payload: ...)))` — exactly one OmegaAgentBehaviorRule per addRule positional arg.
- Conditions: `ctx.event?.name == <Module>Event.xxx.name`, `ctx.intent?.name == <Module>Intent.yyy.name`, combine with && / ||; use payloadAs<T>() when typed.
Cross-file rules:
- Each `OmegaAgentReaction('actionId', ...)` string MUST match a `case "actionId":` (or 'actionId') branch in the agent’s `onAction` — string literals only in switch.
- No async, no setViewState, no HTTP, no Stream/yield, no handleEvent, no OmegaAgentMessage here.

━━ 3) *_agent.dart — EXECUTION + VIEW STATE + BUS OUTPUT ━━
Purpose: Run async work; update viewState; emit domain events the flow listens to.
Must include:
- Imports: omega_architecture, `<lower>_events.dart`, `<lower>_behavior.dart`.
- `class <Module>Agent extends OmegaStatefulAgent<<Module>ViewState>` (or OmegaAgent if no typed UI state — rare for generated modules).
- Constructor: `super(id: AGENT_ID, channel: channel, behavior: <Module>Behavior(), initialState: <Module>ViewState.idle)` — Prefer `AppAgentId.<Module>.id` when `lib/omega/app_runtime_ids.dart` exists; otherwise a string literal matching the module id. Must match `agents:` entry id semantics in setup.
- `@override void onMessage(OmegaAgentMessage msg) {}` or real handling; use `msg.action` not msg.type.
- `@override void onAction(String action, dynamic payload) { switch (action) { case "id": ... } }` with string cases for every behavior actionId.
- Use `setViewState(viewState.copyWith(...))` for UI model; never `state.copyWith` for view fields.
- `emit` / `channel.emit` / `channel.emitTyped`: follow String .name rules for emit(); prefer channel for events the flow must see.
- `OmegaAgentContract`: set listenedEventNames / acceptedIntentNames honestly for debug; `{}` acceptable on shared global channel if rules only use ctx from same bus (see template).
Cross-file rules:
- Emitted event NAMES must appear in Flow contract listenedEventNames / flow onEvent if the flow should react.

━━ 4) *_flow.dart — JOURNEY + EXPRESSIONS FOR UI + BRIDGE TO AGENT ━━
Purpose: Translate intents from handleIntent into channel signals the agent understands; map domain events to OmegaFlowExpression + optional navigation.
Must include:
- omega_architecture + `<lower>_events.dart` (+ app_semantics if navigation uses AppEvent/AppIntent) + import `<lower>_agent.dart` when the flow holds `final <Module>Agent agent` for `uiScopeAgent`.
- `extends OmegaFlow` or `OmegaWorkflowFlow`; `super(id: FLOW_ID, channel: channel)` — Prefer `AppFlowId.<Module>.id` when `app_runtime_ids.dart` exists; else string FLOW_ID. Must equal page getFlow/activate / OmegaFlowExpressionBuilder `flowId` (align with `OmegaRoute(id:)` / navigate.*; [OmegaFlowManager.getFlowFlexible] matches case-insensitively if needed).
- **If the page uses `OmegaFlowExpressionBuilder` + `OmegaScopedAgentBuilder` without `OmegaAgentScope` on the route:** constructor takes `{required super.channel, required this.agent}` (forwards [OmegaFlow.channel]), `: super(id: FLOW_ID);`, `final <Module>Agent agent;`, `@override OmegaAgent? get uiScopeAgent => agent;`. The **same** `agent` instance must appear in `OmegaConfig.agents` and in `MyModuleFlow(..., agent: thatVariable)` — never two `MyModuleAgent(channel)` calls.
- **Extra dependencies (NOT the agent):** colas offline (`OmegaOfflineQueue`), repos, clients HTTP, `ChangeNotifier`, etc. — el flujo los recibe **por constructor** además de `channel` + `agent`; se crean **una vez** en `createOmegaConfig` (`final offlineQueue = OmegaMemoryOfflineQueue();`) y se pasan **nombrados** al flujo: `OrdersFlow(channel: ns, agent: ordersAgent, offlineQueue: offlineQueue)`. No instanciar servicios compartidos dentro del flujo con `new` en cada arranque si deben ser singleton por app. `omega g ecosystem` solo genera `channel` + `agent`; deps extra van en omega_setup **a mano** cuando el dominio las pide.
- `@override OmegaFlowContract? get contract => OmegaFlowContract(...)` OR `OmegaFlowContract.fromTyped(...)` — lists must include every intent name the page will handleIntent and every event name the flow’s onEvent reads; include all `emitExpression` type strings used (for OmegaWorkflowFlow add 'workflow.step', 'workflow.error').
- `onIntent`: read `ctx.intent?.name == <Module>Intent.xxx.name`, payload via `payloadAs<T>()`; emit channel events / emitTyped so behavior/agent pick them up.
- `onEvent`: read `ctx.event?.name`, `payloadAs<T>()`; call `emitExpression('loading'|'success'|'error'|...)`, `next`/`startAt`/`failStep`/`completeWorkflow` as appropriate for OmegaWorkflowFlow. **OmegaWorkflowFlow:** `defineStep(id, () { ... })` / `() async { ... }` — **no** `(OmegaFlowContext ctx)` on the step closure. Do not `emitExpression('success'|'error', ...)` in `onEvent` **and** again inside the step you `next` into for the **same** UI type — choose one place (see `_omegaAiOmegaWorkflowFlow`).
- NEVER read agent viewState from flow; pass data via intent payload, memory, or events.
Cross-file rules:
- If the page only handleIntents start/retry, contract acceptedIntentNames must list their .name values.
- Navigation to another route: outer `OmegaEvent.fromName(AppEvent.navigationIntent or <Module>Event.navigationIntent, payload: OmegaIntent.fromName(...))`.

━━ 5) ui/*_page.dart — WIDGETS ONLY; ENTRY + RENDER ━━
Purpose: Build Flutter UI; subscribe to flow.expressions and/or OmegaAgentBuilder (or scoped helpers).
Must include:
- `flutter/material.dart`, `omega_architecture`, `../<lower>_events.dart`; if Page has `required <Module>Agent agent` or OmegaAgentBuilder<<Module>Agent,...> or OmegaScopedAgentBuilder<<Module>Agent,...> then `../<lower>_agent.dart`.
- Obtain scope: `OmegaScope.of(context)` — .channel, .flowManager, .initialFlowId, .initialNavigationIntent.
- Flow-driven UI: prefer `OmegaFlowExpressionBuilder(flowId: 'FLOW_ID', builder: (context, exp) => ...)` OR `getFlow('FLOW_ID')` + `StreamBuilder<OmegaFlowExpression>(stream: flow!.expressions, ...)` (same FLOW_ID as Flow super(id:)). If the builder nests `OmegaScopedAgentBuilder`, set Flow `uiScopeAgent` + shared agent in omega_setup (see section 4).
- Entry: wrap route with `OmegaFlowActivator(flowId: 'FLOW_ID', child: ...)` (only those ctor args + optional `useSwitchTo` — **no** `onActivate` or other callbacks) OR once `activate('FLOW_ID')` in didChangeDependencies; then EITHER `handleIntent(OmegaIntent.fromName(<Module>Intent.${lower}Start))` OR `channel.emit(OmegaEvent.fromName(<Module>Event.${lower}Requested))` — must match what behavior/flow listen to (see SCREEN ENTRY rules).
- Agent-driven lists: EITHER `OmegaAgentScope` at route + `OmegaScopedAgentBuilder` OR `OmegaFlowExpressionBuilder` + `OmegaScopedAgentBuilder` with Flow `uiScopeAgent` OR classic `OmegaAgentBuilder(..., agent: widget.agent, ...)` — **builder closure: `(BuildContext, TState)` only** (same as typedef `OmegaAgentWidgetBuilder`); never construct a new Agent in build(); never Provider-style `(context, agent, state, child)`.
- Navigator: `channel.emit(OmegaEvent.fromName(...navigationIntent..., payload: OmegaIntent.fromName(...)))` — not handleIntent alone for navigate.*.
- Reactive wait: use `agent.stateStream` / `viewStateStream` (same stream); remember broadcast does not replay current viewState.
Forbidden: `scope.agentManager`, `scope.agentManager.getAgent(...)`, `scope.getAgent` (all invented — [OmegaScope] has channel, flowManager, initialFlowId, initialNavigationIntent only); flow.onIntent from widget; OmegaFlowContext in UI; const Page if non-const agent required.

━━ 6) omega_setup.dart (human wiring after JSON — mention in reasoning) ━━
━━ CANONICAL omega_setup.dart (package example — mirror this) ━━
Ground-truth file: `example/lib/omega/omega_setup.dart` (included in PACKAGE GROUND TRUTH for AI). Registration must match it:
- In `createOmegaConfig(OmegaChannel channel)`: **one** agent instance per module → reuse the **same** variable in `agents: <OmegaAgent>[...]` and in `flows: <OmegaFlow>[ MyFlow(channel: ns, agent: myAgent), ... ]`. Never two `MyModuleAgent(...)` for the same module.
- `flows:` is a list of **constructor calls** with the same named args as *_flow.dart* (`channel:`, `agent:` when `uiScopeAgent`, optional `offlineQueue:` etc.). FORBIDDEN: bare `MyFlow` without `(...)`.
- Example pattern: `final authNs = channel.namespace('auth');` + `AuthAgent(authNs)` + `AuthFlow(channel: authNs, agent: authAgent)` — see example app.
- `initialFlowId:` e.g. `AppFlowId.authFlow.id` when using `app_runtime_ids.dart`; **`initialNavigationIntent:`** `OmegaIntent.fromName(AppIntent.navigateLogin)` for standard apps (same value on **`OmegaScope.initialNavigationIntent`** and **`MaterialApp.home: OmegaInitialRoute(child: ...)`**). **Not optional** when you ship Login+Home — without it the first screen is undefined. `intentHandlerRegistrars:` optional; routes pass shared agents into `builder:` (`OmegaLoginPage(authAgent: authAgent)`), `OmegaRoute.typed<T>` when needed.
- **`OmegaRoute` ids for global intents:** With [OmegaIntentNameDottedCamel], `AppIntent.navigateLogin.name` is `navigate.login` → navigator looks up route id **`login`** (substring after `navigate.`). `navigate.home` → id **`home`**. Using `id: 'Auth'` for login breaks cold start. For any **`AppIntent` member**, **`OmegaRoute.id` MUST equal the navigator destination string**: take `AppIntent.member.name` (the wire), remove the leading `navigate.` once, and use the remainder as `id:` (keep any inner dots). Example: `navigateDeliveryDetail` → **`delivery.detail`**. WRONG: PascalCase ids like `OrderDetails` when the wire expects `delivery.detail`. WRONG: `AppIntent.navigateOrderDetails` when the enum only has `navigateOrderDetail` / `navigateDeliveryDetail` — **declare the member and use the exact same identifier** in `OmegaIntent.fromName`.
- REQUIRED imports (or analyzer: "function/class isn't defined"): from `lib/omega/omega_setup.dart` use relative `../<folder>/<lower>_flow.dart`, `../<folder>/<lower>_agent.dart`, `../<folder>/ui/<lower>_page.dart` OR `package:<app_name>/...` matching pubspec `name:`.
- FORBIDDEN: duplicate `import` lines (same URI twice). Each `*_agent`, `*_flow`, `*_page` path appears at most once at the top of omega_setup.dart.
- **Single agent instance per module:** `final myModuleAgent = MyModuleAgent(channel);` then `agents: <OmegaAgent>[..., myModuleAgent]` and, when the flow defines `uiScopeAgent`, `flows: <OmegaFlow>[..., MyModuleFlow(channel: channel, agent: myModuleAgent)]` — never `MyModuleFlow(channel)` plus a separate `MyModuleAgent(channel)` for the same module.
- **Flows with extra ctor args (ej. example `OrdersFlow`):** además de `channel` y `agent`, el flujo puede requerir `offlineQueue`, repositorios, etc. Declara esos valores **una vez** arriba en `createOmegaConfig` y pásalos nombrados al constructor del flujo. `registerInOmegaSetup` / `omega g ecosystem` no inventan deps extra — hay que alinear *_flow.dart* con omega_setup.
- `flows: <OmegaFlow>[ ..., NewsFlow(channel), ]` — each item is a **constructor call** matching the Flow’s ctor in *_flow.dart* (add named `agent:` when the flow requires it). FORBIDDEN: bare `NewsFlow` without parentheses in the list; FORBIDDEN: treating Flow as a function — it is a class.
- `agents: <OmegaAgent>[ ..., MyAgent(channel), ]` same rule; read ctor in *_agent.dart* (positional vs `{required OmegaEventBus channel}`).
- Routes: `OmegaRoute(id: '...', builder: ...)` — **unique** `id` per route in the whole `routes:` list. **FORBIDDEN:** two `OmegaRoute(id: 'UserManagement', ...)` or same `id` twice for any string — [OmegaNavigator] lookup is by id; duplicates are always wrong. Page with `required agent` needs `final x = MyAgent(...);` once and `MyPage(agent: x)`. Decoupled page (`const MyPage()` + `OmegaScopedAgentBuilder` inside `OmegaFlowExpressionBuilder`) needs **flow `uiScopeAgent`** + shared agent variable as above, not a second agent construction.
- **agents:** list each **distinct** agent reference **once** — FORBIDDEN: the same variable twice (e.g. `..., orderManagementAgent, orderManagementAgent,`) or two `FooAgent(channel)` ctor lines for the same module. **flows:** FORBIDDEN: two `UserManagementFlow(...)` lines — one registration per flow. **CI / local:** `omega validate` rejects these duplicates automatically.
- initialFlowId must match the entry flow’s `super(id: ...)` string when this module is first screen.
- **Product shell — login then home:** When defining full-app wiring (`omega_setup`, `routes`, `app_semantics`): assume **Login** + **Home** exist. **initialFlowId** activates the **login/auth** flow. **initialNavigationIntent** must open the **login** route first (e.g. `OmegaIntent.fromName(AppIntent.navigateLogin)` — wire must match `OmegaRoute` for login). **Home** hosts **global navigation** to the rest of the app. On successful login, emit `OmegaEvent.fromName(AppEvent.navigationIntent, payload: OmegaIntent.fromName(AppIntent.navigateHome))` (or equivalent module outer event + inner intent). Extend `AppIntent` / `routes:` so **navigateLogin** and **navigateHome** both exist; do not cold-start on Home unless the product spec explicitly says “logged-in-only demo”.
- `lib/omega/app_semantics.dart`: shared `AppEvent` / `AppIntent` with `OmegaEventNameDottedCamel` / `OmegaIntentNameDottedCamel` (camelCase → dotted wire). `omega init` creates minimal `navigationIntent` + `navigateHome`; add **`navigateLogin`** (and matching route id) when you add a login module — extend enums there for cross-module names — do not duplicate app-wide enums inside feature `*_events.dart`; import `../omega/app_semantics.dart` or `package:THE_EXACT_PUBSPEC_NAME/omega/app_semantics.dart` where needed (THE_EXACT_PUBSPEC_NAME = pubspec `name:`).

COHERENCE SELF-TEST (model should mentally verify before answering):
- [ ] Every behavior actionId has agent switch case string.
- [ ] Every enum case used in flow/page/agent exists in *_events.dart*.
- [ ] FLOW_ID identical in Flow, Page, Route; if using AppFlowId/AppAgentId, enum members exist in lib/omega/app_runtime_ids.dart.
- [ ] Flow contract sets include all emitted expression types and listened event names used in onEvent.
- [ ] No forbidden APIs (OmegaViewState, case Enum.name in switch, emit(enumWithoutDotName), etc.).
- [ ] omega_setup imports every Flow/Agent/Page class used; flows/agents lists use constructor calls (`FooFlow(channel: c, agent: fooAgent)` when the flow has `uiScopeAgent`), not bare type names.
- [ ] No duplicate identical import lines in omega_setup or module files.
- [ ] omega_setup: no duplicate entries in `agents:`; no duplicate `OmegaRoute` with the same `id:`; no duplicate same `*Flow(...)` line in `flows:`.
- [ ] If using decoupled agent: EITHER route wraps `OmegaAgentScope(agent: ..., child: Page())` OR Flow overrides `uiScopeAgent` + same agent instance in `createOmegaConfig` (agents + flows); page uses `OmegaScopedAgentBuilder` / `OmegaFlowExpressionBuilder` where appropriate.
- [ ] If the flow ctor has extra non-agent params (offlineQueue, repo): they are created once in createOmegaConfig and passed named into the flow; not confused with the module agent.
- [ ] **Full-app wiring:** `routes:` registers **both** a **login** screen and a **home** shell; `initialFlowId` activates the **login/auth** flow; `initialNavigationIntent` opens the **login** route on cold start (not Home). Successful login emits `navigation.intent` with inner intent to the **home** route. **Home** is where global navigation to the rest of the app lives (drawer / bottom nav / rail / tabs).
''';

  /// **User prompt:** default app shell — every real product starts at Login and lands on Home with global navigation.
  static const String _omegaAiLoginHomeShell = r'''
APP SHELL — LOGIN + HOME (mandatory whenever you create or extend a whole app: `lib/omega/omega_setup.dart`, `lib/main.dart`, `lib/omega/app_semantics.dart`, kickstart with several modules, or JSON that invents routes):

- Every app has **two first-class screens**: (1) **Login** — sign-in / cold-start gate; (2) **Home** — post-auth **shell** where **global navigation** lives (Drawer, BottomNavigationBar, NavigationRail, or tabs linking to other modules). Do not leave the user on a feature page with no way to reach other areas after auth.
- **`OmegaConfig` is incomplete without cold start:** When the app includes **Auth/Login + Home**, the `return OmegaConfig(` **MUST** include **`initialFlowId:`** (same string as the **Auth** flow’s `super(id: ...)`, e.g. `AppFlowId.authFlow.id` or `'authFlow'`) **and** **`initialNavigationIntent: OmegaIntent.fromName(AppIntent.navigateLogin)`**. Omitting either leaves the app opening on the wrong screen or with no first navigation — **FORBIDDEN** for standard products. Import `app_semantics.dart` for `AppIntent` / `AppEvent`; import `app_runtime_ids.dart` when using `AppFlowId`.
- **Route ids vs navigator (critical):** [OmegaNavigator] resolves `navigate.{destination}` by stripping the **first** `navigate.` prefix and looking up **`OmegaRoute(id: destination)`** (destination may contain dots). So for `AppIntent.navigateLogin` (wire `navigate.login`) the login route id **must be exactly** `login` — **WRONG:** `OmegaRoute(id: 'Auth', ...)` for the login page. For `AppIntent.navigateHome` use **`id: 'home'`**. For any other `AppIntent.navigateFoo…`, **`OmegaRoute.id` must match `AppIntent.navigateFoo….name` with the leading `navigate.` removed** — e.g. `navigateDeliveryDetail` → **`delivery.detail`**. **AppIntent spelling:** `OmegaIntent.fromName(AppIntent.x)` requires **`x` to exist on the enum** — WRONG: `navigateOrderDetails` vs declared `navigateOrderDetail` (analyzer: no constant named …).
- **Cold start order:** `initialFlowId` = auth flow; `initialNavigationIntent` = `navigateLogin` so the **first visible route is Login**, not Home — mirror `example/lib/omega/omega_setup.dart` + `OmegaInitialRoute` in `example/lib/main.dart`.
- **`lib/main.dart` must forward `runtime` only:** [OmegaScope] uses **`initialFlowId: runtime.initialFlowId`** and **`initialNavigationIntent: runtime.initialNavigationIntent`** — **never** duplicate cold-start values as string literals in `main.dart` (they drift from `OmegaConfig`); **never** omit either field when `home:` is `OmegaInitialRoute`.
- **After successful login:** the **Auth flow or Auth agent** MUST emit `OmegaEvent.fromName(AppEvent.navigationIntent, payload: OmegaIntent.fromName(AppIntent.navigateHome))` when credentials validate (demo: accept non-empty fields). Do not require a manual second tap to reach Home.
- **Home page UX:** When the app has multiple modules (Tracking, Orders, …), the **Home** screen must offer **clear, attractive navigation** to each: e.g. `ListTile` / `Card` with **leading icons**, short titles, subtitles, `FilledButton.tonal` or `NavigationRail` for a polished shell — not a bare `Text('Home')`. Each destination should `channel.emit(OmegaEvent.fromName(AppEvent.navigationIntent, payload: OmegaIntent.fromName(AppIntent.navigateXxx)))` using the correct **`AppIntent`** case whose wire matches the target route id.
- **Duplicates:** Never list the same agent variable twice in `agents:` or duplicate `OmegaRoute(id: ...)` — `omega validate` fails; re-read the list before emitting JSON.
- If this pass outputs **only** one feature module (no `omega_setup` in JSON): still mention in **reasoning** that the host must set **`initialFlowId` + `initialNavigationIntent`**, use route ids **`login`** / **`home`**, and wire **Login → Home** on success.
''';

  /// **Heal user prompt only:** compact Omega API subset when full checklist is omitted (token budget).
  static const String _omegaAiHealPromptCompactOmega = r'''
HEAL — OMEGA API (fix analyzer errors; mirror PACKAGE GROUND TRUTH examples):
- createOmegaConfig: `agents:` / `flows:` use constructor calls only (never bare `MyFlow` without `(...)`). One agent instance per module; reuse the same variable in `MyFlow(channel: c, agent: thatAgent)` when the flow exposes `uiScopeAgent`. No duplicate identical import lines. **routes:** each `OmegaRoute` `id:` **globally unique** in `routes:` — never two blocks with `id: 'UserManagement'` or two `id: 'OrderManagement'`. **agents:** list each variable **once** — WRONG: `agents: [ userAgent, orderAgent, orderAgent ]`; **flows:** one ctor line per flow type — WRONG: two `UserManagementFlow(...)`. Run **`omega validate`** from app root; it fails on duplicate route ids, duplicate agent list entries, and duplicate flow types inside the lists.
- Typed ids: if `lib/omega/app_runtime_ids.dart` exists, `super(id: AppFlowId.X.id)` / `AppAgentId.X.id` must match an enum member; import `package:<THIS_APP>/omega/app_runtime_ids.dart` with THIS_APP from the APP PUBSPEC block.
- OmegaScope: `.channel`, `.flowManager`, `.initialFlowId`, `.initialNavigationIntent` — no agentManager. Use `getFlow` + `StreamBuilder`, or pass `agent` into the Page, or `OmegaAgentScope` / `Flow.uiScopeAgent` + shared agent in setup. **`lib/main.dart`:** mirror `_omegaAiMainDartEntry` / example `main.dart` — **`initialFlowId` + `initialNavigationIntent` from `runtime.` only** (no `'Auth'` / `'authFlow'` literals on `OmegaScope`); `MaterialApp.home` uses `OmegaInitialRoute` + `RootHandler`.
- `OmegaFlowActivator`: only `flowId` + `child` + optional `useSwitchTo` — no `onActivate` / callbacks. `OmegaFlowManager`: no `getAgent` — remove invented manager→agent bridges. `OmegaScope`: no `agentManager` / `getAgent` — use `widget.agent`, `OmegaAgentScope`, or `uiScopeAgent` + `OmegaScopedAgentBuilder`.
- Navigation: `OmegaIntent.fromName` takes an **AppIntent** / **ModuleIntent enum constant**, never a string like `'navigate.home'`; outer `AppEvent.navigationIntent` (see `_omegaAiNavigationChannelEmit`).
- handleIntent reaches running flows’ onIntent; agents and behavior react to **channel** events — emit `OmegaEvent.fromName(...)` / `emitTyped` for patterns that use `ctx.event` (lists, navigation). `OmegaIntent.fromName(MyEnum.member)` — enum constant, not String, not `.name`.
- Do not call `OmegaEventName(...)` / `OmegaIntentName(...)` — abstract; use `fromName` with concrete enums.
- **Intent/event DTO payloads** (classes passed as `payload:` to `OmegaIntent.fromName` / `OmegaEvent.fromName`, read with `payloadAs<YourType>()`): **plain Dart classes** with `final` fields — **FORBIDDEN:** `implements OmegaIntentPayload`, `implements OmegaEventPayload`, or `extends Equatable` on those unless `package:equatable` is a real dependency and you keep the class **without** fake omega interfaces (prefer no Equatable in `*_events.dart`).
- Behavior `OmegaAgentReaction('actionId', ...)` strings must match `onAction` `switch` cases — **string literals** only, not `case SomeEnum.foo.name`.
- OmegaStatefulAgent: `setViewState(viewState.copyWith(...))`; expose `stateStream` / `viewStateStream` (fix wrong stream names); never `extends OmegaViewState`; add missing types in `*_events.dart` and emit via channel.
- OmegaAgentBuilder / OmegaScopedAgentBuilder: builder is **only** `(BuildContext, TState)` — never add `agent`, `child`, or extra parameters (see `_omegaAiAgentUiStateListening` in module prompts).
- OmegaWorkflowFlow: `failStep(code, message: text)` — `message` is **named**, not a second positional.
- OmegaWorkflowFlow: **`defineStep(id, () { ... })` only** — step handler **no parameters** (never `(OmegaFlowContext ctx)`). Avoid `emitExpression` + `next` duplicating the same UI type in `onEvent` and in the step body.
- Flow: `onIntent` / `onEvent` only inside the flow class. `OmegaFlowContext`: `event`, `intent`, `memory` only — no `getAgentViewState` / agent reads from flow.
- Bus: listeners see `OmegaEvent` only; typed payloads — `event.payloadAs<T>()`, never `if (event is MyTypedEvent)`.
- JSON values: avoid invalid `\\` + `$` sequences inside JSON strings (breaks decode); CLI may sanitize common cases — still prefer valid JSON.
- Full app: **initialFlowId** + **initialNavigationIntent** (navigateLogin) required on `OmegaConfig`; route ids **`login`** / **`home`** (not `Auth` for login — breaks `navigate.login` lookup). **Home** = shell with main nav; login success → **navigateHome**. No duplicate agents or route ids.
- **AppIntent:** use only enum members that exist in `app_semantics.dart` (exact spelling). Each `AppIntent.navigateXxx` needs `OmegaRoute(id: …)` where id = substring after `navigate.` from the wire (e.g. `navigateDeliveryDetail` → **`delivery.detail`**). WRONG: `navigateOrderDetails` if undeclared; WRONG: route id `DeliveryDetail` when wire expects `delivery.detail`.
''';

  /// **User prompt:** UTF-8 / encoding hints for string literals inside generated Dart (JSON-safe copy).
  static const String _omegaAiUtf8StringLiterals = r'''
STRING LITERALS (encoding):
- Dart source must be valid UTF-8. For Spanish (or other languages), use real accented characters (á é í ó ú ñ ü) OR plain ASCII without accents — never garbage bytes or control characters inside words (e.g. "Básica" or "Basica", not corrupted sequences).
- If mock catalog copy might corrupt in JSON, prefer short English placeholders for names/descriptions.
''';

  /// **User prompt fragment:** `*_events.dart` allowlist — ViewState is plain Dart; app enums live in `app_semantics.dart`.
  static String _omegaAiEventsFileAllowlist(String moduleName, String lower) {
    return """

OMEGA — FILE ${lower}_events.dart ALLOWLIST (what exists in package:omega_architecture vs what you invent):
- ALLOWED in this file ONLY: (1) **`enum ${moduleName}Intent with OmegaIntentNameDottedCamel implements OmegaIntentName { … }`** — members are **identifiers only** (e.g. `${lower}Start`, `navigateRegister`); **no** `const Case('literal')` and **no** `@override final String name` on these module enums. (2) **`enum ${moduleName}Event with OmegaEventNameDottedCamel implements OmegaEventName { … }`** — same rule; include `navigationIntent` when this file emits navigation envelopes. (3) optional classes implementing OmegaTypedEvent **only** for channel.emitTyped (bus) — with `@override String get name => ${moduleName}Event.<matchingCase>.name`, (4) optional plain Dart class ${moduleName}ViewState (final fields + copyWith + factory idle) and plain data classes for **intent** payloads (OmegaIntent.fromName payload:) and list rows — those classes do **not** implement OmegaTypedEvent; call sites must use the same named args as the fields (e.g. `userName:` not `name:` when the field is `userName`).
- FORBIDDEN — **Auth-style manual wire enums** in this file: `enum X implements OmegaIntentName { loginRequested('login.requested'); const X(this.name); final String name; }` — wrong for Omega **modules**; use **`with OmegaIntentNameDottedCamel`** and a single camelCase member **`loginRequested`** (wire becomes **`login.requested`** automatically). Same for events: use **`OmegaEventNameDottedCamel`**, not per-case string constructors.
- FORBIDDEN — type does NOT exist in omega_architecture: extends OmegaViewState, class OmegaViewState, mixin EquatableMixin on ${moduleName}ViewState, or any “base ViewState” from this package. OmegaStatefulAgent<T> uses YOUR plain class T — copy the template’s plain ${moduleName}ViewState only.
- FORBIDDEN — redundant app enums: do NOT declare enum AppIntent / enum AppEvent again here. Cross-module navigation uses ONE shared **`lib/omega/app_semantics.dart`** — there **`AppEvent` / `AppIntent` MUST use `with OmegaEventNameDottedCamel` / `with OmegaIntentNameDottedCamel`** and **identifier-only** members (`navigationIntent`, `navigateLogin`, …), same as **example/lib/omega/app_semantics.dart** — **not** `enum AppIntent implements OmegaIntentName { navigateLogin('navigate.login'); const …(this.name); final String name; }`. Import app_semantics and use `AppIntent.navigateHome`, `AppEvent.navigationIntent`, etc. — see example/lib/auth/auth_events.dart.
- FORBIDDEN — “fix analyzer” imports in *_events.dart*: package:equatable/equatable.dart, or foundation.dart @immutable on ViewState only to silence errors. If the template ViewState is enough, do not add Equatable.
- FORBIDDEN — **invented payload marker types:** `implements OmegaIntentPayload`, `implements OmegaEventPayload`, or `implements OmegaIntentPayload, OmegaEventPayload` — **those interfaces do not exist** in package:omega_architecture (only **extension** names like `OmegaIntentPayloadExtension` exist on [OmegaIntent] / [OmegaEvent], not types for your DTO). **RIGHT:** plain `class LoginPayload { final String email; … const LoginPayload({required this.email, …}); }` — no `implements` from omega_architecture except **OmegaTypedEvent** for bus-only typed events.
- FORBIDDEN — wrong interfaces on enums: implements OmegaIntent or implements OmegaEvent. ONLY OmegaIntentName / OmegaEventName.
- Action ids in behavior are Strings: OmegaAgentReaction('loadFeed', …) and matching onAction must use the same string in switch: case 'loadFeed': (or case "loadFeed":). A separate enum ActionId is optional; NEVER write case ActionId.loadFeed.name — invalid const case. Use literals as in example/lib/auth/auth_agent.dart.

""";
  }

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
      "  doctor   Check Omi / assistant env (enabled/provider/model/base-url/key).",
    );
    stdout.writeln(
      "  env      Print supported assistant env variable names and examples.",
    );
    stdout.writeln(
      "  explain  Explain a trace file using offline heuristics (no API cost).",
    );
    stdout.writeln("           Add --json for machine-readable output.");
    stdout.writeln(
      "           Add --provider-api so Omi uses your configured OpenAI/Gemini API.",
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
    final providerLc = provider.toLowerCase();
    final model = (env["OMEGA_AI_MODEL"] ?? "not-set").trim();
    final baseUrl = (env["OMEGA_AI_BASE_URL"] ?? "default-provider-url").trim();

    final remote = _OmegaAiRemote.isRemoteProvider(providerLc);
    final hasRemoteKey = _OmegaAiRemote.effectiveApiKey().isNotEmpty;
    final geminiKeySet = (env["OMEGA_AI_GEMINI_API_KEY"] ?? "")
        .trim()
        .isNotEmpty;

    stdout.writeln("Omi doctor (Omega assistant)");
    stdout.writeln("  Enabled : $enabled");
    stdout.writeln("  Provider: $provider");
    stdout.writeln("  Model   : $model");
    if (providerLc == "gemini") {
      stdout.writeln(
        "  Base URL: Google Generative Language API (OMEGA_AI_BASE_URL ignored)",
      );
    } else {
      stdout.writeln("  Base URL: $baseUrl");
    }
    if (remote) {
      var keyLine = "  API key : ${hasRemoteKey ? "configured" : "missing"}";
      if (hasRemoteKey && providerLc == "gemini") {
        keyLine += geminiKeySet
            ? " (OMEGA_AI_GEMINI_API_KEY)"
            : " (OMEGA_AI_API_KEY)";
      }
      stdout.writeln(keyLine);
    } else {
      stdout.writeln(
        "  API key : n/a for this provider (remote assistant uses openai|gemini)",
      );
    }
    stdout.writeln("");

    if (!enabled) {
      stdout.writeln("Omi is asleep (assistant disabled, default-safe mode).");
      stdout.writeln("Set OMEGA_AI_ENABLED=true to enable coach / heal / explain with Omi.");
      return;
    }

    if (providerLc == "none") {
      _err("OMEGA_AI_PROVIDER is not set.");
      stdout.writeln("  Suggested for Omi (remote): openai | gemini");
      return;
    }

    if (providerLc != "none" &&
        providerLc != "ollama" &&
        !_OmegaAiRemote.isRemoteProvider(providerLc)) {
      stdout.writeln(
        "Note: Omi (coach / explain / heal / …) uses OpenAI or Gemini only for remote calls.",
      );
    }

    if (remote && !hasRemoteKey) {
      if (providerLc == "gemini") {
        _err("Gemini requires OMEGA_AI_GEMINI_API_KEY or OMEGA_AI_API_KEY.");
      } else {
        _err("OpenAI requires OMEGA_AI_API_KEY.");
      }
      stdout.writeln("  Set your key and run: omega ai doctor");
      return;
    }

    stdout.writeln("Omi is ready — base configuration looks good.");
    stdout.writeln(
      "Remote Omi calls (coach, audit, explain, heal, create-app fix, …) use the same prompts for OpenAI and Gemini.",
    );
  }

  static void _env() {
    stdout.writeln("Omi / Omega assistant — environment variables");
    stdout.writeln("");
    stdout.writeln("  OMEGA_AI_ENABLED   true|false (default: false)");
    stdout.writeln(
      "  OMEGA_AI_PROVIDER  openai | gemini (remote) | anthropic | ollama | none",
    );
    stdout.writeln(
      "  OMEGA_AI_API_KEY   OpenAI key; also Gemini fallback if OMEGA_AI_GEMINI_API_KEY unset",
    );
    stdout.writeln(
      "  OMEGA_AI_GEMINI_API_KEY   Google AI Studio key (optional; preferred when PROVIDER=gemini)",
    );
    stdout.writeln(
      "  OMEGA_AI_GEMINI_API_VERSION   v1beta | v1 (default: v1beta)",
    );
    stdout.writeln("  OMEGA_AI_MODEL     model id (provider specific)");
    stdout.writeln(
      "  OMEGA_AI_BASE_URL  custom OpenAI-compatible endpoint (OpenAI only)",
    );
    stdout.writeln("");
    stdout.writeln("Package context for coach / heal (optional):");
    stdout.writeln(
      "  OMEGA_PACKAGE_ROOT          path to omega_architecture repo (if auto-detect fails)",
    );
    stdout.writeln(
      "  OMEGA_AI_DOCS_URL           one http(s) URL — fetched via GET and appended to Omi's prompt",
    );
    stdout.writeln(
      "  OMEGA_AI_DOCS_URLS          comma-separated URLs (max 5), same as above",
    );
    stdout.writeln(
      "  OMEGA_AI_SKIP_PACKAGE_CONTEXT   true = do not read package example/*.dart",
    );
    stdout.writeln(
      "  OMEGA_AI_SKIP_REMOTE_DOCS       true = do not GET OMEGA_AI_DOCS_URL(S)",
    );
    stdout.writeln(
      "  OMEGA_AI_STRICT_POSTCHECK       true = if full-module output fails checks, skip writing Omi files and use default template",
    );
    stdout.writeln("");
    stdout.writeln("Self-heal (dart analyze + Omi) tuning:");
    stdout.writeln(
      "  OMEGA_AI_HEAL_MAX_PASSES        max AI fix rounds (default: 3)",
    );
    stdout.writeln(
      "  OMEGA_AI_HEAL_MAX_FILES         max lib/ files sent per heal call (default: 28, clamped 4–60); sorted by error count",
    );
    stdout.writeln(
      "  OMEGA_AI_HEAL_MAX_CONTEXT_CHARS cap on pasted file bytes in heal prompt (default: 90000)",
    );
    stdout.writeln(
      "  OMEGA_AI_HEAL_TIMEOUT_SEC       remote heal request timeout (default: 120, clamped 45–300)",
    );
    stdout.writeln(
      "  OMEGA_AI_HEAL_PUB_ADD           false = skip dart pub add for missing packages",
    );
    stdout.writeln("");
    stdout.writeln("PowerShell example (OpenAI):");
    stdout.writeln('  setx OMEGA_AI_ENABLED "true"');
    stdout.writeln('  setx OMEGA_AI_PROVIDER "openai"');
    stdout.writeln('  setx OMEGA_AI_API_KEY "sk-..."');
    stdout.writeln('  setx OMEGA_AI_MODEL "gpt-4o-mini"');
    stdout.writeln("");
    stdout.writeln("PowerShell example (Gemini):");
    stdout.writeln('  setx OMEGA_AI_ENABLED "true"');
    stdout.writeln('  setx OMEGA_AI_PROVIDER "gemini"');
    stdout.writeln('  setx OMEGA_AI_GEMINI_API_KEY "AIza..."');
    stdout.writeln('  setx OMEGA_AI_MODEL "gemini-2.5-flash"');
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
          en: "Omi is asking the assistant",
          es: "Omi consulta al asistente",
          pt: "Omi consulta o assistente",
          fr: "Omi consulte l'assistant",
          it: "Omi consulta l'assistente",
          de: "Omi fragt den Assistenten",
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
        "  module  ${_tr(en: "Create a complete ecosystem module (with Omi).", es: "Crea un modulo de ecosistema completo (con Omi).", pt: "Cria um modulo de ecossistema completo (com Omi).", fr: "Cree un module d'ecosysteme complet (avec Omi).", it: "Crea un modulo ecosistema completo (con Omi).", de: "Erstellt ein vollstaendiges Oekosystem-Modul (mit Omi).")}",
      );
      stdout.writeln(
        "  redesign ${_tr(en: "Redesign the module UI only (updates ui/*_page.dart; does not change agent/flow/behavior/events).", es: "Rediseña solo la vista del módulo (actualiza ui/*_page.dart; no cambia agent/flow/behavior/events).")}",
      );
      stdout.writeln(
        "          ${_tr(en: "Use --template advanced for workflow/stateful/contracts/tests scaffold.", es: "Usa --template advanced para scaffold con workflow/stateful/contratos/tests.")}",
      );
      return;
    }

    final action = args[0].toLowerCase();
    if (action != "start" &&
        action != "audit" &&
        action != "module" &&
        action != "redesign") {
      _err("Unknown coach action: $action");
      stdout.writeln(
        "  Use: omega ai coach <start|audit|module|redesign> \"<feature>\" [--json] [--provider-api] [--stdout]",
      );
      return;
    }

    final rest = args.sublist(1);
    final asJson = rest.contains("--json");
    final useProviderApi = rest.contains("--provider-api");
    final toTempFile = !rest.contains("--stdout");
    final template =
        (_optionValue(rest, "--template") ??
                "advanced") // Default to advanced for redesign/coach
            .trim()
            .toLowerCase();
    if (template != "basic" && template != "advanced") {
      _err("Invalid template: $template");
      stdout.writeln("  Allowed: basic, advanced");
      return;
    }
    final feature = _collectPositionalArgs(
      rest,
      optionsWithValue: const ["--template", "--module", "-m"],
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
      stdout.writeln('  omega ai coach redesign "Auth: add search bar"');
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

    if (action == "module" || action == "redesign") {
      final moduleNameFlag =
          _optionValue(rest, "--module") ?? _optionValue(rest, "-m");
      await _coachModule(
        feature: feature,
        updateModule: moduleNameFlag,
        productContext: null,
        template: template,
        asJson: asJson,
        useProviderApi: useProviderApi,
        toTempFile: toTempFile,
        uiOnly: action == "redesign",
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
          en: "Omi is asking the assistant",
          es: "Omi consulta al asistente",
          pt: "Omi consulta o assistente",
          fr: "Omi consulte l'assistant",
          it: "Omi consulta l'assistente",
          de: "Omi fragt den Assistenten",
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

  /// Rejects common AI mistakes: wrong *Name types, missing const enums, wrong imports.
  static bool _omegaAiEventsPassSanity(String code, String moduleName) {
    final t = code.trim();
    if (t.isEmpty) return false;
    if (!t.contains("package:omega_architecture/omega_architecture.dart")) {
      return false;
    }
    if (!t.contains("implements OmegaIntentName")) return false;
    if (!t.contains("implements OmegaEventName")) return false;
    if (RegExp(r"implements\s+OmegaIntent\b").hasMatch(t)) return false;
    if (RegExp(r"implements\s+OmegaEvent\b").hasMatch(t)) return false;
    if (!t.contains("${moduleName}Intent")) return false;
    if (!t.contains("${moduleName}Event")) return false;
    if (!t.contains("final String name")) return false;
    if (!t.contains("const ${moduleName}Intent(")) return false;
    if (!t.contains("const ${moduleName}Event(")) return false;
    if (RegExp(r"extends\s+OmegaViewState\b").hasMatch(t)) return false;
    if (t.contains("package:equatable/equatable.dart")) return false;
    return true;
  }

  /// [OmegaIntent.fromName] requires an [OmegaIntentName] value, never a String or `.name`.
  static bool _omegaAiPagePassSanity(String code, String moduleName) {
    final t = code.trim();
    if (t.isEmpty) return false;
    if (!t.contains("package:omega_architecture/omega_architecture.dart")) {
      return false;
    }
    if (!_omegaAiAbstractNameConstructorPassSanity(t)) return false;
    if (!_omegaAiEmitFirstArgStringPassSanity(t)) return false;
    if (t.contains("OmegaIntent.fromName")) {
      if (t.contains("OmegaIntent.fromName('") ||
          t.contains('OmegaIntent.fromName("')) {
        return false;
      }
      if (RegExp(r"OmegaIntent\.fromName\s*\([^)]*\.name\s*\)").hasMatch(t)) {
        return false;
      }
      // Module intents OR shared AppIntent (navigation / app-wide buttons).
      final hasModuleIntent = t.contains("${moduleName}Intent.");
      final hasAppIntent = t.contains("AppIntent.");
      if (!hasModuleIntent && !hasAppIntent) return false;
    }
    if (t.contains("agentManager")) return false;
    if (RegExp(r"\bscope\.getAgent\b").hasMatch(t)) return false;
    if (RegExp(r"\bflow\s*\.\s*onIntent\b").hasMatch(t)) return false;
    if (t.contains("OmegaFlowContext.intent")) return false;
    if (t.contains("OmegaAgentBuilder<") &&
        RegExp(
          r"builder:\s*\(\s*context\s*,\s*[^,)]+,\s*[^)]+\)",
        ).hasMatch(t)) {
      return false;
    }
    if (t.contains("OmegaAgentBuilder")) {
      if (RegExp(r"agent:\s*\w+Agent\s*\(\s*scope\.channel").hasMatch(t)) {
        return false;
      }
      if (RegExp(r"agent:\s*\w+Agent\s*\(\s*channel\s*\)").hasMatch(t)) {
        return false;
      }
      if (RegExp(
        r"agent:\s*\w+Agent\s*\(\s*channel\s*:\s*channel\s*\)",
      ).hasMatch(t)) {
        return false;
      }
    }
    if (RegExp(r"\b" + RegExp.escape(moduleName) + r"Agent\b").hasMatch(t)) {
      final lower = moduleName.toLowerCase();
      if (!t.contains("${lower}_agent.dart")) return false;
    }
    return true;
  }

  /// Rejects BLoC-style behavior files (handleEvent, OmegaAgentMessage, msg.type).
  static bool _omegaAiBehaviorPassSanity(String code) {
    final t = code.trim();
    if (t.isEmpty) return true;
    if (!t.contains("extends OmegaAgentBehaviorEngine")) return true;
    if (t.contains("handleEvent")) return false;
    if (RegExp(r"\basync\s*\*").hasMatch(t)) return false;
    if (RegExp(r"\byield\b").hasMatch(t)) return false;
    if (t.contains("msg.type")) return false;
    if (t.contains("OmegaAgentMessage")) return false;
    if (RegExp(r"addRule\s*\(\s*condition\s*:").hasMatch(t)) return false;
    return true;
  }

  /// Rejects state.copyWith on OmegaStatefulAgent (state is Map, not TState).
  static bool _omegaAiAgentPassSanity(String code) {
    final t = code.trim();
    if (t.isEmpty) return true;
    if (!t.contains("extends OmegaStatefulAgent")) return true;
    if (RegExp(r"\bstate\.copyWith\b").hasMatch(t)) return false;
    if (RegExp(r"orElse\s*:\s*\(\)\s*=>\s*null\s+as\b").hasMatch(t)) {
      return false;
    }
    // switch(action) case Enum.value.name is not a compile-time constant (const_eval_extension_method).
    if (RegExp(r"case\s+[A-Za-z_]\w*\.[A-Za-z_]\w*\.name\s*:").hasMatch(t)) {
      return false;
    }
    if (!_omegaAiEmitFirstArgStringPassSanity(t)) return false;
    return true;
  }

  /// failStep has one positional arg; second value must be message: ...
  static bool _omegaAiFlowPassSanity(String code) {
    final t = code.trim();
    if (t.isEmpty) return true;
    if (t.contains("getAgentViewState")) return false;
    if (RegExp(r"\bctx\.getAgent\b").hasMatch(t)) return false;
    if (!t.contains("failStep(")) return true;
    if (RegExp(r"failStep\s*\(\s*[^,)]+\s*,\s*(?!message\s*:)").hasMatch(t)) {
      return false;
    }
    return true;
  }

  /// [OmegaEventName] / [OmegaIntentName] are abstract — models sometimes emit invalid `OmegaEventName('x')`.
  static bool _omegaAiAbstractNameConstructorPassSanity(String code) {
    if (RegExp(r"\bOmegaEventName\s*\(").hasMatch(code)) return false;
    if (RegExp(r"\bOmegaIntentName\s*\(").hasMatch(code)) return false;
    return true;
  }

  /// [OmegaAgent.emit] is emit(String name, ...) — not emit(MyModuleEvent.case) without .name.
  static bool _omegaAiEmitFirstArgStringPassSanity(String code) {
    final badDotEmit = RegExp(
      r"\.emit\s*\(\s*(?!OmegaEvent\b)\w+Event\.\w+(?!\.name)\s*[\),]",
    );
    final badBareEmit = RegExp(
      r"(?<![.\w])emit\s*\(\s*(?!OmegaEvent\b)\w+Event\.\w+(?!\.name)\s*[\),]",
    );
    if (badDotEmit.hasMatch(code) || badBareEmit.hasMatch(code)) return false;
    return true;
  }

  /// Rejects replacement chars and C0 control characters (common mojibake artifacts).
  static bool _omegaAiSourceEncodingPassSanity(String code) {
    if (code.contains("\uFFFD")) return false;
    for (final r in code.runes) {
      if (r < 0x20 && r != 0x09 && r != 0x0A && r != 0x0D) return false;
    }
    return true;
  }

  /// Post-generation coherence: behavior actionIds ↔ agent branches, flow id ↔ page, forbidden APIs.
  static Set<String> _omegaPostGenBehaviorActionIds(String behavior) {
    final s = <String>{};
    for (final m in RegExp(
      r"OmegaAgentReaction\s*\(\s*'([^']*)'",
    ).allMatches(behavior)) {
      final id = m.group(1)!.trim();
      if (id.isNotEmpty) s.add(id);
    }
    for (final m in RegExp(
      r'OmegaAgentReaction\s*\(\s*"([^"]*)"',
    ).allMatches(behavior)) {
      final id = m.group(1)!.trim();
      if (id.isNotEmpty) s.add(id);
    }
    return s;
  }

  static Set<String> _omegaPostGenAgentHandledActions(String agent) {
    final s = <String>{};
    for (final m in RegExp(r"case\s+'([^']*)'\s*:").allMatches(agent)) {
      final id = m.group(1)!.trim();
      if (id.isNotEmpty) s.add(id);
    }
    for (final m in RegExp(r'case\s+"([^"]*)"\s*:').allMatches(agent)) {
      final id = m.group(1)!.trim();
      if (id.isNotEmpty) s.add(id);
    }
    for (final m in RegExp(r"\baction\s*==\s*'([^']*)'").allMatches(agent)) {
      final id = m.group(1)!.trim();
      if (id.isNotEmpty) s.add(id);
    }
    for (final m in RegExp(r'\baction\s*==\s*"([^"]*)"').allMatches(agent)) {
      final id = m.group(1)!.trim();
      if (id.isNotEmpty) s.add(id);
    }
    return s;
  }

  static String? _omegaPostGenFirstSuperId(String dart) {
    final m1 = RegExp(r"super\s*\(\s*id:\s*'([^']*)'").firstMatch(dart);
    if (m1 != null) return m1.group(1)!.trim();
    final m2 = RegExp(r'super\s*\(\s*id:\s*"([^"]*)"').firstMatch(dart);
    return m2?.group(1)?.trim();
  }

  static void _omegaPostGenAddDualQuotedArg(
    String text,
    String callPrefix,
    Set<String> into,
  ) {
    final re1 = RegExp(RegExp.escape(callPrefix) + r"\s*\(\s*'([^']*)'");
    final re2 = RegExp(RegExp.escape(callPrefix) + r'\s*\(\s*"([^"]*)"');
    for (final m in re1.allMatches(text)) {
      final id = m.group(1)!.trim();
      if (id.isNotEmpty) into.add(id);
    }
    for (final m in re2.allMatches(text)) {
      final id = m.group(1)!.trim();
      if (id.isNotEmpty) into.add(id);
    }
  }

  static Set<String> _omegaPostGenPageFlowIds(String page) {
    final s = <String>{};
    _omegaPostGenAddDualQuotedArg(page, "getFlow", s);
    _omegaPostGenAddDualQuotedArg(page, "activate", s);
    _omegaPostGenAddDualQuotedArg(page, "switchTo", s);
    return s;
  }

  static _OmegaPostGenResult _omegaPostValidateAiModule(
    Map<String, String> files,
    String moduleName,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final buf = StringBuffer();
    for (final k in ["events", "behavior", "agent", "flow", "page"]) {
      final v = files[k];
      if (v != null && v.trim().isNotEmpty) {
        buf.writeln(v);
      }
    }
    final merged = buf.toString();

    final tag = "[$moduleName]";
    if (RegExp(r"extends\s+OmegaViewState\b").hasMatch(merged)) {
      errors.add(
        "$tag extends OmegaViewState — type does not exist; use a plain ViewState class.",
      );
    }
    if (RegExp(
      r"case\s+[A-Za-z_]\w*\.[A-Za-z_]\w*\.name\s*:",
    ).hasMatch(merged)) {
      errors.add(
        "$tag switch uses case Enum.value.name — not a const expression; use case \"literal\" matching behavior actionIds.",
      );
    }
    if (RegExp(r"\bOmegaEventName\s*\(").hasMatch(merged)) {
      errors.add(
        "$tag OmegaEventName(...) cannot be constructed — use enum values.",
      );
    }
    if (RegExp(r"\bOmegaIntentName\s*\(").hasMatch(merged)) {
      errors.add(
        "$tag OmegaIntentName(...) cannot be constructed — use enum values.",
      );
    }

    final behavior = files["behavior"] ?? "";
    final agent = files["agent"] ?? "";
    if (behavior.trim().isNotEmpty && agent.trim().isNotEmpty) {
      final bids = _omegaPostGenBehaviorActionIds(behavior);
      final handled = _omegaPostGenAgentHandledActions(agent);
      if (bids.isNotEmpty && handled.isEmpty) {
        warnings.add(
          "$tag Agent onAction has no case \"...\" / action == \"...\" branches; could not verify behavior actionIds.",
        );
      }
      for (final id in bids) {
        if (!handled.contains(id)) {
          errors.add(
            "$tag Behavior emits OmegaAgentReaction('$id') but agent has no case '$id' (or action == '$id').",
          );
        }
      }
    }

    final flow = files["flow"] ?? "";
    final page = files["page"] ?? "";
    if (flow.trim().isNotEmpty && page.trim().isNotEmpty) {
      final flowId = _omegaPostGenFirstSuperId(flow);
      final pageIds = _omegaPostGenPageFlowIds(page);
      if (flowId != null && pageIds.isNotEmpty && !pageIds.contains(flowId)) {
        warnings.add(
          "$tag Flow uses super(id: '$flowId') but page getFlow/activate/switchTo use: ${pageIds.join(", ")} — possible Flow not registered at runtime.",
        );
      }
      if (flowId != null && pageIds.length > 1) {
        warnings.add(
          "$tag Page references multiple flow ids (${pageIds.join(", ")}); ensure only one matches super(id: '$flowId').",
        );
      }
    }

    final events = files["events"] ?? "";
    if (events.trim().isNotEmpty &&
        !events.contains("implements OmegaIntentName")) {
      warnings.add(
        "$tag events file may be missing enum implements OmegaIntentName.",
      );
    }
    if (events.trim().isNotEmpty &&
        !events.contains("implements OmegaEventName")) {
      warnings.add(
        "$tag events file may be missing enum implements OmegaEventName.",
      );
    }

    return _OmegaPostGenResult(errors: errors, warnings: warnings);
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
      Map<String, String> toWrite = Map<String, String>.from(customCode);
      final ev = toWrite["events"] ?? "";
      if (ev.trim().isNotEmpty && !_omegaAiEventsPassSanity(ev, moduleName)) {
        stdout.writeln(
          "⚠️ ${_tr(en: "Omi spotted possible issues in events — self-heal will try...", es: "Omi ve posibles problemas en eventos — se intentará auto-sanación...")}",
        );
      }
      final pg = toWrite["page"] ?? "";
      if (pg.trim().isNotEmpty && !_omegaAiPagePassSanity(pg, moduleName)) {
        stdout.writeln(
          "⚠️ ${_tr(en: "Omi spotted possible issues in the page — self-heal will try...", es: "Omi ve posibles problemas en la página — se intentará auto-sanación...")}",
        );
      }
      final bh = toWrite["behavior"] ?? "";
      if (bh.trim().isNotEmpty && !_omegaAiBehaviorPassSanity(bh)) {
        stdout.writeln(
          "⚠️ ${_tr(en: "Omi: behavior may not match OmegaAgentBehaviorEngine (addRule/evaluate). Self-heal will try...", es: "Omi: el behavior podría no coincidir con OmegaAgentBehaviorEngine (addRule/evaluate). Se intentará auto-sanación...")}",
        );
      }
      final ag = toWrite["agent"] ?? "";
      if (ag.trim().isNotEmpty && !_omegaAiAgentPassSanity(ag)) {
        stdout.writeln(
          "⚠️ ${_tr(en: "Omi: agent may use state.copyWith — prefer viewState.copyWith (OmegaStatefulAgent). Self-heal will try...", es: "Omi: el agente podría usar state.copyWith — con OmegaStatefulAgent usa viewState.copyWith. Se intentará auto-sanación...")}",
        );
      }
      final fl = toWrite["flow"] ?? "";
      if (fl.trim().isNotEmpty && !_omegaAiFlowPassSanity(fl)) {
        stdout.writeln(
          "⚠️ ${_tr(en: "Omi: flow may use failStep with a second positional arg — use failStep('code', message: ...). Self-heal will try...", es: "Omi: el flow podría usar failStep con un segundo argumento posicional — usa failStep('code', message: ...). Se intentará auto-sanación...")}",
        );
      }
      for (final key in ["events", "behavior", "agent", "flow", "page"]) {
        final chunk = toWrite[key];
        if (chunk != null &&
            chunk.trim().isNotEmpty &&
            !_omegaAiAbstractNameConstructorPassSanity(chunk)) {
          stdout.writeln(
            "⚠️ ${_tr(en: "Omi: file \"$key\" uses OmegaEventName(...) or OmegaIntentName(...) — use enum values (AppEvent.*, AppIntent.*). Self-heal will try...", es: "Omi: el archivo \"$key\" usa OmegaEventName(...) u OmegaIntentName(...) — usa valores de enum (ej. AppEvent.*, AppIntent.*). Se intentará auto-sanación...")}",
          );
          break;
        }
        if (chunk != null &&
            chunk.trim().isNotEmpty &&
            !_omegaAiSourceEncodingPassSanity(chunk)) {
          stdout.writeln(
            "⚠️ ${_tr(en: "Omi: file \"$key\" may contain invalid control characters or mojibake. Self-heal will try...", es: "Omi: el archivo \"$key\" puede tener caracteres de control o texto corrupto. Se intentará auto-sanación...")}",
          );
          break;
        }
      }

      final post = _omegaPostValidateAiModule(toWrite, moduleName);
      if (post.warnings.isNotEmpty || post.errors.isNotEmpty) {
        stdout.writeln(
          _tr(
            en: "--- Post-generation Omega check after Omi (${post.errors.length} error(s), ${post.warnings.length} warning(s)) ---",
            es: "--- Comprobación Omega tras Omi (${post.errors.length} error(es), ${post.warnings.length} aviso(s)) ---",
          ),
        );
      }
      for (final w in post.warnings) {
        stdout.writeln("⚠️ $w");
      }
      for (final e in post.errors) {
        _err(e);
      }

      final strictPost = _readBool(
        Platform.environment["OMEGA_AI_STRICT_POSTCHECK"],
        defaultValue: false,
      );
      final fullAiModule =
          toWrite.containsKey("behavior") &&
          toWrite.containsKey("agent") &&
          toWrite.containsKey("flow");

      if (strictPost && !post.isOk && fullAiModule) {
        stdout.writeln(
          _tr(
            en: "OMEGA_AI_STRICT_POSTCHECK: reverting to default advanced template (Omi full module output rejected).",
            es: "OMEGA_AI_STRICT_POSTCHECK: volviendo a la plantilla avanzada por defecto (se rechazó la salida completa de Omi).",
          ),
        );
        _writeDefaultAdvancedTemplate(
          moduleName: moduleName,
          lower: lower,
          eventsPath: eventsPath,
          behaviorPath: behaviorPath,
          agentPath: agentPath,
          flowPath: flowPath,
          pagePath: pagePath,
        );
      } else {
        if (strictPost && !post.isOk && !fullAiModule) {
          stdout.writeln(
            _tr(
              en: "Strict post-check failed but output is partial (e.g. page-only); writing Omi output anyway.",
              es: "Post-check estricto falló pero la salida es parcial (ej. solo página); se escribe la salida de Omi igualmente.",
            ),
          );
        }
        if (toWrite.containsKey("events")) {
          File(eventsPath).writeAsStringSync(
            _omegaDedupeDuplicateImportLines(toWrite["events"]!),
          );
        }
        if (toWrite.containsKey("behavior")) {
          File(behaviorPath).writeAsStringSync(
            _omegaDedupeDuplicateImportLines(toWrite["behavior"]!),
          );
        }
        if (toWrite.containsKey("agent")) {
          File(agentPath).writeAsStringSync(
            _omegaDedupeDuplicateImportLines(toWrite["agent"]!),
          );
        }
        if (toWrite.containsKey("flow")) {
          File(flowPath).writeAsStringSync(
            _omegaDedupeDuplicateImportLines(toWrite["flow"]!),
          );
        }
        if (toWrite.containsKey("page")) {
          File(pagePath).writeAsStringSync(
            _omegaDedupeDuplicateImportLines(toWrite["page"]!),
          );
        }
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
  test('$moduleName module scaffold compiles', () {
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

enum ${moduleName}Intent with OmegaIntentNameDottedCamel implements OmegaIntentName {
  ${lower}Start,
  ${lower}Retry,
}

enum ${moduleName}Event with OmegaEventNameDottedCamel implements OmegaEventName {
  navigationIntent,
  ${lower}Requested,
  ${lower}Succeeded,
  ${lower}Failed,
}

class ${moduleName}RequestedEvent implements OmegaTypedEvent {
  const ${moduleName}RequestedEvent({required this.input});
  final String input;

  @override
  String get name => ${moduleName}Event.${lower}Requested.name;
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
        condition: (ctx) => ctx.event?.name == ${moduleName}Event.${lower}Requested.name,
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
    // Shared OmegaChannel delivers every module's events to every agent; an empty
    // listenedEventNames set disables false debug warnings. Behavior still filters by name.
    listenedEventNames: {},
  );

  @override
  void onAction(String action, dynamic payload) {
    if (action == 'processRequest') {
      setViewState(viewState.copyWith(isLoading: true, error: null));
      setViewState(viewState.copyWith(isLoading: false));
      channel.emit(OmegaEvent.fromName(${moduleName}Event.${lower}Succeeded));
    }
  }

  @override
  void onMessage(OmegaAgentMessage msg) {}
}
''');

    File(flowPath).writeAsStringSync('''
import 'package:omega_architecture/omega_architecture.dart';
import '${lower}_agent.dart';
import '${lower}_events.dart';

class ${moduleName}Flow extends OmegaWorkflowFlow {
  ${moduleName}Flow({required super.channel, required this.agent})
      : super(id: '$moduleName') {
    defineStep('start', () => emitExpression('loading'));
    defineStep('done', () => completeWorkflow());
  }

  final ${moduleName}Agent agent;

  @override
  OmegaAgent? get uiScopeAgent => agent;

  @override
  OmegaFlowContract? get contract => OmegaFlowContract(
    acceptedIntentNames: {${moduleName}Intent.${lower}Start.name, ${moduleName}Intent.${lower}Retry.name},
    listenedEventNames: {
      ${moduleName}Event.${lower}Requested.name,
      ${moduleName}Event.${lower}Succeeded.name,
      ${moduleName}Event.${lower}Failed.name,
    },
    emittedExpressionTypes: {
      'idle',
      'loading',
      'success',
      'error',
      'workflow.done',
      'workflow.step',
      'workflow.error',
    },
  );

  @override
  void onStart() {
    emitExpression('idle');
  }

  @override
  void onIntent(OmegaFlowContext ctx) {
    final intentName = ctx.intent?.name;
    if (intentName == ${moduleName}Intent.${lower}Start.name) {
      channel.emitTyped(const ${moduleName}RequestedEvent(input: 'initial'));
      startAt('start');
    }
    if (intentName == ${moduleName}Intent.${lower}Retry.name) {
      channel.emitTyped(const ${moduleName}RequestedEvent(input: 'retry'));
      next('start');
    }
  }

  @override
  void onEvent(OmegaFlowContext ctx) {
    final event = ctx.event;
    if (event?.name == ${moduleName}Event.${lower}Succeeded.name) {
      emitExpression('success');
      next('done');
    }
    if (event?.name == ${moduleName}Event.${lower}Failed.name) {
      emitExpression('error', payload: event?.payload);
      failStep('request.failed', message: event?.payload?.toString());
    }
  }
}
''');

    File(pagePath).writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:omega_architecture/omega_architecture.dart';
import '../${lower}_events.dart';

/// Activates the module flow and sends [start] once when the route is ready so
/// lists / agent work can run without an extra tap (see Omega CLI SCREEN ENTRY rules).
class ${moduleName}Page extends StatefulWidget {
  const ${moduleName}Page({super.key});

  @override
  State<${moduleName}Page> createState() => _${moduleName}PageState();
}

class _${moduleName}PageState extends State<${moduleName}Page> {
  bool _entryKickApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryKickApplied) return;
    _entryKickApplied = true;
    final scope = OmegaScope.of(context);
    scope.flowManager.handleIntent(
      OmegaIntent.fromName(${moduleName}Intent.${lower}Start),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = OmegaScope.of(context);
    final flow = scope.flowManager.getFlow('$moduleName');
    if (flow == null) {
      return OmegaFlowActivator(
        flowId: '$moduleName',
        child: const Scaffold(
          body: Center(child: Text('Flow not registered in omega_setup.dart')),
        ),
      );
    }
    return OmegaFlowActivator(
      flowId: '$moduleName',
      child: Scaffold(
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
                  OmegaIntent.fromName(${moduleName}Intent.${lower}Start),
                ),
                child: const Text('Start'),
              );
            },
          ),
        ),
      ),
    );
  }
}
''');
  }

  /// OpenAI `json_object` may include extra string keys (`reasoning`, `response`).
  /// Never use [Map.cast] or [Map.from] assuming all values are [String].
  static Map<String, String>? _normalizeAiModuleJson(Map<String, dynamic> raw) {
    String? pickString(String key) {
      final v = raw[key];
      if (v is String) return v;
      return null;
    }

    final reasoning = pickString("reasoning");
    if (reasoning != null && reasoning.trim().isNotEmpty) {
      stdout.writeln("");
      stdout.writeln(
        "🧠 ${_tr(en: "Omi's design notes", es: "Notas de diseño de Omi")}:",
      );
      stdout.writeln(reasoning.trim());
      stdout.writeln("");
    }

    final events = pickString("events");
    final behavior = pickString("behavior");
    final agent = pickString("agent");
    final flow = pickString("flow");
    var page = pickString("page");
    final response = pickString("response");
    if ((page == null || page.trim().isEmpty) &&
        response != null &&
        response.trim().isNotEmpty) {
      page = response;
    }

    if (events == null ||
        behavior == null ||
        agent == null ||
        flow == null ||
        page == null) {
      _err(
        _tr(
          en:
              "Omi's JSON response is missing required string keys (events, behavior, agent, flow, page). "
              "If the assistant put the screen only in \"response\", that key is used as \"page\" when \"page\" is empty.",
          es:
              "Faltan en la respuesta de Omi claves string obligatorias (events, behavior, agent, flow, page). "
              "Si el asistente dejó la pantalla solo en \"response\", se usa como \"page\" cuando \"page\" está vacío.",
        ),
      );
      return null;
    }

    return {
      "events": events,
      "behavior": behavior,
      "agent": agent,
      "flow": flow,
      "page": page,
    };
  }

  /// `omega ai coach redesign`: model returns only the screen file; disk keeps agent/flow/behavior/events.
  static Map<String, String>? _normalizeAiPageOnlyJson(
    Map<String, dynamic> raw,
  ) {
    String? pickString(String key) {
      final v = raw[key];
      if (v is String) return v;
      return null;
    }

    final reasoning = pickString("reasoning");
    if (reasoning != null && reasoning.trim().isNotEmpty) {
      stdout.writeln("");
      stdout.writeln(
        "🧠 ${_tr(en: "Omi's UI notes", es: "Notas de UI de Omi")}:",
      );
      stdout.writeln(reasoning.trim());
      stdout.writeln("");
    }

    var page = pickString("page");
    final response = pickString("response");
    if ((page == null || page.trim().isEmpty) &&
        response != null &&
        response.trim().isNotEmpty) {
      page = response;
    }

    if (page == null || page.trim().isEmpty) {
      _err(
        _tr(
          en: "Omi's JSON is missing the UI file: need non-empty \"page\" (or \"response\").",
          es: "Falta la pantalla en la respuesta de Omi: se requiere \"page\" o \"response\" con el Dart completo.",
        ),
      );
      return null;
    }

    // Reject if model still sent full module (avoid overwriting other files downstream).
    if (raw.containsKey("agent") ||
        raw.containsKey("flow") ||
        raw.containsKey("events") ||
        raw.containsKey("behavior")) {
      stdout.writeln(
        "⚠️ ${_tr(en: "Omi returned non-UI keys; only \"page\" will be written.", es: "Omi devolvió claves fuera de la vista; solo se escribirá \"page\".")}",
      );
    }

    return {"page": page};
  }

  /// Resolves the `omega_architecture` package root (checks [pubspec.yaml] name).
  static String? _omegaAiPackageRoot() {
    final override = Platform.environment["OMEGA_PACKAGE_ROOT"]?.trim();
    if (override != null && override.isNotEmpty) {
      final d = Directory(override);
      if (d.existsSync() && _omegaAiPubspecIsOmegaArchitecture(d.path)) {
        return d.absolute.path;
      }
    }
    try {
      final script = Platform.script;
      if (script.scheme != "file") return null;
      var dir = File.fromUri(script).absolute.parent;
      for (var i = 0; i < 18; i++) {
        if (_omegaAiPubspecIsOmegaArchitecture(dir.path)) {
          return dir.absolute.path;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}
    return null;
  }

  static bool _omegaAiPubspecIsOmegaArchitecture(String dirPath) {
    try {
      final f = File("$dirPath${Platform.pathSeparator}pubspec.yaml");
      if (!f.existsSync()) return false;
      final t = f.readAsStringSync();
      return RegExp(
        r"^name:\s*omega_architecture\s*$",
        multiLine: true,
      ).hasMatch(t);
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _omegaAiHttpGetText(String url, int maxBytes) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme != "http" && uri.scheme != "https") return null;
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        "omega_architecture-cli/$_version",
      );
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length >= maxBytes) break;
      }
      var text = utf8.decode(bytes, allowMalformed: true);
      if (text.length > maxBytes) {
        text =
            "${text.substring(0, maxBytes)}\n... [truncated after $maxBytes bytes]";
      }
      return text;
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  /// Builds the **PACKAGE GROUND TRUTH** attachment: example Dart the model must mimic (not invent APIs).
  static Future<String> _omegaAiBuildPackageGroundTruthBlock({
    required bool pageOnly,
    bool compactForHeal = false,
  }) async {
    final env = Platform.environment;
    if (env["OMEGA_AI_SKIP_PACKAGE_CONTEXT"] == "true") return "";

    final buf = StringBuffer();
    final root = _omegaAiPackageRoot();
    final maxEachExample = compactForHeal ? 6000 : 10000;
    final maxEachDoc = compactForHeal ? 4000 : 8000;
    final maxTotal = compactForHeal ? 22000 : 45000;
    final attachPackageDocs = env["OMEGA_AI_ATTACH_PACKAGE_DOCS"] == "true";
    final sep = Platform.pathSeparator;

    if (root != null) {
      final List<String> exampleRels;
      if (compactForHeal) {
        exampleRels = [
          "example/lib/omega/omega_setup.dart",
          "example/lib/auth/auth_behavior.dart",
          "example/lib/auth/auth_agent.dart",
        ];
      } else if (pageOnly) {
        exampleRels = [
          "example/lib/auth/ui/auth_page.dart",
          "example/lib/omega/omega_setup.dart",
        ];
      } else {
        exampleRels = [
          "example/lib/omega/omega_setup.dart",
          "example/lib/auth/auth_flow.dart",
          "example/lib/auth/auth_behavior.dart",
          "example/lib/auth/auth_agent.dart",
          "example/lib/auth/ui/auth_page.dart",
          "example/lib/omega/app_semantics.dart",
          "example/lib/omega/app_runtime_ids.dart",
        ];
      }

      for (final rel in exampleRels) {
        final f = File("$root$sep${rel.replaceAll("/", sep)}");
        if (f.existsSync()) {
          var text = f.readAsStringSync();
          if (text.length > maxEachExample) {
            text =
                "${text.substring(0, maxEachExample)}\n... [truncated, was ${text.length} chars]";
          }
          buf.writeln("--- PACKAGE EXAMPLE: $rel ---");
          buf.writeln(text);
          buf.writeln();
        }
      }

      if (!compactForHeal && attachPackageDocs) {
        for (final rel in ["doc/ARQUITECTURA.md", "README.md"]) {
          final f = File("$root$sep${rel.replaceAll("/", sep)}");
          if (f.existsSync()) {
            var text = f.readAsStringSync();
            if (text.length > maxEachDoc) {
              text = "${text.substring(0, maxEachDoc)}\n... [truncated]";
            }
            buf.writeln("--- PACKAGE DOC FILE: $rel ---");
            buf.writeln(text);
            buf.writeln();
          }
        }
      }
    }

    if (env["OMEGA_AI_SKIP_REMOTE_DOCS"] != "true" && !compactForHeal) {
      final urls = <String>[];
      final urlsEnv = env["OMEGA_AI_DOCS_URLS"]?.trim();
      final urlEnv = env["OMEGA_AI_DOCS_URL"]?.trim();
      if (urlsEnv != null && urlsEnv.isNotEmpty) {
        urls.addAll(
          urlsEnv.split(",").map((s) => s.trim()).where((s) => s.isNotEmpty),
        );
      } else if (urlEnv != null && urlEnv.isNotEmpty) {
        urls.add(urlEnv);
      }
      const maxUrlBytes = 65536;
      for (final url in urls.take(5)) {
        final body = await _omegaAiHttpGetText(url, maxUrlBytes);
        if (body != null && body.trim().isNotEmpty) {
          buf.writeln("--- REMOTE DOCUMENTATION (HTTP GET) ---");
          buf.writeln("URL: $url");
          buf.writeln(body);
          buf.writeln();
        }
      }
    }

    final raw = buf.toString().trim();
    if (raw.isEmpty) return "";
    var block =
        "PACKAGE GROUND TRUTH (authoritative Omega patterns for this call — match them; do not invent APIs that are not in this block or in `package:omega_architecture/omega_architecture.dart`):\n\n$raw\n";
    if (block.length > maxTotal) {
      block = "${block.substring(0, maxTotal)}\n... [GROUND TRUTH TRUNCATED]\n";
    }
    return block;
  }

  static Future<Map<String, String>?> _providerGenerateModuleCode(
    String description,
    String moduleName, {
    required String appPubspecName,
    String? productContext,
    Map<String, String>? currentFiles,
    bool pageOnly = false,
  }) async {
    if (!_OmegaAiRemote.canCallRemote()) return null;

    final pkgId = appPubspecName.trim().isEmpty ? "app" : appPubspecName.trim();
    final lower = moduleName.toLowerCase();
    final projectPackageBlock = """

PROJECT PUBSPEC NAME (mandatory — read before any import line that uses package: for THIS app):
- pubspec.yaml name: is exactly: **$pkgId**
- Allowed package: URIs in generated Dart: only package:omega_architecture/... and package:$pkgId/...
- FORBIDDEN: inventing an id from the product description (delivery_app, shop, etc.) or placeholder text.
- Prefer relative imports between files in lib/$lower/ (e.g. import '${lower}_events.dart';). Use package:$pkgId/omega/app_runtime_ids.dart (or app_semantics.dart) when importing lib/omega/* from a feature module.

STEPWISE — build in phases (still ONE JSON reply with all keys, but do not design everything in parallel):
- Treat this as a pipeline, not a single blob: complete **(1) events** end-to-end (intents, events, ViewState, typed payloads) before you invent any behavior rule names. Then **(2) behavior** (every OmegaAgentReaction actionId) before **(3) agent** onAction switch strings — those strings must match behavior exactly. Then **(4) flow** (contract lists, onIntent/onEvent names) only using names already in events + what behavior/flow emit. Then **(5) page** last — only OmegaScope / getFlow / intents & events you already defined.
- WRONG: writing the page or flow first and back-filling events; adding flow steps that reference event names not in *_events.dart*; behavior actionIds that do not exist as case "..." in the agent.
- RIGHT: after each phase, mentally cross-check wire strings and actionIds against the previous file; then emit the next file. Prefer the smallest feature that satisfies the instruction in this pass — no extra screens, deps, or enums “for later”.

${OmegaAiCommand._omegaAiConceptualArchitecture}

${OmegaAiCommand._omegaAiOmegaSourceOfTruth}

""";
    final camelAgentVar = moduleName.isEmpty
        ? "moduleAgent"
        : "${moduleName[0].toLowerCase()}${moduleName.substring(1)}Agent";
    final contextBlock =
        (productContext != null && productContext.trim().isNotEmpty)
        ? """
OVERALL PRODUCT / APP CONTEXT (use for screen purpose, layout, labels, tone, and domain widgets; keep Omega APIs correct):
${productContext.trim()}

"""
        : "";

    final filesContextBlock = (currentFiles != null && currentFiles.isNotEmpty)
        ? """
${pageOnly ? "EXISTING MODULE FILES (REFERENCE ONLY — keep agent, flow, behavior, and events on disk unchanged; only the page Dart may change):" : "CURRENT MODULE CODE (EVOLVE AND REDESIGN THIS CODE, DO NOT IGNORE EXISTING LOGIC):"}
${currentFiles.entries.map((e) => "--- FILE: ${e.key} ---\n${e.value}").join("\n\n")}

"""
        : "";

    final packageGroundTruth = await _omegaAiBuildPackageGroundTruthBlock(
      pageOnly: pageOnly,
    );
    if (packageGroundTruth.isNotEmpty) {
      stdout.writeln(
        "  ${_tr(en: "Omi: attached package examples/docs (${packageGroundTruth.length} chars)", es: "Omi: ejemplos/docs del paquete (${packageGroundTruth.length} caracteres)")}",
      );
    }
    final packageContextBlock = packageGroundTruth.isEmpty
        ? ""
        : "$packageGroundTruth\n";

    late final String prompt;
    late final String aiSystemContent;
    if (pageOnly) {
      aiSystemContent =
          "You output exactly one JSON object (json_object mode). UI-ONLY mode: keys reasoning + page (+ optional response) only. NEVER events/agent/flow/behavior — this is a **single-step** task: only the page file. Output valid Dart (Flutter) source only — not Kotlin, Swift, TypeScript, or pseudocode. Follow ONLY Omega APIs and patterns from package:omega_architecture/omega_architecture.dart plus the user prompt (PACKAGE GROUND TRUTH + rules); do not invent scope getters, flow APIs, or alternate packages. The page MUST import package:omega_architecture/omega_architecture.dart and package:flutter/material.dart so OmegaScope and types resolve. If the page references the module agent type (e.g. ${moduleName}Agent) or OmegaAgentBuilder<${moduleName}Agent,...>, add import '../${lower}_agent.dart' the same way as events (example: auth_page imports ../auth_agent.dart). OmegaScope, getFlow, StreamBuilder, OmegaIntent.fromName using ONLY existing intents from the reference files. If you emit any import package:THIS_APP/..., THIS_APP must be exactly **$pkgId** from the user prompt PROJECT PUBSPEC NAME block. No prose outside JSON.";
      prompt =
          """
UI-ONLY REDESIGN for Omega module '$moduleName' ($lower).
$projectPackageBlock
USER INSTRUCTION: '$description'.
$contextBlock
$filesContextBlock
$packageContextBlock
OUTPUT JSON RULES:
1. Required string keys: "reasoning" (2-5 lines: confirm you only adjusted UI against existing module contracts — no new intents/events), "page" (complete Dart for ${moduleName}Page — file path conceptually: ui/${lower}_page.dart).
2. Optional: "response" (duplicate of "page").
3. FORBIDDEN: do not include keys "events", "behavior", "agent", or "flow" in the JSON at all.
4. Page must use: import 'package:flutter/material.dart'; import 'package:omega_architecture/omega_architecture.dart'; import '../${lower}_events.dart'; if the screen uses type ${moduleName}Agent or OmegaAgentBuilder<${moduleName}Agent,...> you MUST add import '../${lower}_agent.dart'; (otherwise Undefined class ${moduleName}Agent).
5. Keep class name ${moduleName}Page, OmegaScope.of(context), scope.flowManager.getFlow('$moduleName'), StreamBuilder<OmegaFlowExpression>. Use existing ${moduleName}Intent / ${moduleName}Event names from the reference — do not rename or replace non-UI files.

$_omegaAiScreenEntryDataLoad
$_omegaAiOmegaChannelEvents
$_omegaAiNavigationChannelEmit
$_omegaAiMainDartEntry
$_omegaAiAgentUiStateListening
$_omegaAiFlowActivatorAndFlowManager
$_omegaAiRolesFlowAgentBehavior
$_omegaAiUtf8StringLiterals
$_omegaAiUiDesignStandards

Return only one JSON object. No markdown fences. No text outside JSON.
""";
    } else {
      aiSystemContent =
          "You are a Senior Flutter Developer writing Dart (Flutter) only. You output exactly one JSON object (json_object mode) with string values only. Include \"reasoning\" in the user’s language as **numbered steps 1→5** matching STEPWISE (events → behavior → agent → flow → page) — short lines per step; do not collapse into one vague paragraph. Every code value MUST be valid Dart — never Kotlin, Swift, TypeScript, or pseudocode. Use ONLY Omega APIs from package:omega_architecture/omega_architecture.dart and the patterns in the user prompt (MASTER CHECKLIST, templates, PACKAGE GROUND TRUTH); do not invent Omega types, scope members, agent methods, or internal package paths. You MUST satisfy the MASTER CHECKLIST BY FILE for events, behavior, agent, flow, and page so all five artifacts + setup wiring are coherent (same FLOW_ID, behavior actionIds = agent switch strings, flow contract matches real emits). When the app uses lib/omega/app_runtime_ids.dart, wire AppFlowId/AppAgentId in agent and flow files and keep enum bodies updated. Every file MUST import 'package:omega_architecture/omega_architecture.dart' where Omega types are used; page also needs flutter/material. The page that references ${moduleName}Agent MUST import '../${lower}_agent.dart'. Do NOT invent OmegaViewState. Behavior: addRule/OmegaAgentBehaviorRule only; agent: onAction with string cases; flow: contract + onIntent/onEvent; page: OmegaScope + kickoff. For any import package:THIS_APP/... the identifier THIS_APP must be exactly **$pkgId** from the user prompt PROJECT PUBSPEC NAME block (never a marketing slug). For full apps: cold start = Login route + auth flow; Home = shell with global navigation; success path must navigate Login → Home. No prose outside JSON.";
      prompt =
          """
Generate COMPLETE and FUNCTIONAL Dart (Flutter) code only — not Kotlin, Swift, TypeScript, or pseudocode — for an Omega Architecture module named '$moduleName' ($lower).
$projectPackageBlock
PRIMARY FOCUS / INSTRUCTION: '$description'.
$contextBlock
$filesContextBlock
$packageContextBlock
REFERENCE (official package patterns; PRIMARY: example/lib/omega/omega_setup.dart in PACKAGE GROUND TRUTH — agents, flows, routes, initialFlowId, initialNavigationIntent; **example/lib/main.dart** for `lib/main.dart` — OmegaScope + OmegaInitialRoute + RootHandler; auth_flow.dart for Flow ctor with channel + agent):
- **omega_setup.dart is the source of truth:** same agent variable in `agents:` and in each `SomeFlow(channel: ns, agent: thatAgent)`; optional `channel.namespace('x')` per module. **DEDUPE:** each agent variable **once** in `agents: <OmegaAgent>[...]`; each `OmegaRoute(id: 'X')` **once** per id in `routes:` (never two routes with the same `id:`); each flow ctor **once** in `flows:`. For flows with **extra** non-agent deps (offline queue, repos), mirror your app’s existing patterns or doc/GUIA — not duplicated in this prompt to save tokens.
- Agent + behavior ground truth (same repo): example/lib/auth/auth_behavior.dart + example/lib/auth/auth_agent.dart — match their structure before inventing patterns.
- Typed ids: if the app has `lib/omega/app_runtime_ids.dart`, use `super(id: AppFlowId.$moduleName.id, ...)` / `super(id: AppAgentId.$moduleName.id, ...)` with `import 'package:$pkgId/omega/app_runtime_ids.dart';` and ensure both enums contain a `$moduleName,` entry (user would run `omega g ecosystem $moduleName` to merge; in JSON you may edit that file to add the member). CLI: `omega g ecosystem` updates both enums; `omega g agent` only AppAgentId; `omega g flow` only AppFlowId.
- Flow id: ${moduleName}Flow must use super(id: ...) consistent with getFlow / OmegaFlowExpressionBuilder (string or AppFlowId.$moduleName.id). If this module is the app entry flow, OmegaConfig.initialFlowId in omega_setup.dart must be that same wire string (example legacy: AuthFlow id "authFlow" and OmegaConfig.initialFlowId: "authFlow").
- Pages: scope.flowManager.getFlow('$moduleName'); StreamBuilder<OmegaFlowExpression>(stream: flow.expressions, ...).
- omega_setup.dart (not in this JSON): add imports `../$lower/${lower}_flow.dart`, `../$lower/${lower}_agent.dart`, `../$lower/ui/${lower}_page.dart` (from lib/omega/) or `package:$pkgId/...` (same **$pkgId** as PROJECT PUBSPEC NAME above). **One agent instance:** `final $camelAgentVar = ${moduleName}Agent(channel);` in agents:[...]. **Flow:** `${moduleName}Flow(channel: channel, agent: $camelAgentVar)` when the generated flow holds `uiScopeAgent` (required for OmegaFlowExpressionBuilder + OmegaScopedAgentBuilder); otherwise `${moduleName}Flow(channel)` only if the flow has no agent field. NEVER `${moduleName}Agent(channel)` twice (once in agents and again implicitly in Flow). **Extra flow dependencies** (NOT agents): e.g. `OmegaOfflineQueue`, repositories — create once in createOmegaConfig and pass **named** into the flow ctor (see example `OrdersFlow(..., offlineQueue: offlineQueue)`); `omega g ecosystem` does not generate those — add by hand when the spec requires them. If ${moduleName}Page has `required ${moduleName}Agent agent`: pass `$camelAgentVar` to the Page. If the page is const + scoped: `OmegaRoute(id: '$moduleName', builder: (context) => const ${moduleName}Page())` **only** when Flow exposes `uiScopeAgent` with the same `$camelAgentVar`. Typed routes: OmegaRoute.typed<T>(...).
- Contracts (debug warnings): OmegaWorkflowFlow always emits workflow.step (and failStep emits workflow.error)—include those in emittedExpressionTypes. Flow listenedEventNames must include *.requested if that event is published on the same bus. On a shared global channel, agents should use OmegaAgentContract(listenedEventNames: {}) OR wire agents/flows with channel.namespace('$lower') for isolation.

$_omegaAiScreenEntryDataLoad
$_omegaAiOmegaChannelEvents
$_omegaAiNavigationChannelEmit
$_omegaAiMainDartEntry
$_omegaAiAgentUiStateListening
$_omegaAiFlowActivatorAndFlowManager
$_omegaAiRolesFlowAgentBehavior
$_omegaAiOmegaWorkflowFlow
$_omegaAiAgentBehaviorApi
$_omegaAiCompleteArtifactGuide
$_omegaAiLoginHomeShell
$_omegaAiUtf8StringLiterals
${_omegaAiEventsFileAllowlist(moduleName, lower)}
CRITICAL RULES:
1. IMPORTS — EVERY generated Dart string (events, behavior, agent, flow) MUST start with:
   import 'package:omega_architecture/omega_architecture.dart';
   The page file MUST have that import PLUS import 'package:flutter/material.dart'; (order: flutter first or architecture first, both valid).
   Without this line, the app will show Undefined class OmegaAgent / OmegaEventBus / OmegaFlow / OmegaIntentName.
2. NEVER use internal paths like 'package:omega_architecture/omega/core/...' or relative imports into the package.
3. Class names use '$moduleName' (PascalCase). File-level imports for sibling files: '${lower}_events.dart' or '../${lower}_events.dart' from ui/. If the page uses type ${moduleName}Agent or OmegaAgentBuilder<${moduleName}Agent,...>, it MUST also import '../${lower}_agent.dart' (see example/lib/auth/ui/auth_page.dart + ../auth_agent.dart).
4. Return ONE JSON object. Every value MUST be a JSON string (no nested objects for code). Required keys:
   - "reasoning": 6-12 short lines in natural language (Spanish if the user wrote in Spanish). MUST be numbered **1)** through **5)** for phases: events → behavior → agent → flow → page (one line each: what you locked in that phase). Then add: FLOW_ID; first-load path (handleIntent vs channel emit); confirm behavior actionIds = agent switch cases; every `package:` for this app is **$pkgId**; brief UI note. No markdown fences.
   - "events", "behavior", "agent", "flow", "page": full Dart file contents as strings (same as before).
   - "response" (optional): if the user asked for a single "template" or "código de pantalla", you MAY put the same full Dart as "page" here too so tools can read one field; if omitted, "page" alone is enough.
5. ENUMS in **"events"** (module `*_events.dart`): **`enum ${moduleName}Intent with OmegaIntentNameDottedCamel implements OmegaIntentName`** and **`enum ${moduleName}Event with OmegaEventNameDottedCamel implements OmegaEventName`** — camelCase members only; wire strings come from the mixin (e.g. member `navigateRegister` → wire `navigate.register`). NEVER write `implements OmegaIntent` / `implements OmegaEvent` on an enum. NEVER call `OmegaEventName('...')` / `OmegaIntentName('...')`. **FORBIDDEN everywhere in greenfield code (modules AND `lib/omega/app_semantics.dart`):** `const MyCase('a.b'); const Foo(this.name); @override final String name;` — use **example/lib/omega/app_semantics.dart** as the app-wide pattern (`AppEvent` / `AppIntent` with DottedCamel mixins only).
6. UI: OmegaIntent.fromName(${moduleName}Intent.${lower}Start) — pass the enum constant, NOT a String, NOT ${moduleName}Intent.${lower}Start.name.
7. If the page uses OmegaAgentBuilder with `required ${moduleName}Agent agent`, put in "reasoning" one line: user must set omega_setup route to ${moduleName}Page(agent: $camelAgentVar) and declare `final $camelAgentVar = ${moduleName}Agent(channel);` (or `channel: channel` if ctor is named-only) in agents — same pattern as example omega_setup + auth page.
8. If the screen lists items, metrics, or catalog data: the "page" MUST implement an on-open kickoff per SCREEN ENTRY rules (activate + one-shot handleIntent(start) and/or channel emit of *.requested) so data loads without requiring a dummy first tap.
9. Do NOT reply with plain text outside JSON. Do NOT wrap the JSON in markdown. The entire assistant message must parse as one JSON object.
10. JSON string values that contain Dart: in JSON a backslash may only introduce the usual escapes (quote, another backslash, slash, b, f, n, r, t, or u plus four hex digits). Any other backslash-plus-character (including before a dollar sign, space, or letters) is invalid and breaks jsonDecode (FormatException: unrecognized string escape). Avoid lone backslashes in embedded Dart; use concatenation or double each literal backslash per JSON rules. The CLI repairs some invalid escapes before decode; still emit valid JSON when possible.
11. Intent payload classes (passed to OmegaIntent.fromName(..., payload: YourPayload(...))): **plain Dart only** — NOT [OmegaTypedEvent]. **FORBIDDEN:** `implements OmegaIntentPayload`, `implements OmegaEventPayload`, or both — **those types are not in** package:omega_architecture (undefined class). Optional: `extends Equatable` only if pubspec has `equatable` and you avoid fake omega `implements`. Named arguments when constructing the payload MUST match **field names** (e.g. `userName:` not `name:` when the field is `userName`).
12. If the JSON includes **`lib/omega/omega_setup.dart`**: `OmegaConfig` MUST include **`initialFlowId:`** (auth/login flow id) **and** **`initialNavigationIntent: OmegaIntent.fromName(AppIntent.navigateLogin)`** when the app has login+home. Login route: **`OmegaRoute(id: 'login', ...)`** (not `Auth` — navigator matches `navigate.login` → id **`login`**). Home route: **`id: 'home'`**. On valid login, auth flow/agent emits **`navigateHome`** via `AppEvent.navigationIntent`. **HomePage** must expose attractive navigation (cards / list tiles / rail) to every other module route. Never duplicate the same agent in `agents:` or the same `id:` twice in `routes:`.
13. **`AppIntent` + routes:** Every `OmegaIntent.fromName(AppIntent.someCase)` must use a **`someCase` that exists** in `app_semantics.dart` (exact spelling — no `navigateOrderDetails` vs `navigateOrderDetail` mix-ups). Every such navigation target needs **`OmegaRoute(id: '<segment after navigate.>', …)`** where the id matches the navigator rule (DottedCamel → dotted wire; e.g. `navigateDeliveryDetail` → id **`delivery.detail`**). If you emit a navigate intent, register the matching route in the same JSON or state it explicitly in **reasoning**.
14. If the JSON includes **`lib/main.dart`** (or you describe the host entry): **[OmegaScope]** MUST use **`initialFlowId: runtime.initialFlowId`** and **`initialNavigationIntent: runtime.initialNavigationIntent`** after **`OmegaRuntime.bootstrap(createOmegaConfig)`** — **FORBIDDEN** string literals on `OmegaScope` for cold start (e.g. `initialFlowId: 'Auth'`) and **FORBIDDEN** omitting **`initialNavigationIntent`** when `MaterialApp` uses **`OmegaInitialRoute`**. Single source of truth: **`OmegaConfig`** in `omega_setup.dart`; `main.dart` only forwards **`runtime`**.
15. **CLI post-check:** `omega ai coach module` / `omega ai coach redesign` runs **`omega validate`** on the app root after a successful pass (when `lib/omega/omega_setup.dart` exists). **`omega create app`** runs one final **`omega validate`** after modules + `main.dart`. Your emitted **`OmegaConfig`** must pass those checks (**`initialFlowId`**, **`initialNavigationIntent`**, **`login`/`home` route ids** when applicable, no duplicate `agents:`/`flows:`/`routes:` entries).

UI DESIGN (apply to the 'page' value only — maximize quality; the structural snippet below is NOT the final UI):
$_omegaAiUiDesignStandards
- Map the PRIMARY FOCUS / INSTRUCTION above to a concrete layout (auth, feed, settings, wizard, etc.); add enough widgets that the screen feels like a shipped feature.

FILE TEMPLATES AND RULES (STRUCTURE ONLY - DO NOT COPY PASTE THE UI CONTENT):

- 'events' (copy this pattern exactly for intent/event enums — **do not** substitute “explicit string per enum case” styles from other tutorials):
  - enum ${moduleName}Intent with OmegaIntentNameDottedCamel implements OmegaIntentName { ${lower}Start, ${lower}Retry; } — wires `$lower.start`, `$lower.retry`.
  - enum ${moduleName}Event with OmegaEventNameDottedCamel implements OmegaEventName { navigationIntent, ${lower}Requested, ${lower}Succeeded, ${lower}Failed; } — `navigationIntent` → `navigation.intent`; add e.g. navigateRegister on Intent enum (member `navigateRegister` → `navigate.register`) matching OmegaRoute ids.
  - FORBIDDEN here: `enum AuthIntent implements OmegaIntentName { x('a.b'); const AuthIntent(this.name); final String name; }` (and the same for `OmegaEventName`) — use **only** the two **with Omega…DottedCamel** enum lines above; the mixin derives dotted wires from camelCase [Enum.name].
  - class ${moduleName}RequestedEvent implements OmegaTypedEvent { const ${moduleName}RequestedEvent({required this.input}); final String input; @override String get name => ${moduleName}Event.${lower}Requested.name; }
  - class ${moduleName}ViewState { /* plain class — NOT extends OmegaViewState (not in package); NO Equatable; NO @immutable import circus */
      final bool isLoading; final String? error;
      const ${moduleName}ViewState({this.isLoading = false, this.error});
      ${moduleName}ViewState copyWith({bool? isLoading, String? error}) => ${moduleName}ViewState(isLoading: isLoading ?? this.isLoading, error: error);
      static const idle = ${moduleName}ViewState();
    }
  - When handling channel events (OmegaEvent): unwrap typed classes with event.payloadAs<${moduleName}RequestedEvent>() (or your other OmegaTypedEvent types). Do NOT use if (event is ${moduleName}RequestedEvent) — typed events are not subtypes of OmegaEvent.

- 'behavior' (Omega architecture — NOT a BLoC; mirror example/lib/auth/auth_behavior.dart for style):
  - import '${lower}_events.dart';
  - Every rule MUST be addRule(OmegaAgentBehaviorRule(condition: ..., reaction: ...)) — never addRule(condition: ...) without OmegaAgentBehaviorRule (that is a compile error).
  - class ${moduleName}Behavior extends OmegaAgentBehaviorEngine { ${moduleName}Behavior() { addRule(OmegaAgentBehaviorRule(...)); addRule(OmegaAgentBehaviorRule(...)); /* as many rules as needed */ } }
  - Patterns: (1) several intents sharing one reaction: condition uses || on ctx.intent?.name == ${moduleName}Intent.${lower}Start.name etc. (2) one intent with typed payload: condition adds && (ctx.intent?.payload is String) or use ctx.intent?.payloadAs<YourPayloadType>() != null. (3) react to channel events: ctx.event?.name == ${moduleName}Event.${lower}Succeeded.name and pass ctx.event?.payloadAs<YourTypedEvent>()?.field into OmegaAgentReaction payload.
  - reaction: (ctx) => OmegaAgentReaction('distinctActionId', payload: ...) — keep rules declarative; no async. Order rules from more specific to general if needed.
  - Alternative: override evaluate(OmegaAgentBehaviorContext ctx) synchronously; return OmegaAgentReaction(...) or null.
  - FORBIDDEN: handleEvent, Stream, async*, yield, OmegaAgentMessage, msg.type. Async work and setViewState live in ${moduleName}Agent.onAction (one case per actionId).

- 'agent':
  - import '${lower}_events.dart' and '${lower}_behavior.dart';
  - Prefer `${moduleName}Agent(OmegaEventBus channel)` (positional) like example/lib/auth/auth_agent.dart so omega_setup can use `Agent(channel)`. If you use `${moduleName}Agent({required OmegaEventBus channel})`, omega_setup must use `Agent(channel: channel)`.
  - class ${moduleName}Agent extends OmegaStatefulAgent<${moduleName}ViewState> {
      ${moduleName}Agent(OmegaEventBus channel) : super(id: '$moduleName', channel: channel, behavior: ${moduleName}Behavior(), initialState: ${moduleName}ViewState.idle);
      @override OmegaAgentContract? get contract => OmegaAgentContract(listenedEventNames: {});
      @override void onMessage(OmegaAgentMessage msg) {}
      @override void onAction(String action, dynamic payload) { /* switch(action) { case "actionIdString": ... } — string literals only, NOT case Enum.foo.name. setViewState(viewState.copyWith(...)) — NOT state.copyWith */ }
    }

- 'flow':
  - import '${lower}_events.dart'; import '${lower}_agent.dart'; when the flow stores the module agent.
  - **Default ecosystem template:** only `channel` + `agent` + `uiScopeAgent`. If the feature needs **other** services (cola offline, API client, repo), add **named** fields to the flow ctor and document them; in omega_setup create each dependency **once** above `OmegaConfig` and pass them into the flow (example: `OrdersFlow(channel: ns, agent: a, offlineQueue: q)`). Those extras are **not** agents and are **not** auto-generated by `omega g ecosystem` — extend the generated flow + omega_setup manually.
  - class ${moduleName}Flow extends OmegaWorkflowFlow {
      ${moduleName}Flow({required super.channel, required this.agent}) : super(id: '$moduleName') {
        defineStep('start', () => emitExpression('loading'));
        defineStep('done', () => completeWorkflow());
      }
      final ${moduleName}Agent agent;
      @override OmegaAgent? get uiScopeAgent => agent;
      @override OmegaFlowContract? get contract => OmegaFlowContract(
        acceptedIntentNames: {${moduleName}Intent.${lower}Start.name, ${moduleName}Intent.${lower}Retry.name},
        listenedEventNames: {${moduleName}Event.${lower}Requested.name, ${moduleName}Event.${lower}Succeeded.name, ${moduleName}Event.${lower}Failed.name},
        emittedExpressionTypes: {'idle', 'loading', 'success', 'error', 'workflow.done', 'workflow.step', 'workflow.error'},
      );
      @override void onStart() { emitExpression('idle'); }
      @override void onIntent(OmegaFlowContext ctx) { /* use ctx.intent?.name == ${moduleName}Intent.${lower}Start.name; payload: ctx.intent?.payloadAs<...>(); NEVER ctx.getAgentViewState — OmegaFlowContext only has event, intent, memory */ }
      @override void onEvent(OmegaFlowContext ctx) { /* on succeeded: emitExpression('success'); next('done'); on failed: emitExpression('error', payload: ...); failStep('code', message: ...) — failStep has only one positional arg */ }
    }

- 'page' (STRUCTURE ONLY - REWRITE THE UI CONTENT):
  - import 'package:flutter/material.dart'; import 'package:omega_architecture/omega_architecture.dart'; import '../${lower}_events.dart'; AND for (B) add import '../${lower}_agent.dart'; so ${moduleName}Agent resolves (omega_architecture.dart does NOT export your app agent class).
  - FORBIDDEN unless the app pubspec lists them: package:intl, DateFormat, package:equatable. Format dates with string interpolation on DateTime fields or toString(); use OmegaStatefulAgent.stateStream (or viewStateStream alias on current package) — never invent APIs on the agent.
  - EITHER (A) flow-only: prefer StatefulWidget if you need didChangeDependencies for activate + one-shot kickoff; otherwise StatelessWidget is OK only when flow onStart or another layer already loads data.
  - OR (B) agent + flow: StatefulWidget or StatelessWidget; if lists come from OmegaAgentBuilder, almost always use StatefulWidget with didChangeDependencies + bool guard: activate('$moduleName'), then handleIntent(start) OR channel.emit(requested) per behavior — omega_setup MUST pass agent as for (B) below.
  - Flow-only skeleton (A) with automatic first load (rewrite UI body, keep kickoff):
      class ${moduleName}Page extends StatefulWidget {
      const ${moduleName}Page({super.key});
      @override State<${moduleName}Page> createState() => _${moduleName}PageState();
    }
    class _${moduleName}PageState extends State<${moduleName}Page> {
      bool _entryKickApplied = false;
      @override void didChangeDependencies() {
        super.didChangeDependencies();
        if (_entryKickApplied) return;
        _entryKickApplied = true;
        final scope = OmegaScope.of(context);
        scope.flowManager.activate('$moduleName');
        scope.flowManager.handleIntent(OmegaIntent.fromName(${moduleName}Intent.${lower}Start));
      }
      @override Widget build(BuildContext context) {
        final scope = OmegaScope.of(context);
        final flow = scope.flowManager.getFlow('$moduleName');
        if (flow == null) return const Scaffold(body: Center(child: Text('Flow not registered')));
        return Scaffold(
          appBar: AppBar(title: const Text('$moduleName')),
          body: StreamBuilder<OmegaFlowExpression>(
            stream: flow.expressions,
            builder: (context, snapshot) {
              final expr = snapshot.data;
              if (expr?.type == 'loading') return const Center(child: CircularProgressIndicator());
              // Full Material 3 UI: lists/cards — data should already be loading from kickoff + flow/agent chain
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(children: [ /* YOUR PROFESSIONAL UI DESIGN HERE */ ]),
              );
            },
          ),
        );
      }
    }
  - Agent + flow (B classic): `class ${moduleName}Page extends StatefulWidget { ${moduleName}Page({super.key, required this.agent}); final ${moduleName}Agent agent;` + same didChangeDependencies pattern if lists are agent-driven + OmegaAgentBuilder — omega_setup MUST use `final $camelAgentVar = ${moduleName}Agent(channel);` (or `${moduleName}Agent(channel: channel);` if the agent ctor is `{required OmegaEventBus channel}`) in agents: [..., $camelAgentVar] and `OmegaRoute(..., builder: (c) => ${moduleName}Page(agent: $camelAgentVar))`.
  - Agent + flow (B decoupled): `const ${moduleName}Page()` + body uses `OmegaFlowExpressionBuilder(flowId: '$moduleName', builder: (_, exp) => OmegaScopedAgentBuilder<${moduleName}Agent, ${moduleName}ViewState>(builder: (context, state) => /* UI from state only — TWO args */))` — then **flow** MUST have `agent` field + `uiScopeAgent` and omega_setup MUST wire `final $camelAgentVar = ${moduleName}Agent(channel);` once and `${moduleName}Flow(channel: channel, agent: $camelAgentVar)`.

Return ONLY one JSON object with string values, including "reasoning" plus "events","behavior","agent","flow","page". No markdown fences. No text before or after the JSON.
""";
    }

    final raw = await _OmegaAiRemote.completeChat(
      system: aiSystemContent,
      user: prompt,
      temperature: 0.3,
      jsonObject: true,
      timeout: const Duration(seconds: 180),
    );
    if (raw == null || raw.isEmpty) return null;

    try {
      final jsonText = _OmegaAiRemote.sanitizeAiJsonTextForDecode(
        _OmegaAiRemote.stripCodeFences(raw),
      );
      final decodedModule = jsonDecode(jsonText);
      if (decodedModule is! Map) {
        _err("Omi: provider JSON error — root is not a JSON object");
        return null;
      }
      if (pageOnly) {
        return _normalizeAiPageOnlyJson(
          Map<String, dynamic>.from(decodedModule),
        );
      }
      return _normalizeAiModuleJson(Map<String, dynamic>.from(decodedModule));
    } catch (e) {
      _err("Omi: provider JSON error: $e");
      return null;
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

    // Robust detection: use the same PascalCase logic as generation
    final pascalBase = toPascalCase(
      feature
          .replaceAll(RegExp(r"[^a-zA-Z0-9_ ]"), " ")
          .replaceAll(RegExp(r"\s+"), " ")
          .trim(),
    );
    final slug = pascalBase.toLowerCase();

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

    final hasFlowRegistration =
        setupContent.contains(
          RegExp("${RegExp.escape(pascalBase)}Flow\\s*\\("),
        ) ||
        setupContent.toLowerCase().contains("${slug}flow(");
    final hasAgentRegistration =
        setupContent.contains(
          RegExp("${RegExp.escape(pascalBase)}Agent\\s*\\("),
        ) ||
        setupContent.toLowerCase().contains("${slug}agent(");
    final hasRouteRegistration =
        setupContent.contains("id: '$pascalBase'") ||
        setupContent.contains("id: \"$pascalBase\"");

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
      if (!hasRouteRegistration) {
        gaps.add("Route is not registered in omega_setup.dart");
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
        _tr(
          en: "Omi is asking the assistant",
          es: "Omi consulta al asistente",
          pt: "Omi consulta o assistente",
          fr: "Omi consulte l'assistant",
          it: "Omi consulta l'assistente",
          de: "Omi fragt den Assistenten",
        ),
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

  /// Returns `false` when [useProviderApi] was set but the AI returned no usable module JSON
  /// (console generation stops; new modules are not scaffolded).
  static Future<bool> _coachModule({
    required String feature,

    /// Optional specific module name to update (e.g. "Login").
    /// If null, it tries to detect it from "Module: description" or generates a new name.
    String? updateModule,

    /// Full app description (e.g. `omega create app --kickstart "..."`) so each module's UI matches the product.
    String? productContext,
    required String template,
    required bool asJson,
    required bool useProviderApi,
    required bool toTempFile,

    /// When true (`omega ai coach redesign`), only `ui/*_page.dart` is regenerated; agent/flow/behavior/events stay as-is.
    bool uiOnly = false,

    /// When false, skips [OmegaValidateCommand.validateProjectRoot] at the end (e.g. `omega create app` kickstart runs one final validate after all modules + `main.dart`).
    bool runPostValidate = true,
  }) async {
    String moduleName;
    String cleanFeature = feature;

    if (updateModule != null && updateModule.isNotEmpty) {
      moduleName = toPascalCase(updateModule);
    } else {
      // Check if feature starts with "ModuleName: ..."
      final match = RegExp(r"^([a-zA-Z0-9_]+)\s*:\s*(.*)$").firstMatch(feature);
      if (match != null) {
        moduleName = toPascalCase(match.group(1)!);
        cleanFeature = match.group(2)!;
      } else {
        moduleName = toPascalCase(
          feature
              .replaceAll(RegExp(r"[^a-zA-Z0-9_ ]"), " ")
              .replaceAll(RegExp(r"\s+"), " ")
              .trim(),
        );
      }
    }

    final requiredArtifacts = _coachRequiredArtifacts(moduleName);
    final checks = _coachValidationChecks();
    final insights = <String>[];
    var validateOk = true;
    var mode = "offline";

    Map<String, String>? aiGeneratedCode;

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

    final lower = moduleName.toLowerCase();
    final modulePath = "$appLib${Platform.pathSeparator}$lower";
    final expectedFiles = <String>[
      "$modulePath${Platform.pathSeparator}${lower}_agent.dart",
      "$modulePath${Platform.pathSeparator}${lower}_flow.dart",
      "$modulePath${Platform.pathSeparator}${lower}_behavior.dart",
      "$modulePath${Platform.pathSeparator}${lower}_events.dart",
      "$modulePath${Platform.pathSeparator}ui${Platform.pathSeparator}${lower}_page.dart",
    ];

    final moduleDir = Directory(modulePath);
    final moduleExists = moduleDir.existsSync();

    if (uiOnly) {
      if (!useProviderApi) {
        _err(
          _tr(
            en: "Command redesign requires --provider-api.",
            es: "El comando redesign requiere --provider-api.",
          ),
        );
        return false;
      }
      if (!moduleExists) {
        _err(
          _tr(
            en: "Module folder not found: create the module first with 'omega ai coach module ...' or 'omega g ecosystem $moduleName'.",
            es: "No existe la carpeta del módulo: créalo antes con 'omega ai coach module ...' o 'omega g ecosystem $moduleName'.",
          ),
        );
        return false;
      }
    }

    if (useProviderApi) {
      final providerSteps = await _runWithProgress<List<String>?>(
        _tr(
          en: "Omi is asking the assistant",
          es: "Omi consulta al asistente",
          pt: "Omi consulta o assistente",
          fr: "Omi consulte l'assistant",
          it: "Omi consulta l'assistente",
          de: "Omi fragt den Assistenten",
        ),
        () => _providerCoachPlan(cleanFeature),
      );
      if (providerSteps != null && providerSteps.isNotEmpty) {
        insights.addAll(providerSteps);
        mode = "provider-api";
      }

      // Read current files if they exist to allow Redesign/Evolve
      final Map<String, String> currentFiles = {};
      final mapping = {
        "agent": expectedFiles[0],
        "flow": expectedFiles[1],
        "behavior": expectedFiles[2],
        "events": expectedFiles[3],
        "page": expectedFiles[4],
      };
      for (final entry in mapping.entries) {
        final f = File(entry.value);
        if (f.existsSync()) {
          currentFiles[entry.key] = f.readAsStringSync();
        }
      }

      final generated = await _runWithProgress<Map<String, String>?>(
        _tr(
          en: uiOnly
              ? "Omi is redesigning the screen (page only)"
              : "Omi is writing / redesigning module logic",
          es: uiOnly
              ? "Omi rediseña la vista (solo página)"
              : "Omi escribe o rediseña la lógica del módulo",
        ),
        () => _providerGenerateModuleCode(
          cleanFeature,
          moduleName,
          appPubspecName: getPackageName(appRoot),
          productContext: productContext,
          currentFiles: currentFiles.isNotEmpty ? currentFiles : null,
          pageOnly: uiOnly,
        ),
        treatNullAsFailure: true,
      );
      if (generated != null) {
        aiGeneratedCode = generated;
      }
    }

    var created = false;
    final originalCwd = Directory.current.path;
    if (hasSetup) {
      if (aiGeneratedCode == null && useProviderApi) {
        if (moduleExists) {
          _err(
            _tr(
              en: "Omi could not generate this pass. Keeping existing files for module '$moduleName'.",
              es: "Omi no pudo completar esta generación. Se mantienen los archivos del módulo '$moduleName'.",
            ),
          );
          stdout.writeln("");
          stdout.writeln(
            "⏹️ ${_tr(en: "Stopped — Omi's response was missing or invalid; module left unchanged.", es: "Detenido — la respuesta de Omi faltaba o era inválida; el módulo no se modificó.")}",
          );
          if (asJson) {
            _emitAiOutput(
              content: jsonEncode({
                "success": false,
                "error": "ai_generation_failed",
                "coach": uiOnly ? "redesign" : "module",
                "mode": mode,
                "feature": feature,
                "moduleName": moduleName,
                "modulePath": _absPath(modulePath),
                "uiOnly": uiOnly,
              }),
              toTempFile: toTempFile,
              kind: "coach_module",
              extension: "json",
            );
          }
          Directory.current = originalCwd;
          return false;
        } else {
          _err(
            _tr(
              en: "Omi could not create a new module — no valid assistant output.",
              es: "Omi no pudo crear el módulo nuevo — sin salida válida del asistente.",
            ),
          );
          stdout.writeln("");
          stdout.writeln(
            "⏹️ ${_tr(en: "Generation aborted. No ecosystem files were written for this module.", es: "Generación cancelada. No se escribieron archivos del ecosistema para este módulo.")}",
          );
          if (asJson) {
            _emitAiOutput(
              content: jsonEncode({
                "success": false,
                "error": "ai_generation_failed",
                "coach": uiOnly ? "redesign" : "module",
                "mode": mode,
                "feature": feature,
                "moduleName": moduleName,
                "modulePath": _absPath(modulePath),
                "uiOnly": uiOnly,
                "newModule": true,
              }),
              toTempFile: toTempFile,
              kind: "coach_module",
              extension: "json",
            );
          }
          Directory.current = originalCwd;
          return false;
        }
      }

      if (!(uiOnly && moduleExists)) {
        await _runWithProgress<void>(
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
      }
      if (template == "advanced" || uiOnly) {
        _applyAdvancedModuleTemplate(
          appRoot: appRoot,
          modulePath: modulePath,
          moduleName: moduleName,
          customCode: aiGeneratedCode,
        );
      }

      // Re-read *_page.dart after AI/advanced template: first register pass used the
      // Stateless scaffold and may have wired `const FooPage()`; sync agent + route.
      if (hasSetup && (template == "advanced" || uiOnly)) {
        registerInOmegaSetup(
          moduleName,
          modulePath,
          appRoot,
          registerAgent: true,
          registerFlow: true,
        );
      }

      if (uiOnly && aiGeneratedCode != null) {
        stdout.writeln(
          "✅ ${_tr(en: "Updated UI file only (${lower}_page.dart); agent, flow, behavior, and events were not modified.", es: "Solo se actualizó la vista (${lower}_page.dart); no se modificaron agent, flow, behavior ni events.")}",
        );
      }

      if (useProviderApi) {
        await OmegaCreateAppCommand._selfHealProject(appRoot, true);
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

    if (hasSetup && runPostValidate) {
      stdout.writeln("");
      stdout.writeln(
        _tr(
          en: "Running omega validate (OmegaConfig, cold start, duplicates)...",
          es: "Ejecutando omega validate (OmegaConfig, arranque en frio, duplicados)...",
        ),
      );
      validateOk = OmegaValidateCommand.validateProjectRoot(appRoot);
      if (!validateOk) {
        insights.add(
          _tr(
            en: "omega validate failed — fix omega_setup.dart (e.g. initialFlowId, initialNavigationIntent, routes), then run: dart run omega_architecture:omega validate",
            es: "omega validate fallo — corrige omega_setup.dart (p. ej. initialFlowId, initialNavigationIntent, rutas) y ejecuta: dart run omega_architecture:omega validate",
          ),
        );
      }
    }

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
          "success": true,
          "coach": uiOnly ? "redesign" : "module",
          "mode": mode,
          "feature": feature,
          "moduleName": moduleName,
          "template": template,
          "uiOnly": uiOnly,
          "modulePath": _absPath(modulePath),
          "requiredArtifacts": requiredArtifacts,
          "created": created,
          "createdFiles": createdFiles.map(_absPath).toList(),
          "validationChecks": checks,
          "insights": insights,
          "validateOk": validateOk,
        }),
        toTempFile: toTempFile,
        kind: "coach_module",
        extension: "json",
      );
      return true;
    }

    final out = StringBuffer()
      ..writeln("# Omi — Omega coach ${uiOnly ? "redesign" : "module"} ($mode)")
      ..writeln("")
      ..writeln("- Feature: `$feature`")
      ..writeln("- Module name: `$moduleName`")
      ..writeln("- Template: `$template`")
      ..writeln("- Module path: `${_absPath(modulePath)}`")
      ..writeln(
        "- ${_tr(en: "UI only (page)", es: "Solo vista (página)")}: `${uiOnly ? "yes" : "no"}`",
      )
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
        ..writeln("## ${_tr(en: "Omi's ideas", es: "Ideas de Omi")}");
      for (final i in insights) {
        out.writeln("- $i");
      }
    }
    out
      ..writeln("")
      ..writeln(
        "## ${_tr(en: "Post-generation: omega validate", es: "Post-generacion: omega validate")}",
      )
      ..writeln(
        "- ${_tr(en: "Result", es: "Resultado")}: `${validateOk ? "OK" : "FAILED"}`",
      );
    _emitAiOutput(
      content: out.toString(),
      toTempFile: toTempFile,
      kind: "coach_module",
      extension: "md",
    );
    return true;
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

  /// Normalizes plain-text / bullet replies from OpenAI and Gemini for coach, audit, explain.
  static List<String> _providerLinesFromText(String content, int maxLines) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return [];
    final lines = trimmed
        .split("\n")
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map(
          (l) => l
              .replaceFirst(RegExp(r"^[-*•]\s*"), "")
              .replaceFirst(RegExp(r"^\d+[\.\)]\s*"), ""),
        )
        .where((l) => l.isNotEmpty)
        .take(maxLines)
        .toList();
    return lines.isEmpty ? [trimmed] : lines;
  }

  static Future<List<String>?> _providerCoachPlan(String feature) async {
    if (!_OmegaAiRemote.canCallRemote()) return null;

    final targetLanguage = _preferredAiLanguage();
    final system =
        "You are Omega coding coach. Respond strictly in $targetLanguage. Return 5-7 concise numbered steps with practical guidance for implementation.";
    final user =
        "Create a practical step-by-step coding guide in Omega architecture for this feature: '$feature'. Include flow, agent, intents/events, setup wiring, and testing.";

    final content = await _OmegaAiRemote.completeChat(
      system: system,
      user: user,
      temperature: 0.2,
      jsonObject: false,
      timeout: const Duration(seconds: 35),
      silentErrors: true,
    );
    if (content == null || content.trim().isEmpty) return null;
    return _providerLinesFromText(content, 8);
  }

  static Future<List<String>?> _providerAuditInsights(
    String feature,
    List<String> gaps,
    List<String> findings,
  ) async {
    if (!_OmegaAiRemote.canCallRemote()) return null;

    final targetLanguage = _preferredAiLanguage();
    final system =
        "You are Omega architecture reviewer. Respond strictly in $targetLanguage with short actionable bullet points.";
    final user =
        "Feature: $feature\nCurrent findings: ${jsonEncode(findings)}\nCurrent gaps: ${jsonEncode(gaps)}\nReturn 3-6 prioritized actions to close gaps in Omega architecture.";

    final content = await _OmegaAiRemote.completeChat(
      system: system,
      user: user,
      temperature: 0.2,
      jsonObject: false,
      timeout: const Duration(seconds: 35),
      silentErrors: true,
    );
    if (content == null || content.trim().isEmpty) return null;
    return _providerLinesFromText(content, 8);
  }

  static Future<List<String>?> _providerExplain(
    List<Map<String, dynamic>> events,
  ) async {
    if (!_OmegaAiRemote.canCallRemote()) return null;

    final targetLanguage = _preferredAiLanguage();
    final system =
        "You are Omega architecture assistant. Return concise diagnostics as plain bullet lines only. Respond strictly in $targetLanguage.";
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
    final user =
        "Analyze this Omega trace event sequence and return 2-4 short bullet points: root cause guess, risky pattern, and concrete next check. Do not use markdown styling.\n${jsonEncode(compactEvents)}";

    final content = await _OmegaAiRemote.completeChat(
      system: system,
      user: user,
      temperature: 0.2,
      jsonObject: false,
      timeout: const Duration(seconds: 35),
      silentErrors: true,
    );
    if (content == null || content.trim().isEmpty) return null;
    return _providerLinesFromText(content, 6);
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
        en: "Omi saved output to temporary file:",
        es: "Omi guardó la salida en archivo temporal:",
        pt: "Omi salvou a saida em arquivo temporario:",
        fr: "Omi a enregistre la sortie dans un fichier temporaire:",
        it: "Omi ha salvato l'output in un file temporaneo:",
        de: "Omi hat die Ausgabe in einer temporaeren Datei gespeichert:",
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
    b.writeln("# Omi — Omega trace explain ($mode)");
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
    b.writeln("# Omi — Omega coach ($mode)");
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
      b.writeln("## ${_tr(en: "Omi's ideas", es: "Ideas de Omi")}");
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
    b.writeln("# Omi — Omega coach audit ($mode)");
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
      b.writeln("## ${_tr(en: "Omi's ideas", es: "Ideas de Omi")}");
      for (final item in insights) {
        b.writeln("- $item");
      }
    }

    return b.toString();
  }

  static Future<T> _runWithProgress<T>(
    String label,
    Future<T> Function() action, {
    bool treatNullAsFailure = false,
  }) async {
    return runWithProgress<T>(
      label,
      action,
      treatNullAsFailure: treatNullAsFailure,
    );
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

Future<T> runWithProgress<T>(
  String label,
  Future<T> Function() action, {

  /// When true and [action] returns `null`, print a failure line instead of "done."
  /// (Use for AI steps where null means the provider returned nothing usable.)
  bool treatNullAsFailure = false,
}) async {
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
    final dynamic nullableResult = result;
    final isNullFailure = treatNullAsFailure && nullableResult == null;
    if (isNullFailure) {
      stdout.writeln(
        _tr(
          en: "$label — failed (no usable response from Omi).",
          es: "$label — falló (sin respuesta usable de Omi).",
          pt: "$label — falhou (sem resposta utilizavel de Omi).",
          fr: "$label — echec (pas de reponse utilisable d'Omi).",
          it: "$label — fallito (nessuna risposta utilizzabile da Omi).",
          de: "$label — fehlgeschlagen (keine brauchbare Antwort von Omi).",
        ),
      );
    } else {
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
    }
    return result;
  } finally {
    timer.cancel();
  }
}
