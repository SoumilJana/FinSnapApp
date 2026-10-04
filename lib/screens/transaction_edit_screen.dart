import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

class TransactionEditScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionEditScreen({super.key, required this.transaction});

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TransactionRepository _repository = TransactionRepository();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _noteController;
  late String _category;
  late bool _isImpulse;
  late bool _isIncome;

  final List<String> _categories = [
    'Groceries',
    'Food/Dining',
    'Transport',
    'Utilities',
    'Entertainment',
    'Impulse/Useless',
    'Transfer',
    'Income',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.transaction.merchant,
    );
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    String displayTime = widget.transaction.date;
    if (!displayTime.contains(':')) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        widget.transaction.timestamp,
      );
      displayTime +=
          " ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    _dateController = TextEditingController(text: displayTime);
    _noteController = TextEditingController(
      text: widget.transaction.note ?? '',
    );
    _category = _categories.contains(widget.transaction.category)
        ? widget.transaction.category
        : 'Other';
    _isImpulse = widget.transaction.isImpulse;
    _isIncome = widget.transaction.isIncome;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      String dateString = _dateController.text.trim();
      int parsedTimestamp = widget.transaction.timestamp;
      try {
        parsedTimestamp = DateTime.parse(dateString.replaceAll(' ', 'T'))
            .millisecondsSinceEpoch;
      } catch (e) {
        // keep original timestamp if invalid
      }

      final updatedTx = TransactionModel(
        id: widget.transaction.id,
        merchant: _merchantController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0.0,
        date: dateString,
        category: _category,
        isImpulse: _isImpulse,
        isIncome: _isIncome,
        isPending: false, // Explicitly clear pending state if manually edited
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        timestamp: parsedTimestamp,
      );

      await _repository.updateTransaction(updatedTx);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _deleteTransaction() async {
    if (widget.transaction.id != null) {
      await _repository.deleteTransaction(widget.transaction.id!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Edit Transaction',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Transaction'),
                  content: const Text(
                    'Are you sure you want to delete this transaction?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteTransaction();
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant/Source',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD HH:mm)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add additional context for AI analysis',
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Income?'),
                subtitle: const Text('Money received instead of spent'),
                value: _isIncome,
                onChanged: (val) => setState(() => _isIncome = val),
              ),
              SwitchListTile(
                title: const Text('Is Impulse Buy?'),
                subtitle: const Text('Flags this as an unnecessary purchase'),
                value: _isImpulse,
                onChanged: _isIncome
                    ? null
                    : (val) => setState(
                        () => _isImpulse = val,
                      ), // Disable if it's income
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF1E1E2C),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
