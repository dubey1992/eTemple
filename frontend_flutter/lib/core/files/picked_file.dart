import 'dart:typed_data';

/// A file the visitor chose in their browser, read into memory.
///
/// Bytes rather than a path: on the web there is no filesystem path to hand to
/// an upload, and the picked file is only ever read, never stored locally.
class PickedFile {
  const PickedFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;

  /// What the browser said the file is. Sent onward for completeness and
  /// ignored by the server, which detects the type from the bytes itself.
  final String mimeType;

  int get byteSize => bytes.length;
}
