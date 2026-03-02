// test/omega_flutter_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

void main() {
  testWidgets('OmegaScope provides channel and OmegaBuilder reacts to events', (
    WidgetTester tester,
  ) async {
    final channel = OmegaChannel();
    final flowManager = OmegaFlowManager(channel: channel);

    await tester.pumpWidget(
      MaterialApp(
        home: OmegaScope(
          channel: channel,
          flowManager: flowManager,
          child: Scaffold(
            body: OmegaBuilder(
              eventName: 'test_event',
              builder: (context, event) {
                return Text(event?.payload ?? 'no event');
              },
            ),
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text('no event'), findsOneWidget);

    // Emit event
    channel.emit(
      const OmegaEvent(id: '1', name: 'test_event', payload: 'hello omega'),
    );

    // Re-render
    await tester.pump();

    // Verify update
    expect(find.text('hello omega'), findsOneWidget);

    // Emit different event (should not update due to eventName filter)
    channel.emit(
      const OmegaEvent(
        id: '2',
        name: 'other_event',
        payload: 'should not see this',
      ),
    );

    await tester.pump();
    expect(find.text('hello omega'), findsOneWidget);
  });
}
