import 'package:material_ui/material_ui.dart';

/// Colors of the daily log screen, taken from docs/appearance.md. The IDs in
/// the comments point back to that document. Parts take their colors from
/// these roles as Material assigns them, except where the theme says why not.
const _dailyLogScheme = ColorScheme(
  brightness: Brightness.light,
  surface: Color(0xFFE2E7E3), // V3
  onSurface: Color(0xFF253532), // V4
  primary: Color(0xFF1D4B44), // V22
  onPrimary: Color(0xFFFFFFFF), // V23
  primaryContainer: Color(0xFFB3E2D8), // V24
  onPrimaryContainer: Color(0xFF253532), // V25
  secondary: Color(0xFF695B18), // V26
  onSecondary: Color(0xFFFFFFFF), // V27
  secondaryContainer: Color(0xFFAFA67F), // V28
  onSecondaryContainer: Color(0xFF253532), // V29
  tertiary: Color(0xFF1E6282), // V30
  onTertiary: Color(0xFFFFFFFF), // V31
  tertiaryContainer: Color(0xFFB3D7DD), // V32
  onTertiaryContainer: Color(0xFF283539), // V33
  error: Color(0xFF740050), // V34
  onError: Color(0xFFFFFFFF), // V35
  errorContainer: Color(0xFFE3ADD5), // V36
  onErrorContainer: Color(0xFF3A2D31), // V37
  outline: Color(0xFF385B63), // V50
  outlineVariant: Color(0xFF297364), // V51
  surfaceContainerLow: Color(0xFFD5DDD8), // V100
  surfaceContainer: Color(0xFFC8D4CE), // V77
  surfaceContainerHigh: Color(0xFFADC2BD), // V78
);

/// Theme of the daily log screen. Text sizes follow Typography.dense2021
/// (V75), which Material picks for the Japanese locale, and are scaled by the
/// OS text setting only (R3).
ThemeData dailyLogTheme() {
  return ThemeData(
    colorScheme: _dailyLogScheme,
    scaffoldBackgroundColor: _dailyLogScheme.surface,
    // V60: every page's header bar matches the bottom navigation, which
    // Material colors surfaceContainer, rather than the ground. Material also
    // gives it surfaceContainer while content scrolls under it.
    appBarTheme: AppBarTheme(backgroundColor: _dailyLogScheme.surfaceContainer),
    // A field is shown by its frame rather than Material's underline, so an
    // unfilled field still reads as a place to write on the ground and the
    // cards. The name stands on the frame from the start (fieldDecoration),
    // at Material's size; the room around the content is Material's.
    inputDecorationTheme: const InputDecorationThemeData(
      border: OutlineInputBorder(),
    ),
    // V101: the chosen row takes the body text color and is told by its
    // check mark. Material's primary falls below the body text minimum on a
    // dialog under the focus highlight of a hardware keyboard.
    listTileTheme: ListTileThemeData(selectedColor: _dailyLogScheme.onSurface),
    navigationBarTheme: NavigationBarThemeData(
      // V92: the destination shown is filled like a chosen step (V64).
      // Material fills it in secondaryContainer, which falls below the
      // non-text contrast minimum against the bar.
      indicatorColor: _dailyLogScheme.secondary,
      // V95: lower than Material's 80 dp. The icons and the names sit in the
      // middle, so the room above and below them shrinks alike.
      height: 68,
      // V98: a size larger than Material's 24 dp. The drawn shape stays
      // inside the 32 dp high fill, as icons leave a margin in their box.
      // V93: on the V92 fill, Material's onSecondaryContainer cannot be read,
      // so the icon shown takes onSecondary. The size needs a resolver for
      // both states, so the icons not shown copy Material's color for them in
      // material_ui 1.5.0 (onSurfaceVariant).
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 32,
          color: states.contains(WidgetState.selected)
              ? _dailyLogScheme.onSecondary
              : _dailyLogScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
