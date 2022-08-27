import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/menu/play_button.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class HomeScreenComponent extends Component with HasGameRef<MyGame> {
  late final TextComponent _title;
  late final TextComponent _title2;
  late final TextComponent _title3;
  late final PlayButton _playButton;

  HomeScreenComponent() {
    addAll([
      _title = TextComponent(
        priority: 0,
        text: "Untitled",
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier', color: Colors.white, fontSize: 36)),
        anchor: Anchor.center,
      ),
      _title2 = TextComponent(
        priority: 0,
        text: "R H Y T H M",
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier',
                color: Colors.teal,
                fontSize: 42,
                fontWeight: FontWeight.bold)),
        anchor: Anchor.center,
      ),
      _title3 = TextComponent(
        priority: 0,
        text: "Game",
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier', color: Colors.white, fontSize: 36)),
        anchor: Anchor.center,
      ),
      _playButton = PlayButton(
        onButtonTap: goToMenu,
        anchor: Anchor.center,
        buttonText: "S T A R T",
      ),
    ]);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Play menu music.
    FlameAudio.bgm.play('music/menu.mp3');
    FlameAudio.audioCache.load('effects/button_click.mp3');
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _title.position = canvasSize / 2 - Vector2(0, 175);
    _title2.position = canvasSize / 2 - Vector2(0, 124);
    _title3.position = canvasSize / 2 - Vector2(0, 75);
    _playButton.position = canvasSize / 2 + Vector2(0, 25);
  }

  void goToMenu() {
    FlameAudio.play('effects/button_click.mp3');
    gameRef.router.pushNamed(GameRoutes.menuSongList.name);
  }
}
