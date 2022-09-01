import 'dart:math';

import 'package:untitled_rhythm_game/components/games/minigame_type.dart';

class SongScore {
  /// The streak amount that must be reached before the next score multiplier is applied.
  static const _streakMultiplierThreshold = 10;

  /// Max multiplier the player can reach from a note streak.
  static const _maxMultiplier = 4;

  /// Base points earned for successfully hitting a TapTap note.
  static const int _tapTapNoteBasePoints = 100;

  /// Base points earned for successfully hitting an OSU note.
  static const _osuNoteBasePoints = 100;

  /// Base points earned for successfully hitting a Tilt note.
  static const _tiltNoteBasePoints = 75;

  /// Base points earned for successfully hitting a Slide/Drag note.
  static const _slideNoteBasePoints = 75;

  /// Base points earned for successfully avoiding a Swipe/Dodge obstacle.
  static const _swipeObstacleBasePoints = 150;

  int _score = 0;
  int bestPotentialScore = 0;
  int streak = 0;
  int highestStreak = 0;
  int notesHit = 0;
  int notesMissed = 0;

  int get score => _score;

  /// Returns the current note multiplier.
  int get noteMultiplier =>
      min((streak / _streakMultiplierThreshold).floor() + 1, _maxMultiplier);

  /// Returns the best multiplier that could be reached at this point in the level.
  int get _bestPotentialCurrentNoteMultiplier => min(
      ((notesHit + notesMissed) / _streakMultiplierThreshold).floor() + 1,
      _maxMultiplier);

  void hit(MiniGameType gameType) {
    // Update score.
    _score += _getPointsByGameType(gameType);
    bestPotentialScore +=
        _getPointsByGameType(gameType, _bestPotentialCurrentNoteMultiplier);
    // Update streak.
    streak += _getStreakWorth(gameType);
    if (streak > highestStreak) {
      highestStreak = streak;
    }
    // Update count of notes hit.
    notesHit++;
  }

  void miss(MiniGameType gameType) {
    streak = 0;
    // Update potential score to track best possible score.
    bestPotentialScore +=
        _getPointsByGameType(gameType, _bestPotentialCurrentNoteMultiplier);
    // Update count of notes missed.
    notesMissed++;
  }

  int _getPointsByGameType(MiniGameType gameType, [int? customNoteMultiplier]) {
    late int basePoints;
    switch (gameType) {
      case MiniGameType.tapTap:
        basePoints = _tapTapNoteBasePoints;
        break;
      case MiniGameType.osu:
        basePoints = _osuNoteBasePoints;
        break;
      case MiniGameType.tilt:
        basePoints = _tiltNoteBasePoints;
        break;
      case MiniGameType.slide:
        basePoints = _slideNoteBasePoints;
        break;
      case MiniGameType.swipe:
        basePoints = _swipeObstacleBasePoints;
        break;
      case MiniGameType.gameTransition:
        basePoints = 0;
        break;
    }
    return basePoints * (customNoteMultiplier ?? noteMultiplier);
  }

  /// Returns the worth that a single note hit has toward a streak.
  int _getStreakWorth(MiniGameType gameType) {
    switch (gameType) {
      case MiniGameType.swipe:
        return 2; // Streak is increased faster since there are less chances.
      default:
        return 1;
    }
  }
}
