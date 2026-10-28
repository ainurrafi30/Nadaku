/// Fungsi pemformat tampilan (durasi, angka, tanggal) dalam bahasa Indonesia.

String formatClock(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatSeconds(int seconds) => formatClock(Duration(seconds: seconds));

String formatCompact(int value) {
  if (value >= 1000000000) return '${_oneDecimal(value / 1000000000)} M';
  if (value >= 1000000) return '${_oneDecimal(value / 1000000)} jt';
  if (value >= 1000) return '${_oneDecimal(value / 1000)} rb';
  return value.toString();
}

String _oneDecimal(double value) {
  final text = value.toStringAsFixed(1);
  if (text.endsWith('.0')) return text.substring(0, text.length - 2);
  return text.replaceAll('.', ',');
}

const List<String> _monthNames = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Mengubah tanggal ISO (yyyy-MM-dd) menjadi contoh "12 Mei 2024".
/// Mengembalikan "-" jika tanggal tidak tersedia atau tidak valid.
String formatReleaseDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final parts = iso.split('-');
  if (parts.length != 3) return '-';
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return '-';
  if (year <= 0 || month < 1 || month > 12 || day < 1) return '-';
  return '$day ${_monthNames[month - 1]} $year';
}

/// Mengambil tahun dari tanggal ISO, atau null jika tidak valid.
String? formatYear(String? iso) {
  if (iso == null || iso.length < 4) return null;
  final year = int.tryParse(iso.substring(0, 4));
  if (year == null || year <= 0) return null;
  return year.toString();
}
