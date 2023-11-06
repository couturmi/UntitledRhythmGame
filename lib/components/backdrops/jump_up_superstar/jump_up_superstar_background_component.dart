import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class JumpUpSuperStarBackgroundComponent extends LevelBackgroundComponent
    with HasGameRef<OffBeatGame> {
  static const double defaultSpriteRadius = 200.0;

  int beatCount = 0;
  late final SpriteAnimationComponent _marioSpriteGif;

  JumpUpSuperStarBackgroundComponent({required super.interval});

  @override
  Future<void> onLoad() async {
    position = this.game.size / 2;
    Sprite marioSpriteSheet =
        await Sprite.load('mario_running_sprite_sheet.png');
    await add(_marioSpriteGif = SpriteAnimationComponent(
      animation: SpriteAnimation.fromFrameData(
        marioSpriteSheet.image,
        SpriteAnimationData.sequenced(
          amount: 12,
          textureSize: Vector2.all(200),
          // Make the step time to the rhythm of the song.
          stepTime: _beatInterval() / 6,
          loop: true,
        ),
      ),
      anchor: Anchor.center,
      size: Vector2.all(defaultSpriteRadius),
      position: Vector2(-(game.size.x / 2 + defaultSpriteRadius), 0),
      removeOnFinish: false,
    ));

    // Paint dimming overlay.
    // final dimOverlay = RectangleComponent.square(
    //   size: max(gameSize.x * 1.5, gameSize.y * 1.5),
    //   position: Vector2(0, 0),
    //   anchor: Anchor.center,
    //   paint: Paint()..color = Colors.black.withOpacity(0.1),
    // );
    // add(dimOverlay);
    await super.onLoad();
  }

  @override
  void beatUpdate() {
    // Move Mario across the screen.
    if (beatCount == 0) {
      final runAcrossMoveEffect = MoveEffect.to(
          Vector2(game.size.x / 2 + defaultSpriteRadius, 0),
          LinearEffectController(_beatInterval() * 16));
      runAcrossMoveEffect.onComplete = () {
        // set up next position.
        _marioSpriteGif.position = Vector2(
            -(game.size.x / 2 + defaultSpriteRadius),
            game.size.y / 2 + defaultSpriteRadius);
      };
      _marioSpriteGif.add(runAcrossMoveEffect);
    }
    // Mario quickly jumps up from the bottom.
    else if (beatCount == 19) {
      final jumpUpMoveEffect = MoveEffect.to(
          Vector2(-50, -75), LinearEffectController(_beatInterval() * 1.35));
      jumpUpMoveEffect.onComplete = () {
        // Fall back down a bit.
        _marioSpriteGif.add(MoveEffect.to(
            Vector2.all(0), LinearEffectController(_beatInterval() * 0.4)));
      };
      _marioSpriteGif.add(jumpUpMoveEffect);
    }
    // Move Mario off the screen (he is going to be skydiving soon!).
    else if (beatCount == 36) {
      final runAwayMoveEffect = MoveEffect.to(
          Vector2(game.size.x / 2 + defaultSpriteRadius, 0),
          LinearEffectController(_beatInterval() * 4));
      runAwayMoveEffect.onComplete = () {
        // set up next position.
        _marioSpriteGif.position =
            Vector2(-(game.size.y / 2 + defaultSpriteRadius), 0);
      };
      _marioSpriteGif.add(runAwayMoveEffect);
    }
    // Move Mario back into frame.
    else if (beatCount == 76) {
      final runIntoFrameMoveEffect = MoveEffect.to(
        Vector2.all(0),
        LinearEffectController(_beatInterval() * 4),
      );
      _marioSpriteGif.add(runIntoFrameMoveEffect);
    }
    // Mario runs off screen for the ending.
    // 187 is very ending
    else if (beatCount == 146) {
      final runAwayMoveEffect = MoveEffect.to(
          Vector2(game.size.x / 2 + defaultSpriteRadius, 0),
          LinearEffectController(_beatInterval() * 4));
      _marioSpriteGif.add(runAwayMoveEffect);
    }

    beatCount++;
  }

  /// In seconds.
  double _beatInterval() {
    return microsecondsToSeconds(gameRef.currentLevel.beatMap.beatInterval);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawColor(Colors.red.shade700, BlendMode.src);
    super.render(canvas);
  }
}
