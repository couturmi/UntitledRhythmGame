import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/menu/pause_button.dart';
import 'package:untitled_rhythm_game/components/scoring/score_multiplier_component.dart';
import 'package:untitled_rhythm_game/components/scoring/song_score.dart';

class ScoreComponent extends PositionComponent with HasGameRef {
  NumberFormat commaNumberFormat = NumberFormat('#,##0', "en_US");

  SongScore songScore;

  bool isScoringEnabled = false;

  late TextComponent _scoreComponent;
  late ScoreMultiplierComponent _scoreMultiplierComponent;
  late PauseButton _pauseButton;

  ScoreComponent()
      : songScore = SongScore(),
        super(priority: 10);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
    position = game.size / 2;
    _scoreComponent = TextComponent(
      text: songScore.score.toString(),
      textRenderer: TextPaint(
          style: TextStyle(color: Colors.yellowAccent[100], fontSize: 20)),
      scale: Vector2.all(2),
      anchor: Anchor.topLeft,
    );
    _scoreMultiplierComponent = ScoreMultiplierComponent(
      anchor: Anchor.topLeft,
      multiplier: songScore.noteMultiplier,
    );
    _pauseButton = PauseButton(
      anchor: Anchor.topLeft,
    );
    _pauseButton.hide();
    add(_scoreComponent);
    add(_scoreMultiplierComponent);
    add(_pauseButton);
    resetWithGivenDimensions(game.size);
  }

  void resetStreak() {
    if (isScoringEnabled) {
      songScore.streak = 0;
      _scoreMultiplierComponent.multiplier = songScore.noteMultiplier;
    }
  }

  void missed(MiniGameType gameType, {double durationOfBeatInterval = 0}) {
    if (isScoringEnabled) {
      songScore.miss(gameType, durationOfBeatInterval: durationOfBeatInterval);
      _scoreMultiplierComponent.multiplier = songScore.noteMultiplier;
    }
  }

  void noteHit(MiniGameType gameType, {double durationOfBeatInterval = 0}) {
    if (isScoringEnabled) {
      songScore.hit(gameType, durationOfBeatInterval: durationOfBeatInterval);
      _scoreMultiplierComponent.multiplier = songScore.noteMultiplier;
    }
  }

  void noteHeld(MiniGameType gameType, double percentageOfBeatInterval) {
    if (isScoringEnabled) {
      songScore.heldNotePoint(gameType, percentageOfBeatInterval);
    }
  }

  /// Occurs after an obstacle was successfully avoided for games that have obstacles, rather than notes.
  void avoidedObstacle() {
    if (isScoringEnabled) {
      songScore.avoidedObstacle();
    }
  }

  /// Occurs after a collision for games that have obstacles, rather than notes.
  void collision(MiniGameType gameType) {
    if (isScoringEnabled) {
      songScore.collision(gameType);
      _scoreMultiplierComponent.multiplier = songScore.noteMultiplier;
    }
  }

  void enableScoring() {
    isScoringEnabled = true;
    _pauseButton.show();
  }

  void disableScoring() {
    isScoringEnabled = false;
    _pauseButton.hide();
  }

  @override
  void update(double dt) {
    _scoreComponent.text = '${commaNumberFormat.format(songScore.score)}';
  }

  void resetWithGivenDimensions(Vector2 levelSize) {
    _scoreComponent.position =
        Vector2(-(levelSize.x / 2) + 10, -(levelSize.y / 2) + 10);
    _scoreMultiplierComponent.position =
        Vector2((levelSize.x / 2) - 10, -(levelSize.y / 2) + 10);
    _pauseButton.position = Vector2(-20, -(levelSize.y / 2) + 10);
  }
}
