import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Curriculum scelto dal candidato, pronto per l'upload.
class PickedCv {
  final String fileName;
  final Uint8List bytes;

  const PickedCv(this.fileName, this.bytes);

  int get size => bytes.length;
}

/// Astrazione sul selettore di file: consente di sostituirlo nei test.
abstract class CvPicker {
  Future<PickedCv?> pickPdf();
}

/// Implementazione reale: selettore di file di sistema, solo PDF.
class FilePickerCvPicker implements CvPicker {
  @override
  Future<PickedCv?> pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      dialogTitle: 'Scegli il curriculum (PDF)',
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    return PickedCv(file.name, bytes);
  }
}
