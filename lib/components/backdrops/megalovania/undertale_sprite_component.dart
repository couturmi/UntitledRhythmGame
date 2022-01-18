import 'dart:async' as Async;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class UndertaleSpriteComponent extends SpriteComponent {
  bool visible = false;
  static const double defaultRadius = 128.0;
  double componentSize = defaultRadius;
  Sprite? mainSprite;
  Sprite? secondarySprite;

  Vector2 positionOffset;
  bool isMainSprite;
  double directionalModifier;

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
    // When the beat drop hits.
    if (beatCount >= 33) {
      // switch sprites when beat drops.
      if (beatCount == 33) {
        sprite = secondarySprite;
      }
      // When the cymbals triple crash
      if ((beatCount - 33) % 16 == 14) {
        if (isMainSprite) {
          visible = true;
          paint..colorFilter = null;
          transform.angle = 0;
          size = Vector2.all(componentSize) * 0.8;
          add(_quickZoomEffect(interval));
          int cymbalCrashes = 1;
          Async.Timer.periodic(
              Duration(microseconds: ((interval * 2) / 3).round()), (timer) {
            cymbalCrashes++;
            add(_quickZoomEffect(interval));
            if (cymbalCrashes == 3) {
              timer.cancel();
            }
          });
        } else {
          size = Vector2.all(0);
        }
      } else if ((beatCount - 33) % 16 == 15) {
        // do nothing.
      } else {
        flipHorizontally();

        // change size
        size = Vector2.all(componentSize) * 1.3;
        add(RotateEffect.to(0.5 * directionalModifier,
            LinearEffectController(microsecondsToSeconds(interval / 2))));
        Async.Timer(Duration(microseconds: (interval / 2).round()), () {
          size = Vector2.all(componentSize);
          add(RotateEffect.to(-0.5 * directionalModifier,
              LinearEffectController(microsecondsToSeconds(interval / 2))));
        });
      }
    }
    // When the beat starts picking up
    else if (beatCount >= 18) {
      flipHorizontally();
    } else if (beatCount == 16 && !isMainSprite) {
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
