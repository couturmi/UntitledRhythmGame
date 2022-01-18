enum MiniGameType {
  gameTransition,
  tapTap,
}

MiniGameType miniGameTypeFromString(String name) {
  return MiniGameType.values
      .firstWhere((type) => type.toString().split(".").last == name);
}

String getMiniGameName(MiniGameType game) {
  switch (game) {
    case MiniGameType.tapTap:
      return "Tap Hero";
    case MiniGameType.gameTransition:
      throw ArgumentError(
          "This is a transition, and not a true mini-game, and "
          "therefore has no reason to have an associated name",
          game.toString());
  }
}
