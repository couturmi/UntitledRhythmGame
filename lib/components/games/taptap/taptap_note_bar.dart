import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';

class TapTapNoteBar extends PositionComponent with GameSizeAware {
  /// Duration (in percentage of an interval) that this note should be held after being tapped.
  /// A note with no holding will have a [holdDuration] of 0;
  final double holdDuration;

  /// True when the note is being held by the player.
  bool isBeingHeld = false;

  late final RectangleComponent _barFill;
  late final RectangleComponent _barBorder;

  TapTapNoteBar({
    super.position,
    super.anchor,
    super.priority,
    super.size,
    required this.holdDuration,
  });

  Future<void> onLoad() async {
    if (holdDuration > 0) {
      add(_barFill = RectangleComponent(
        priority: 1,
        paint: Paint()..color = Colors.blue.shade700,
        anchor: Anchor.bottomRight,
        position: size,
        size: size,
      ));
      add(_barBorder = RectangleComponent(
        priority: 0,
        paint: Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
        anchor: Anchor.bottomRight,
        position: size,
        size: size,
      ));
    }
    await super.onLoad();
  }

  void holding() {
    isBeingHeld = true;
    _barFill.paint.color = Colors.lightBlue.shade300;
    _barBorder.paint.color = Colors.lightBlue.shade100;
  }

  void dead() {
    isBeingHeld = false;
    _barFill.paint.color = Colors.grey.shade700;
    _barBorder.paint.color = Colors.grey;
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(gameSize);
  }
}
