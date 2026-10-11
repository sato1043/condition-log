import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/features/visits/data/drift_care_provider_repository.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';
import 'package:condition_log/features/visits/domain/visit_filter.dart';
import 'package:condition_log/features/visits/ui/providers.dart';

import '../../../support/app.dart';

void main() {
  late DriftCareProviderRepository repository;
  late ProviderContainer container;
  late int a;
  late int b;

  setUp(() async {
    final db = memoryDatabase();
    addTearDown(db.close);
    repository = DriftCareProviderRepository(db, clock: DateTime.now);
    a = await repository.addCareProvider(CareProviderNames(hospital: 'A'));
    b = await repository.addCareProvider(CareProviderNames(hospital: 'B'));
    container = ProviderContainer(
      overrides: [careProviderRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  /// The filter the visits page applies, once the usual care provider has
  /// been read.
  Future<VisitFilter> effective() async {
    final sub = container.listen(effectiveVisitFilterProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 50 && sub.read() is! AsyncData; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return sub.read().requireValue;
  }

  test('until one is chosen, it is all when there is no usual one', () async {
    expect(await effective(), VisitFilter.all);
  });

  test('until one is chosen, it is the usual care provider', () async {
    await repository.setUsualCareProvider(b);

    expect(await effective(), VisitsAtCareProvider(b));
  });

  test('once chosen, it stays whatever the usual one is', () async {
    await repository.setUsualCareProvider(b);
    container
        .read(visitFilterProvider.notifier)
        .choose(VisitsAtCareProvider(a));
    expect(await effective(), VisitsAtCareProvider(a));

    container.read(visitFilterProvider.notifier).choose(VisitFilter.all);
    expect(await effective(), VisitFilter.all);
  });

  test('the usual one taken out of use leaves all', () async {
    await repository.setUsualCareProvider(b);
    await repository.setCareProviderInUse(b, inUse: false);

    expect(await effective(), VisitFilter.all);
  });
}
