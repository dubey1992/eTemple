import 'package:flutter/material.dart';

/// Every stored photograph on the site is loaded through here.
///
/// Two things are decided once, rather than at each of the half-dozen call
/// sites that show an image:
///
/// **The decode is bounded.** `cacheWidth` makes the bitmap in memory match the
/// size on screen rather than the size of the file. A 1920-pixel image in a
/// 300-pixel tile costs about 15 MB of RAM, and twenty of those on a phone is
/// the end of the page (PHASE_5_PLAN assumption M11).
///
/// **A cross-origin image still displays.** Flutter Web fetches image *bytes*,
/// which needs `Access-Control-Allow-Origin` on the response — and uploads are
/// served as static files by the web server, which does not run Laravel's CORS
/// middleware. On a host where that header is missing, every photograph in the
/// gallery would silently fail. [WebHtmlElementStrategy.fallback] keeps the
/// byte path (and therefore `cacheWidth`) when the header is present, and drops
/// to a plain `<img>` element when it is not.
///
/// The header is still the right answer, and the deployment checklist asks for
/// it; this is what stops a missing one from emptying the gallery.
class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.loading,
    this.error,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// The widest this image will be drawn, in **device** pixels.
  final int? cacheWidth;

  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context)? error;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: loading == null
          ? null
          : (context, child, progress) =>
                progress == null ? child : loading!(context),
      errorBuilder: error == null ? null : (context, _, _) => error!(context),
    );
  }
}
