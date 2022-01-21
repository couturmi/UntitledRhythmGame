import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:untitled_rhythm_game/components/games/tilt/pendulum_sprite_component.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';

class TiltPendulum extends PositionComponent with GameSizeAware {
  late double pendulumSize;
  late double _maxPendulumAngle;

  late StreamSubscription _gyroListenerSubscription;

  late PendulumSpriteComponent _pendulumSprite;
  RotateEffect? _pendulumRotateEffect;
  double _pendulumTargetAngle = 0.0;
  double _deviceCurrentAngle = 0.0;

  double _currentRotationRate = 0.0;

  TiltPendulum({int? priority})
      : super(anchor: Anchor.bottomCenter, priority: priority);

  /// Get the current column the pendulum is pointing to
  int get currentColumn => _deviceCurrentAngle < 0 ? 0 : 1;

  @override
  Future<void> onLoad() async {
    pendulumSize = gameSize.y / 3;
    double pendulumEndDiameter = gameSize.x / 3;
    // calculate the maximum pendulum angle based on the device size. TRIGONOMETRY BITCH.
    _maxPendulumAngle = atan((pendulumEndDiameter - 10) /
        (pendulumSize + (pendulumEndDiameter / 2)));

    // Set the default angle to be to the left on the initial load.
    _pendulumTargetAngle = -_maxPendulumAngle;
    _deviceCurrentAngle = _pendulumTargetAngle;
    angle = _pendulumTargetAngle;

    _pendulumSprite = PendulumSpriteComponent(
      hitCircleCenterHeight: pendulumSize,
      hitCircleDiameter: pendulumEndDiameter,
    );
    await add(_pendulumSprite);
    _gyroListenerSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (event.z.abs() > _currentRotationRate.abs()) {
        _currentRotationRate = event.z;
      }
    });
    super.onLoad();
  }

  @override
  void update(double dt) {
    if (_currentRotationRate != 0) {
      // TODO add semaphore here
      final double sideTiltAmount = -_currentRotationRate / 2;
      // TODO remove this commented code ONLY if you decide the current performance is best.
      // Check if the pendulum has reached its max range or not
      // late double newAngle;
      // if (_pendulumTargetAngle + sideTiltAmount < -_maxPendulumAngle) {
      //   newAngle = -_maxPendulumAngle;
      // } else if (_pendulumTargetAngle + sideTiltAmount > _maxPendulumAngle) {
      //   newAngle = _maxPendulumAngle;
      // } else {
      //   newAngle = _pendulumTargetAngle + sideTiltAmount;
      // }
      // // Only update the effect if the angle changed.
      // if (_pendulumTargetAngle != newAngle) {
      //   _pendulumTargetAngle = newAngle;
      //   // Remove previous rotation effect and set a new rotation.
      //   if (_pendulumRotateEffect != null) {
      //     remove(_pendulumRotateEffect!);
      //   }
      //   _pendulumRotateEffect =
      //       RotateEffect.to(newAngle, LinearEffectController(0.15));
      //   add(_pendulumRotateEffect!);
      // }

      _deviceCurrentAngle += sideTiltAmount;
      // Check for either a large motion, or if the device has been rotating long enough.
      if (sideTiltAmount.abs() > 0.4 ||
          _deviceCurrentAngle.abs() > _maxPendulumAngle / 2) {
        _deviceCurrentAngle = sideTiltAmount.sign * _maxPendulumAngle / 2;
      }
      if ((_deviceCurrentAngle > 0 &&
              _pendulumTargetAngle != _maxPendulumAngle) ||
          (_deviceCurrentAngle < 0 &&
              _pendulumTargetAngle != -_maxPendulumAngle)) {
        _pendulumTargetAngle = _deviceCurrentAngle.sign * _maxPendulumAngle;
        _deviceCurrentAngle = _pendulumTargetAngle / 2;

        // Remove previous rotation effect and set a new rotation.
        if (_pendulumRotateEffect != null) {
          remove(_pendulumRotateEffect!);
        }
        _pendulumRotateEffect =
            RotateEffect.to(_pendulumTargetAngle, LinearEffectController(0.1));
        add(_pendulumRotateEffect!);
      }
      // reset the rotation rate.
      _currentRotationRate = 0;
    }
    super.update(dt);
  }

  @override
  void onRemove() {
    _gyroListenerSubscription.cancel();
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 gameSize) {
    this.onResize(gameSize);
    position = Vector2(gameSize.x / 2, gameSize.y);
    super.onGameResize(gameSize);
  }
}
