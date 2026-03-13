import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

void main() {
  test('OmegaQueuedIntent.fromIntent copies id, name and payload', () {
    final intent = OmegaIntent(id: 'i1', name: 'order.create.v1', payload: {'x': 1});
    final q = OmegaQueuedIntent.fromIntent(intent);

    expect(q.id, 'i1');
    expect(q.name, 'order.create.v1');
    expect(q.payload, {'x': 1});
  });

  test('OmegaQueuedIntent toJson/fromJson round-trip', () {
    final original = OmegaQueuedIntent(
      id: 'q1',
      name: 'order.create.v2',
      payload: {'total': 10},
      createdAt: DateTime.now(),
    );
    final json = original.toJson();
    final restored = OmegaQueuedIntent.fromJson(json);

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.payload, original.payload);
    expect(restored.createdAt.toIso8601String(), original.createdAt.toIso8601String());
  });

  test('OmegaMemoryOfflineQueue behaves as FIFO queue', () async {
    final queue = OmegaMemoryOfflineQueue();
    final a = OmegaQueuedIntent(
      id: 'a',
      name: 'intent.a',
      payload: null,
      createdAt: DateTime.now(),
    );
    final b = OmegaQueuedIntent(
      id: 'b',
      name: 'intent.b',
      payload: null,
      createdAt: DateTime.now(),
    );

    await queue.enqueue(a);
    await queue.enqueue(b);

    final all = await queue.getAll();
    expect(all.length, 2);
    expect(all.first.id, 'a');
    expect(all.last.id, 'b');

    await queue.remove('a');
    final afterRemove = await queue.getAll();
    expect(afterRemove.length, 1);
    expect(afterRemove.first.id, 'b');

    await queue.clear();
    final afterClear = await queue.getAll();
    expect(afterClear, isEmpty);
  });
}

