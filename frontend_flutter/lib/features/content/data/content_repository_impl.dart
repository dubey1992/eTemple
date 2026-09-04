import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/content_repository.dart';
import '../domain/page_content.dart';
import '../domain/site_settings.dart';

/// HTTP implementation of [ContentRepository] against the Laravel API.
class ContentRepositoryImpl implements ContentRepository {
  const ContentRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<PageContent> page(String slug, {required String language}) async {
    final envelope = await _api.get<PageContent>(
      ApiEndpoints.publicPage(slug),
      queryParameters: {'lang': language},
      decode: (data) => PageContent.fromJson(_object(data, 'page')),
    );
    return envelope.data;
  }

  @override
  Future<SiteSettings> siteSettings({required String language}) async {
    final envelope = await _api.get<SiteSettings>(
      ApiEndpoints.publicSiteSettings,
      queryParameters: {'lang': language},
      decode: (data) => SiteSettings.fromJson(_object(data, 'site settings')),
    );
    return envelope.data;
  }

  @override
  Future<List<EditablePage>> adminPages() async {
    final envelope = await _api.get<List<EditablePage>>(
      ApiEndpoints.adminPages,
      queryParameters: {'per_page': 100},
      decode: (data) {
        if (data is! List) {
          throw const AppException(
            code: ErrorCode.malformedResponse,
            debugMessage: 'Expected a list of pages.',
          );
        }
        return data
            .map(ApiEnvelopeParser.asMap)
            .whereType<Map<String, dynamic>>()
            .map(EditablePage.fromJson)
            .toList(growable: false);
      },
    );
    return envelope.data;
  }

  @override
  Future<EditablePage> adminPage(int id) async {
    final envelope = await _api.get<EditablePage>(
      ApiEndpoints.adminPage(id),
      decode: (data) => EditablePage.fromJson(_object(data, 'page')),
    );
    return envelope.data;
  }

  @override
  Future<EditablePage> savePage(int id, EditablePageDraft draft) async {
    // The API client attaches the CSRF header for unsafe methods; the cookie is
    // already present because the editor is signed in.
    final envelope = await _api.put<EditablePage>(
      ApiEndpoints.adminPage(id),
      body: draft.toJson(),
      decode: (data) => EditablePage.fromJson(_object(data, 'page')),
    );
    return envelope.data;
  }

  static Map<String, dynamic> _object(Object? data, String what) {
    final json = ApiEnvelopeParser.asMap(data);
    if (json == null) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a $what object in the response data.',
      );
    }
    return json;
  }
}
