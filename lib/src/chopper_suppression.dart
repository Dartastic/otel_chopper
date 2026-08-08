// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #otel_chopper_suppress;

/// Whether Chopper instrumentation is suppressed in the current [Zone].
///
/// True inside [runWithoutChopperInstrumentation] /
/// [runWithoutChopperInstrumentationAsync] scopes.
bool chopperInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] with Chopper instrumentation suppressed: no spans are
/// opened and no `traceparent` header is injected.
T runWithoutChopperInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Async variant of [runWithoutChopperInstrumentation]: the suppression
/// zone stays in effect across awaits inside [body].
Future<T> runWithoutChopperInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
