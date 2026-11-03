from rest_framework.routers import DefaultRouter

from apps.reports.views import PotholeViewSet, ReportViewSet

router = DefaultRouter()
router.register("potholes", PotholeViewSet, basename="pothole")
router.register("reports", ReportViewSet, basename="report")

urlpatterns = router.urls
