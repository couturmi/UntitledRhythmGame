import 'package:flame/components.dart';
import 'package:untitled_rhythm_game/components/games/landscape_minigame_component.dart';

mixin GameSizeAware on Component {
  late Vector2 gameSize;
  bool? _isLandscapeModeGame;

  /// Checks if a parent exists that is a [LandscapeMiniGameComponent].
  bool get isLandscapeModeGame {
    if (_isLandscapeModeGame == null) {
      Component? c = this;
      while (c != null) {
        if (c != this && c is GameSizeAware) {
          _isLandscapeModeGame = c.isLandscapeModeGame;
          return _isLandscapeModeGame!;
        } else if (c is LandscapeMiniGameComponent) {
          _isLandscapeModeGame = true;
          return _isLandscapeModeGame!;
        } else {
          c = c.parent;
        }
      }
      _isLandscapeModeGame = false;
    }
    return _isLandscapeModeGame!;
  }

  /// Method that should be called in the [onGameResize] function of a component.
  void onResize(Vector2 newGameSize) {
    // If this component is within a landscape game element, flip the x and y.
    if (isLandscapeModeGame) {
      gameSize = Vector2(newGameSize.y, newGameSize.x);
    } else {
      gameSize = newGameSize;
    }
  }
}
