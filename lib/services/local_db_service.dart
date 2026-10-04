import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/transaction_model.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  static Database? _database;

  LocalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finsnap.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textTypeNull = 'TEXT';

    await db.execute('''
CREATE TABLE transactions (
  id $textTypeNull,
  merchant $textType,
  amount $realType,
  date $textType,
  category $textType,
  isImpulse $intType,
  isIncome $intType DEFAULT 0,
  isPending $intType DEFAULT 0,
  note $textTypeNull,
  timestamp $intType,
  subcategory $textTypeNull,
  intent $textTypeNull,
  necessity $textTypeNull,
  spendingType $textTypeNull,
  aiSuggestedCategory $textTypeNull,
  aiReclassificationReason $textTypeNull
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN isIncome INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN isPending INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE transactions ADD COLUMN note TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE transactions ADD COLUMN subcategory TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN intent TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN necessity TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN spendingType TEXT');
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN aiSuggestedCategory TEXT',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN aiReclassificationReason TEXT',
      );
    }
  }

  Future<void> insert(TransactionModel transaction) async {
    final db = await instance.database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final orderBy = 'timestamp DESC';
    final result = await db.query('transactions', orderBy: orderBy);

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<void> update(TransactionModel transaction) async {
    final db = await instance.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('transactions');
  }
}
