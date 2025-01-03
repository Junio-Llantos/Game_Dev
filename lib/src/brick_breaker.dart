import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
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
    switch (playState) {
      case PlayState.welcome:
      case PlayState.gameOver:
      case PlayState.won:
        overlays.add(playState.name);
        break;
      case PlayState.playing:
        overlays.clear();
        break;
    }
  }

  late Timer _brickMovementTimer;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(PlayArea());
    playState = PlayState.welcome;

    // Comment out the brick movement timer to prevent random movement
    // _brickMovementTimer = Timer(5, onTick: moveBricks, repeat: true);
  }

  void startGame() {
    if (playState == PlayState.playing) return;

    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Bat>());
    world.removeAll(world.children.query<Brick>());
    world.removeAll(world.children.query<PowerUp>());

    playState = PlayState.playing;
    score.value = 0;

    addNewBall(position: size / 2);

    world.add(Bat(
      size: Vector2(batWidth, batHeight),
      cornerRadius: const Radius.circular(ballRadius / 2),
      position: Vector2(width / 2, height * 0.90),
    ));

    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
        for (var j = 1; j <= 7; j++)
          Brick(
            position: Vector2(
              (i + 0.5) * brickWidth + (i + 1) * brickGutter,
              (j + 2.0) * brickHeight + j * brickGutter,
            ),
            color:
                ((j == 2 || j == 6) && (i < 3 || i >= brickColors.length - 3))
                    ? Colors.black
                    : brickColors[i],
            hasPowerUp: rand.nextDouble() < 0.1,
            isIndestructible:
                (j == 2 || j == 6) && (i < 3 || i >= brickColors.length - 3),
          ),
    ]);
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
    print('Ball added. Active balls: ${world.children.query<Ball>().length}');
  }

  void removeBall(Ball ball) {
    world.remove(ball);
    checkGameOver();
  }

  void handleBrickHit(Brick brick) {
    if (!brick.isIndestructible) {
      world.remove(brick); // Remove destructible bricks
      score.value += 10; // Increment score
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
      // No longer using the brick movement timer
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

  @override
  void onRemove() {
    super.onRemove();
    // Timer stop removed as brick movement is disabled
  }
}
