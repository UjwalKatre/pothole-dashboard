import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'pages/page1_live_scan.dart';
import 'pages/page2_potholes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PotholeDashboardApp());
}

class PotholeDashboardApp extends StatelessWidget {
  const PotholeDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Road Pothole Monitoring Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardShell(),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.map_outlined, label: 'Live Scan'),
    _NavItem(icon: Icons.warning_amber_outlined, label: 'Potholes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildTopBar(),
      ),
      body: Row(
        children: [
          _buildSideNav(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                Page1LiveScan(),
                Page2Potholes(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppTheme.primaryBlue,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.account_balance, color: AppTheme.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'MINISTRY OF ROAD TRANSPORT & HIGHWAYS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Road Pothole Monitoring System',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _LiveIndicator(),
              const SizedBox(width: 16),
              Text(
                _currentDateTime(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _currentDateTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSideNav() {
    return Container(
      width: 72,
      color: const Color(0xFF002366),
      child: Column(
        children: [
          const SizedBox(height: 12),
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final selected = _selectedIndex == i;
            return Tooltip(
              message: item.label,
              preferBelow: false,
              child: InkWell(
                onTap: () => setState(() => _selectedIndex = i),
                child: Container(
                  width: 72,
                  height: 68,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.accentOrange.withOpacity(0.15) : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: selected ? AppTheme.accentOrange : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: selected ? AppTheme.accentOrange : Colors.white60,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? AppTheme.accentOrange : Colors.white54,
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _LiveIndicator extends StatefulWidget {
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent.withOpacity(_anim.value),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
