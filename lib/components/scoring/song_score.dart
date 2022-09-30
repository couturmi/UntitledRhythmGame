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

  double _score = 0;
  double bestPotentialScore = 0;
  int streak = 0;
  int highestStreak = 0;
  int notesHit = 0;
  int notesMissed = 0;

  int get score => _score.floor();

  /// Returns the current note multiplier.
  int get noteMultiplier =>
      min((streak / _streakMultiplierThreshold).floor() + 1, _maxMultiplier);

  /// Returns the best multiplier that could be reached at this point in the level.
  int get _bestPotentialCurrentNoteMultiplier => min(
      ((notesHit + notesMissed) / _streakMultiplierThreshold).floor() + 1,
      _maxMultiplier);

  /// [durationOfBeatInterval]: the percentage of a full beat interval that this note is held. 0 by default, since most notes are not held.
  void hit(MiniGameType gameType, {double durationOfBeatInterval = 0}) {
    // Update score.
    _score += _getPointsByGameType(gameType);
    bestPotentialScore +=
        _getPointsByGameType(gameType, _bestPotentialCurrentNoteMultiplier);
    // Update best potential score for any additional duration points for held notes (if applicable).
    bestPotentialScore += _getPointsForHeldNotes(
        gameType, durationOfBeatInterval, _bestPotentialCurrentNoteMultiplier);
    // Update streak.
    streak += _getStreakWorth(gameType);
    if (streak > highestStreak) {
      highestStreak = streak;
    }
    // Update count of notes hit.
    notesHit++;
  }

  /// [durationOfBeatInterval]: the percentage of a full beat interval that this note is held.
  void heldNotePoint(MiniGameType gameType, double durationOfBeatInterval) {
    double pointsToAdd =
        _getPointsForHeldNotes(gameType, durationOfBeatInterval);
    _score += pointsToAdd;
  }

  /// [durationOfBeatInterval]: the percentage of a full beat interval that this note is held. 0 by default, since most notes are not held.
  void miss(MiniGameType gameType, {double durationOfBeatInterval = 0}) {
    streak = 0;
    // Update potential score to track best possible score.
    bestPotentialScore +=
        _getPointsByGameType(gameType, _bestPotentialCurrentNoteMultiplier);
    // Update best potential score for any additional duration points for held notes (if applicable).
    bestPotentialScore += _getPointsForHeldNotes(
        gameType, durationOfBeatInterval, _bestPotentialCurrentNoteMultiplier);
    // Update count of notes missed.
    notesMissed++;
  }

  int _getPointsByGameType(MiniGameType gameType, [int? customNoteMultiplier]) {
    late int basePoints;
    switch (gameType) {
      case MiniGameType.tapTap:
        basePoints = _tapTapNoteBasePoints;
        break;
      case MiniGameType.tapTap5:
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

  double _getPointsForHeldNotes(
      MiniGameType gameType, double durationOfBeatInterval,
      [int? customNoteMultiplier]) {
    return durationOfBeatInterval *
        (_getPointsByGameType(gameType, customNoteMultiplier) / 2);
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
