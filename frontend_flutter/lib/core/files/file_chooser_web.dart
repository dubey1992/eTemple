import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'picked_file.dart';

/// Web implementation. See `file_chooser.dart`.
class FileChooser {
  const FileChooser();

  /// Opens the browser's file chooser and reads the chosen file into memory.
  ///
  /// [accept] populates the input's `accept` attribute, which filters what the
  /// chooser offers. It is a convenience for the person picking and nothing
  /// more — the server validates the bytes it receives regardless, because an
  /// attribute in a page is not a check.
  Future<PickedFile?> pickImage({
    List<String> accept = const ['image/jpeg', 'image/png', 'image/webp'],
  }) => pickFile(accept: accept);

  /// The same, for anything the browser can hand over — a bill may be a PDF.
  Future<PickedFile?> pickFile({
    List<String> accept = const ['image/jpeg', 'image/png', 'image/webp'],
  }) {
    final completer = Completer<PickedFile?>();

    final input = web.document.createElement('input') as web.HTMLInputElement
      ..type = 'file'
      ..accept = accept.join(',')
      ..multiple = false;

    // The chooser is modal to the browser, not to us: if the visitor cancels,
    // some browsers fire nothing at all. `cancel` covers the ones that do, and
    // the completer is guarded so whichever arrives first wins.
    void finish(PickedFile? file) {
      if (!completer.isCompleted) completer.complete(file);
    }

    input.onchange = ((web.Event _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        finish(null);
        return;
      }

      final file = files.item(0);
      if (file == null) {
        finish(null);
        return;
      }

      final reader = web.FileReader();
      reader.onload = ((web.Event _) {
        final result = reader.result;
        if (result.isA<JSArrayBuffer>()) {
          final buffer = (result as JSArrayBuffer).toDart;
          finish(
            PickedFile(
              name: file.name,
              bytes: Uint8List.view(buffer),
              mimeType: file.type.isEmpty
                  ? 'application/octet-stream'
                  : file.type,
            ),
          );
        } else {
          finish(null);
        }
      }).toJS;
      reader.onerror = ((web.Event _) => finish(null)).toJS;
      reader.readAsArrayBuffer(file);
    }).toJS;

    input.oncancel = ((web.Event _) => finish(null)).toJS;

    input.click();

    return completer.future;
  }

  bool get isSupported => true;
}
