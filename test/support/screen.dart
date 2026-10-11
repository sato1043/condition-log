import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The largest text scale each OS offers. A test at one of them runs on that
/// platform too (`variant: TargetPlatformVariant.only(platform)`), so the
/// platform's own Material defaults, such as where an app bar puts its
/// title, are laid out at that size.
/// - Android 14 and later: 200% in the font size setting.
/// - iOS: the largest accessibility size (AX5) sets body text to 53 pt
///   against 17 pt at the default size.
const maxTextScales = {
  TargetPlatform.android: 2.0,
  TargetPlatform.iOS: 53 / 17,
};

/// Runs a test on each OS the app is for, where what a screen reader is
/// given is to hold on both.
const bothSystems = TargetPlatformVariant({
  TargetPlatform.android,
  TargetPlatform.iOS,
});

/// The smallest common phone size, in dp.
const smallPhone = Size(360, 640);

/// The pixels per dp of the phone [useSmallPhone] sets up.
const smallPhonePixelRatio = 3.0;

/// A [smallPhone] screen with the given text scale. The settings are reset
/// when the test ends.
void useSmallPhone(WidgetTester tester, {double textScale = 1.0}) {
  tester.view.devicePixelRatio = smallPhonePixelRatio;
  tester.view.physicalSize = smallPhone * smallPhonePixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
