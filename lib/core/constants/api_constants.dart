class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.36.128.125:8000/api';
  static const String loginPath = '/login';
  static const String logoutPath = '/logout';
  static const String mePath = '/me';
  static const String attendances = '$baseUrl/attendances';
  static const String visits = '$baseUrl/visits';
  static const String reimbursements = '$baseUrl/reimbursements';
  static const String timesheets = '$baseUrl/timesheets';
  static const String leaves = '$baseUrl/leaves';

  static String fileUrl(String path) {
    if (path.startsWith('http:') || path.startsWith('https:')) {
      return path;
    }
    final parts = path
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    final base = Uri.parse(baseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : 80,
      pathSegments: ['storage', ...parts],
    ).toString();
  }

  static bool isLocalFilePath(String path) {
    if (path.startsWith('/')) {
      return true;
    }
    return RegExp(r'^[A-Za-z]:').hasMatch(path) || path.contains('\\');
  }
}
