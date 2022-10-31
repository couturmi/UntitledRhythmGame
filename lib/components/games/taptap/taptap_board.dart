import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_column.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class TapTapBoardComponent extends MiniGameComponent {
  /// Total number of columns that make up this TapTap board.
  final int numberOfColumns;

  late List<TapTapColumn> _columns;

  TapTapBoardComponent(
      {required super.model,
      required super.beatInterval,
      this.numberOfColumns = 3});

  @override
  Future<void> onLoad() async {
    _columns = [];
    for (int i = 0; i < numberOfColumns; i++) {
      _columns
          .add(TapTapColumn(columnIndex: i, numberOfColumns: numberOfColumns));
    }
    await addAll(_columns);
    super.onLoad();
  }

  @override
  void handleNote({
    required int exactTiming,
    required NoteModel noteModel,
  }) {
    _columns[noteModel.column].addNote(
      duration: noteModel.duration,
      exactTiming: exactTiming,
      interval: beatInterval,
    );
  }
}
