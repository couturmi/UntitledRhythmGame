import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled_rhythm_game/components/games/osu/osu_scoring.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_scoring.dart';
import 'package:untitled_rhythm_game/components/games/tilt/tilt_scoring.dart';
import 'package:untitled_rhythm_game/components/scoring/score_multiplier_component.dart';

class ScoreComponent extends PositionComponent
    implements TapTapScoring, OsuScoring, TiltScoring {
  /// The streak amount that must be reached before the next score multiplier is applied.
  static const _streakMultiplierThreshold = 10;

  NumberFormat commaNumberFormat = NumberFormat('#,##0', "en_US");

  int score;
  int streak;

  late TextComponent _scoreComponent;
  late ScoreMultiplierComponent _scoreMultiplierComponent;

  ScoreComponent()
      : score = 0,
        streak = 0,
        super(priority: 10);

  int get noteMultiplier =>
      min((streak / _streakMultiplierThreshold).floor() + 1, 4);

  void resetStreak() {
    streak = 0;
    _scoreMultiplierComponent.multiplier = noteMultiplier;
  }

  @override
  void tapTapHit() async {
    streak++;
    score += TapTapScoring.noteBasePoints * noteMultiplier;
    _scoreMultiplierComponent.multiplier = noteMultiplier;
  }

  @override
  void osuHit() async {
    streak++;
    score += OsuScoring.noteBasePoints * noteMultiplier;
    _scoreMultiplierComponent.multiplier = noteMultiplier;
  }

  @override
  void tiltHit() {
    streak++;
    score += TiltScoring.noteBasePoints * noteMultiplier;
    _scoreMultiplierComponent.multiplier = noteMultiplier;
  }

  @override
  void update(double dt) {
    _scoreComponent.text = '${commaNumberFormat.format(score)}';
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    // set initial properties if needed
    if (position == Vector2.zero()) {
      anchor = Anchor.center;
      position = gameSize / 2;
    }
    // rebuild child widgets
    children.clear();
    _scoreComponent = TextComponent(
      text: score.toString(),
      textRenderer: TextPaint(
          style: TextStyle(color: Colors.yellowAccent[100], fontSize: 20)),
      position: Vector2(-(gameSize.x / 2) + 10, -(gameSize.y / 2) + 10),
      scale: Vector2.all(2),
      anchor: Anchor.topLeft,
    );
    _scoreMultiplierComponent = ScoreMultiplierComponent(
      position: Vector2((gameSize.x / 2) - 10, -(gameSize.y / 2) + 10),
      anchor: Anchor.topLeft,
      multiplier: noteMultiplier,
    );
    add(_scoreComponent);
    add(_scoreMultiplierComponent);
  }
}
