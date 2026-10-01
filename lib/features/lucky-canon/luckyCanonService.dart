import 'dart:math' as math;

class Marble {
  Marble({required this.name, required this.index, required this.radius});

  final String name;
  final int index;
  final double radius;
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  bool launched = false;
  double? landedAt;
}

class Peg {
  const Peg(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;
}

class CanonWorld {
  CanonWorld({
    required this.width,
    required this.height,
    required this.marbles,
    required this.pegs,
  });

  final double width;
  final double height;
  final List<Marble> marbles;
  final List<Peg> pegs;
  double time = 0;
  bool firing = false;
  bool completed = false;

  void start() {
    firing = true;
    completed = false;
    time = 0;
    for (final marble in marbles) {
      marble.launched = false;
      marble.landedAt = null;
      marble.vx = 0;
      marble.vy = 0;
    }
  }

  void step(double dt) {
    if (!firing || completed) return;
    var remaining = dt.clamp(0.0, 0.05);
    while (remaining > 0) {
      final slice = remaining > 1 / 120 ? 1 / 120 : remaining;
      _substep(slice);
      remaining -= slice;
      if (completed) return;
    }
  }

  Marble? get winner {
    if (!completed) return null;
    final ranked = [...marbles]
      ..sort((a, b) => b.landedAt!.compareTo(a.landedAt!));
    return ranked.first;
  }

  List<Marble> get ranking {
    final ranked = [...marbles]
      ..sort((a, b) => (b.landedAt ?? 0).compareTo(a.landedAt ?? 0));
    return ranked;
  }

  void _substep(double dt) {
    time += dt;
    for (var i = 0; i < marbles.length; i++) {
      final marble = marbles[i];
      if (!marble.launched && time >= i * 0.35) {
        _launch(marble, i);
      }
      if (!marble.launched || marble.landedAt != null) continue;
      marble.vy += 1100 * dt;
      marble.x += marble.vx * dt;
      marble.y += marble.vy * dt;
      _walls(marble);
      for (final peg in pegs) {
        _peg(marble, peg);
      }
      _floor(marble);
    }
    _separateMarbles();
    _completeIfNeeded();
  }

  void _launch(Marble marble, int index) {
    marble.launched = true;
    final center = (marbles.length - 1) / 2;
    final angle = -math.pi / 2 + (index - center) * 0.22;
    final speed = 680 + (index % 4) * 40;
    marble.x = width / 2;
    marble.y = height - 46;
    marble.vx = math.cos(angle) * speed;
    marble.vy = math.sin(angle) * speed;
  }

  void _walls(Marble marble) {
    if (marble.x < marble.radius) {
      marble.x = marble.radius;
      marble.vx = marble.vx.abs() * 0.82;
    }
    if (marble.x > width - marble.radius) {
      marble.x = width - marble.radius;
      marble.vx = -marble.vx.abs() * 0.82;
    }
    if (marble.y < marble.radius + 8) {
      marble.y = marble.radius + 8;
      marble.vy = marble.vy.abs() * 0.55;
    }
  }

  void _peg(Marble marble, Peg peg) {
    final dx = marble.x - peg.x;
    final dy = marble.y - peg.y;
    final distanceSquared = dx * dx + dy * dy;
    final minDistance = marble.radius + peg.radius;
    if (distanceSquared >= minDistance * minDistance ||
        distanceSquared < 0.0001) {
      return;
    }
    final distance = math.sqrt(distanceSquared);
    final nx = dx / distance;
    final ny = dy / distance;
    marble.x += nx * (minDistance - distance);
    marble.y += ny * (minDistance - distance);
    final impact = marble.vx * nx + marble.vy * ny;
    if (impact < 0) {
      marble.vx -= 1.86 * impact * nx;
      marble.vy -= 1.86 * impact * ny;
    }
  }

  void _floor(Marble marble) {
    final floor = height - 18 - marble.radius;
    if (marble.y <= floor) return;
    marble.y = floor;
    marble.vy = -marble.vy.abs() * 0.2;
    marble.vx *= 0.7;
    if (marble.vy.abs() < 48 && marble.vx.abs() < 48) {
      marble.landedAt = time;
      marble.vx = 0;
      marble.vy = 0;
    }
  }

  void _separateMarbles() {
    for (var i = 0; i < marbles.length; i++) {
      for (var j = i + 1; j < marbles.length; j++) {
        final a = marbles[i];
        final b = marbles[j];
        if (!a.launched ||
            !b.launched ||
            a.landedAt != null ||
            b.landedAt != null) {
          continue;
        }
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final minDistance = a.radius + b.radius;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared >= minDistance * minDistance ||
            distanceSquared < 0.0001) {
          continue;
        }
        final distance = math.sqrt(distanceSquared);
        final nx = dx / distance;
        final ny = dy / distance;
        final overlap = (minDistance - distance) / 2;
        a.x -= nx * overlap;
        a.y -= ny * overlap;
        b.x += nx * overlap;
        b.y += ny * overlap;
        final impact = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
        if (impact > 0) continue;
        a.vx += impact * nx;
        a.vy += impact * ny;
        b.vx -= impact * nx;
        b.vy -= impact * ny;
      }
    }
  }

  void _completeIfNeeded() {
    if (!marbles.every((marble) => marble.launched)) return;
    final allLanded = marbles.every((marble) => marble.landedAt != null);
    if (!allLanded && time < 16) return;
    for (final marble in marbles) {
      marble.landedAt ??= time + marble.index * 0.001;
      marble.vx = 0;
      marble.vy = 0;
    }
    completed = true;
    firing = false;
  }
}

List<String> parseCanonNames(String raw) {
  final names = <String>[];
  final seen = <String>{};
  for (final part in raw.split(RegExp(r'[\n,]'))) {
    final name = part.trim();
    if (name.isEmpty || !seen.add(name)) continue;
    names.add(name);
    if (names.length == 8) break;
  }
  return names;
}

CanonWorld createCanonWorld(
  List<String> names, {
  double width = 720,
  double height = 520,
}) {
  if (names.length < 2) {
    throw const FormatException('구슬이 될 이름을 두 개 이상 입력해 주세요.');
  }
  final marbles = [
    for (var i = 0; i < names.length; i++)
      Marble(name: names[i], index: i, radius: 16),
  ];
  final pegs = <Peg>[];
  const columns = 7;
  const rows = 6;
  const top = 78.0;
  final bottom = height - 150;
  for (var row = 0; row < rows; row++) {
    final y = top + (bottom - top) * row / (rows - 1);
    final shift = row.isOdd ? width / columns / 2 : 0.0;
    for (var column = 0; column < columns; column++) {
      final x = shift + (column + 0.5) * width / columns;
      if (x < 28 || x > width - 28) continue;
      pegs.add(Peg(x, y, 8));
    }
  }
  final world = CanonWorld(
    width: width,
    height: height,
    marbles: marbles,
    pegs: pegs,
  );
  for (var i = 0; i < marbles.length; i++) {
    marbles[i].x = width / 2 + (i - (names.length - 1) / 2) * 20;
    marbles[i].y = height - 30;
  }
  return world;
}
