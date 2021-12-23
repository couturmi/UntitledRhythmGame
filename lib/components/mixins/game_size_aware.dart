import 'package:flame/components.dart';

mixin GameSizeAware on Component {
  late Vector2 gameSize;

  /// Method that should be called in the [onGameResize] function of a component.
  void onResize(Vector2 newGameSize) {
    gameSize = newGameSize;
  }
}
