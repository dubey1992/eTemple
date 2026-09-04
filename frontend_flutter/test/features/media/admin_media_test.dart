import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/core/files/file_chooser.dart';
import 'package:rkt_web/core/files/picked_file.dart';
import 'package:rkt_web/core/widgets/state_views.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/media/domain/media_item.dart';
import 'package:rkt_web/features/media/presentation/admin_album_editor_screen.dart';
import 'package:rkt_web/features/media/presentation/admin_albums_screen.dart';
import 'package:rkt_web/features/media/presentation/admin_media_editor_screen.dart';
import 'package:rkt_web/features/media/presentation/admin_media_screen.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/fake_media_repository.dart';
import '../../support/pump_app.dart';

Future<void> pumpMedia(
  WidgetTester tester,
  Widget screen,
  FakeMediaRepository media, {
  Set<String> permissions = const {Permissions.mediaManage},
  Size surfaceSize = const Size(1024, 2600),
  List<Override> overrides = const [],
}) async {
  await pumpScreen(
    tester,
    Scaffold(body: screen),
    surfaceSize: surfaceSize,
    media: media,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(session: testUser(permissions: permissions)),
      ),
      contentRepositoryProvider.overrideWithValue(FakeContentRepository()),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminMediaScreen', () {
    testWidgets('lists everything, including drafts', (tester) async {
      final media = FakeMediaRepository(
        adminList: [
          testAdminMedia(
            id: 1,
            titleHi: 'प्रकाशित चित्र',
            status: MediaStatuses.published,
          ),
          testAdminMedia(id: 2, titleHi: 'मसौदा चित्र'),
        ],
      );

      await pumpMedia(tester, const AdminMediaScreen(), media);

      expect(find.byKey(const Key('admin-media-1')), findsOneWidget);
      expect(find.byKey(const Key('admin-media-2')), findsOneWidget);
    });

    testWidgets('an empty library shows its empty state', (tester) async {
      await pumpMedia(tester, const AdminMediaScreen(), FakeMediaRepository());

      expect(find.byKey(const Key('admin-media-empty')), findsOneWidget);
    });

    testWidgets('the status filter narrows the list', (tester) async {
      final media = FakeMediaRepository(
        adminList: [
          testAdminMedia(id: 1, status: MediaStatuses.published),
          testAdminMedia(id: 2, titleHi: 'मसौदा'),
        ],
      );

      await pumpMedia(tester, const AdminMediaScreen(), media);
      expect(find.byKey(const Key('admin-media-2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('media-filter-published')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin-media-1')), findsOneWidget);
      expect(find.byKey(const Key('admin-media-2')), findsNothing);
    });

    testWidgets('reordering sends the whole arrangement', (tester) async {
      final media = FakeMediaRepository(
        adminList: [
          testAdminMedia(id: 1, sortOrder: 0),
          testAdminMedia(id: 2, sortOrder: 1),
          testAdminMedia(id: 3, sortOrder: 2),
        ],
      );

      await pumpMedia(tester, const AdminMediaScreen(), media);

      await tester.tap(find.byKey(const Key('media-down-1')));
      await tester.pumpAndSettle();

      // Not one move: a dropped request then leaves the previous order intact
      // rather than half of a new one.
      expect(media.lastOrder, [2, 1, 3]);
    });

    testWidgets('the arrows are hidden while a filter is on', (tester) async {
      // Moving an item "up" past rows the filter is hiding would produce an
      // order nobody asked for.
      final media = FakeMediaRepository(
        adminList: [
          testAdminMedia(id: 1, status: MediaStatuses.published),
          testAdminMedia(id: 2, status: MediaStatuses.published),
        ],
      );

      await pumpMedia(tester, const AdminMediaScreen(), media);
      expect(find.byKey(const Key('media-down-1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('media-filter-published')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media-down-1')), findsNothing);
    });

    testWidgets('a viewer sees the library but is offered no new button', (
      tester,
    ) async {
      final media = FakeMediaRepository(adminList: [testAdminMedia(id: 1)]);

      await pumpMedia(
        tester,
        const AdminMediaScreen(),
        media,
        permissions: const {Permissions.contentView},
      );

      expect(find.byKey(const Key('admin-media-1')), findsOneWidget);
      // A courtesy, never the access control: the server refuses the write
      // whatever this widget shows.
      expect(find.byKey(const Key('media-new')), findsNothing);
      expect(find.byKey(const Key('media-down-1')), findsNothing);
    });

    testWidgets('a forbidden load shows the unauthorized state', (
      tester,
    ) async {
      final media = FakeMediaRepository(
        adminError: const AppException(code: ErrorCode.forbidden),
      );

      await pumpMedia(tester, const AdminMediaScreen(), media);

      expect(find.byType(UnauthorizedView), findsOneWidget);
    });
  });

  group('AdminMediaEditorScreen', () {
    testWidgets('a new item asks for a photograph or a video', (tester) async {
      await pumpMedia(
        tester,
        const AdminMediaEditorScreen(),
        FakeMediaRepository(),
      );

      expect(find.byKey(const Key('media-kind')), findsOneWidget);
      expect(find.byKey(const Key('media-choose-file')), findsOneWidget);
      expect(find.byKey(const Key('media-external_url')), findsNothing);
    });

    testWidgets('choosing video swaps the file picker for a link field', (
      tester,
    ) async {
      await pumpMedia(
        tester,
        const AdminMediaEditorScreen(),
        FakeMediaRepository(),
      );

      await tester.tap(find.byIcon(Icons.smart_display_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media-external_url')), findsOneWidget);
      expect(find.byKey(const Key('media-choose-file')), findsNothing);
    });

    testWidgets('saving a photograph with no file chosen is refused here', (
      tester,
    ) async {
      final media = FakeMediaRepository();

      await pumpMedia(tester, const AdminMediaEditorScreen(), media);

      await tester.enterText(find.byKey(const Key('media-title_hi')), 'चित्र');
      await tester.tap(find.byKey(const Key('media-save')));
      await tester.pumpAndSettle();

      // Refused before the request, so an obviously incomplete form does not
      // cost a round trip.
      expect(media.uploadCalls, 0);
      expect(find.byKey(const Key('media-error')), findsOneWidget);
    });

    testWidgets('a chosen file is uploaded with the typed values', (
      tester,
    ) async {
      final media = FakeMediaRepository();

      await pumpMedia(
        tester,
        AdminMediaEditorScreen(chooser: _StubChooser()),
        media,
      );

      await tester.tap(find.byKey(const Key('media-choose-file')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media-chosen-file')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('media-title_hi')),
        'संध्या आरती',
      );
      await tester.tap(find.byKey(const Key('media-save')));
      await tester.pumpAndSettle();

      expect(media.uploadCalls, 1);
      expect(media.lastUpload?.titleHi, 'संध्या आरती');
      expect(media.lastUpload?.fileName, 'aarti.jpg');
      expect(media.lastUpload?.byteSize, greaterThan(0));
    });

    testWidgets('a video link is sent as typed for the server to validate', (
      tester,
    ) async {
      final media = FakeMediaRepository();

      await pumpMedia(tester, const AdminMediaEditorScreen(), media);

      await tester.tap(find.byIcon(Icons.smart_display_outlined).first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('media-external_url')),
        'https://youtu.be/abcdefghijk',
      );
      await tester.enterText(find.byKey(const Key('media-title_hi')), 'दर्शन');
      await tester.tap(find.byKey(const Key('media-save')));
      await tester.pumpAndSettle();

      // The host allow-list and the id extraction are the server's: a check
      // here would be a second implementation to disagree with.
      expect(media.createVideoCalls, 1);
      expect(media.lastVideo?.externalUrl, 'https://youtu.be/abcdefghijk');
    });

    testWidgets('a server refusal about the file is spelled out', (
      tester,
    ) async {
      final media = FakeMediaRepository(
        saveError: const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'file': ['The file could not be read as an image.'],
          },
        ),
      );

      await pumpMedia(
        tester,
        AdminMediaEditorScreen(chooser: _StubChooser()),
        media,
      );

      await tester.tap(find.byKey(const Key('media-choose-file')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('media-title_hi')), 'चित्र');
      await tester.tap(find.byKey(const Key('media-save')));
      await tester.pumpAndSettle();

      // A refusal about the file has no text box to attach itself to; without
      // this it would be reduced to a generic "check what you entered".
      expect(find.byKey(const Key('media-error')), findsOneWidget);
      expect(
        find.text('The file could not be read as an image.'),
        findsOneWidget,
      );
    });

    testWidgets('an existing item cannot have its file replaced', (
      tester,
    ) async {
      final media = FakeMediaRepository(adminList: [testAdminMedia(id: 4)]);

      await pumpMedia(tester, const AdminMediaEditorScreen(mediaId: 4), media);

      expect(find.byKey(const Key('media-stored-summary')), findsOneWidget);
      expect(find.byKey(const Key('media-choose-file')), findsNothing);
      expect(find.byKey(const Key('media-kind')), findsNothing);
    });

    testWidgets('editing sends the changed values', (tester) async {
      final media = FakeMediaRepository(adminList: [testAdminMedia(id: 4)]);

      await pumpMedia(tester, const AdminMediaEditorScreen(mediaId: 4), media);

      await tester.enterText(
        find.byKey(const Key('media-title_hi')),
        'नया शीर्षक',
      );
      await tester.tap(find.byKey(const Key('media-save')));
      await tester.pumpAndSettle();

      expect(media.saveCalls, 1);
      expect(media.lastDraft?.titleHi, 'नया शीर्षक');
    });

    testWidgets('deleting asks the server what is in the way first', (
      tester,
    ) async {
      final media = FakeMediaRepository(
        adminList: [testAdminMedia(id: 4)],
        referenceAnswer: const MediaReferences(
          canDelete: false,
          references: [
            MediaReference(type: 'event_poster', label: 'जन्माष्टमी', id: 9),
          ],
        ),
      );

      await pumpMedia(tester, const AdminMediaEditorScreen(mediaId: 4), media);

      await tester.tap(find.byKey(const Key('media-delete')));
      await tester.pumpAndSettle();

      // No confirmation dialogue at all: the button would have failed, and
      // saying why beats asking a question whose answer cannot be honoured.
      expect(find.byKey(const Key('media-delete-dialog')), findsNothing);
      expect(find.byKey(const Key('media-in-use')), findsOneWidget);
      expect(find.textContaining('जन्माष्टमी'), findsOneWidget);
      expect(media.deleteCalls, 0);
    });

    testWidgets('an unreferenced item is deleted after a confirmation', (
      tester,
    ) async {
      final media = FakeMediaRepository(
        adminList: [testAdminMedia(id: 4)],
        referenceAnswer: const MediaReferences(canDelete: true, references: []),
      );

      await pumpMedia(tester, const AdminMediaEditorScreen(mediaId: 4), media);

      await tester.tap(find.byKey(const Key('media-delete')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media-delete-dialog')), findsOneWidget);
      expect(media.deleteCalls, 0);

      await tester.tap(find.byKey(const Key('media-delete-confirm')));
      await tester.pumpAndSettle();

      expect(media.deleteCalls, 1);
      expect(media.lastDeletedId, 4);
    });

    testWidgets('a viewer sees the form read-only', (tester) async {
      final media = FakeMediaRepository(adminList: [testAdminMedia(id: 4)]);

      await pumpMedia(
        tester,
        const AdminMediaEditorScreen(mediaId: 4),
        media,
        permissions: const {Permissions.contentView},
      );

      expect(find.byKey(const Key('media-read-only')), findsOneWidget);
      expect(find.byKey(const Key('media-save')), findsNothing);
      expect(find.byKey(const Key('media-delete')), findsNothing);
    });
  });

  group('AdminAlbumsScreen', () {
    testWidgets('lists albums with a count that includes drafts', (
      tester,
    ) async {
      final media = FakeMediaRepository(
        adminAlbumList: [
          testAdminAlbum(id: 1, titleHi: 'जन्माष्टमी', mediaCount: 7),
        ],
      );

      await pumpMedia(tester, const AdminAlbumsScreen(), media);

      expect(find.byKey(const Key('admin-album-1')), findsOneWidget);
      expect(find.textContaining('7'), findsOneWidget);
    });

    testWidgets('no albums is an empty state', (tester) async {
      await pumpMedia(tester, const AdminAlbumsScreen(), FakeMediaRepository());

      expect(find.byKey(const Key('admin-albums-empty')), findsOneWidget);
    });

    testWidgets('creating an album sends the typed values', (tester) async {
      final media = FakeMediaRepository();

      await pumpMedia(tester, const AdminAlbumEditorScreen(), media);

      await tester.enterText(
        find.byKey(const Key('album-title_hi')),
        'रथ यात्रा',
      );
      await tester.tap(find.byKey(const Key('album-save')));
      await tester.pumpAndSettle();

      expect(media.lastAlbumDraft?.titleHi, 'रथ यात्रा');
      // Left blank on purpose: the server generates a unique one, because a
      // Hindi-only title transliterates to nothing usable.
      expect(media.lastAlbumDraft?.slug, isNull);
    });

    testWidgets('deleting an album asks first and says the photographs stay', (
      tester,
    ) async {
      final media = FakeMediaRepository(
        adminAlbumList: [testAdminAlbum(id: 3)],
      );

      await pumpMedia(tester, const AdminAlbumEditorScreen(albumId: 3), media);

      await tester.tap(find.byKey(const Key('album-delete')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('album-delete-dialog')), findsOneWidget);
      expect(media.deleteCalls, 0);

      await tester.tap(find.byKey(const Key('album-delete-confirm')));
      await tester.pumpAndSettle();

      expect(media.deleteCalls, 1);
      expect(media.lastDeletedId, 3);
    });
  });
}

/// Stands in for the browser's file chooser, which does not exist on the VM.
class _StubChooser implements FileChooser {
  @override
  bool get isSupported => true;

  @override
  Future<PickedFile?> pickImage({List<String> accept = const []}) async =>
      PickedFile(
        name: 'aarti.jpg',
        bytes: testBytes(64),
        mimeType: 'image/jpeg',
      );
}
