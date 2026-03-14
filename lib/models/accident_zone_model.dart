import 'geo_point.dart';

class AccidentZone {
  final String id;
  final GeoPoint location;
  final int accidentsPerYear;
  final String description;
  final String roadName;

  const AccidentZone({
    required this.id,
    required this.location,
    required this.accidentsPerYear,
    required this.description,
    required this.roadName,
  });

  factory AccidentZone.fromJson(Map<String, dynamic> json) {
    return AccidentZone(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      location: GeoPoint(
        _toDouble(json['lat']) ?? 21.2514,
        _toDouble(json['lng']) ?? 81.6296,
      ),
      accidentsPerYear: (json['accidentsPerYear'] as num?)?.toInt() ?? 1,
      description: json['description']?.toString() ?? '',
      roadName: json['roadName']?.toString() ?? 'NH-30',
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
