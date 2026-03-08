import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// EVE SSO 应用内 WebView 授权页面（使用 flutter_inappwebview，支持 Windows 桌面）
///
/// 流程：
/// 1. 加载传入的 SSO URL（EVE 官方授权页）
/// 2. 监听导航，当跳转到 /sso/eve/callback 时自动拦截
/// 3. 从 URL 提取 code 和 state，弹出并返回给调用方
/// 4. 调用方再调用后端 /sso/eve/callback 完成登录
class SsoWebViewPage extends StatefulWidget {
  const SsoWebViewPage({super.key, required this.url});

  /// EVE SSO 登录 URL（从后端 /sso/eve/login 获得）
  final String url;

  @override
  State<SsoWebViewPage> createState() => _SsoWebViewPageState();
}

class _SsoWebViewPageState extends State<SsoWebViewPage> {
  bool _isLoading = true;
  bool _handled = false; // 防止重复处理回调

  /// 判断是否是 SSO 回调 URL
  bool _isCallbackUrl(String url) => url.contains('/sso/eve/callback');

  /// 提取 code/state 并弹出，只处理一次
  void _tryHandle(String url) {
    if (_handled) return;
    if (!_isCallbackUrl(url)) return;

    final uri = Uri.tryParse(url);
    final code = uri?.queryParameters['code'];
    final state = uri?.queryParameters['state'];

    if (code != null && code.isNotEmpty && state != null && state.isNotEmpty) {
      _handled = true;
      if (mounted) {
        Navigator.of(context).pop({'code': code, 'state': state});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EVE SSO 授权'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: '取消',
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.url),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent:
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
              ' (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        ),
        onLoadStart: (controller, url) {
          final urlStr = url?.toString() ?? '';
          _tryHandle(urlStr);
          if (mounted) setState(() => _isLoading = true);
        },
        onLoadStop: (controller, url) {
          final urlStr = url?.toString() ?? '';
          _tryHandle(urlStr);
          if (mounted) setState(() => _isLoading = false);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final urlStr =
              navigationAction.request.url?.toString() ?? '';
          if (_isCallbackUrl(urlStr)) {
            _tryHandle(urlStr);
            // 阻止 WebView 实际加载回调 URL
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
