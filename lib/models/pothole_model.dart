import 'geo_point.dart';

enum PotholeSeverity { low, medium, high, critical }
enum PotholeStatus { active, resolved }

class PotholeModel {
  final String id;
  final String roadName;
  final GeoPoint location;
  final PotholeSeverity severity;
  final DateTime registeredDate;
  final String imageUrl;
  final String yoloImageUrl;
  final double area;
  final double depth;
  final double volume;
  final PotholeStatus status;
  final DateTime? resolvedDate;
  final String contractor;
  final int accidentCount;
  final String potholeId;

  const PotholeModel({
    required this.id,
    required this.roadName,
    required this.location,
    required this.severity,
    required this.registeredDate,
    required this.imageUrl,
    required this.yoloImageUrl,
    required this.area,
    required this.depth,
    required this.volume,
    required this.status,
    this.resolvedDate,
    required this.contractor,
    required this.accidentCount,
    required this.potholeId,
  });

  String get durationText {
    final diff = DateTime.now().difference(registeredDate);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''}';
    }
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    return '${diff.inHours} hour${diff.inHours != 1 ? 's' : ''}';
  }

  static PotholeSeverity _parseSeverity(String s) {
    switch (s.toLowerCase()) {
      case 'critical': return PotholeSeverity.critical;
      case 'high': return PotholeSeverity.high;
      case 'medium': return PotholeSeverity.medium;
      default: return PotholeSeverity.low;
    }
  }

  factory PotholeModel.fromMap(String key, Map<String, dynamic> map) {
    final locData = map['location'];
    final location = locData != null ? GeoPoint.fromMap(locData) : const GeoPoint(21.2514, 81.6296);
    final regTs = map['registeredDate'];
    final regDate = regTs != null
        ? DateTime.fromMillisecondsSinceEpoch((regTs as num).toInt())
        : DateTime.now().subtract(const Duration(days: 7));
    final resolvedTs = map['resolvedDate'];
    final resolvedDate = resolvedTs != null
        ? DateTime.fromMillisecondsSinceEpoch((resolvedTs as num).toInt())
        : null;
    return PotholeModel(
      id: key,
      potholeId: map['potholeId']?.toString() ?? 'PTH-${key.substring(0, key.length > 8 ? 8 : key.length).toUpperCase()}',
      roadName: map['roadName']?.toString() ?? 'Unknown Road',
      location: location,
      severity: _parseSeverity(map['severity']?.toString() ?? 'medium'),
      registeredDate: regDate,
      imageUrl: map['imageUrl']?.toString() ?? '',
      yoloImageUrl: map['yoloImageUrl']?.toString() ?? '',
      area: _toDouble(map['area']) ?? 1.0,
      depth: _toDouble(map['depth']) ?? 10.0,
      volume: _toDouble(map['volume']) ?? 0.1,
      status: (map['status']?.toString() == 'resolved') ? PotholeStatus.resolved : PotholeStatus.active,
      resolvedDate: resolvedDate,
      contractor: map['contractor']?.toString() ?? 'Unassigned',
      accidentCount: (map['accidentCount'] as num?)?.toInt() ?? 0,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> toMap() => {
    'potholeId': potholeId,
    'roadName': roadName,
    'location': location.toMap(),
    'severity': severity.name,
    'registeredDate': registeredDate.millisecondsSinceEpoch,
    'imageUrl': imageUrl,
    'yoloImageUrl': yoloImageUrl,
    'area': area,
    'depth': depth,
    'volume': volume,
    'status': status.name,
    if (resolvedDate != null) 'resolvedDate': resolvedDate!.millisecondsSinceEpoch,
    'contractor': contractor,
    'accidentCount': accidentCount,
  };
}
