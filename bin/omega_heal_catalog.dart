import 'dart:io';

import 'package:yaml/yaml.dart';

/// Loads [tool/omega_heal_catalog.yaml] from the omega_architecture **package** root
/// and appends matching HEAL RECIPE text for the remote AI (reduces duplicate prompt bulk
/// in [bin/omega.dart]).
///
/// Disable: `OMEGA_HEAL_CATALOG=false`
class OmegaHealCatalog {
  OmegaHealCatalog._();

  static const String _relPath = 'tool/omega_heal_catalog.yaml';

  /// Extra user-prompt block: matched recipes sorted by [priority] descending.
  static String promptBlockForErrors(
    List<String> analyzerMachineLines,
    String? omegaPackageRoot,
  ) {
    if (omegaPackageRoot == null || omegaPackageRoot.isEmpty) return '';
    final flag = Platform.environment['OMEGA_HEAL_CATALOG']?.trim().toLowerCase();
    if (flag == 'false' || flag == '0' || flag == 'no') return '';

    final sep = Platform.pathSeparator;
    final f = File('$omegaPackageRoot$sep${_relPath.replaceAll('/', sep)}');
    if (!f.existsSync()) return '';

    final List<_HealRule> rules;
    try {
      rules = _parseCatalog(f.readAsStringSync());
    } catch (_) {
      return '';
    }
    if (rules.isEmpty) return '';

    final matched = <_HealRule>[];
    final seen = <String>{};
    for (final line in analyzerMachineLines) {
      final lower = line.toLowerCase();
      for (final r in rules) {
        if (r.matches(lower) && seen.add(r.id)) {
          matched.add(r);
        }
      }
    }
    if (matched.isEmpty) return '';

    matched.sort((a, b) => b.priority.compareTo(a.priority));

    final buf = StringBuffer();
    buf.writeln('');
    buf.writeln(
      'HEAL — KNOWLEDGE BASE (tool/omega_heal_catalog.yaml — ${matched.length} recipe(s) matched; apply before inventing APIs):',
    );
    for (final r in matched) {
      buf.writeln('');
      buf.writeln('--- catalog: ${r.id} (priority ${r.priority}) ---');
      buf.writeln(r.body.trim());
    }
    buf.writeln('');
    return buf.toString();
  }

  static List<String> _stringList(Object? y) {
    if (y is YamlList) {
      return y.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  static List<_HealRule> _parseCatalog(String yamlText) {
    final loaded = loadYaml(yamlText);
    if (loaded is! YamlMap) return [];
    final recipes = loaded['recipes'];
    if (recipes is! YamlList) return [];
    final out = <_HealRule>[];
    for (final raw in recipes) {
      if (raw is! YamlMap) continue;
      final id = raw['id']?.toString();
      final body = raw['body']?.toString();
      if (id == null || id.isEmpty || body == null || body.isEmpty) continue;
      final priority = int.tryParse(raw['priority']?.toString() ?? '') ?? 0;
      final groups = <_MatchGroup>[];
      final mg = raw['match_groups'];
      if (mg is YamlList) {
        for (final g in mg) {
          if (g is YamlMap) {
            groups.add(_MatchGroup(_stringList(g['all_of']), _stringList(g['any_of'])));
          }
        }
      } else {
        final allOf = raw['all_of'];
        final anyOf = raw['any_of'];
        if (allOf is YamlList || anyOf is YamlList) {
          groups.add(_MatchGroup(_stringList(allOf), _stringList(anyOf)));
        }
      }
      if (groups.isEmpty) continue;
      out.add(_HealRule(id: id, priority: priority, groups: groups, body: body));
    }
    return out;
  }
}

class _MatchGroup {
  _MatchGroup(this.allOf, this.anyOf);

  final List<String> allOf;
  final List<String> anyOf;

  bool matches(String errorLower) {
    for (final a in allOf) {
      if (!errorLower.contains(a.toLowerCase())) return false;
    }
    if (anyOf.isEmpty) return true;
    return anyOf.any((a) => errorLower.contains(a.toLowerCase()));
  }
}

class _HealRule {
  _HealRule({
    required this.id,
    required this.priority,
    required this.groups,
    required this.body,
  });

  final String id;
  final int priority;
  final List<_MatchGroup> groups;
  final String body;

  bool matches(String errorLower) => groups.any((g) => g.matches(errorLower));
}
