# Changelog

## [0.3.0-wip]

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
