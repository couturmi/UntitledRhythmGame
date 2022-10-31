import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';

class MiiChannelBackgroundComponent extends LevelBackgroundComponent
    with GameSizeAware {
  MiiChannelBackgroundComponent({required super.interval});

  @override
  Future<void> onLoad() async {
    // Paint dimming overlay.
    final dimOverlay = RectangleComponent.square(
      size: max(gameSize.x * 1.5, gameSize.y * 1.5),
      position: Vector2(0, 0),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.black.withOpacity(0.15),
    );
    add(dimOverlay);
    await super.onLoad();
  }

  @override
  void beatUpdate() {
    // TODO: implement beatUpdate
  }

  @override
  void render(Canvas canvas) {
    canvas.drawColor(Colors.white, BlendMode.src);
    super.render(canvas);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    this.onResize(canvasSize);
    position = this.gameSize / 2;
  }
}
