import 'dart:io';

import 'package:flutter/material.dart';

import '../repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../transaction_parser.dart';

class ReviewScreen extends StatefulWidget {
  final String imagePath;
  final String ocrText;

  const ReviewScreen({
    super.key,
    required this.imagePath,
    required this.ocrText,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  String _selectedCategory = 'Other';
  bool _isAIProcessing = true;
  bool _isImpulse = false;

  final List<String> _categories = [
    'Groceries',
    'Food/Dining',
    'Transport',
    'Utilities',
    'Entertainment',
    'Impulse/Useless',
    'Transfer',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController();
    _amountController = TextEditingController();

    // Quick regex for amount just to have something instantly
    final amountMatch = RegExp(
      r'(?:rs\.?|inr|₹)\s?(\d+(?:,\d+)*(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(widget.ocrText);
    if (amountMatch != null) {
      _amountController.text = amountMatch.group(1)?.replaceAll(',', '') ?? '';
    }

    // Quick fallback for merchant (grab the very first line of OCR)
    final lines = widget.ocrText
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isNotEmpty && _merchantController.text.isEmpty) {
      _merchantController.text = lines.first;
    }

    _dateController = TextEditingController(
      text: DateTime.now().toString().substring(0, 16),
    );

    _runAIParsing();
  }

  Future<void> _runAIParsing() async {
    try {
      final parsedData = await TransactionParser.parseTransaction(
        widget.ocrText,
      );
      if (parsedData != null && mounted) {
        setState(() {
          if (_merchantController.text.isEmpty) {
            _merchantController.text = parsedData['merchant']?.toString() ?? '';
          }
          if (_amountController.text.isEmpty && parsedData['amount'] != null) {
            _amountController.text = parsedData['amount'].toString();
          }
          if (parsedData['date'] != null) {
            _dateController.text = parsedData['date'].toString();
          }
          final parsedCategory = parsedData['category']?.toString();
          if (parsedCategory != null && _categories.contains(parsedCategory)) {
            _selectedCategory = parsedCategory;
          }
          _isImpulse =
              parsedData['isImpulse'] == true ||
              _selectedCategory == 'Impulse/Useless';
        });
      }
    } catch (e) {
      print('AI Parsing error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAIProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Review Transaction',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Thumbnail
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // AI Indicator
            if (_isAIProcessing)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'AI is extracting details...',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),

            // Form Fields
            _buildTextField('Merchant', _merchantController),
            const SizedBox(height: 16),
            _buildTextField('Amount (?)', _amountController, isNumber: true),
            const SizedBox(height: 16),
            _buildTextField('Date', _dateController),
            const SizedBox(height: 16),

            // Category Dropdown
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCategory,
                  items: _categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      if (newValue != null) _selectedCategory = newValue;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 40),
            // Save Button
            ElevatedButton(
              onPressed: () async {
                String dateString = _dateController.text.trim();
                int parsedTimestamp = DateTime.now().millisecondsSinceEpoch;
                try {
                  parsedTimestamp = DateTime.parse(
                    dateString.replaceAll(' ', 'T'),
                  ).millisecondsSinceEpoch;
                } catch (e) {
                  // Keep current timestamp
                }

                final repo = TransactionRepository();
                final transaction = TransactionModel(
                  merchant: _merchantController.text.trim(),
                  amount: double.tryParse(_amountController.text) ?? 0.0,
                  date: dateString,
                  category: _selectedCategory,
                  isImpulse:
                      _isImpulse || _selectedCategory == 'Impulse/Useless',
                  timestamp: parsedTimestamp,
                );

                await repo.saveTransaction(transaction);

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction Saved!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E2C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E1E2C)),
            ),
          ),
        ),
      ],
    );
  }
}
