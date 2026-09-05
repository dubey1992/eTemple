import 'picked_file.dart';

/// Non-web stub. See `file_chooser.dart`.
class FileChooser {
  const FileChooser();

  /// No-op: there is no browser to open a chooser in.
  ///
  /// Returning null rather than throwing keeps every widget that offers an
  /// upload pumpable in a test; what the upload does with a file is tested
  /// through the repository instead.
  Future<PickedFile?> pickImage({List<String> accept = const []}) async => null;

  /// The same. See [pickImage].
  Future<PickedFile?> pickFile({List<String> accept = const []}) async => null;

  bool get isSupported => false;
}
