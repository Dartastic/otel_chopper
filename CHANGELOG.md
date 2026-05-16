# Changelog

## [0.1.0-wip]

### Added

- `OTelChopperInterceptor` — a Chopper `Interceptor` that opens
  an HTTP CLIENT span around each outbound request and injects
  the W3C `traceparent` header.
- Span attributes: `http.request.method`, `http.method`
  (legacy), `url.full`, `server.address`, `server.port`,
  `http.response.status_code`. `4xx`/`5xx` responses flip span
  status to Error.
- Zone-scoped suppression
  (`runWithoutChopperInstrumentation` / async variant).
- 4 tests using `http.testing.MockClient` (no network needed):
  span shape on success, error status flip, traceparent header
  injection, suppression scope.
