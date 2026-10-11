import 'package:flutter_test/flutter_test.dart';
import 'package:condition_log/features/visits/domain/care_provider.dart';

void main() {
  final fullWidthSpace = String.fromCharCode(0x3000);

  group('CareProviderNames', () {
    test('keeps each name without its surrounding spaces', () {
      final names = CareProviderNames(hospital: ' 市民病院 ');

      expect(names.hospital, '市民病院');
      expect(names.department, isNull);
      expect(names.doctor, isNull);
    });

    test('keeps a blank name as none', () {
      final names = CareProviderNames(hospital: '市民病院', doctor: '  ');

      expect(names.doctor, isNull);
    });

    final noName = <(String, String?, String?, String?)>[
      ('no names', null, null, null),
      ('blank and empty names', '  ', '', null),
      ('a full-width space', fullWidthSpace, null, null),
    ];
    for (final (label, hospital, department, doctor) in noName) {
      test('refuses $label', () {
        expect(
          () => CareProviderNames(
            hospital: hospital,
            department: department,
            doctor: doctor,
          ),
          throwsArgumentError,
        );
      });
      test('orNone gives null for $label', () {
        expect(
          CareProviderNames.orNone(
            hospital: hospital,
            department: department,
            doctor: doctor,
          ),
          isNull,
        );
      });
    }

    test('orNone gives the names when one is left', () {
      expect(
        CareProviderNames.orNone(hospital: '  ', doctor: '山田'),
        CareProviderNames(doctor: '山田'),
      );
      expect(CareProviderNames.orNone(department: ' '), isNull);
    });

    test('lists the names it has from the widest to the narrowest', () {
      expect(CareProviderNames(doctor: '山田', hospital: '市民病院').parts, [
        '市民病院',
        '山田',
      ]);
      expect(
        CareProviderNames(
          hospital: '市民病院',
          department: '内科',
          doctor: '山田',
        ).parts,
        ['市民病院', '内科', '山田'],
      );
    });
  });

  group('CareProvider.choicesFor', () {
    CareProvider c(int id, {bool inUse = true}) => CareProvider(
      id: id,
      names: CareProviderNames(hospital: 'H$id'),
      inUse: inUse,
    );
    final all = [c(1), c(2, inUse: false), c(3)];

    test('offers those in use, in the order given', () {
      expect(
        [for (final x in CareProvider.choicesFor(all, null)) x.id],
        [1, 3],
      );
    });

    test('also offers the chosen one when it is out of use', () {
      expect(
        [for (final x in CareProvider.choicesFor(all, 2)) x.id],
        [1, 2, 3],
      );
    });
  });

  group('CareProvider.withId', () {
    final all = [
      CareProvider(
        id: 1,
        names: CareProviderNames(hospital: 'H1'),
        inUse: true,
      ),
      CareProvider(
        id: 2,
        names: CareProviderNames(hospital: 'H2'),
        inUse: false,
      ),
    ];

    test('finds the one under the id, in use or not', () {
      expect(CareProvider.withId(all, 2)?.id, 2);
    });

    test('is null when none is under the id', () {
      expect(CareProvider.withId(all, 3), isNull);
    });
  });
}
