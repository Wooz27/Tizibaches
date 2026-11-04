from rest_framework.throttling import UserRateThrottle


class ReportCreateThrottle(UserRateThrottle):
    scope = "report_create"
