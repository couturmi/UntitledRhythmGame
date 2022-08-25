import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/rendering.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:untitled_rhythm_game/home_screen_component.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';

enum GameRoutes {
  home,
  pause,
  level,
}

class MyGame extends FlameGame with HasTappableComponents, HasDraggables {
  late final RouterComponent router;
  late SongLevelComponent currentLevel;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    FlameAudio.bgm.initialize();
    add(
      router = RouterComponent(
        routes: {
          GameRoutes.home.name: Route(HomeScreenComponent.new),
          GameRoutes.pause.name: PauseRoute(),
          GameRoutes.level.name: Route(() {
            currentLevel = SongLevelComponent(songLevel: Level.megalovania);
            return currentLevel;
          }),
        },
        initialRoute: 'home',
      ),
    );
  }
}

class PauseRoute extends Route {
  PauseRoute() : super(PausePage.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    previousRoute!
      ..stopTime()
      ..addRenderEffect(
        PaintDecorator.grayscale(opacity: 0.5)..addBlur(3.0),
      );
  }

  @override
  void onPop(Route previousRoute) {
    previousRoute
      ..resumeTime()
      ..removeRenderEffect();
  }
}

class PausePage extends Component with TapCallbacks, HasGameRef<MyGame> {
  @override
  Future<void> onLoad() async {
    final game = findGame()!;
    addAll([
      TextComponent(
        text: 'PAUSED',
        position: game.canvasSize / 2,
        anchor: Anchor.center,
        children: [
          ScaleEffect.to(
            Vector2.all(1.1),
            EffectController(
              duration: 0.3,
              alternate: true,
              infinite: true,
            ),
          )
        ],
      ),
    ]);
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) {
    FlameAudio.play('effects/button_click.mp3');
    gameRef.router.pop();
  }
}
