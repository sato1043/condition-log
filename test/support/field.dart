import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// How much Material shrinks a field's name to sit on the frame: three
/// quarters of body text (R9). Material keeps it in a private constant.
const nameOnFrameScale = 0.75;

/// Expects the field named [name] to be shown by an outline frame rather than
/// a fill (docs/appearance.md, the colors of parts), and to keep its name on
/// the frame while empty: a name in the middle of an empty frame reads as a
/// button's text. [within] picks the field when the name shows more than once.
void expectFieldNamedOnFrame(
  WidgetTester tester,
  String name, {
  Finder? within,
}) {
  final label = within == null
      ? find.text(name)
      : find.descendant(of: within, matching: find.text(name));
  final field = find
      .ancestor(of: label, matching: find.byType(InputDecorator))
      .first;
  // As the field draws it: the theme fills in what the field leaves unset.
  final decoration = tester
      .widget<InputDecorator>(field)
      .decoration
      .applyDefaults(Theme.of(tester.element(field)).inputDecorationTheme);
  expect(decoration.filled, isFalse);
  expect(decoration.border, isA<OutlineInputBorder>());

  final labelRect = tester.getRect(label);
  expect(
    (labelRect.center.dy - tester.getRect(field).top).abs(),
    lessThan(labelRect.height / 2),
    reason: 'the name sits on the top edge of the frame',
  );
  expect(
    shownFontSize(tester, label),
    closeTo(bodyFontSize(tester, label) * nameOnFrameScale, 0.5),
    reason:
        'the name takes Material\'s size on the frame, three quarters of '
        'body text (R9)',
  );
}

/// The size [text] shows at on screen: its font size, times the OS text
/// size it was given, times the scale it is drawn with.
double shownFontSize(WidgetTester tester, Finder text) =>
    _scaledFontSize(tester.renderObject<RenderParagraph>(text)) *
    _drawnScale(tester, text);

// The letters below are measured from a line's box, on two premises:
// - the room a line leaves beside its letters is split evenly above and
//   below them, as Material's type scale sets (checked on every call);
// - the letters are as high as the font size, as in Flutter's test font
//   (its ascent and descent add up to one font size).
// So the measure is exact in tests only: a phone's Japanese font draws its
// letters at its own height. It tells whether letters overlap; how much room
// a field keeps is checked against Material's values elsewhere.

/// The top of the letters of the first line of [text] on screen: its box less
/// the room its line height leaves above them. Letters sit in the middle of a
/// line taller than they are, so two boxes can meet while the letters in them
/// stay apart.
double lettersTop(WidgetTester tester, Finder text) =>
    tester.getRect(text).top + _roomBesideLetters(tester, text);

/// The bottom of the letters of the last line of [text] on screen.
double lettersBottom(WidgetTester tester, Finder text) =>
    tester.getRect(text).bottom - _roomBesideLetters(tester, text);

/// The room a line of [text] leaves above, and below, its letters on screen.
double _roomBesideLetters(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  _expectEvenRoom(paragraph.text.style!, paragraph.textHeightBehavior);
  return (paragraph.preferredLineHeight - _scaledFontSize(paragraph)) /
      2 *
      _drawnScale(tester, text);
}

/// The top of the letters of the first line typed in [field], an
/// [EditableText]: its box less the room its line height leaves above them.
/// Unlike a name on the frame, the box is drawn at its own size, so no
/// drawn scale applies.
double typedLettersTop(WidgetTester tester, Finder field) {
  final editable = tester.state<EditableTextState>(field).renderEditable;
  final style = editable.text!.style!;
  _expectEvenRoom(style, editable.textHeightBehavior);
  final letters = editable.textScaler.scale(style.fontSize!);
  return editable.localToGlobal(Offset.zero).dy +
      (editable.preferredLineHeight - letters) / 2;
}

/// The font size of [paragraph] after the OS text size.
double _scaledFontSize(RenderParagraph paragraph) =>
    paragraph.textScaler.scale(paragraph.text.style!.fontSize!);

/// The scale [text] is drawn with, as a name shrinks on the frame.
double _drawnScale(WidgetTester tester, Finder text) =>
    tester.getRect(text).height /
    tester.renderObject<RenderParagraph>(text).size.height;

void _expectEvenRoom(TextStyle style, TextHeightBehavior? behavior) {
  expect(
    style.leadingDistribution ??
        behavior?.leadingDistribution ??
        TextLeadingDistribution.proportional,
    TextLeadingDistribution.even,
    reason: 'the room beside the letters is split evenly above and below',
  );
}

/// The size body text shows at where [near] is, after the OS text size.
double bodyFontSize(WidgetTester tester, Finder near) {
  final context = tester.element(near);
  return MediaQuery.textScalerOf(context)
      .scale(Theme.of(context).textTheme.bodyLarge!.fontSize!);
}
