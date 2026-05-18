// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

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
