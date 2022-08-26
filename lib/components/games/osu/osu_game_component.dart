import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:untitled_rhythm_game/components/games/landscape_minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/osu/osu_note_area.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class OsuGameComponent extends LandscapeMiniGameComponent with TapCallbacks {
  late OsuNoteArea _noteArea;
  OsuGameComponent(MiniGameModel model) : super(model: model);

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
    required int interval,
    required NoteModel noteModel,
  }) {
    _noteArea.addNote(
      interval: interval,
      beatDelay: noteModel.timing,
      xPercentage: noteModel.posX,
      yPercentage: noteModel.posY,
    );
  }
}
