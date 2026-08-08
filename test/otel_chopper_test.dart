// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:chopper/chopper.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:otel_chopper/otel_chopper.dart';
import 'package:test/test.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

void main() {
  group('OTelChopperInterceptor', () {
    late _MemorySpanExporter exporter;
    Map<String, String>? lastSeenHeaders;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'chopper-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
      lastSeenHeaders = null;
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    ChopperClient buildClient({int status = 200}) {
      final mock = MockClient((request) async {
        lastSeenHeaders = request.headers;
        return http.Response('OK', status);
      });
      return ChopperClient(
        baseUrl: Uri.parse('https://api.example.com'),
        client: mock,
        interceptors: [OTelChopperInterceptor()],
      );
    }

    test('emits CLIENT span with http.* + url.* + server.* attrs', () async {
      final client = buildClient();
      final response = await client.get<dynamic, dynamic>(
        Uri.parse('https://api.example.com/v1/users'),
      );
      expect(response.statusCode, equals(200));

      final span = exporter.spans.single;
      expect(span.kind, equals(SpanKind.client));
      expect(span.name, equals('HTTP GET'));
      final attrs = _attrs(span);
      expect(attrs['http.request.method'], equals('GET'));
      // Deprecated legacy key must NOT be emitted.
      expect(attrs.containsKey('http.method'), isFalse);
      expect(attrs['url.full'], contains('/v1/users'));
      expect(attrs['server.address'], equals('api.example.com'));
      expect(attrs['http.response.status_code'], equals(200));
      expect(span.status, isNot(equals(SpanStatusCode.Error)));
    });

    test('4xx/5xx response flips span status to Error', () async {
      final client = buildClient(status: 500);
      await client.get<dynamic, dynamic>(
        Uri.parse('https://api.example.com/v1/boom'),
      );
      final span = exporter.spans.single;
      expect(span.status, equals(SpanStatusCode.Error));
      expect(_attrs(span)['http.response.status_code'], equals(500));
    });

    test('injects traceparent into outbound headers', () async {
      final client = buildClient();
      await client.get<dynamic, dynamic>(
        Uri.parse('https://api.example.com/v1/users'),
      );
      expect(lastSeenHeaders, isNotNull);
      final tp = lastSeenHeaders!['traceparent'];
      expect(tp, isNotNull);
      expect(tp!.startsWith('00-'), isTrue);
      expect(tp.length, equals(55));
    });

    test('runWithoutChopperInstrumentationAsync bypasses spans', () async {
      final client = buildClient();
      await runWithoutChopperInstrumentationAsync(() async {
        await client.get<dynamic, dynamic>(
          Uri.parse('https://api.example.com/v1/users'),
        );
      });
      expect(exporter.spans, isEmpty);
      expect(lastSeenHeaders?['traceparent'], isNull);
    });
  });
}
