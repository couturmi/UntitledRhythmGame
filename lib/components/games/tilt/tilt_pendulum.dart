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
  int lastRotationTimestamp = 0;
  double _pendulumTargetAngle = 0.0;
  double _deviceCurrentAngle = 0.0;

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
      // ******** Something to Note ************
      // For gyroscope events such as this, it is important to note that the
      // "rate" of angle change (in radians) is what is reported, NOT the current angle.
      // So in order to calculate the change in angle, you have to multiply the rate
      // of the angle change by the time that has passed since the last event.
      int now = DateTime.now().microsecondsSinceEpoch;
      if (lastRotationTimestamp != 0) {
        final dT = (now - lastRotationTimestamp) /
            1000000; // convert from ms to seconds.
        double rotationAmount = -event.z * dT;
        _deviceCurrentAngle += rotationAmount;
        // Minimize the stored device angle to a range.
        if (_deviceCurrentAngle.abs() > _maxPendulumAngle / 2) {
          _deviceCurrentAngle = rotationAmount.sign * _maxPendulumAngle / 2;
        }
        // Check if the target angle should be updated.
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
          _pendulumRotateEffect = RotateEffect.to(
              _pendulumTargetAngle, LinearEffectController(0.1));
          add(_pendulumRotateEffect!);
        }
      }
      lastRotationTimestamp = now;
    });
    super.onLoad();
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
