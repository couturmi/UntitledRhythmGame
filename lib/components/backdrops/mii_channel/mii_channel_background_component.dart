import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';
import 'package:untitled_rhythm_game/components/level/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class MiiChannelBackgroundComponent extends LevelBackgroundComponent
    with HasGameRef {
  static const int checkerRows = 8;

  int beatCount = 0;
  late final SpriteComponent _miiSpriteComponent;
  late final Sprite? _miiPrimarySprite;
  late final Sprite? _miiSecondarySprite;
  late final List<List<RectangleComponent>> boardSquares = [];

  /// Returns the list of all note color options.
  List<Color> get _squareColors => [
        Colors.pinkAccent.shade100,
        Colors.green.shade300,
        Colors.orange.shade300,
        Colors.purple.shade300,
        Colors.red.shade300,
        Colors.yellow.shade300,
        Colors.teal.shade300,
        Colors.white,
        Colors.grey.shade300,
      ];
  late final Color defaultSquareColor1 = Colors.white;
  late final Color defaultSquareColor2 = Colors.grey.shade300;
  Random rand = Random();

  MiiChannelBackgroundComponent({required super.interval})
      : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = this.game.size / 2;
    size = Vector2.all(max(game.size.x * 1.5, game.size.y * 1.5));
    // Create checkered background
    for (int row = 0; row < checkerRows; row++) {
      boardSquares.add([]);
      for (int col = 0; col < checkerRows; col++) {
        late Color squareColor;
        // If even row and odd column OR
        // If odd row and even column
        if ((row % 2 == 0 && col % 2 == 1) || (row % 2 == 1 && col % 2 == 0)) {
          squareColor = defaultSquareColor2;
        } else {
          squareColor = defaultSquareColor1;
        }
        final RectangleComponent square = RectangleComponent.square(
          size: size.x / checkerRows,
          position:
              Vector2(col * size.x / checkerRows, row * size.x / checkerRows),
          paint: Paint()..color = squareColor,
        );
        boardSquares[row].add(square);
        add(square);
      }
    }
    // Add mii sprite.
    _miiPrimarySprite = await Sprite.load("mii_head.png");
    _miiSecondarySprite = await Sprite.load("mii_head_surprised.png");
    add(_miiSpriteComponent = SpriteComponent(
      priority: 1,
      sprite: _miiPrimarySprite,
      size: size / 6,
      anchor: Anchor.center,
      position: size / 2,
    ));
    _miiSpriteComponent.setOpacity(0);
    // Paint dimming overlay.
    final dimOverlay = RectangleComponent.square(
      priority: 100,
      size: size.x,
      position: Vector2(0, 0),
      paint: Paint()..color = Colors.black.withOpacity(0.15),
    );
    add(dimOverlay);
    await super.onLoad();
  }

  @override
  void beatUpdate() {
    int actualBeatCount =
        beatCount - SongLevelComponent.INTERVAL_TIMING_MULTIPLIER;

    if (actualBeatCount == 4) {
      _miiSpriteComponent.add(OpacityEffect.fadeIn(
          LinearEffectController(microsecondsToSeconds(this.interval) * 4)));
    } else if (actualBeatCount >= 36 && actualBeatCount < 62) {
      // pulse animation.
      final Effect pulseOutEffect = ScaleEffect.by(Vector2.all(1.070),
          LinearEffectController(microsecondsToSeconds(this.interval) * 0.25));
      pulseOutEffect.onComplete = () {
        _miiSpriteComponent.add(ScaleEffect.by(
            Vector2.all(0.975),
            LinearEffectController(
                microsecondsToSeconds(this.interval) * 0.75)));
      };
      _miiSpriteComponent.add(pulseOutEffect);
    } else if (actualBeatCount == 62) {
      _miiSpriteComponent.sprite = _miiSecondarySprite;
    } else if (actualBeatCount >= 68 && actualBeatCount < 128) {
      _updateCheckerboardColors();
      if (actualBeatCount == 68) {
        _miiSpriteComponent.sprite = _miiPrimarySprite;
        _miiSpriteComponent.scale = Vector2.all(1);
      }
      if (actualBeatCount == 101) {
        _miiSpriteComponent.setOpacity(0);
      }
    } else if (actualBeatCount == 128) {
      _updateCheckerboardColors(defaultSquareColor1, defaultSquareColor2);
    } else if (actualBeatCount == 164) {
      _miiSpriteComponent.add(OpacityEffect.fadeIn(
          LinearEffectController(microsecondsToSeconds(this.interval) * 2)));
    } else if (actualBeatCount >= 200 && actualBeatCount < 262) {
      _updateCheckerboardColors();
    } else if (actualBeatCount == 262) {
      _updateCheckerboardColors(defaultSquareColor1, defaultSquareColor2);
    } else if (actualBeatCount == 264) {
      _miiSpriteComponent.add(OpacityEffect.fadeOut(
          LinearEffectController(microsecondsToSeconds(this.interval))));
    }

    beatCount++;
  }

  void _updateCheckerboardColors(
      [Color? color1Override, Color? color2Override]) {
    final Color currentColor1 = boardSquares[0][0].paint.color;
    final Color currentColor2 = boardSquares[0][0].paint.color;
    Color newColor1 = color1Override ?? currentColor1;
    Color newColor2 = color2Override ?? currentColor2;
    // Select to new colors, making sure they are different than the last, and not equal to eachother.
    while (color1Override == null && newColor1 == currentColor1) {
      newColor1 = _squareColors[rand.nextInt(_squareColors.length)];
    }
    while (color2Override == null &&
        (newColor2 == currentColor2 || newColor2 == newColor1)) {
      newColor2 = _squareColors[rand.nextInt(_squareColors.length)];
    }
    // Update board with new colors.
    for (int row = 0; row < boardSquares.length; row++) {
      for (int col = 0; col < boardSquares[row].length; col++) {
        if ((row % 2 == 0 && col % 2 == 1) || (row % 2 == 1 && col % 2 == 0)) {
          boardSquares[row][col].paint.color = newColor2;
        } else {
          boardSquares[row][col].paint.color = newColor1;
        }
      }
    }
  }
}
