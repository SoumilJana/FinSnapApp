import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'ai_insights_screen.dart';
import 'analytics_screen.dart';
import 'ai_chat_screen.dart';

import '../repositories/transaction_repository.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final TransactionRepository _repository = TransactionRepository();

  final List<Widget> _screens = [
    const HomeScreen(),
    const AiInsightsScreen(),
    const AnalyticsScreen(),
    const AiChatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _repository.transactionsNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _repository.transactionsNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  int get _needsAuditCount {
    return _repository.transactionsNotifier.value.where((t) => 
      t.note != null && 
      t.note!.trim().isNotEmpty && 
      t.aiReclassificationReason == null &&
      !t.isIncome
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body to flow under the floating bar
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 16.0),
          child: Container(
            height: 68,
            padding: const EdgeInsets.all(
              6.0,
            ), // Perfectly even 6px gap on all sides
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double tabWidth = constraints.maxWidth / 4;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // The sliding background pill
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      left: _currentIndex * tabWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: tabWidth,
                        // No horizontal padding: ensures the left/right semicircles perfectly match the outer pill's gap
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(
                            28,
                          ), // 68/2 - 6 = 28
                        ),
                      ),
                    ),
                    // The clickable icons and text
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildNavItem(
                          index: 0,
                          label: 'Home',
                          icon: Icons.grid_view_rounded,
                          width: tabWidth,
                        ),
                        _buildNavItem(
                          index: 1,
                          label: 'Insights',
                          icon: Icons.auto_awesome_outlined,
                          width: tabWidth,
                          badgeCount: _needsAuditCount,
                        ),
                        _buildNavItem(
                          index: 2,
                          label: 'Analytics',
                          icon: Icons.bar_chart_rounded,
                          width: tabWidth,
                        ),
                        _buildNavItem(
                          index: 3,
                          label: 'CA',
                          icon: Icons.chat_bubble_outline_rounded,
                          width: tabWidth,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required double width,
    int badgeCount = 0,
  }) {
    final bool isSelected = _currentIndex == index;
    
    Widget iconWidget = Icon(icon, color: const Color(0xFF0F172A), size: 24);
    
    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(
          badgeCount > 9 ? '9+' : badgeCount.toString(), 
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.redAccent,
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
