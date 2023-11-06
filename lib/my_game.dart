import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/rendering.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/menu/pause_menu_button.dart';
import 'package:untitled_rhythm_game/home_screen_component.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/components/level/song_level_component.dart';
import 'package:untitled_rhythm_game/song_list_menu_component.dart';

enum GameRoutes {
  home,
  menuSongList,
  pause,
  level,
}

class MyGame extends FlameGame with HasCollisionDetection {
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
          GameRoutes.menuSongList.name: Route(SongListMenuComponent.new),
          GameRoutes.pause.name: PauseRoute(),
        },
        initialRoute: 'home',
      ),
    );
  }

  /// Route to a [SongLevelComponent] for the given [beatMap]/level.
  void startSongLevel(BeatMap beatMap) {
    currentLevel = SongLevelComponent(beatMap: beatMap);
    router.pushRoute(Route(() => currentLevel));
  }

  /// Restarts the [currentLevel] from the beginning.
  void restartSongLevel() {
    currentLevel.removeFromParent();
    router.pop();
    currentLevel = SongLevelComponent(beatMap: currentLevel.beatMap);
    router.pushRoute(Route(() => currentLevel));
  }

  /// Leave the [SongLevelComponent] and return to the song menu.
  void returnToSongMenu() {
    router.pushNamed(GameRoutes.menuSongList.name);
    SongListMenuComponent.playSongPreview();
  }
}

class PauseRoute extends Route with HasGameRef<MyGame> {
  PauseRoute() : super(PausePage.new, transparent: true);

  @override
  void onPush(Route? previousRoute) {
    // Not sure if this stuff should be here, on in the song component somehow?
    gameRef.currentLevel.pause();
    previousRoute!
      ..stopTime()
      ..addRenderEffect(
        PaintDecorator.grayscale(opacity: 0.5)..addBlur(3.0),
      );
  }

  @override
  void onPop(Route previousRoute) {
    // Not sure if this stuff should be here, on in the song component somehow?
    gameRef.currentLevel.resume();
    previousRoute
      ..resumeTime()
      ..removeRenderEffect();
  }
}

class PausePage extends PositionComponent
    with TapCallbacks, HasGameRef<MyGame> {
  DeviceOrientation? orientation;

  PausePage() : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final game = findGame()!;
    position = game.canvasSize / 2;
    addAll([
      TextComponent(
        text: 'PAUSED',
        position: Vector2(0, -50),
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
      PauseMenuButton(
        buttonText: "Return to Menu",
        position: Vector2(0, 25),
        anchor: Anchor.center,
        onButtonTap: () => gameRef.returnToSongMenu(),
      ),
      PauseMenuButton(
        buttonText: "Restart Song",
        position: Vector2(0, 75),
        anchor: Anchor.center,
        onButtonTap: () => gameRef.restartSongLevel(),
      ),
      PauseMenuButton(
        buttonText: "Keep Playing",
        position: Vector2(0, 125),
        anchor: Anchor.center,
        onButtonTap: () => gameRef.router.pop(),
      ),
    ]);
    super.onLoad();
  }

  void setRotation() {
    orientation = gameRef.currentLevel.currentLevelOrientation;
    late double rotationAngle;
    if (orientation == DeviceOrientation.landscapeLeft) {
      rotationAngle = pi / 2;
    } else if (orientation == DeviceOrientation.landscapeRight) {
      rotationAngle = -pi / 2;
    } else {
      rotationAngle = 0.0;
    }
    // Rotate entire level component.
    angle = rotationAngle;
  }

  @override
  void update(double dt) {
    if (orientation != gameRef.currentLevel.currentLevelOrientation) {
      setRotation();
    }
    super.update(dt);
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) {
    FlameAudio.play('effects/button_click.mp3');
    gameRef.router.pop();
  }
}
