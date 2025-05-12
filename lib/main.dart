import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';

// TODO add a level fail for missed notes/hit obstacles
// TODO update the score to be based on timing
main() {
  // Force portrait orientation before starting app.
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    // Run game.
    runApp(
      WidgetsApp(
        home: SafeArea(
          child: GameWidget(
            game: OffBeatGame(),
          ),
        ),
        debugShowCheckedModeBanner: false,
        color: Colors.transparent,
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return MaterialPageRoute<T>(settings: settings, builder: builder);
        },
      ),
    );
  });
}

//ideas:

// Whackamole
// - 3x3 grid, moles pop up right before they should be hit, and hopefully it makes sense when to hit them?

// Fruit Ninja
// - apples show for one beat at the top, then fall but accelerate like a real apple falling (unlike the constant speed of the taptap notes)
// - when the apple passes the yellow line at the center of the screen, the player has to slice the apple to get the points

// Geometry Dash type game?

// Keyboard Game? Keyboard comes up and you have to type the letters as they appear lol

// Monetization Ideas:

// Step 1. In-Game Currency
//   - First-Time completion of songs gets you lots of currency (or a rare type of currency, like "gems")
//   - Consecutive completion of songs gets you some currency (more currency for higher difficulties?)
//   - You can also buy the In-Game currency with real money

// Step 2. Skins
//   - With so many different types of minigames, you are already playing around with different mini-game skins. You can essentially make these permanent additions to a player's account
//   - You can unlock skins from specific levels by completing them (maybe a different amount for different difficulties?)
//     - "Unlock" here means the skins become available for achievement or purchasable outright. Essentially they are added to the store / collection of winnable skins
//     - Getting a SS rank gets you a free skin from the level (or if youve already purchased/won them all, it gives you a random skin)
//       - Or, there can be one skin that is only achievable by getting an SS rank. (So, it is not purchasable. Basically a badge that you are actually good at the game)
//   - There can also be a bunch of additional skins available in the store (not from specific levels) that can be purchased with In-Game currency.
//   - A player can use their achieved skins as the new default skin for a mini-game, if there isn't a level-specific skin for it
//     - If the player has already completed the level, they can select to override all skins (regardless of any level-specific skin/sprite used)
//       - this should be selected by default. if they want to see the skins again, they can uncheck it
//       - OR... that might be annoying to get a skin and then only be able to see it on replayed levels.. So maybe just always make it the default.

// Step 3. Song Packs
//   - The classic with every rhythm game. Add song packs in bulk that are available for purchase with real money (or In-Game currency / gems?)

// Step 4. Player Profiles
// - Players can achieve profile badges for completing certain tours or achieving SS rank enough times. Might just be a cool thing to be able to show off and "game-ify"

// Step 5. Unlock Song Variations
//   - Essentially since the song already switches around so much, you could add additional mini-games to the beat maps that would replace different sections of the song.
//   - Then the player could choose a specific combination to try to achieve a high score, or they could make it randomized to keep things entertaining, true Wario-Ware style!
//   - You could essentially just map the entire song for multiple-mini game types, and break it up into the sections where the minigames would switch.
//     - You could also skip some sections if the minigame type is not valid with the part of the song, so that only some song sections are available for that minigame.
//   - This would make songs highly customizable, and also add a challenge into which combinations would provide the highest score output! The only problem is that this implementation would add so much effort, since every song would require soooo much beatmapping.
