import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/firebase/firebaseBootstrap.dart';
import '../../core/registry/featureModule.dart';
import '../../core/registry/featureRegistry.dart';
import '../../core/session/sessionController.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
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
              children: [
                SizedBox(
                  width: 280,
                  child: _Sidebar(
                    location: widget.location,
                    closeOnSelect: false,
                  ),
                ),
                Expanded(child: content),
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
              title: Text(
                'mybmiscellany',
                style: orbitron(16, color: AppColors.navy),
              ),
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
  const _Sidebar({required this.location, required this.closeOnSelect});

  final String location;
  final bool closeOnSelect;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    final shortId = user.userId.length > 8
        ? user.userId.substring(0, 8)
        : user.userId;
    return Material(
      color: AppColors.navy,
      child: SafeArea(
        child: Column(
          children: [
            InkWell(
              onTap: () => _go(context, '/'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'mybmiscellany',
                      style: orbitron(16, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PLAY & LEARN',
                      style: pixel(8, color: AppColors.neonGreen),
                    ),
                  ],
                ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.displayName} · $shortId',
                    style: bodyText(size: 12, color: Colors.white),
                  ),
                  Text(
                    FirebaseBootstrap.status,
                    style: labelText(size: 12, color: AppColors.aqua),
                  ),
                ],
              ),
            ),
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
