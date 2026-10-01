import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/history/historyRepository.dart';
import '../core/router/appRouter.dart';
import '../core/session/sessionController.dart';
import '../core/theme/appTheme.dart';

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
      ],
      child: MaterialApp.router(
        title: 'mybmiscellany',
        theme: buildAppTheme(),
        scrollBehavior: const AppScrollBehavior(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
