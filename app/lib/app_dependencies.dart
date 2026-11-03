import 'data/repositories/auth_repository.dart';
import 'data/repositories/pothole_repository.dart';
import 'data/repositories/report_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/google_auth_service.dart';
import 'data/services/location_service.dart';
import 'data/services/photo_service.dart';
import 'data/services/session_store.dart';
import 'ui/features/auth/view_models/auth_controller.dart';
import 'ui/features/map/view_models/map_view_model.dart';
import 'ui/features/report/view_models/report_controller.dart';
import 'ui/features/reports/view_models/my_reports_view_model.dart';

class AppDependencies {
  AppDependencies._({
    required this.api,
    required this.authRepository,
    required this.authController,
    required this.mapViewModel,
    required this.myReportsViewModel,
    required this.reportRepository,
    required this.locationService,
    required this.photoService,
  });

  final ApiService api;
  final AuthRepository authRepository;
  final AuthController authController;
  final MapViewModel mapViewModel;
  final MyReportsViewModel myReportsViewModel;
  final ReportRepository reportRepository;
  final LocationService locationService;
  final PhotoService photoService;

  factory AppDependencies.create() {
    final api = ApiService();
    final sessionStore = SessionStore();
    final googleAuth = GoogleAuthService();
    final authRepository = AuthRepository(
      api: api,
      store: sessionStore,
      google: googleAuth,
    );
    final authController = AuthController(repository: authRepository);
    final potholeRepository = PotholeRepository(api: api);
    final reportRepository = ReportRepository(api: api, auth: authRepository);

    return AppDependencies._(
      api: api,
      authRepository: authRepository,
      authController: authController,
      mapViewModel: MapViewModel(repository: potholeRepository),
      myReportsViewModel: MyReportsViewModel(repository: reportRepository),
      reportRepository: reportRepository,
      locationService: LocationService(),
      photoService: PhotoService(),
    );
  }

  ReportController createReportController() {
    return ReportController(
      repository: reportRepository,
      locationService: locationService,
      photoService: photoService,
    );
  }
}
