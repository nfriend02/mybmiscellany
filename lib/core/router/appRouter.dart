import 'package:go_router/go_router.dart';

import '../../app/HomeWidget.dart';
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
