// lib/omega/offline/omega_offline_queue.dart
//
// Offline-first support: queue of intents to be retried when the app regains connectivity.
//
// This file is intentionally minimal: it defines the core types so apps and flows
// can implement their own persistence strategies (SharedPreferences, Hive, SQLite, etc.).

import '../core/semantics/omega_intent.dart';

/// Represents an intent that could not be executed online and is pending retry.
///
/// **Why use it:** When the app is offline (or a network call fails), instead of
/// dropping the user's action, you can enqueue an [OmegaQueuedIntent] and retry
/// later when connectivity is restored.
class OmegaQueuedIntent {
  /// Stable identifier for the queued operation. You can use it to deduplicate
  /// or show progress in the UI.
  final String id;

  /// Original intent name (e.g. "order.create.v2").
  final String name;

  /// Optional payload. Should be JSON-serializable if you plan to persist it.
  final dynamic payload;

  /// When the intent was queued.
  final DateTime createdAt;

  const OmegaQueuedIntent({
    required this.id,
    required this.name,
    this.payload,
    required this.createdAt,
  });

  /// Convenience helper to create a queued item from an [OmegaIntent].
  ///
  /// The [id] is copied from the intent; you can generate a stable id when
  /// creating the intent if you need to track it across retries.
  factory OmegaQueuedIntent.fromIntent(OmegaIntent intent) {
    return OmegaQueuedIntent(
      id: intent.id,
      name: intent.name,
      payload: intent.payload,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  static OmegaQueuedIntent fromJson(Map<String, dynamic> json) {
    return OmegaQueuedIntent(
      id: json['id'] as String,
      name: json['name'] as String,
      payload: json['payload'],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Abstraction for an offline queue of intents.
///
/// Implement this interface to store queued intents in memory, on disk or in
/// any backend. Flows/agents can depend on [OmegaOfflineQueue] without caring
/// about the persistence mechanism.
abstract class OmegaOfflineQueue {
  /// Adds [intent] to the queue. Implementations decide whether to overwrite
  /// existing items with the same id or keep duplicates.
  Future<void> enqueue(OmegaQueuedIntent intent);

  /// Returns all queued intents in FIFO order (oldest first).
  Future<List<OmegaQueuedIntent>> getAll();

  /// Removes a queued intent by [id]. Called after a successful retry.
  Future<void> remove(String id);

  /// Clears the entire queue.
  Future<void> clear();
}

/// Simple in-memory implementation of [OmegaOfflineQueue].
///
/// **Use cases:** tests, demos or apps that only need offline support within a
/// single session. The queue is lost when the process exits.
class OmegaMemoryOfflineQueue implements OmegaOfflineQueue {
  final List<OmegaQueuedIntent> _items = <OmegaQueuedIntent>[];

  @override
  Future<void> enqueue(OmegaQueuedIntent intent) async {
    _items.add(intent);
  }

  @override
  Future<List<OmegaQueuedIntent>> getAll() async {
    return List<OmegaQueuedIntent>.from(_items);
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}

