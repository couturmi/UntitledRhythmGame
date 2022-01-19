import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/megalovania/undertale_sprite_component.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';

class MegalovaniaBackgroundComponent extends PositionComponent
    with GameSizeAware {
  List<UndertaleSpriteComponent> sprites = [];
  final int interval;
  int beatCount = 0;

  MegalovaniaBackgroundComponent({required this.interval}) : super(priority: 0);

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    await loadSprites();
    await super.onLoad();
  }

  Future<void> loadSprites() async {
    // First Row
    sprites.add(
        UndertaleSpriteComponent(Vector2(0, -300), directionalModifier: -1));
    // Second Row
    sprites.add(
        UndertaleSpriteComponent(Vector2(-75, -225), directionalModifier: -1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(75, -225), directionalModifier: 1));
    // Third Row
    sprites.add(
        UndertaleSpriteComponent(Vector2(-150, -150), directionalModifier: -1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(0, -150), directionalModifier: -1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(150, -150), directionalModifier: 1));
    // Fourth Row
    sprites.add(
        UndertaleSpriteComponent(Vector2(-225, -75), directionalModifier: 1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(-75, -75), directionalModifier: -1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(75, -75), directionalModifier: 1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(225, -75), directionalModifier: 1));
    // Fifth Row
    sprites.add(
        UndertaleSpriteComponent(Vector2(-300, 0), directionalModifier: -1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(-150, 0), directionalModifier: 1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(150, 0), directionalModifier: -1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(300, 0), directionalModifier: -1));
    // Sixth Row
    sprites.add(
        UndertaleSpriteComponent(Vector2(-225, 75), directionalModifier: 1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(-75, 75), directionalModifier: -1));
    sprites
        .add(UndertaleSpriteComponent(Vector2(75, 75), directionalModifier: 1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(225, 75), directionalModifier: 1));
    // Seventh Row
    sprites.add(
        UndertaleSpriteComponent(Vector2(-150, 150), directionalModifier: -1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(0, 150), directionalModifier: -1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(150, 150), directionalModifier: 1));
    // Eighth Row
    sprites.add(
        UndertaleSpriteComponent(Vector2(-75, 225), directionalModifier: 1));
    sprites.add(
        UndertaleSpriteComponent(Vector2(75, 225), directionalModifier: -1));
    // Bottom Row
    sprites.add(
        UndertaleSpriteComponent(Vector2(0, 300), directionalModifier: -1));

    sprites.add(UndertaleSpriteComponent(Vector2(0, 0), isMainSprite: true));
    for (var sprite in sprites) {
      await add(sprite);
    }

    // Paint dimming overlay.
    final dimOverlay = RectangleComponent.square(
      size: max(gameSize.x, gameSize.y),
      scale: Vector2.all(1.5),
      position: Vector2(0, 0),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.black.withOpacity(0.6),
    );
    add(dimOverlay);
  }

  /// Updates the UI to reflect a new beat occurrence.
  void beatUpdate() {
    if (beatCount >= SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) {
      sprites.forEach((sprite) {
        sprite.handleBeat(interval, beatCount);
      });
    }
    beatCount++;
  }

  @override
  void render(Canvas canvas) {
    // Background color.
    if (beatCount >= 34) {
      canvas.drawColor(Colors.deepPurple, BlendMode.src);
    } else {
      canvas.drawColor(Colors.black, BlendMode.src);
    }
    super.render(canvas);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(gameSize);
    position = gameSize / 2;
  }
}
