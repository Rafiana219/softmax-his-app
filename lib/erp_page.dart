import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_log.dart';
import 'config.dart';
import 'splash.dart';

/// Full-screen app that shows the web ERP.
class ErpPage extends StatefulWidget {
  const ErpPage({super.key});

  @override
  State<ErpPage> createState() => _ErpPageState();
}

class _ErpPageState extends State<ErpPage> {
  InAppWebViewController? _web;
  PullToRefreshController? _pullToRefresh;
  String? _userAgent;
  bool _ready = false;
  bool _firstLoadDone = false;
  bool _minSplashDone = false;
  bool _splashRemoved = false;
  bool _canGoBack = false;
  bool _showLog = false;
  double _progress = 0;
  String? _error;
  Timer? _slowTimer;
  final _loadStarted = <String, DateTime>{};

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _mobile =>
      _android || (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  /// Splash stays at least 1.8 s (so the intro animation is seen) and
  /// until the first ERP page has loaded; an error skips it.
  bool get _hideSplash => (_firstLoadDone && _minSplashDone) || _error != null;

  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    if (_mobile) {
      _pullToRefresh = PullToRefreshController(
        settings: PullToRefreshSettings(color: BrandColors.blue),
        onRefresh: () => _web?.reload(),
      );
    }
    _splashTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _minSplashDone = true);
    });
    _init();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _slowTimer?.cancel();
    super.dispose();
  }

  /// Collects device / WebView facts for the log, then shows the WebView.
  Future<void> _init() async {
    AppLog.info('เปิด app ${AppConfig.appName} บน $defaultTargetPlatform');
    AppLog.info('URL เริ่มต้น: ${AppConfig.startUrl}');
    if (_android) {
      try {
        final pkg = await InAppWebViewController.getCurrentWebViewPackage();
        if (pkg == null) {
          AppLog.error('ไม่พบ Android System WebView บนเครื่องนี้');
        } else {
          AppLog.info(
            'WebView: ${pkg.packageName} เวอร์ชัน ${pkg.versionName}',
          );
          final major =
              int.tryParse((pkg.versionName ?? '').split('.').first) ?? 0;
          if (major > 0 && major < 100) {
            AppLog.warn(
              'WebView เก่ามาก (v$major) ให้อัปเดต '
              '"Android System WebView" และ "Chrome" ใน Play Store',
            );
          }
        }
      } catch (e) {
        AppLog.warn('อ่านเวอร์ชัน WebView ไม่ได้: $e');
      }
      try {
        final ua = await InAppWebViewController.getDefaultUserAgent();
        _userAgent = chromeUserAgent(ua);
        AppLog.info('User agent (แบบ Chrome): $_userAgent');
      } catch (e) {
        AppLog.warn('อ่าน user agent ไม่ได้: $e');
      }
      try {
        AppLog.info(
          'มี Chrome สำหรับเปิดแบบ Chrome: '
          '${await ChromeSafariBrowser.isAvailable() ? 'มี' : 'ไม่มี'}',
        );
      } catch (e) {
        AppLog.warn('ตรวจ Chrome ไม่ได้: $e');
      }
    }
    if (!mounted) return;
    setState(() => _ready = true);
    _slowTimer = Timer(const Duration(seconds: 20), () {
      if (!_firstLoadDone) {
        AppLog.warn('ผ่านไป 20 วินาทีแล้ว หน้าแรกยังโหลดไม่เสร็จ');
      }
    });
  }

  Future<void> _openOutside(Uri url) async {
    AppLog.info('เปิดนอก app: $url');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        AppLog.error('เปิดลิงก์นอก app ไม่ได้: $url');
      }
    } catch (e) {
      AppLog.error('เปิดลิงก์นอก app ไม่ได้: $url ($e)');
    }
  }

  /// Opens the current ERP page in the phone's real Chrome (Custom Tab).
  Future<void> _openInChrome() async {
    final current = await _web?.getUrl();
    final url = current != null && current.toString().startsWith('http')
        ? current
        : WebUri(AppConfig.startUrl);
    try {
      if (await ChromeSafariBrowser.isAvailable()) {
        AppLog.info('เปิดด้วย Chrome: $url');
        await ChromeSafariBrowser().open(
          url: url,
          settings: ChromeSafariBrowserSettings(
            showTitle: true,
            shareState: CustomTabsShareState.SHARE_STATE_OFF,
          ),
        );
      } else {
        AppLog.warn('เครื่องนี้ไม่มี Chrome ใช้ browser หลักแทน');
        await _openOutside(url);
      }
    } catch (e) {
      AppLog.error('เปิดด้วย Chrome ไม่ได้: $e');
      await _openOutside(url);
    }
  }

  Future<void> _updateBack() async {
    final can = await _web?.canGoBack() ?? false;
    if (mounted && can != _canGoBack) setState(() => _canGoBack = can);
  }

  void _retry() {
    AppLog.info('กดลองใหม่');
    setState(() => _error = null);
    _web?.reload();
  }

  void _toggleLog() => setState(() => _showLog = !_showLog);

  // ---------- WebView ----------

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(AppConfig.startUrl)),
      pullToRefreshController: _pullToRefresh,
      initialSettings: InAppWebViewSettings(
        userAgent: _userAgent,
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        thirdPartyCookiesEnabled: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
        useShouldOverrideUrlLoading: true,
        useOnDownloadStart: true,
        useHybridComposition: true,
        supportZoom: false,
        // iOS has no Back button: swipe from the left edge to go back.
        allowsBackForwardNavigationGestures: true,
        mediaPlaybackRequiresUserGesture: false,
        supportMultipleWindows: true,
        javaScriptCanOpenWindowsAutomatically: true,
      ),
      onWebViewCreated: (c) {
        _web = c;
        AppLog.info('สร้าง WebView แล้ว');
      },
      shouldOverrideUrlLoading: (c, action) async {
        final url = action.request.url;
        // iOS also asks about frames inside the page (Android only asks
        // about the page itself). Frames always load where they are.
        if (action.isForMainFrame == false) {
          return NavigationActionPolicy.ALLOW;
        }
        if (url == null || isInternalUrl(url)) {
          return NavigationActionPolicy.ALLOW;
        }
        await _openOutside(url);
        return NavigationActionPolicy.CANCEL;
      },
      onCreateWindow: (c, action) async {
        // target="_blank": ERP pages load here, others outside.
        final url = action.request.url;
        if (url != null) {
          if (isInternalUrl(url)) {
            await c.loadUrl(urlRequest: URLRequest(url: url));
          } else {
            await _openOutside(url);
          }
        }
        return false;
      },
      onDownloadStartRequest: (c, req) {
        AppLog.info('ดาวน์โหลด: ${req.url} (${req.mimeType ?? '-'})');
        _openOutside(req.url);
      },
      onLoadStart: (c, url) {
        final u = url.toString();
        _loadStarted[u] = DateTime.now();
        AppLog.info('เริ่มโหลด: $u');
      },
      onProgressChanged: (c, p) {
        if (p == 100) _pullToRefresh?.endRefreshing();
        setState(() => _progress = p / 100);
      },
      onLoadStop: (c, url) async {
        _pullToRefresh?.endRefreshing();
        final u = url.toString();
        final start = _loadStarted.remove(u);
        final ms = start == null
            ? ''
            : ' (${DateTime.now().difference(start).inMilliseconds} ms)';
        AppLog.info('โหลดเสร็จ: $u$ms');
        setState(() => _firstLoadDone = true);
        await _updateBack();
      },
      onUpdateVisitedHistory: (c, url, _) => _updateBack(),
      onReceivedError: (c, req, err) {
        _pullToRefresh?.endRefreshing();
        // A load replaced by another one (redirect, link tapped while
        // loading, link sent outside the app) is not a real failure.
        // iOS reports these as errors; Android does not.
        // (WebKit error 102 "Frame load interrupted" has no enum value.)
        if (err.type == WebResourceErrorType.CANCELLED ||
            err.description.contains('Frame load interrupted')) {
          AppLog.info('ยกเลิกการโหลด (ไม่ใช่ error): ${req.url}');
          return;
        }
        final main = req.isForMainFrame ?? true;
        final msg =
            'โหลดไม่สำเร็จ [${err.type}] ${err.description} '
            '-> ${req.url}';
        if (main) {
          AppLog.error(msg);
          setState(() => _error = err.description);
        } else {
          AppLog.warn('ไฟล์ประกอบหน้า: $msg');
        }
      },
      onReceivedHttpError: (c, req, res) {
        final msg =
            'HTTP ${res.statusCode} ${res.reasonPhrase ?? ''} '
            '-> ${req.url}';
        (req.isForMainFrame ?? false) ? AppLog.error(msg) : AppLog.warn(msg);
      },
      onReceivedServerTrustAuthRequest: (c, challenge) async {
        final ssl = challenge.protectionSpace.sslError;
        // iOS calls this for EVERY https connection, not only for bad
        // certificates (Android only calls it on an SSL error). With no
        // error, return null so the system checks the certificate as usual;
        // cancelling here would block every https page on iPhone/iPad.
        if (ssl == null) return null;
        AppLog.error(
          'SSL ไม่ผ่าน: ${ssl.code} ${ssl.message ?? ''} '
          '(${challenge.protectionSpace.host}) - ตรวจวันเวลาของเครื่อง',
        );
        return ServerTrustAuthResponse(
          action: ServerTrustAuthResponseAction.CANCEL,
        );
      },
      onConsoleMessage: (c, m) {
        final text = 'console: ${m.message}';
        switch (m.messageLevel) {
          case ConsoleMessageLevel.ERROR:
            AppLog.error(text);
          case ConsoleMessageLevel.WARNING:
            AppLog.warn(text);
          default:
            AppLog.info(text);
        }
      },
      onRenderProcessGone: (c, detail) {
        AppLog.error(
          'WebView หยุดทำงาน (crash: ${detail.didCrash}) '
          'กำลังโหลดใหม่',
        );
        c.reload();
      },
      onPermissionRequest: (c, req) async {
        AppLog.warn('เว็บขอสิทธิ์ ${req.resources} (ไม่อนุญาต)');
        return PermissionResponse(
          resources: req.resources,
          action: PermissionResponseAction.DENY,
        );
      },
    );
  }

  // ---------- Layout ----------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Phone Back closes the log first, then goes back in the ERP.
      canPop: !_canGoBack && !_showLog,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_showLog) {
          _toggleLog();
        } else {
          _web?.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Stack(
                children: [
                  if (_ready) _buildWebView(),
                  if (_firstLoadDone && _progress < 1)
                    LinearProgressIndicator(value: _progress, minHeight: 3),
                  if (_error != null)
                    _ErrorView(
                      message: _error!,
                      onRetry: _retry,
                      onChrome: _openInChrome,
                      onShowLog: AppConfig.showDebugLog ? _toggleLog : null,
                    ),
                  if (AppConfig.showDebugLog && _showLog)
                    _LogPanel(onClose: _toggleLog, onChrome: _openInChrome),
                  if (AppConfig.showDebugLog && !_showLog)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _LogButton(onPressed: _toggleLog),
                    ),
                ],
              ),
            ),
            // Full-screen splash; fades out once the ERP has loaded.
            if (!_splashRemoved)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _hideSplash,
                  child: AnimatedOpacity(
                    opacity: _hideSplash ? 0 : 1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    onEnd: () {
                      if (_hideSplash) setState(() => _splashRemoved = true);
                    },
                    child: const BrandSplash(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------- Widgets ----------

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onChrome,
    this.onShowLog,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onChrome;
  final VoidCallback? onShowLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 72,
            color: BrandColors.blue.withAlpha(150),
          ),
          const SizedBox(height: 16),
          const Text(
            'เปิดหน้า ${AppConfig.systemLabel} ไม่ได้',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('ลองใหม่'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onChrome,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('เปิดด้วย Chrome'),
          ),
          if (onShowLog != null)
            TextButton.icon(
              onPressed: onShowLog,
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('ดู log'),
            ),
        ],
      ),
    );
  }
}

/// Small floating button; turns red when there are errors in the log.
class _LogButton extends StatelessWidget {
  const _LogButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LogEntry>>(
      valueListenable: AppLog.entries,
      builder: (context, _, _) {
        final errors = AppLog.errorCount;
        return Badge(
          isLabelVisible: errors > 0,
          label: Text('$errors'),
          child: FloatingActionButton.small(
            heroTag: 'log',
            tooltip: 'ดู log',
            backgroundColor: errors > 0 ? Colors.red.shade600 : Colors.black87,
            foregroundColor: Colors.white,
            onPressed: onPressed,
            child: const Icon(Icons.bug_report_outlined),
          ),
        );
      },
    );
  }
}

/// The on-screen log: bottom half of the screen, newest line at the bottom.
class _LogPanel extends StatefulWidget {
  const _LogPanel({required this.onClose, required this.onChrome});

  final VoidCallback onClose;
  final VoidCallback onChrome;

  @override
  State<_LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<_LogPanel> {
  bool _errorsOnly = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: AppLog.asText()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คัดลอก log แล้ว วางส่งใน LINE ได้เลย')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.55;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: const Color(0xF0101418),
        elevation: 12,
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bug_report_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Log',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _iconBtn(
                      _errorsOnly ? Icons.filter_alt : Icons.filter_alt_off,
                      'เฉพาะ error',
                      () => setState(() => _errorsOnly = !_errorsOnly),
                    ),
                    _iconBtn(
                      Icons.open_in_browser,
                      'เปิดด้วย Chrome',
                      widget.onChrome,
                    ),
                    _iconBtn(Icons.copy, 'คัดลอก log', _copy),
                    _iconBtn(Icons.delete_outline, 'ล้าง log', AppLog.clear),
                    _iconBtn(Icons.close, 'ปิด', widget.onClose),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: ValueListenableBuilder<List<LogEntry>>(
                  valueListenable: AppLog.entries,
                  builder: (context, all, _) {
                    final list = _errorsOnly
                        ? all.where((e) => e.level != LogLevel.info).toList()
                        : all;
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'ยังไม่มี log',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    // reverse: true keeps the newest line in view.
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[list.length - 1 - i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: SelectableText(
                            '${e.timeText}  ${e.message}',
                            style: TextStyle(
                              color: logColor(e.level),
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tip, VoidCallback onTap) => IconButton(
    tooltip: tip,
    visualDensity: VisualDensity.compact,
    color: Colors.white70,
    icon: Icon(icon, size: 20),
    onPressed: onTap,
  );
}
