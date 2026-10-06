import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../services/ai_chat_service.dart';
import '../services/ai_insights_engine.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  final TransactionRepository _repository = TransactionRepository();
  late AiInsightsEngine _insightsEngine;
  final AiChatService _chatService = AiChatService();
  
  bool _isReviewing = false;
  bool _isLoadingSummary = false;
  String? _smartSummary;

  @override
  void initState() {
    super.initState();
    _insightsEngine = AiInsightsEngine(_repository);
    _repository.transactionsNotifier.addListener(_onDataChanged);
    _fetchSmartSummary();
  }

  @override
  void dispose() {
    _repository.transactionsNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }
  
  Future<void> _fetchSmartSummary() async {
    if (_isLoadingSummary) return;
    setState(() => _isLoadingSummary = true);
    
    try {
      final txs = _repository.transactionsNotifier.value;
      // Get recent transactions (e.g. last 30 days) to keep context small
      final now = DateTime.now();
      final recent = txs.where((t) {
        final txDate = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
        return now.difference(txDate).inDays <= 30;
      }).toList();
      
      final summary = await _chatService.generateSmartSummary(recent);
      if (mounted) {
        setState(() {
          _smartSummary = summary;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _smartSummary = "Unable to generate insights at this time.";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSummary = false);
      }
    }
  }

  void _showRejectDialog(BuildContext context, TransactionModel tx) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Suggestion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you rejecting this? (Optional)\nThis feedback helps the AI learn your rules for future audits.'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Lassi is a drink, not useless...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _repository.rejectSuggestion(tx, reasonController.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E2C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runAudit() async {
    setState(() => _isReviewing = true);
    try {
      final count = await _repository.runTransactionAudit();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Audited $count transactions.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('AI review failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isReviewing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = _repository.transactionsNotifier.value;

    final needsAuditCount = allTransactions
        .where(
          (t) =>
              t.note != null &&
              t.note!.trim().isNotEmpty &&
              t.aiReclassificationReason == null &&
              !t.isIncome,
        )
        .length;

    final pendingSuggestions = allTransactions
        .where((t) => t.aiSuggestedCategory != null)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'AI Insights',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E1E2C),
        centerTitle: false,
      ),
      body: _isReviewing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1E1E2C)),
                  SizedBox(height: 16),
                  Text(
                    'Reviewing transactions...',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
              children: [
                _buildSmartSummaryCard(),
                const SizedBox(height: 20),
                _buildMetricsRow(),
                const SizedBox(height: 20),
                _buildAnomaliesSection(),
                const SizedBox(height: 32),
                
                if (needsAuditCount > 0 || pendingSuggestions.isNotEmpty) ...[
                  const Divider(height: 32),
                  const Text(
                    'Data Quality / Action Needed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (needsAuditCount > 0) _buildAuditCard(needsAuditCount),
                  if (needsAuditCount > 0 && pendingSuggestions.isNotEmpty) const SizedBox(height: 24),
                  ...pendingSuggestions.map((tx) => _buildSuggestionCard(tx)),
                ],
              ],
            ),
    );
  }

  Widget _buildSmartSummaryCard() {
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
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    'Smart Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                onPressed: () { HapticFeedback.lightImpact(); _fetchSmartSummary(); },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingSummary)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
            )
          else
            Text(
              _smartSummary ?? 'Analyze your transactions to get AI-powered insights here.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final burnRate = _insightsEngine.getBurnRateForecast();
    final impulse = _insightsEngine.getMonthlyImpulseSpending();
    final budget = _repository.monthlyBudgetNotifier.value;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Forecasted Spend',
            value: '₹${burnRate.toStringAsFixed(0)}',
            subtitle: 'End of month estimate',
            icon: Icons.trending_up,
            iconColor: burnRate > budget ? Colors.redAccent : Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Impulse Buying',
            value: '₹${impulse.toStringAsFixed(0)}',
            subtitle: 'This month',
            icon: Icons.shopping_bag_outlined,
            iconColor: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2C)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesSection() {
    final anomalies = _insightsEngine.getCategoryAnomalies();
    
    if (anomalies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending Anomalies',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...anomalies.map((anomaly) {
          final isNew = anomaly.percentageIncrease == 999;
          final pctString = isNew ? 'NEW' : '+${anomaly.percentageIncrease.toStringAsFixed(0)}%';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anomaly.category,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${anomaly.currentSpend.toStringAsFixed(0)} this month',
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pctString,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAuditCard(int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rule,
                color: Colors.indigo.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Transaction Auditor',
                  style: TextStyle(
                    color: Colors.indigo.shade900,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You have $count transactions with notes that haven\'t been reviewed by AI yet.',
            style: TextStyle(
              color: Colors.indigo.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { HapticFeedback.lightImpact(); _runAudit(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Review Transactions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(TransactionModel tx) {
    String subcategory = '';
    String reason = '';
    String confidenceStr = '';

    if (tx.aiReclassificationReason != null &&
        tx.aiReclassificationReason!.startsWith('{')) {
      try {
        final parsed = jsonDecode(tx.aiReclassificationReason!);
        subcategory = parsed['suggestedSubcategory'] ?? '';
        reason = parsed['reason'] ?? '';

        if (parsed['confidence'] != null) {
          final conf = (parsed['confidence'] as num).toDouble() * 100;
          confidenceStr = '${conf.toStringAsFixed(0)}%';
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Category Change',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigoAccent,
                ),
              ),
              if (confidenceStr.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$confidenceStr Confidence',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.merchant,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${tx.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.category,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.black26,
                  size: 20,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Suggested',
                        style: TextStyle(fontSize: 12, color: Colors.black45),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx.aiSuggestedCategory ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigoAccent,
                        ),
                      ),
                      if (subcategory.isNotEmpty)
                        Text(
                          subcategory,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.indigo,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Reason',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reason,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () { HapticFeedback.lightImpact(); _showRejectDialog(context, tx); },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black54,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () { HapticFeedback.lightImpact(); _repository.acceptSuggestion(tx); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E2C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

