import 'dart:async';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/tilt/tilt_column.dart';
import 'package:untitled_rhythm_game/components/games/tilt/tilt_pendulum.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class TiltGameComponent extends MiniGameComponent {
  static const int numberOfColumns = 2;

  late List<TiltColumn> _columns;
  late final TiltPendulum _pendulum;

  TiltGameComponent({required super.model, required super.beatInterval});

  @override
  Future<void> onLoad() async {
    _columns = [];
    for (int i = 0; i < numberOfColumns; i++) {
      _columns.add(TiltColumn(
        columnIndex: i,
        isPendulumAtThisColumn: () => isPendulumAtColumn(i),
        priority: 0,
      ));
    }
    _pendulum = TiltPendulum(priority: 1);
    addAll(_columns);
    add(_pendulum);
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

  /// Checks if the pendulum is pointing the the column at [columnIndex].
  bool isPendulumAtColumn(int columnIndex) {
    return _pendulum.currentColumn == columnIndex;
  }
}
