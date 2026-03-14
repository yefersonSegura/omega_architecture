// Stub: no-op on web (dart:io not available). Use omega_inspector_server_io.dart on VM/io.

import 'package:flutter/foundation.dart';

import '../../core/channel/omega_channel.dart';
import '../../flows/omega_flow_manager.dart';

/// Server that exposes Omega state (events + flow snapshots) over HTTP/WebSocket
/// so you can open the Inspector in a browser tab (e.g. http://localhost:9292).
///
/// On **web** this class does nothing ([start] returns null; no HTTP server).
/// Use [OmegaInspectorLauncher] on web to open the Inspector in a separate window.
/// On **mobile/desktop** the conditional export selects the IO implementation.
class OmegaInspectorServer {
  /// Starts the server if on a platform that supports dart:io (desktop, mobile).
  /// On web, this is a no-op and returns null. Only run in **debug mode** (e.g. `kDebugMode`).
  ///
  /// [channel] and [flowManager] are used to stream events and snapshots to
  /// connected browser clients. [port] defaults to 9292; use 0 for any free port.
  /// Returns the port actually bound, or null if server was not started (e.g. on web).
  static Future<int?> start(
    OmegaChannel channel,
    OmegaFlowManager flowManager, {
    int port = 9292,
  }) async {
    if (kDebugMode) {
      debugPrint(
        'Omega Inspector Server: not available on web. '
        'Use OmegaInspectorLauncher to open the Inspector in a new window.',
      );
    }
    return null;
  }

  /// Stops the server if it is running. No-op on web.
  static void stop() {}
}
