import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import/domain/webview_html_codec.dart';

void main() {
  test('ignores empty json arrays instead of treating them as html', () {
    expect(WebViewHtmlCodec.decodeHtml('[]'), isNull);
  });

  test('decodes current html from object payloads', () {
    final payload = jsonEncode(<String, Object>{
      'currentHtml': '<html><body>当前页面</body></html>',
    });

    expect(
      WebViewHtmlCodec.decodeHtml(payload),
      '<html><body>当前页面</body></html>',
    );
  });

  test('decodes json object results for WebView API payloads', () {
    final payload = jsonEncode(<String, Object>{
      'ok': true,
      'payload': <String, Object>{'kbList': <Object>[], 'sjkList': <Object>[]},
    });

    final decoded = WebViewHtmlCodec.decodeJson(payload);

    expect(decoded, isA<Map>());
    final map = decoded! as Map;
    expect(map['ok'], isTrue);
    expect(map['payload'], isA<Map>());
  });

  test('decodes raw and json encoded html strings', () {
    expect(
      WebViewHtmlCodec.decodeHtml('<html><body>课表</body></html>'),
      '<html><body>课表</body></html>',
    );
    expect(
      WebViewHtmlCodec.decodeHtml(jsonEncode('<html><body>课表</body></html>')),
      '<html><body>课表</body></html>',
    );
  });

  test('decodes double encoded WebView string results', () {
    final html = '<html><body>双层编码课表</body></html>';
    final doubleEncoded = jsonEncode(jsonEncode(html));

    expect(WebViewHtmlCodec.decodeHtml(doubleEncoded), html);
  });
}
