import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_column.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class TapTapBoardComponent extends MiniGameComponent {
  late List<TapTapColumn> columns;

  TapTapBoardComponent(MiniGameModel model) : super(model: model);

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

  @override
  void handleNote({
    required int interval,
    required NoteModel noteModel,
  }) {
    columns[noteModel.column]
        .addNote(interval: interval, beatDelay: noteModel.timing);
  }
}
