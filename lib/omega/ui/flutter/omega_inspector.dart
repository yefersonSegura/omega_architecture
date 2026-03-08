// lib/omega/ui/flutter/omega_inspector.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/events/omega_event.dart';
import '../../flows/omega_flow_snapshot.dart';
import '../../flows/omega_flow_state.dart';
import 'omega_scope.dart';

/// Número por defecto de eventos recientes que muestra el inspector.
const int kOmegaInspectorDefaultEventLimit = 30;

/// Panel mínimo de inspección para Omega: eventos recientes del canal y estado de los flows.
///
/// Usa [OmegaScope.of](context) para obtener el canal y el flow manager. Muestra los últimos
/// [eventLimit] eventos emitidos y un snapshot de todos los flows (id, estado, última expresión).
/// Pensado para **modo debug**; en release puedes ocultarlo con [kDebugMode].
///
/// Ejemplo:
/// ```dart
/// if (kDebugMode)
///   Stack(
///     children: [
///       child,
///       Positioned(right: 0, top: 0, child: OmegaInspector(eventLimit: 20)),
///     ],
///   )
/// ```
class OmegaInspector extends StatefulWidget {
  /// Máximo de eventos recientes a mostrar (por defecto [kOmegaInspectorDefaultEventLimit]).
  final int eventLimit;

  /// Si true, el panel se muestra colapsado (solo un botón para expandir).
  final bool initiallyCollapsed;

  const OmegaInspector({
    super.key,
    this.eventLimit = kOmegaInspectorDefaultEventLimit,
    this.initiallyCollapsed = true,
  });

  @override
  State<OmegaInspector> createState() => _OmegaInspectorState();
}

class _OmegaInspectorState extends State<OmegaInspector> {
  final List<_EventEntry> _events = [];
  OmegaAppSnapshot? _snapshot;
  StreamSubscription<OmegaEvent>? _subscription;
  Timer? _snapshotTimer;
  bool _collapsed = true;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed;
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    if (!mounted) return;
    final scope = OmegaScope.of(context);
    _subscription = scope.channel.events.listen((e) {
      if (!mounted) return;
      setState(() {
        _events.insert(0, _EventEntry(e, DateTime.now()));
        while (_events.length > widget.eventLimit) {
          _events.removeLast();
        }
      });
    });
    _refreshSnapshot();
    _snapshotTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _refreshSnapshot();
    });
  }

  void _refreshSnapshot() {
    if (!mounted) return;
    final scope = OmegaScope.of(context);
    setState(() {
      _snapshot = scope.flowManager.getAppSnapshot();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _snapshotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_collapsed) {
      return Material(
        elevation: 2,
        child: InkWell(
          onTap: () => setState(() => _collapsed = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bug_report, size: 18, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                const Text('Omega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 8,
      child: Container(
        width: 320,
        height: 400,
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildEventsSection(),
                    const SizedBox(height: 12),
                    _buildFlowsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(child: Text('Omega Inspector', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: _refreshSnapshot,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => setState(() => _collapsed = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eventos (${_events.length})', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (_events.isEmpty)
          const Text('Ninguno aún', style: TextStyle(color: Colors.grey, fontSize: 12))
        else
          ..._events.take(15).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(e.time.toString().substring(11, 19), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.event.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          if (e.event.payload != null)
                            Text(_payloadSummary(e.event.payload), style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildFlowsSection() {
    final snap = _snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Flows${snap != null ? " (active: ${snap.activeFlowId ?? "—"})" : ""}', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (snap == null || snap.flows.isEmpty)
          const Text('Ninguno registrado', style: TextStyle(color: Colors.grey, fontSize: 12))
        else
          ...snap.flows.map((f) => _flowTile(f)),
      ],
    );
  }

  Widget _flowTile(OmegaFlowSnapshot f) {
    final stateLabel = _stateLabel(f.state);
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(f.flowId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: _stateColor(f.state), borderRadius: BorderRadius.circular(4)),
                  child: Text(stateLabel, style: const TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ],
            ),
            if (f.lastExpression != null) ...[
              const SizedBox(height: 4),
              Text('Última expresión: ${f.lastExpression!.type}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
            if (f.memory.isNotEmpty)
              Text('memory: ${f.memory.length} keys', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _stateLabel(OmegaFlowState s) {
    switch (s) {
      case OmegaFlowState.idle:
        return 'idle';
      case OmegaFlowState.running:
        return 'running';
      case OmegaFlowState.sleeping:
        return 'sleeping';
      case OmegaFlowState.paused:
        return 'paused';
      case OmegaFlowState.ended:
        return 'ended';
    }
  }

  Color _stateColor(OmegaFlowState s) {
    switch (s) {
      case OmegaFlowState.running:
        return Colors.green;
      case OmegaFlowState.paused:
        return Colors.orange;
      case OmegaFlowState.ended:
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _payloadSummary(dynamic p) {
    if (p == null) return '';
    final s = p.toString();
    return s.length > 60 ? '${s.substring(0, 60)}…' : s;
  }
}

class _EventEntry {
  final OmegaEvent event;
  final DateTime time;

  _EventEntry(this.event, this.time);
}
