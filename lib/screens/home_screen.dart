import 'dart:io';
import '../services/update_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../repositories/transaction_repository.dart';
import 'border_progress_painter.dart';
import '../models/transaction_model.dart';
import '../transaction_parser.dart';
import 'transaction_edit_screen.dart';
import 'analytics_screen.dart';
import '../services/ai_insights_engine.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionRepository _repository = TransactionRepository();
  late final AiInsightsEngine _insightsEngine = AiInsightsEngine(_repository);
  String? _loadingMessage;

  @override
  void initState() {
    super.initState();
    _repository.loadTransactions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  Future<void> _importPdf() async {
    List<PlatformFile>? files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } catch (e) {
      print("File picker error: $e");
    }

    if (files != null && files.isNotEmpty && files.first.path != null) {
      setState(() {
        _loadingMessage = 'Reading PDF (This may take a while)...';
      });

      try {
        File pdfFile = File(files.first.path!);
        List<Map<String, dynamic>> parsedTransactions =
            await TransactionParser.parseBankStatement(pdfFile);

        for (var txData in parsedTransactions) {
          String dateString =
              txData['date']?.toString() ??
              DateTime.now().toString().substring(0, 16);
          int parsedTimestamp = DateTime.now().millisecondsSinceEpoch;
          try {
            parsedTimestamp = DateTime.parse(dateString.replaceAll(' ', 'T'))
                .millisecondsSinceEpoch;
          } catch (e) {
            // fallback to current if parsing fails
          }
          final tx = TransactionModel(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                txData.hashCode.toString(),
            merchant: txData['merchant']?.toString() ?? 'Unknown',
            amount: double.tryParse(txData['amount']?.toString() ?? '0') ?? 0.0,
            date: dateString,
            category: txData['category']?.toString() ?? 'Other',
            isImpulse: txData['isImpulse'] == true,
            isIncome: txData['isIncome'] == true,
            timestamp: parsedTimestamp,
          );
          await _repository.saveTransaction(tx);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imported ${parsedTransactions.length} transactions!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error importing PDF: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _loadingMessage = null;
          });
        }
      }
    }
  }

  Future<void> _editInitialBalance(BuildContext context) async {
    double totalSpent = 0;
    double totalIncome = 0;
    for (var tx in _repository.transactionsNotifier.value) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalSpent += tx.amount;
      }
    }

    double currentBalance =
        _repository.initialBalanceNotifier.value + totalIncome - totalSpent;

    final TextEditingController controller = TextEditingController(
      text: currentBalance.toStringAsFixed(0),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Available Balance'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Current Bank Balance',
              prefixText: '₹',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? parsed = double.tryParse(controller.text);
                if (parsed != null) {
                  final newInitialBalance = parsed - totalIncome + totalSpent;
                  _repository.setInitialBalance(newInitialBalance);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showCloudWipeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Full Cloud Wipe'),
          content: const Text(
            'This will delete all transactions from your local device AND the cloud server. Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close first dialog
                _showFinalCloudWipeConfirmation(context); // Show second dialog
              },
              child: const Text(
                'Yes, continue',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFinalCloudWipeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Final Warning',
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            'Are you REALLY sure you want to delete everything everywhere? This action cannot be undone!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog

                setState(
                  () => _loadingMessage =
                      'Wiping all data from local device and cloud...',
                );

                try {
                  // Add a timeout to the cloud wipe to prevent hanging if offline
                  await _repository.wipeAllData().timeout(
                    const Duration(seconds: 15),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'All local and cloud data has been permanently wiped.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Wipe finished with an error or timeout: $e',
                        ),
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _loadingMessage = null);
                  }
                }
              },
              child: const Text(
                'WIPE EVERYTHING',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Groceries':
        return Icons.shopping_bag_outlined;
      case 'Food/Dining':
        return Icons.restaurant_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Utilities':
        return Icons.bolt_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      case 'Transfer':
        return Icons.swap_horiz_outlined;
      case 'Income':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'FinSnap',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.cleaning_services_outlined,
              color: Colors.black54,
            ),
            tooltip: 'Clear Local Data',
            onPressed: () async {
              await _repository.deleteTransaction("ALL");
              await _repository.loadTransactions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local Database Cleared!')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
            ),
            tooltip: 'Full Cloud Wipe',
            onPressed: () => _showCloudWipeConfirmation(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ValueListenableBuilder<List<TransactionModel>>(
              valueListenable: _repository.transactionsNotifier,
              builder: (context, transactions, child) {
                // Calculate totals
                double totalSpentAllTime = 0;
                double totalIncomeAllTime = 0;
                
                double spentThisMonth = 0;
                double incomeThisMonth = 0;
                double impulseThisMonth = 0;

                double spentToday = 0;
                double incomeToday = 0;

                final now = DateTime.now();
                final todayString = now.toString().split(' ')[0];
                final currentMonth = now.month;
                final currentYear = now.year;

                for (var tx in transactions) {
                  bool isThisMonth = false;
                  try {
                    final txDate = DateTime.parse(tx.date.replaceAll(' ', 'T'));
                    if (txDate.month == currentMonth && txDate.year == currentYear) {
                      isThisMonth = true;
                    }
                  } catch (e) {
                    // Fallback if parsing fails
                    if (tx.date.startsWith('${currentYear}-${currentMonth.toString().padLeft(2, '0')}')) {
                      isThisMonth = true;
                    }
                  }

                  if (tx.isIncome) {
                    totalIncomeAllTime += tx.amount;
                    if (isThisMonth) incomeThisMonth += tx.amount;
                    if (tx.date.startsWith(todayString)) incomeToday += tx.amount;
                  } else {
                    totalSpentAllTime += tx.amount;
                    if (isThisMonth) {
                      spentThisMonth += tx.amount;
                      if (tx.isImpulse) impulseThisMonth += tx.amount;
                    }
                    if (tx.date.startsWith(todayString)) spentToday += tx.amount;
                  }
                }

                return ValueListenableBuilder<double>(
                  valueListenable: _repository.initialBalanceNotifier,
                  builder: (context, initialBalance, child) {
                    final remainingBudget =
                        initialBalance + totalIncomeAllTime - totalSpentAllTime;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // Budget Card
                          GestureDetector(
                            onTap: () => _editInitialBalance(context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1E1E2C,
                                ), // Deep minimal dark color
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available Balance (Tap to Edit)',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${remainingBudget.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      _buildMiniStat(
                                        'Daily Income',
                                        '+₹${incomeToday.toStringAsFixed(0)}',
                                        color: Colors.greenAccent,
                                      ),
                                      const SizedBox(width: 40),
                                      _buildMiniStat(
                                        'Daily Expense',
                                        '-₹${spentToday.toStringAsFixed(0)}',
                                        color: Colors.redAccent,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _importPdf,
                                icon: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Import PDF',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF1E1E2C),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xFF1E1E2C)
                                      .withOpacity(0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Dynamic list
                          Expanded(
                            child: ShaderMask(
                              shaderCallback: (Rect rect) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black,
                                    Colors.black,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.05, 0.85, 1.0],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstIn,
                              child: transactions.isEmpty
                                  ? RefreshIndicator(
                                      onRefresh: () async {
                                        await _repository.loadTransactions();
                                      },
                                      child: LayoutBuilder(
                                        builder: (context, constraints) => SingleChildScrollView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                            child: const Center(
                                              child: Text(
                                                'No transactions yet.\nShare a payment screenshot to start!',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.black54),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: () async {
                                        await _repository.loadTransactions();
                                      },
                                      child: ListView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                          bottom: 100.0,
                                        ), // Padding to clear floating nav bar
                                        children: _buildTransactionList(transactions),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_loadingMessage != null)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF1E1E2C),
                        ),
                        const SizedBox(height: 16),
                        Text(_loadingMessage!),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionList(List<TransactionModel> transactions) {
    final sortedTransactions = List<TransactionModel>.from(transactions);
    sortedTransactions.sort((a, b) {
      DateTime dateA;
      try {
        dateA = DateTime.parse(a.date.replaceAll(' ', 'T'));
      } catch (e) {
        dateA = DateTime.fromMillisecondsSinceEpoch(a.timestamp);
      }
      DateTime dateB;
      try {
        dateB = DateTime.parse(b.date.replaceAll(' ', 'T'));
      } catch (e) {
        dateB = DateTime.fromMillisecondsSinceEpoch(b.timestamp);
      }
      return dateB.compareTo(dateA);
    });

    Map<String, double> monthlySpent = {};
    for (var tx in sortedTransactions) {
      if (!tx.isIncome) {
        DateTime date;
        try {
          date = DateTime.parse(tx.date.replaceAll(' ', 'T'));
        } catch (e) {
          date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
        }
        final monthLabel = "${DateFormat('MMMM').format(date)} '${DateFormat('yy').format(date)}";
        monthlySpent[monthLabel] = (monthlySpent[monthLabel] ?? 0) + tx.amount;
      }
    }

    final listItems = <Widget>[];
    String? currentMonth;

    for (var tx in sortedTransactions) {
      DateTime date;
      try {
        date = DateTime.parse(tx.date.replaceAll(' ', 'T'));
      } catch (e) {
        date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
      }
      final monthLabel = "${DateFormat('MMMM').format(date)} '${DateFormat('yy').format(date)}";

      if (currentMonth != monthLabel) {
        currentMonth = monthLabel;
        final spentThisMonth = monthlySpent[monthLabel] ?? 0.0;
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0, left: 4.0, right: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E2C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You have spent ₹${spentThisMonth.toStringAsFixed(2)} in this month",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_outward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final isIncome = tx.isIncome;
      final amountString = isIncome
          ? '+₹${tx.amount.toStringAsFixed(2)}'
          : '-₹${tx.amount.toStringAsFixed(2)}';

      String displayTime = "";
      final timeFormat = DateFormat('h:mm a');
      displayTime = "${DateFormat('d MMM').format(date)} • ${timeFormat.format(date)}";

      listItems.add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionEditScreen(transaction: tx),
              ),
            );
          },
          child: _buildTransactionTile(
            tx.isPending ? 'Processing...' : tx.merchant,
            tx.isPending ? 'AI is analyzing screenshot...' : tx.category,
            amountString,
            displayTime,
            tx.isPending ? Icons.hourglass_bottom_outlined : _getCategoryIcon(tx.category),
            isIncome: isIncome,
            isPending: tx.isPending,
          ),
        ),
      );
    }
    return listItems;
  }

  Widget _buildMiniStat(
    String label,
    String amount, {
    Color color = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
    String title,
    String subtitle,
    String amount,
    String time,
    IconData icon, {
    bool isIncome = false,
    bool isPending = false,
  }) {
    Widget content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPending
            ? null // handled by custom painter
            : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: isPending
            ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPending
                  ? Colors.blue.withValues(alpha: 0.1)
                  : const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isPending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: const Color(0xFF1E1E2C), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isPending ? Colors.blue : Colors.black54,
                    fontSize: 13,
                    fontStyle: isPending ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPending
                      ? Colors.black38
                      : (isIncome ? Colors.green : Colors.black87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.black38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
        if (isPending) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 10), // Estimated processing time
            builder: (context, value, child) {
              return CustomPaint(
                painter: BorderProgressPainter(progress: value, color: Colors.blue, strokeWidth: 3.0),
                child: child,
              );
            },
            child: content,
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: content,
      );
    }
  }

