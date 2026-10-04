import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

class CategorySummary {
  final String category;
  final double amount;
  final double percentage;
  CategorySummary(this.category, this.amount, this.percentage);
}

class SpendingTrendPoint {
  final DateTime date;
  final double amount;
  SpendingTrendPoint(this.date, this.amount);
}

class NecessitySummary {
  final String type;
  final double amount;
  final double percentage;
  NecessitySummary(this.type, this.amount, this.percentage);
}

class BudgetSummary {
  final double budget;
  final double spent;
  final double remaining;
  final double percentageUsed;
  BudgetSummary(this.budget, this.spent, this.remaining, this.percentageUsed);
}

class MonthOverMonthComparison {
  final double absoluteDifference;
  final double percentageChange;
  final bool isIncrease;
  final bool hasSufficientData;
  MonthOverMonthComparison(
    this.absoluteDifference,
    this.percentageChange,
    this.isIncrease,
    this.hasSufficientData,
  );
}

class DataCoverageSummary {
  final double totalTransactions;
  final double classifiedTransactions;
  final double coveragePercentage;
  DataCoverageSummary(
    this.totalTransactions,
    this.classifiedTransactions,
    this.coveragePercentage,
  );
}

class AnalyticsEngine {
  final TransactionRepository _repository;

  AnalyticsEngine(this._repository);

  // ---------------------------------------------------------
  // CORE METRICS
  // ---------------------------------------------------------

  double getTotalSpending({DateTime? startDate, DateTime? endDate}) {
    final transactions = _repository.transactionsNotifier.value;
    return _calculateTotal(transactions, startDate, endDate, isIncome: false);
  }

  double getTotalIncome({DateTime? startDate, DateTime? endDate}) {
    final transactions = _repository.transactionsNotifier.value;
    return _calculateTotal(transactions, startDate, endDate, isIncome: true);
  }

  BudgetSummary getBudgetSummary({DateTime? startDate, DateTime? endDate}) {
    final budget = _repository.monthlyBudgetNotifier.value;
    final spent = getTotalSpending(startDate: startDate, endDate: endDate);
    final remaining = budget - spent;
    final percentageUsed = budget > 0 ? (spent / budget) * 100 : 0.0;

    return BudgetSummary(budget, spent, remaining, percentageUsed);
  }

  MonthOverMonthComparison getMonthOverMonthComparison(
    DateTime currentMonthStart,
    DateTime currentMonthEnd,
  ) {
    // Current period
    final currentSpent = getTotalSpending(
      startDate: currentMonthStart,
      endDate: currentMonthEnd,
    );

    // Previous period
    final prevMonthStart = DateTime(
      currentMonthStart.year,
      currentMonthStart.month - 1,
      1,
    );
    final prevMonthEnd = currentMonthStart.subtract(
      const Duration(milliseconds: 1),
    );
    final prevSpent = getTotalSpending(
      startDate: prevMonthStart,
      endDate: prevMonthEnd,
    );

    // If there's no data for the previous month, we can't do a valid comparison.
    if (prevSpent == 0 && currentSpent == 0) {
      return MonthOverMonthComparison(0, 0, false, false);
    }
    if (prevSpent == 0) {
      // Started using app this month
      return MonthOverMonthComparison(currentSpent, 100.0, true, false);
    }

    final diff = currentSpent - prevSpent;
    final percentage = (diff.abs() / prevSpent) * 100;

    return MonthOverMonthComparison(diff.abs(), percentage, diff > 0, true);
  }

  // ---------------------------------------------------------
  // CATEGORIZATION & BREAKDOWNS
  // ---------------------------------------------------------

  List<CategorySummary> getCategoryBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final transactions = _repository.transactionsNotifier.value;
    final Map<String, double> rawBreakdown = {};
    double totalSpent = 0;

    for (final t in transactions) {
      if (t.isIncome) continue;

      if (_isWithinDateRange(t.timestamp, startDate, endDate)) {
        rawBreakdown[t.category] = (rawBreakdown[t.category] ?? 0.0) + t.amount;
        totalSpent += t.amount;
      }
    }

    final List<CategorySummary> summaries = [];
    rawBreakdown.forEach((category, amount) {
      final percentage = totalSpent > 0 ? (amount / totalSpent) * 100 : 0.0;
      summaries.add(CategorySummary(category, amount, percentage));
    });

    // Sort descending
    summaries.sort((a, b) => b.amount.compareTo(a.amount));
    return summaries;
  }

  List<NecessitySummary> getSpendingTypeBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final transactions = _repository.transactionsNotifier.value;
    final Map<String, double> breakdown = {
      'Necessary': 0.0,
      'Discretionary': 0.0,
      'Unclassified': 0.0,
    };
    double totalSpent = 0;

    for (final t in transactions) {
      if (t.isIncome) continue;

      if (_isWithinDateRange(t.timestamp, startDate, endDate)) {
        String type = t.spendingType ?? 'Unclassified';

        // Safety fallback mapping to prevent breaking old data if spendingType is null
        if (t.spendingType == null) {
          type = _fallbackSpendingType(t.category, isImpulse: t.isImpulse);
        }

        breakdown[type] = (breakdown[type] ?? 0.0) + t.amount;
        totalSpent += t.amount;
      }
    }

    final List<NecessitySummary> summaries = [];
    breakdown.forEach((type, amount) {
      final percentage = totalSpent > 0 ? (amount / totalSpent) * 100 : 0.0;
      summaries.add(NecessitySummary(type, amount, percentage));
    });

    return summaries;
  }

  // ---------------------------------------------------------
  // TRENDS
  // ---------------------------------------------------------

  List<SpendingTrendPoint> getSpendingTrend({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final transactions = _repository.transactionsNotifier.value;
    final Map<DateTime, double> dailyTotals = {};

    // Initialize all days in range to 0
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dailyTotals[current] = 0.0;
      current = current.add(const Duration(days: 1));
    }

    for (final t in transactions) {
      if (t.isIncome) continue;

      if (_isWithinDateRange(t.timestamp, startDate, endDate)) {
        final txDate = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
        final normalizedDate = DateTime(txDate.year, txDate.month, txDate.day);

        if (dailyTotals.containsKey(normalizedDate)) {
          dailyTotals[normalizedDate] = dailyTotals[normalizedDate]! + t.amount;
        }
      }
    }

    final List<SpendingTrendPoint> trend = [];
    dailyTotals.forEach((date, amount) {
      trend.add(SpendingTrendPoint(date, amount));
    });

    // Sort chronologically
    trend.sort((a, b) => a.date.compareTo(b.date));
    return trend;
  }

  // ---------------------------------------------------------
  // DATA QUALITY
  // ---------------------------------------------------------

  DataCoverageSummary getClassificationCoverage({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final transactions = _repository.transactionsNotifier.value;
    int total = 0;
    int classified = 0;

    for (final t in transactions) {
      if (t.isIncome) continue; // Only care about expense classification

      if (_isWithinDateRange(t.timestamp, startDate, endDate)) {
        total++;
        // If it has a legitimate DB spendingType, it's classified.
        if (t.spendingType != null && t.spendingType!.isNotEmpty) {
          classified++;
        }
      }
    }

    final coverage = total > 0 ? (classified / total) * 100 : 0.0;
    return DataCoverageSummary(
      total.toDouble(),
      classified.toDouble(),
      coverage,
    );
  }

  // ---------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------

  double _calculateTotal(
    List<TransactionModel> transactions,
    DateTime? startDate,
    DateTime? endDate, {
    required bool isIncome,
  }) {
    double total = 0.0;
    for (final t in transactions) {
      if (t.isIncome != isIncome) continue;

      if (_isWithinDateRange(t.timestamp, startDate, endDate)) {
        total += t.amount;
      }
    }
    return total;
  }

  bool _isWithinDateRange(
    int timestampEpoch,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return true;

    final date = DateTime.fromMillisecondsSinceEpoch(timestampEpoch);
    if (startDate != null && date.isBefore(startDate)) return false;

    // We treat endDate as inclusive by pushing it to 23:59:59 if it's purely a date object
    if (endDate != null) {
      final adjustedEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      if (date.isAfter(adjustedEnd)) return false;
    }

    return true;
  }

  String _fallbackSpendingType(String category, {bool isImpulse = false}) {
    if (isImpulse) return 'Discretionary';
    
    final lower = category.toLowerCase();
    if (lower.contains('groceries') ||
        lower.contains('utilities') ||
        lower.contains('rent') ||
        lower.contains('health') ||
        lower.contains('transport')) {
      return 'Necessary';
    } else if (lower.contains('entertainment') ||
        lower.contains('dining') ||
        lower.contains('food') ||
        lower.contains('shopping') ||
        lower.contains('recreation') ||
        lower.contains('impulse')) {
      return 'Discretionary';
    }
    return 'Unclassified';
  }
}
