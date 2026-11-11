from rest_framework.pagination import LimitOffsetPagination


class BoundedLimitOffsetPagination(LimitOffsetPagination):
    # LimitOffsetPagination ignora MAX_PAGE_SIZE: sin max_limit, un
    # ?limit=999999999 serializa la tabla completa en memoria.
    max_limit = 200
