import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/swipe/ship_component.dart';
import 'package:untitled_rhythm_game/components/games/swipe/swipe_column.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class SwipeGameComponent extends MiniGameComponent with DragCallbacks {
  static const int numberOfColumns = 3;

  late List<SwipeColumn> _columns;
  late final ShipComponent _ship;

  int? currentShipColumn;

  SwipeGameComponent({required super.model, required super.beatInterval});

  Future<void> onLoad() async {
    _columns = [];
    for (int i = 0; i < numberOfColumns; i++) {
      _columns.add(SwipeColumn(columnIndex: i));
    }
    await addAll([
      ..._columns,
      _ship = ShipComponent(),
    ]);
    super.onLoad();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // Ship will always start in the middle of the screen, not necessarily in a column,
    // so we need to determine which column it should go to based on its current location.
    double shipColumnLocation = currentShipColumn?.toDouble() ??
        ((SwipeGameComponent.numberOfColumns - 1) / 2);
    int nextColumn = event.velocity.x.isNegative
        ? shipColumnLocation.ceil() - 1
        : shipColumnLocation.floor() + 1;
    // Check if column is within range of actual columns
    if (nextColumn >= 0 && nextColumn < SwipeGameComponent.numberOfColumns) {
      _ship.evadeTo(nextColumn);
      currentShipColumn = nextColumn;
    }
    super.onDragEnd(event);
  }

  @override
  void handleNote({
    required int exactTiming,
    required NoteModel noteModel,
  }) {
    _columns[noteModel.column].addObstacle(
      exactTiming: exactTiming,
      interval: beatInterval,
    );
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    size = canvasSize;
  }
}
