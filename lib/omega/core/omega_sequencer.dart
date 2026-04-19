/// Per-isolate monotonic counter for Omega ids (avoids [DateTime.now] syscalls on hot paths).
int _omegaSeq = 0;

/// Returns `"$prefix$next"` with a unique incrementing suffix (e.g. `ev:1`, `intent:2`).
String omegaNextSequencedId(String prefix) => '$prefix${++_omegaSeq}';
