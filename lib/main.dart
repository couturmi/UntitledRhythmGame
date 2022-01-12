import 'package:flame/components.dart';
import 'dart:async' as Async;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/menu/play_button.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';

class MyGame extends FlameGame with HasTappables {
  late SongLevelComponent currentLevel;

  @override
  Future<void> onLoad() async {
    add(TextComponent(
      priority: 0,
      text: "Megalovania?",
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 26)),
      anchor: Anchor.center,
      position: size / 2 - Vector2(0, 150),
    ));
    add(PlayButton(
      onButtonTap: startLevel,
      anchor: Anchor.center,
      position: size / 2,
    ));
    await super.onLoad();
  }

  startLevel() {
    children.clear();
    currentLevel = SongLevelComponent(songLevel: Level.megalovania);
    add(currentLevel);
  }
}

main() {
  final myGame = MyGame();
  runApp(
    GameWidget(
      game: myGame,
    ),
  );
}
