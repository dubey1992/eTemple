import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean URLs without the hash fragment, so /admin and /login are real,
  // shareable, refreshable links. The web host must rewrite unknown paths to
  // index.html for this to work in production (see docs/DEPLOYMENT_CHECKLIST.md).
  usePathUrlStrategy();

  runApp(const ProviderScope(child: RadhaKrishnaThakurbariApp()));
}
