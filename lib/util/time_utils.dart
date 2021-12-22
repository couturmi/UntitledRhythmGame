double microsecondsToSeconds(num microseconds) {
  return microseconds / 1000000;
}

/// Converts a song's [bpm] to (Microseconds / beat)
int bpmToMicroseconds(int bpm) {
  return ((1 / (bpm / 60)) * 1000000).round();
}
