import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/composition.dart';

void main() {
  runApp(
    ProviderScope(overrides: repositoryWiring, child: const ConditionLogApp()),
  );
}
