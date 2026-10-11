import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/calendar_day.dart';
import '../../../ui/save_failure.dart';
import 'providers.dart';
import 'visit_page.dart';

/// Adds a visit on [day] at [careProviderId] (null for none) and goes to its
/// page in the visits destination, below the visit list, so going back leads
/// to the list whichever destination it was added from. A failed add is
/// told through [reportFailure] and opens nothing. Shared by the visit list
/// and the day's page, which each ask first, and pick the care provider, in
/// their own way. True once the visit is added.
Future<bool> addVisitAndOpen(
  BuildContext context,
  WidgetRef ref,
  CalendarDay day,
  SaveFailureHandler reportFailure, {
  required int? careProviderId,
}) async {
  final int id;
  try {
    id = await ref
        .read(visitsProvider.notifier)
        .add(day, careProviderId: careProviderId);
  } catch (error, stack) {
    reportFailure(error, stack);
    return false;
  }
  if (context.mounted) context.go(VisitPage.location('$id'));
  return true;
}
