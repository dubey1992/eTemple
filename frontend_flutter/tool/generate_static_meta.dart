// Pre-render the static half of the SEO strategy.
//
// Flutter Web paints to a canvas, so a crawler that does not execute JavaScript
// sees only `web/index.html` — the same title and description for every route.
// The runtime half (lib/core/seo) fixes this for crawlers that do run JS.
//
// This tool covers the rest: after `flutter build web`, it reads the published
// pages from the API and writes, for each slug, a `build/web/<slug>/index.html`
// that carries that page's real title, description, canonical URL and Open Graph
// tags, followed by the unchanged Flutter bootstrap. The Flutter UI is not
// replaced — a browser still boots the same app; only the head differs.
//
// It also emits sitemap.xml and robots.txt.
//
// Usage:
//   dart run tool/generate_static_meta.dart \
//     --api=https://api.thakurbari.example/api \
//     --site=https://thakurbari.example \
//     [--build=build/web] [--slugs=home,about]
//
// The host must serve `/<slug>/index.html` for `/<slug>`; see
// docs/DEPLOYMENT_CHECKLIST.md.

import 'dart:convert';
import 'dart:io';

const _defaultSlugs = ['home', 'about'];

/// Used only when the committee has not written the temple's name yet, which
/// mirrors what the running app shows in the same situation.
const _fallbackSiteName = 'राधा कृष्ण ठाकुरबाड़ी';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  if (options == null) {
    stderr.writeln(
      'usage: dart run tool/generate_static_meta.dart '
      '--api=<url> --site=<url> [--build=build/web] [--slugs=a,b]',
    );
    exitCode = 64;
    return;
  }

  final buildDir = Directory(options.buildDir);
  final indexFile = File('${options.buildDir}/index.html');
  if (!buildDir.existsSync() || !indexFile.existsSync()) {
    stderr.writeln(
      'error: ${options.buildDir}/index.html not found. '
      'Run "flutter build web --release" first.',
    );
    exitCode = 66;
    return;
  }

  final template = indexFile.readAsStringSync();
  final client = HttpClient();
  final written = <String>[];

  try {
    // The temple's own name is CMS content from Phase 3 on, so the pre-rendered
    // head takes it from the profile rather than from a constant in this file.
    final siteName = await _fetchSiteName(client, options.apiBase);
    if (siteName == null) {
      stdout.writeln(
        'note   temple profile has no name yet; '
        'falling back to "$_fallbackSiteName"',
      );
    }

    for (final slug in options.slugs) {
      final page = await _fetchPage(client, options.apiBase, slug);
      if (page == null) {
        stdout.writeln('skip   /$slug  (not published)');
        continue;
      }

      // The home page is served from the root, every other slug from its path.
      final isHome = slug == 'home';
      final path = isHome ? '/' : '/$slug';
      final html = _render(
        template,
        page,
        options.siteBase,
        path,
        siteName ?? _fallbackSiteName,
      );

      final target = isHome
          ? indexFile
          : File('${options.buildDir}/$slug/index.html');
      target.parent.createSync(recursive: true);
      target.writeAsStringSync(html);

      written.add(path);
      stdout.writeln('wrote  ${_relative(target.path, options.buildDir)}');
    }

    _writeSitemap(options, written);
    _writeRobots(options);
  } finally {
    client.close(force: true);
  }

  stdout.writeln('done: ${written.length} route(s) pre-rendered');
}

/// The temple's name as the committee has written it, or null if they have not.
Future<String?> _fetchSiteName(HttpClient client, String apiBase) async {
  final uri = Uri.parse('$apiBase/public/temple-profile?lang=hi');
  final request = await client.getUrl(uri);
  request.headers.set(HttpHeaders.acceptHeader, 'application/json');
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();

  if (response.statusCode != 200) return null;

  final decoded = jsonDecode(body);
  if (decoded is! Map || decoded['success'] != true) return null;

  final data = decoded['data'];
  return data is Map ? _blockValue(data.cast<String, dynamic>(), 'name') : null;
}

/// Fetches one published page. Returns null for anything not publicly visible,
/// which is exactly what the API reports for a draft.
Future<Map<String, dynamic>?> _fetchPage(
  HttpClient client,
  String apiBase,
  String slug,
) async {
  final uri = Uri.parse('$apiBase/public/pages/$slug?lang=hi');
  final request = await client.getUrl(uri);
  request.headers.set(HttpHeaders.acceptHeader, 'application/json');
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();

  if (response.statusCode != 200) return null;

  final decoded = jsonDecode(body);
  if (decoded is! Map || decoded['success'] != true) return null;

  final data = decoded['data'];
  return data is Map ? data.cast<String, dynamic>() : null;
}

String? _blockValue(Map<String, dynamic> page, String key) {
  final block = page[key];
  if (block is! Map) return null;
  final value = block['value'];
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

/// Replaces the head tags in the built index.html with this page's real values.
String _render(
  String template,
  Map<String, dynamic> page,
  String siteBase,
  String path,
  String siteName,
) {
  final pageTitle =
      _blockValue(page, 'meta_title') ?? _blockValue(page, 'title');
  // Matched against the page title so an SEO title that already names the
  // temple is not suffixed with the temple's name a second time.
  final title = pageTitle == null
      ? siteName
      : (pageTitle.contains(siteName) ? pageTitle : '$pageTitle | $siteName');

  final description =
      _blockValue(page, 'meta_description') ??
      _truncate(_blockValue(page, 'content'));

  final canonical = '$siteBase$path';

  var html = template;
  html = html.replaceAll(
    RegExp(r'<title>.*?</title>', dotAll: true),
    '<title>${_escape(title)}</title>',
  );
  html = _replaceMeta(html, 'name', 'description', description);
  html = _replaceMeta(html, 'property', 'og:title', title);
  html = _replaceMeta(html, 'property', 'og:description', description);

  // Canonical and og:url are not in the template, so insert them.
  html = html.replaceFirst(
    '</head>',
    '  <link rel="canonical" href="${_escape(canonical)}"/>\n'
        '  <meta property="og:url" content="${_escape(canonical)}"/>\n'
        '</head>',
  );

  return html;
}

String _replaceMeta(String html, String attr, String key, String? content) {
  if (content == null) return html;

  final pattern = RegExp('<meta $attr="${RegExp.escape(key)}"[^>]*>');
  final tag = '<meta $attr="$key" content="${_escape(content)}">';

  return pattern.hasMatch(html)
      ? html.replaceFirst(pattern, tag)
      : html.replaceFirst('</head>', '  $tag\n</head>');
}

String? _truncate(String? text, [int max = 160]) {
  if (text == null) return null;
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.isEmpty) return null;
  return flat.length <= max
      ? flat
      : '${flat.substring(0, max - 1).trimRight()}…';
}

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

void _writeSitemap(_Options options, List<String> paths) {
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

  for (final path in paths) {
    buffer
      ..writeln('  <url>')
      ..writeln('    <loc>${_escape('${options.siteBase}$path')}</loc>')
      ..writeln('  </url>');
  }
  buffer.writeln('</urlset>');

  File('${options.buildDir}/sitemap.xml').writeAsStringSync(buffer.toString());
  stdout.writeln('wrote  sitemap.xml (${paths.length} url(s))');
}

void _writeRobots(_Options options) {
  // The admin area must never be indexed.
  File('${options.buildDir}/robots.txt').writeAsStringSync(
    'User-agent: *\n'
    'Disallow: /admin\n'
    'Disallow: /login\n'
    'Disallow: /forgot-password\n'
    'Allow: /\n'
    'Sitemap: ${options.siteBase}/sitemap.xml\n',
  );
  stdout.writeln('wrote  robots.txt');
}

String _relative(String path, String base) =>
    path.replaceFirst(RegExp('^${RegExp.escape(base)}[\\\\/]?'), '');

class _Options {
  const _Options({
    required this.apiBase,
    required this.siteBase,
    required this.buildDir,
    required this.slugs,
  });

  final String apiBase;
  final String siteBase;
  final String buildDir;
  final List<String> slugs;

  static _Options? parse(List<String> args) {
    String? value(String name) {
      final prefix = '--$name=';
      for (final arg in args) {
        if (arg.startsWith(prefix)) return arg.substring(prefix.length);
      }
      return null;
    }

    final api = value('api');
    final site = value('site');
    if (api == null || site == null) return null;

    final slugs = value('slugs')
        ?.split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return _Options(
      apiBase: _stripTrailingSlash(api),
      siteBase: _stripTrailingSlash(site),
      buildDir: _stripTrailingSlash(value('build') ?? 'build/web'),
      slugs: slugs == null || slugs.isEmpty ? _defaultSlugs : slugs,
    );
  }

  static String _stripTrailingSlash(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
