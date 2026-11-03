import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<PickedPhoto?> takePhoto() => _pick(ImageSource.camera);

  Future<PickedPhoto?> pickFromGallery() => _pick(ImageSource.gallery);

  // Android puede matar la actividad al abrir la cámara (por memoria o por
  // permisos de ubicación de una sola vez). image_picker guarda el archivo y
  // lo devuelve aquí al reabrir el reporte.
  Future<PickedPhoto?> retrieveLostPhoto() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty || response.files == null) return null;
      final file = response.files!.first;
      final bytes = await file.readAsBytes();
      final name = file.name.trim().isEmpty ? 'bache.jpg' : file.name;
      return PickedPhoto(bytes: bytes, name: name);
    } on Exception {
      return null;
    }
  }

  Future<PickedPhoto?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final name = file.name.trim().isEmpty ? 'bache.jpg' : file.name;
    return PickedPhoto(bytes: bytes, name: name);
  }
}
