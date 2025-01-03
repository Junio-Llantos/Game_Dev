import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import '../config.dart';
import 'ball.dart';
import 'bat.dart';

class PowerUp extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  PowerUp({required Vector2 position, required this.type})
      : super(
          position: position,
          size: Vector2(30, 30),
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
        text: type == PowerUpType.fireball
            ? '🔥'
            : type == PowerUpType.enlarge
                ? '🔼'
                : type == PowerUpType.shrink
                    ? '🔽'
                    : '+',
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
  final PowerUpType type;

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (position.y > game.height) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Bat) {
      if (type == PowerUpType.fireball) {
        // Spawn a fireball
        final fireBall = Ball(
          velocity: Vector2(0, -game.height / 2),
          position: other.position.clone(),
          radius: ballRadius,
          difficultyModifier: difficultyModifier,
          isFireball: true,
        );
        game.world.add(fireBall);
      } else if (type == PowerUpType.enlarge) {
        // Enlarge the bat
        other.size = Vector2(other.size.x * 1.5, other.size.y);
      } else if (type == PowerUpType.shrink) {
        // Shrink the bat
        other.size = Vector2(other.size.x * 0.5, other.size.y);
      } else {
        // Add 3 additional balls
        for (int i = 0; i < 3; i++) {
          final newBall = Ball(
            velocity: Vector2(
                  game.rand.nextDouble() * 2 - 1,
                  -1,
                ).normalized() *
                game.height /
                2,
            position: game.world.children.query<Ball>().first.position.clone(),
            radius: ballRadius,
            difficultyModifier: difficultyModifier,
          );
          game.world.add(newBall);
        }
      }
      removeFromParent();
    }
  }
}

enum PowerUpType {
  fireball,
  enlarge,
  shrink, // New shrink power-up type
  defaultPowerUp,
}
