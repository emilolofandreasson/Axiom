import 'dart:convert';
import 'package:crypto/crypto.dart';

/// One-way transformation: Entra ID `sub` claim → anonymized Subject_ID.
///
/// Uses HMAC-SHA256 with a per-deployment secret so the UUID is:
///   - Stable across sessions for the same user
///   - Irreversible (cannot reconstruct the real sub claim)
///   - Consistent across all apps in the ecosystem (same secret = same UUID)
///
/// The [salt] MUST be loaded from secure remote config, never hardcoded.
abstract final class SubjectIdHasher {
  static String hash(String entraSubClaim, String salt) {
    final key  = utf8.encode(salt);
    final data = utf8.encode(entraSubClaim);
    final mac  = Hmac(sha256, key).convert(data);

    // Format as UUID v4-shaped string for downstream compatibility.
    final hex = mac.toString();
    return '${hex.substring(0, 8)}-'
           '${hex.substring(8, 12)}-'
           '4${hex.substring(13, 16)}-'   // version 4 marker
           '${hex.substring(16, 20)}-'
           '${hex.substring(20, 32)}';
  }
}
