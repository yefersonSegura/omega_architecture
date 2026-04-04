// Web implementation: opens the inspector in a new browser window (Isar-style).
// Uses package:web instead of dart:html (recommended by pub.dev).

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../core/events/omega_event.dart';
import 'omega_scope.dart';

const String _kChannelName = 'omega_inspector';

/// Button that opens the inspector in a **new browser window** and sends data via BroadcastChannel.
class OmegaInspectorLauncher extends StatefulWidget {
  final int eventLimit;

  const OmegaInspectorLauncher({super.key, this.eventLimit = 30});

  @override
  State<OmegaInspectorLauncher> createState() => _OmegaInspectorLauncherWebState();
}

class _OmegaInspectorLauncherWebState extends State<OmegaInspectorLauncher> {
  StreamSubscription<OmegaEvent>? _sub;
  Timer? _timer;
  final List<Map<String, dynamic>> _events = [];
  bool _sending = false;

  void _openWindow() {
    if (_sending) return;
    final loc = web.window.location;
    final base = '${loc.origin}${loc.pathname}${loc.search}';
    final sep = base.contains('?') ? '&' : '?';
    final url = '$base${sep}omega_inspector=1';
    // Unique name each time so if the user closed the previous window the browser
    // opens a new one instead of reusing a dead window reference.
    final windowName = 'omega_inspector_${DateTime.now().millisecondsSinceEpoch}';
    web.window.open(url, windowName, 'width=400,height=500');
    _sending = true;
    _sendOnce();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _sendOnce());
  }

  void _sendOnce() {
    if (!mounted) return;
    try {
      final scope = OmegaScope.of(context);
      final snapshot = scope.flowManager.getAppSnapshot();
      final payload = <String, dynamic>{
        'events': List<Map<String, dynamic>>.from(_events),
        'activeFlowId': snapshot.activeFlowId,
        'flows': snapshot.flows.map((f) {
          return <String, dynamic>{
            'flowId': f.flowId,
            'state': f.state.name,
            'memoryKeys': f.memory.length,
            'lastExpressionType': f.lastExpression?.type,
            'lastExpressionPayload': f.lastExpression?.payload?.toString(),
          };
        }).toList(),
      };
      final channel = web.BroadcastChannel(_kChannelName);
      channel.postMessage(jsonEncode(payload).toJS);
      channel.close();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    if (!kDebugMode) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = OmegaScope.of(context);
      _sub = scope.channel.events.listen((e) {
        if (!mounted) return;
        setState(() {
          _events.insert(0, {
            'name': e.name,
            'payload': e.payload?.toString() ?? '',
            'time': DateTime.now().toIso8601String(),
          });
          while (_events.length > widget.eventLimit) {
            _events.removeLast();
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Open Omega Inspector in a new window',
      onPressed: _openWindow,
    );
  }
}
