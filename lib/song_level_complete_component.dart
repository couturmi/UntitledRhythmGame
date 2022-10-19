import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled_rhythm_game/components/menu/play_button.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/components/scoring/song_score.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class SongLevelCompleteComponent extends Component
    with HasGameRef<MyGame>, GameSizeAware {
  NumberFormat commaNumberFormat = NumberFormat('#,##0', "en_US");

  final BeatMap songBeatMap;
  final SongScore songScore;

  late TextComponent _rankingLabel;

  SongLevelCompleteComponent({
    required this.songBeatMap,
    required this.songScore,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final String ranking = _calculateRanking();
    late final Color rankingColor;
    if (ranking == "SS") {
      rankingColor = Colors.amber;
    } else if (ranking == "oof") {
      rankingColor = Colors.red;
    } else {
      rankingColor = Colors.teal;
    }
    bool anyNotes = songScore.totalNotes > 0;
    bool anyObstacles = songScore.totalObstacles > 0;
    addAll([
      TextComponent(
        text: songBeatMap.songName,
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier', color: Colors.white, fontSize: 36)),
        position: Vector2(0, 50),
      ),
      TextComponent(
        text: "By: " + songBeatMap.artistName,
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier', color: Colors.white, fontSize: 36)),
        position: Vector2(0, 100),
      ),
      _rankingLabel = TextComponent(
        text: "Ranking",
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier', color: Colors.white, fontSize: 30)),
        position: Vector2(0, 200),
      ),
      TextComponent(
        priority: 1,
        text: ranking,
        textRenderer: TextPaint(
            style: TextStyle(
          color: rankingColor,
          fontSize: 76,
          fontWeight: FontWeight.bold,
        )),
        anchor: Anchor.centerLeft,
        position: Vector2(_rankingLabel.size.x + 10, 200),
      ),
      TextComponent(
        priority: 0,
        text: ranking,
        textRenderer: TextPaint(
            style: TextStyle(
                color: Colors.white,
                fontSize: 76,
                fontWeight: FontWeight.bold)),
        anchor: Anchor.centerLeft,
        position: Vector2(_rankingLabel.size.x + 10 - 2, 200 + 2),
      ),
      TextComponent(
        text: "Score: ${commaNumberFormat.format(songScore.score)}",
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier', color: Colors.teal, fontSize: 28)),
        anchor: Anchor.center,
        position: Vector2(gameSize.x / 2, gameSize.y / 2 - 25),
      ),
      if (anyNotes)
        TextComponent(
          text: "${calculateNotesHitPercentage()}% Notes Hit",
          textRenderer: TextPaint(
              style: TextStyle(
                  fontFamily: 'Courier', color: Colors.amber, fontSize: 28)),
          anchor: Anchor.center,
          position: Vector2(gameSize.x / 2, gameSize.y / 2 + 25),
        ),
      if (anyObstacles)
        TextComponent(
          text: "${calculateObstaclesAvoidedPercentage()}% Obstacles Avoided",
          textRenderer: TextPaint(
              style: TextStyle(
                  fontFamily: 'Courier', color: Colors.amber, fontSize: 24)),
          anchor: Anchor.center,
          position: Vector2(
              gameSize.x / 2, gameSize.y / 2 + 25 + (anyNotes ? 50 : 0)),
        ),
      TextComponent(
        text: "Longest Streak",
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier', color: Colors.red, fontSize: 24)),
        anchor: Anchor.center,
        position: Vector2(
            gameSize.x / 2,
            (gameSize.y / 2) +
                25 +
                (anyNotes ? 50 : 0) +
                (anyObstacles ? 50 : 0)),
      ),
      TextComponent(
        text: "${songScore.highestStreak} Notes!",
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier', color: Colors.red, fontSize: 28)),
        anchor: Anchor.center,
        position: Vector2(
            gameSize.x / 2,
            (gameSize.y / 2) +
                60 +
                (anyNotes ? 50 : 0) +
                (anyObstacles ? 50 : 0)),
      ),
      PlayButton(
        onButtonTap: goToMenu,
        anchor: Anchor.center,
        buttonText: "To Song Menu",
        position: Vector2(gameSize.x / 2, gameSize.y - 100),
      ),
    ]);
    FlameAudio.bgm.play(getLevelMP3PreviewPathMap(songBeatMap.level));
    // Print out info for debugging.
    print("Best Possible Score: ${songScore.bestPotentialScore}");
    print(
        "Total Notes Possible: ${songScore.notesHit + songScore.notesMissed}");
    print("Total Notes Hit: ${songScore.notesHit}");
    print(
        "Total Obstacles: ${songScore.obstaclesAvoided + songScore.obstaclesCollided}");
    print("Total Obstacles Avoided: ${songScore.obstaclesAvoided}");
  }

  String _calculateRanking() {
    final double totalPercentage =
        (((songScore.notesHit + songScore.obstaclesAvoided) /
                        (songScore.totalNotes + songScore.totalObstacles)) *
                    1000)
                .floor() /
            10;
    print("Total Weighted Ranking Percentage: $totalPercentage%");
    if (totalPercentage >= 100.0) {
      return "SS";
    } else if (totalPercentage >= 98.0) {
      return "S";
    } else if (totalPercentage >= 95.0) {
      return "A";
    } else if (totalPercentage >= 90.0) {
      return "B";
    } else if (totalPercentage >= 85.0) {
      return "C";
    } else if (totalPercentage >= 80.0) {
      return "D";
    }
    return "oof";
  }

  double calculateNotesHitPercentage() {
    return ((songScore.notesHit / (max(songScore.totalNotes, 1)) * 1000)
            .floor()) /
        10;
  }

  double calculateObstaclesAvoidedPercentage() {
    return ((songScore.obstaclesAvoided /
                (max(songScore.totalObstacles, 1)) *
                1000)
            .floor()) /
        10;
  }

  void goToMenu() {
    FlameAudio.play('effects/button_click.mp3');
    gameRef.router.popUntilNamed(GameRoutes.menuSongList.name);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    this.onResize(canvasSize);
  }
}
