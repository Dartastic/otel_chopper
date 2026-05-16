# otel_chopper

OpenTelemetry instrumentation for
[`package:chopper`](https://pub.dev/packages/chopper).

```dart
import 'package:chopper/chopper.dart';
import 'package:otel_chopper/otel_chopper.dart';

final chopper = ChopperClient(
  baseUrl: Uri.parse('https://api.example.com'),
  interceptors: [OTelChopperInterceptor()],
  services: [...],
);
```

Each outbound request opens a CLIENT span:
- name: `HTTP <METHOD>` (low cardinality — span name doesn't
  include URL path)
- `http.request.method`, `http.method` (legacy)
- `url.full`, `server.address`, `server.port`
- `http.response.status_code` on completion
- W3C `traceparent` header injected so the server side can stitch

`4xx` / `5xx` responses flip span status to Error.

Suppression: `runWithoutChopperInstrumentationAsync`.

## License

Apache 2.0
