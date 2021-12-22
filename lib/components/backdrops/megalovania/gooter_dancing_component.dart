import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/megalovania/gooter_component.dart';

class GooterDancingComponent extends PositionComponent {
  List<GooterComponent> sprites = [];
  final int interval;
  int beatCount = 0;

  Vector2 gameSize = Vector2(1000, 1000);

  GooterDancingComponent({required this.interval});

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    await loadSprites();
    await super.onLoad();
  }

  Future<void> loadSprites() async {
    sprites
        .add(GooterComponent(Vector2(0, -300), directionalModifier: -1)); //top
    sprites.add(GooterComponent(Vector2(-75, -225), directionalModifier: -1));
    sprites.add(GooterComponent(Vector2(75, -225), directionalModifier: 1));
    sprites.add(GooterComponent(Vector2(-150, -150), directionalModifier: -1));
    sprites.add(GooterComponent(Vector2(0, -150), directionalModifier: -1));
    sprites.add(GooterComponent(Vector2(150, -150), directionalModifier: 1));
    sprites.add(GooterComponent(Vector2(-75, -75), directionalModifier: -1));
    sprites.add(GooterComponent(Vector2(75, -75), directionalModifier: 1));
    sprites.add(
        GooterComponent(Vector2(-150, 0), directionalModifier: 1)); //far left
    sprites.add(
        GooterComponent(Vector2(150, 0), directionalModifier: -1)); // far right
    sprites.add(GooterComponent(Vector2(-75, 75), directionalModifier: -1));
    sprites.add(GooterComponent(Vector2(75, 75), directionalModifier: 1));
    sprites.add(GooterComponent(Vector2(-150, 150), directionalModifier: -1));
    sprites.add(GooterComponent(Vector2(0, 150), directionalModifier: -1));
    sprites.add(GooterComponent(Vector2(150, 150), directionalModifier: 1));
    sprites.add(GooterComponent(Vector2(-75, 225), directionalModifier: 1));
    sprites.add(GooterComponent(Vector2(75, 225), directionalModifier: -1));
    sprites.add(
        GooterComponent(Vector2(0, 300), directionalModifier: -1)); //bottom

    sprites.add(GooterComponent(Vector2(0, 0), isMainGooter: true));
    for (var sprite in sprites) {
      await add(sprite);
    }

    // Paint dimming overlay.
    final dimOverlay = RectangleComponent.square(
      size: max(gameSize.x, gameSize.y),
      position: Vector2(0, 0),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.black.withOpacity(0.6),
    );
    add(dimOverlay);
  }

  /// Updates the UI to reflect a new beat occurrence.
  void beatUpdate() {
    sprites.forEach((sprite) {
      sprite.handleBeat(interval, beatCount);
    });
    beatCount++;
  }

  @override
  void render(Canvas canvas) {
    // Background color.
    if (beatCount >= 32) {
      canvas.drawColor(Colors.deepPurple, BlendMode.src);
    } else {
      canvas.drawColor(Colors.black, BlendMode.src);
    }
    super.render(canvas);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.gameSize = gameSize;
    position = gameSize / 2;
  }
}
