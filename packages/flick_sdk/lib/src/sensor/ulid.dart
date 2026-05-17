import 'dart:math';

/// Pure-Dart ULID (Universally Unique Lexicographically Sortable Identifier).
///
/// Format: [TTTTTTTTTT][RRRRRRRRRRRRRRRR]
///   - 10 chars: 48-bit Unix ms timestamp (sort order guaranteed)
///   - 16 chars: 80-bit cryptographic random
///
/// Why ULID over UUID:
///   - Sortable by creation time → B-tree-friendly inserts in Delta Lake
///   - Globally unique → safe for de-duplication across shards
///   - URL-safe base32 encoding (no hyphens, always 26 chars)
abstract final class Ulid {
  static const _chars  = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static final _random = Random.secure();

  static String generate() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return _encodeTime(ms) + _encodeRandom();
  }

  /// Extracts the timestamp from a ULID string.
  static DateTime timestampOf(String ulid) {
    assert(ulid.length == 26, 'Invalid ULID length');
    var t = 0;
    for (var i = 0; i < 10; i++) {
      t = (t << 5) | _chars.indexOf(ulid[i]);
    }
    return DateTime.fromMillisecondsSinceEpoch(t, isUtc: true);
  }

  static String _encodeTime(int ms) {
    var t = ms;
    final buf = List<String>.filled(10, '');
    for (var i = 9; i >= 0; i--) {
      buf[i] = _chars[t & 0x1F];
      t >>= 5;
    }
    return buf.join();
  }

  static String _encodeRandom() {
    final buf = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buf.write(_chars[_random.nextInt(32)]);
    }
    return buf.toString();
  }
}
