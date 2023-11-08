import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_column.dart';
import 'package:untitled_rhythm_game/components/level/song_level_component.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class GiornosThemeBackgroundComponent extends LevelBackgroundComponent
    with HasGameRef<OffBeatGame> {
  final Color flashColor = Color(0xffecbb37);

  int beatCount = 0;

  late final RectangleComponent _background;
  late List<Shader> backgroundColors;
  late int backgroundColorIndex = 0;

  late final RectangleComponent _flash;
  int flashCount = 0;

  late final SpriteComponent _headSprite;

  late final List<Sprite> _beetleSpriteList;
  late final SpriteComponent _beetleSpriteComponent;
  int _beetleSpriteIndex = 0;

  late final SpriteComponent _titleSprite;
  late final SpriteComponent _titleFlashSprite1;
  late final SpriteComponent _titleFlashSprite2;

  GiornosThemeBackgroundComponent({required super.interval})
      : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = game.size / 2;
    final shaderShape = Rect.fromCircle(
      center: Offset(game.size.x, game.size.y),
      radius: game.size.x,
    );
    backgroundColors = [
      RadialGradient(
        colors: [
          Colors.purple.shade400,
          Colors.purple.shade400.darken(0.4),
        ],
      ).createShader(shaderShape),
      RadialGradient(
        colors: [
          Color(0xff4444f1),
          Color(0xff4444f1).darken(0.4),
        ],
      ).createShader(shaderShape),
      RadialGradient(
        colors: [
          flashColor,
          flashColor.darken(0.4),
        ],
      ).createShader(shaderShape),
    ];

    add(_background = RectangleComponent(
      priority: -5,
      paint: Paint()..shader = backgroundColors[backgroundColorIndex],
      anchor: Anchor.center,
      size: game.size * 2,
    ));
    add(_flash = RectangleComponent(
      priority: -4,
      paint: Paint()..color = flashColor,
      anchor: Anchor.center,
      size: game.size * 2,
    ));
    add(_titleFlashSprite1 = SpriteComponent(
      priority: 11,
      sprite: await Sprite.load("jojo_title_part1.png"),
      size: Vector2.all(game.size.x * 0.5),
      anchor: Anchor.center,
      position: Vector2(0, -game.size.y * 0.3),
    ));
    add(_titleFlashSprite2 = SpriteComponent(
      priority: 11,
      sprite: await Sprite.load("jojo_title_part2.png"),
      size: Vector2.all(game.size.x * 0.5),
      anchor: Anchor.center,
      position: Vector2(0, -game.size.y * 0.1),
    ));
    _flash.setOpacity(0);
    _titleFlashSprite1.setOpacity(0);
    _titleFlashSprite2.setOpacity(0);

    _beetleSpriteList = [
      await Sprite.load("jojo_beetle.png"),
      await Sprite.load("jojo_beetle_2.png"),
      await Sprite.load("jojo_beetle_3.png"),
      await Sprite.load("jojo_beetle_4.png"),
    ];
    double beetleSpriteYOffset = -50;
    add(_beetleSpriteComponent = SpriteComponent(
      priority: 0,
      sprite: _beetleSpriteList[_beetleSpriteIndex],
      size: Vector2.all(game.size.x),
      anchor: Anchor.center,
      position: Vector2(0, beetleSpriteYOffset),
    ));
    _beetleSpriteComponent.setOpacity(0);
    add(_headSprite = SpriteComponent(
      priority: 10,
      sprite: await Sprite.load("jojo_giorno_head.png"),
      size: Vector2.all(game.size.x * 2),
      anchor: Anchor.center,
      position: Vector2(
        0,
        (game.size.y * TapTapColumn.hitCircleYPlacementModifierDefault) -
            (game.size.y / 2),
      ),
    ));
    _headSprite.setOpacity(0);

    add(_titleSprite = SpriteComponent(
      priority: 1,
      sprite: await Sprite.load("jojo_title.png"),
      size: Vector2.all(game.size.x * 0.8),
      anchor: Anchor.center,
    ));
    _titleSprite.setOpacity(0);
    await super.onLoad();
  }

  @override
  void beatUpdate() {
    int actualBeatCount =
        beatCount - SongLevelComponent.INTERVAL_TIMING_MULTIPLIER;
    // Fade in head.
    if (actualBeatCount == 0) {
      _headSprite.add(OpacityEffect.fadeIn(
          LinearEffectController(microsecondsToSeconds(this.interval) * 2)));
    }
    // Fade in beetle.
    if (actualBeatCount == 16) {
      _beetleSpriteComponent.add(OpacityEffect.to(0.8,
          LinearEffectController(microsecondsToSeconds(this.interval) * 2)));
    }
    // beetle pulse animation.
    if ((actualBeatCount >= 18 && actualBeatCount < 66) ||
        actualBeatCount >= 82) {
      final Effect pulseOutEffect = ScaleEffect.to(Vector2.all(1.070),
          LinearEffectController(microsecondsToSeconds(this.interval) * 0.25));
      pulseOutEffect.onComplete = () {
        _beetleSpriteComponent.add(ScaleEffect.to(
            Vector2.all(1.0),
            LinearEffectController(
                microsecondsToSeconds(this.interval) * 0.75)));
      };
      _beetleSpriteComponent.add(pulseOutEffect);

      final Effect titlePulseOutEffect = ScaleEffect.to(Vector2.all(1.070),
          LinearEffectController(microsecondsToSeconds(this.interval) * 0.25));
      titlePulseOutEffect.onComplete = () {
        _titleSprite.add(ScaleEffect.to(
            Vector2.all(1.0),
            LinearEffectController(
                microsecondsToSeconds(this.interval) * 0.75)));
      };
      _titleSprite.add(titlePulseOutEffect);
    }
    // Fade out head
    if (actualBeatCount == 64) {
      _headSprite.add(OpacityEffect.fadeOut(
          LinearEffectController(microsecondsToSeconds(this.interval) * 2)));
    }
    // Stop the pulse.
    if (actualBeatCount == 66) {
      _beetleSpriteComponent.opacity = 1.0;
      _beetleSpriteIndex = 1;
      _beetleSpriteComponent.sprite = _beetleSpriteList[_beetleSpriteIndex];
      backgroundColorIndex = _beetleSpriteIndex;
      _background.paint.shader = backgroundColors[backgroundColorIndex];
    }
    // Building to the chorus color swapping.
    if (actualBeatCount >= 82 && actualBeatCount < 98) {
      _beetleSpriteIndex = (_beetleSpriteIndex + 1) % 2;
      _beetleSpriteComponent.sprite = _beetleSpriteList[_beetleSpriteIndex];
      backgroundColorIndex = _beetleSpriteIndex;
      _background.paint.shader = backgroundColors[backgroundColorIndex];
    }
    // Chorus color swapping.
    if (actualBeatCount == 98) {
      _titleSprite.setOpacity(1.0);
      backgroundColorIndex = -1;
    }
    if (actualBeatCount >= 98) {
      _beetleSpriteIndex = ((_beetleSpriteIndex + 1) % 2) + 2;
      _beetleSpriteComponent.sprite = _beetleSpriteList[_beetleSpriteIndex];
      backgroundColorIndex = ((backgroundColorIndex + 1) % 4);
      Shader backgroundColor;
      if (backgroundColorIndex.isEven) {
        backgroundColor = backgroundColors[2];
      } else {
        backgroundColor = backgroundColorIndex == 1
            ? backgroundColors[0]
            : backgroundColors[1];
      }
      _background.paint.shader = backgroundColor;
    }
    beatCount++;
  }

  @override
  void update(double dt) {
    int actualBeatCount =
        beatCount - SongLevelComponent.INTERVAL_TIMING_MULTIPLIER;
    // For handling any animations that aren't directly "on" beat.
    // Handle flashes on the bam bams
    if (actualBeatCount >= 34 && actualBeatCount < 66) {
      double intervalPercentage =
          (gameRef.currentLevel.songTime % microsecondsToSeconds(interval)) /
              microsecondsToSeconds(interval);
      bool isFirstBeatOfFlash = (actualBeatCount - 34) % 8 == 1;
      bool isSecondBeatOfFlash = (actualBeatCount - 34) % 8 == 2;
      bool isFifthBeatOfFlash = (actualBeatCount - 34) % 8 == 5;
      // Display the flashes and the title sprites.
      if (isFirstBeatOfFlash || isSecondBeatOfFlash) {
        if ((flashCount == 0 && isFirstBeatOfFlash) ||
            (flashCount == 1 &&
                isSecondBeatOfFlash &&
                intervalPercentage >= 0.5)) {
          _flash.setOpacity(1.0);
          if (isFirstBeatOfFlash) _titleFlashSprite1.setOpacity(1.0);
          if (isSecondBeatOfFlash) _titleFlashSprite2.setOpacity(1.0);
          _flash.add(OpacityEffect.fadeOut(
            DelayedEffectController(
                EffectController(
                    duration: microsecondsToSeconds(interval) *
                        (isFirstBeatOfFlash ? 0.75 : 1.25)),
                delay: microsecondsToSeconds(interval) * 0.25),
          ));
          flashCount++;
        }
      }
      // Fade out the titles sprites.
      else if (isFifthBeatOfFlash) {
        _titleFlashSprite1.add(
          OpacityEffect.fadeOut(EffectController(
            duration: microsecondsToSeconds(interval) * 2,
          )),
        );
        _titleFlashSprite2.add(
          OpacityEffect.fadeOut(EffectController(
            duration: microsecondsToSeconds(interval) * 2,
          )),
        );
      } else {
        flashCount = 0;
      }
    }
    super.update(dt);
  }
}
