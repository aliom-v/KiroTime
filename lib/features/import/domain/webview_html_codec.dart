import 'dart:convert';

class WebViewHtmlCodec {
  WebViewHtmlCodec._();

  static String? decodeHtml(Object? result) {
    final decoded = decodeJson(result);
    if (decoded is Map) {
      return _html(decoded['currentHtml'] ?? decoded['html']);
    }
    return _html(decoded);
  }

  static Object? decodeJson(Object? result) {
    if (result == null) {
      return null;
    }
    if (result is! String) {
      return result;
    }

    Object? value = result.trim();
    for (var depth = 0; depth < 4; depth++) {
      if (value is! String) {
        return value;
      }
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      try {
        value = jsonDecode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }
    return value;
  }

  static String? _html(Object? value) {
    if (value is! String) {
      return null;
    }
    final html = value.trim();
    return _looksLikeHtml(html) ? html : null;
  }

  static bool _looksLikeHtml(String value) {
    final normalized = value.trimLeft().toLowerCase();
    return normalized.startsWith('<') ||
        normalized.contains('<html') ||
        normalized.contains('<body') ||
        normalized.contains('<table') ||
        normalized.contains('<div') ||
        normalized.contains('<td');
  }
}
