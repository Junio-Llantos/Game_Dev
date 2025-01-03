import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
//import 'package:flame/effects.dart';
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
    this.isFireball = false, // Added isFireball
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
  final bool isFireball; // Fireball property

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (position.x - radius <= 0 && velocity.x < 0) {
      // Bounce off the left wall
      velocity.x = -velocity.x;
      position.x = radius; // Correct the position to stay inside the screen
    } else if (position.x + radius >= game.width && velocity.x > 0) {
      // Bounce off the right wall
      velocity.x = -velocity.x;
      position.x =
          game.width - radius; // Correct the position to stay inside the screen
    }

    if (position.y - radius <= 0 && velocity.y < 0) {
      // Bounce off the top wall
      velocity.y = -velocity.y;
      position.y = radius; // Correct the position to stay inside the screen
    } else if (position.y + radius >= game.height && velocity.y > 0) {
      // Ball falls below the screen (handled as a missed ball)
      game.removeBall(this);
    }

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
        explodeBricks(other); // Explode multiple bricks
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
    // Define explosion radius
    const double explosionRadius = 50.0;

    // Get all bricks within the radius
    final bricksToDestroy = game.world.children.query<Brick>().where((brick) {
      return brick.position.distanceTo(position) <= explosionRadius;
    }).toList();

    // Destroy up to 4 bricks
    for (var i = 0; i < bricksToDestroy.length && i < 4; i++) {
      game.world.remove(bricksToDestroy[i]);
    }
  }
}
