/// Fungsi bantu untuk membaca nilai JSON secara aman.
///
/// Respons API bisa saja memuat nilai null atau tipe yang berbeda dari dugaan,
/// sehingga setiap pembacaan diberi nilai cadangan agar aplikasi tidak crash.

int asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? asIntOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String asString(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) return value;
  return fallback;
}

String? asStringOrNull(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

bool asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

Map<String, dynamic> asMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
