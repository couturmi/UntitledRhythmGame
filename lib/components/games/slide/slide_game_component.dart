import 'package:untitled_rhythm_game/components/games/landscape_minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/slide/bucket_component.dart';
import 'package:untitled_rhythm_game/components/games/slide/slide_note_area.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class SlideGameComponent extends LandscapeMiniGameComponent {
  late BucketComponent _bucket;
  late SlideNoteArea _noteArea;

  SlideGameComponent(MiniGameModel model) : super(model: model);

  double get bucketXPosition => _bucket.position.x;

  Future<void> onLoad() async {
    _bucket = BucketComponent();
    _noteArea = SlideNoteArea(getBucketXPosition: () => bucketXPosition);
    add(_bucket);
    add(_noteArea);
    await super.onLoad();
  }

  @override
  void handleNote({
    required int exactTiming,
    required int interval,
    required NoteModel noteModel,
  }) {
    _noteArea.addNote(
      interval: interval,
      exactTiming: exactTiming,
      xPercentage: noteModel.posX,
    );
  }
}
