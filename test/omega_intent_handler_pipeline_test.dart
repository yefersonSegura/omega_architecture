import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

enum _PipeIntent with OmegaIntentNameDottedCamel implements OmegaIntentName {
  pipelineDemo,
}

void main() {
  test('pipeline execute and onSuccess', () async {
    final channel = OmegaChannel();
    final fm = OmegaFlowManager(channel: channel);
    var last = 0;

    OmegaIntentHandlerPipeline.withPayload<int>(_PipeIntent.pipelineDemo)
        .validate((p, intent, ctx) => p > 0)
        .execute((p, intent, ctx) => p * 2)
        .onSuccess((r, intent, ctx) {
          last = r;
        })
        .register(fm, consumeIntent: true);

    fm.handleIntent(OmegaIntent.fromName(_PipeIntent.pipelineDemo, payload: 3));
    await pumpEventQueue();
    expect(last, 6);

    fm.dispose();
    channel.dispose();
  });

  test('pipeline validate false skips execute', () async {
    final channel = OmegaChannel();
    final fm = OmegaFlowManager(channel: channel);
    var ran = false;

    OmegaIntentHandlerPipeline.withPayload<int>(_PipeIntent.pipelineDemo)
        .validate((p, intent, ctx) => false)
        .execute((p, intent, ctx) {
          ran = true;
          return 1;
        })
        .register(fm);

    fm.handleIntent(OmegaIntent.fromName(_PipeIntent.pipelineDemo, payload: 1));
    await pumpEventQueue();
    expect(ran, isFalse);

    fm.dispose();
    channel.dispose();
  });

  test('pipeline onPayloadMissing', () async {
    final channel = OmegaChannel();
    final fm = OmegaFlowManager(channel: channel);
    var missing = false;

    OmegaIntentHandlerPipeline.withPayload<int>(_PipeIntent.pipelineDemo)
        .execute((p, intent, ctx) => 1)
        .onPayloadMissing((intent, ctx) {
          missing = true;
        })
        .register(fm);

    fm.handleIntent(OmegaIntent.fromName(_PipeIntent.pipelineDemo));
    await pumpEventQueue();
    expect(missing, isTrue);

    fm.dispose();
    channel.dispose();
  });

  test('pipeline onError', () async {
    final channel = OmegaChannel();
    final fm = OmegaFlowManager(channel: channel);
    Object? caught;

    OmegaIntentHandlerPipeline.withPayload<int>(_PipeIntent.pipelineDemo)
        .execute((p, intent, ctx) => throw StateError('x'))
        .onError((e, st, intent, ctx) {
          caught = e;
        })
        .register(fm);

    fm.handleIntent(OmegaIntent.fromName(_PipeIntent.pipelineDemo, payload: 1));
    await pumpEventQueue();
    expect(caught, isA<StateError>());

    fm.dispose();
    channel.dispose();
  });
}
