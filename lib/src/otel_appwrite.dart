// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_appwrite_suppression.dart';

const _tracerName = 'dartastic_otel_libs_appwrite';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps an Appwrite Account (auth) operation in a CLIENT span.
///
/// ```dart
/// final session = await tracedAppwriteAccount<Session>(
///   operation: 'createEmailPasswordSession',
///   email: email,
///   invoke: () => account.createEmailPasswordSession(
///     email: email,
///     password: password,
///   ),
/// );
/// ```
Future<T> tracedAppwriteAccount<T>({
  required String operation,
  required Future<T> Function() invoke,
  String? email,
  String? userId,
}) async {
  if (appwriteInstrumentationSuppressed()) return invoke();
  final m = <String, Object>{'appwrite.operation': operation};
  if (email != null) m[User.userEmail.key] = email;
  if (userId != null) m[User.userId.key] = userId;
  return _run(
    spanName: 'appwrite.account $operation',
    attributes: m,
    invoke: invoke,
  );
}

/// Wraps an Appwrite Databases call (`listDocuments`,
/// `createDocument`, `updateDocument`, `deleteDocument`, etc.) in a
/// CLIENT span carrying database id, collection id, and operation.
Future<T> tracedAppwriteDb<T>({
  required String databaseId,
  required String collectionId,
  required String operation,
  required Future<T> Function() invoke,
}) async {
  if (appwriteInstrumentationSuppressed()) return invoke();
  final m = <String, Object>{
    'db.system': 'appwrite',
    'db.operation': operation,
    'db.namespace': databaseId,
    'db.collection.name': collectionId,
    'appwrite.database.id': databaseId,
    'appwrite.collection.id': collectionId,
    'appwrite.operation': operation,
  };
  return _run(
    spanName: 'appwrite.db $operation $collectionId',
    attributes: m,
    invoke: invoke,
  );
}

/// Wraps an Appwrite Storage call (`createFile`, `getFile`,
/// `deleteFile`, `listFiles`, `getFileView`, `getFilePreview`) in a
/// CLIENT span.
Future<T> tracedAppwriteStorage<T>({
  required String bucketId,
  required String operation,
  required Future<T> Function() invoke,
  String? fileId,
}) async {
  if (appwriteInstrumentationSuppressed()) return invoke();
  final m = <String, Object>{
    'appwrite.operation': operation,
    'appwrite.bucket.id': bucketId,
  };
  if (fileId != null) m['appwrite.file.id'] = fileId;
  return _run(
    spanName: 'appwrite.storage $operation $bucketId',
    attributes: m,
    invoke: invoke,
  );
}

/// Wraps an Appwrite Functions execution.
Future<T> tracedAppwriteFunction<T>({
  required String functionId,
  required Future<T> Function() invoke,
}) async {
  if (appwriteInstrumentationSuppressed()) return invoke();
  return _run(
    spanName: 'appwrite.function $functionId',
    attributes: {
      'appwrite.operation': 'createExecution',
      'appwrite.function.id': functionId,
    },
    invoke: invoke,
  );
}

Future<T> _run<T>({
  required String spanName,
  required Map<String, Object> attributes,
  required Future<T> Function() invoke,
}) async {
  final span = _tracer().startSpan(
    spanName,
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(attributes),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(
      OTel.attributes([
        OTel.attributeString(
          ErrorResource.errorType.key,
          e.runtimeType.toString(),
        ),
      ]),
    );
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
