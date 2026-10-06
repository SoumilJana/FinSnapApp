import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import 'analytics_engine.dart'; // To reuse BudgetSummary and getTotalSpending if needed

class InsightAnomaly {
  final String category;
  final double currentSpend;
  final double previousSpend;
  final double percentageIncrease;

  InsightAnomaly({
    required this.category,
    required this.currentSpend,
    required this.previousSpend,
    required this.percentageIncrease,
  });
}

class AiInsightsEngine {
  final TransactionRepository _repository;
  final AnalyticsEngine _analytics;

  AiInsightsEngine(this._repository) : _analytics = AnalyticsEngine(_repository);

  /// Calculates total impulse spending for the current month
  double getMonthlyImpulseSpending() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final transactions = _repository.transactionsNotifier.value;

    double total = 0;
    for (final t in transactions) {
      if (t.isIncome || !t.isImpulse) continue;
      
      final txDate = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
      if (txDate.isAfter(startOfMonth) || txDate.isAtSameMomentAs(startOfMonth)) {
        total += t.amount;
      }
    }
    return total;
  }

  /// Forecasts end-of-month spending based on current daily average
  double getBurnRateForecast() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = now.day;

    final currentSpent = _analytics.getTotalSpending(
      startDate: startOfMonth,
      endDate: now,
    );

    if (daysElapsed == 0) return 0;

    final dailyAverage = currentSpent / daysElapsed;
    return dailyAverage * daysInMonth;
  }

  /// Finds categories where spending is significantly higher than last month
  List<InsightAnomaly> getCategoryAnomalies() {
    final now = DateTime.now();
    
    // Current Month Range
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = now;

    // Previous Month Range
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    final currentBreakdown = _analytics.getCategoryBreakdown(
      startDate: currentMonthStart,
      endDate: currentMonthEnd,
    );
    
    final prevBreakdown = _analytics.getCategoryBreakdown(
      startDate: prevMonthStart,
      endDate: prevMonthEnd,
    );

    // Create a map for previous month's spending
    final prevMap = <String, double>{};
    for (final c in prevBreakdown) {
      prevMap[c.category] = c.amount;
    }

    final anomalies = <InsightAnomaly>[];

    for (final current in currentBreakdown) {
      // Only care about significant categories (e.g., spent > 500)
      if (current.amount < 500) continue;

      final prevAmount = prevMap[current.category] ?? 0;
      
      // If previous amount is very small or 0, it's inherently a huge increase,
      // but we should cap or handle it properly.
      if (prevAmount < 100) {
        if (current.amount > 1000) { // Large new expense
          anomalies.add(InsightAnomaly(
            category: current.category,
            currentSpend: current.amount,
            previousSpend: prevAmount,
            percentageIncrease: 999, // Represents a 'new/large' spike
          ));
        }
        continue;
      }

      final increase = current.amount - prevAmount;
      if (increase > 0) {
        final percentage = (increase / prevAmount) * 100;
        // If increased by more than 30% and absolute increase is > 500
        if (percentage > 30 && increase > 500) {
          anomalies.add(InsightAnomaly(
            category: current.category,
            currentSpend: current.amount,
            previousSpend: prevAmount,
            percentageIncrease: percentage,
          ));
        }
      }
    }

    // Sort by highest percentage increase
    anomalies.sort((a, b) => b.percentageIncrease.compareTo(a.percentageIncrease));
    return anomalies;
  }
}
