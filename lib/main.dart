import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'app_log.dart';
import 'config.dart';
import 'erp_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Send app crashes to the on-screen log too.
  FlutterError.onError = (details) {
    AppLog.error('Flutter error: ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error('Error: $error');
    return true;
  };

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      // Lets chrome://inspect on a PC see the page when the phone is on USB.
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    } catch (e) {
      AppLog.warn('เปิด WebView debugging ไม่ได้: $e');
    }
  }
  runApp(const ErpApp());
}

class ErpApp extends StatelessWidget {
  const ErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: BrandColors.blue),
      home: const ErpPage(),
    );
  }
}
