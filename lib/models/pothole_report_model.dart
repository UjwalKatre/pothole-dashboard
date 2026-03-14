class PotholeReport {
  final String id;
  final double latitude;
  final double longitude;
  final String imageBase64;
  final double distanceCovered;
  final DateTime timestamp;
  final String status; // 'active' or 'resolved'

  const PotholeReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imageBase64,
    required this.distanceCovered,
    required this.timestamp,
    this.status = 'active',
  });

  factory PotholeReport.fromMap(String key, Map<String, dynamic> map) {
    return PotholeReport(
      id: key,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      imageBase64: map['imageBase64']?.toString() ?? '',
      distanceCovered: (map['distanceCovered'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ?? 0,
      ),
      status: map['status']?.toString() ?? 'active',
    );
  }
}