// IO implementation: HTTP + WebSocket server for Inspector (desktop/mobile). Not used on web.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/channel/omega_channel.dart';
import '../../core/events/omega_event.dart';
import '../../core/semantics/omega_intent.dart';
import '../../flows/omega_flow_manager.dart';

const int _kDefaultEventLimit = 30;
const Duration _kSnapshotInterval = Duration(seconds: 2);

/// Static Inspector UI (same markup as `docs/public/inspector.html`), hosted for VM Service links.
const String kOmegaInspectorPublicPageUrl =
    'https://yefersonsegura.com/projects/omega/inspector.html';

/// Extension method name for VM Service (mobile Inspector without adb reverse).
const String _kExtGetState = 'ext.omega.inspector.getState';

/// Server that exposes Omega state over HTTP/WebSocket so the Inspector
/// can be opened in a browser tab (e.g. http://localhost:9292).
/// On mobile, uses the VM Service extension so the PC can connect without adb reverse.
class OmegaInspectorServer {
  static HttpServer? _server;
  static final List<WebSocket> _sockets = [];
  static StreamSubscription<OmegaEvent>? _eventSub;
  static Timer? _snapshotTimer;
  static OmegaFlowManager? _flowManager;
  static final List<Map<String, dynamic>> _recentEvents = [];
  static Map<String, dynamic> _cachedSnapshot = const {};
  static const int _eventLimit = _kDefaultEventLimit;

  // Deprecated: constant kept for backward compatibility with older code; currently unused.
  // ignore: unused_field
  static const int _kMaxPortTry = 9302;

  static Future<int?> start(
    OmegaChannel channel,
    OmegaFlowManager flowManager, {
    int port = 9292,
    bool openBrowser = true,
  }) async {
    if (!kDebugMode) return null;
    _flowManager = flowManager;

    final isMobile = Platform.isAndroid || Platform.isIOS;

    // Shared: keep events and snapshot updated for both HTTP server and VM extension.
    _eventSub?.cancel();
    _eventSub = channel.events.listen((e) {
      final json = _eventToEncodableMap(e);
      _recentEvents.insert(0, json);
      while (_recentEvents.length > _eventLimit) {
        _recentEvents.removeLast();
      }
      _broadcast({'type': 'event', 'data': json});
    });
    _cachedSnapshot = const {};
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(_kSnapshotInterval, (_) {
      final fm = _flowManager;
      if (fm != null) {
        try {
          _cachedSnapshot = fm.getAppSnapshot().toJson();
        } catch (_) {}
      }
      _sendSnapshot();
    });

    // VM platforms (mobile + desktop): use VM Service + public web inspector.
    // No local HTTP server; everything goes through [kOmegaInspectorPublicPageUrl].
    if (_server != null) {
      _server!.close(force: true);
      _server = null;
      _sockets.clear();
    }
    _registerVmExtension();
    final vmUri = await _vmServiceUri();
    if (vmUri != null && vmUri.isNotEmpty) {
      final hash = Uri.encodeComponent(vmUri);
      final publicUrl = '$kOmegaInspectorPublicPageUrl#$hash';
      debugPrint(
        'Omega Inspector [vm] — Open in your browser (no adb reverse needed):',
      );
      debugPrint('  $publicUrl');
      debugPrint('  (The page will auto-connect using that VM Service URL.)');
      debugPrint(
        '  If needed, you can also paste this VM Service URL manually:',
      );
      debugPrint('  $vmUri');
      if (openBrowser && !isMobile) {
        // On desktop we can open the browser automatically.
        _openBrowser(publicUrl);
      }
    } else {
      debugPrint(
        'Omega Inspector [vm] — VM Service URI not available. Use the in-app overlay or launcher.',
      );
    }
    return 0; // No port; Inspector is via VM Service + public web.
  }

  static void _registerVmExtension() {
    try {
      developer.registerExtension(_kExtGetState, (
        String method,
        Map<String, String>? params,
      ) async {
        return developer.ServiceExtensionResponse.result(
          jsonEncode(<String, dynamic>{
            'events': List<Map<String, dynamic>>.from(_recentEvents),
            'snapshot': Map<String, dynamic>.from(_cachedSnapshot),
          }),
        );
      });
    } catch (_) {}
  }

  /// Returns the VM Service HTTP URI (e.g. http://127.0.0.1:38473/abc=/) so the PC can open the Inspector.
  /// Flutter already forwards this port when running on a device.
  static Future<String?> _vmServiceUri() async {
    try {
      final info = await developer.Service.getInfo();
      final uri = info.serverUri;
      return uri?.toString();
    } catch (_) {}
    return null;
  }

  /// Opens the Inspector URL in the default browser (desktop only). On mobile, open the printed URL on your PC.
  static void _openBrowser(String url) {
    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      try {
        final uri = Uri.parse(url);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          debugPrint('Omega Inspector: open manually: $url');
        }
      } catch (e) {
        debugPrint('Omega Inspector: open manually: $url ($e)');
      }
    });
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
    _cachedSnapshot = const {};
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

}
