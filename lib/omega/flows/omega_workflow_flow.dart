import 'dart:async';
import 'omega_flow.dart';

typedef OmegaWorkflowStepHandler = FutureOr<void> Function();

/// Optional advanced flow: models a process as explicit steps.
///
/// This keeps Omega's core model intact (events/intents/channel) and adds:
/// - step registration
/// - controlled transitions
/// - standard step/error expressions for UI/Inspector
abstract class OmegaWorkflowFlow extends OmegaFlow {
  OmegaWorkflowFlow({required super.id, required super.channel});

  String? _currentStepId;
  final Map<String, OmegaWorkflowStepHandler> _steps = {};

  /// Current workflow step id (if started).
  String? get currentStepId => _currentStepId;

  /// Registers a step handler.
  void defineStep(String id, OmegaWorkflowStepHandler handler) {
    _steps[id] = handler;
  }

  /// Starts workflow execution at [stepId].
  Future<void> startAt(String stepId) async {
    _currentStepId = stepId;
    emitExpression('workflow.step', payload: {'step': stepId});
    await _run(stepId);
  }

  /// Moves workflow to the next step and executes it.
  Future<void> next(String stepId) async {
    _currentStepId = stepId;
    emitExpression('workflow.step', payload: {'step': stepId});
    await _run(stepId);
  }

  /// Emits a standard workflow error expression.
  ///
  /// Only [code] is positional; [message] must be passed by name.
  /// Wrong: `failStep('start', errorPayload)` (extra positional). Right: `failStep('start', message: err.toString())`.
  void failStep(String code, {String? message}) {
    emitExpression(
      'workflow.error',
      payload: {
        'step': _currentStepId,
        'code': code,
        if (message != null) 'message': message,
      },
    );
  }

  /// Emits a standard workflow completion expression.
  void completeWorkflow({dynamic payload}) {
    emitExpression(
      'workflow.done',
      payload: payload ?? {'flow': id, 'step': _currentStepId},
    );
  }

  Future<void> _run(String stepId) async {
    final handler = _steps[stepId];
    if (handler == null) {
      failStep(
        'workflow.step.not_found',
        message: 'Step "$stepId" is not registered.',
      );
      return;
    }

    try {
      await handler();
    } catch (e) {
      failStep('workflow.step.exception', message: e.toString());
    }
  }
}
