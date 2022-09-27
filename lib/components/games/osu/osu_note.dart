import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/osu/osu_note_bar.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';

class OsuNote extends PositionComponent with HasGameRef<MyGame> {
  /// Scale of the timing ring when the note is created.
  static const double timingRingStartingScale = 2.5;

  /// Represents how close the timing ring is to completion to
  /// consider a note hit successful.
  static const double timingRingHitAllowanceModifier = 0.2;

  /// Current color of this note group. This value updates when the next note
  /// with a label "1" is added.
  static int currentNoteColorIndex = -1;

  /// Duration (in percentage of an interval) that this note should be held after being tapped.
  /// A note with no holding will have a [holdDuration] of 0;
  final double holdDuration;

  /// Number of times the note should reverse after reaching the end of its hold duration.
  /// This will essentially mean the "total" hold duration is: ([holdDuration] * [reversals]).
  final int reversals;

  /// Used to track the number of reversals that have occurred.
  int _currentReverseCount;

  /// Time (in seconds) that this note was expected to be loaded.
  final double expectedTimeOfStart;

  /// Represents the exact song time (in seconds) that the score was updated for holding the note.
  double? lastPointUpdateTime;

  /// Time (in seconds) of a single beat.
  final double beatInterval;

  /// Max time (in seconds) that the note is able to be tapped.
  final double timeNoteIsInQueue;

  /// For held notes, the position that the note should be dragged to, relative to the starting position.
  final Vector2 endRelativePosition;

  /// Number label displayed on the note.
  final String label;

  /// Ring used to determine the timing of the note.
  late final CircleComponent _timingRing;

  /// Color of this note.
  late final Color noteColor;

  late final CircleComponent _noteFill;
  late final CircleComponent _noteBorder;
  late final SpriteComponent _sprite;
  late final TextComponent _labelComponent;
  OsuNoteBar? _noteBar;

  OsuNote({
    required double diameter,
    super.position,
    required this.endRelativePosition,
    super.anchor,
    super.priority,
    required this.holdDuration,
    required this.reversals,
    required this.expectedTimeOfStart,
    required this.timeNoteIsInQueue,
    required this.beatInterval,
    required this.label,
  })  : _currentReverseCount = 0,
        super(
          size: Vector2.all(diameter),
        ) {
    // If this is a new group, update the color index.
    if (label == "1") {
      currentNoteColorIndex++;
      if (currentNoteColorIndex > _noteColors.length - 1) {
        currentNoteColorIndex = 0;
      }
    }
    noteColor = _noteColors[currentNoteColorIndex];
  }

  /// Returns the list of all note color options.
  List<Color> get _noteColors => [
        Colors.pinkAccent.shade200,
        Colors.green.shade700,
        Colors.blue.shade900,
        Colors.orange.shade700,
        Colors.purple,
        Colors.red.shade900,
        Colors.amber,
      ];

  double get currentTimingOfNote =>
      gameRef.currentLevel.songTime - expectedTimeOfStart;

  /// Relevant to held notes only. Represents the exact time the note is expected to finish.
  double get expectedTimeOfFinish =>
      expectedTimeOfStart +
      (beatInterval *
          (SongLevelComponent.INTERVAL_TIMING_MULTIPLIER +
              (holdDuration * (reversals + 1))));

  /// Gives the current position of the tappable note circle, relative to the parent's area.
  Vector2 get currentPositionOfNoteCircle =>
      position + _noteFill.position - (size / 2);

  /// Gives the current absolute position of the tappable note circle (center).
  Vector2 get currentAbsoluteCenterOfNoteCircle => _noteFill.absoluteCenter;

  Future<void> onLoad() async {
    add(_noteFill = CircleComponent(
      paint: Paint()..color = noteColor,
      radius: size.x / 2,
      position: size / 2,
      anchor: Anchor.center,
      priority: 1,
    ));
    add(_sprite = SpriteComponent(
      sprite: await Sprite.load('osu_note.png'),
      size: size,
      position: size / 2,
      anchor: Anchor.center,
      priority: 2,
    ));
    add(_noteBorder = CircleComponent(
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
      radius: size.x / 2 -
          3, // the -3 here is because the stroke goes outside of the radius that the [_noteFill] renders.
      position: size / 2,
      anchor: Anchor.center,
      priority: 3,
    ));
    add(_labelComponent = TextComponent(
      text: label,
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: TextStyle(
        color: Colors.white,
        fontSize: 60,
        fontFamily: 'Courier',
        fontWeight: FontWeight.bold,
      )),
      priority: 3,
    ));
    // Set opacity to hidden, and add animation to fade in.
    // Note: Both the timing ring and the text component do not fade in.
    _noteFill.setOpacity(0);
    _noteBorder.setOpacity(0);
    _sprite.setOpacity(0);
    double currentTiming = currentTimingOfNote;
    _noteFill.add(OpacityEffect.fadeIn(
        LinearEffectController(beatInterval - currentTiming)));
    _noteBorder.add(OpacityEffect.fadeIn(
        LinearEffectController(beatInterval - currentTiming)));
    _sprite.add(OpacityEffect.fadeIn(
        LinearEffectController(beatInterval - currentTiming)));
    // Create timing ring component and add scaling effect.
    _timingRing = CircleComponent(
      radius: size.x / 2,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = noteColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
      priority: 2,
    );
    final double currentProgress = currentTiming / timeNoteIsInQueue;
    _timingRing.scale = Vector2.all(
      timingRingStartingScale -
          (min(currentProgress, 1) * timingRingStartingScale),
    );
    add(_timingRing);
    _timingRing.add(
      ScaleEffect.to(
          Vector2.all(1),
          LinearEffectController(
              (beatInterval * SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) -
                  currentTiming)),
    );

    // Add note bar if it is a held note.
    if (holdDuration > 0) {
      add(_noteBar = OsuNoteBar(
        startCircleCenterPosition: size / 2,
        endCircleCenterPosition: endRelativePosition + (size / 2),
        noteRadius: size.x / 2,
        showEndReverseArrow: reversals > 0,
        showStartReverseArrow: reversals > 1,
        paint: Paint()..color = noteColor.darken(0.2),
        priority: 0,
      ));
      _noteBar!.setOpacity(0);
      _noteBar!.add(OpacityEffect.fadeIn(
          LinearEffectController(beatInterval - currentTiming)));
    }
    await super.onLoad();
  }

  /// Check if the current hit timing would result in a successful hit.
  bool isHitTimingSuccessful() {
    return _timingRing.scale.x <= 1 + timingRingHitAllowanceModifier;
  }

  /// Called if a note is tapped and cleared successfully.
  void hit() {
    // Remove all active effects.
    children.removeWhere((c) => c is Effect);
    // update with glow.
    _sprite.paint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
      ..colorFilter = ColorFilter.mode(Colors.white, BlendMode.overlay);
    // Provide haptic feedback.
    HapticFeedback.mediumImpact();
    if (_noteBar != null) {
      _labelComponent.scale = Vector2.all(0);
      // Expand timing ring so timing can be seen under your finger.
      _timingRing
          .add(ScaleEffect.to(Vector2.all(2.0), LinearEffectController(0.1)));
      // Move note along the NoteBar path. Any reversals occur automatically.
      _timingRing.add(MoveEffect.to(
          endRelativePosition + (size / 2),
          _OsuReversalEffectController(
            effectDuration: beatInterval * holdDuration,
            reversals: reversals,
          )));
      _sprite.add(MoveEffect.to(
          endRelativePosition + (size / 2),
          _OsuReversalEffectController(
            effectDuration: beatInterval * holdDuration,
            reversals: reversals,
          )));
      _noteBorder.add(MoveEffect.to(
          endRelativePosition + (size / 2),
          _OsuReversalEffectController(
            effectDuration: beatInterval * holdDuration,
            reversals: reversals,
          )));
      // Manually create the alternating effect in order to track when each end is reached.
      _noteFill.add(MoveEffect.to(
          endRelativePosition + (size / 2),
          _OsuReversalEffectController(
            effectDuration: beatInterval * holdDuration,
            reversals: reversals,
            onEffectCompleted: _onReversal,
          )));
      // set last point update time to the start of the note hit.
      lastPointUpdateTime = gameRef.currentLevel.songTime;
    } else {
      _timingRing.scale = Vector2.all(0);
      // remove the note after a short time of displaying.
      add(RemoveEffect(delay: 0.1));
    }
  }

  /// When a drag note reversal occurs, check if an arrow should be removed
  /// from either end of the note.
  void _onReversal() {
    _currentReverseCount++;
    if (reversals - _currentReverseCount == 1) {
      reversals.isOdd
          ? _noteBar?.hideStartReverseArrow()
          : _noteBar?.hideEndReverseArrow();
    } else if (reversals - _currentReverseCount == 0) {
      reversals.isOdd
          ? _noteBar?.hideEndReverseArrow()
          : _noteBar?.hideStartReverseArrow();
    }
  }

  /// Called when the player is dragging within range of the note.
  void inDraggingRange() {
    // Only take action if player is re-entering dragging range.
    if (lastPointUpdateTime == null) {
      // lastPointUpdateTime should be reset to notify parent that this note should now be awarding points
      lastPointUpdateTime = gameRef.currentLevel.songTime;
      // Expand timing ring so timing can be seen under your finger.
      _timingRing.children.removeWhere((c) => c is ScaleEffect);
      _timingRing
          .add(ScaleEffect.to(Vector2.all(2.0), LinearEffectController(0.1)));
    }
  }

  /// Called when the player is no longer dragging within range of the note.
  void leftDraggingRange() {
    // Only take action if player was last within range.
    if (lastPointUpdateTime != null) {
      // Clear lastPointUpdateTime to notify parent that this note should no longer be awarding points.
      lastPointUpdateTime = null;
      // Shrink timing ring to let user know they are no longer in range.
      _timingRing.children.removeWhere((c) => c is ScaleEffect);
      _timingRing
          .add(ScaleEffect.to(Vector2.all(1.0), LinearEffectController(0.1)));
    }
  }

  /// Called when the the end of the held note was reached.
  void endOfNoteBarReached() {
    // If player was in range of note when it ended, add HapticFeedback.
    if (lastPointUpdateTime != null) {
      HapticFeedback.mediumImpact();
    }
    // remove the note after a short time of displaying.
    fadeOutAndRemove(duration: 0.1, delay: 0.1);
  }

  /// If in range, update score for a held note (since the last time it was updated).
  void updateHeldNoteScoreIfInRange() {
    if (lastPointUpdateTime != null) {
      late double percentageOfBeatInterval;
      bool isNoteDurationFinished =
          gameRef.currentLevel.songTime >= expectedTimeOfFinish;
      if (isNoteDurationFinished) {
        percentageOfBeatInterval =
            (expectedTimeOfFinish - lastPointUpdateTime!) / beatInterval;
      } else {
        percentageOfBeatInterval =
            (gameRef.currentLevel.songTime - lastPointUpdateTime!) /
                beatInterval;
      }
      if (percentageOfBeatInterval > 0) {
        gameRef.currentLevel.scoreComponent
            .noteHeld(MiniGameType.osu, percentageOfBeatInterval);
      }
      // Update last updated score to now.
      lastPointUpdateTime = gameRef.currentLevel.songTime;
    }
  }

  /// Called if a note is missed completely and the player has horribly failed.
  void missed() {
    // Remove all active effects.
    children.removeWhere((c) => c is Effect);
    // update with red glow.
    _sprite.paint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
      ..colorFilter =
          ColorFilter.mode(Colors.red.withOpacity(0.5), BlendMode.overlay);
    // Add a fade out and fall effect.
    add(MoveEffect.by(Vector2(0, 25), LinearEffectController(0.2)));
    fadeOutAndRemove(duration: 0.2);
  }

  void fadeOutAndRemove({
    required double duration,
    double delay = 0.0,
  }) {
    _timingRing.add(OpacityEffect.fadeOut(DelayedEffectController(
        LinearEffectController(duration),
        delay: delay)));
    _noteFill.add(OpacityEffect.fadeOut(DelayedEffectController(
        LinearEffectController(duration),
        delay: delay)));
    _noteBorder.add(OpacityEffect.fadeOut(DelayedEffectController(
        LinearEffectController(duration),
        delay: delay)));
    _sprite.add(OpacityEffect.fadeOut(DelayedEffectController(
        LinearEffectController(duration),
        delay: delay)));
    _noteBar?.add(OpacityEffect.fadeOut(DelayedEffectController(
        LinearEffectController(duration),
        delay: delay)));
    // remove the note after a short time of displaying.
    add(RemoveEffect(delay: duration + delay));
  }
}

class _OsuReversalEffectController extends _OsuSequenceEffectController {
  final double effectDuration;
  final int reversals;
  final Function? onEffectCompleted;

  _OsuReversalEffectController({
    required this.effectDuration,
    required this.reversals,
    this.onEffectCompleted,
  }) : super(
          buildEffectList(reversals, effectDuration),
          onEffectCompleted: onEffectCompleted,
        );

  static List<EffectController> buildEffectList(
      int reversals, double effectDuration) {
    List<EffectController> effectList = [];
    for (int i = 0; i <= reversals; i++) {
      if (i.isEven) {
        effectList.add(LinearEffectController(effectDuration));
      } else {
        effectList.add(ReverseLinearEffectController(effectDuration));
      }
    }
    return effectList;
  }
}

class _OsuSequenceEffectController extends SequenceEffectController {
  int _effectsCompleted;

  final Function? onEffectCompleted;

  _OsuSequenceEffectController(super.controllers, {this.onEffectCompleted})
      : _effectsCompleted = 0;

  @override
  double advance(double dt) {
    var t = super.advance(dt);
    // check if a child effect was completed.
    for (int i = _effectsCompleted; i < children.length; i++) {
      if (children[i].completed) {
        _effectsCompleted++;
        onEffectCompleted?.call();
      }
    }
    return t;
  }
}
