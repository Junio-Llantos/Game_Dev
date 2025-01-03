import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import 'bat.dart';
import 'brick.dart';
import 'play_area.dart';

class Ball extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Ball({
    required this.velocity,
    required super.position,
    required double radius,
    required this.difficultyModifier,
    this.isSticky = false,
    this.isBouncy = false,
    this.isFireball = false,
  }) : super(
          radius: radius,
          anchor: Anchor.center,
          paint: Paint()
            ..color = isFireball ? Colors.red : const Color(0xff1e6091),
          children: [CircleHitbox()],
        );

  final Vector2 velocity;
  final double difficultyModifier;
  final bool isSticky;
  final bool isBouncy;
  final bool isFireball;

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    // Collision with screen boundaries
    if (position.x - radius <= 0 && velocity.x < 0) {
      velocity.x = -velocity.x;
      position.x = radius;
    } else if (position.x + radius >= game.width && velocity.x > 0) {
      velocity.x = -velocity.x;
      position.x = game.width - radius;
    }

    if (position.y - radius <= 0 && velocity.y < 0) {
      velocity.y = -velocity.y;
      position.y = radius;
    } else if (position.y + radius >= game.height && velocity.y > 0) {
      game.removeBall(this);
    }

    // Modify velocity based on sticky or bouncy properties
    if (isSticky) {
      velocity.x *= 0.98;
      velocity.y *= 0.98;
    } else if (isBouncy) {
      velocity.x *= 1.1;
      velocity.y *= 1.1;
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayArea) {
      if (intersectionPoints.first.y <= 0) {
        velocity.y = -velocity.y;
      } else if (intersectionPoints.first.x <= 0 ||
          intersectionPoints.first.x >= game.width) {
        velocity.x = -velocity.x;
      } else if (intersectionPoints.first.y >= game.height) {
        game.removeBall(this);
      }
    } else if (other is Bat) {
      velocity.y = -velocity.y;
      velocity.x +=
          (position.x - other.position.x) / other.size.x * game.width * 0.3;
    } else if (other is Brick) {
      if (isFireball) {
        explodeBricks(other);
      } else {
        if (position.y < other.position.y - other.size.y / 2 ||
            position.y > other.position.y + other.size.y / 2) {
          velocity.y = -velocity.y;
        } else {
          velocity.x = -velocity.x;
        }
        velocity.x *= difficultyModifier;
        velocity.y *= difficultyModifier;
      }
    }
  }

  void explodeBricks(Brick hitBrick) {
    const double explosionRadius = 50.0;

    final bricksToDestroy = game.world.children.query<Brick>().where((brick) {
      return brick.position.distanceTo(position) <= explosionRadius;
    }).toList();

    for (var i = 0; i < bricksToDestroy.length && i < 4; i++) {
      game.world.remove(bricksToDestroy[i]);
    }
  }
}
