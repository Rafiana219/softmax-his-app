import 'dart:ui';

/// Change these to point the app at another system or rename it.
class AppConfig {
  static const appName = 'Softmax HIS';

  /// Short system name shown on the splash and in messages.
  static const systemLabel = 'HIS';
  static const startUrl = 'https://his.softmax-one.com/user/login';

  /// Pages on these domains (and their subdomains) open inside the app.
  /// Everything else (LINE, maps, phone, e-mail...) opens outside.
  static const internalDomains = ['softmax-one.com'];

  /// Shows the bug button and the on-screen log. Off by default (the
  /// version that goes to customers); turn on for a test build with
  ///   flutter build ... --dart-define=SHOW_DEBUG_LOG=true
  /// (codemagic.yaml does this for the iOS Simulator / Appetize build).
  static const showDebugLog = bool.fromEnvironment('SHOW_DEBUG_LOG');

  // Branding shown on the splash screen.
  static const orgNameTh = 'สถาบันสุขภาพเด็กแห่งชาติมหาราชินี';
  static const orgNameEn = 'Queen Sirikit National Institute of Child Health';
  static const poweredBy = 'Powered by Softmax';
  static const logoAsset = 'assets/branding/logo.png';
}

/// Colours taken from the logo.
class BrandColors {
  static const blue = Color(0xFF1C8FD9);
  static const navy = Color(0xFF16325C);
  static const gold = Color(0xFFE2A60F);
  static const goldLight = Color(0xFFE3F1FC); // HIS: light blue top
  static const blueLight = Color(0xFFD9F2EE); // HIS: light teal bottom
}

/// True when [url] should stay inside the app.
bool isInternalUrl(Uri url) {
  if (url.scheme == 'about' || url.scheme == 'data' || url.scheme == 'blob') {
    return true;
  }
  if (url.scheme != 'http' && url.scheme != 'https') return false;
  final host = url.host.toLowerCase();
  return AppConfig.internalDomains.any(
    (d) => host == d || host.endsWith('.$d'),
  );
}

/// Android WebView adds "; wv" to its user agent, and some sites
/// (and Google sign-in) treat that as "not a real browser". Removing it
/// makes the app identify itself exactly like Chrome on the phone.
String chromeUserAgent(String webViewUserAgent) => webViewUserAgent
    .replaceAll('; wv)', ')')
    .replaceAll(RegExp(r' Version/\d+(\.\d+)*'), '');
