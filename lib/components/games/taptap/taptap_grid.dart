import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_column.dart';

class TapTapGridComponent extends PositionComponent {
  List<TapTapColumn> columns = [
    TapTapColumn(columnIndex: 0),
    TapTapColumn(columnIndex: 1),
    TapTapColumn(columnIndex: 2),
  ];
  @override
  Future<void> onLoad() async {
    await addAll(columns);
    super.onLoad();
  }

  void addNote({required int columnIndex, required int interval, required double beatDelay}) {
    columns[columnIndex].addNote(interval: interval, beatDelay: beatDelay);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
  }
}
