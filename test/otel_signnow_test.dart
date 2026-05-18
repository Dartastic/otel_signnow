// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_signnow/otel_signnow.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_signnow-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('invite.send records signers + template + status', () async {
    await tracedSignnow<String>(
      operation: 'document.invite.send',
      invoke: () async => const SignnowCallResult(
        value: 'ok',
        result: SignnowResult(
          documentId: 'd-1',
          inviteId: 'i-1',
          status: 'pending',
          signersTotal: 3,
          signersSigned: 0,
          templateUsed: true,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('signnow document.invite.send')!);
    expect(a['signnow.document.id'], 'd-1');
    expect(a['signnow.invite.id'], 'i-1');
    expect(a['signnow.signers.total'], 3);
    expect(a['signnow.template.used'], true);
  });

  test('cancelled sets span error', () async {
    await tracedSignnow<String>(
      operation: 'document.invite.cancel',
      invoke: () async => const SignnowCallResult(
        value: 'ok',
        result: SignnowResult(status: 'cancelled'),
      ),
    );
    expect(
      spans.findSpanByName('signnow document.invite.cancel')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutSignnowInstrumentationAsync(() async {
      await tracedSignnow<String>(
        operation: 'document.get',
        invoke: () async => const SignnowCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('signnow '), isEmpty);
  });
}
