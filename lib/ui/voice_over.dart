import 'package:material_ui/material_ui.dart';

/// Whether the screen reader is VoiceOver, which reads semantics differently
/// from TalkBack: it ignores [Semantics.onTapHint], so what a tap does has to
/// be told as [Semantics.hint], and it tells which radio button is chosen only
/// by [Semantics.selected], not by [Semantics.checked].
bool readsWithVoiceOver(BuildContext context) =>
    switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => false,
    };
