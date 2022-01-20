import 'dart:async';
import 'dart:math';

import 'package:flame/effects.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/tilt/pendulum_sprite_component.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class TiltGameComponent extends MiniGameComponent with GameSizeAware {
  static const double pendulumSize = 350;
  late double maxPendulumAngle;
  late StreamSubscription gyroListenerSubscription;
  late PendulumSpriteComponent pendulum;
  RotateEffect? pendulumRotateEffect;
  double pendulumTargetAngle = 0.0;

  TiltGameComponent(MiniGameModel model) : super(model: model);

  @override
  Future<void> onLoad() async {
    // calculate the maximum pendulum angle based on the device width. GEOMETRY BITCH.
    maxPendulumAngle = atan((gameSize.x / 4) / pendulumSize);
    pendulum = PendulumSpriteComponent(
      size: Vector2.all(pendulumSize),
      position: Vector2(gameSize.x / 2, gameSize.y),
    );
    add(pendulum);
    gyroListenerSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // TODO add semaphore here
      final double sideTiltAmount = -event.z / 3;
      // Check if the pendulum has reached its max range or not
      late double newAngle;
      if (pendulumTargetAngle + sideTiltAmount < -maxPendulumAngle) {
        newAngle = -maxPendulumAngle;
      } else if (pendulumTargetAngle + sideTiltAmount > maxPendulumAngle) {
        newAngle = maxPendulumAngle;
      } else {
        newAngle = pendulumTargetAngle + sideTiltAmount;
      }
      // Only update the effect if the angle changed.
      if (pendulumTargetAngle != newAngle) {
        pendulumTargetAngle = newAngle;
        if (newAngle.abs() == maxPendulumAngle) {
          HapticFeedback.mediumImpact();
        }
        // Remove previous rotation effect and set a new rotation.
        if (pendulumRotateEffect != null) {
          pendulum.remove(pendulumRotateEffect!);
        }
        pendulumRotateEffect =
            RotateEffect.to(newAngle, LinearEffectController(0.15));
        pendulum.add(pendulumRotateEffect!);
      }
    });
    super.onLoad();
  }

  @override
  void handleNote({required int interval, required NoteModel noteModel}) {
    // TODO: implement handleNote
  }

  @override
  void update(double dt) {
    // if (pendulum.angle < pendulumTargetAngle) {
    //   pendulum.angle = min(
    //       pendulum.angle +
    //           (dt * (1 + (pendulumTargetAngle - pendulum.angle).abs())),
    //       pendulumTargetAngle);
    // } else if (pendulum.angle > pendulumTargetAngle) {
    //   pendulum.angle = max(
    //       pendulum.angle -
    //           (dt * (1 + (pendulumTargetAngle - pendulum.angle).abs())),
    //       pendulumTargetAngle);
    // }
    super.update(dt);
  }

  @override
  void onRemove() {
    gyroListenerSubscription.cancel();
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 gameSize) {
    this.onResize(gameSize);
    super.onGameResize(gameSize);
  }
}
