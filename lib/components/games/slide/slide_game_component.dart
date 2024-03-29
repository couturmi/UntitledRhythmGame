import 'package:untitled_rhythm_game/components/games/landscape_minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/slide/bucket_component.dart';
import 'package:untitled_rhythm_game/components/games/slide/slide_note_area.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class SlideGameComponent extends LandscapeMiniGameComponent {
  late BucketComponent _bucket;
  late SlideNoteArea _noteArea;

  SlideGameComponent({required super.model, required super.beatInterval});

  double get bucketXPosition => _bucket.position.x;

  Future<void> onLoad() async {
    _bucket = BucketComponent(priority: 1);
    _noteArea = SlideNoteArea(
      priority: 0,
      getBucketXPosition: () => bucketXPosition,
    );
    add(_bucket);
    add(_noteArea);
    await super.onLoad();
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
    );
  }
}
