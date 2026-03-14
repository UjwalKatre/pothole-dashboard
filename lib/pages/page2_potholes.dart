import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/pothole_report_model.dart';
import '../services/firebase_service.dart';
import '../widgets/pothole_report_detail_dialog.dart';

class Page2Potholes extends StatefulWidget {
  const Page2Potholes({super.key});

  @override
  State<Page2Potholes> createState() => _Page2PotholesState();
}

class _Page2PotholesState extends State<Page2Potholes>
    with SingleTickerProviderStateMixin {
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
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList(
              reports: _active,
              emptyMessage: 'No active pothole reports',
              emptySubMessage: 'All reported potholes have been resolved.',
              showResolve: true,
            ),
            _buildList(
              reports: _resolved,
              emptyMessage: 'No resolved reports yet',
              emptySubMessage:
                  'Resolved potholes will appear here automatically.',
              showResolve: false,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.primaryBlue,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('POTHOLE REPORTS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  Text('NH-30, Chhattisgarh',
                      style:
                          TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
            const Spacer(),
            _StatBadge(
                label: 'Active',
                count: _active.length,
                color: AppTheme.errorRed),
            const SizedBox(width: 8),
            _StatBadge(
                label: 'Resolved',
                count: _resolved.length,
                color: AppTheme.successGreen),
          ]),
        ),
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.construction, size: 16),
              const SizedBox(width: 6),
              Text('ACTIVE (${_active.length})'),
            ])),
            Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline, size: 16),
              const SizedBox(width: 6),
              Text('RESOLVED (${_resolved.length})'),
            ])),
          ],
        ),
      ]),
    );
  }

  Widget _buildList({
    required List<PotholeReport> reports,
    required String emptyMessage,
    required String emptySubMessage,
    required bool showResolve,
  }) {
    if (reports.isEmpty) {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            const Icon(Icons.inbox_outlined,
                size: 56, color: AppTheme.borderGrey),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(emptySubMessage,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textLight)),
          ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final report = reports[i];
        return _ReportCard(
          report: report,
          rank: i + 1,
          onResolve: showResolve ? () => _svc.resolvePothole(report.id) : null,
          onViewDetails: () {
            showDialog(
              context: ctx,
              barrierDismissible: true,
              builder: (dialogCtx) => PotholeReportDetailDialog(
                report: report,
                reportNumber: i + 1,
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Stat Badge ───────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count $label',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

// ─── Report Card ──────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final PotholeReport report;
  final int rank;
  final VoidCallback? onResolve;
  final VoidCallback onViewDetails;

  const _ReportCard({
    required this.report,
    required this.rank,
    required this.onViewDetails,
    this.onResolve,
  });

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
    final isResolved = report.status == 'resolved';
    final accentColor =
        isResolved ? AppTheme.successGreen : AppTheme.errorRed;

    return Card(
      elevation: 1,
      child: IntrinsicHeight(
        child: Row(children: [
          // Left accent bar
          Container(
            width: 48,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomLeft: Radius.circular(5)),
              border: Border(
                  left: BorderSide(color: accentColor, width: 4)),
            ),
            alignment: Alignment.center,
            child: Text('#$rank',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: accentColor)),
          ),

          // Thumbnail
          if (bytes != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.memory(bytes,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        report.id,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppTheme.textDark),
                      ),
                      const SizedBox(width: 10),
                      _StatusBadge(isResolved: isResolved),
                    ]),
                    const SizedBox(height: 7),
                    Wrap(spacing: 16, runSpacing: 4, children: [
                      _meta(Icons.location_on_outlined,
                          '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}'),
                      _meta(Icons.access_time,
                          DateFormat('dd MMM yyyy, HH:mm:ss')
                              .format(report.timestamp)),
                      _meta(Icons.straighten,
                          '${report.distanceCovered.toStringAsFixed(2)} m covered'),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                      if (onResolve != null) ...[
                        OutlinedButton.icon(
                          onPressed: onResolve,
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('Mark Resolved'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.successGreen,
                            side: const BorderSide(
                                color: AppTheme.successGreen),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(
                            Icons.visibility_outlined,
                            size: 14),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textLight),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMedium)),
        ],
      );
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isResolved;
  const _StatusBadge({required this.isResolved});

  @override
  Widget build(BuildContext context) {
    final color =
        isResolved ? AppTheme.successGreen : AppTheme.errorRed;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        isResolved ? 'RESOLVED' : 'ACTIVE',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }
}