import 'package:flame/components.dart';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

abstract class LandscapeMiniGameComponent extends MiniGameComponent {
  LandscapeMiniGameComponent({required MiniGameModel model})
      : super(model: model);

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    // Essentially this resets the TopLeft position of the component to be at
    // the "TopLeft" of the device when it is horizontal.
    // (In reality, if turned clockwise this would be the device's TopRight,
    // and if counterclockwise, the device's BottomLeft.)
    position =
        Vector2(-(gameSize.y - gameSize.x) / 2, (gameSize.y - gameSize.x) / 2);
    size = Vector2(gameSize.y, gameSize.x);
  }
}
