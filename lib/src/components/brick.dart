import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import '../config.dart';
import 'power_up.dart';

class Brick extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Brick({
    required super.position,
    required Color color,
    this.hasPowerUp = false,
    this.isIndestructible = false,
    this.hitPoints = 1,
  }) : super(
          size: Vector2(brickWidth, brickHeight),
          anchor: Anchor.center,
          paint: Paint()
            ..color = isIndestructible ? Colors.black : color
            ..style = PaintingStyle.fill,
          children: [RectangleHitbox()],
        );

  final bool hasPowerUp;
  final bool isIndestructible;
  int hitPoints;

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // Debugging log to check what's colliding
    print('Brick collided with: ${other.runtimeType}');

    if (!isIndestructible) {
      hitPoints--;
      if (hitPoints <= 0) {
        removeFromParent();
        game.score.value++;
        if (hasPowerUp) {
          game.world.add(PowerUp(
            position: position,
            type: PowerUpType.values[game.rand.nextInt(3)],
          ));
        }
      }
    } else {
      // Indestructible brick handling: it shouldn't be destroyed
      print('This brick is indestructible, not removed.');
    }
  }
}
