import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';

class CaptchaScreen extends StatefulWidget {
  const CaptchaScreen({super.key});

  @override
  State<CaptchaScreen> createState() => _CaptchaScreenState();
}

class _CaptchaScreenState extends State<CaptchaScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..addJavaScriptChannel(
        'Captcha',
        onMessageReceived: (message) {
          final token = message.message.trim();
          if (token.isNotEmpty && mounted) {
            Navigator.pop(context, token);
          }
        },
      )
      ..loadHtmlString(_captchaHtml, baseUrl: SupabaseConfig.url);
  }

  String get _captchaHtml {
    final siteKey = const HtmlEscape().convert(SupabaseConfig.hcaptchaSiteKey);
    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://js.hcaptcha.com/1/api.js" async defer></script>
  <style>
    html, body {
      height: 100%;
      margin: 0;
      background: #f8fafc;
      font-family: Arial, sans-serif;
    }
    .wrap {
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
      box-sizing: border-box;
    }
    .card {
      width: 100%;
      max-width: 360px;
      border-radius: 24px;
      background: white;
      box-shadow: 0 18px 44px rgba(15, 23, 42, .14);
      padding: 26px 20px;
      text-align: center;
    }
    h1 {
      margin: 0 0 10px;
      font-size: 22px;
      color: #1f2937;
    }
    p {
      margin: 0 0 22px;
      color: #64748b;
      line-height: 1.4;
    }
    .captcha-box {
      display: flex;
      justify-content: center;
      min-height: 90px;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>Security Check</h1>
      <p>Please complete CAPTCHA verification to continue.</p>
      <div class="captcha-box">
        <div
          class="h-captcha"
          data-sitekey="$siteKey"
          data-callback="onCaptchaSuccess">
        </div>
      </div>
    </div>
  </div>
  <script>
    function onCaptchaSuccess(token) {
      Captcha.postMessage(token);
    }
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('CAPTCHA Verification'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
        ],
      ),
    );
  }
}
