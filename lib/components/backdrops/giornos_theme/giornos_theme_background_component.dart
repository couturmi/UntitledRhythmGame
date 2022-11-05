import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';

class GiornosThemeBackgroundComponent extends LevelBackgroundComponent
    with GameSizeAware {
  GiornosThemeBackgroundComponent({required super.interval});

  @override
  void beatUpdate() {
    // TODO: implement beatUpdate
  }

  @override
  void render(Canvas canvas) {
    canvas.drawColor(Colors.purple.shade400, BlendMode.src);
    super.render(canvas);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    this.onResize(canvasSize);
    position = this.gameSize / 2;
  }
}
