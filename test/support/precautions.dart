import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:condition_log/features/daily_log/domain/precaution.dart';
import 'package:condition_log/features/daily_log/domain/precaution_repository.dart';

/// Registers a precaution of one manner and gives the item itself, for the
/// tests that only need one to be there.
extension AddPrecautionOfManner on PrecautionRepository {
  Future<Precaution> addToRefrain(String name) async =>
      (await addPrecaution(name, PrecautionManner.refrain)).precaution;

  Future<Precaution> addToKeepUp(String name) async =>
      (await addPrecaution(name, PrecautionManner.keepUp)).precaution;
}

/// The mark of the precaution [name] on the day's page, read as [name] and
/// [done] (控えた or 続けた).
Finder precautionMark(String name, String done) =>
    find.bySemanticsLabel('$name、$done');

/// The chip of [precautionMark], which is what a finger presses.
Finder markChip(String name, String done) => find.descendant(
  of: precautionMark(name, done),
  matching: find.byType(FilterChip),
);
