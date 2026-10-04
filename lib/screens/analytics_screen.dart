import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../repositories/transaction_repository.dart';
import '../services/analytics_engine.dart';
import '../utils/category_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsEngine _engine;
  final TransactionRepository _repository = TransactionRepository();

  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Month', 'Last Month', 'All Time'];

  @override
  void initState() {
    super.initState();
    _engine = AnalyticsEngine(_repository);
    _repository.transactionsNotifier.addListener(_onDataChanged);
    _repository.monthlyBudgetNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _repository.transactionsNotifier.removeListener(_onDataChanged);
    _repository.monthlyBudgetNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  DateTime? _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Last Month':
        return DateTime(now.year, now.month - 1, 1);
      case 'All Time':
      default:
        return null;
    }
  }

  DateTime? _getEndDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Month':
        // The last day of this month (by getting the 0th day of next month)
        return DateTime(now.year, now.month + 1, 0);
      case 'Last Month':
        return DateTime(now.year, now.month, 0);
      case 'All Time':
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = _getStartDate();
    final endDate = _getEndDate();

    final budgetSummary = _engine.getBudgetSummary(
      startDate: startDate,
      endDate: endDate,
    );
    final categoryData = _engine.getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
    );
    final necessityData = _engine.getSpendingTypeBreakdown(
      startDate: startDate,
      endDate: endDate,
    );
    final coverageData = _engine.getClassificationCoverage(
      startDate: startDate,
      endDate: endDate,
    );

    // Only fetch trends if it's a bounded date range
    List<SpendingTrendPoint> trendData = [];
    if (startDate != null && endDate != null) {
      trendData = _engine.getSpendingTrend(
        startDate: startDate,
        endDate: endDate,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean light gray
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E1E2C),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1E1E2C),
                ),
                style: const TextStyle(
                  color: Color(0xFF1E1E2C),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPeriod = newValue;
                    });
                  }
                },
                items: _periods.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 120,
        ), // Bottom padding for FAB/Nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinancialOverview(budgetSummary),
            const SizedBox(height: 24),
            if (trendData.isNotEmpty) ...[
              _buildSpendingTrend(trendData),
              const SizedBox(height: 24),
            ],
            _buildCategorySection(categoryData, budgetSummary.spent),
            const SizedBox(height: 24),
            _buildNecessitySection(necessityData),
            const SizedBox(height: 24),
            if (categoryData.isNotEmpty) ...[
              _buildTopSpendingAreas(categoryData),
              const SizedBox(height: 24),
            ],
            if (coverageData.totalTransactions > 0) ...[
              _buildDataCoverage(coverageData),
              const SizedBox(height: 24),
            ],
            _buildAIPreview(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WIDGET BUILDERS
  // --------------------------------------------------------------------------

  Widget _buildFinancialOverview(BudgetSummary summary) {
    // Determine MoM Comparison if applicable
    Widget momWidget = const SizedBox.shrink();
    if (_selectedPeriod == 'This Month') {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      final mom = _engine.getMonthOverMonthComparison(start, end);

      if (mom.hasSufficientData) {
        final icon = mom.isIncrease ? Icons.arrow_upward : Icons.arrow_downward;
        final color = mom.isIncrease ? Colors.redAccent : Colors.greenAccent;
        final text =
            '${mom.percentageChange.toStringAsFixed(1)}% vs last month';

        momWidget = Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL SPENT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${summary.spent.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          momWidget,
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${summary.percentageUsed.toStringAsFixed(0)}% of ₹${summary.budget.toStringAsFixed(0)} budget',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '₹${summary.remaining > 0 ? summary.remaining.toStringAsFixed(0) : "0"} remaining',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.budget > 0
                  ? (summary.spent / summary.budget).clamp(0.0, 1.0)
                  : 0,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.percentageUsed > 90
                    ? Colors.redAccent
                    : (summary.percentageUsed > 75
                          ? Colors.orangeAccent
                          : Colors.greenAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrend(List<SpendingTrendPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0)
      return const SizedBox.shrink(); // No spending trend to show

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].amount));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending Trend',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.only(
            top: 24,
            bottom: 16,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final intIndex = value.toInt();
                      if (intIndex < 0 || intIndex >= data.length)
                        return const SizedBox.shrink();

                      // Show roughly 5 labels across the bottom
                      if (intIndex % ((data.length / 5).ceil()) == 0 ||
                          intIndex == data.length - 1) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('d MMM').format(data[intIndex].date),
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF1E1E2C),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF1E1E2C).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(List<CategorySummary> data, double totalSpent) {
    if (data.isEmpty) {
      return _buildEmptyState('Spending by Category');
    }

    // Top 5 + Other
    List<CategorySummary> displayData = [];
    if (data.length > 5) {
      displayData = data.take(5).toList();
      double otherAmount = 0;
      for (int i = 5; i < data.length; i++) {
        otherAmount += data[i].amount;
      }
      final otherPercentage = totalSpent > 0
          ? (otherAmount / totalSpent) * 100
          : 0.0;
      displayData.add(CategorySummary('Other', otherAmount, otherPercentage));
    } else {
      displayData = List.from(data);
    }

    List<PieChartSectionData> sections = [];
    for (var cat in displayData) {
      sections.add(
        PieChartSectionData(
          color: CategoryColors.getColorForCategory(cat.category),
          value: cat.amount,
          title: '', // Hide labels inside donut, rely on list
          radius: 35, // Slim donut
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending by Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 65,
                        sections: sections,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${totalSpent.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E2C),
                          ),
                        ),
                        const Text(
                          'Total Spent',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Category List
              ...displayData.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: CategoryColors.getColorForCategory(
                            cat.category,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.category,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '₹${cat.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${cat.percentage.toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNecessitySection(List<NecessitySummary> data) {
    if (data.isEmpty || data.every((d) => d.amount == 0)) {
      return _buildEmptyState('Necessity Breakdown');
    }

    final necessary = data.firstWhere(
      (e) => e.type == 'Necessary',
      orElse: () => NecessitySummary('Necessary', 0, 0),
    );
    final discretionary = data.firstWhere(
      (e) => e.type == 'Discretionary',
      orElse: () => NecessitySummary('Discretionary', 0, 0),
    );
    final unclassified = data.firstWhere(
      (e) => e.type == 'Unclassified',
      orElse: () => NecessitySummary('Unclassified', 0, 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Necessity Breakdown',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildNecessityRow(
                'Necessary',
                necessary.amount,
                necessary.percentage,
                Colors.greenAccent.shade400,
              ),
              const Divider(height: 32),
              _buildNecessityRow(
                'Discretionary',
                discretionary.amount,
                discretionary.percentage,
                Colors.orangeAccent,
              ),
              const Divider(height: 32),
              _buildNecessityRow(
                'Unclassified',
                unclassified.amount,
                unclassified.percentage,
                Colors.grey.shade400,
              ),

              if (unclassified.percentage > 10) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${unclassified.percentage.toStringAsFixed(0)}% of spending is currently unclassified.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNecessityRow(
    String label,
    double amount,
    double percentage,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E2C),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSpendingAreas(List<CategorySummary> data) {
    // Already sorted descending by the engine
    final topData = data.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Spending Areas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(topData.length, (index) {
              final cat = topData[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        cat.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '₹${cat.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E2C),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCoverage(DataCoverageSummary data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Coverage',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Classification',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${data.coveragePercentage.toStringAsFixed(0)}% classified',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: data.coveragePercentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.indigoAccent.shade200,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIPreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF1E1E2C)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.amberAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your personalized spending analysis will appear here once the AI Engine is activated in the next phase.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Center(
            child: Text(
              'Not enough data available.',
              style: TextStyle(color: Colors.black45, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
