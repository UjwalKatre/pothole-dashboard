import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import '../models/pothole_report_model.dart';
import '../models/scanned_road_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static Map<String, dynamic> _safeMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  /// Stream all pothole reports sorted by timestamp
  Stream<List<PotholeReport>> potholeReportsStream() {
    return _db.child('pothole_reports').onValue.map((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data == null) return <PotholeReport>[];
      try {
        final map = _safeMap(data);
        final reports = map.entries
            .map((e) => PotholeReport.fromMap(e.key, _safeMap(e.value)))
            .toList();
        reports.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return reports;
      } catch (_) {
        return <PotholeReport>[];
      }
    });
  }

  Future<void> resolvePothole(String id) async {
    await _db.child('pothole_reports/$id').update({
      'status': 'resolved',
      'resolvedDate': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<PotholeReport>> activeReportsStream() {
    return potholeReportsStream().map((list) =>
        list.where((r) => r.status != 'resolved').toList());
  }

  Stream<List<PotholeReport>> resolvedReportsStream() {
    return potholeReportsStream().map((list) =>
        list.where((r) => r.status == 'resolved').toList());
  }

  /// Stream all scanned roads
  Stream<List<ScannedRoad>> scannedRoadsStream() {
    return _db.child('scanned_roads').onValue.map((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data == null) return <ScannedRoad>[];
      try {
        final map = _safeMap(data);
        final roads = map.entries
            .map((e) => ScannedRoad.fromMap(e.key, _safeMap(e.value)))
            .toList();
        roads.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return roads;
      } catch (_) {
        return <ScannedRoad>[];
      }
    });
  }

  double haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dlat = _rad(lat2 - lat1);
    final dlng = _rad(lng2 - lng1);
    final a = math.sin(dlat / 2) * math.sin(dlat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) *
        math.sin(dlng / 2) * math.sin(dlng / 2);
    return r * 2 * math.asin(math.sqrt(a));
  }

  double _rad(double deg) => deg * math.pi / 180;
}