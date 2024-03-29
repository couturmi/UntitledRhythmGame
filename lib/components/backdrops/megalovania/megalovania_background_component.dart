import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';
import 'package:untitled_rhythm_game/components/backdrops/megalovania/undertale_sprite_component.dart';
import 'package:untitled_rhythm_game/components/level/song_level_component.dart';

class MegalovaniaBackgroundComponent extends LevelBackgroundComponent
    with HasGameRef {
  List<UndertaleSpriteComponent> sprites = [];
  int beatCount = 0;

  MegalovaniaBackgroundComponent({required super.interval});

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    position = this.game.size / 2;
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
      size: max(game.size.x * 1.5, game.size.y * 1.5),
      position: Vector2(0, 0),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.black.withOpacity(0.6),
    );
    add(dimOverlay);
  }

  /// Updates the UI to reflect a new beat occurrence.
  @override
  void beatUpdate() {
    beatCount++;
  }

  @override
  void update(double dt) {
    sprites.forEach((sprite) {
      sprite.handleBeat(
          interval, beatCount - SongLevelComponent.INTERVAL_TIMING_MULTIPLIER);
    });
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Background color depending on what part of the song its in.
    int actualBeatCount =
        beatCount - SongLevelComponent.INTERVAL_TIMING_MULTIPLIER;
    if (actualBeatCount >= 289) {
      canvas.drawColor(Colors.black, BlendMode.src);
    } else if (actualBeatCount >= 193) {
      canvas.drawColor(
          beatCount.isOdd ? Colors.deepPurple.shade900 : Colors.deepPurple,
          BlendMode.src);
    } else if (actualBeatCount >= 161) {
      canvas.drawColor(Colors.black, BlendMode.src);
    } else if (actualBeatCount >= 33) {
      canvas.drawColor(Colors.deepPurple, BlendMode.src);
    } else {
      canvas.drawColor(Colors.black, BlendMode.src);
    }
    super.render(canvas);
  }
}
