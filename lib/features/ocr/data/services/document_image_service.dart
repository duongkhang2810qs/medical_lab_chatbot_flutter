import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

class DocumentImageService {
  DocumentImageService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<String?> scanDocument() async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.base,
        pageLimit: 1,
        isGalleryImport: false,
      ),
    );

    try {
      final result = await scanner.scanDocument();
      if (result == null || result.images.isEmpty) return null;
      return _normalizeFilePath(result.images.first);
    } finally {
      scanner.close();
    }
  }

  Future<String?> pickFromGallery() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  String _normalizeFilePath(String path) {
    return path.startsWith('file://') ? path.replaceFirst('file://', '') : path;
  }
}
