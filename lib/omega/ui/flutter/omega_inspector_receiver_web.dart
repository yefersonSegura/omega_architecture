// Web implementation: receives data from the main window via BroadcastChannel and shows the inspector.
// Uses package:web instead of dart:html (recommended by pub.dev).
// Same visual theme as OmegaInspector (overlay) for consistency.

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const String _kChannelName = 'omega_inspector';

// Visual theme (aligned with omega_inspector.dart).
const Color _kInspectorPrimary = Color(0xFF2962FF);
const Color _kInspectorPrimaryDark = Color(0xFF1743B3);
const Color _kInspectorSurface = Color(0xFFF3F4F8);
const Color _kInspectorCard = Color(0xFFFAFAFC);
const Color _kInspectorText = Color(0xFF1F2937);
const Color _kInspectorTextMuted = Color(0xFF6B7280);
const double _kCardRadius = 10.0;

/// In the window opened with ?omega_inspector=1, this widget listens to BroadcastChannel and displays the inspector.
class OmegaInspectorReceiver extends StatefulWidget {
  const OmegaInspectorReceiver({super.key});

  @override
  State<OmegaInspectorReceiver> createState() => _OmegaInspectorReceiverWebState();
}

class _OmegaInspectorReceiverWebState extends State<OmegaInspectorReceiver> {
  List<Map<String, dynamic>> _events = [];
  String? _activeFlowId;
  List<Map<String, dynamic>> _flows = [];
  web.BroadcastChannel? _channel;
  String _error = '';

  void _onMessage(web.Event e) {
    final me = e as web.MessageEvent;
    final raw = me.data?.dartify();
    try {
      Map<String, dynamic>? data;
      if (raw is String) {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        data = Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v)));
      }
      if (data == null || !mounted) return;
      final events = data['events'] as List<dynamic>? ?? [];
      final activeFlowId = data['activeFlowId'] as String?;
      final flows = data['flows'] as List<dynamic>? ?? [];
      setState(() {
        _events = List<Map<String, dynamic>>.from(events);
        _activeFlowId = activeFlowId;
        _flows = List<Map<String, dynamic>>.from(flows);
        _error = '';
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Error decoding');
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      _channel = web.BroadcastChannel(_kChannelName);
      _channel!.addEventListener('message', ((web.Event e) => _onMessage(e)).toJS);
    } catch (e) {
      _error = e.toString();
    }
  }

  @override
  void dispose() {
    _channel?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: _kInspectorSurface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (_error.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(_kCardRadius),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error, style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
                  ],
                ),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: events
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
                  // Right: flows
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
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _kInspectorPrimaryDark,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              'Omega Inspector (ventana remota)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3),
            ),
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
          _emptyState('Esperando datos del canal…')
        else ...[
          _buildTimelineRow(),
          const SizedBox(height: 8),
          ..._events.take(20).map((e) => _eventTile(e)),
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

  Widget _eventTile(Map<String, dynamic> e) {
    final name = e['name'] as String? ?? '';
    final timeStr = _formatTime(e['time'] as String?);
    final payload = (e['payload'] as String? ?? '').toString();
    final hasPayload = payload.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _kInspectorCard,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
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
                            child: Text(timeStr, style: const TextStyle(fontSize: 10, color: _kInspectorTextMuted, fontFamily: 'monospace')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kInspectorText, fontFamily: 'monospace'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (hasPayload) ...[
                        const SizedBox(height: 6),
                        Text(
                          payload,
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
    final subtitle = _activeFlowId != null ? 'activo: $_activeFlowId' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Flows', subtitle),
        if (_flows.isEmpty)
          _emptyState('None yet')
        else
          ..._flows.map((f) => _flowTile(f)),
      ],
    );
  }

  Widget _flowTile(Map<String, dynamic> f) {
    final flowId = f['flowId'] as String? ?? '';
    final stateStr = f['state'] as String? ?? '';
    final stateColor = _colorForState(stateStr);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kInspectorCard,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
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
                              flowId,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kInspectorText),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: stateColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(stateStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: stateColor)),
                          ),
                        ],
                      ),
                      if (f['lastExpressionType'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Last expression: ${f['lastExpressionType']}',
                          style: const TextStyle(fontSize: 11, color: _kInspectorTextMuted),
                        ),
                      ],
                      if ((f['memoryKeys'] as int? ?? 0) > 0)
                        Text('memory: ${f['memoryKeys']} keys', style: const TextStyle(fontSize: 10, color: _kInspectorTextMuted)),
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

  String _formatTime(String? iso) {
    if (iso == null || iso.length < 19) return '';
    return iso.substring(11, 19);
  }

  Color _colorForState(String? s) {
    switch (s) {
      case 'running':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  /// Horizontal timeline of recent events (most recent on the right).
  Widget _buildTimelineRow() {
    if (_events.isEmpty) return const SizedBox.shrink();
    final items = _events.take(30).toList().reversed.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final e in items) ...[
            Tooltip(
              message: '${_formatTime(e['time'] as String?)}\n${e['name'] ?? ''}',
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
