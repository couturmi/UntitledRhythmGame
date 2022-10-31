import 'dart:math';

import 'package:flutter/services.dart';

enum MiniGameType {
  gameTransition,
  tapTap,
  tapTap7,
  osu,
  tilt,
  slide,
  swipe,
  undertale,
}

MiniGameType miniGameTypeFromString(String name) {
  return MiniGameType.values.firstWhere((type) => type.name == name);
}

String getMiniGameName(MiniGameType game) {
  switch (game) {
    case MiniGameType.tapTap:
      return "Tap Hero";
    case MiniGameType.tapTap7:
      return "Tap Hero";
    case MiniGameType.osu:
      return "OSU!"; // Whack-A-Note?
    case MiniGameType.tilt:
      return "↶Tilt↷";
    case MiniGameType.slide:
      return "←Drag→";
    case MiniGameType.swipe:
      return "Swipe to";
    case MiniGameType.undertale:
      return "Avoid";
    case MiniGameType.gameTransition:
      throw ArgumentError(
          "This is a transition, and not a true mini-game, and "
          "therefore has no reason to have an associated name",
          game.toString());
  }
}

String getMiniGameNameLine2(MiniGameType game) {
  switch (game) {
    case MiniGameType.swipe:
      return "←Dodge→";
    default:
      return "";
  }
}

DeviceOrientation getOrientationForMiniGame(MiniGameType game) {
  switch (game) {
    case MiniGameType.tapTap:
    case MiniGameType.tilt:
    case MiniGameType.swipe:
    case MiniGameType.undertale:
      return DeviceOrientation.portraitUp;
    case MiniGameType.tapTap7:
    case MiniGameType.osu:
    case MiniGameType.slide:
      Random rand = Random();
      return rand.nextBool()
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.landscapeRight;
    case MiniGameType.gameTransition:
      throw ArgumentError(
          "This is a transition, and not a true mini-game, and "
          "therefore has no reason to have a static orientation",
          game.toString());
  }
}
