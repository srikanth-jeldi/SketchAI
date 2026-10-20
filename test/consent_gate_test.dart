import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/ads/consent_gate.dart';

void main() {
  test(
    'ads require successful update, form and SDK permission in order',
    () async {
      final calls = <String>[];
      expect(
        await prepareAdConsent(
          update: () async {
            calls.add('update');
            return true;
          },
          showIfRequired: () async {
            calls.add('form');
            return true;
          },
          canRequestAds: () async {
            calls.add('permission');
            return true;
          },
        ),
        isTrue,
      );
      expect(calls, ['update', 'form', 'permission']);
    },
  );
  test('update failure never reaches form or ad permission', () async {
    var shown = false, requested = false;
    expect(
      await prepareAdConsent(
        update: () async => false,
        showIfRequired: () async {
          shown = true;
          return true;
        },
        canRequestAds: () async {
          requested = true;
          return true;
        },
      ),
      isFalse,
    );
    expect(shown, isFalse);
    expect(requested, isFalse);
  });
  test('form failure never reaches ad permission', () async {
    var requested = false;
    expect(
      await prepareAdConsent(
        update: () async => true,
        showIfRequired: () async => false,
        canRequestAds: () async {
          requested = true;
          return true;
        },
      ),
      isFalse,
    );
    expect(requested, isFalse);
  });
  test('denied permission and native errors leave ads disabled', () async {
    for (final fail in [false, true]) {
      expect(
        await prepareAdConsent(
          update: () async => true,
          showIfRequired: () async => true,
          canRequestAds: () async {
            if (fail) throw StateError('native channel unavailable');
            return false;
          },
        ),
        isFalse,
      );
    }
  });
}
