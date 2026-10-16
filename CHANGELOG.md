# Changelog

## [0.3.2-wip]

## [0.3.1] - 2026-10-16

### Changed

- README: standard header naming the instrumented library, its supported platforms and project links; pubspec description to match.

## [0.3.0] - 2026-10-11

### Changed

- Requires `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- Context is propagated with the app's configured propagators
  (`OTelAPI.textMapPropagator`: W3C trace context and baggage by
  default, `OTEL_PROPAGATORS` to change them) instead of a fixed W3C
  propagator.
- **Breaking:** depends on `dartastic_opentelemetry_api` only, no
  longer on the SDK. The application chooses and initializes the
  OpenTelemetry SDK. Parameters and fields typed with SDK classes
  now use the API types (`APITracer`, `APISpan`, `APILogger`, ...);
  SDK instances are still accepted wherever an API type is expected.

## [0.2.0] - 2026-08-08

### Changed

- Semantic conventions updated to the current OTel registry: deprecated
  attribute keys are no longer emitted (`db.system` -> `db.system.name`,
  `db.operation` -> `db.operation.name`, `rpc.system` -> `rpc.system.name`,
  with `rpc.service` folded into a fully-qualified `rpc.method`).
- Dependency floors raised to `dartastic_opentelemetry ^1.1.0-beta.12` and
  `dartastic_opentelemetry_api ^1.0.0-rc.1`. The previous floors declared
  compatibility with API versions that predate the semconv enums this
  package uses and could not actually resolve-and-compile.
- `repository` URL corrected to the canonical `Dartastic` org casing so
  pub.dev repository verification succeeds.

### Added

- `OTelChopperInterceptor` — a Chopper `Interceptor` that opens
  an HTTP CLIENT span around each outbound request and injects
  the W3C `traceparent` header.
- Span attributes: `http.request.method`, `url.full`,
  `server.address`, `server.port`,
  `http.response.status_code`. `4xx`/`5xx` responses flip span
  status to Error. The deprecated `http.method` legacy key is
  not emitted.
- Zone-scoped suppression
  (`runWithoutChopperInstrumentation` / async variant).
- 4 tests using `http.testing.MockClient` (no network needed):
  span shape on success, error status flip, traceparent header
  injection, suppression scope.
