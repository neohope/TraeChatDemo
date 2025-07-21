import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_config.dart';
import 'core/utils/app_router.dart';
import 'presentation/themes/app_theme.dart';
import 'l10n/generated/l10n.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // 可以根据用户设置更改
      
      // 国际化配置
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      locale: Locale(AppConfig.instance.defaultLanguage),
      
      // 路由配置
      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
      
      // 错误处理
      builder: (context, child) {
        // 添加全局错误处理
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '发生了一个错误',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (AppConfig.instance.isDebug)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        details.exception.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          );
        };
        
        return child!;
      },
    );
  }
}