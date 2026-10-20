import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Pipeline de imagem do README: foto no celular (4MB+) → compressão local
/// (~1200px, JPEG 78%) → upload multipart. O servidor ainda gera as variantes
/// thumb/card/full.
class ImagePickerHelper {
  const ImagePickerHelper();

  /// Abre a câmera/galeria, comprime e devolve o arquivo pronto para upload.
  /// Retorna null quando o usuário cancela.
  Future<File?> pickAndCompress({required ImageSource source}) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 78,
    );
    if (picked == null) return null;

    try {
      final original = await File(picked.path).readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        original,
        quality: 78,
        format: CompressFormat.jpeg,
      );

      final tmpDir = await Directory.systemTemp.createTemp('freshbox_upload');
      final file = File(
          '${tmpDir.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(compressed);
      return file;
    } catch (_) {
      // Compressão falhou (plugin indisponível em testes, por ex.) — usa o
      // arquivo original; o validador do servidor ainda cobre extensão/tamanho.
      return File(picked.path);
    }
  }
}
