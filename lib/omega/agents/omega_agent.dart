import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:omega_architecture/omega/core/semantics/omega_intent.dart';

import '../core/omega_sequencer.dart';
import '../contracts/omega_flow_contract.dart';
import '../core/channel/omega_channel.dart';
import '../core/events/omega_event.dart';

import 'behavior/omega_agent_behavior_engine.dart';
import 'behavior/omega_agent_behavior_context.dart';
import 'behavior/omega_agent_reaction.dart';

import 'protocol/omega_agent_inbox.dart';
import 'protocol/omega_agent_message.dart';

/// Autonomous logic unit: reacts to channel events and intents according to a [behavior].
///
/// **Why use it:** Encapsulates a responsibility (e.g. API login). The flow emits "auth.login.request";
/// the agent receives it, calls the API and emits "auth.login.success" or "auth.login.error".
///
/// **Example:** In [onAction] you receive the behavior's reaction; you emit events with [emit]. Call [dispose] on close.
abstract class OmegaAgent {
  /// Unique agent identifier.
  final String id;

  /// Event bus (channel or [OmegaChannelNamespace]) for emitting and listening.
  final OmegaEventBus channel;

  /// Engine that defines how the agent reacts to events and intents.
  final OmegaAgentBehaviorEngine behavior;

  StreamSubscription? _eventSubscription;

  /// Inbox for direct messages between agents.
  late final OmegaAgentInbox inbox;

  /// Agent's mutable internal state.
  final Map<String, dynamic> state = {};

  OmegaAgent({
    required this.id,
    required this.channel,
    required this.behavior,
  }) {
    inbox = OmegaAgentInbox();

    // Listen to system events and keep the subscription
    _eventSubscription = channel.events.listen(_handleEvent);
  }

  /// Optional declarative contract: events and intents this agent is declared to handle.
  ///
  /// In debug mode, Omega warns only when [behavior] would run a reaction but the name is
  /// missing from the contract. Bus traffic that matches no rule does not print.
  /// Cached on first access so prefer returning a const or stable instance.
  OmegaAgentContract? get contract => null;

  OmegaAgentContract? _contractCache;
  bool _contractCacheComputed = false;

  OmegaAgentContract? get _cachedContract {
    if (_contractCacheComputed) return _contractCache;
    _contractCacheComputed = true;
    _contractCache = contract;
    return _contractCache;
  }

  /// Cleans up resources and cancels subscriptions.
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  // -----------------------------------------------------------
  // 1. Process DIRECT messages from other agents
  // -----------------------------------------------------------

  /// Adds a message to the inbox and calls [onMessage]. For agent-to-agent communication.
  void receiveMessage(OmegaAgentMessage msg) {
    inbox.receive(msg);
    onMessage(msg);
  }

  /// Abstract method each agent must implement to respond to messages.
  void onMessage(OmegaAgentMessage msg);

  // -----------------------------------------------------------
  // 2. Process global events (OmegaChannel)
  // -----------------------------------------------------------

  void _handleEvent(OmegaEvent event) {
    final ctx = OmegaAgentBehaviorContext(event: event, state: state);
    final reaction = behavior.evaluate(ctx);
    if (kDebugMode) {
      final c = _cachedContract;
      if (c != null &&
          reaction != null &&
          !c.acceptsEvent(event.name)) {
        debugPrint(
          'OmegaAgent[$id]: received event "${event.name}" not in contract (listened: ${c.listenedEventNames}).',
        );
      }
    }
    if (reaction != null) {
      _executeReaction(reaction);
    }
  }

  // -----------------------------------------------------------
  // 3. Process semantic intents
  // -----------------------------------------------------------

  /// Evaluates the intent with [behavior] and runs the reaction in [onAction]. Called by the flow when it delegates to the agent.
  ///
  /// **Example:** Flow receives intent "auth.login"; calls agent.receiveIntent(intent); agent performs login and emits events.
  void receiveIntent(OmegaIntent intent) {
    final ctx = OmegaAgentBehaviorContext(intent: intent, state: state);
    final reaction = behavior.evaluate(ctx);
    if (kDebugMode) {
      final c = _cachedContract;
      if (c != null &&
          reaction != null &&
          !c.acceptsIntent(intent.name)) {
        debugPrint(
          'OmegaAgent[$id]: received intent "${intent.name}" not in contract (accepted: ${c.acceptedIntentNames}).',
        );
      }
    }
    if (reaction != null) {
      _executeReaction(reaction);
    }
  }

  // -----------------------------------------------------------
  // 4. Execute reactions from the BehaviorEngine
  // -----------------------------------------------------------

  void _executeReaction(OmegaAgentReaction reaction) {
    onAction(reaction.action, reaction.payload);
  }

  // -----------------------------------------------------------
  // 5. Each agent defines its internal actions
  // -----------------------------------------------------------

  /// Implement the logic for each action (e.g. "login": call API, then [emit] success/error).
  ///
  /// **Example:** `if (action == "login") { await api.login(payload); emit("auth.login.success", payload: user); }`
  void onAction(String action, dynamic payload);

  // -----------------------------------------------------------
  // 6. Emit global events
  // -----------------------------------------------------------

  /// Publishes an event on the channel. Use to notify the flow and other listeners of the result (success, error).
  ///
  /// [name] must be a **string** (the event name). For app enums that implement the event-name contract, use `.name`:
  /// `emit(AppEvent.authLoginSuccess.name, payload: user)` — not `emit(AppEvent.authLoginSuccess)`.
  ///
  /// **Example:** `emit("auth.login.success", payload: LoginSuccessPayload(token: t, user: u));`
  void emit(String name, {dynamic payload}) {
    channel.emit(
      OmegaEvent(
        id: omegaNextSequencedId('$id:'),
        name: name,
        payload: payload,
      ),
    );
  }
}
