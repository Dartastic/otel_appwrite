// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// OpenTelemetry instrumentation for Appwrite BaaS calls.
///
/// Four callback-shaped helpers — `tracedAppwriteAccount`,
/// `tracedAppwriteDb`, `tracedAppwriteStorage`,
/// `tracedAppwriteFunction` — wrap the corresponding Appwrite product
/// calls in CLIENT spans with `db.*` for databases plus `appwrite.*`
/// vendor-specific attrs.
library;

export 'src/otel_appwrite.dart';
export 'src/otel_appwrite_suppression.dart';
