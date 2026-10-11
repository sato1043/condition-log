import 'package:material_ui/material_ui.dart';

/// The size Material gives the icon of an icon button.
const _iconSize = 24.0;

/// How far the icons grow with the text, to 36 dp: a size at which the date
/// in the day header keeps its lines and every screen still fits at the
/// largest text sizes.
const _maxIconScale = 1.5;

/// The icon size for an icon button beside text. It grows with the OS text
/// size, which alone leaves icons as they are, so the icon stays easy to see
/// beside large text.
double iconSizeBesideText(BuildContext context) =>
    MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: _maxIconScale)
        .scale(_iconSize);
