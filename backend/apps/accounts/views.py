from rest_framework import status
from rest_framework.generics import RetrieveAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.google import InvalidGoogleToken, verify_google_id_token
from apps.accounts.serializers import GoogleLoginSerializer, UserSerializer
from apps.accounts.services import GoogleAccountConflict, get_or_create_user_from_google


class GoogleLoginView(APIView):
    # Intercambia un ID token de Google por tokens de acceso y refresco.

    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        serializer = GoogleLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            claims = verify_google_id_token(serializer.validated_data["id_token"])
            user = get_or_create_user_from_google(claims)
        except InvalidGoogleToken as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_401_UNAUTHORIZED)
        except GoogleAccountConflict as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_409_CONFLICT)

        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": UserSerializer(user).data,
            }
        )


class LogoutView(APIView):
    # Revoca el refresh token para que no pueda reutilizarse después del logout.

    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        raw_refresh = request.data.get("refresh")
        if not raw_refresh:
            return Response(
                {"detail": "Falta el refresh token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            RefreshToken(raw_refresh).blacklist()
        except TokenError:
            return Response(
                {"detail": "El refresh token no es válido."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(status=status.HTTP_204_NO_CONTENT)


class MeView(RetrieveAPIView):
    # Devuelve el usuario autenticado.

    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user
