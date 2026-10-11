import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calendar_day.dart';
import '../features/settings/settings_providers.dart';

/// The current local time. Tests replace it to fix "now".
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// "Today", shared by every page that reads the day. It moves on by itself
/// at the day-start hour while the app stays open. A timer does not notice
/// the clock or the time zone being changed, so the daily log page also reads
/// it again whenever the app comes back to the foreground. The day-start hour
/// must have loaded; the pages that read this wait for it.
final todayProvider = Provider<CalendarDay>((ref) {
  final now = ref.watch(clockProvider)();
  final dayStart = ref.watch(dayStartHourProvider).requireValue;
  final change = CalendarDay.nextChange(now, dayStart);
  final timer = Timer(change.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return CalendarDay.today(now, dayStart);
});

/// [todayProvider] once the day-start hour has loaded, else null: for a page
/// that can open before it, as one opened at its location directly.
CalendarDay? todayIfKnown(WidgetRef ref) =>
    ref.read(dayStartHourProvider).hasValue ? ref.read(todayProvider) : null;
