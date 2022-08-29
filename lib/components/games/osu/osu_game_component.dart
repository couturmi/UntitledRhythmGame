import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:untitled_rhythm_game/components/games/landscape_minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/osu/osu_note_area.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class OsuGameComponent extends LandscapeMiniGameComponent with TapCallbacks {
  late OsuNoteArea _noteArea;
  OsuGameComponent({required super.model, required super.beatInterval});

  Future<void> onLoad() async {
    anchor = Anchor.topLeft;
    _noteArea = OsuNoteArea();
    add(_noteArea);
    await super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    // The reason the TapCallbacks functionality exists within this component is
    // because the OsuNoteArea has margins that wouldn't otherwise be tappable.
    _noteArea.onGameAreaTapped(event);
  }

  @override
  void handleNote({
    required int exactTiming,
    required NoteModel noteModel,
  }) {
    _noteArea.addNote(
      interval: beatInterval,
      exactTiming: exactTiming,
      xPercentage: noteModel.posX,
      yPercentage: noteModel.posY,
      label: noteModel.label,
    );
  }
}
