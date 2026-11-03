import 'package:geolocator/geolocator.dart';

import '../../domain/models/failures.dart';

class LocatedPoint {
  const LocatedPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationService {
  Future<LocatedPoint> locate() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const AppFailure(
        'Encendé la ubicación del teléfono para marcar el bache.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppFailure(
        'Necesitamos tu ubicación para registrar el bache en la calle correcta.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppFailure(
        'La ubicación está bloqueada. Habilitala en los ajustes de Android.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocatedPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on Exception {
      throw const AppFailure(
        'No pudimos obtener tu ubicación. Sal a un espacio abierto e intenta de nuevo.',
      );
    }
  }
}
