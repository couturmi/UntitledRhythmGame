import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';

class GiornosThemeBackgroundComponent extends LevelBackgroundComponent
    with HasGameRef {
  GiornosThemeBackgroundComponent({required super.interval});

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    position = this.game.size / 2;
    await super.onLoad();
  }

  @override
  void beatUpdate() {
    // TODO: implement beatUpdate
  }

  @override
  void render(Canvas canvas) {
    canvas.drawColor(Colors.purple.shade400, BlendMode.src);
    super.render(canvas);
  }
}
