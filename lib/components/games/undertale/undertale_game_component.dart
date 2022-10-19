import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/widgets.dart';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/undertale/undertale_cage_area.dart';
import 'package:untitled_rhythm_game/components/games/undertale/undertale_joystick.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class UndertaleGameComponent extends MiniGameComponent
    with GameSizeAware, DragCallbacks {
  late UndertaleCageArea _cageArea;
  late UndertaleJoystick _joystick;
  UndertaleGameComponent({required super.model, required super.beatInterval});

  @override
  Future<void> onLoad() async {
    add(_joystick = UndertaleJoystick(
      anchor: Anchor.center,
      size: Vector2.all(100),
      position: Vector2(gameSize.x / 2, gameSize.y - 80),
    ));
    _cageArea = UndertaleCageArea(
      anchor: Anchor.center,
      position: gameSize / 2,
      joystick: _joystick,
    );
    add(_cageArea);
    super.onLoad();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _joystick.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _joystick.onDragEnd();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    _joystick.onDragEnd();
  }

  @override
  void handleNote({
    required int exactTiming,
    required NoteModel noteModel,
  }) {
    // Make sure that a side is actually set properly.
    assert((noteModel.posXEnd == 0 && noteModel.posYEnd != 0) ||
        (noteModel.posXEnd != 0 && noteModel.posYEnd == 0));
    // Determine side that the obstacle will pop out from.
    late AxisDirection entrySide;
    if (noteModel.posXEnd == 0) {
      entrySide =
          noteModel.posYEnd == -1 ? AxisDirection.up : AxisDirection.down;
    } else {
      entrySide =
          noteModel.posXEnd == -1 ? AxisDirection.left : AxisDirection.right;
    }
    _cageArea.addGunner(
      interval: beatInterval,
      exactTiming: exactTiming,
      entrySide: entrySide,
      xPercentage: noteModel.posX,
      yPercentage: noteModel.posY,
    );
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    this.onResize(canvasSize);
    size = gameSize;
  }
}
