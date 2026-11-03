# Google sign-in setup

The backend verifies Google ID tokens. It never receives or stores Google
passwords.

## 1. Google Cloud project

1. Create a project in the [Google Cloud Console](https://console.cloud.google.com/).
2. Configure **Google Auth Platform / OAuth consent screen**:
   - App name: `Tízibaches`.
   - User support email and developer contact.
   - Audience: `External`. While the app is in `Testing`, add every Gmail
     account used on the test phone as a **test user**. Otherwise Google blocks
     the consent with `Access blocked`.
   - Scopes: only `openid`, `email` and `profile` are needed. They are
     non-sensitive, so no verification review is required.
3. Create the OAuth clients:
   - **Web application**: its client ID is the token audience the backend
     verifies. It is also the `serverClientId` used by Flutter. This is the ID
     that goes in `GOOGLE_CLIENT_IDS`.
   - **Android**: package `mx.tizimin.baches` and the SHA-1 fingerprint of the
     signing key. The debug APK currently uses:

     ```text
     <debug-sha1>
     ```

     For a release build, register the SHA-1 of the release/Play signing key
     instead.

The **client secret is not used or required** for this ID-token flow. Do not put
it in Flutter, the APK or the repository. If the backend later exchanges an
authorization code, the secret belongs only in the backend environment.

## 2. Backend configuration

Add the Web client ID to `.env`:

```dotenv
GOOGLE_CLIENT_IDS=1234567890-abc.apps.googleusercontent.com
```

Multiple audiences can be comma-separated if the Android client issues tokens
directly.

The endpoint is:

```
POST /api/auth/google/
Content-Type: application/json

{"id_token": "<token from google_sign_in>"}
```

The response contains `access`, `refresh` and the user profile. The access token
is sent as `Authorization: Bearer <token>`.

The backend checks:

- the token signature and expiration;
- the audience against `GOOGLE_CLIENT_IDS`;
- `email_verified`;
- the stable `sub` claim, which is stored in `User.google_sub`.

An existing account with the same verified email is linked only once. If that
email already belongs to a different Google account, the API returns `409`.

## 3. Flutter

Use the Web client ID as `serverClientId`:

```bash
cd app
flutter run -d <android-device> \
  --dart-define=API_BASE_URL=http://<laptop-lan-ip>:3000 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
```

After `authenticate()`, read `authentication.idToken` and send it to
`/api/auth/google/`. Store the returned tokens in secure storage.

Local API URLs:

- Android emulator: `http://10.0.2.2:3000`
- Physical phone on the same Wi-Fi: `http://<laptop-lan-ip>:3000`
- USB alternative: `adb reverse tcp:3000 tcp:3000` and use
  `http://127.0.0.1:3000`

## Common Google errors

- `Access blocked`: the signed-in Gmail is not a test user while the consent
  screen is in `Testing`, or the OAuth app is not published.
- `An error occurred` / `Account reauth failed`: the Google account needs to be
  reauthenticated on the phone, or a stale account was selected. Remove and add
  the account again, or test with a different account that is registered.
- `invalid audience`: the backend `GOOGLE_CLIENT_IDS` does not contain the Web
  client ID used by Flutter.
- `28444 Developer console is not set up correctly`: the `serverClientId`
  is the Android client, or the Android OAuth client does not match the
  package/SHA-1. Use the **Web application** ID in `GOOGLE_WEB_CLIENT_ID`
  and the Android ID only in `GOOGLE_ANDROID_CLIENT_ID`.
- `Falta GOOGLE_WEB_CLIENT_ID`: run `make app-config` after filling the
  Web client ID in `.env`; the generated config never contains
  `GOOGLE_SECRET`.
- `Falta configurar el client ID...`: the APK was built without
  `--dart-define=GOOGLE_SERVER_CLIENT_ID`.

## Testing

Automated tests mock `google.oauth2.id_token.verify_oauth2_token`. A real login
test requires Google Cloud credentials and is performed manually after the
Flutter app is configured.
