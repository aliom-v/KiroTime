enum UserAgentMode { mobile, desktop, custom }

class ImportPreferences {
  const ImportPreferences({
    required this.academicSystemUrl,
    required this.semesterApiPath,
    required this.userAgentMode,
    required this.customUserAgent,
    required this.keepWebViewLoginState,
    required this.keepHtmlDiagnostics,
    this.savedAcademicUrls = const <String>[],
  });

  static const String mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0 Mobile Safari/537.36';

  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0 Safari/537.36';

  /// 用户固定的常用网址（导入页快捷选择 + 设置中管理）。
  final List<String> savedAcademicUrls;

  final String academicSystemUrl;
  final String semesterApiPath;
  final UserAgentMode userAgentMode;
  final String customUserAgent;
  final bool keepWebViewLoginState;
  final bool keepHtmlDiagnostics;

  String get effectiveUserAgent {
    switch (userAgentMode) {
      case UserAgentMode.mobile:
        return mobileUserAgent;
      case UserAgentMode.desktop:
        return desktopUserAgent;
      case UserAgentMode.custom:
        final trimmed = customUserAgent.trim();
        return trimmed.isEmpty ? mobileUserAgent : trimmed;
    }
  }

  factory ImportPreferences.defaults() {
    return const ImportPreferences(
      academicSystemUrl: '',
      semesterApiPath: '',
      userAgentMode: UserAgentMode.mobile,
      customUserAgent: '',
      keepWebViewLoginState: false,
      keepHtmlDiagnostics: false,
    );
  }

  factory ImportPreferences.fromJson(Map<String, dynamic> json) {
    final fallback = ImportPreferences.defaults();
    return ImportPreferences(
      academicSystemUrl: _stringValue(
        json['academicSystemUrl'],
        fallback.academicSystemUrl,
      ),
      savedAcademicUrls: json['savedAcademicUrls'] is List
          ? (json['savedAcademicUrls'] as List)
                .map((item) => item?.toString() ?? '')
                .where((item) => item.trim().isNotEmpty)
                .toList(growable: false)
          : fallback.savedAcademicUrls,
      semesterApiPath: _stringValue(
        json['semesterApiPath'],
        fallback.semesterApiPath,
      ),
      userAgentMode: _enumFromName(
        UserAgentMode.values,
        json['userAgentMode'],
        fallback.userAgentMode,
      ),
      customUserAgent: _stringValue(
        json['customUserAgent'],
        fallback.customUserAgent,
      ),
      keepWebViewLoginState: _boolValue(
        json['keepWebViewLoginState'],
        fallback.keepWebViewLoginState,
      ),
      keepHtmlDiagnostics: _boolValue(
        json['keepHtmlDiagnostics'],
        fallback.keepHtmlDiagnostics,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'academicSystemUrl': academicSystemUrl,
      'savedAcademicUrls': savedAcademicUrls,
      'semesterApiPath': semesterApiPath,
      'userAgentMode': userAgentMode.name,
      'customUserAgent': customUserAgent,
      'keepWebViewLoginState': keepWebViewLoginState,
      'keepHtmlDiagnostics': keepHtmlDiagnostics,
    };
  }

  ImportPreferences copyWith({
    String? academicSystemUrl,
    List<String>? savedAcademicUrls,
    String? semesterApiPath,
    UserAgentMode? userAgentMode,
    String? customUserAgent,
    bool? keepWebViewLoginState,
    bool? keepHtmlDiagnostics,
  }) {
    return ImportPreferences(
      academicSystemUrl: academicSystemUrl ?? this.academicSystemUrl,
      savedAcademicUrls: savedAcademicUrls ?? this.savedAcademicUrls,
      semesterApiPath: semesterApiPath ?? this.semesterApiPath,
      userAgentMode: userAgentMode ?? this.userAgentMode,
      customUserAgent: customUserAgent ?? this.customUserAgent,
      keepWebViewLoginState:
          keepWebViewLoginState ?? this.keepWebViewLoginState,
      keepHtmlDiagnostics: keepHtmlDiagnostics ?? this.keepHtmlDiagnostics,
    );
  }
}

T _enumFromName<T extends Enum>(List<T> values, Object? rawValue, T fallback) {
  if (rawValue is! String) {
    return fallback;
  }
  for (final value in values) {
    if (value.name == rawValue) {
      return value;
    }
  }
  return fallback;
}

bool _boolValue(Object? rawValue, bool fallback) {
  return rawValue is bool ? rawValue : fallback;
}

String _stringValue(Object? rawValue, String fallback) {
  return rawValue is String ? rawValue : fallback;
}
