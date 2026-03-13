// lib/omega/ui/flutter/omega_inspector.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/events/omega_event.dart';
import '../../flows/omega_flow_snapshot.dart';
import '../../flows/omega_flow_state.dart';
import 'omega_scope.dart';

/// Default number of recent events shown by the inspector.
const int kOmegaInspectorDefaultEventLimit = 30;

// Inspector visual theme (modern, high contrast).
const Color _kInspectorPrimary = Color(0xFF1565C0);
const Color _kInspectorPrimaryDark = Color(0xFF0D47A1);
const Color _kInspectorSurface = Color(0xFFF5F7FA);
const Color _kInspectorCard = Color(0xFFFFFFFF);
const Color _kInspectorText = Color(0xFF1A237E);
const Color _kInspectorTextMuted = Color(0xFF546E7A);
const double _kInspectorRadius = 16.0;
const double _kCardRadius = 12.0;

/// Minimal inspection panel for Omega: recent channel events and flow state.
///
/// Uses [OmegaScope.of](context) to get the channel and flow manager. Shows the last
/// [eventLimit] emitted events and a snapshot of all flows (id, state, last expression).
/// Intended for **debug mode**; in release you can hide it with [kDebugMode].
///
/// Example:
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
  /// Maximum recent events to show (default [kOmegaInspectorDefaultEventLimit]).
  final int eventLimit;

  /// If true, the panel is shown collapsed (only a button to expand).
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
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        shadowColor: _kInspectorPrimary.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () => setState(() => _collapsed = false),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kInspectorPrimary, _kInspectorPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insights, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Omega Inspector', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(_kInspectorRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kInspectorRadius),
        child: Container(
          width: 620,
          height: 480,
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 480),
          decoration: const BoxDecoration(color: _kInspectorSurface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const Divider(height: 1, color: Color(0xFFE0E4F0)),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: events and timeline
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.black.withValues(alpha: 0.06),
                              width: 1,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: _buildEventsSection(),
                        ),
                      ),
                    ),
                    // Right: flows / state
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: _buildFlowsSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kInspectorPrimary, _kInspectorPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.insights, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Omega Inspector',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _refreshSnapshot,
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15)),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            onPressed: () => setState(() => _collapsed = true),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kInspectorText, letterSpacing: 0.2)),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _kInspectorPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kInspectorPrimary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Events', '${_events.length}'),
        if (_events.isEmpty)
          _emptyState('No events yet')
        else ...[
          _buildTimelineRow(),
          const SizedBox(height: 8),
          ..._events.take(15).map((e) => _eventTile(e)),
        ],
      ],
    );
  }

  Widget _emptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontSize: 12, color: _kInspectorTextMuted)),
    );
  }

  Widget _eventTile(_EventEntry e) {
    final hasPayload = e.event.payload != null;
    final payloadStr = hasPayload ? _payloadSummary(e.event.payload) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _kInspectorCard,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(color: _kInspectorPrimary.withValues(alpha: 0.5)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _kInspectorSurface, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              e.time.toString().substring(11, 19),
                              style: const TextStyle(fontSize: 10, color: _kInspectorTextMuted, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.event.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kInspectorText, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (payloadStr != null && payloadStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          payloadStr,
                          style: const TextStyle(fontSize: 10, color: _kInspectorTextMuted, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowsSection() {
    final snap = _snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Flows', snap != null && snap.activeFlowId != null ? 'active: ${snap.activeFlowId}' : null),
        if (snap == null || snap.flows.isEmpty)
          _emptyState('None registered')
        else
          ...snap.flows.map((f) => _flowTile(f)),
      ],
    );
  }

  Widget _flowTile(OmegaFlowSnapshot f) {
    final stateLabel = _stateLabel(f.state);
    final stateColor = _stateColor(f.state);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kInspectorCard,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(color: stateColor),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              f.flowId,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kInspectorText),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: stateColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(stateLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: stateColor)),
                          ),
                        ],
                      ),
                      if (f.lastExpression != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Última expresión: ${f.lastExpression!.type}',
                          style: const TextStyle(fontSize: 11, color: _kInspectorTextMuted),
                        ),
                      ],
                      if (f.memory.isNotEmpty)
                        Text('memory: ${f.memory.length} keys', style: const TextStyle(fontSize: 10, color: _kInspectorTextMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  /// Simple horizontal timeline of recent events (most recent on the right).
  Widget _buildTimelineRow() {
    if (_events.isEmpty) return const SizedBox.shrink();
    final items = _events.take(20).toList().reversed.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final e in items) ...[
            Tooltip(
              message: '${e.time.toIso8601String()}\n${e.event.name}',
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kInspectorPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventEntry {
  final OmegaEvent event;
  final DateTime time;

  _EventEntry(this.event, this.time);
}
