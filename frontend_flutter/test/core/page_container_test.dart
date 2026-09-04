import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/widgets/page_container.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('constrains the reading measure on a wide screen', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(
        body: PageContainer(
          maxWidth: 600,
          child: SizedBox(height: 40, child: Text('content')),
        ),
      ),
      surfaceSize: const Size(1440, 900),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(PageContainer)).width, 1440);
    // The padded content stays within the measure, not the full window.
    expect(tester.getSize(find.text('content')).width, lessThanOrEqualTo(600));
  });

  testWidgets('takes only the height of its child', (tester) async {
    // It must not expand to fill whatever height it is offered. A version that
    // did covered the whole page when used as a footer in
    // `bottomNavigationBar`, painting over the app bar and swallowing taps —
    // the site looked right and nothing was clickable.
    await pumpScreen(
      tester,
      const Scaffold(
        body: PageContainer(
          verticalPadding: 10,
          child: SizedBox(height: 40, child: Text('content')),
        ),
      ),
      surfaceSize: const Size(800, 900),
    );
    await tester.pumpAndSettle();

    // 40 of content plus 10 of padding above and below.
    expect(tester.getSize(find.byType(PageContainer)).height, 60);
  });
}
