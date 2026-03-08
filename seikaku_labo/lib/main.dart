import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';

import 'pages/splash/splash_page.dart';
import 'providers/app_providers.dart';
import 'providers/fitting_provider.dart';
import 'providers/image_provider.dart';
import 'providers/sde_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  // 全局启用系统代理：读取 http_proxy / https_proxy 环境变量
  // 如使用 Clash/v2ray 等代理工具，请在代理工具中启用「设置系统代理」或手动设置环境变量
  if (!Platform.isAndroid && !Platform.isIOS) {
    HttpOverrides.global = _SystemProxyOverrides();
  }
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SeikakuLaboApp()));
}

class SeikakuLaboApp extends ConsumerWidget {
  const SeikakuLaboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdeReady = ref.watch(sdeReadyProvider);
    // 同步启动图片包检查（不阻塞 SDE 流程）
    ref.watch(imagePackNotifierProvider);

    // SDE 未就绪时显示启动页（下载/检查/错误）
    // 就绪后显示主界面
    return MaterialApp(
      title: 'Seikaku Labo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: sdeReady ? _MainApp() : const SplashPage(),
    );
  }
}

/// 主界面包装 — 使用 go_router
class _MainApp extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<_MainApp> {
  @override
  void initState() {
    super.initState();
    _initAppDatabase();
  }

  Future<void> _initAppDatabase() async {
    final db = ref.read(appDatabaseProvider);
    await db.open();
    await ref.read(savedFitsProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    // 同步系统 locale 到 sdeLanguageProvider
    final locale = Localizations.localeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sdeLanguageProvider.notifier).setState(locale.languageCode);
    });

    return MaterialApp.router(
      title: 'Seikaku Labo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}

// ─── 系统代理支持 ──────────────────────────────────────────────────────────────

/// 让 dart:io HttpClient 遵循 http_proxy / https_proxy / no_proxy 环境变量，
/// 从而接管 Clash、v2ray 等工具设置的系统代理。
/// 移动端（Android/iOS）由平台层自动处理代理，无需此覆盖。
class _SystemProxyOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = HttpClient.findProxyFromEnvironment;
  }
}
