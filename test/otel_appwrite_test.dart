// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_appwrite/otel_appwrite.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_appwrite-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('Account session creation', () async {
    await tracedAppwriteAccount<String>(
      operation: 'createEmailPasswordSession',
      email: 'ada@example.com',
      invoke: () async => 'session-1',
    );
    final span =
        spans.findSpanByName('appwrite.account createEmailPasswordSession');
    expect(span, isNotNull);
    final a = attrsOf(span!);
    expect(a['appwrite.operation'], 'createEmailPasswordSession');
    expect(a['user.email'], 'ada@example.com');
  });

  test('DB createDocument span has db.* + appwrite.* attrs', () async {
    await tracedAppwriteDb<String>(
      databaseId: 'main',
      collectionId: 'orders',
      operation: 'createDocument',
      invoke: () async => 'doc-1',
    );
    final span = spans.findSpanByName('appwrite.db createDocument orders');
    expect(span, isNotNull);
    final a = attrsOf(span!);
    expect(a['db.system'], 'appwrite');
    expect(a['db.namespace'], 'main');
    expect(a['db.collection.name'], 'orders');
    expect(a['appwrite.database.id'], 'main');
    expect(a['appwrite.collection.id'], 'orders');
  });

  test('Storage createFile span', () async {
    await tracedAppwriteStorage<String>(
      bucketId: 'avatars',
      operation: 'createFile',
      fileId: 'u-42',
      invoke: () async => 'file-1',
    );
    final span = spans.findSpanByName('appwrite.storage createFile avatars');
    final a = attrsOf(span!);
    expect(a['appwrite.bucket.id'], 'avatars');
    expect(a['appwrite.file.id'], 'u-42');
  });

  test('Function execution span', () async {
    await tracedAppwriteFunction<String>(
      functionId: 'enrich-order',
      invoke: () async => 'ok',
    );
    expect(
      spans.findSpanByName('appwrite.function enrich-order'),
      isNotNull,
    );
  });

  test('records exception on throw', () async {
    await expectLater(
      tracedAppwriteDb<String>(
        databaseId: 'main',
        collectionId: 'x',
        operation: 'createDocument',
        invoke: () async => throw StateError('forbidden'),
      ),
      throwsA(isA<StateError>()),
    );
    final span = spans.findSpanByName('appwrite.db createDocument x');
    expect(span!.status, SpanStatusCode.Error);
  });

  test('suppression skips spans across helpers', () async {
    await runWithoutAppwriteInstrumentationAsync(() async {
      await tracedAppwriteAccount<String>(
        operation: 'get',
        invoke: () async => 'ok',
      );
      await tracedAppwriteDb<String>(
        databaseId: 'm',
        collectionId: 'c',
        operation: 'list',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('appwrite.'), isEmpty);
  });
}
