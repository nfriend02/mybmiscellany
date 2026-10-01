import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/history/historyRepository.dart';
import '../../../core/session/sessionController.dart';
import '../api/leaveWatcher.dart';

class SiteLeaveGuard extends StatefulWidget {
  const SiteLeaveGuard({super.key, required this.child});

  final Widget child;

  @override
  State<SiteLeaveGuard> createState() => _SiteLeaveGuardState();
}

class _SiteLeaveGuardState extends State<SiteLeaveGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    bindSiteLeave(_leave);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) _leave();
  }

  void _leave() {
    if (!mounted) return;
    final session = context.read<SessionController>();
    if (!session.user.signedIn) return;
    context.read<HistoryRepository>().flush();
    session.leaveSite();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
