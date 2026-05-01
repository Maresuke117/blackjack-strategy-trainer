import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 収支履歴のデータモデル。
class BalanceHistory {
  final int? id;
  final int balance;
  final String mode;
  final DateTime createdAt;

  BalanceHistory({
    this.id,
    required this.balance,
    required this.mode,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'balance': balance,
      'played_mode': mode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BalanceHistory.fromMap(Map<String, dynamic> map) {
    return BalanceHistory(
      id: map['id'],
      balance: map['balance'],
      mode: map['played_mode'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

/// 収支履歴をデータベースで管理するNotifier。
class BalanceHistoryNotifier extends StateNotifier<List<BalanceHistory>> {
  Database? _database;

  BalanceHistoryNotifier() : super([]) {
    _initDb();
  }

  Future<void> _initDb() async {
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, 'blackjack_stats.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE balance_history(id INTEGER PRIMARY KEY AUTOINCREMENT, balance INTEGER, played_mode TEXT, created_at TEXT)',
        );
      },
      version: 1,
    );
    loadHistory();
  }

  /// 履歴を読み込む（最新の100件など）。
  Future<void> loadHistory() async {
    if (_database == null) return;
    final List<Map<String, dynamic>> maps = await _database!.query(
      'balance_history',
      orderBy: 'id ASC',
      limit: 100,
    );
    state = List.generate(maps.length, (i) => BalanceHistory.fromMap(maps[i]));
  }

  /// 新しい履歴を追加する。
  Future<void> addRecord(int balance, String mode) async {
    if (_database == null) await _initDb();
    final record = BalanceHistory(
      balance: balance,
      mode: mode,
      createdAt: DateTime.now(),
    );
    await _database!.insert('balance_history', record.toMap());
    await loadHistory();
  }

  /// 全ての履歴を削除する。
  Future<void> clearHistory() async {
    if (_database == null) return;
    await _database!.delete('balance_history');
    state = [];
  }
}

/// BalanceHistoryNotifier を提供するプロバイダー。
final balanceHistoryProvider =
    StateNotifierProvider<BalanceHistoryNotifier, List<BalanceHistory>>((ref) {
      return BalanceHistoryNotifier();
    });
