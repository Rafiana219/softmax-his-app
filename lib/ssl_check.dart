import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// True when an onReceivedServerTrustAuthRequest challenge is a real
/// certificate problem that should block the page.
///
/// Android only calls the callback on an SSL error, so any error there is
/// real. iOS/macOS call it for every https connection and put Apple's
/// SecTrustResultType in [SslError.code]; "proceed" (1) and "unspecified"
/// (4) mean the certificate PASSED the system check (normal for any valid
/// public certificate), so they are not errors. Treating "unspecified" as
/// an error blocked every https page on iPhone/iPad.
bool isRealSslError(SslError? error, {required bool apple}) {
  if (error == null) return false;
  if (!apple) return true;
  final code = error.code?.toNativeValue();
  const proceed = 1, unspecified = 4;
  return !(code == null || code == proceed || code == unspecified);
}
