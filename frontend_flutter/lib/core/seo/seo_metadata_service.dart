/// Applies [PageMetadata] to the browser document.
///
/// Flutter Web renders to canvas, so nothing a widget builds is visible to a
/// crawler or a link preview. This service is the runtime half of the
/// specification's "explicit Flutter Web metadata strategy": on every route it
/// rewrites the real `<title>`, `<meta name="description">`, `<link rel=canonical>`,
/// the Open Graph tags and `<html lang>`.
///
/// The static half — pre-rendered per-slug metadata for crawlers that do not
/// execute JavaScript — is produced by `tool/generate_static_meta.dart`.
library;

export 'page_metadata.dart';
export 'seo_metadata_service_io.dart'
    if (dart.library.js_interop) 'seo_metadata_service_web.dart';
