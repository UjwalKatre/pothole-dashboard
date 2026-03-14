import 'geo_point.dart';

class ScannedRoad {
  final String id;
  final String roadName;
  final DateTime timestamp;
  final List<GeoPoint> path;
  final String droneId;

  const ScannedRoad({
    required this.id,
    required this.roadName,
    required this.timestamp,
    required this.path,
    required this.droneId,
  });

  factory ScannedRoad.fromMap(String key, Map<String, dynamic> map) {
    final ts = map['timestamp'];
    final timestamp = ts != null
        ? DateTime.fromMillisecondsSinceEpoch((ts as num).toInt())
        : DateTime.now();
    final pathData = map['path'];
    List<GeoPoint> parsedPath = [];
    if (pathData is List) {
      parsedPath = pathData.whereType<Map>().map((p) => GeoPoint.fromMap(p)).toList();
    } else if (pathData is Map) {
      parsedPath = pathData.values.whereType<Map>().map((p) => GeoPoint.fromMap(p)).toList();
    }
    return ScannedRoad(
      id: key,
      roadName: map['roadName']?.toString() ?? 'Unknown Road',
      timestamp: timestamp,
      path: parsedPath,
      droneId: map['droneId']?.toString() ?? 'DRONE-01',
    );
  }

  Map<String, dynamic> toMap() => {
    'roadName': roadName,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'path': path.map((p) => p.toMap()).toList(),
    'droneId': droneId,
  };

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
