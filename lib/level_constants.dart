import 'package:untitled_rhythm_game/components/backdrops/jump_up_superstar/jump_up_superstar_background_component.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';
import 'package:untitled_rhythm_game/components/backdrops/megalovania/megalovania_background_component.dart';
import 'package:untitled_rhythm_game/components/backdrops/mii_channel/mii_channel_background_component.dart';

enum Level {
  megalovania,
  jumpUpSuperstar,
  miiChannel,
}

String getLevelBeatMapPath(Level level) {
  switch (level) {
    case Level.megalovania:
      return "assets/beat_maps/megalovania.json";
    case Level.jumpUpSuperstar:
      return "assets/beat_maps/jump_up_superstar.json";
    case Level.miiChannel:
      return "assets/beat_maps/mii_channel.json";
  }
}

String getLevelMP3PathMap(Level level) {
  switch (level) {
    case Level.megalovania:
      return "music/megalovania.mp3";
    case Level.jumpUpSuperstar:
      return "music/jump_up_superstar.mp3";
    case Level.miiChannel:
      return "music/mii_channel.mp3";
  }
}

String getLevelMP3PreviewPathMap(Level level) {
  switch (level) {
    case Level.megalovania:
      return "music/megalovania_preview.mp3";
    case Level.jumpUpSuperstar:
      return "music/jump_up_superstar_preview.mp3";
    case Level.miiChannel:
      return "music/mii_channel_preview.mp3";
  }
}

LevelBackgroundComponent getLevelBackgroundComponent(
    {required Level level, required int interval}) {
  switch (level) {
    case Level.megalovania:
      return MegalovaniaBackgroundComponent(interval: interval);
    case Level.jumpUpSuperstar:
      return JumpUpSuperStarBackgroundComponent(interval: interval);
    case Level.miiChannel:
      return MiiChannelBackgroundComponent(interval: interval);
  }
}
