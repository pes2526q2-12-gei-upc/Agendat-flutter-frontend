# Android Push Notification Setup

This guide explains how to test Android push notification registration for the Flutter app.

The backend is working as designed if `/api/notifications/test/` returns a
skipped notification with no active device tokens, for example:

```json
{
  "status": "skipped",
  "delivery_summary": {
    "reason": "no_active_device_tokens"
  }
}
```

That response means the logged-in user has no registered Firebase Cloud Messaging device token yet. The frontend must obtain a real FCM token from the Android device and register it with the backend before the backend can send a test push notification.

The current goal is to verify that the app can:

- initialize Firebase Messaging;
- request notification permission;
- obtain an FCM token;
- register that token with the backend at `/api/notifications/devices/`.

This does not cover sending a visible push notification yet.

## 1. Firebase Android App

Use the same Firebase project that the backend uses. Inside that project, add an Android app for this Flutter app.

Android package name:

```text
com.example.agendat
```

Download the Android Firebase config file and place it here:

```text
android/app/google-services.json
```

Check that the file exists:

```powershell
Test-Path .\android\app\google-services.json
```

Expected result:

```text
True
```

Do not commit real Firebase config files if the team policy treats them as private.

The Gradle configuration is already prepared to apply the Google services plugin when `android/app/google-services.json` exists.

## 2. Android Device Setup

### Emulator

The emulator can use the default backend URL configured in the app:

```text
http://10.0.2.2:8080
```

Run:

```powershell
flutter run -d emulator-5554
```

### Physical Android Phone

Enable Developer options and USB debugging on the phone.

For Xiaomi, Redmi, or POCO phones, also enable these options if present:

- `Install via USB`
- `USB debugging (Security settings)`

Then connect the phone by USB and verify Flutter detects it:

```powershell
flutter devices
```

Run the app using the device id:

```powershell
flutter run -d <device-id>
```

Example:

```powershell
flutter run -d b2cc68b5
```

If the backend is running in Docker on your PC and publishes port `8080`, use
USB port forwarding instead of the PC's changing Wi-Fi IP:

```powershell
.\scripts\run_android_docker.ps1 -DeviceId <device-id>
```

Example:

```powershell
.\scripts\run_android_docker.ps1 -DeviceId b2cc68b5
```

This runs:

```powershell
adb -s <device-id> reverse tcp:8080 tcp:8080
flutter run -d <device-id> --dart-define=USE_ADB_REVERSE=true
```

With `USE_ADB_REVERSE=true`, the app uses:

```text
http://127.0.0.1:8080
```

from the phone, and ADB forwards that request to port `8080` on your PC, where
Docker exposes the backend.

If install fails with `INSTALL_FAILED_USER_RESTRICTED`, the phone is blocking USB installs. Re-check Xiaomi developer settings, unplug/replug the phone, and accept any USB debugging prompts.

## 3. Backend URL

For the Android emulator, the app can reach the local backend through:

```text
http://10.0.2.2:8080
```

For a physical phone, use the PC LAN IP instead.

Recommended for USB debugging with Docker:

```powershell
.\scripts\run_android_docker.ps1 -DeviceId <device-id>
```

Use this when your backend container is reachable on the PC at:

```text
http://localhost:8080
```

The script sets up `adb reverse` and starts Flutter with
`--dart-define=USE_ADB_REVERSE=true`, so no LAN IP is needed.

Alternative over Wi-Fi:

Find the PC IP:

```powershell
ipconfig
```

Use the IPv4 address from the active Wi-Fi or Ethernet adapter. Example:

```text
192.168.68.110
```

Start the backend so it listens on the network, not only on `localhost`.

For Django:

```powershell
python manage.py runserver 0.0.0.0:8080
```

Then run Flutter with:

```powershell
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<PC-IP>:8080
```

Example:

```powershell
flutter run -d b2cc68b5 --dart-define=API_BASE_URL=http://192.168.68.110:8080
```

Before testing login in the app, open this URL in the phone browser:

```text
http://<PC-IP>:8080
```

If the phone browser cannot reach the backend, the app login will show a network error. Check that both devices are on the same network and that Windows Firewall allows port `8080` on private networks.

## 4. Expected App Logs

After logging in, watch the `flutter run` console for logs beginning with:

```text
[PushNotifications]
```

A successful registration should include:

```text
[PushNotifications] Firebase initialized on android
[PushNotifications] notification permission status: authorized
[PushNotifications] FCM token obtained (length ...)
[PushNotifications] DEBUG FCM token for Swagger/curl: <fcm-token>
[PushNotifications] device token registered as backend device ...
```

The full FCM token is printed only in Flutter debug builds so it can be copied
into Swagger or curl during local troubleshooting. The backend login/auth token
must not be printed in app logs.

The backend should receive:

```http
POST /api/notifications/devices/
```

With headers:

```http
Authorization: Token <backend_login_token>
Content-Type: application/json
```

And a JSON body containing:

```json
{
  "token": "<fcm-token>",
  "platform": "android"
}
```

The app already attempts this after a successful login and after restoring an existing session.

It also listens to Firebase token refresh events and re-sends refreshed tokens to the same backend endpoint.

## 5. Backend Test Flow

After logging in from the app, confirm the backend returned a DRF auth token and the app registered the FCM token.

Confirm the device exists:

```http
GET /api/notifications/devices/
Authorization: Token <backend_login_token>
```

Expected result: at least one active token for the authenticated user.

`GET /api/notifications/devices/` lists only active tokens for the current
authenticated user. If Swagger is using no token, a raw token without the
`Token ` prefix, a session cookie for another user, or a token for a different
user than the app login, the response can still be `[]`.

In Swagger, click **Authorize** and use the `TokenAuth` value:

```text
Token <backend_login_token>
```

Do not paste only the raw token if Swagger says to use
`Token <your_token>`.

### Manual Swagger/Curl Device Registration

The app already attempts device registration after successful login and after
restoring an existing session. If the app log shows an FCM token but
`GET /api/notifications/devices/` still returns `[]`, manually replay the
registration with the debug FCM token from the Flutter console.

Use:

```http
POST /api/notifications/devices/
Authorization: Token <backend_login_token>
Content-Type: application/json
```

Body:

```json
{
  "token": "<fcm-token-from-flutter-debug-log>",
  "platform": "android"
}
```

The backend may create a new device token or reactivate an existing matching
token. After the POST succeeds, run:

```http
GET /api/notifications/devices/
Authorization: Token <backend_login_token>
```

Expected result: the list contains one active Android device for that user.

Then call:

```http
POST /api/notifications/test/
```

Example body:

```json
{
  "channel": "push",
  "title": "Agenda't test notification",
  "body": "This is a test notification from Agenda't.",
  "data": {
    "name": "Alex",
    "age": 28,
    "active": true
  }
}
```

Expected result:

```json
{
  "status": "sent"
}
```

If `/api/notifications/test/` returns `400 no_active_device_tokens` or a skipped
notification with `delivery_summary.reason` set to `no_active_device_tokens`,
the currently authenticated backend user has no active FCM token.

If it returns `502` with Firebase errors, the token exists but Firebase rejected delivery. The most common cause is that the mobile app and backend credentials are from different Firebase projects.

## 6. Troubleshooting

### `Firebase initialization failed`

Check that `android/app/google-services.json` exists and was created for package name:

```text
com.example.agendat
```

### `Error de xarxa` on login

The app cannot reach the backend.

- Emulator: confirm the backend is running on the PC at port `8080`.
- Physical phone over USB with Docker: run `.\scripts\run_android_docker.ps1 -DeviceId <device-id>`.
- Physical phone over Wi-Fi: run with `--dart-define=API_BASE_URL=http://<PC-IP>:8080`.
- Confirm Docker publishes the backend on the PC at `http://localhost:8080`.
- Confirm the phone browser can open `http://<PC-IP>:8080`.
- Check Windows Firewall.

### `notification permission denied`

The user denied Android notification permission. Enable notifications for the app from Android settings, or reinstall the app and allow permission when prompted.

### `save token failed`

Firebase returned an FCM token, but the backend registration failed.

Check:

- the user is logged in;
- the backend is reachable;
- the backend accepts `POST /api/notifications/devices/`;
- the backend response status matches the app expectation, currently HTTP `201`.
- the backend and Android app use the same Firebase project.

### Logout Test

On logout, the app should call:

```http
DELETE /api/notifications/devices/<device-id>/
```

The local stored notification device id should then be cleared.
