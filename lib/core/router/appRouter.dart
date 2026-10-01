import 'package:go_router/go_router.dart';

import '../../app/HomeWidget.dart';
import '../../features/auth/ui/authWelcomePage.dart';
import '../../features/auth/ui/myPage.dart';
import '../../features/auth/ui/signInPage.dart';
import '../../features/auth/ui/signUpPage.dart';
import '../../features/out-of-office/OfficeNoticePage.dart';
import '../../shared/widgets/Layout.dart';
import '../registry/featureRegistry.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          Layout(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PageScroll(child: HomeWidget()),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) =>
              const PageScroll(child: AuthWelcomePage()),
        ),
        GoRoute(
          path: '/auth/join',
          builder: (context, state) => const PageScroll(child: SignUpPage()),
        ),
        GoRoute(
          path: '/auth/enter',
          builder: (context, state) => const PageScroll(child: SignInPage()),
        ),
        GoRoute(
          path: '/me',
          builder: (context, state) => const PageScroll(child: MyPage()),
        ),
        GoRoute(
          path: '/out-of-office/notice',
          builder: (context, state) =>
              const PageScroll(child: OfficeNoticePage()),
        ),
        for (final feature in FeatureRegistry.all)
          GoRoute(
            path: feature.route,
            builder: (context, state) =>
                PageScroll(child: feature.build(context, feature)),
          ),
      ],
    ),
  ],
);
