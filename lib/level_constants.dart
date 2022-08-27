enum Level {
  megalovania,
}

String getLevelBeatMapPath(Level level) {
  switch (level) {
    case Level.megalovania:
      return "assets/beat_maps/megalovania.json";
  }
}

String getLevelMP3PathMap(Level level) {
  switch (level) {
    case Level.megalovania:
      return "music/megalovania.mp3";
  }
}

String getLevelMP3PreviewPathMap(Level level) {
  switch (level) {
    case Level.megalovania:
      return "music/megalovania_preview.mp3";
  }
}
