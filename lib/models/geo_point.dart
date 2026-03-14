class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng};

  factory GeoPoint.fromMap(dynamic data) {
    final map = _safeMap(data);
    return GeoPoint(
      _toDouble(map['lat']) ?? 21.2514,
      _toDouble(map['lng']) ?? 81.6296,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static Map<String, dynamic> _safeMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}
