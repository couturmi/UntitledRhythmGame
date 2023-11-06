import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class UndertaleSpriteComponent extends SpriteComponent with HasGameRef<OffBeatGame> {
  bool visible = false;
  static const double defaultRadius = 128.0;
  double componentSize = defaultRadius;
  Sprite? mainSprite;
  Sprite? secondarySprite;

  Vector2 positionOffset;
  bool isMainSprite;
  double directionalModifier;

  int _cymbalCrashes = 0;

  UndertaleSpriteComponent(this.positionOffset,
      {this.isMainSprite = false, this.directionalModifier = 1})
      : super(
            size: Vector2.all(
                !isMainSprite ? defaultRadius : defaultRadius * 1.2));

  Future<void> onLoad() async {
    mainSprite = await Sprite.load(isMainSprite ? 'sans.png' : 'dragon.png');
    secondarySprite =
        await Sprite.load(isMainSprite ? 'sans_eye.png' : 'dragon_eye.png');
    sprite = mainSprite;
    anchor = Anchor.center;

    // set starting state.
    if (isMainSprite) {
      visible = true;
      componentSize = defaultRadius * 1.2;
    } else {
      visible = false;
    }

    await super.onLoad();
  }

  void handleBeat(int interval, int beatCount) async {
    double intervalPercentage =
        (gameRef.currentLevel.songTime % microsecondsToSeconds(interval)) /
            microsecondsToSeconds(interval);
    // Last beats of the song.
    if (beatCount >= 289) {
      sprite = mainSprite;
      if (isMainSprite) {
        size = Vector2.all(componentSize);
        transform.angle = 0;
      } else {
        size = Vector2.all(0);
      }
    }
    // Things slow down a bit here.
    else if (beatCount >= 161) {
      transform.angle = 0;
      scale.x = beatCount.isEven ? scale.x.abs() : -scale.x.abs();
      size = intervalPercentage < 0.5
          ? Vector2.all(componentSize) * 1.3
          : Vector2.all(componentSize);
    }
    // When the initial beat drop hits.
    else if (beatCount >= 33) {
      // switch sprites when beat drops.
      if (beatCount == 33) {
        sprite = secondarySprite;
      }
      // When the cymbals triple crash
      bool isFirstBeatOfCrash = (beatCount - 33) % 16 == 14;
      bool isSecondBeatOfCrash = (beatCount - 33) % 16 == 15;
      if (isFirstBeatOfCrash || isSecondBeatOfCrash) {
        if (isMainSprite) {
          // If start of cymbal crashes.
          if (_cymbalCrashes == 0) {
            visible = true; // TODO needed?
            paint..colorFilter = null;
            transform.angle = 0;
            size = Vector2.all(componentSize) * 0.8;
            add(_quickZoomEffect(interval));
            _cymbalCrashes++;
          }
          // If time for second crash.
          else if (_cymbalCrashes == 1 &&
              isFirstBeatOfCrash &&
              (intervalPercentage * interval) >= ((interval * 2) / 3)) {
            add(_quickZoomEffect(interval));
            _cymbalCrashes++;
          }
          // If time for third crash.
          else if (_cymbalCrashes == 2 &&
              isSecondBeatOfCrash &&
              (intervalPercentage * interval) >= ((interval) / 3)) {
            add(_quickZoomEffect(interval));
            _cymbalCrashes++;
          }
        } else {
          size = Vector2.all(0);
        }
      } else {
        _cymbalCrashes = 0;
        scale.x = beatCount.isEven ? scale.x.abs() : -scale.x.abs();

        // change size and rotation
        size = intervalPercentage < 0.5
            ? Vector2.all(componentSize) * 1.3
            : Vector2.all(componentSize);
        double angleSize = 0.7;
        transform.angle = directionalModifier *
            (intervalPercentage < 0.5
                ? -angleSize + (intervalPercentage * (angleSize * 4))
                : angleSize -
                    ((intervalPercentage * (angleSize * 4)) - (angleSize * 2)));
      }
    }
    // When the beat starts picking up
    else if (beatCount >= 17) {
      scale.x = beatCount.isEven ? scale.x.abs() : -scale.x.abs();
    } else if (beatCount == 15 && !isMainSprite) {
      show();
    }
  }

  /// Set to visible and give a default size;
  void show() {
    visible = true;
    size = Vector2.all(componentSize);
  }

  Effect _quickZoomEffect(int interval) {
    return SizeEffect.by(Vector2.all(200),
        LinearEffectController(((((interval * 2) / 3) / 4) / 1000000)));
  }

  @override
  void render(Canvas canvas) {
    if (!visible) {
      size = Vector2.all(0);
    }
    super.render(canvas);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = positionOffset;
  }
}
