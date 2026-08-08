// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'chopper_suppression.dart';

const _tracerName = 'otel_chopper';

/// Chopper [Interceptor] that opens an HTTP `CLIENT` span around
/// each outbound request, injects the W3C `traceparent` header
/// into the request, and records `http.*` semconv attributes.
///
/// ```dart
/// final chopper = ChopperClient(
///   baseUrl: Uri.parse('https://api.example.com'),
///   interceptors: [OTelChopperInterceptor()],
///   services: [...],
/// );
/// ```
///
/// ## Span shape
///
/// - **Name**: `HTTP <METHOD>` (e.g. `HTTP GET`) — low cardinality.
/// - **Kind**: `CLIENT`
/// - **Attributes**:
///   - `http.request.method`
///   - `url.full` (the full request URL)
///   - `server.address`, `server.port` (parsed from the URL)
///   - `http.response.status_code` (on success)
///   - `error.type` (on exception)
class OTelChopperInterceptor implements Interceptor {
  /// Creates the interceptor.
  ///
  /// - [tracer] — defaults to
  ///   `OTel.tracerProvider().getTracer('otel_chopper')`.
  OTelChopperInterceptor({Tracer? tracer})
      : _tracer = tracer ?? OTel.tracerProvider().getTracer(_tracerName);

  final Tracer _tracer;
  final _propagator = W3CTraceContextPropagator();

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    if (chopperInstrumentationSuppressed()) {
      return chain.proceed(chain.request);
    }

    final request = chain.request;
    final url = request.url;
    final method = request.method.toUpperCase();

    final attrs = <String, Object>{
      Http.httpRequestMethod.key: method,
      Url.urlFull.key: url.toString(),
    };
    if (url.host.isNotEmpty) {
      attrs[Server.serverAddress.key] = url.host;
    }
    if (url.hasPort) attrs[Server.serverPort.key] = url.port;

    final span = _tracer.startSpan(
      'HTTP $method',
      kind: SpanKind.client,
      attributes: OTel.attributesFromMap(attrs),
    );

    // Inject traceparent into the request headers.
    final mutableHeaders = Map<String, String>.from(request.headers);
    _propagator.inject(
      Context.current.withSpan(span),
      mutableHeaders,
      _MapSetter(mutableHeaders),
    );
    final tracedRequest = request.copyWith(headers: mutableHeaders);

    try {
      final response = await chain.proceed(tracedRequest);
      span.addAttributes(OTel.attributes([
        OTel.attributeInt(
          Http.httpResponseStatusCode.key,
          response.statusCode,
        ),
      ]));
      if (response.statusCode >= 400) {
        span.setStatus(
          SpanStatusCode.Error,
          'HTTP ${response.statusCode}',
        );
      }
      return response;
    } catch (e, st) {
      span.addAttributes(OTel.attributes([
        OTel.attributeString(
          ErrorAttributes.errorType.key,
          e.runtimeType.toString(),
        ),
      ]));
      span.recordException(e, stackTrace: st);
      span.setStatus(SpanStatusCode.Error, e.toString());
      rethrow;
    } finally {
      span.end();
    }
  }
}

class _MapSetter implements TextMapSetter<String> {
  _MapSetter(this._carrier);
  final Map<String, String> _carrier;

  @override
  void set(String key, String value) {
    _carrier[key] = value;
  }
}
