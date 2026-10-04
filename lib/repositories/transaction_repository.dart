import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';
import '../services/local_db_service.dart';
import '../services/cloud_db_service.dart';
import '../transaction_parser.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';

class TransactionRepository {
  final LocalDbService _localDb = LocalDbService.instance;
  final CloudDbService _cloudDb = CloudDbService();
  final Uuid _uuid = const Uuid(); // We need to add uuid to pubspec.yaml

  // A notifier that the UI can listen to for updates
  final ValueNotifier<List<TransactionModel>> transactionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<double> initialBalanceNotifier = ValueNotifier(10000.0);
  final ValueNotifier<double> monthlyBudgetNotifier = ValueNotifier(10000.0);

  // Singleton pattern for the repository so we share the notifier
  static final TransactionRepository _instance =
      TransactionRepository._internal();
  factory TransactionRepository() => _instance;
  TransactionRepository._internal() {
    _loadInitialBalance();
  }

  Future<void> _loadInitialBalance() async {
    final prefs = await SharedPreferences.getInstance();
    initialBalanceNotifier.value = prefs.getDouble('initialBalance') ?? 10000.0;
    monthlyBudgetNotifier.value = prefs.getDouble('monthlyBudget') ?? 10000.0;
  }

  Future<void> setInitialBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('initialBalance', balance);
    initialBalanceNotifier.value = balance;
    await loadTransactions();
  }

  Future<void> setMonthlyBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', budget);
    monthlyBudgetNotifier.value = budget;
    // Don't need to reload transactions, just update UI
  }

  // Fetch transactions: prefers local database for speed and offline availability.
  Future<void> loadTransactions() async {
    final transactions = await _localDb.getAllTransactions();

    transactions.sort((a, b) {
      int timeA = a.timestamp;
      int timeB = b.timestamp;

      try {
        timeA = DateTime.parse(a.date.replaceAll(' ', 'T'))
            .millisecondsSinceEpoch;
      } catch (_) {}

      try {
        timeB = DateTime.parse(b.date.replaceAll(' ', 'T'))
            .millisecondsSinceEpoch;
      } catch (_) {}

      return timeB.compareTo(timeA);
    });

    transactionsNotifier.value = transactions;

    // Update Home Widget
    double totalSpent = 0;
    double totalIncome = 0;
    
    double dailyIncome = 0;
    double dailyExpense = 0;
    double monthlySpent = 0;

    final now = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(now);
    final currentMonth = now.month;
    final currentYear = now.year;

    for (var tx in transactions) {
      bool isThisMonth = false;
      try {
        final txDate = DateTime.parse(tx.date.replaceAll(' ', 'T'));
        if (txDate.month == currentMonth && txDate.year == currentYear) {
          isThisMonth = true;
        }
      } catch (_) {}

      if (tx.isIncome) {
        totalIncome += tx.amount;
        if (tx.date.startsWith(todayString)) dailyIncome += tx.amount;
      } else {
        totalSpent += tx.amount;
        if (tx.date.startsWith(todayString)) dailyExpense += tx.amount;
        if (isThisMonth) monthlySpent += tx.amount;
      }
    }

    final availableBalance = initialBalanceNotifier.value + totalIncome - totalSpent;
    final budgetLeft = monthlyBudgetNotifier.value - monthlySpent;
    
    final formatter = NumberFormat('#,##0');
    
    int budgetProgress = 0;
    if (monthlyBudgetNotifier.value > 0) {
      budgetProgress = ((monthlySpent / monthlyBudgetNotifier.value) * 100).toInt();
      if (budgetProgress > 100) budgetProgress = 100;
    }

    try {
      // Data for Main Widget (Daily/Balance)
      await HomeWidget.saveWidgetData<String>('availableBalance', '₹${availableBalance.toStringAsFixed(0)}');
      await HomeWidget.saveWidgetData<String>('dailyIncome', '+₹${dailyIncome.toStringAsFixed(0)}');
      await HomeWidget.saveWidgetData<String>('dailyExpense', '-₹${dailyExpense.toStringAsFixed(0)}');
      
      // Data for New Pill Widget (Monthly)
      await HomeWidget.saveWidgetData<String>('budgetLeft', formatter.format(budgetLeft.abs()));
      await HomeWidget.saveWidgetData<String>('monthlySpent', formatter.format(monthlySpent));
      await HomeWidget.saveWidgetData<String>('budgetLeftLabel', budgetLeft >= 0 ? 'left' : 'over');
      await HomeWidget.saveWidgetData<int>('budgetProgress', budgetProgress);
      
      // Update both widgets (we'll map the new one in Android soon)
      await HomeWidget.updateWidget(androidName: 'FinancialWidgetProvider');
      await HomeWidget.updateWidget(androidName: 'MonthlyWidgetProvider');
    } catch (e) {
      print("Failed to update home widget: $e");
    }
  }

  // Save transaction to local cache first, then asynchronously to the cloud.
  Future<void> saveTransaction(TransactionModel transaction) async {
    // Generate an ID if it doesn't exist
    final String id = transaction.id ?? _uuid.v4();

    final newTransaction = TransactionModel(
      id: id,
      merchant: transaction.merchant,
      amount: transaction.amount,
      date: transaction.date,
      category: transaction.category,
      isImpulse: transaction.isImpulse,
      isIncome: transaction.isIncome,
      isPending: transaction.isPending,
      note: transaction.note,
      timestamp: transaction.timestamp,
    );

    // Save locally
    await _localDb.insert(newTransaction);

    // Attempt to sync to cloud (fire and forget for now)
    _cloudDb.saveTransaction(newTransaction);

    // Update the UI state
    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _localDb.update(transaction);
    _cloudDb.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    if (id == "ALL") {
      await _localDb.clearAll();
      // Not clearing cloud to be safe, or you can wipe it from Firebase console
    } else {
      await _localDb.delete(id);
      _cloudDb.deleteTransaction(id);
    }
    await loadTransactions();
  }

  Future<void> wipeAllData() async {
    await _localDb.clearAll();
    await _cloudDb.clearAll();
    await loadTransactions();
  }

  Future<int> runTransactionAudit() async {
    final all = transactionsNotifier.value;
    final needsAudit = all
        .where(
          (t) =>
              t.aiReclassificationReason == null &&
              !t.isIncome &&
              ((t.note != null && t.note!.trim().isNotEmpty) ||
                  t.spendingType == 'Unclassified' ||
                  t.spendingType == null),
        )
        .take(10)
        .toList();

    if (needsAudit.isEmpty) return 0;

    final pastRejections = all
        .where((t) => t.aiReclassificationReason != null && t.aiReclassificationReason!.startsWith('REJECTED: '))
        .take(15) // Use the last 15 rejections to build learning context
        .toList();
    
    String feedbackContext = "";
    if (pastRejections.isNotEmpty) {
      feedbackContext = "\nLEARN FROM PAST MISTAKES - The user has explicitly rejected some of your previous suggestions. Follow their rules implicitly:\n";
      for (var t in pastRejections) {
        String rule = t.aiReclassificationReason!.substring(10).trim();
        feedbackContext += "- For a transaction to '${t.merchant}' (${t.category}), User said: \"$rule\"\n";
      }
    }

    final jsonPayload = needsAudit
        .map(
          (t) => {
            'id': t.id,
            'merchant': t.merchant,
            'amount': t.amount,
            'category': t.category,
            'note': t.note,
          },
        )
        .toList();

    try {
      final results = await TransactionParser.auditTransactions(jsonPayload, feedbackContext: feedbackContext);

      int auditedCount = 0;
      for (final res in results) {
        final txId = res['id'];
        final tx = all.firstWhere((t) => t.id == txId);

        final shouldSuggest = res['shouldSuggestChange'] == true;

        TransactionModel updated;
        if (shouldSuggest) {
          updated = TransactionModel(
            id: tx.id,
            merchant: tx.merchant,
            amount: tx.amount,
            date: tx.date,
            category: tx.category, // Keep original
            isImpulse: tx.isImpulse,
            isIncome: tx.isIncome,
            isPending: tx.isPending,
            note: tx.note,
            timestamp: tx.timestamp,
            subcategory: tx.subcategory,
            intent: tx.intent,
            necessity: tx.necessity,
            spendingType: tx.spendingType,
            aiSuggestedCategory: res['suggestedCategory'] ?? tx.category,
            aiReclassificationReason: jsonEncode({
              'suggestedSubcategory': res['suggestedSubcategory'],
              'confidence': res['confidence'],
              'reason': res['reason'],
            }),
          );
        } else {
          updated = TransactionModel(
            id: tx.id,
            merchant: tx.merchant,
            amount: tx.amount,
            date: tx.date,
            category: tx.category,
            isImpulse: tx.isImpulse,
            isIncome: tx.isIncome,
            isPending: tx.isPending,
            note: tx.note,
            timestamp: tx.timestamp,
            subcategory: tx.subcategory,
            intent: tx.intent,
            necessity: tx.necessity,
            spendingType: tx.spendingType,
            aiSuggestedCategory: null,
            aiReclassificationReason: 'NO_CHANGE',
          );
        }

        await _localDb.update(updated);
        _cloudDb.updateTransaction(updated);
        auditedCount++;
      }

      await loadTransactions();
      return auditedCount;
    } catch (e) {
      print('Audit failed: $e');
      throw e;
    }
  }

  Future<void> acceptSuggestion(TransactionModel tx) async {
    String? subcategory = tx.subcategory;
    try {
      if (tx.aiReclassificationReason != null &&
          tx.aiReclassificationReason!.startsWith('{')) {
        final parsed = jsonDecode(tx.aiReclassificationReason!);
        subcategory = parsed['suggestedSubcategory'] ?? tx.subcategory;
      }
    } catch (_) {}

    final updated = TransactionModel(
      id: tx.id,
      merchant: tx.merchant,
      amount: tx.amount,
      date: tx.date,
      category: tx.aiSuggestedCategory ?? tx.category,
      isImpulse: tx.isImpulse,
      isIncome: tx.isIncome,
      isPending: tx.isPending,
      note: tx.note,
      timestamp: tx.timestamp,
      subcategory: subcategory,
      intent: tx.intent,
      necessity: tx.necessity,
      spendingType: tx.spendingType,
      aiSuggestedCategory: null,
      aiReclassificationReason: 'ACCEPTED',
    );
    await updateTransaction(updated);
  }

  Future<void> rejectSuggestion(TransactionModel tx, [String? reason]) async {
    final updated = TransactionModel(
      id: tx.id,
      merchant: tx.merchant,
      amount: tx.amount,
      date: tx.date,
      category: tx.category,
      isImpulse: tx.isImpulse,
      isIncome: tx.isIncome,
      isPending: tx.isPending,
      note: tx.note,
      timestamp: tx.timestamp,
      subcategory: tx.subcategory,
      intent: tx.intent,
      necessity: tx.necessity,
      spendingType: tx.spendingType,
      aiSuggestedCategory: null,
      aiReclassificationReason: reason != null && reason.trim().isNotEmpty 
          ? 'REJECTED: ${reason.trim()}' 
          : 'REJECTED',
    );
    await updateTransaction(updated);
  }
}
