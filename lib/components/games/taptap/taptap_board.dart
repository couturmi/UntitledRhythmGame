import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_column.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class TapTapBoardComponent extends MiniGameComponent {
  static const int numberOfColumns = 3;
  late List<TapTapColumn> _columns;

  TapTapBoardComponent({required super.model, required super.beatInterval});

  @override
  Future<void> onLoad() async {
    _columns = [];
    for (int i = 0; i < numberOfColumns; i++) {
      _columns.add(TapTapColumn(columnIndex: i));
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
      exactTiming: exactTiming,
      interval: beatInterval,
    );
  }
}
