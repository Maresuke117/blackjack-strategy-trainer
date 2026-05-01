import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../logic/betting_system.dart';
import '../logic/localization.dart';

/// ユーザーの設定情報を保持するクラス。
class UserSettings {
  final int balance;
  final int baseBet;
  final int betUnit;
  final BettingStrategy strategy;
  final bool isSoftHandMode;
  final bool isTotalVisible;
  final AppLanguage language;
  final int maxBet;

  final List<int> balanceHistory;
  final List<bool> accuracyHistory; // 正解率の推移用
  final Map<BettingStrategy, StrategyStats> strategyStats; // 戦略ごとの勝敗

  UserSettings({
    required this.balance,
    required this.baseBet,
    required this.betUnit,
    required this.strategy,
    required this.isSoftHandMode,
    required this.isTotalVisible,
    required this.language,
    required this.maxBet,
    required this.balanceHistory,
    required this.accuracyHistory,
    required this.strategyStats,
  });

  UserSettings copyWith({
    int? balance,
    int? baseBet,
    int? betUnit,
    BettingStrategy? strategy,
    bool? isSoftHandMode,
    bool? isTotalVisible,
    AppLanguage? language,
    int? maxBet,
    List<int>? balanceHistory,
    List<bool>? accuracyHistory,
    Map<BettingStrategy, StrategyStats>? strategyStats,
  }) {
    return UserSettings(
      balance: balance ?? this.balance,
      baseBet: baseBet ?? this.baseBet,
      betUnit: betUnit ?? this.betUnit,
      strategy: strategy ?? this.strategy,
      isSoftHandMode: isSoftHandMode ?? this.isSoftHandMode,
      isTotalVisible: isTotalVisible ?? this.isTotalVisible,
      language: language ?? this.language,
      maxBet: maxBet ?? this.maxBet,
      balanceHistory: balanceHistory ?? this.balanceHistory,
      accuracyHistory: accuracyHistory ?? this.accuracyHistory,
      strategyStats: strategyStats ?? this.strategyStats,
    );
  }
}

/// 戦略ごとの統計データ
class StrategyStats {
  final int games;
  final int wins;
  final int losses;
  final int pushes;

  StrategyStats({
    this.games = 0,
    this.wins = 0,
    this.losses = 0,
    this.pushes = 0,
  });

  StrategyStats copyWith({int? games, int? wins, int? losses, int? pushes}) {
    return StrategyStats(
      games: games ?? this.games,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      pushes: pushes ?? this.pushes,
    );
  }

  Map<String, dynamic> toJson() => {
    'games': games,
    'wins': wins,
    'losses': losses,
    'pushes': pushes,
  };

  factory StrategyStats.fromJson(Map<String, dynamic> json) => StrategyStats(
    games: json['games'] ?? 0,
    wins: json['wins'] ?? 0,
    losses: json['losses'] ?? 0,
    pushes: json['pushes'] ?? 0,
  );
}

/// 設定値を管理し、永続化を行うNotifier。
class SettingsNotifier extends StateNotifier<UserSettings> {
  static const String _keyBalance = 'balance';
  static const String _keyBaseBet = 'base_bet';
  static const String _keyBetUnit = 'bet_unit';
  static const String _keyStrategy = 'strategy';
  static const String _keySoftHand = 'is_soft_hand';
  static const String _keyTotalVisible = 'is_total_visible';
  static const String _keyLanguage = 'language';
  static const String _keyMaxBet = 'max_bet';
  static const String _keyBalanceHistory = 'balance_history';
  static const String _keyAccuracyHistory = 'accuracy_history';
  static const String _keyStrategyStats = 'strategy_stats';

  SettingsNotifier()
    : super(
        UserSettings(
          balance: 1000,
          baseBet: 30,
          betUnit: 10,
          strategy: BettingStrategy.flat,
          isSoftHandMode: false,
          isTotalVisible: true,
          language: AppLanguage.en,
          maxBet: 500,
          balanceHistory: [1000],
          accuracyHistory: [],
          strategyStats: {
            for (var s in BettingStrategy.values) s: StrategyStats(),
          },
        ),
      ) {
    _loadSettings();
  }

  /// SharedPreferences から設定を読み込む。
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final historyRaw = prefs.getStringList(_keyBalanceHistory) ?? [];
    final history = historyRaw.map((e) => int.parse(e)).toList();
    if (history.isEmpty) history.add(1000);

    final accRaw = prefs.getStringList(_keyAccuracyHistory) ?? [];
    final accuracy = accRaw.map((e) => e == 'true').toList();

    final statsRaw = prefs.getString(_keyStrategyStats);
    Map<BettingStrategy, StrategyStats> stats = {
      for (var s in BettingStrategy.values) s: StrategyStats(),
    };
    if (statsRaw != null) {
      final Map<String, dynamic> decoded = jsonDecode(statsRaw);
      decoded.forEach((key, value) {
        final strategy = BettingStrategy.values.firstWhere(
          (s) => s.toString() == key,
          orElse: () => BettingStrategy.flat,
        );
        stats[strategy] = StrategyStats.fromJson(value);
      });
    }

    state = UserSettings(
      balance: prefs.getInt(_keyBalance) ?? 1000,
      baseBet: prefs.getInt(_keyBaseBet) ?? 30,
      betUnit: prefs.getInt(_keyBetUnit) ?? 10,
      strategy: BettingStrategy.values[prefs.getInt(_keyStrategy) ?? 0],
      isSoftHandMode: prefs.getBool(_keySoftHand) ?? false,
      isTotalVisible: prefs.getBool(_keyTotalVisible) ?? true,
      language: AppLanguage.values[prefs.getInt(_keyLanguage) ?? 0],
      maxBet: prefs.getInt(_keyMaxBet) ?? 500,
      balanceHistory: history,
      accuracyHistory: accuracy,
      strategyStats: stats,
    );
  }

  /// 所持金を更新し、永続化する。
  Future<void> updateBalance(int newBalance) async {
    state = state.copyWith(balance: newBalance);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBalance, newBalance);
  }

  /// ベース賭け金を更新する。
  Future<void> updateBaseBet(int amount) async {
    state = state.copyWith(baseBet: amount);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBaseBet, amount);
  }

  /// ベット単位を更新する。
  Future<void> updateBetUnit(int amount) async {
    state = state.copyWith(betUnit: amount);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBetUnit, amount);
  }

  /// ベット戦略を更新する。
  Future<void> updateStrategy(BettingStrategy strategy) async {
    state = state.copyWith(strategy: strategy);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStrategy, strategy.index);
  }

  /// ソフトハンドモードを切り替える。
  Future<void> toggleSoftHandMode(bool value) async {
    state = state.copyWith(isSoftHandMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoftHand, value);
  }

  /// 合計値表示を切り替える。
  Future<void> toggleTotalVisible(bool value) async {
    state = state.copyWith(isTotalVisible: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTotalVisible, value);
  }

  /// 言語を更新する。
  Future<void> updateLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLanguage, language.index);
  }

  /// マックスベットを更新する。
  Future<void> updateMaxBet(int amount) async {
    state = state.copyWith(maxBet: amount);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxBet, amount);
  }

  /// 現在の所持金を履歴に追加する。
  Future<void> recordHistory() async {
    final newHistory = [...state.balanceHistory, state.balance];
    // 履歴が長くなりすぎないように制限（例：過去100ゲーム）
    if (newHistory.length > 100) {
      newHistory.removeAt(0);
    }

    state = state.copyWith(balanceHistory: newHistory);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyBalanceHistory,
      newHistory.map((e) => e.toString()).toList(),
    );
  }

  /// 履歴をリセットする。
  Future<void> resetHistory() async {
    state = state.copyWith(
      balanceHistory: [state.balance],
      accuracyHistory: [],
      strategyStats: {for (var s in BettingStrategy.values) s: StrategyStats()},
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyBalanceHistory, [state.balance.toString()]);
    await prefs.remove(_keyAccuracyHistory);
    await prefs.remove(_keyStrategyStats);
  }

  /// 所持金をリセットし、履歴もリセットする。
  Future<void> resetBalance(int amount) async {
    state = state.copyWith(
      balance: amount,
      balanceHistory: [amount],
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBalance, amount);
    await prefs.setStringList(_keyBalanceHistory, [amount.toString()]);
  }

  /// 正解・不正解を記録する。
  Future<void> recordAccuracy(bool isCorrect) async {
    final newHistory = [...state.accuracyHistory, isCorrect];
    if (newHistory.length > 200) newHistory.removeAt(0);

    state = state.copyWith(accuracyHistory: newHistory);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyAccuracyHistory,
      newHistory.map((e) => e.toString()).toList(),
    );
  }

  /// 戦略ごとの統計を更新する。
  Future<void> recordStrategyResult(
    BettingStrategy strategy,
    GameResult result,
  ) async {
    final currentStats = state.strategyStats[strategy] ?? StrategyStats();
    StrategyStats newStats;

    switch (result) {
      case GameResult.win:
      case GameResult.blackjack:
        newStats = currentStats.copyWith(
          games: currentStats.games + 1,
          wins: currentStats.wins + 1,
        );
        break;
      case GameResult.loss:
        newStats = currentStats.copyWith(
          games: currentStats.games + 1,
          losses: currentStats.losses + 1,
        );
        break;
      case GameResult.push:
        newStats = currentStats.copyWith(
          games: currentStats.games + 1,
          pushes: currentStats.pushes + 1,
        );
        break;
    }

    final newMap = Map<BettingStrategy, StrategyStats>.from(
      state.strategyStats,
    );
    newMap[strategy] = newStats;

    state = state.copyWith(strategyStats: newMap);

    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> encodeMap = {};
    newMap.forEach((key, value) {
      encodeMap[key.toString()] = value.toJson();
    });
    await prefs.setString(_keyStrategyStats, jsonEncode(encodeMap));
  }
}

/// SettingsNotifier を提供するプロバイダー。
final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((
  ref,
) {
  return SettingsNotifier();
});
