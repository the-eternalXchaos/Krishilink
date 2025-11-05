class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? title;

  AppException(this.message, {this.statusCode, this.title});

  @override
  String toString() {
    final msg = message.trim();
    final code = statusCode != null ? ' (Status Code: $statusCode)' : '';
    // Keep toString concise and backward-compatible; callers that want a title
    // should use the 'title' field explicitly when available.
    return msg + code;
  }
}
