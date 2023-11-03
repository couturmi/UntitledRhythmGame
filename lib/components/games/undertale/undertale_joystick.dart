import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class UndertaleJoystick extends PositionComponent with HasGameRef<MyGame> {
  final double _knobRadius;
  final Vector2 _baseKnobPosition;

  /// The amount the knob is dragged from the center, scaled to fit inside the
  /// bounds of the joystick.
  final Vector2 delta = Vector2.zero();

  /// The total amount the knob is dragged from the center of the joystick.
  final Vector2 _unscaledDelta = Vector2.zero();

  /// The percentage `[0.0, 1.0]` the knob is dragged from the center to the
  /// edge.
  double intensity = 0.0;

  late final CircleComponent _knob;

  UndertaleJoystick({super.position, required super.size, super.anchor})
      : _knobRadius = size!.x / 3,
        _baseKnobPosition = size / 2;

  @override
  Future<void> onLoad() async {
    // Joystick background
    add(CircleComponent(
      priority: 0,
      radius: size.x / 2,
      anchor: Anchor.center,
      position: _baseKnobPosition,
      paint: Paint()..color = Colors.white.withOpacity(0.6),
    ));
    // Joystick knob
    add(_knob = CircleComponent(
      priority: 1,
      radius: size.x / 4,
      anchor: Anchor.center,
      position: _baseKnobPosition,
      paint: Paint()..color = Colors.white,
    ));
    super.onLoad();
  }

  /// Returns the direction the joystick is facing (in radians)
  double? getCurrentDirection() {
    if (delta.isZero()) {
      return null;
    }
    return delta.screenAngle() - (pi / 2);
  }

  void onDragUpdate(DragUpdateEvent event) {
    _unscaledDelta.add(event.delta);
  }

  void onDragEnd() {
    _unscaledDelta.setZero();
  }

  @override
  void update(double dt) {
    final knobRadius2 = _knobRadius * _knobRadius;
    delta.setFrom(_unscaledDelta);
    if (delta.isZero() && _baseKnobPosition != _knob.position) {
      _knob.position = _baseKnobPosition;
    } else if (delta.length2 > knobRadius2) {
      delta.scaleTo(_knobRadius);
    }
    if (!delta.isZero()) {
      _knob.position
        ..setFrom(_baseKnobPosition)
        ..add(delta);
    }
    intensity = delta.length2 / knobRadius2;
    super.update(dt);
  }
}
