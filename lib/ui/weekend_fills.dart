import 'package:material_ui/material_ui.dart';

/// The fills that tell a Saturday's and a Sunday's line in a list of days.
/// They are none of Material's color roles, so the theme carries them as an
/// extension.
@immutable
class WeekendFills extends ThemeExtension<WeekendFills> {
  const WeekendFills({required this.saturday, required this.sunday});

  final Color saturday;
  final Color sunday;

  /// The fill of a day of [weekday], counted as [DateTime.weekday] is, or
  /// null on a day that is neither.
  Color? forWeekday(int weekday) => switch (weekday) {
    DateTime.saturday => saturday,
    DateTime.sunday => sunday,
    _ => null,
  };

  @override
  WeekendFills copyWith({Color? saturday, Color? sunday}) => WeekendFills(
    saturday: saturday ?? this.saturday,
    sunday: sunday ?? this.sunday,
  );

  @override
  WeekendFills lerp(WeekendFills? other, double t) => other == null
      ? this
      : WeekendFills(
          saturday: Color.lerp(saturday, other.saturday, t)!,
          sunday: Color.lerp(sunday, other.sunday, t)!,
        );
}
