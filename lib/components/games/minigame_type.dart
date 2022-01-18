enum MiniGameType {
  gameTransition,
  tapTap,
}

MiniGameType miniGameTypeFromString(String name) {
  return MiniGameType.values
      .firstWhere((type) => type.toString().split(".").last == name);
}
