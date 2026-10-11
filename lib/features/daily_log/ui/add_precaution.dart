import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/name.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/save_failure.dart';
import '../domain/precaution.dart';
import '../domain/precaution_repository.dart';
import 'manner_choice.dart';
import 'precaution_name_field.dart';
import 'precaution_words.dart';
import 'providers.dart';

/// Adds a precaution: its name, its manner and the button, on the day's page
/// and in the editor alike. While a name is typed, the items out of use that
/// hold the typed text are offered under the field; one chosen fills in its
/// name and manner, and adding it brings that item back into use.
///
/// An add the list turns down, because an item in use has the name and the
/// manner, is told under the name and keeps what was typed.
class AddPrecaution extends ConsumerStatefulWidget {
  const AddPrecaution({super.key, required this.onFailed});

  final SaveFailureHandler onFailed;

  @override
  ConsumerState<AddPrecaution> createState() => _AddPrecautionState();
}

class _AddPrecautionState extends ConsumerState<AddPrecaution>
    with AutomaticKeepAliveClientMixin {
  final _name = TextEditingController();
  final _focus = FocusNode();

  /// The manner an add starts on.
  static const _firstManner = PrecautionManner.refrain;
  var _manner = _firstManner;
  var _adding = false;
  NameAndManner? _turnedDown;

  /// A name typed and not yet added stays when the page is scrolled far
  /// from the field: the list would otherwise drop the field with it.
  @override
  bool get wantKeepAlive => _name.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _name.addListener(updateKeepAlive);
  }

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    // Read at the press, and one add at a time: a second press before the
    // button is built disabled would find the first one's item and be
    // turned down.
    final name = nameOf(_name.text);
    if (name == null || _adding) return;
    final manner = _manner;
    setState(() => _adding = true);
    try {
      final write = await ref
          .read(precautionListProvider.notifier)
          .add(name, manner);
      if (!mounted) return;
      if (write.turnedDown) {
        setState(() => _turnedDown = (name: name, manner: manner));
      } else {
        // Cleared only once saved, so a failed add keeps what was entered.
        // The manner goes back with the name: the next add starts as the
        // first did, whatever an offered item or the last add had set.
        _name.clear();
        setState(() => _manner = _firstManner);
      }
    } catch (error, stack) {
      widget.onFailed(error, stack);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  static bool _inUse(List<Precaution>? inUse, NameAndManner asked) =>
      inUse != null && inUse.any((item) => item.nameAndManner == asked);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(precautionListProvider).value;
    final outOfUse = list?.notInUse ?? const <Precaution>[];
    // What was turned down holds only while an item in use has it: once
    // that item is taken out of use, here or on another page, the same add
    // would bring it back.
    final turnedDown = switch (_turnedDown) {
      final asked? when _inUse(list?.inUse, asked) => asked,
      _ => null,
    };

    // One under another, the button at the end of its own line: it stays in
    // one place at every text size.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A node of its own, so a screen reader goes from the field to the
        // items offered for it: on a card, the place they are read from
        // would otherwise be the whole card.
        Semantics(
          container: true,
          child: RawAutocomplete<Precaution>(
            textEditingController: _name,
            focusNode: _focus,
            // Offered only for a name being typed: an empty field offers
            // nothing, so it stays as quiet as any other field.
            optionsBuilder: (typed) {
              final text = nameOf(typed.text);
              if (text == null) return const [];
              return outOfUse.where((item) => item.name.contains(text));
            },
            displayStringForOption: (item) => item.name,
            onSelected: (item) => setState(() => _manner = item.manner),
            // Toward the side with more room: with the keyboard up, the field
            // sits just above it.
            optionsViewOpenDirection: OptionsViewOpenDirection.mostSpace,
            // The field's own submit would take the first one offered, so
            // it is left unused: the offered items are chosen by a press.
            fieldViewBuilder: (context, controller, focusNode, _) =>
                PrecautionNameField(
                  controller: controller,
                  focusNode: focusNode,
                  manner: _manner,
                  turnedDown: turnedDown,
                ),
            optionsViewBuilder: (context, onSelected, options) =>
                _Offered(options: options, onSelected: onSelected),
          ),
        ),
        const SizedBox(height: 16),
        MannerChoice(
          manner: _manner,
          onChanged: (manner) => setState(() => _manner = manner),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ListenableBuilder(
            listenable: _name,
            builder: (context, _) => FilledButton(
              onPressed: nameOf(_name.text) == null || _adding ? null : _add,
              child: Text(l10n.addPrecaution),
            ),
          ),
        ),
      ],
    );
  }
}

/// The items offered under the name field, each with its manner, which is
/// what tells two items of one name apart.
///
/// Shaped as material_ui 1.5.0's `Autocomplete` shapes its options: the
/// shadow, the height the list scrolls within, the room around a row, and a
/// row read as a button. Its mark on the option the field's submit would
/// take is left out, as that submit is left unused. Nothing checks the two
/// against each other: read them side by side when material_ui is updated.
class _Offered extends StatelessWidget {
  const _Offered({required this.options, required this.onSelected});

  final Iterable<Precaution> options;
  final AutocompleteOnSelected<Precaution> onSelected;

  static const _elevation = 4.0;
  static const _maxHeight = 200.0;
  static const _rowPadding = EdgeInsets.all(16);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Material(
      elevation: _elevation,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            for (final item in options)
              // Read as something to press, which the ink well alone does
              // not say.
              Semantics(
                button: true,
                child: InkWell(
                  onTap: () => onSelected(item),
                  child: Padding(
                    padding: _rowPadding,
                    child: Text(
                      l10n.precautionWithManner(
                        item.name,
                        l10n.mannerName(item.manner),
                      ),
                      style: textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
