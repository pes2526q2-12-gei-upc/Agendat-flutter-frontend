/// URL base de l'API del backend. Canvia-la segons l'entorn (local, staging, producció).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  // Android emulator: el host (el teu PC) és 10.0.2.2
  defaultValue: 'http://10.0.2.2:8000',
);
