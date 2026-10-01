import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../core/firebase/firestoreGateway.dart';
import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/session/sessionController.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/css/cssTokens.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/GameSplash.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'luckyCanonService.dart';

class LuckyCanonWidget extends StatefulWidget {
  const LuckyCanonWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<LuckyCanonWidget> createState() => _LuckyCanonWidgetState();
}

class _LuckyCanonWidgetState extends State<LuckyCanonWidget>
    with TickerProviderStateMixin {
  final _names = TextEditingController(text: '하나, 두리, 세리, 넷');
  Map<String, Color> _colors = {};
  CanonWorld? _world;
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool _splash = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadCssColors('lib/features/lucky-canon/luckyCanon.css').then((colors) {
      if (mounted) setState(() => _colors = colors);
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _names.dispose();
    super.dispose();
  }

  void _launch() {
    try {
      final world = createCanonWorld(parseCanonNames(_names.text));
      world.start();
      _ticker?.dispose();
      _last = Duration.zero;
      _ticker = createTicker((elapsed) {
        final dt = _last == Duration.zero
            ? 1 / 60
            : (elapsed - _last).inMicroseconds / 1000000;
        _last = elapsed;
        world.step(dt);
        if (world.completed) _ticker?.stop();
        if (mounted) setState(() {});
      })..start();
      setState(() {
        _world = world;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _save(CanonWorld world) async {
    final winner = world.winner;
    if (winner == null) return;
    final ranking = world.ranking.map((marble) => marble.name).toList();
    final preview = '당첨: ${winner.name}\n순위: ${ranking.join(' > ')}';
    await saveResult(
      context,
      featureType: widget.module.featureType,
      title: '당첨 ${winner.name}',
      preview: preview,
      input: {'names': parseCanonNames(_names.text)},
      output: {'winner': winner.name, 'ranking': ranking, 'text': preview},
    );
    if (!mounted) return;
    final user = context.read<SessionController>().user;
    await const FirestoreGateway().saveScore(
      game: GameDraft(
        gameId: widget.module.featureType,
        name: 'Lucky Canon',
        description: '마지막에 떨어진 구슬이 이기는 캐논 게임',
        icon: '🎯',
        createdBy: user.userId,
      ),
      score: ScoreDraft(
        gameId: widget.module.featureType,
        userId: user.userId,
        score: 100,
        rank: 1,
      ),
    );
  }

  Color _marbleColor(int index) {
    const keys = ['lc-marble', 'lc-marble-2', 'lc-marble-3', 'lc-marble-4'];
    const fallbacks = [
      AppColors.neonGreen,
      AppColors.neonPurple,
      AppColors.neonOrange,
      AppColors.aqua,
    ];
    return _colors[keys[index % keys.length]] ??
        fallbacks[index % fallbacks.length];
  }

  @override
  Widget build(BuildContext context) {
    final world = _world;
    return FeatureFrame(
      module: widget.module,
      children: [
        if (_splash)
          GameSplash(
            title: 'LUCKY CANON',
            subtitle: '마지막에 떨어진 구슬이 이깁니다',
            onFinished: () {
              if (mounted) setState(() => _splash = false);
            },
          )
        else ...[
          InputBox(
            label: '구슬 이름',
            hint: '쉼표 또는 줄바꿈, 최대 8개',
            controller: _names,
            maxLines: 3,
            enableVoice: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              FilledButton(onPressed: _launch, child: const Text('발사')),
              if (world != null && world.completed)
                OutlinedButton(
                  onPressed: () => _save(world),
                  child: const Text('결과 저장'),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: bodyText(color: AppColors.neonOrange)),
          ],
          if (world != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 520,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: [
                      _colors['lc-bg-0'] ?? const Color(0xFF07111F),
                      _colors['lc-bg-1'] ?? const Color(0xFF12305C),
                      _colors['lc-bg-2'] ?? const Color(0xFF241447),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: CustomPaint(
                    painter: _CanonPainter(
                      world: world,
                      colorFor: _marbleColor,
                      obstacle:
                          _colors['lc-obstacle'] ?? const Color(0xFFD7C6FF),
                      cannon: _colors['lc-cannon'] ?? AppColors.neonOrange,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            if (world.completed && world.winner != null) ...[
              const SizedBox(height: 12),
              ResultPanel(
                title: '당첨 ${world.winner!.name}',
                child: Text(
                  world.ranking.map((marble) => marble.name).join('  >  '),
                  style: bodyText(),
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class _CanonPainter extends CustomPainter {
  _CanonPainter({
    required this.world,
    required this.colorFor,
    required this.obstacle,
    required this.cannon,
  });

  final CanonWorld world;
  final Color Function(int index) colorFor;
  final Color obstacle;
  final Color cannon;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / world.width,
      size.height / world.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - world.width * scale) / 2,
      (size.height - world.height * scale) / 2,
    );
    canvas.scale(scale);
    final pegPaint = Paint()..color = obstacle;
    for (final peg in world.pegs) {
      canvas.drawCircle(Offset(peg.x, peg.y), peg.radius, pegPaint);
    }
    final floor = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(12, world.height - 18),
      Offset(world.width - 12, world.height - 18),
      floor,
    );
    final cannonPath = Path()
      ..moveTo(world.width / 2 - 28, world.height - 8)
      ..lineTo(world.width / 2 + 28, world.height - 8)
      ..lineTo(world.width / 2, world.height - 58)
      ..close();
    canvas.drawPath(cannonPath, Paint()..color = cannon);
    final winner = world.winner;
    for (final marble in world.marbles) {
      final color = colorFor(marble.index);
      if (winner?.index == marble.index) {
        canvas.drawCircle(
          Offset(marble.x, marble.y),
          marble.radius + 6,
          Paint()..color = color.withValues(alpha: 0.35),
        );
      }
      canvas.drawCircle(
        Offset(marble.x, marble.y),
        marble.radius,
        Paint()..color = color,
      );
      final label = marble.name.isEmpty
          ? ''
          : String.fromCharCode(marble.name.runes.first);
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(marble.x - painter.width / 2, marble.y - painter.height / 2),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CanonPainter oldDelegate) => true;
}
