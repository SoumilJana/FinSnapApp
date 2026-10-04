import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_onnx_ocr/flutter_onnx_ocr.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'transaction_parser.dart';
import 'screens/main_screen.dart';
import 'screens/review_screen.dart';

import 'dart:io';

import 'repositories/transaction_repository.dart';
import 'models/transaction_model.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FlutterOnnxOcr.initialize(
      detectionModelPath: 'assets/models/ch_PP-OCRv3_det_infer.onnx',
      recognitionModelPath: 'assets/models/ch_PP-OCRv3_rec_infer.onnx',
      characterDictPath: 'assets/models/ch_ppocrv5_dict.txt',
    );
  } catch (e) {
    print("Failed to initialize OCR: $e");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinSnap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto', // Simple modern font
      ),
      home: const IntentHandlerWrapper(child: MainScreen()),
    );
  }
}

// This wrapper listens for sharing intents anywhere in the app
class IntentHandlerWrapper extends StatefulWidget {
  final Widget child;
  const IntentHandlerWrapper({super.key, required this.child});

  @override
  State<IntentHandlerWrapper> createState() => _IntentHandlerWrapperState();
}

class _IntentHandlerWrapperState extends State<IntentHandlerWrapper> {
  late StreamSubscription _intentDataStreamSubscription;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((value) {
          if (value.isNotEmpty) _handleSharedFile(value.first.path);
        });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) _handleSharedFile(value.first.path);
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _handleSharedFile(String imagePath) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. OCR Extract for quick offline details
      String text = '';
        try {
          final results = await FlutterOnnxOcr.recognizeFromFile(imagePath);
          text = results.map((e) => e.text).join('\n');
        } catch (e) {
          print("OCR Error: $e");
        }
        
        String quickMerchant = 'Processing...';
        double quickAmount = 0.0;
      print("OCR TEXT: \n" + text + "\n===END OCR===");
      List<String> lines = text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // 1. Better Amount Parsing (Handle OCR misreading '₹' as '?', 'F', etc)
      // We use \b or lookbehinds to ensure we don't accidentally match the 'r' in "September 15"
      var amountMatch = RegExp(
        r'(?:(?:^|\s)(?:rs\.?|inr|f|r|7)|₹|\?)\s?(\d+(?:,\d+)*(?:\.\d{1,2})?)',
        caseSensitive: false,
      ).firstMatch(text);
      if (amountMatch == null) {
        // Fallback: look for a line that is almost entirely just a number
        for (var line in lines) {
          var match = RegExp(r'^[^\d]*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s*$')
              .firstMatch(line);
          if (match != null) {
            double? val = double.tryParse(
              match.group(1)?.replaceAll(',', '') ?? '',
            );
            if (val != null && val < 1000000) {
              // sanity check
              amountMatch = match;
              break;
            }
          }
        }
      }

      if (amountMatch != null) {
        quickAmount =
            double.tryParse(amountMatch.group(1)?.replaceAll(',', '') ?? '0') ??
            0.0;
      }

      // 2. Better Merchant Parsing
      bool foundMerchant = false;
      for (int i = 0; i < lines.length; i++) {
        String lower = lines[i].toLowerCase();
        if (lower.startsWith("paid to") ||
            lower.startsWith("sent to") ||
            lower.startsWith("paying") ||
            lower.startsWith("to: ") ||
            lower.startsWith("to ")) {
          if (lower == "paid to" ||
              lower == "sent to" ||
              lower == "to:" ||
              lower == "to") {
            if (i + 1 < lines.length) quickMerchant = lines[i + 1];
          } else {
            quickMerchant = lines[i].replaceAll(
              RegExp(
                r'^(paid to|sent to|paying|to:\s*|to\s+)\s*',
                caseSensitive: false,
              ),
              '',
            );
          }
          foundMerchant = true;
          break;
        }
      }

      // Fallback if no keywords found
      if (!foundMerchant && lines.isNotEmpty) {
        var validLines = lines
            .where(
              (l) =>
                  !l.toLowerCase().contains("success") &&
                  !l.toLowerCase().contains("payment") &&
                  !RegExp(r'^\d').hasMatch(l), // Not starting with a number
            )
            .toList();

        if (validLines.isNotEmpty) {
          quickMerchant = validLines.first;
        } else {
          quickMerchant = lines.first;
        }
      }

      final repo = TransactionRepository();

      // We must provide an ID here so we know what to update later
      final newId = DateTime.now().millisecondsSinceEpoch.toString();

      final pendingTx = TransactionModel(
        id: newId,
        merchant: quickMerchant,
        amount: quickAmount,
        date: DateTime.now().toString().substring(0, 16),
        category: 'Other',
        isImpulse: false,
        isIncome: false,
        isPending: true,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await repo.saveTransaction(pendingTx);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved as Pending! Processing in background...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Kick off background processing
      _processImageInBackground(newId, text);

      // Removed early pop: we now pop at the end of _processImageInBackground
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processImageInBackground(String txId, String ocrText) async {
    try {
      final parsedData = await TransactionParser.parseTransaction(ocrText);
      if (parsedData != null) {
        final repo = TransactionRepository();

        String dateString =
            parsedData['date']?.toString() ??
            DateTime.now().toString().substring(0, 16);
        int parsedTimestamp = DateTime.now().millisecondsSinceEpoch;
        try {
          parsedTimestamp = DateTime.parse(dateString.replaceAll(' ', 'T'))
              .millisecondsSinceEpoch;
        } catch (e) {
          // fallback to current if parsing fails
        }
        final updatedTx = TransactionModel(
          id: txId,
          merchant: parsedData['merchant']?.toString() ?? 'Unknown',
          amount:
              double.tryParse(parsedData['amount']?.toString() ?? '0') ?? 0.0,
          date: dateString,
          category: parsedData['category']?.toString() ?? 'Other',
          isImpulse: parsedData['isImpulse'] == true,
          isIncome: parsedData['isIncome'] == true,
          isPending: false, // Done processing
          timestamp: parsedTimestamp,
        );

        await repo.updateTransaction(updatedTx);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI successfully processed receipt!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception("AI returned null data.");
      }
    } catch (e) {
      print("Background processing failed: $e");
      // Set isPending to false so the user can edit it manually without being stuck
      try {
        final repo = TransactionRepository();
        final txs = repo.transactionsNotifier.value;
        final tx = txs.firstWhere((t) => t.id == txId);
        final failedTx = TransactionModel(
          id: tx.id,
          merchant: tx.merchant,
          amount: tx.amount,
          date: tx.date,
          category: tx.category,
          isImpulse: tx.isImpulse,
          isIncome: tx.isIncome,
          isPending: false, // Turn off loading state on failure
          timestamp: tx.timestamp,
        );
        await repo.updateTransaction(failedTx);
      } catch (innerE) {
        print("Failed to reset pending state: $innerE");
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('AI Processing Failed'),
            content: const Text(
              'We could not automatically process your receipt. Please edit the pending transaction manually.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      // Automatically go back to the previous app after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        SystemNavigator.pop();
      });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1E1E2C)),
                      SizedBox(height: 16),
                      Text('Reading receipt...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
