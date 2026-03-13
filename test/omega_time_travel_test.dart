import 'package:flutter_test/flutter_test.dart';
import 'package:omega_architecture/omega_architecture.dart';

class _DummyFlow extends OmegaFlow {
  _DummyFlow(OmegaChannel channel) : super(id: "f", channel: channel);
  @override
  void onEvent(OmegaFlowContext ctx) {}
  @override
  void onIntent(OmegaFlowContext ctx) {}
}

void main() {
  test("OmegaTimeTravelRecorder startRecording records events and stopRecording returns session", () async {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final flow = _DummyFlow(channel);
    manager.registerFlow(flow);
    manager.activate("f");

    final recorder = OmegaTimeTravelRecorder();
    expect(recorder.isRecording, isFalse);

    recorder.startRecording(channel, manager);
    expect(recorder.isRecording, isTrue);

    channel.emit(OmegaEvent(id: "e1", name: "ev.one"));
    channel.emit(OmegaEvent(id: "e2", name: "ev.two"));
    await Future<void>.delayed(Duration.zero);

    final session = recorder.stopRecording();
    expect(recorder.isRecording, isFalse);
    expect(session.initialSnapshot, isNotNull);
    expect(session.events.length, 2);
    expect(session.length, 2);
    expect(session.events[0].name, "ev.one");
    expect(session.events[1].name, "ev.two");

    manager.dispose();
    channel.dispose();
  });

  test("OmegaTimeTravelRecorder replay with empty session does nothing", () {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final recorder = OmegaTimeTravelRecorder();
    final session = OmegaRecordedSession(initialSnapshot: null, events: []);

    recorder.replay(session, channel, manager);
    recorder.replay(session, channel, manager, upToIndex: 0);

    manager.dispose();
    channel.dispose();
  });

  test("OmegaTimeTravelRecorder replay restores snapshot and re-emits events up to upToIndex", () async {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    final flow = _DummyFlow(channel);
    manager.registerFlow(flow);
    manager.switchTo("f");
    flow.memory["x"] = 1;

    final snapshot = manager.getAppSnapshot();
    final session = OmegaRecordedSession(
      initialSnapshot: snapshot,
      events: [
        OmegaEvent(id: "a", name: "e1"),
        OmegaEvent(id: "b", name: "e2"),
        OmegaEvent(id: "c", name: "e3"),
      ],
    );

    final recorder = OmegaTimeTravelRecorder();
    final received = <String>[];
    channel.events.listen((e) => received.add(e.name));

    recorder.replay(session, channel, manager, upToIndex: 1);
    await Future<void>.delayed(Duration.zero);

    expect(received, ["e1", "e2"]);
    expect(flow.memory["x"], 1);

    manager.dispose();
    channel.dispose();
  });

  test("OmegaTimeTravelRecorder second startRecording while recording is no-op", () async {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    manager.registerFlow(_DummyFlow(channel));
    manager.activate("f");

    final recorder = OmegaTimeTravelRecorder();
    recorder.startRecording(channel, manager);
    channel.emit(OmegaEvent(id: "e1", name: "one"));
    recorder.startRecording(channel, manager);
    channel.emit(OmegaEvent(id: "e2", name: "two"));
    await Future<void>.delayed(Duration.zero);

    final session = recorder.stopRecording();
    expect(session.events.length, 2);

    manager.dispose();
    channel.dispose();
  });

  test("OmegaTimeTravelRecorder replay does not record re-emitted events", () async {
    final channel = OmegaChannel();
    final manager = OmegaFlowManager(channel: channel);
    manager.registerFlow(_DummyFlow(channel));
    manager.activate("f");

    final recorder = OmegaTimeTravelRecorder();
    recorder.startRecording(channel, manager);
    channel.emit(OmegaEvent(id: "e1", name: "original"));
    await Future<void>.delayed(Duration.zero);
    final session = recorder.stopRecording();
    expect(session.events.length, 1);

    recorder.startRecording(channel, manager);
    recorder.replay(session, channel, manager);
    await Future<void>.delayed(Duration.zero);
    final session2 = recorder.stopRecording();
    expect(session2.events.length, 0);

    manager.dispose();
    channel.dispose();
  });
}
