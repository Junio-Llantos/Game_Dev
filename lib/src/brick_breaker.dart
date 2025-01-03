import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'dart:async' as dart;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/components.dart';
import 'config.dart';

enum PlayState { welcome, playing, gameOver, won }

class BrickBreaker extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector {
  BrickBreaker()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: gameWidth,
            height: gameHeight,
          ),
        );

  final ValueNotifier<int> score = ValueNotifier(0);
  final rand = math.Random();
  double get width => size.x;
  double get height => size.y;

  late PlayState _playState;
  PlayState get playState => _playState;
  set playState(PlayState playState) {
    _playState = playState;
    overlays.clear();
    if (playState != PlayState.playing) {
      overlays.add(playState.name);
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(PlayArea());
    playState = PlayState.welcome;
  }

  void startGame() {
    if (playState == PlayState.playing) return;

    // Clear existing game objects
    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Bat>());
    world.removeAll(world.children.query<Brick>());
    //world.removeAll(world.children.query<Obstacle>());
    world.removeAll(world.children.query<PowerUp>());

    // Reset play state
    playState = PlayState.playing;
    score.value = 0;

    // Add new ball
    addNewBall(position: size / 2);

    // Add Bat
    world.add(Bat(
      size: Vector2(batWidth, batHeight),
      cornerRadius: const Radius.circular(ballRadius / 2),
      position: Vector2(width / 2, height * 0.90),
    ));

    // Bricks setup
    const int rows = 7;
    final int columns = brickColors.length;

    final bricksWithHitPoints = <Brick>[];

    for (var i = 0; i < columns; i++) {
      for (var j = 1; j <= rows; j++) {
        final isIndestructible =
            (j == 2 || j == 6) && (i < 3 || i >= brickColors.length - 3);

        final hasHitPoints = !isIndestructible &&
            bricksWithHitPoints.length < 6 &&
            rand.nextBool();

        final hitPoints = hasHitPoints ? rand.nextInt(4) + 2 : 1;

        final brick = Brick(
          position: Vector2(
            (i + 0.5) * brickWidth + (i + 1) * brickGutter,
            (j + 2.0) * brickHeight + j * brickGutter,
          ),
          color: hasHitPoints ? Colors.red : brickColors[i],
          hasPowerUp: rand.nextDouble() < 0.1,
          isIndestructible: isIndestructible,
          hitPoints: hasHitPoints ? hitPoints : 1,
        );

        world.add(brick);

        if (hasHitPoints) {
          bricksWithHitPoints.add(brick);
        }
      }
    }

    // Add obstacle at the center of the brick gri

    // Reposition hit-point bricks periodically
    dart.Timer.periodic(const Duration(seconds: 20), (timer) {
      if (playState != PlayState.playing) {
        timer.cancel();
      } else {
        repositionHitPointBricks();
      }
    });
  }

  void repositionHitPointBricks() {
    final bricksWithHitPoints = world.children
        .query<Brick>()
        .where((brick) => brick.hitPoints > 1)
        .toList();
    final bricksWithoutHitPoints = world.children
        .query<Brick>()
        .where((brick) => brick.hitPoints == 1)
        .toList();

    if (bricksWithHitPoints.isEmpty || bricksWithoutHitPoints.isEmpty) return;

    for (var brick in bricksWithHitPoints) {
      final targetBrick =
          bricksWithoutHitPoints[rand.nextInt(bricksWithoutHitPoints.length)];
      final oldPosition = brick.position.clone();
      brick.position = targetBrick.position;
      targetBrick.position = oldPosition;
    }
  }

  void addNewBall({required Vector2 position}) {
    final newBall = Ball(
      difficultyModifier: difficultyModifier,
      radius: ballRadius,
      position: position,
      velocity:
          Vector2((rand.nextDouble() - 0.5) * width, height * 0.2).normalized()
            ..scale(height / 2),
    );
    world.add(newBall);
  }

  void removeBall(Ball ball) {
    world.remove(ball);
    checkGameOver();
  }

  void handleBrickHit(Brick brick) {
    if (!brick.isIndestructible) {
      world.remove(brick);
      score.value += 10;
      checkGameWon();
    }
  }

  void checkGameWon() {
    final remainingBricks =
        world.children.query<Brick>().where((b) => !b.isIndestructible);
    if (remainingBricks.isEmpty) {
      playState = PlayState.won;
    }
  }

  void checkGameOver() {
    final activeBalls = world.children.query<Ball>();
    if (activeBalls.isEmpty) {
      playState = PlayState.gameOver;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (playState == PlayState.playing) {
      checkGameOver();
    }
  }

  @override
  void onTap() {
    super.onTap();
    if (playState != PlayState.playing) {
      startGame();
    }
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        world.children.query<Bat>().first.moveBy(-batStep);
        break;
      case LogicalKeyboardKey.arrowRight:
        world.children.query<Bat>().first.moveBy(batStep);
        break;
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        startGame();
        break;
    }
    return KeyEventResult.handled;
  }

  @override
  Color backgroundColor() => const Color(0xfff2e8cf);
}
