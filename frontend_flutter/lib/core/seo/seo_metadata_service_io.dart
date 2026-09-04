import 'page_metadata.dart';

/// Non-web implementation: there is no document to update.
///
/// Records what it was asked to apply so tests can assert the strategy without
/// a browser.
class SeoMetadataService {
  SeoMetadataService();

  final List<PageMetadata> applied = [];

  PageMetadata? get lastApplied => applied.isEmpty ? null : applied.last;

  void apply(PageMetadata metadata) => applied.add(metadata);
}
