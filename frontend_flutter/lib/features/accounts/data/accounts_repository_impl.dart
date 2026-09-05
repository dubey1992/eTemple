import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/account.dart';
import '../domain/accounts_repository.dart';

/// HTTP implementation of [AccountsRepository] against the Laravel API.
class AccountsRepositoryImpl implements AccountsRepository {
  const AccountsRepositoryImpl(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  @override
  Future<Transparency> transparency({
    required String language,
    int? year,
  }) async {
    final envelope = await _api.get<Transparency>(
      ApiEndpoints.publicTransparency,
      queryParameters: {'lang': language, 'year': ?year},
      decode: (data) => Transparency.fromJson(_object(data, 'transparency')),
    );
    return envelope.data;
  }

  @override
  Future<TransactionPage> transactions(TransactionQuery query) async {
    final envelope = await _api.get<List<Transaction>>(
      ApiEndpoints.adminTransactions,
      queryParameters: query.toQueryParameters(),
      decode: (data) => _list(
        data,
        'transactions',
      ).map(Transaction.fromJson).toList(growable: false),
    );

    return TransactionPage(transactions: envelope.data, meta: envelope.meta);
  }

  @override
  Future<AccountsSummary> summary(TransactionQuery query) async {
    final envelope = await _api.get<AccountsSummary>(
      ApiEndpoints.adminTransactionSummary,
      queryParameters: query.toSummaryParameters(),
      decode: (data) => AccountsSummary.fromJson(_object(data, 'summary')),
    );
    return envelope.data;
  }

  @override
  Future<Transaction> transaction(int id) async {
    final envelope = await _api.get<Transaction>(
      ApiEndpoints.adminTransaction(id),
      decode: (data) => Transaction.fromJson(_object(data, 'transaction')),
    );
    return envelope.data;
  }

  @override
  Future<Transaction> record(
    TransactionDraft draft, {
    AttachmentUpload? bill,
  }) async {
    final envelope = await _api.post<Transaction>(
      ApiEndpoints.adminTransactions,
      body: bill == null ? draft.toJson() : _form(draft, bill),
      decode: (data) => Transaction.fromJson(_object(data, 'transaction')),
    );
    return envelope.data;
  }

  @override
  Future<Transaction> save(
    int id,
    TransactionDraft draft, {
    AttachmentUpload? bill,
  }) async {
    if (bill == null) {
      final envelope = await _api.put<Transaction>(
        ApiEndpoints.adminTransaction(id),
        body: draft.toJson(),
        decode: (data) => Transaction.fromJson(_object(data, 'transaction')),
      );
      return envelope.data;
    }

    // Multipart cannot be sent as a PUT by every browser and proxy, so the
    // upload goes as a POST carrying Laravel's `_method` override — the same
    // spelling an HTML form would use.
    final envelope = await _api.post<Transaction>(
      ApiEndpoints.adminTransaction(id),
      body: _form(draft, bill, method: 'PUT'),
      decode: (data) => Transaction.fromJson(_object(data, 'transaction')),
    );
    return envelope.data;
  }

  @override
  Future<Transaction> approve(int id) async {
    final envelope = await _api.post<Transaction>(
      ApiEndpoints.adminTransactionApprove(id),
      decode: (data) => Transaction.fromJson(_object(data, 'transaction')),
    );
    return envelope.data;
  }

  @override
  Future<Transaction> reverse(int id, String reason) async {
    final envelope = await _api.post<Transaction>(
      ApiEndpoints.adminTransactionReverse(id),
      body: {'reversal_reason': reason},
      decode: (data) => Transaction.fromJson(_object(data, 'transaction')),
    );
    return envelope.data;
  }

  @override
  String attachmentUrl(int id) =>
      '${_config.apiBaseUrl}${ApiEndpoints.adminTransactionAttachment(id)}';

  @override
  Future<List<AccountingCategory>> categories({
    String? type,
    bool? activeOnly,
  }) async {
    final envelope = await _api.get<List<AccountingCategory>>(
      ApiEndpoints.adminAccountingCategories,
      queryParameters: {'type': ?type, 'active_only': ?activeOnly},
      decode: (data) => _list(
        data,
        'categories',
      ).map(AccountingCategory.fromJson).toList(growable: false),
    );
    return envelope.data;
  }

  @override
  Future<AccountingCategory> createCategory(
    AccountingCategoryDraft draft,
  ) async {
    final envelope = await _api.post<AccountingCategory>(
      ApiEndpoints.adminAccountingCategories,
      body: draft.toJson(),
      decode: (data) => AccountingCategory.fromJson(_object(data, 'category')),
    );
    return envelope.data;
  }

  @override
  Future<AccountingCategory> saveCategory(
    int id,
    AccountingCategoryDraft draft,
  ) async {
    final envelope = await _api.put<AccountingCategory>(
      ApiEndpoints.adminAccountingCategory(id),
      body: draft.toJson(),
      decode: (data) => AccountingCategory.fromJson(_object(data, 'category')),
    );
    return envelope.data;
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _api.delete<void>(
      ApiEndpoints.adminAccountingCategory(id),
      decode: (_) {},
    );
  }

  @override
  Future<AccountingSettings> settings() async {
    final envelope = await _api.get<AccountingSettings>(
      ApiEndpoints.adminAccountingSettings,
      decode: (data) =>
          AccountingSettings.fromJson(_object(data, 'accounting settings')),
    );
    return envelope.data;
  }

  @override
  Future<AccountingSettings> saveSettings(AccountingSettingsDraft draft) async {
    final envelope = await _api.put<AccountingSettings>(
      ApiEndpoints.adminAccountingSettings,
      body: draft.toJson(),
      decode: (data) =>
          AccountingSettings.fromJson(_object(data, 'accounting settings')),
    );
    return envelope.data;
  }

  /// The draft plus the bill, as multipart.
  ///
  /// Dio sets the boundary and the content type from the FormData itself. The
  /// declared `contentType` below is passed along for completeness and is not
  /// trusted by anything: the server decides the type by reading the bytes.
  static FormData _form(
    TransactionDraft draft,
    AttachmentUpload bill, {
    String? method,
  }) {
    final fields = <String, Object?>{
      '_method': ?method,
      for (final entry in draft.toJson().entries)
        // A multipart field has no concept of absence, so an empty optional has
        // to simply not be there rather than travel as the string "null".
        if (entry.value != null && entry.value != '') entry.key: entry.value,
      'attachment': MultipartFile.fromBytes(
        bill.bytes,
        filename: bill.filename,
        contentType: bill.contentType == null
            ? null
            : DioMediaType.parse(bill.contentType!),
      ),
    };

    return FormData.fromMap(fields);
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

  static List<Map<String, dynamic>> _list(Object? data, String what) {
    if (data is! List) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a list of $what.',
      );
    }
    return data
        .map(ApiEnvelopeParser.asMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}
