import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_scoring.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/components/scoring/score_multiplier_component.dart';

class ScoreComponent extends PositionComponent
    with GameSizeAware
    implements TapTapScoring {
  /// The streak amount that must be reached before the next score multiplier is applied.
  static const _streakMultiplierThreshold = 10;

  NumberFormat commaNumberFormat = NumberFormat('#,##0', "en_US");

  int score;
  int streak;

  late TextComponent _scoreComponent;
  late ScoreMultiplierComponent _scoreMultiplierComponent;

  ScoreComponent()
      : score = 0,
        streak = 0;

  int get noteMultiplier =>
      min((streak / _streakMultiplierThreshold).floor() + 1, 4);

  void resetStreak() {
    streak = 0;
    _scoreMultiplierComponent.multiplier = noteMultiplier;
  }

  @override
  void tapTapHit() async {
    streak++;
    int multiplier = noteMultiplier;
    score += TapTapScoring.noteBasePoints * multiplier;
    _scoreMultiplierComponent.multiplier = multiplier;
  }

  @override
  Future<void> onLoad() async {
    _scoreComponent = TextComponent(
      text: '0',
      textRenderer: TextPaint(
          style: TextStyle(color: Colors.yellowAccent[100], fontSize: 20)),
      position: Vector2(10, 20),
      scale: Vector2.all(2),
      anchor: Anchor.topLeft,
    );
    _scoreMultiplierComponent = ScoreMultiplierComponent(
      position: Vector2(gameSize.x - 10, 20),
      anchor: Anchor.topLeft,
    );
    add(_scoreComponent);
    add(_scoreMultiplierComponent);
    super.onLoad();
  }

  @override
  void update(double dt) {
    _scoreComponent.text = '${commaNumberFormat.format(score)}';
  }

  @override
  void onGameResize(Vector2 gameSize) {
    this.onResize(gameSize);
    super.onGameResize(gameSize);
  }
}
