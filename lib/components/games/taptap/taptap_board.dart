import 'package:flame/components.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_column.dart';

class TapTapBoardComponent extends PositionComponent {
  TapTapBoardComponent() : super(priority: 1);

  late List<TapTapColumn> columns;

  @override
  Future<void> onLoad() async {
    columns = [
      TapTapColumn(columnIndex: 0),
      TapTapColumn(columnIndex: 1),
      TapTapColumn(columnIndex: 2),
    ];
    await addAll(columns);
    super.onLoad();
  }

  void addNote(
      {required int columnIndex,
      required int interval,
      required double beatDelay}) {
    columns[columnIndex].addNote(interval: interval, beatDelay: beatDelay);
  }
}
