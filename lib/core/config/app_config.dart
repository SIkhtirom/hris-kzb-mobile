import '../constants/api_constants.dart';

class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = ApiConstants.baseUrl;

  static bool get useMockBackend => apiBaseUrl.isEmpty;

  static bool allowRepeatCheckIn = false;

  static bool allowEarlyCheckOut = false;
}
