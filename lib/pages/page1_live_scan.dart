import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/accident_zone_model.dart';
import '../models/pothole_report_model.dart';
import '../models/scanned_road_model.dart';
import '../services/firebase_service.dart';
import '../services/gemini_vision_service.dart';

class Page1LiveScan extends StatefulWidget {
  const Page1LiveScan({super.key});

  @override
  State<Page1LiveScan> createState() => _Page1LiveScanState();
}

class _Page1LiveScanState extends State<Page1LiveScan> {
  final FirebaseService _svc = FirebaseService();
  GoogleMapController? _mapController;

  List<PotholeReport> _reports = [];
  List<AccidentZone> _zones = [];
  List<ScannedRoad> _scannedRoads = [];
  bool _loadingZones = true;

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _loadZones();
    _subs.add(_svc.potholeReportsStream().listen((reports) {
      if (mounted) {
        setState(() => _reports = reports);
        if (reports.isNotEmpty) {
          final last = reports.last;
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(last.latitude, last.longitude)),
          );
        }
      }
    }));
    _subs.add(_svc.scannedRoadsStream().listen((roads) {
      if (mounted) setState(() => _scannedRoads = roads);
    }));
  }

  Future<void> _loadZones() async {
    try {
      final zones = await GeminiVisionService.fetchAccidentBlackspots('NH-30');
      if (mounted) setState(() { _zones = zones; _loadingZones = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingZones = false);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Yellow polyline connecting all scanned points in order
  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};
    
    // Add scanned roads
    for (final road in _scannedRoads) {
      polylines.add(Polyline(
        polylineId: PolylineId('scanned_road_${road.id}'),
        points: road.path.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: Colors.orange,
        width: 5,
      ));
    }
    
    // Add pothole connection line if no scanned roads
    if (_scannedRoads.isEmpty && _reports.length >= 2) {
      polylines.add(Polyline(
        polylineId: const PolylineId('pothole_path'),
        points: _reports
            .map((r) => LatLng(r.latitude, r.longitude))
            .toList(),
        color: Colors.amber,
        width: 5,
      ));
    }
    
    return polylines;
  }

  // Markers: red for active potholes, green for resolved, blue for latest position
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (int i = 0; i < _reports.length; i++) {
      final r = _reports[i];
      final status = r.status.toLowerCase();
      final isActive = status == 'active';
      final hue = isActive ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen;
      markers.add(Marker(
        markerId: MarkerId('report_${r.id}'),
        position: LatLng(r.latitude, r.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: '${isActive ? 'Active' : 'Resolved'} Pothole #${i + 1}',
          snippet:
              '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}',
        ),
      ));
    }
    if (_reports.isNotEmpty) {
      final last = _reports.last;
      markers.add(Marker(
        markerId: const MarkerId('live_pos'),
        position: LatLng(last.latitude, last.longitude),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Latest Scan Point'),
      ));
    }
    return markers;
  }

  // Red heatmap circles for accident blackspots
  Set<Circle> _buildAccidentCircles() {
    return _zones.map((z) {
      final intensity = (z.accidentsPerYear / 25.0).clamp(0.15, 1.0);
      return Circle(
        circleId: CircleId('acc_${z.id}'),
        center: LatLng(z.location.lat, z.location.lng),
        radius: 600 + (intensity * 1200),
        fillColor: Colors.red.withOpacity(intensity * 0.4),
        strokeColor: Colors.red.withOpacity(0.7),
        strokeWidth: 1,
      );
    }).toSet();
  }

  LatLng get _initialTarget => _reports.isNotEmpty
      ? LatLng(_reports.last.latitude, _reports.last.longitude)
      : const LatLng(21.2514, 81.6296);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatusBar(),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 65, child: _buildMap()),
              const VerticalDivider(width: 1, color: AppTheme.borderGrey),
              Expanded(flex: 35, child: _buildPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    final totalDist =
        _reports.isEmpty ? 0.0 : _reports.last.distanceCovered;
    return Container(
      height: 40,
      color: const Color(0xFF1B3A6B),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        const Icon(Icons.map, color: Colors.white70, size: 15),
        const SizedBox(width: 6),
        const Text(
          'LIVE DRONE SCAN — NH-30, CHHATTISGARH',
          style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0),
        ),
        const Spacer(),
        _badge(Colors.red, '${_reports.where((r) => r.status.toLowerCase() == 'active').length} active'),
        const SizedBox(width: 10),
        _badge(Colors.green, '${_reports.where((r) => r.status.toLowerCase() != 'active').length} resolved'),
        const SizedBox(width: 10),
        _badge(Colors.green, '${totalDist.toStringAsFixed(1)} m covered'),
        const SizedBox(width: 10),
        _badge(Colors.orange, '${_scannedRoads.length} scans'),
        const SizedBox(width: 10),
        _badge(Colors.red, '${_zones.length} blackspots'),
      ]),
    );
  }

  Widget _badge(Color c, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withOpacity(0.2),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: c.withOpacity(0.5)),
        ),
        child: Row(children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: c,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _buildMap() {
    return Stack(children: [
      GoogleMap(
        initialCameraPosition:
            CameraPosition(target: _initialTarget, zoom: 13),
        onMapCreated: (c) => setState(() => _mapController = c),
        polylines: _buildPolylines(),
        markers: _buildMarkers(),
        circles: _buildAccidentCircles(),
        zoomControlsEnabled: true,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: false,
      ),
      Positioned(
        bottom: 100,
        left: 12,
        child: _buildLegend(),
      ),
      Positioned(
        top: 12,
        right: 12,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () {
              if (_reports.isNotEmpty) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_reports.last.latitude,
                        _reports.last.longitude),
                    14,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.my_location,
                  size: 20, color: AppTheme.primaryBlue),
            ),
          ),
        ),
      ),
      if (_loadingZones)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4)
              ],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                  width: 12,
                  height: 12,
                  child:
                      CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Loading accident data...',
                  style: TextStyle(fontSize: 11)),
            ]),
          ),
        ),
    ]);
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LEGEND',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textLight)),
            const SizedBox(height: 6),
            _legendRow(
              Container(
                  width: 28,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2))),
              'Scanned Path',
            ),
            const SizedBox(height: 4),
            _legendRow(
              Container(
                  width: 28,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(2))),
              'Pothole Path',
            ),
            const SizedBox(height: 4),
            _legendRow(
              const Icon(Icons.location_on,
                  color: Colors.red, size: 16),
              'Active Pothole',
            ),
            const SizedBox(height: 4),
            _legendRow(
              const Icon(Icons.location_on,
                  color: Colors.green, size: 16),
              'Resolved Pothole',
            ),
            const SizedBox(height: 4),
            _legendRow(
              const Icon(Icons.location_on,
                  color: Colors.blueAccent, size: 16),
              'Latest Position',
            ),
            const SizedBox(height: 4),
            _legendRow(
              Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.3),
                      border:
                          Border.all(color: Colors.red, width: 1.5))),
              'Accident Blackspot',
            ),
          ]),
    );
  }

  Widget _legendRow(Widget icon, String label) => Row(children: [
        icon,
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textMedium)),
      ]);

  Widget _buildPanel() {
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Container(
          color: AppTheme.primaryBlue,
          child: const TabBar(tabs: [
            Tab(text: 'DETECTIONS'),
            Tab(text: 'BLACKSPOTS'),
          ]),
        ),
        Expanded(
          child: TabBarView(children: [
            _DetectionsPanel(reports: _reports),
            AccidentZonesPanel(
                zones: _zones,
                loading: _loadingZones,
                error: null),
          ]),
        ),
      ]),
    );
  }
}

// ─── Detections Panel ─────────────────────────────────────────────────────────

class _DetectionsPanel extends StatelessWidget {
  final List<PotholeReport> reports;
  const _DetectionsPanel({required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: AppTheme.borderGrey),
              SizedBox(height: 12),
              Text('No potholes detected yet',
                  style: TextStyle(
                      color: AppTheme.textLight, fontSize: 14)),
              SizedBox(height: 6),
              Text('Start the drone survey app to begin scanning',
                  style: TextStyle(
                      color: AppTheme.textLight, fontSize: 12)),
            ]),
      );
    }
    final sorted = [...reports]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _DetectionCard(
        report: sorted[i],
        index: sorted.length - i,
      ),
    );
  }
}

class _DetectionCard extends StatelessWidget {
  final PotholeReport report;
  final int index;
  const _DetectionCard({required this.report, required this.index});

  Uint8List? _getBytes() {
    try {
      if (report.imageBase64.isEmpty) return null;
      final clean = report.imageBase64.contains(',')
          ? report.imageBase64.split(',').last
          : report.imageBase64;
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _getBytes();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: bytes != null
                ? Image.memory(bytes,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pothole #$index',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 3),
                  _row(Icons.location_on,
                      '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}'),
                  const SizedBox(height: 3),
                  _row(Icons.access_time,
                      DateFormat('dd MMM, HH:mm:ss')
                          .format(report.timestamp)),
                  const SizedBox(height: 3),
                  _row(Icons.straighten,
                      '${report.distanceCovered.toStringAsFixed(2)} m covered'),
                ]),
          ),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _ImageDialog(report: report),
            ),
            icon: const Icon(Icons.zoom_in,
                color: AppTheme.primaryBlue, size: 20),
            tooltip: 'View Image',
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: AppTheme.backgroundGrey,
        child: const Icon(Icons.image_not_supported_outlined,
            size: 24, color: AppTheme.borderGrey),
      );

  Widget _row(IconData icon, String text) => Row(children: [
        Icon(icon, size: 12, color: AppTheme.textLight),
        const SizedBox(width: 4),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMedium),
                overflow: TextOverflow.ellipsis)),
      ]);
}

// ─── Image Dialog ─────────────────────────────────────────────────────────────

class _ImageDialog extends StatelessWidget {
  final PotholeReport report;
  const _ImageDialog({required this.report});

  Uint8List? _getBytes() {
    try {
      if (report.imageBase64.isEmpty) return null;
      final clean = report.imageBase64.contains(',')
          ? report.imageBase64.split(',').last
          : report.imageBase64;
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _getBytes();
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8)),
          ),
          child: Row(children: [
            const Icon(Icons.image_outlined,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('POTHOLE IMAGE',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close,
                  color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
        ),
        // Image
        if (bytes != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Image.memory(bytes, fit: BoxFit.contain),
          )
        else
          const Padding(
            padding: EdgeInsets.all(40),
            child: Column(children: [
              Icon(Icons.broken_image_outlined,
                  size: 48, color: AppTheme.borderGrey),
              SizedBox(height: 8),
              Text('Image not available',
                  style: TextStyle(color: AppTheme.textLight)),
            ]),
          ),
        // Footer info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundGrey,
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8)),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Text(
                '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w600),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time,
                  size: 14, color: AppTheme.textLight),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMM yyyy, HH:mm:ss')
                    .format(report.timestamp),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textLight),
              ),
              const Spacer(),
              const Icon(Icons.straighten,
                  size: 14, color: AppTheme.textLight),
              const SizedBox(width: 6),
              Text(
                '${report.distanceCovered.toStringAsFixed(2)} m covered',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textLight),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─── Accident Zones Panel (reused from original) ──────────────────────────────

class AccidentZonesPanel extends StatelessWidget {
  final List<AccidentZone> zones;
  final bool loading;
  final String? error;
  const AccidentZonesPanel(
      {super.key,
      required this.zones,
      required this.loading,
      this.error});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Fetching accident data via AI...',
                style: TextStyle(
                    color: AppTheme.textLight, fontSize: 13)),
          ]));
    }
    final sorted = [...zones]
      ..sort((a, b) => b.accidentsPerYear.compareTo(a.accidentsPerYear));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ZoneCard(zone: sorted[i], rank: i + 1),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final AccidentZone zone;
  final int rank;
  const _ZoneCard({required this.zone, required this.rank});

  @override
  Widget build(BuildContext context) {
    final intensity = (zone.accidentsPerYear / 25.0).clamp(0.0, 1.0);
    final Color badgeColor = intensity > 0.7
        ? AppTheme.errorRed
        : intensity > 0.4
            ? AppTheme.warningAmber
            : AppTheme.successGreen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.red.withOpacity(0.3))),
            alignment: Alignment.center,
            child: Text('#$rank',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.errorRed)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppTheme.textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                      '${zone.roadName}  •  ${zone.location.lat.toStringAsFixed(3)}, ${zone.location.lng.toStringAsFixed(3)}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textLight)),
                ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: badgeColor.withOpacity(0.4))),
            child: Column(children: [
              Text('${zone.accidentsPerYear}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: badgeColor)),
              Text('acc/yr',
                  style: TextStyle(
                      fontSize: 9,
                      color: badgeColor,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}