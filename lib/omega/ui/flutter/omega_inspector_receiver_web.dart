// Implementación web: recibe datos del canal principal por BroadcastChannel y muestra el inspector.

import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/material.dart';

const String _kChannelName = 'omega_inspector';

/// En la ventana abierta con ?omega_inspector=1, este widget escucha BroadcastChannel y muestra el inspector.
class OmegaInspectorReceiver extends StatefulWidget {
  const OmegaInspectorReceiver({super.key});

  @override
  State<OmegaInspectorReceiver> createState() => _OmegaInspectorReceiverWebState();
}

class _OmegaInspectorReceiverWebState extends State<OmegaInspectorReceiver> {
  List<Map<String, dynamic>> _events = [];
  String? _activeFlowId;
  List<Map<String, dynamic>> _flows = [];
  html.BroadcastChannel? _channel;
  String _error = '';

  @override
  void initState() {
    super.initState();
    try {
      _channel = html.BroadcastChannel(_kChannelName);
      _channel!.onMessage.listen((event) {
        try {
          final data = jsonDecode(event.data) as Map<String, dynamic>;
          if (!mounted) return;
          setState(() {
            _events = List<Map<String, dynamic>>.from(data['events'] as List<dynamic>? ?? []);
            _activeFlowId = data['activeFlowId'] as String?;
            _flows = List<Map<String, dynamic>>.from(data['flows'] as List<dynamic>? ?? []);
            _error = '';
          });
        } catch (_) {
          if (mounted) setState(() => _error = 'Error al decodificar');
        }
      });
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
        color: Colors.orange.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Omega Inspector (ventana remota)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
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
          const Text('Esperando datos del canal…', style: TextStyle(color: Colors.grey, fontSize: 12))
        else
          ..._events.take(20).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        _formatTime(e['time'] as String?),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['name'] as String? ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text((e['payload'] as String? ?? '').toString(), style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Flows${_activeFlowId != null ? " (activo: $_activeFlowId)" : ""}', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (_flows.isEmpty)
          const Text('Ninguno aún', style: TextStyle(color: Colors.grey, fontSize: 12))
        else
          ..._flows.map((f) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(f['flowId'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _colorForState(f['state'] as String?),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(f['state'] as String? ?? '', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ],
                      ),
                      if (f['lastExpressionType'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Última expresión: ${f['lastExpressionType']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                      if ((f['memoryKeys'] as int? ?? 0) > 0)
                        Text('memory: ${f['memoryKeys']} keys', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              )),
      ],
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
}
