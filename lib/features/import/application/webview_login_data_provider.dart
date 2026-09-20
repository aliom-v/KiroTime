import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef ClearWebViewLoginData = Future<void> Function();

final clearWebViewLoginDataProvider = Provider<ClearWebViewLoginData>((ref) {
  return () async {
    final cookieManager = WebViewCookieManager();
    final controller = WebViewController();
    await cookieManager.clearCookies();
    await controller.clearCache();
    await controller.clearLocalStorage();
  };
});
