import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/pothole_report_model.dart';
import '../services/firebase_service.dart';

class Page2Potholes extends StatefulWidget {
  const Page2Potholes({super.key});

  @override
  State<Page2Potholes> createState() => _Page2PotholesState();
}

class _Page2PotholesState extends State<Page2Potholes> with SingleTickerProviderStateMixin {
  final FirebaseService _svc = FirebaseService();
  late TabController _tabController;
  List<PotholeReport> _active = [];
  List<PotholeReport> _resolved = [];
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subs.add(_svc.activeReportsStream().listen((list) {
      if (mounted) setState(() => _active = list);
    }));
    _subs.add(_svc.resolvedReportsStream().listen((list) {
      if (mounted) setState(() => _resolved = list);
    }));
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final s in _subs) s.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildHeader(),
      Expanded(child: TabBarView(
        controller: _tabController,
        children: [
          _ReportsList(
            reports: _active,
            emptyMessage: 'No active pothole reports',
            onResolve: (id) => _svc.resolvePothole(id),
          ),
          _ReportsList(
            reports: _resolved,
            emptyMessage: 'No resolved reports yet',
            onResolve: null,
          ),
        ],
      )),
    ]);
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.primaryBlue,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('POTHOLE REPORTS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              Text('NH-30, Chhattisgarh — pothole_reports', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
            const Spacer(),
            _StatBadge(label: 'Active', count: _active.length, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            _StatBadge(label: 'Resolved', count: _resolved.length, color: AppTheme.successGreen),
          ]),
        ),
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.construction, size: 16), const SizedBox(width: 6),
              Text('ACTIVE (${_active.length})'),
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline, size: 16), const SizedBox(width: 6),
              Text('RESOLVED (${_resolved.length})'),
            ])),
          ],
        ),
      ]),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label; final int count; final Color color;
  const _StatBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.5))),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$count $label', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _ReportsList extends StatelessWidget {
  final List<PotholeReport> reports;
  final String emptyMessage;
  final Future<void> Function(String)? onResolve;
  const _ReportsList({required this.reports, required this.emptyMessage, this.onResolve});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.inbox_outlined, size: 56, color: AppTheme.borderGrey),
        const SizedBox(height: 16),
        Text(emptyMessage, style: const TextStyle(fontSize: 15, color: AppTheme.textMedium)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _ReportCard(
        report: reports[i],
        rank: i + 1,
        onResolve: onResolve != null ? () => onResolve!(reports[i].id) : null,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final PotholeReport report;
  final int rank;
  final VoidCallback? onResolve;
  const _ReportCard({required this.report, required this.rank, this.onResolve});

  Uint8List? _getBytes() {
    try {
      if (report.imageBase64.isEmpty) return null;
      final clean = report.imageBase64.contains(',')
          ? report.imageBase64.split(',').last : report.imageBase64;
      return base64Decode(clean);
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _getBytes();
    final isResolved = report.status == 'resolved';

    return Card(
      child: IntrinsicHeight(
        child: Row(children: [
          // Left accent
          Container(
            width: 44,
            decoration: BoxDecoration(
              color: (isResolved ? AppTheme.successGreen : AppTheme.errorRed).withOpacity(0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
              border: Border(left: BorderSide(color: isResolved ? AppTheme.successGreen : AppTheme.errorRed, width: 4)),
            ),
            alignment: Alignment.center,
            child: Text('#$rank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isResolved ? AppTheme.successGreen : AppTheme.errorRed)),
          ),
          // Image thumbnail
          if (bytes != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(bytes, width: 70, height: 70, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          // Content
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Report #$rank',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textDark)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isResolved ? AppTheme.successGreen : AppTheme.errorRed).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: (isResolved ? AppTheme.successGreen : AppTheme.errorRed).withOpacity(0.4)),
                  ),
                  child: Text(isResolved ? 'RESOLVED' : 'ACTIVE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isResolved ? AppTheme.successGreen : AppTheme.errorRed)),
                ),
              ]),
              const SizedBox(height: 6),
              _row(Icons.location_on_outlined, '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}'),
              const SizedBox(height: 3),
              _row(Icons.access_time, DateFormat('dd MMM yyyy, HH:mm:ss').format(report.timestamp)),
              const SizedBox(height: 3),
              _row(Icons.straighten, '${report.distanceCovered.toStringAsFixed(2)} m distance covered'),
              const SizedBox(height: 10),
              if (onResolve != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Mark Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
    Icon(icon, size: 13, color: AppTheme.textLight),
    const SizedBox(width: 5),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium), overflow: TextOverflow.ellipsis)),
  ]);
}