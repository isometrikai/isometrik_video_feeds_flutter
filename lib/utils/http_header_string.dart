/// Helpers for values sent as HTTP header field values.
///
/// Dart's http client only allows visible ASCII in header values. Location
/// names such as "Yaoundé" must be transliterated (e.g. "Yaounde") first.
extension HttpHeaderString on String {
  /// Returns an ASCII-only string safe to use as an HTTP header value.
  String toHttpHeaderValue() {
    if (isEmpty) return this;

    const accented =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüŸÿÑñŠšŽžÝýÞþßĐđ';
    const plain =
        'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNnSsZzYyBbSsDd';

    var result = this;
    for (var i = 0; i < accented.length; i++) {
      result = result.replaceAll(accented[i], plain[i]);
    }

    return result.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
  }
}
