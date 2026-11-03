import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../data/repositories/report_repository.dart';
import '../../../../data/services/location_service.dart';
import '../../../../data/services/photo_service.dart';
import '../../../../domain/models/failures.dart';
import '../../../../domain/models/report.dart';

class ReportController extends ChangeNotifier {
  ReportController({
    required ReportRepository repository,
    required LocationService locationService,
    required PhotoService photoService,
  }) : _repository = repository,
       _locationService = locationService,
       _photoService = photoService;

  final ReportRepository _repository;
  final LocationService _locationService;
  final PhotoService _photoService;

  PickedPhoto? _photo;
  LocatedPoint? _location;
  int _severity = 2;
  String _description = '';
  bool _locating = false;
  bool _submitting = false;
  String? _error;
  bool _approximate = false;
  ReportSubmission? _result;

  PickedPhoto? get photo => _photo;
  LocatedPoint? get location => _location;
  int get severity => _severity;
  String get description => _description;
  bool get locating => _locating;
  bool get submitting => _submitting;
  String? get error => _error;
  bool get approximate => _approximate;
  ReportSubmission? get result => _result;
  bool get canSubmit =>
      _photo != null && _location != null && !_submitting && !_locating;

  Future<void> takePhoto() => _pickPhoto(camera: true);

  Future<void> pickPhoto() => _pickPhoto(camera: false);

  Future<void> recoverLostPhoto() async {
    if (_photo != null) return;
    final picked = await _photoService.retrieveLostPhoto();
    if (picked == null) return;
    _photo = picked;
    notifyListeners();
  }

  Future<void> _pickPhoto({required bool camera}) async {
    _error = null;
    notifyListeners();
    try {
      final picked = camera
          ? await _photoService.takePhoto()
          : await _photoService.pickFromGallery();
      if (picked != null) {
        _photo = picked;
        notifyListeners();
      }
    } on Exception {
      _error = 'No pudimos abrir la cámara. Prueba con la galería.';
      notifyListeners();
    }
  }

  void clearPhoto() {
    _photo = null;
    notifyListeners();
  }

  Future<void> locate() async {
    if (_locating) return;
    _locating = true;
    _error = null;
    notifyListeners();

    try {
      _location = await _locationService.locate();
      _approximate = false;
    } on AppFailure catch (failure) {
      _error = failure.message;
    } on Exception {
      _error = 'No pudimos obtener tu ubicación.';
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  void useCityCenter() {
    _location = const LocatedPoint(
      latitude: AppConfig.cityLat,
      longitude: AppConfig.cityLon,
    );
    _approximate = true;
    _error = null;
    notifyListeners();
  }

  void setSeverity(int value) {
    _severity = value.clamp(1, 4);
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
  }

  Future<bool> submit() async {
    if (_submitting) return false;
    final photo = _photo;
    final location = _location;

    if (photo == null) {
      _error = 'Agregá una foto del bache para continuar.';
      notifyListeners();
      return false;
    }
    if (location == null) {
      _error = 'Marca la ubicación del bache para continuar.';
      notifyListeners();
      return false;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.create(
        ReportDraft(
          latitude: location.latitude,
          longitude: location.longitude,
          severity: _severity,
          photoBytes: photo.bytes,
          photoName: photo.name,
          description: _description,
          approximateLocation: _approximate,
        ),
      );
      return true;
    } on AppFailure catch (failure) {
      _error = failure.message;
      return false;
    } on Exception {
      _error = 'No pudimos enviar el reporte. Intentá de nuevo.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void reset() {
    _photo = null;
    _location = null;
    _severity = 2;
    _description = '';
    _locating = false;
    _submitting = false;
    _error = null;
    _approximate = false;
    _result = null;
    notifyListeners();
  }
}
