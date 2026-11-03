import 'package:flutter/foundation.dart';

import '../../../../data/repositories/pothole_repository.dart';
import '../../../../domain/models/failures.dart';
import '../../../../domain/models/pothole.dart';
import '../../../../domain/models/pothole_status.dart';

class MapViewModel extends ChangeNotifier {
  MapViewModel({required PotholeRepository repository})
    : _repository = repository;

  final PotholeRepository _repository;

  List<Pothole> _all = const [];
  PotholeStatus? _filter;
  String _query = '';
  Pothole? _selected;
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  PotholeStatus? get filter => _filter;
  String get query => _query;
  Pothole? get selected => _selected;
  List<Pothole> get all => _all;

  List<Pothole> get visible {
    final needle = _query.trim().toLowerCase();
    final items = _all.where((pothole) {
      if (_filter != null && pothole.status != _filter) return false;
      if (needle.isEmpty) return true;
      return pothole.displayAddress.toLowerCase().contains(needle) ||
          pothole.id.toString().contains(needle) ||
          pothole.status.label.toLowerCase().contains(needle);
    }).toList();

    items.sort((a, b) {
      final aDate = a.lastReportedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastReportedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return items;
  }

  int get total => _all.length;

  int countFor(PotholeStatus status) =>
      _all.where((pothole) => pothole.status == status).length;

  bool get hasActiveFilter => _filter != null || _query.trim().isNotEmpty;

  Future<void> load({bool showLoader = true}) async {
    if (_loading) return;
    if (showLoader) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final loaded = await _repository.fetchAll();
      _all = loaded;
      if (_selected != null) {
        _selected = _findById(loaded, _selected!.id);
      }
      _error = null;
    } on AppFailure catch (failure) {
      _error = failure.message;
      if (kDebugMode) debugPrint('No se pudieron cargar los baches: $failure');
    } on Exception {
      _error = 'No pudimos cargar los expedientes.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(showLoader: false);

  void setFilter(PotholeStatus? status) {
    _filter = status;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void clearFilters() {
    _filter = null;
    _query = '';
    notifyListeners();
  }

  void select(Pothole? pothole) {
    _selected = pothole;
    notifyListeners();
  }

  void syncSelectedFromList() {
    final current = _selected;
    if (current == null) return;
    _selected = _findById(_all, current.id);
    notifyListeners();
  }

  Pothole? _findById(List<Pothole> items, int id) {
    for (final pothole in items) {
      if (pothole.id == id) return pothole;
    }
    return null;
  }
}
