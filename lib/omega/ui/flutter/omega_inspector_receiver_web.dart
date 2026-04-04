// Web implementation: receives data from the main window via BroadcastChannel and shows the inspector.
// Uses package:web instead of dart:html (recommended by pub.dev).
// Same visual theme as OmegaInspector (overlay) for consistency.

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const String _kChannelName = 'omega_inspector';

// Visual theme: aligned with presentation/inspector.html (dark dashboard).
const Color _kInspectorBg = Color(0xFF020617);
const Color _kInspectorBgSoft = Color(0xFF0F172A);
const Color _kInspectorHeaderDark = Color(0xFF020617);
const Color _kInspectorHeaderDark2 = Color(0xFF0B1120);
const Color _kInspectorAccent = Color(0xFF38BDF8);
const Color _kInspectorAccent2 = Color(0xFF6366F1);
const Color _kInspectorText = Color(0xFFE5E7EB);
const Color _kInspectorTextMuted = Color(0xFF9CA3AF);
const double _kCardRadius = 14.0;

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
  int? _selectedEventIndex;
  String? _selectedFlowId;

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
    if (!kDebugMode) return;
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
    if (!kDebugMode) {
      return Material(
        child: Center(
          child: Text(
            'Inspector is only available in debug mode.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [Color(0xFF1F2937), _kInspectorBg],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (_error.isNotEmpty) _buildErrorBanner(),
            Expanded(
              child: Row(
                children: [
                  _buildSidebar(),
                  Expanded(child: _buildMainPanels()),
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
        gradient: LinearGradient(
          colors: [_kInspectorHeaderDark, _kInspectorHeaderDark2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF94A3B8), width: 0.6),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [_kInspectorAccent, _kInspectorAccent2, Color(0xFFA855F7), _kInspectorAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kInspectorAccent.withValues(alpha: 0.6),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kInspectorBg,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Omega Inspector',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Flows · Events · Web bridge',
                    style: TextStyle(
                      color: _kInspectorTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isConnected = _events.isNotEmpty || _flows.isNotEmpty;
    final dotColor = isConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isConnected ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
          width: 0.7,
        ),
        gradient: LinearGradient(
          colors: isConnected
              ? [const Color(0xFF16A34A).withValues(alpha: 0.2), _kInspectorHeaderDark2]
              : [const Color(0xFF991B1B).withValues(alpha: 0.2), _kInspectorHeaderDark2],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.7),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Connected' : 'Waiting...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              letterSpacing: 0.06,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade500.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade200),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error,
              style: TextStyle(color: Colors.red.shade100, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
        ),
        border: Border(
          right: BorderSide(color: Color(0xFF111827), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flows',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kInspectorTextMuted,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _flows.isEmpty
                ? const Center(
                    child: Text(
                      'No flows',
                      style: TextStyle(fontSize: 12, color: _kInspectorTextMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: _flows.length,
                    itemBuilder: (context, index) {
                      final f = _flows[index];
                      return _flowTile(f);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPanels() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          if (isNarrow) {
            return Column(
              children: [
                Expanded(child: _buildEventsCard()),
                const SizedBox(height: 12),
                SizedBox(height: 200, child: _buildDetailsCard()),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: _buildEventsCard()),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _buildDetailsCard()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kInspectorTextMuted,
              letterSpacing: 0.06,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _kInspectorAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kInspectorAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventsCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: const Color(0xFF111827)),
        gradient: const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [Color(0xFF1F2937), _kInspectorBgSoft],
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Events', '${_events.length}'),
              Text(
                _events.isEmpty
                    ? 'No events'
                    : '${_events.length == 1 ? "1 event" : "${_events.length} events"}',
                style: const TextStyle(fontSize: 11, color: _kInspectorTextMuted),
              ),
            ],
          ),
          if (_events.isEmpty) _emptyState('Waiting for channel data…') else _buildTimelineRow(),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              itemCount: _events.length.clamp(0, 25),
              itemBuilder: (context, index) => _eventTile(_events[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: _kInspectorTextMuted),
      ),
    );
  }

  Widget _eventTile(Map<String, dynamic> e, int index) {
    final name = e['name'] as String? ?? '';
    final timeStr = _formatTime(e['time'] as String?);
    final ns = e['namespace'] as String?;
    final isSelected = _selectedEventIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? _kInspectorBgSoft : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(
          color: isSelected ? _kInspectorAccent.withValues(alpha: 0.8) : const Color(0xFF1F2937),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(_kCardRadius),
        onTap: () {
          setState(() {
            _selectedEventIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF020617),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _kInspectorTextMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kInspectorText,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (ns != null && ns.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  ns,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF93C5FD)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final Map<String, dynamic>? selectedEvent =
        _selectedEventIndex != null && _selectedEventIndex! >= 0 && _selectedEventIndex! < _events.length
            ? _events[_selectedEventIndex!]
            : null;
    final Map<String, dynamic>? selectedFlow = (_selectedFlowId != null)
        ? _flows.firstWhere(
            (f) => f['flowId'] == _selectedFlowId,
            orElse: () => <String, dynamic>{},
          )
        : null;

    final hasSelection = selectedEvent != null || (selectedFlow != null && selectedFlow.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: const Color(0xFF111827)),
        gradient: const RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [Color(0xFF111827), _kInspectorBgSoft],
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Details', hasSelection ? '' : null),
              Text(
                selectedEvent != null
                    ? 'Event payload'
                    : selectedFlow != null && selectedFlow.isNotEmpty
                        ? 'Flow snapshot'
                        : 'Select an event or flow',
                style: const TextStyle(fontSize: 11, color: _kInspectorTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: hasSelection
                ? SingleChildScrollView(
                    child: Text(
                      const JsonEncoder.withIndent('  ')
                          .convert(selectedEvent ?? selectedFlow),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kInspectorText,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'No selection yet.',
                      style: TextStyle(fontSize: 12, color: _kInspectorTextMuted),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _flowTile(Map<String, dynamic> f) {
    final flowId = f['flowId'] as String? ?? '';
    final stateStr = f['state'] as String? ?? '';
    final stateColor = _colorForState(stateStr);
    final isActive = _activeFlowId == flowId;
    final isSelected = _selectedFlowId == flowId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCardRadius),
        color: isSelected ? _kInspectorBgSoft : const Color(0xFF020617),
        border: Border.all(
          color: isSelected ? _kInspectorAccent2.withValues(alpha: 0.9) : const Color(0xFF1F2937),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(_kCardRadius),
        onTap: () {
          setState(() {
            _selectedFlowId = flowId;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      flowId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _kInspectorText,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stateColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.greenAccent.shade200,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          stateStr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: stateColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (f['lastExpressionType'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Last: ${f['lastExpressionType']}',
                  style: const TextStyle(fontSize: 10, color: _kInspectorTextMuted),
                ),
              ],
              if ((f['memoryKeys'] as int? ?? 0) > 0)
                Text(
                  'Memory: ${f['memoryKeys']} keys',
                  style: const TextStyle(fontSize: 10, color: _kInspectorTextMuted),
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
                  color: _kInspectorAccent.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
