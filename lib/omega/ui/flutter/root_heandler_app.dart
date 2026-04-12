import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omega_architecture/omega/core/channel/omega_channel.dart';
import 'package:omega_architecture/omega/flows/omega_flow_manager.dart';
import 'package:omega_architecture/omega/time_travel/omega_recorded_session.dart';
import 'package:omega_architecture/omega/time_travel/omega_time_travel_recorder.dart';

import 'omega_flow_activator.dart';
import 'omega_inspector_launcher.dart';
import 'omega_scope.dart';

/// Shell under [MaterialApp] (after [OmegaInitialRoute]): activates [OmegaScope.initialFlowId]
/// with [OmegaFlowActivator].
///
/// By default ([wrapWithScaffold] `true`) builds a [Scaffold] with an optional debug [AppBar]
/// (docs, time-travel, [OmegaInspectorLauncher] on web when [showInspector]).
/// Set [wrapWithScaffold] to `false` when each route supplies its own [Scaffold] (avoids nested
/// scaffolds and duplicate app bars).
///
/// Must be a descendant of [OmegaScope].
class RootHandler extends StatefulWidget {
  const RootHandler({
    super.key,
    this.appTitle,
    this.showInspector = false,
    this.wrapWithScaffold = true,
    this.child,
  });

  /// AppBar title in debug mode (only if [wrapWithScaffold]).
  final String? appTitle;

  /// When `true` and [kDebugMode], shows [OmegaInspectorLauncher] on web in the AppBar.
  final bool showInspector;

  /// When `true` (default), wraps [child] in a [Scaffold] with optional debug [AppBar].
  /// When `false`, only [child] (or a minimal placeholder) is wrapped in [OmegaFlowActivator] —
  /// use when pushed routes own the [Scaffold].
  final bool wrapWithScaffold;

  /// Replaces the default `"Omega Running"` body / root when there is no route yet.
  final Widget? child;

  @override
  State<RootHandler> createState() => _RootHandlerState();
}

class _RootHandlerState extends State<RootHandler> {
  @override
  Widget build(BuildContext context) {
    final scope = OmegaScope.of(context);
    final initialId = scope.initialFlowId;

    final Widget inner =
        widget.child ?? const Center(child: Text('Omega Running'));

    Widget shell = widget.wrapWithScaffold
        ? Scaffold(
            appBar: kDebugMode
                ? AppBar(
                    title: Text(widget.appTitle ?? 'Omega Example'),
                    actions: [
                      const _DocsLink(),
                      const _TimeTravelButton(),
                      if (kIsWeb && widget.showInspector)
                        const OmegaInspectorLauncher(),
                    ],
                  )
                : null,
            body: inner,
          )
        : inner;

    if (initialId != null) {
      shell = OmegaFlowActivator(
        flowId: initialId,
        useSwitchTo: true,
        child: shell,
      );
    }

    return shell;
  }
}

/// Button that shows the documentation link (web doc or run `omega doc`).
class _DocsLink extends StatelessWidget {
  const _DocsLink();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_book),
      tooltip: 'Documentación',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Documentación web: yefersonsegura.com/proyects/omega/ · O ejecuta: omega doc',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      },
    );
  }
}

/// Button that opens the Time-travel panel (record & replay session).
class _TimeTravelButton extends StatelessWidget {
  const _TimeTravelButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.history),
      tooltip: 'Time-travel (grabar / reproducir)',
      onPressed: () {
        final scope = OmegaScope.of(context);
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.85,
            expand: false,
            builder: (_, scrollController) => _TimeTravelPanel(
              channel: scope.channel,
              flowManager: scope.flowManager,
              scrollController: scrollController,
            ),
          ),
        );
      },
    );
  }
}

/// Panel to record a session and replay up to a step (time-travel).
class _TimeTravelPanel extends StatefulWidget {
  const _TimeTravelPanel({
    required this.channel,
    required this.flowManager,
    required this.scrollController,
  });

  final OmegaChannel channel;
  final OmegaFlowManager flowManager;
  final ScrollController scrollController;

  @override
  State<_TimeTravelPanel> createState() => _TimeTravelPanelState();
}

class _TimeTravelPanelState extends State<_TimeTravelPanel> {
  final OmegaTimeTravelRecorder _recorder = OmegaTimeTravelRecorder();
  OmegaRecordedSession? _session;
  int _replayStep = 0;

  @override
  void dispose() {
    if (_recorder.isRecording) {
      _recorder.stopRecording();
    }
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _recorder.startRecording(widget.channel, widget.flowManager);
    });
  }

  void _stopRecording() {
    setState(() {
      final s = _recorder.stopRecording();
      _session = s.events.isEmpty ? null : s;
      _replayStep = 0;
    });
  }

  void _replayToStep() {
    if (_session == null || _session!.events.isEmpty) return;
    _recorder.replay(
      _session!,
      widget.channel,
      widget.flowManager,
      upToIndex: _replayStep,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Replay hasta paso $_replayStep')),
      );
    }
  }

  void _clearSession() {
    setState(() {
      _session = null;
      _replayStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _recorder.isRecording;
    final hasSession = _session != null && _session!.events.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Time-travel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Graba eventos del canal y reproduce hasta un paso para inspeccionar el estado.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (!isRecording && _session == null)
            ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.fiber_manual_record, size: 20),
              label: const Text('Iniciar grabación'),
            ),
          if (isRecording) ...[
            Row(
              children: [
                const Icon(
                  Icons.fiber_manual_record,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text('Grabando...', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop, size: 20),
              label: const Text('Detener y guardar sesión'),
            ),
          ],
          if (hasSession) ...[
            const Divider(),
            Text(
              'Sesión: ${_session!.length} eventos',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            if (_session!.length > 1) ...[
              Text('Reproducir hasta el paso: $_replayStep'),
              Slider(
                value: _replayStep.toDouble(),
                min: 0,
                max: (_session!.length - 1).toDouble(),
                divisions: _session!.length - 1,
                onChanged: (v) => setState(() => _replayStep = v.round()),
              ),
            ] else
              const Text(
                'Un evento grabado. Replay restaura y emite ese evento.',
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _replayToStep,
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Replay a este paso'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _clearSession,
                  child: const Text('Nueva sesión'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
