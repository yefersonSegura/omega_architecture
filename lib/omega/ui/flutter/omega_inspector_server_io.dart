// IO implementation: HTTP + WebSocket server for Inspector (desktop/mobile). Not used on web.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/channel/omega_channel.dart';
import '../../core/events/omega_event.dart';
import '../../core/semantics/omega_intent.dart';
import '../../flows/omega_flow_manager.dart';

const int _kDefaultEventLimit = 30;
const Duration _kSnapshotInterval = Duration(seconds: 2);

/// Server that exposes Omega state over HTTP/WebSocket so the Inspector
/// can be opened in a browser tab (e.g. http://localhost:9292).
class OmegaInspectorServer {
  static HttpServer? _server;
  static final List<WebSocket> _sockets = [];
  static StreamSubscription<OmegaEvent>? _eventSub;
  static Timer? _snapshotTimer;
  static OmegaFlowManager? _flowManager;
  static final List<Map<String, dynamic>> _recentEvents = [];
  static const int _eventLimit = _kDefaultEventLimit;

  static Future<int?> start(
    OmegaChannel channel,
    OmegaFlowManager flowManager, {
    int port = 9292,
  }) async {
    if (!kDebugMode) return null;
    if (_server != null) return _server!.port;
    _flowManager = flowManager;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException catch (e) {
      debugPrint('Omega Inspector Server: could not bind port $port: $e');
      return null;
    }

    final boundPort = _server!.port;
    _server!.listen(_onRequest);

    _eventSub = channel.events.listen((e) {
      final json = _eventToEncodableMap(e);
      _recentEvents.insert(0, json);
      while (_recentEvents.length > _eventLimit) {
        _recentEvents.removeLast();
      }
      _broadcast({'type': 'event', 'data': json});
    });

    _snapshotTimer = Timer.periodic(_kSnapshotInterval, (_) => _sendSnapshot());

    debugPrint('Omega Inspector: http://localhost:$boundPort');

    return boundPort;
  }

  static void stop() {
    _eventSub?.cancel();
    _eventSub = null;
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    for (final ws in _sockets) {
      try {
        ws.close();
      } catch (_) {}
    }
    _sockets.clear();
    _server?.close(force: true);
    _server = null;
    _flowManager = null;
    _recentEvents.clear();
  }

  static void _sendSnapshot() {
    final fm = _flowManager;
    if (fm == null) return;
    try {
      final snapshot = fm.getAppSnapshot();
      _broadcast({'type': 'snapshot', 'data': snapshot.toJson()});
    } catch (_) {}
  }

  /// Converts [event] to a map safe for jsonEncode (payload may be OmegaIntent or other objects).
  static Map<String, dynamic> _eventToEncodableMap(OmegaEvent event) {
    final payload = event.payload;
    final Object? safePayload;
    if (payload == null) {
      safePayload = null;
    } else if (payload is OmegaIntent) {
      safePayload = <String, dynamic>{
        'id': payload.id,
        'name': payload.name,
        if (payload.namespace != null) 'namespace': payload.namespace,
        'payload': _toEncodableValue(payload.payload),
      };
    } else {
      safePayload = _toEncodableValue(payload);
    }
    return <String, dynamic>{
      'id': event.id,
      'name': event.name,
      if (safePayload != null) 'payload': safePayload,
      if (event.namespace != null) 'namespace': event.namespace,
      if (event.meta.isNotEmpty) 'meta': Map<String, dynamic>.from(event.meta),
    };
  }

  static Object? _toEncodableValue(dynamic value) {
    if (value == null) return null;
    if (value is num || value is bool || value is String) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toEncodableValue(v)));
    }
    if (value is List) return value.map(_toEncodableValue).toList();
    return value.toString();
  }

  static void _broadcast(Map<String, dynamic> message) {
    final s = jsonEncode(message);
    for (final ws in List<WebSocket>.from(_sockets)) {
      try {
        ws.add(s);
      } catch (_) {
        _sockets.remove(ws);
      }
    }
  }

  static void _onRequest(HttpRequest request) {
    if (request.uri.path == '/' || request.uri.path.isEmpty) {
      request.response
        ..headers.contentType = ContentType.html
        ..write(_kInspectorHtml)
        ..close();
      return;
    }
    if (request.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocketTransformer.upgrade(request).then((ws) {
        _sockets.add(ws);
        ws.listen(
          null,
          onDone: () => _sockets.remove(ws),
          onError: (_) => _sockets.remove(ws),
        );
        _sendSnapshot();
        if (_recentEvents.isNotEmpty) {
          ws.add(jsonEncode({'type': 'events_batch', 'data': _recentEvents}));
        }
      });
      return;
    }
    request.response.statusCode = 404;
    request.response.close();
  }

  static const String _kInspectorHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Omega Inspector</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; background: #f3f4f8; color: #1f2937; }
    .header { background: #1743b3; color: #fff; padding: 10px 14px; display: flex; align-items: center; gap: 10px; }
    .header h1 { margin: 0; font-size: 15px; font-weight: 700; }
    .badge { background: rgba(255,255,255,0.2); padding: 4px 8px; border-radius: 6px; font-size: 11px; }
    .badge.connected { background: #22c55e; }
    .badge.disconnected { background: #ef4444; }
    .layout { display: flex; height: calc(100vh - 42px); }
    .panel { overflow: auto; padding: 12px; }
    .panel.events { flex: 2; background: #fff; border-right: 1px solid #e5e7eb; }
    .panel.flows { flex: 3; background: #fafafc; }
    .section-title { font-size: 12px; font-weight: 700; color: #6b7280; margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.05em; }
    .event { background: #fafafc; border-left: 4px solid #2962ff; padding: 8px 10px; margin-bottom: 6px; border-radius: 6px; font-size: 12px; }
    .event .name { font-weight: 600; color: #1f2937; }
    .event .time { font-size: 10px; color: #9ca3af; margin-left: 8px; }
    .flow-row { display: flex; align-items: center; padding: 8px 10px; margin-bottom: 4px; background: #fff; border-radius: 8px; border: 1px solid #e5e7eb; font-size: 12px; }
    .flow-row.active { border-color: #2962ff; background: #eff6ff; }
    .flow-id { font-weight: 600; color: #1f2937; min-width: 120px; }
    .flow-state { color: #6b7280; margin-left: 12px; }
    .flow-expr { color: #2962ff; margin-left: 8px; font-size: 11px; }
    .empty { color: #9ca3af; font-size: 12px; padding: 16px 0; }
  </style>
</head>
<body>
  <div class="header">
    <h1>Omega Inspector</h1>
    <span id="status" class="badge disconnected">Connecting...</span>
  </div>
  <div class="layout">
    <div class="panel events">
      <div class="section-title">Events</div>
      <div id="events"></div>
    </div>
    <div class="panel flows">
      <div class="section-title">Flows</div>
      <div id="flows"></div>
    </div>
  </div>
  <script>
    const eventsEl = document.getElementById('events');
    const flowsEl = document.getElementById('flows');
    const statusEl = document.getElementById('status');
    let events = [];
    let snapshot = null;

    function connect() {
      const ws = new WebSocket('ws://' + location.host + '/ws');
      ws.onopen = () => {
        statusEl.textContent = 'Connected';
        statusEl.className = 'badge connected';
      };
      ws.onclose = () => {
        statusEl.textContent = 'Disconnected';
        statusEl.className = 'badge disconnected';
        setTimeout(connect, 2000);
      };
      ws.onerror = () => {};
      ws.onmessage = (e) => {
        try {
          const msg = JSON.parse(e.data);
          if (msg.type === 'event') {
            events.unshift({ ...msg.data, _ts: new Date().toISOString().substr(11, 8) });
            if (events.length > 30) events.pop();
            renderEvents();
          } else if (msg.type === 'events_batch') {
            events = (msg.data || []).map(d => ({ ...d, _ts: '' }));
            renderEvents();
          } else if (msg.type === 'snapshot') {
            snapshot = msg.data;
            renderFlows();
          }
        } catch (err) {}
      };
    }

    function renderEvents() {
      if (events.length === 0) {
        eventsEl.innerHTML = '<div class="empty">No events yet</div>';
        return;
      }
      eventsEl.innerHTML = events.slice(0, 25).map(e => 
        '<div class="event"><span class="name">' + (e.name || '') + '</span><span class="time">' + (e._ts || '') + '</span></div>'
      ).join('');
    }

    function renderFlows() {
      if (!snapshot || !snapshot.flows || snapshot.flows.length === 0) {
        flowsEl.innerHTML = '<div class="empty">No flows</div>';
        return;
      }
      const active = snapshot.activeFlowId || '';
      flowsEl.innerHTML = snapshot.flows.map(f => 
        '<div class="flow-row ' + (f.flowId === active ? 'active' : '') + '">' +
        '<span class="flow-id">' + (f.flowId || '') + '</span>' +
        '<span class="flow-state">' + (f.state || '') + '</span>' +
        '<span class="flow-expr">' + (f.lastExpressionType || '') + '</span></div>'
      ).join('');
    }

    connect();
  </script>
</body>
</html>
''';
}
