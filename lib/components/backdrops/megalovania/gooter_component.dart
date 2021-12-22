import 'dart:math';
import 'dart:async' as Async;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class GooterComponent extends SpriteComponent {
  bool visible = false;
  static const double defaultRadius = 128.0;
  double componentSize = defaultRadius;
  static const List<Color> _colorList = [
    Colors.red,
    Colors.blue,
    Colors.orange,
    Colors.green
  ];
  int colorIndex = 0;

  Vector2 positionOffset;
  bool isMainGooter;
  double directionalModifier;

  GooterComponent(this.positionOffset,
      {this.isMainGooter = false, this.directionalModifier = 1})
      : super(
            size: Vector2.all(
                !isMainGooter ? defaultRadius : defaultRadius * 1.2));

  Future<void> onLoad() async {
    Random random = Random();
    sprite =
        await Sprite.load(random.nextBool() ? 'trevbot.jpg' : 'gooter.jpg');
    anchor = Anchor.center;

    colorIndex = random.nextInt(4);

    // set starting state.
    if (isMainGooter) {
      visible = true;
      componentSize = defaultRadius * 1.2;
    } else {
      visible = false;
    }

    await super.onLoad();
  }

  void handleBeat(int interval, int beatCount) {
    // When the drop hits.
    if (beatCount >= 31) {
      // When the cymbals triple crash
      if ((beatCount - 31) % 16 == 14) {
        if (isMainGooter) {
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
      } else if ((beatCount - 31) % 16 == 15) {
        // do nothing.
      } else {
        flipHorizontally();
        // change color
        paint
          ..colorFilter =
              ColorFilter.mode(_colorList[colorIndex], BlendMode.overlay);
        if (colorIndex == _colorList.length - 1) {
          colorIndex = 0;
        } else {
          colorIndex++;
        }

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
    else if (beatCount >= 16) {
      flipHorizontally();
    } else if (beatCount == 15 && !isMainGooter) {
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
