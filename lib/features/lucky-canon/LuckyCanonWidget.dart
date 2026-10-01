import 'dart:async';
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

const _icons = [
  '🎯',
  '⭐',
  '🔥',
  '💎',
  '🌙',
  '🍀',
  '🎵',
  '🐱',
  '🦊',
  '🐼',
  '🐸',
  '🦄',
  '🚀',
  '⚡️',
  '🌈',
  '🎲',
];

class _Player {
  _Player(this.name, this.icon);

  final String name;
  String icon;
}

class _Backdrop {
  const _Backdrop({
    required this.background,
    required this.obstacle,
    required this.cannon,
    required this.layout,
  });

  final List<Color> background;
  final Color obstacle;
  final Color cannon;
  final int layout;
}

const _backdrops = [
  _Backdrop(
    background: [Color(0xFF07111F), Color(0xFF12305C), Color(0xFF241447)],
    obstacle: Color(0xFFD7C6FF),
    cannon: Color(0xFFFF8A3D),
    layout: 0,
  ),
  _Backdrop(
    background: [Color(0xFF04241C), Color(0xFF0E6B4F), Color(0xFF14324A)],
    obstacle: Color(0xFFB6FF6A),
    cannon: Color(0xFFFFD166),
    layout: 1,
  ),
  _Backdrop(
    background: [Color(0xFF2A0A14), Color(0xFF8C2F39), Color(0xFF1C2748)],
    obstacle: Color(0xFFFFB4A2),
    cannon: Color(0xFF7CFFCB),
    layout: 2,
  ),
  _Backdrop(
    background: [Color(0xFF101820), Color(0xFF24587A), Color(0xFF0B3B2E)],
    obstacle: Color(0xFF9BE7FF),
    cannon: Color(0xFFFF6B6B),
    layout: 3,
  ),
  _Backdrop(
    background: [Color(0xFF1A1033), Color(0xFF4B2E83), Color(0xFF0F2747)],
    obstacle: Color(0xFFE7C6FF),
    cannon: Color(0xFF3DFFB0),
    layout: 4,
  ),
  _Backdrop(
    background: [Color(0xFF1B1208), Color(0xFF8A4B08), Color(0xFF1E3A5F)],
    obstacle: Color(0xFFFFE08A),
    cannon: Color(0xFF7AA2FF),
    layout: 5,
  ),
];

class _Setup {
  const _Setup({
    required this.names,
    required this.icons,
    required this.seconds,
    required this.backdrop,
  });

  final List<String> names;
  final List<String> icons;
  final int seconds;
  final _Backdrop backdrop;

  String get signature =>
      '${names.join('|')}|${icons.join('|')}|$seconds|${backdrop.layout}';
}

class LuckyCanonWidget extends StatefulWidget {
  const LuckyCanonWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<LuckyCanonWidget> createState() => _LuckyCanonWidgetState();
}

class _LuckyCanonWidgetState extends State<LuckyCanonWidget>
    with TickerProviderStateMixin {
  final _names = TextEditingController(text: '하나, 두리, 세리, 넷');
  final _random = math.Random();
  late final AnimationController _film;
  Map<String, Color> _colors = {};
  List<_Player> _players = [];
  _Backdrop _backdrop = _backdrops.first;
  _Setup? _confirmed;
  CanonWorld? _world;
  Ticker? _ticker;
  Timer? _countdownTimer;
  Duration _last = Duration.zero;
  double _seconds = 60;
  int? _count;
  bool _splash = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _film = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _names.addListener(_onNames);
    _syncPlayers();
    loadCssColors('lib/features/lucky-canon/luckyCanon.css').then((colors) {
      if (mounted) setState(() => _colors = colors);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _ticker?.dispose();
    _film.dispose();
    _names.removeListener(_onNames);
    _names.dispose();
    super.dispose();
  }

  void _onNames() {
    _syncPlayers();
    _confirmed = null;
    if (mounted) setState(() {});
  }

  void _syncPlayers() {
    final names = parseCanonNames(_names.text);
    final next = <_Player>[];
    final used = <_Player>{};
    for (final name in names) {
      _Player? kept;
      for (final player in _players) {
        if (player.name == name && used.add(player)) {
          kept = player;
          break;
        }
      }
      next.add(kept ?? _Player(name, _rollIcon()));
    }
    _players = next;
  }

  String _rollIcon({String? except}) {
    for (var attempt = 0; attempt < 8; attempt++) {
      final icon = _icons[_random.nextInt(_icons.length)];
      if (icon != except) return icon;
    }
    return _icons.first;
  }

  _Setup _currentSetup() {
    return _Setup(
      names: [for (final player in _players) player.name],
      icons: [for (final player in _players) player.icon],
      seconds: _seconds.round(),
      backdrop: _backdrop,
    );
  }

  void _confirm() {
    if (_players.length < 2) {
      setState(() => _error = '구슬이 될 이름을 두 개 이상 입력해 주세요.');
      return;
    }
    setState(() {
      _confirmed = _currentSetup();
      _error = null;
      _world = null;
      _count = null;
    });
  }

  void _shuffleBackdrop() {
    final next = _backdrops[_random.nextInt(_backdrops.length)];
    setState(() {
      _backdrop = next.layout == _backdrop.layout
          ? _backdrops[(next.layout + 1) % _backdrops.length]
          : next;
      _confirmed = null;
    });
  }

  void _fillExample() {
    _names.text = '하나, 두리, 세리, 넷';
    _seconds = 30;
    _backdrop = _backdrops.first;
    for (final player in _players) {
      player.icon = _rollIcon(except: player.icon);
    }
    _confirm();
  }

  void _beginCountdown() {
    final setup = _confirmed;
    if (setup == null || setup.signature != _currentSetup().signature) return;
    _ticker?.stop();
    _countdownTimer?.cancel();
    setState(() {
      _count = 5;
      _world = null;
      _error = null;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final count = _count;
      if (count == null || count <= 1) {
        timer.cancel();
        setState(() => _count = null);
        _launch();
        return;
      }
      setState(() => _count = count - 1);
    });
  }

  void _launch() {
    final setup = _confirmed;
    if (setup == null) return;
    try {
      final world = createCanonWorld(
        setup.names,
        duration: setup.seconds.toDouble(),
        layout: setup.backdrop.layout,
        icons: setup.icons,
      );
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
    final preview =
        '당첨: ${winner.icon} ${winner.name}\n순위: ${ranking.join(' > ')}';
    await saveResult(
      context,
      featureType: widget.module.featureType,
      title: '당첨 ${winner.name}',
      preview: preview,
      input: {
        'names': parseCanonNames(_names.text),
        'icons': [for (final player in _players) player.icon],
        'seconds': _seconds.round(),
        'layout': _backdrop.layout,
      },
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

  String _lengthLabel(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    if (minutes == 0) return '$rest초';
    if (rest == 0) return '$minutes분';
    return '$minutes분 $rest초';
  }

  @override
  Widget build(BuildContext context) {
    final world = _world;
    final setup = _confirmed;
    final ready = setup != null && setup.signature == _currentSetup().signature;
    final count = _count;
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
          const SizedBox(height: 14),
          Text(
            '게임 시간 ${_lengthLabel(_seconds.round())}',
            style: orbitron(15, color: AppColors.navy),
          ),
          Slider(
            min: 30,
            max: 120,
            divisions: 3,
            value: _seconds,
            label: _lengthLabel(_seconds.round()),
            onChanged: (value) => setState(() {
              _seconds = value;
              _confirmed = null;
            }),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _shuffleBackdrop,
              child: const Text('배경 바꾸기'),
            ),
          ),
          const SizedBox(height: 8),
          _BackdropStrip(backdrop: _backdrop),
          const SizedBox(height: 12),
          for (final player in _players)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(player.icon, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(player.name, style: bodyText())),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      player.icon = _rollIcon(except: player.icon);
                      _confirmed = null;
                    }),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(onPressed: _confirm, child: const Text('세팅 완료')),
              FilledButton(
                onPressed: ready && count == null ? _beginCountdown : null,
                child: const Text('게임 시작'),
              ),
              OutlinedButton(
                onPressed: _fillExample,
                child: const Text('예시 세팅'),
              ),
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
          if (setup != null && ready) ...[
            const SizedBox(height: 16),
            ResultPanel(
              title: '확정된 세팅',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('시간 ${_lengthLabel(setup.seconds)}', style: bodyText()),
                  const SizedBox(height: 8),
                  _BackdropStrip(backdrop: setup.backdrop),
                  const SizedBox(height: 8),
                  Text(
                    [
                      for (var i = 0; i < setup.names.length; i++)
                        '${setup.icons[i]} ${setup.names[i]}',
                    ].join('   '),
                    style: bodyText(size: 16),
                  ),
                ],
              ),
            ),
          ],
          if (count != null) ...[
            const SizedBox(height: 16),
            _CountdownFilm(count: count, animation: _film),
          ] else if (world != null) ...[
            const SizedBox(height: 16),
            Text(
              world.completed
                  ? '종료'
                  : '남은 시간 ${_lengthLabel((world.duration - world.time).ceil().clamp(0, world.duration.round()))}',
              style: labelText(color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 520,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: _backdrop.background,
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
                      obstacle: _backdrop.obstacle,
                      cannon: _backdrop.cannon,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            if (world.completed && world.winner != null) ...[
              const SizedBox(height: 12),
              ResultPanel(
                title: '당첨 ${world.winner!.icon} ${world.winner!.name}',
                child: Text(
                  world.ranking
                      .map((marble) => '${marble.icon} ${marble.name}')
                      .join('  >  '),
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

class _BackdropStrip extends StatelessWidget {
  const _BackdropStrip({required this.backdrop});

  final _Backdrop backdrop;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: backdrop.background),
      ),
    );
  }
}

class _CountdownFilm extends StatelessWidget {
  const _CountdownFilm({required this.count, required this.animation});

  final int count;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final turn = animation.value;
        return Container(
          height: 420,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment(-1 + turn * 2, -1),
              end: Alignment(1, 1 - turn),
              colors: const [
                Color(0xFF07070C),
                Color(0xFF1A1030),
                Color(0xFF102033),
              ],
            ),
          ),
          child: child,
        );
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('LUCKY CANON', style: pixel(12, color: AppColors.neonGreen)),
            const SizedBox(height: 12),
            Text('$count', style: orbitron(88, color: Colors.white)),
            const SizedBox(height: 8),
            Text('곧 시작합니다', style: bodyText(color: Colors.white)),
          ],
        ),
      ),
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
      final label = marble.icon.isNotEmpty
          ? marble.icon
          : (marble.name.isEmpty
                ? ''
                : String.fromCharCode(marble.name.runes.first));
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
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
