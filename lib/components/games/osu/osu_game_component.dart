import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:untitled_rhythm_game/components/games/landscape_minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/osu/osu_note_area.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class OsuGameComponent extends LandscapeMiniGameComponent
    with TapCallbacks, DragCallbacks {
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
  void onTapUp(TapUpEvent event) {
    // Note: onTapUp will only occur if the event was actually a tap.
    // If the event is a drag, onTapUp will not be called at the end of the
    // drag. Regardless, we should still notify the game that the note is no longer
    // being held for this case.
    _noteArea.onGameAreaTapUp(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // The reason the DragCallbacks functionality exists within this component is
    // because the OsuNoteArea has margins that wouldn't otherwise be draggable.
    _noteArea.onGameAreaDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // The reason the DragCallbacks functionality exists within this component is
    // because the OsuNoteArea has margins that wouldn't otherwise be draggable.
    _noteArea.onGameAreaDragEnd(event);
    super.onDragEnd(event);
  }

  @override
  void handleNote({
    required int exactTiming,
    required NoteModel noteModel,
  }) {
    _noteArea.addNote(
      duration: noteModel.duration,
      interval: beatInterval,
      exactTiming: exactTiming,
      xPercentage: noteModel.posX,
      yPercentage: noteModel.posY,
      xPercentageEnd: noteModel.posXEnd,
      yPercentageEnd: noteModel.posYEnd,
      reversals: noteModel.reversals,
      label: noteModel.label,
    );
  }
}
