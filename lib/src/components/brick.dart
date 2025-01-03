import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import '../config.dart';
import 'power_up.dart';
import 'ball.dart';

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

  // Text component to display hitPoints on the brick
  late TextComponent hitPointsText;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    if (!isIndestructible && hitPoints > 1) {
      hitPointsText = TextComponent(
        text: '$hitPoints',
        position: size / 2,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
      add(hitPointsText);
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (!isIndestructible && other is Ball) {
      hitPoints--;
      if (hitPoints <= 0) {
        removeFromParent();
        game.score.value += 10;
        if (hasPowerUp) {
          game.world.add(PowerUp(
            position: position,
            type: PowerUpType.values[game.rand.nextInt(3)],
          ));
        }
      } else {
        hitPointsText.text = '$hitPoints';
      }
    }
  }
}
