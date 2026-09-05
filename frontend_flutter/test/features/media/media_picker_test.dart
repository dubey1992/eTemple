import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';
import 'package:rkt_web/features/events/presentation/admin_event_editor_screen.dart';
import 'package:rkt_web/features/media/domain/media_item.dart';
import 'package:rkt_web/features/media/presentation/widgets/media_picker_field.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/fake_media_repository.dart';
import '../../support/fake_event_repository.dart';
import '../../support/pump_app.dart';

/// The picker is the integration this phase exists to make possible: the three
/// URL boxes left over from Phases 3 and 4 can now be filled from the library.
void main() {
  group('MediaPickerField', () {
    testWidgets('fills the field with the URL the deletion guard looks for', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      final photo = testAdminMedia(id: 5, status: MediaStatuses.published);
      final media = FakeMediaRepository(adminList: [photo]);

      await pumpScreen(
        tester,
        Scaffold(
          body: MediaPickerField(
            fieldKey: const ValueKey('test-picker'),
            controller: controller,
            label: 'Poster',
          ),
        ),
        media: media,
        surfaceSize: const Size(1024, 900),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('test-picker-choose')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media-picker-dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('media-picker-option-5')));
      await tester.pumpAndSettle();

      // Exactly the value the server compares against when it decides whether
      // the file may be deleted, so the picker and the guard agree.
      expect(controller.text, photo.referenceUrl);
    });

    testWidgets('an empty library says so rather than showing a blank grid', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpScreen(
        tester,
        Scaffold(
          body: MediaPickerField(
            fieldKey: const ValueKey('test-picker'),
            controller: controller,
            label: 'Poster',
          ),
        ),
        media: FakeMediaRepository(),
        surfaceSize: const Size(1024, 900),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('test-picker-choose')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media-picker-empty')), findsOneWidget);
    });

    testWidgets('an externally hosted URL can still be typed', (tester) async {
      // Removing the text box would make an image hosted anywhere else
      // impossible, and would hide values entered before this phase existed.
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpScreen(
        tester,
        Scaffold(
          body: MediaPickerField(
            fieldKey: const ValueKey('test-picker'),
            controller: controller,
            label: 'Poster',
          ),
        ),
        media: FakeMediaRepository(),
        surfaceSize: const Size(1024, 900),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('test-picker')),
        'https://example.org/poster.jpg',
      );

      expect(controller.text, 'https://example.org/poster.jpg');
    });

    testWidgets('the event poster field is now a picker', (tester) async {
      await pumpScreen(
        tester,
        const Scaffold(body: AdminEventEditorScreen()),
        media: FakeMediaRepository(),
        events: FakeEventRepository(),
        surfaceSize: const Size(1024, 3000),
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              session: testUser(permissions: const {Permissions.eventsManage}),
            ),
          ),
          contentRepositoryProvider.overrideWithValue(FakeContentRepository()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event-poster_url-choose')), findsOneWidget);
    });
  });

  group('the home page gallery block', () {
    testWidgets('shows the approved placeholder while nothing is published', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const HomeScreen(),
        media: FakeMediaRepository(),
        surfaceSize: const Size(1280, 3600),
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            FakeContentRepository(settings: testSettings()),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gallery-placeholder')), findsOneWidget);

      // The way through is offered even here. The gallery page is a real
      // destination — albums, the video darshan, and its own empty state in
      // the temple's words — and a visitor should never have to guess whether
      // the mosaic on the home page is all there is.
      expect(find.byKey(const Key('gallery-see-all')), findsOneWidget);
    });

    /// A visitor at the foot of the pictures should not have to scroll back to
    /// the heading to see the rest of them.
    testWidgets('offers a way through under the mosaic as well', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const HomeScreen(),
        media: FakeMediaRepository(
          photos: List.generate(
            9,
            (index) =>
                testMediaItem(id: index + 1, title: 'तस्वीर ${index + 1}'),
          ),
        ),
        surfaceSize: const Size(1280, 3600),
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            FakeContentRepository(settings: testSettings()),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gallery-see-all')), findsOneWidget);
      expect(find.byKey(const Key('gallery-view-all')), findsOneWidget);

      // Nine published, five on the home page: the button says how many more
      // there are rather than leaving the visitor to wonder.
      expect(find.text('सभी 9 तस्वीरें देखें'), findsOneWidget);
    });

    testWidgets('shows published photographs and a link to the gallery', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const HomeScreen(),
        media: FakeMediaRepository(
          photos: [
            testMediaItem(id: 1, title: 'मंदिर प्रांगण'),
            testMediaItem(id: 2, title: 'दीपावली'),
          ],
        ),
        surfaceSize: const Size(1280, 3600),
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            FakeContentRepository(settings: testSettings()),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media-tile-1')), findsOneWidget);
      expect(find.byKey(const Key('gallery-see-all')), findsOneWidget);
      expect(find.byKey(const Key('gallery-placeholder')), findsNothing);
    });

    testWidgets('an unreachable gallery degrades to the placeholder', (
      tester,
    ) async {
      // The block is decorative here; the page a devotee came for must not
      // break because of it.
      await pumpScreen(
        tester,
        const HomeScreen(),
        media: FakeMediaRepository(
          listError: const AppException(code: ErrorCode.network),
        ),
        surfaceSize: const Size(1280, 3600),
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            FakeContentRepository(settings: testSettings()),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gallery-placeholder')), findsOneWidget);
    });
  });
}
