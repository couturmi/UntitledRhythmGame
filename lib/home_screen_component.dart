import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:untitled_rhythm_game/components/menu/play_button.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class HomeScreenComponent extends Component
    with HasGameRef<MyGame>, GameSizeAware {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    addAll([
      SpriteComponent(
        sprite:
            await Sprite.load('off_beat_title.png', srcSize: Vector2.all(990)),
        anchor: Anchor.center,
        size: Vector2.all(gameSize.x - 75),
        position: gameSize / 2 - Vector2(0, 150),
      ),
      PlayButton(
        onButtonTap: goToMenu,
        anchor: Anchor.center,
        buttonText: "S T A R T",
        position: gameSize / 2 + Vector2(0, 50),
      ),
    ]);
    // Play menu music.
    FlameAudio.bgm.play('music/menu.mp3');
    FlameAudio.audioCache.load('effects/button_click.mp3');
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    this.onResize(canvasSize);
  }

  void goToMenu() {
    FlameAudio.play('effects/button_click.mp3');
    gameRef.router.pushNamed(GameRoutes.menuSongList.name);
  }
}
