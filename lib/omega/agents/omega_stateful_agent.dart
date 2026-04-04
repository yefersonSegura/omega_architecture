import 'dart:async';
import 'package:omega_architecture/omega_architecture.dart';

/// [OmegaAgent] variant that exposes a reactive view state [TState].
///
/// - The Omega **core** stays the same: intents/events still go through
///   [OmegaChannel] and the agent reacts via its [behavior].
/// - In addition, the agent keeps a typed `viewState` (for example
///   `CartState`) and emits changes through [stateStream] so the UI can
///   rebuild without touching the base `Map<String, dynamic> state`.
///
/// **Important:** The inherited [OmegaAgent.state] is a [Map] for generic use;
/// your UI model lives in [viewState]. Use [setViewState] with
/// `viewState.copyWith(...)` when [TState] supports it — do not call
/// `state.copyWith` (maps have no such method for your view model).
///
/// Use this when you want an agent to also behave as a small observable
/// store for a specific part of the UI.
///
/// **Lists in [viewState]:** to find an optional element, use [List.indexWhere]
/// and a null-safe index check (or a short loop). Avoid
/// `firstWhere(..., orElse: () => null as T?)` — it relies on an invalid cast and
/// is unnecessary when a nullable result is intended.
abstract class OmegaStatefulAgent<TState> extends OmegaAgent {
  OmegaStatefulAgent({
    required super.id,
    required super.channel,
    required TState initialState,
    required super.behavior,
  }) : _viewState = initialState;

  TState _viewState;
  final _stateController = StreamController<TState>.broadcast();

  /// Latest known view state (the agent's reactive store).
  TState get viewState => _viewState;

  /// Stream of [viewState] changes for UI widgets and tests.
  Stream<TState> get stateStream => _stateController.stream;

  /// Updates the view state and notifies all subscribers.
  void setViewState(TState next) {
    _viewState = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  @override
  void dispose() {
    if (!_stateController.isClosed) {
      _stateController.close();
    }
    super.dispose();
  }
}