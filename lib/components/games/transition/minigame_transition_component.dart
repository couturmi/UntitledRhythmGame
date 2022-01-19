import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/main.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class GameTransitionComponent extends MiniGameComponent
    with HasGameRef<MyGame> {
  static const String firstGameTitle = "F I R S T   U P";
  static const String nextUpTitle = "N E X T   U P";

  /// Next mini-game after this transition.
  final MiniGameType nextMiniGameType;

  /// The type of device orientation this transition should rotate to.
  final DeviceOrientation newOrientation;

  /// True if this transition is for introducing the first game of the level.
  final bool isStartingTransition;

  late final Component title;
  late final Component subTitle;

  GameTransitionComponent(MiniGameModel model,
      {required this.nextMiniGameType, this.isStartingTransition = false})
      : newOrientation = getOrientationForMiniGame(nextMiniGameType),
        super(model: model);

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    title = TextComponent(
      text: isStartingTransition ? firstGameTitle : nextUpTitle,
      textRenderer: TextPaint(
          style: TextStyle(
              color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
      position: Vector2(0, -50),
      anchor: Anchor.center,
    );
    subTitle = TextComponent(
      text: getMiniGameName(nextMiniGameType).toUpperCase(),
      textRenderer: TextPaint(
          style: TextStyle(
              color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
      position: Vector2(0, 10),
      anchor: Anchor.center,
    );
    super.onLoad();
  }

  @override
  void handleNote({required int interval, required NoteModel noteModel}) {
    // Add Title.
    if (miniGameBeatCount ==
        SongLevelComponent.INTERVAL_TIMING_MULTIPLIER - 2) {
      add(title);
    }
    // Add Subtitle.
    if (miniGameBeatCount == SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) {
      add(subTitle);
    }
    // Rotate component.
    if (miniGameBeatCount ==
        SongLevelComponent.INTERVAL_TIMING_MULTIPLIER + 2) {
      int currentOrientationWeight =
          getOrientationWeight(gameRef.currentLevel.currentLevelOrientation);
      int newOrientationWeight = getOrientationWeight(newOrientation);
      double rotationAngle =
          (currentOrientationWeight - newOrientationWeight) * (pi / 2);
      add(RotateEffect.to(
          rotationAngle,
          LinearEffectController(
            microsecondsToSeconds(interval * 2),
          )));
      gameRef.currentLevel.backgroundComponent.add(RotateEffect.to(
          rotationAngle,
          LinearEffectController(
            microsecondsToSeconds(interval * 2),
          )));
    }
    // Hide component and rotate entire level if necessary
    else if (model.beats.length - 1 == miniGameBeatCount) {
      removeAll(children);
      if (newOrientation != gameRef.currentLevel.currentLevelOrientation) {
        gameRef.currentLevel.backgroundComponent.angle = 0;
        gameRef.currentLevel.rotateLevel(newOrientation);
      }
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = gameSize / 2;
  }

  /// Returns a 'weight' value assigned to a specific [DeviceOrientation] that
  /// helps with rotation calculations.
  int getOrientationWeight(DeviceOrientation orientation) {
    if (orientation == DeviceOrientation.landscapeLeft) return 0;
    if (orientation == DeviceOrientation.landscapeRight) return 2;
    return 1;
  }
}
