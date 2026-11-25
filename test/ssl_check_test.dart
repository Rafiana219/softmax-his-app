import 'package:flutter/foundation.dart';
import 'package:flutter_browser/ssl_check.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS (SecTrustResultType codes)', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    SslError ios(int code) =>
        SslError(code: SslErrorType.fromNativeValue(code), message: 'x');

    test('passed checks are not errors (the Appetize bug)', () {
      expect(isRealSslError(ios(4), apple: true), isFalse); // unspecified
      expect(isRealSslError(ios(1), apple: true), isFalse); // proceed
      expect(isRealSslError(null, apple: true), isFalse);
    });

    test('real failures still block', () {
      for (final code in [0, 3, 5, 6, 7]) {
        expect(
          isRealSslError(ios(code), apple: true),
          isTrue,
          reason: 'code $code',
        );
      }
    });
  });

  test('Android: any reported SSL error is real', () {
    expect(isRealSslError(SslError(message: 'expired'), apple: false), isTrue);
    expect(isRealSslError(null, apple: false), isFalse);
  });
}
