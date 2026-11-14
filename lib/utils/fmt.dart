/// Formattazioni in italiano, senza dipendenze esterne.
class Fmt {
  static String _two(int n) => n.toString().padLeft(2, '0');

  static DateTime? _parse(String iso) => DateTime.tryParse(iso)?.toLocal();

  /// 2026-11-14T15:04:05Z -> 14/11/2026
  static String date(String iso) {
    final d = _parse(iso);
    if (d == null) return iso;
    return '${_two(d.day)}/${_two(d.month)}/${d.year}';
  }

  /// 2026-11-14T15:04:05Z -> 14/11/2026 · 15:04
  static String dateTime(String iso) {
    final d = _parse(iso);
    if (d == null) return iso;
    return '${date(iso)} · ${_two(d.hour)}:${_two(d.minute)}';
  }

  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  }

  static String plural(int n, String singular, String plural) =>
      n == 1 ? '$n $singular' : '$n $plural';
}
