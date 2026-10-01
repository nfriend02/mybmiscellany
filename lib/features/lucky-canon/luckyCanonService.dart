import 'dart:math' as math;

class Marble {
  Marble({
    required this.name,
    required this.index,
    required this.radius,
    this.icon = '',
  });

  final String name;
  final int index;
  final double radius;
  final String icon;
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
    this.duration = 30,
    this.cruise = 720,
  });

  final double width;
  final double height;
  final List<Marble> marbles;
  final List<Peg> pegs;
  final double duration;

  /// Pixels per second. Speed 10 crosses [width] in one second.
  final double cruise;
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
    final maxSlice = (6 / cruise).clamp(0.001, 1 / 60);
    while (remaining > 0) {
      final slice = remaining > maxSlice ? maxSlice : remaining;
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
      marble.x += marble.vx * dt;
      marble.y += marble.vy * dt;
      _walls(marble);
      for (final peg in pegs) {
        _peg(marble, peg);
      }
    }
    _separateMarbles();
    _separateMarbles();
    for (final marble in marbles) {
      if (marble.launched && marble.landedAt == null) _keepSpeed(marble);
    }
    _completeIfNeeded();
  }

  void _launch(Marble marble, int index) {
    marble.launched = true;
    const angles = [-2.7, -0.45, -1.15, -2.15, -0.85, -1.9, -0.25, -2.4];
    final angle = angles[index % angles.length];
    final span = marbles.length <= 1 ? 0.5 : index / (marbles.length - 1);
    marble.x = width * (0.22 + 0.56 * span);
    marble.y = height * 0.62;
    marble.vx = math.cos(angle) * cruise;
    marble.vy = math.sin(angle) * cruise;
  }

  void _walls(Marble marble) {
    final left = marble.radius;
    final right = width - marble.radius;
    final top = marble.radius + 8;
    final bottom = height - 18 - marble.radius;
    if (marble.x < left) {
      marble.x = left;
      marble.vx = marble.vx.abs();
    } else if (marble.x > right) {
      marble.x = right;
      marble.vx = -marble.vx.abs();
    }
    if (marble.y < top) {
      marble.y = top;
      marble.vy = marble.vy.abs();
    } else if (marble.y > bottom) {
      marble.y = bottom;
      marble.vy = -marble.vy.abs();
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
      marble.vx -= 2 * impact * nx;
      marble.vy -= 2 * impact * ny;
    }
  }

  void _keepSpeed(Marble marble) {
    final speed = math.sqrt(marble.vx * marble.vx + marble.vy * marble.vy);
    if (speed < 1) {
      final angle = marble.index * 1.7;
      marble.vx = math.cos(angle) * cruise;
      marble.vy = math.sin(angle) * cruise;
      return;
    }
    final scale = cruise / speed;
    marble.vx *= scale;
    marble.vy *= scale;
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
    if (time < duration) return;
    for (final marble in marbles) {
      marble.landedAt = duration + (height - marble.y) + marble.index * 0.0001;
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
  double duration = 30,
  int layout = 0,
  int pegCount = 5,
  int speedLevel = 5,
  List<String> icons = const [],
}) {
  if (names.length < 2) {
    throw const FormatException('구슬이 될 이름을 두 개 이상 입력해 주세요.');
  }
  final marbles = [
    for (var i = 0; i < names.length; i++)
      Marble(
        name: names[i],
        index: i,
        radius: 16,
        icon: i < icons.length ? icons[i] : '',
      ),
  ];
  final level = speedLevel.clamp(1, 20);
  final world = CanonWorld(
    width: width,
    height: height,
    marbles: marbles,
    pegs: _pegs(layout, width, height, pegCount),
    duration: duration,
    cruise: level / 10.0 * width,
  );
  for (var i = 0; i < marbles.length; i++) {
    marbles[i].x = width / 2 + (i - (names.length - 1) / 2) * 20;
    marbles[i].y = height - 30;
  }
  return world;
}

List<Peg> _pegs(int layout, double width, double height, int count) {
  final wanted = count.clamp(0, 30);
  if (wanted == 0) return [];
  final pool = _layoutPegs(layout, width, height);
  if (pool.length == wanted) return pool;
  if (pool.length > wanted) {
    return [
      for (var i = 0; i < wanted; i++)
        pool[((i + 0.5) * pool.length / wanted).floor().clamp(
          0,
          pool.length - 1,
        )],
    ];
  }
  final random = math.Random(layout + 40);
  final pegs = [...pool];
  while (pegs.length < wanted) {
    pegs.add(
      Peg(
        36 + random.nextDouble() * (width - 72),
        80 + random.nextDouble() * (height - 230),
        8,
      ),
    );
  }
  return pegs;
}

List<Peg> _layoutPegs(int layout, double width, double height) {
  final kind = layout % 6;
  if (kind == 2) return _diamond(width);
  if (kind == 3) return _scattered(width, height, layout);
  if (kind == 4) return _gates(width, height);
  if (kind == 5) return _rings(width, height);
  final columns = kind == 1 ? 5 : 7;
  final rows = kind == 1 ? 8 : 6;
  final radius = kind == 1 ? 12.0 : 8.0;
  return _grid(width, height, columns: columns, rows: rows, radius: radius);
}

List<Peg> _grid(
  double width,
  double height, {
  required int columns,
  required int rows,
  required double radius,
}) {
  final pegs = <Peg>[];
  const top = 78.0;
  final bottom = height - 150;
  for (var row = 0; row < rows; row++) {
    final y = top + (bottom - top) * row / (rows - 1);
    final shift = row.isOdd ? width / columns / 2 : 0.0;
    for (var column = 0; column < columns; column++) {
      final x = shift + (column + 0.5) * width / columns;
      if (x < 28 || x > width - 28) continue;
      pegs.add(Peg(x, y, radius));
    }
  }
  return pegs;
}

List<Peg> _diamond(double width) {
  final pegs = <Peg>[];
  for (var row = 0; row < 8; row++) {
    final count = row < 4 ? row + 2 : 9 - row;
    for (var i = 0; i < count; i++) {
      final x = width / 2 + (i - (count - 1) / 2) * 72;
      if (x < 28 || x > width - 28) continue;
      pegs.add(Peg(x, 86 + row * 46, 9));
    }
  }
  return pegs;
}

List<Peg> _scattered(double width, double height, int layout) {
  final random = math.Random(layout + 11);
  return [
    for (var i = 0; i < 26; i++)
      Peg(
        36 + random.nextDouble() * (width - 72),
        80 + random.nextDouble() * (height - 230),
        7 + random.nextDouble() * 6,
      ),
  ];
}

List<Peg> _gates(double width, double height) {
  final pegs = <Peg>[];
  for (var row = 0; row < 9; row++) {
    final y = 70 + (height - 210) * row / 8;
    final gap = width * (0.28 + (row % 3) * 0.12);
    for (var x = 40.0; x < width - 40; x += 36) {
      if ((x - width / 2).abs() < gap / 2) continue;
      pegs.add(Peg(x, y, 8));
    }
  }
  return pegs;
}

List<Peg> _rings(double width, double height) {
  final pegs = <Peg>[];
  final centerX = width / 2;
  final centerY = height * 0.42;
  for (var ring = 1; ring <= 3; ring++) {
    final count = 6 + ring * 4;
    final radius = 50.0 + ring * 58;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + ring * 0.3;
      pegs.add(
        Peg(
          centerX + math.cos(angle) * radius,
          centerY + math.sin(angle) * radius * 0.72,
          8,
        ),
      );
    }
  }
  return pegs;
}
