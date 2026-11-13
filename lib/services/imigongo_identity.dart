/// The Imigongo-inspired motif drawn in one cell of an identity pattern.
enum ImigongoMotif { diamond, triangle, chevron, zigzag, spiral }

/// One cell of the generated composition.
class ImigongoCell {
  const ImigongoCell({
    required this.motif,
    required this.rotation,
    required this.tint,
  });

  final ImigongoMotif motif;

  /// Quarter turns (0-3) applied when the cell is painted.
  final int rotation;

  /// Index into the shared earth-tone palette.
  final int tint;
}

/// A deterministic, account-derived Imigongo identity.
///
/// The seed is the account's stable identifier — `auth.users.id` in Supabase
/// mode, or an id generated once per local account — never the display name.
/// Renaming an account therefore never changes its artwork, and the same
/// account sees exactly the same pattern after logout/login, on another
/// device and after reinstalling.
///
/// [patternVersion] tracks the composition design so a future redesign can be
/// rolled out without silently changing existing accounts. The stable account
/// id stays the source of truth: the artwork is always regenerated from it,
/// never stored as an image.
///
/// This is artwork generation only. It must never be used to protect
/// passwords or to make any security decision — password hashing and
/// authentication stay entirely inside Supabase Auth.
class ImigongoIdentity {
  const ImigongoIdentity._({
    required this.accountKey,
    required this.seed,
    required this.frame,
    required this.palette,
    required this.cells,
    required this.code,
  });

  /// Bumped when the composition changes shape, so a stored profile can tell
  /// which design an account was rendered with.
  static const int patternVersion = 1;

  /// Accessible label used wherever the artwork appears.
  static const String label = 'Your Imigongo identity';

  /// The stable account identifier this identity was derived from. Never
  /// render this directly — public UI shows [code] instead.
  final String accountKey;

  /// 32-bit seed, kept for diagnostics and collision checks.
  final int seed;

  /// Border treatment variant (0-3).
  final int frame;

  /// Background palette variant (0-3).
  final int palette;

  /// Nine cells, row-major, making the 3x3 composition.
  final List<ImigongoCell> cells;

  /// Short human-readable identity code, e.g. `IMI-7K2-9FQ`. Derived for
  /// display only — it is not a secret.
  final String code;

  /// Builds the identity for [accountKey] (see the class docs).
  ///
  /// Pure function: the same key always yields the same identity, on every
  /// platform and Dart runtime.
  factory ImigongoIdentity.forAccount(String accountKey) {
    final key = accountKey.trim().isEmpty ? 'anonymous' : accountKey.trim();
    final seed = _seedFor(key);
    var state = seed;

    int take() {
      state = _step(state);
      return state;
    }

    final frame = take() % 4;
    final palette = take() % 4;

    final cells = <ImigongoCell>[
      for (var i = 0; i < 9; i++)
        ImigongoCell(
          motif: ImigongoMotif.values[take() % ImigongoMotif.values.length],
          rotation: take() % 4,
          tint: take() % 4,
        ),
    ];

    // Ambiguous glyphs (0/O, 1/I) are left out so the code can be read aloud.
    const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final buffer = StringBuffer('IMI');
    for (var group = 0; group < 2; group++) {
      var chunk = 0;
      for (var i = 0; i < 3; i++) {
        chunk = (chunk << 5) | (take() & 0x1F);
      }
      buffer
        ..write('-')
        ..write(alphabet[(chunk >> 10) & 0x1F])
        ..write(alphabet[(chunk >> 5) & 0x1F])
        ..write(alphabet[chunk & 0x1F]);
    }

    return ImigongoIdentity._(
      accountKey: key,
      seed: seed,
      frame: frame,
      palette: palette,
      cells: List<ImigongoCell>.unmodifiable(cells),
      code: buffer.toString(),
    );
  }

  /// 32-bit string hash. Every operation stays inside 32 bits (and below
  /// 2^53 for the multiply) so the result is identical on the Dart VM and on
  /// the web, where ints are JavaScript numbers.
  static int _seedFor(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + (unit & 0xFFFF)) & 0xFFFFFFFF;
    }
    // xorshift avalanche for dispersion; a few rounds is plenty here.
    var mixed = hash ^ 0x9E3779B9;
    for (var i = 0; i < 3; i++) {
      mixed = _step(mixed);
    }
    return mixed;
  }

  /// xorshift32 — deterministic, and safe on every platform.
  static int _step(int value) {
    var x = value & 0xFFFFFFFF;
    x ^= (x << 13) & 0xFFFFFFFF;
    x &= 0xFFFFFFFF;
    x ^= x >>> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    return x & 0xFFFFFFFF;
  }

  @override
  bool operator ==(Object other) =>
      other is ImigongoIdentity &&
      other.accountKey == accountKey &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(accountKey, seed);

  @override
  String toString() => 'ImigongoIdentity($code, seed: $seed)';
}
