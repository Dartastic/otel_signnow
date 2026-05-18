// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_signnow_suppression.dart';

const _tracerName = 'dartastic_otel_libs_signnow';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class SignnowResult {
  const SignnowResult({
    this.itemCount,
    this.documentId,
    this.inviteId,
    this.status,
    this.fieldInviteStatus,
    this.signersTotal,
    this.signersSigned,
    this.templateUsed,
    this.workflowId,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `id` of the document.
  final String? documentId;

  /// `invite_id`.
  final String? inviteId;

  /// `created` / `pending` / `fulfilled` / `cancelled`.
  final String? status;

  /// Per-field invite status `pending` / `fulfilled` / `created`.
  final String? fieldInviteStatus;

  /// Total signers on the invite.
  final int? signersTotal;

  /// Count of signers who have signed.
  final int? signersSigned;

  /// `template_id` was used.
  final bool? templateUsed;

  /// Workflow id when this is a freeform workflow invite.
  final String? workflowId;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class SignnowCallResult<T> {
  const SignnowCallResult({required this.value, this.result});
  final T value;
  final SignnowResult? result;
}

/// Wraps a SignNow API call in a CLIENT span. [operation] is one of
/// `document.upload`, `document.get`, `document.update`,
/// `document.delete`, `document.download`, `document.invite.send`,
/// `document.invite.cancel`, `document.freeform_invite.create`,
/// `template.list`, `template.copy`, `template.create_from_doc`,
/// `folder.list`, `folder.documents`, `webhook.create`,
/// `teams.list`, `users.me`.
Future<T> tracedSignnow<T>({
  required String operation,
  required Future<SignnowCallResult<T>> Function() invoke,
}) async {
  if (signnowInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'signnow',
    'rpc.method': operation,
    'signnow.operation': operation,
  };

  final span = _tracer().startSpan(
    'signnow $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'signnow.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.documentId != null) {
        extras.add(OTel.attributeString(
          'signnow.document.id',
          r.result!.documentId!,
        ));
      }
      if (r.result!.inviteId != null) {
        extras.add(OTel.attributeString(
          'signnow.invite.id',
          r.result!.inviteId!,
        ));
      }
      if (r.result!.status != null) {
        extras.add(OTel.attributeString(
          'signnow.status',
          r.result!.status!,
        ));
        if (r.result!.status == 'cancelled') {
          span.setStatus(
            SpanStatusCode.Error,
            'SignNow cancelled',
          );
        }
      }
      if (r.result!.fieldInviteStatus != null) {
        extras.add(OTel.attributeString(
          'signnow.field_invite.status',
          r.result!.fieldInviteStatus!,
        ));
      }
      if (r.result!.signersTotal != null) {
        extras.add(OTel.attributeInt(
          'signnow.signers.total',
          r.result!.signersTotal!,
        ));
      }
      if (r.result!.signersSigned != null) {
        extras.add(OTel.attributeInt(
          'signnow.signers.signed',
          r.result!.signersSigned!,
        ));
      }
      if (r.result!.templateUsed != null) {
        extras.add(OTel.attributeBool(
          'signnow.template.used',
          r.result!.templateUsed!,
        ));
      }
      if (r.result!.workflowId != null) {
        extras.add(OTel.attributeString(
          'signnow.workflow.id',
          r.result!.workflowId!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'signnow.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'SignNow HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
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
