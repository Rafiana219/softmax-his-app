import 'package:flutter_browser/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ERP pages stay in the app', () {
    expect(isInternalUrl(Uri.parse(AppConfig.startUrl)), isTrue);
    expect(isInternalUrl(Uri.parse('https://softmax-one.com/x')), isTrue);
    expect(isInternalUrl(Uri.parse('https://api.softmax-one.com/x')), isTrue);
  });

  test('other links open outside', () {
    expect(isInternalUrl(Uri.parse('https://line.me/abc')), isFalse);
    expect(isInternalUrl(Uri.parse('https://evilsoftmax-one.com')), isFalse);
    expect(isInternalUrl(Uri.parse('tel:021234567')), isFalse);
    expect(isInternalUrl(Uri.parse('mailto:a@b.com')), isFalse);
  });

  test('WebView user agent becomes a Chrome one', () {
    const wv = 'Mozilla/5.0 (Linux; Android 13; SM-A536E Build/TP1A; wv) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 '
        'Chrome/131.0.6778.135 Mobile Safari/537.36';
    expect(
        chromeUserAgent(wv),
        'Mozilla/5.0 (Linux; Android 13; SM-A536E Build/TP1A) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/131.0.6778.135 Mobile Safari/537.36');
  });
}
