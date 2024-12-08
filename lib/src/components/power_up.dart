import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import '../config.dart';
import 'ball.dart';
import 'bat.dart';

class PowerUp extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  PowerUp({required Vector2 position})
      : super(
          position: position,
          size: Vector2(30, 30), // Slightly larger for better visibility
          anchor: Anchor.center,
          paint: Paint()
            ..color = Colors.orange
            ..style = PaintingStyle.fill,
          children: [
            RectangleHitbox(),
          ],
        ) {
    add(
      TextComponent(
        text: '+',
        position: size / 2,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  final Vector2 velocity = Vector2(0, 100);

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (position.y > game.height) {
      removeFromParent(); // Remove the power-up if it falls off the screen
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Bat) {
      // Add three additional balls
      for (var i = 0; i < 3; i++) {
        final newBall = Ball(
          difficultyModifier: difficultyModifier,
          radius: ballRadius,
          position: game.world.children.query<Ball>().first.position.clone(),
          velocity: Vector2(
            game.rand.nextDouble() * 2 - 1, // Random horizontal direction
            -1,
          ).normalized()
            ..scale(game.height / 2),
        );
        game.world.add(newBall);
      }

      removeFromParent(); // Remove the power-up after collision
    }
  }
}
