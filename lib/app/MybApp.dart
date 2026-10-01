import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/history/historyRepository.dart';
import '../core/router/appRouter.dart';
import '../core/session/sessionController.dart';
import '../core/theme/appTheme.dart';
import '../features/auth/ui/siteLeaveGuard.dart';
import '../features/out-of-office/officeNoticeBoard.dart';

class MybApp extends StatelessWidget {
  const MybApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final session = SessionController();
            session.bootstrap();
            return session;
          },
        ),
        ChangeNotifierProvider(create: (_) => HistoryRepository()),
        ChangeNotifierProvider(create: (_) => OfficeNoticeBoard()),
      ],
      child: const SiteLeaveGuard(child: _RoutedApp()),
    );
  }
}

class _RoutedApp extends StatelessWidget {
  const _RoutedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'mybmiscellany',
      theme: buildAppTheme(),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
