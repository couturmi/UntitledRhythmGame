import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';

class JumpUpSuperStarBackgroundComponent extends LevelBackgroundComponent
    with GameSizeAware {
  JumpUpSuperStarBackgroundComponent({required super.interval});

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: gameSize,
      paint: Paint()..color = Colors.red.shade800,
    ));
    await super.onLoad();
  }

  @override
  void beatUpdate() {
    // TODO: implement beatUpdate
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(gameSize);
  }
}
