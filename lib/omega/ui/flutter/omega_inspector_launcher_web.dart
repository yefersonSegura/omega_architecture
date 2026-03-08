// Implementación web: abre el inspector en una nueva ventana del navegador (estilo Isar).
// Usa package:web en lugar de dart:html (recomendado por pub.dev).

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../core/events/omega_event.dart';
import 'omega_scope.dart';

const String _kChannelName = 'omega_inspector';

/// Botón que abre el inspector en una **nueva ventana** del navegador y envía datos por BroadcastChannel.
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
    web.window.open(url, 'omega_inspector', 'width=400,height=500');
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
    return IconButton(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Abrir Omega Inspector en nueva ventana',
      onPressed: _openWindow,
    );
  }
}
