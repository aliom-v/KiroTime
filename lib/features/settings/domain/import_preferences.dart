enum UserAgentMode { mobile, desktop, custom }

class SavedAcademicUrl {
  const SavedAcademicUrl({required this.name, required this.url});

  final String name;
  final String url;

  String get displayName {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    final uri = Uri.tryParse(url);
    return uri != null && uri.host.isNotEmpty ? uri.host : url;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'name': name, 'url': url};

  factory SavedAcademicUrl.fromJson(Map<String, dynamic> json) {
    return SavedAcademicUrl(
      name: json['name'] is String ? json['name'] as String : '',
      url: json['url'] is String ? json['url'] as String : '',
    );
  }
}

class ImportPreferences {
  const ImportPreferences({
    required this.academicSystemUrl,
    required this.semesterApiPath,
    required this.userAgentMode,
    required this.customUserAgent,
    required this.keepWebViewLoginState,
    required this.keepHtmlDiagnostics,
    this.savedAcademicUrlBookmarks = const <SavedAcademicUrl>[],
  });

  static const String mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0 Mobile Safari/537.36';

  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0 Safari/537.36';

  /// 用户固定的常用网址（导入页快捷选择 + 设置中管理）。
  final List<SavedAcademicUrl> savedAcademicUrlBookmarks;

  List<String> get savedAcademicUrls => savedAcademicUrlBookmarks
      .map((bookmark) => bookmark.url)
      .toList(growable: false);

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
      userAgentMode: UserAgentMode.desktop,
      customUserAgent: '',
      keepWebViewLoginState: true,
      keepHtmlDiagnostics: false,
    );
  }

  factory ImportPreferences.fromJson(Map<String, dynamic> json) {
    final fallback = ImportPreferences.defaults();
    return ImportPreferences(
      academicSystemUrl:
          normalizeAcademicHttpsUrl(
            _stringValue(json['academicSystemUrl'], ''),
          ) ??
          fallback.academicSystemUrl,
      savedAcademicUrlBookmarks: _decodeSavedAcademicUrls(
        json['savedAcademicUrls'],
      ),
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
      'savedAcademicUrls': savedAcademicUrlBookmarks
          .map((bookmark) => bookmark.toJson())
          .toList(growable: false),
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
    List<SavedAcademicUrl>? savedAcademicUrlBookmarks,
    String? semesterApiPath,
    UserAgentMode? userAgentMode,
    String? customUserAgent,
    bool? keepWebViewLoginState,
    bool? keepHtmlDiagnostics,
  }) {
    return ImportPreferences(
      academicSystemUrl: academicSystemUrl == null
          ? this.academicSystemUrl
          : normalizeAcademicHttpsUrl(academicSystemUrl) ?? '',
      savedAcademicUrlBookmarks: _decodeSavedAcademicUrls(
        savedAcademicUrlBookmarks ??
            (savedAcademicUrls ?? this.savedAcademicUrlBookmarks),
      ),
      semesterApiPath: semesterApiPath ?? this.semesterApiPath,
      userAgentMode: userAgentMode ?? this.userAgentMode,
      customUserAgent: customUserAgent ?? this.customUserAgent,
      keepWebViewLoginState:
          keepWebViewLoginState ?? this.keepWebViewLoginState,
      keepHtmlDiagnostics: keepHtmlDiagnostics ?? this.keepHtmlDiagnostics,
    );
  }
}

List<SavedAcademicUrl> _decodeSavedAcademicUrls(Object? rawValue) {
  if (rawValue is! List) {
    return const <SavedAcademicUrl>[];
  }
  final bookmarks = <SavedAcademicUrl>[];
  final normalizedUrls = <String>{};
  for (final item in rawValue) {
    final bookmark = switch (item) {
      SavedAcademicUrl value => value,
      String value => SavedAcademicUrl(name: '', url: value),
      Map value => SavedAcademicUrl.fromJson(
        value.map((key, value) => MapEntry(key.toString(), value)),
      ),
      _ => null,
    };
    if (bookmark == null) {
      continue;
    }
    final normalizedUrl = normalizeAcademicHttpsUrl(bookmark.url);
    if (normalizedUrl == null || !normalizedUrls.add(normalizedUrl)) {
      continue;
    }
    bookmarks.add(
      SavedAcademicUrl(name: bookmark.name.trim(), url: normalizedUrl),
    );
  }
  return List<SavedAcademicUrl>.unmodifiable(bookmarks);
}

String? normalizeAcademicHttpsUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final candidate = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(candidate);
  if (uri == null ||
      uri.host.isEmpty ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri.hasFragment
      ? candidate.substring(0, candidate.indexOf('#'))
      : candidate;
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
