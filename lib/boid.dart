import 'dart:math';
import 'dart:ui';

/// Shortest signed angle from [from] to [to], normalised to (-pi, pi] — Dart's
/// `%` gives 2pi - 0.1 for a small negative turn, which is awkward to compare.
double shortestTurn(double from, double to) {
  double delta = (to - from) % (2 * pi);
  if (delta > pi) delta -= 2 * pi;
  if (delta <= -pi) delta += 2 * pi;
  return delta;
}

Offset limit(Offset v, double max) {
  final length = v.distance;
  if (length <= max || length == 0) return v;
  return v * (max / length);
}

class Boid {
  Offset position;
  Offset velocity;

  double heading;

  double maxSpeed;
  double maxForce;
  double maxTurnRate;

  Offset _acceleration = Offset.zero;

  Boid({
    required this.position,
    required this.velocity,
    required this.maxSpeed,
    required this.maxForce,
    this.maxTurnRate = pi,
    double? heading,
  }) : heading = heading ?? (velocity == Offset.zero ? 0 : velocity.direction);

  double get speed => velocity.distance;

  /// The correction that brings [velocity] toward [desired], capped at
  /// [maxForce]. That cap is what makes movement look deliberate: a low
  /// maxForce can only bend the path gradually, so the boid commits to wide
  /// arcs instead of snapping onto every new target.
  Offset steerTowards(Offset desired) => limit(desired - velocity, maxForce);

  Offset seek(Offset target) {
    final offset = target - position;
    if (offset.distance == 0) return Offset.zero;
    return steerTowards(offset * (maxSpeed / offset.distance));
  }

  Offset arrive(Offset target, double slowRadius) {
    final offset = target - position;
    final distance = offset.distance;
    if (distance == 0) return steerTowards(Offset.zero);

    final speed = distance < slowRadius
        ? maxSpeed * (distance / slowRadius)
        : maxSpeed;
    return steerTowards(offset * (speed / distance));
  }

  void applyForce(Offset force) => _acceleration += force;

  void integrate(double dt) {
    if (dt <= 0) return;

    velocity = limit(velocity + _acceleration * dt, maxSpeed);
    position += velocity * dt;
    _acceleration = Offset.zero;

    if (velocity.distance > 0.0001) {
      final turn = shortestTurn(heading, velocity.direction);
      final maxStep = maxTurnRate * dt;
      heading = shortestTurn(0, heading + turn.clamp(-maxStep, maxStep));
    }
  }
}
