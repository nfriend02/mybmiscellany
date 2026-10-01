import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/firebase/firebaseBootstrap.dart';
import '../../core/registry/featureModule.dart';
import '../../core/registry/featureRegistry.dart';
import '../../core/session/sessionController.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import 'AppLogo.dart';
import 'IconSet.dart';

class Layout extends StatefulWidget {
  const Layout({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _gradient;

  @override
  void initState() {
    super.initState();
    _gradient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _gradient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradient,
      builder: (context, child) {
        final t = _gradient.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t, -1),
              end: Alignment(1, 1 - t),
              colors: const [
                Color(0xFFE7F0FA),
                Color(0xFFF7F4FF),
                Color(0xFFFFF6EE),
                Color(0xFFE9FBF3),
              ],
            ),
          ),
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= desktopBreakpoint;
          final content = SafeArea(child: widget.child);
          if (desktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 280,
                  child: _Sidebar(
                    location: widget.location,
                    closeOnSelect: false,
                    showAccountLinks: true,
                  ),
                ),
                Expanded(
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: content,
                  ),
                ),
              ],
            );
          }
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.88),
              foregroundColor: AppColors.navy,
              elevation: 0,
              title: const AppLogo(compact: true, onDark: false, markSize: 36),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: _LogoAccountLinks(onDark: false),
                ),
              ],
            ),
            drawer: Drawer(
              backgroundColor: AppColors.navy,
              child: _Sidebar(location: widget.location, closeOnSelect: true),
            ),
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: widget.location == '/' ? 0 : 1,
              onDestinationSelected: (index) {
                if (index == 0) context.go('/');
                if (index == 1) _scaffoldKey.currentState?.openDrawer();
              },
              destinations: const [
                NavigationDestination(icon: Icon(IconSet.home), label: '홈'),
                NavigationDestination(icon: Icon(IconSet.menu), label: '메뉴'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PageScroll extends StatelessWidget {
  const PageScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= desktopBreakpoint;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        wide ? 28 : 16,
        wide ? 24 : 16,
        wide ? 28 : 16,
        32,
      ),
      child: child,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.location,
    required this.closeOnSelect,
    this.showAccountLinks = false,
  });

  final String location;
  final bool closeOnSelect;
  final bool showAccountLinks;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      child: SafeArea(
        child: Column(
          children: [
            InkWell(
              onTap: () => _go(context, '/'),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 6),
                child: AppLogo(markSize: 92),
              ),
            ),
            if (showAccountLinks)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Align(
                  alignment: Alignment.center,
                  child: _LogoAccountLinks(),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _SectionLabel(
                    title: 'GAME CENTER',
                    caption: '게임 센터',
                    color: AppColors.neonGreen,
                  ),
                  for (final feature in FeatureRegistry.inSection(
                    FeatureSection.gameCenter,
                  ))
                    _NavTile(
                      feature: feature,
                      selected: location == feature.route,
                      onTap: () => _go(context, feature.route),
                    ),
                  const SizedBox(height: 12),
                  _SectionLabel(
                    title: 'LEARNING TOOLBOX',
                    caption: '학습 툴박스',
                    color: AppColors.aqua,
                  ),
                  for (final feature in FeatureRegistry.inSection(
                    FeatureSection.learningToolbox,
                  ))
                    _NavTile(
                      feature: feature,
                      selected: location == feature.route,
                      onTap: () => _go(context, feature.route),
                    ),
                ],
              ),
            ),
            const _AccountPanel(),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    if (closeOnSelect && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    context.go(route);
  }
}

class _LogoAccountLinks extends StatelessWidget {
  const _LogoAccountLinks({this.onDark = true});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<SessionController>().user.signedIn;
    final color = onDark ? Colors.white : AppColors.navy;
    final first = signedIn
        ? _link(context, '로그아웃', color, () async {
            await context.read<SessionController>().signOut();
            if (context.mounted) context.go('/auth');
          })
        : _link(context, '로그인', color, () => context.go('/auth'));
    final second = signedIn
        ? _link(context, '마이페이지', color, () => context.go('/me'))
        : _link(context, '회원 가입', color, () => context.go('/auth/join'));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [first, const SizedBox(width: 4), second],
    );
  }

  Widget _link(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.symmetric(horizontal: onDark ? 10 : 6),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: onDark ? Colors.white24 : AppColors.line),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: bodyText(size: onDark ? 13 : 12, color: color),
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    final loginLabel = user.loginLabel;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.signedIn ? user.displayName : '게스트',
            style: bodyText(size: 12, color: Colors.white),
          ),
          if (user.signedIn && loginLabel.isNotEmpty)
            Text(
              loginLabel,
              style: bodyText(size: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            FirebaseBootstrap.status,
            style: labelText(size: 12, color: AppColors.aqua),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.caption,
    required this.color,
  });

  final String title;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: pixel(8, color: color)),
          Text(caption, style: bodyText(size: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.feature,
    required this.selected,
    required this.onTap,
  });

  final FeatureModule feature;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = feature.isGame ? AppColors.neonGreen : AppColors.aqua;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconSet.of(feature.featureType),
                  color: selected ? accent : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(feature.emoji),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: orbitron(11, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        feature.koreanTitle,
                        style: bodyText(size: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
