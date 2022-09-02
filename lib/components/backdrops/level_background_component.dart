import 'package:flame/components.dart';

abstract class LevelBackgroundComponent extends PositionComponent {
  final int interval;
  LevelBackgroundComponent({required this.interval}) : super(priority: 0);

  void beatUpdate();
}
