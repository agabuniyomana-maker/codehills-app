import 'package:flutter_test/flutter_test.dart';

import 'package:code_hills_app/services/imigongo_identity.dart';

void main() {
  test('the same account id always yields the same identity', () {
    final first = ImigongoIdentity.forAccount('6f1c2a4e-0000-4000-8000-abc123');
    final second =
        ImigongoIdentity.forAccount('6f1c2a4e-0000-4000-8000-abc123');

    expect(second, first);
    expect(second.code, first.code);
    expect(second.frame, first.frame);
    expect(second.palette, first.palette);
    expect(second.cells.length, 9);
    for (var i = 0; i < first.cells.length; i++) {
      expect(second.cells[i].motif, first.cells[i].motif);
      expect(second.cells[i].rotation, first.cells[i].rotation);
      expect(second.cells[i].tint, first.cells[i].tint);
    }
  });

  test('different accounts get different patterns', () {
    final codes = <String>{};
    var identicalPatterns = 0;
    final patterns = <String>{};

    for (var i = 0; i < 500; i++) {
      final identity = ImigongoIdentity.forAccount('account-$i');
      codes.add(identity.code);
      final pattern = identity.cells
          .map((c) => '${c.motif.index}${c.rotation}${c.tint}')
          .join(',');

      // A hash guarantees repeatability, not uniqueness — measure how often a
      // whole 3x3 composition repeats and keep the design space large.
      if (!patterns.add(pattern)) identicalPatterns++;
    }

    expect(codes.length, greaterThan(490));
    expect(identicalPatterns, lessThan(5));
  });

  test('blank and anonymous keys are handled without crashing', () {
    expect(ImigongoIdentity.forAccount('').code, startsWith('IMI-'));
    expect(ImigongoIdentity.forAccount('   ').accountKey, 'anonymous');
  });

  test('pattern version is recorded for stored profiles', () {
    expect(ImigongoIdentity.patternVersion, greaterThanOrEqualTo(1));
  });
}
