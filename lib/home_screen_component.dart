import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/menu/play_button.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class HomeScreenComponent extends Component
    with HasGameRef<MyGame>, GameSizeAware {
  static const double backgroundCircleLifespan = 6.0;
  static const double backgroundCircleFadeTime = 1.0;
  late Timer backgroundCircleTimer;

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
    // Load background particle system.
    _addRandomBackgroundCircle();
    _addRandomBackgroundCircle();
    backgroundCircleTimer = Timer(0.5, repeat: true, onTick: () {
      _addRandomBackgroundCircle();
    });
    // Play menu music.
    FlameAudio.bgm.play('music/menu.mp3', volume: 0.8);
    FlameAudio.audioCache.load('effects/button_click.mp3');
  }

  void _addRandomBackgroundCircle() {
    Random rnd = Random();
    final circleComponent = CircleComponent(
      priority: -1,
      paint: Paint()..color = Colors.deepPurple,
      radius: max((gameSize.x / 2) * rnd.nextDouble(), gameSize.x * 0.2),
      anchor: Anchor.center,
      position:
          Vector2(gameSize.x * rnd.nextDouble(), gameSize.y * rnd.nextDouble()),
    );
    add(circleComponent);
    circleComponent.setOpacity(0);
    circleComponent.add(MoveEffect.by(
        (Vector2.random() - Vector2.random()) * 80,
        LinearEffectController(backgroundCircleLifespan)));
    circleComponent.add(OpacityEffect.to(max(rnd.nextDouble(), 0.4),
        LinearEffectController(backgroundCircleFadeTime)));
    circleComponent.add(OpacityEffect.fadeOut(
      DelayedEffectController(LinearEffectController(backgroundCircleFadeTime),
          delay: backgroundCircleLifespan - backgroundCircleFadeTime),
      onComplete: () {
        remove(circleComponent);
      },
    ));
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    this.onResize(canvasSize);
  }

  void goToMenu() {
    FlameAudio.play('effects/button_click.mp3', volume: 0.8);
    gameRef.router.pushNamed(GameRoutes.menuSongList.name);
  }

  @override
  void update(double dt) {
    backgroundCircleTimer.update(dt);
    super.update(dt);
  }
}
