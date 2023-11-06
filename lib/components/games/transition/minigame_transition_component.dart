import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/components/level/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class GameTransitionComponent extends MiniGameComponent
    with HasGameRef<OffBeatGame> {
  static const int TRANSITION_BEAT_COUNT = 8;

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
  Component? subTitle2;

  GameTransitionComponent(
      {required this.nextMiniGameType,
      this.isStartingTransition = false,
      required super.model,
      required super.beatInterval})
      : newOrientation = getOrientationForMiniGame(nextMiniGameType);

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    String subtitleLine2 = getMiniGameNameLine2(nextMiniGameType);
    bool hasTwoLines = subtitleLine2.isNotEmpty;
    double yCenter = hasTwoLines ? -50 : -20;

    title = TextComponent(
      text: isStartingTransition ? firstGameTitle : nextUpTitle,
      textRenderer: TextPaint(
          style: TextStyle(
              color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
      position: Vector2(0, yCenter - 30),
      anchor: Anchor.center,
    );
    subTitle = TextComponent(
      text: getMiniGameName(nextMiniGameType).toUpperCase(),
      textRenderer: TextPaint(
          style: TextStyle(
              color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
      position: Vector2(0, yCenter + 30),
      anchor: Anchor.center,
    );
    if (hasTwoLines) {
      subTitle2 = TextComponent(
        text: subtitleLine2.toUpperCase(),
        textRenderer: TextPaint(
            style: TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.bold)),
        position: Vector2(0, yCenter + 95),
        anchor: Anchor.center,
      );
    }
    super.onLoad();
  }

  @override
  void handleNote({
    required int exactTiming,
    required NoteModel noteModel,
  }) {
    // Add Title.
    if (miniGameBeatCount ==
        SongLevelComponent.INTERVAL_TIMING_MULTIPLIER - 2) {
      add(title);
    }
    // Add Subtitle.
    if (miniGameBeatCount == SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) {
      add(subTitle);
      if (subTitle2 != null) {
        add(subTitle2!);
      }
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
            microsecondsToSeconds(beatInterval * 2),
          )));
      gameRef.currentLevel.backgroundComponent.add(RotateEffect.to(
          rotationAngle,
          LinearEffectController(
            microsecondsToSeconds(beatInterval * 2),
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
