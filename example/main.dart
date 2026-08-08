// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// Minimal example: initialize OTel, add the interceptor to a
/// ChopperClient, make a request inside an active parent span, then
/// shut down cleanly.
library;

import 'package:chopper/chopper.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_chopper/otel_chopper.dart';

Future<void> main() async {
  await OTel.initialize(
    serviceName: 'chopper-otel-example',
    serviceVersion: '0.0.1',
  );

  final chopper = ChopperClient(
    baseUrl: Uri.parse('https://httpbin.org'),
    interceptors: [OTelChopperInterceptor()],
  );

  // Wrap the outbound call in a parent span so the client span has
  // somewhere to be attached. In a real server, the parent would be
  // the incoming-request span you got from your framework's interceptor.
  final tracer = OTel.tracer();
  await tracer.startActiveSpanAsync<void>(
    name: 'serve-request',
    fn: (_) async {
      final response =
          await chopper.get<dynamic, dynamic>(Uri.parse('/status/200'));
      print('status: ${response.statusCode}');
    },
  );

  chopper.dispose();
  await OTel.shutdown();
}
