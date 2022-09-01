import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/menu/pause_button.dart';
import 'package:untitled_rhythm_game/components/scoring/score_multiplier_component.dart';
import 'package:untitled_rhythm_game/components/scoring/song_score.dart';

class ScoreComponent extends PositionComponent {
  NumberFormat commaNumberFormat = NumberFormat('#,##0', "en_US");

  SongScore songScore;

  late TextComponent _scoreComponent;
  late ScoreMultiplierComponent _scoreMultiplierComponent;

  ScoreComponent()
      : songScore = SongScore(),
        super(priority: 10);

  void resetStreak() {
    songScore.streak = 0;
    _scoreMultiplierComponent.multiplier = songScore.noteMultiplier;
  }

  void missed(MiniGameType gameType) {
    songScore.miss(gameType);
    _scoreMultiplierComponent.multiplier = songScore.noteMultiplier;
  }

  void noteHit(MiniGameType gameType) {
    songScore.hit(gameType);
    _scoreMultiplierComponent.multiplier = songScore.noteMultiplier;
  }

  @override
  void update(double dt) {
    _scoreComponent.text = '${commaNumberFormat.format(songScore.score)}';
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
    children.removeWhere((c) => true);
    _scoreComponent = TextComponent(
      text: songScore.score.toString(),
      textRenderer: TextPaint(
          style: TextStyle(color: Colors.yellowAccent[100], fontSize: 20)),
      position: Vector2(-(gameSize.x / 2) + 10, -(gameSize.y / 2) + 10),
      scale: Vector2.all(2),
      anchor: Anchor.topLeft,
    );
    _scoreMultiplierComponent = ScoreMultiplierComponent(
      position: Vector2((gameSize.x / 2) - 10, -(gameSize.y / 2) + 10),
      anchor: Anchor.topLeft,
      multiplier: songScore.noteMultiplier,
    );
    add(_scoreComponent);
    add(_scoreMultiplierComponent);
    add(PauseButton(
      position: Vector2(-20, -(gameSize.y / 2) + 10),
      anchor: Anchor.topLeft,
    ));
  }
}
