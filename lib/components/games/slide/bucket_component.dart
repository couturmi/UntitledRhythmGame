import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/components.dart' as Flame;
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class BucketComponent extends PositionComponent
    with GameSizeAware, HasGameRef<MyGame>, Flame.Draggable {
  /// Represents the Y placement of the hit circle out of the game size's full Y axis.
  static const double hitCircleYPlacementModifier = 0.9;

  /// The height of the bucket.
  static const double bucketHeight = 50.0;

  /// The width of the bucket.
  static const double bucketWidth = 180.0;

  BucketComponent() : super(anchor: Anchor.bottomCenter);

  Future<void> onLoad() async {
    position =
        Vector2(gameSize.x / 2, gameSize.y * hitCircleYPlacementModifier);
    size = Vector2(bucketWidth, gameSize.y);
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(bucketWidth / 2, gameSize.y - bucketHeight),
        height: bucketHeight * 2,
        width: bucketWidth,
      ),
      -pi,
      -pi,
      false,
      paint,
    );
    super.render(canvas);
  }

  @override
  bool onDragUpdate(DragUpdateInfo info) {
    double dragAmount = info.delta.game.y;
    if (gameRef.currentLevel.currentLevelOrientation ==
        DeviceOrientation.landscapeRight) {
      dragAmount *= -1;
    }
    double newXPosition = position.x + dragAmount;
    if (newXPosition < (bucketWidth / 2) ||
        newXPosition > gameSize.x - (bucketWidth / 2)) {
      return true;
    }
    position = Vector2(newXPosition, position.y);
    return true;
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(Vector2(gameSize.y, gameSize.x));
  }
}
