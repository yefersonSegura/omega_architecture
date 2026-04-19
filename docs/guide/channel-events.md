# Channel & events

**OmegaChannel** is the shared bus: anything can `emit(OmegaEvent)` and listen to `channel.events`.

- Use **`OmegaEvent.fromName`** with typed enums or string names.  
- Prefer **`OmegaTypedEvent`** + **`emitTyped`** when you want compile-time safety.  
- Use **`channel.namespace('module')`** to avoid name collisions in large apps.

Minimal pattern:

```dart
final channel = OmegaChannel();
channel.emit(OmegaEvent.fromName(AppEvent.authLoginRequest, payload: creds));
channel.events.listen((e) { /* react */ });
// channel.dispose() when tearing down
```

Full examples: **`example/lib/auth/`** and **[Channel & events](./channel-events)** (this section).
