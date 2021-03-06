import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/menu/play_button.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';

class MyGame extends FlameGame with HasTappables {
  late SongLevelComponent currentLevel;

  /// TODO This is a temporary flag until this annoying onGameResize issue is fixed.
  bool isCorrectGameSizeSet = false;
  bool onLoadOccurred = false;
  bool componentsAdded = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    onLoadOccurred = true;
    if (isCorrectGameSizeSet) {
      componentsAdded = true;
      addComponents();
    }

    // Preload all songs.
    Level.values.forEach((level) {
      FlameAudio.audioCache.load(getLevelMP3PathMap(level));
    });
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    if (!componentsAdded) {
      if (!isCorrectGameSizeSet) {
        if (canvasSize.x > 0 && canvasSize.y > 0) {
          isCorrectGameSizeSet = true;
          if (onLoadOccurred) {
            componentsAdded = true;
            addComponents();
          }
        }
      }
    }
  }

  void addComponents() {
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
  }

  void startLevel() {
    children.clear();
    currentLevel = SongLevelComponent(songLevel: Level.megalovania);
    add(currentLevel);
  }
}

main() {
  // Force portrait orientation before starting app.
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    // Run game.
    runApp(
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: GameWidget(
          game: MyGame(),
        ),
      ),
    );
  });
}
