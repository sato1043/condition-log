import 'package:material_ui/material_ui.dart';

import '../../../domain/calendar_day.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/app_dialog.dart';

/// The first day a visit can be on.
final _firstDay = DateTime(2000);

/// The largest text scale the date picker is shown at: Android's largest.
const _maxPickerTextScale = 2.0;

/// Lets the person choose a visit's day, starting on [initial]. Days from
/// 2000 up to a year after [today] can be chosen: visits had long ago, and
/// the next one planned. Null when closed without a choice.
Future<CalendarDay?> pickVisitDay(
  BuildContext context, {
  required CalendarDay initial,
  required CalendarDay today,
}) async {
  final last = DateTime(today.year + 1, today.month, today.day);
  final start = DateTime(initial.year, initial.month, initial.day);
  // Material's picker, opened as the app's other dialogs are, in place of
  // its own opening, which leaves the barrier to screen readers. Built as
  // material_ui 1.5.0's showDatePicker builds it, which nothing checks: read
  // the two side by side when material_ui is updated.
  final chosen = await showAppDialog<DateTime>(
    context: context,
    // Material's date picker overflows a small phone at the iOS max text
    // size (its header, by 24 dp at 360 x 640). Held to the Android max of
    // 2.0, it fits; only this dialog is held, an exception to R3 in the
    // appearance description.
    builder: (context) => MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxPickerTextScale,
      child: DatePickerDialog(
        // Held within the range: the picker refuses to open on a day
        // outside it, as on a visit planned before the clock was set back.
        initialDate: start.isBefore(_firstDay)
            ? _firstDay
            : (start.isAfter(last) ? last : start),
        firstDate: _firstDay,
        lastDate: last,
        // Says what the day is for, in place of Material's general heading.
        helpText: AppLocalizations.of(context).pickVisitDayHelp,
        // The app's today, which follows the day-start hour, rather than
        // the clock's date the picker would mark by itself.
        currentDate: DateTime(today.year, today.month, today.day),
      ),
    ),
  );
  return chosen == null
      ? null
      : CalendarDay(chosen.year, chosen.month, chosen.day);
}
