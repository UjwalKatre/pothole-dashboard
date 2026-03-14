import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/pothole_model.dart';

class PotholeDetailDialog extends StatelessWidget {
  final PotholeModel pothole;
  const PotholeDetailDialog({super.key, required this.pothole});

  @override
  Widget build(BuildContext context) {
    final costs = _calculateCosts(pothole.area, pothole.depth, pothole.volume);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 45, child: _buildImageSection()),
                      const SizedBox(width: 20),
                      Expanded(flex: 55, child: _buildDetailsSection(costs)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'POTHOLE DETAIL — ${pothole.potholeId}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              Text(
                pothole.roadName,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ]),
          ),
          _SeverityBadge(severity: pothole.severity.name),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('YOLO DETECTION IMAGE'),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: pothole.yoloImageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    pothole.yoloImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                )
              : _imagePlaceholder(),
        ),
        const SizedBox(height: 10),
        if (pothole.imageUrl.isNotEmpty) ...[
          _sectionTitle('ORIGINAL IMAGE'),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderGrey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                pothole.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        _sectionTitle('MEASUREMENTS'),
        const SizedBox(height: 8),
        _MeasurementsCard(area: pothole.area, depth: pothole.depth, volume: pothole.volume),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.image_not_supported_outlined, size: 40, color: AppTheme.borderGrey),
        const SizedBox(height: 8),
        const Text('Image not available', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
      ]),
    );
  }

  Widget _buildDetailsSection(Map<String, double> costs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoGrid(pothole: pothole),
        const SizedBox(height: 16),
        _sectionTitle('COST ESTIMATION'),
        const SizedBox(height: 8),
        _CostCard(costs: costs),
        const SizedBox(height: 16),
        _sectionTitle('CONTRACTOR DETAILS'),
        const SizedBox(height: 8),
        _ContractorCard(contractor: pothole.contractor),
        const SizedBox(height: 16),
        _sectionTitle('STATUS TIMELINE'),
        const SizedBox(height: 8),
        _TimelineCard(pothole: pothole),
      ],
    );
  }

  Widget _sectionTitle(String title) => Row(children: [
    Container(width: 3, height: 14, color: AppTheme.primaryBlue),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppTheme.textLight)),
  ]);

  Map<String, double> _calculateCosts(double area, double depth, double volume) {
    final v = volume > 0 ? volume : area * (depth / 100);
    final scale = (v / 0.1).clamp(0.5, 5.0);
    final labour = (1000 * scale).roundToDouble().clamp(600.0, 4500.0);
    final dambar = (1500 * scale).roundToDouble().clamp(900.0, 7000.0);
    final sand = (300 * scale).roundToDouble().clamp(200.0, 1500.0);
    return {
      'labour': labour,
      'dambar': dambar,
      'sand': sand,
      'total': labour + dambar + sand,
    };
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }
}

class _MeasurementsCard extends StatelessWidget {
  final double area, depth, volume;
  const _MeasurementsCard({required this.area, required this.depth, required this.volume});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBDD7F4)),
      ),
      child: Column(children: [
        _row('Area (m²)', '${area.toStringAsFixed(2)} m²', Icons.crop_square),
        const Divider(height: 14),
        _row('Est. Depth (cm)', '${depth.toStringAsFixed(1)} cm', Icons.arrow_downward),
        const Divider(height: 14),
        _row('Volume (m³)', '${volume.toStringAsFixed(3)} m³', Icons.view_in_ar),
      ]),
    );
  }

  Widget _row(String label, String value, IconData icon) => Row(children: [
    Icon(icon, size: 14, color: AppTheme.lightBlue),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
    const Spacer(),
    Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
  ]);
}

class _InfoGrid extends StatelessWidget {
  final PotholeModel pothole;
  const _InfoGrid({required this.pothole});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.2,
      children: [
        _InfoTile(label: 'Pothole ID', value: pothole.potholeId, icon: Icons.fingerprint),
        _InfoTile(label: 'Road', value: pothole.roadName, icon: Icons.route),
        _InfoTile(
          label: 'Registered',
          value: DateFormat('dd/MM/yyyy').format(pothole.registeredDate),
          icon: Icons.calendar_today,
        ),
        _InfoTile(label: 'Duration', value: pothole.durationText, icon: Icons.timer),
        _InfoTile(label: 'Accidents Nearby', value: '${pothole.accidentCount}/yr', icon: Icons.warning_amber),
        _InfoTile(label: 'Location', value: '${pothole.location.lat.toStringAsFixed(3)}, ${pothole.location.lng.toStringAsFixed(3)}', icon: Icons.location_on),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: AppTheme.primaryBlue),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}

class _CostCard extends StatelessWidget {
  final Map<String, double> costs;
  const _CostCard({required this.costs});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBDE5BD)),
      ),
      child: Column(children: [
        _costRow(Icons.person_outline, 'Labour', costs['labour'] ?? 0, fmt),
        const SizedBox(height: 8),
        _costRow(Icons.water_drop_outlined, 'Bitumen / Dambar', costs['dambar'] ?? 0, fmt),
        const SizedBox(height: 8),
        _costRow(Icons.grain, 'Sand & Aggregate', costs['sand'] ?? 0, fmt),
        const Divider(height: 16),
        Row(children: [
          const Icon(Icons.currency_rupee, size: 16, color: AppTheme.successGreen),
          const SizedBox(width: 4),
          const Text('TOTAL ESTIMATED COST', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.successGreen)),
          const Spacer(),
          Text('₹${fmt.format(costs['total'] ?? 0)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.successGreen)),
        ]),
      ]),
    );
  }

  Widget _costRow(IconData icon, String label, double value, NumberFormat fmt) => Row(children: [
    Icon(icon, size: 14, color: AppTheme.textLight),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
    const Spacer(),
    Text('₹${fmt.format(value)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
  ]);
}

class _ContractorCard extends StatelessWidget {
  final String contractor;
  const _ContractorCard({required this.contractor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.engineering, color: AppTheme.primaryBlue, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(contractor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
          const SizedBox(height: 2),
          const Text('Registered PWD Contractor', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.successGreen.withOpacity(0.4))),
          child: const Text('VERIFIED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.successGreen)),
        ),
      ]),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final PotholeModel pothole;
  const _TimelineCard({required this.pothole});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(children: [
        _timelineItem(Icons.add_circle_outline, 'Reported', DateFormat('dd MMM yyyy').format(pothole.registeredDate), AppTheme.primaryBlue, true),
        if (pothole.status == PotholeStatus.resolved && pothole.resolvedDate != null)
          _timelineItem(Icons.check_circle_outline, 'Resolved', DateFormat('dd MMM yyyy').format(pothole.resolvedDate!), AppTheme.successGreen, true),
        if (pothole.status == PotholeStatus.active)
          _timelineItem(Icons.build_circle_outlined, 'Repair Pending', pothole.durationText + ' elapsed', AppTheme.warningAmber, false),
      ]),
    );
  }

  Widget _timelineItem(IconData icon, String title, String subtitle, Color color, bool done) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
      ])),
    ]),
  );
}
