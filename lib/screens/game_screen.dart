import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_state_provider.dart';
import '../logic/game_engine.dart';
import '../logic/betting_system.dart';
import '../widgets/hand_widget.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/balance_board_widget.dart';
import '../providers/settings_provider.dart';
import 'stats_screen.dart';
import '../logic/localization.dart';
import '../widgets/ad_banner_widget.dart';

/// 実際のブラックジャックのゲーム進行を表示する画面。
class GameScreen extends ConsumerWidget {
  final String title;

  const GameScreen({Key? key, required this.title}) : super(key: key);

  Color _getBackgroundColor(GameSessionState state) {
    if (state.isPracticeMode) return const Color(0xFFF2F2F7); // ホワイト（トレーニングセンター）
    if (state.isSwitchMode) return const Color(0xFF6B0F1A); // リッチな高級ワインレッド（バーガンディ）
    if (state.isFreeBetMode) return const Color(0xFF0D253F); // クールブルー
    return const Color(0xFF2E7D32); // カジノグリーン
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations(settings.language);

    final bgColor = _getBackgroundColor(gameState);
    final isLightTheme = gameState.isPracticeMode;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          l10n.get('game_${title.toLowerCase().replaceAll(' ', '')}'),
          style: TextStyle(
            color: isLightTheme ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isLightTheme ? Colors.black87 : Colors.white,
        ),
        actions: [
          if (gameState.isPracticeMode)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '${l10n.get('accuracy')}: ${gameState.accuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const _SettingsDialog(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
          Column(
            children: [
              if (!gameState.isPracticeMode) const BalanceBoardWidget(),

              // ディーラーエリア
              Expanded(
                flex: 3,
                child: Center(
                  child: HandWidget(
                    hand: gameState.dealerHand,
                    label: l10n.get('dealer'),
                    isDealer: true,
                    showTotal: ref.watch(settingsProvider).isTotalVisible,
                    hideSecondCard: gameState.status == GameStatus.playerTurn,
                    scoreOverride: ((gameState.isSwitchMode || gameState.isFreeBetMode) &&
                            gameState.dealerHand.totalScore == 22)
                        ? '22 (${l10n.get('push')})'
                        : null,
                  ),
                ),
              ),

              // メッセージエリア
              if ((gameState.status == GameStatus.gameOver ||
                      gameState.message != null) &&
                  gameState.playerHands.length == 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0), // 8.0 -> 4.0
                  child: _ResultDisplay(
                    result: gameState.lastResult,
                    message: gameState.message,
                  ),
                )
              else
                const SizedBox(height: 2), 
              // プレイヤーエリア
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 12.0,
                    ),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        for (int i = 0; i < gameState.playerHands.length; i++)
                          Opacity(
                            opacity:
                                (gameState.status == GameStatus.playerTurn &&
                                    gameState.currentHandIndex != i)
                                ? 0.6
                                : 1.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (gameState.status ==
                                            GameStatus.playerTurn &&
                                        gameState.currentHandIndex == i)
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: (gameState.status ==
                                              GameStatus.playerTurn &&
                                          gameState.currentHandIndex == i)
                                      ? const Color(0xFF007AFF) // iOS Blue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: (gameState.status ==
                                            GameStatus.playerTurn &&
                                        gameState.currentHandIndex == i)
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF007AFF)
                                              .withOpacity(0.2),
                                          blurRadius: 15,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: HandWidget(
                                hand: gameState.playerHands[i],
                                showTotal: ref
                                    .watch(settingsProvider)
                                    .isTotalVisible,
                                label: gameState.playerHands.length > 1
                                    ? '${l10n.get('hand')} ${i + 1}'
                                    : l10n.get('player'),
                                result: gameState.status == GameStatus.gameOver
                                    ? GameEngine.determineResult(
                                        gameState.playerHands[i],
                                        gameState.dealerHand,
                                        isSwitchMode: gameState.isSwitchMode,
                                        isFreeBetMode: gameState.isFreeBetMode,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ストラテジーメッセージ
              if (gameState.strategyMessage != null &&
                  gameState.strategyMessage!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: (gameState.isLastActionCorrect ??
                            !gameState.strategyMessage!.contains('LOSS'))
                        ? const Color(0xFF34C759).withOpacity(0.15) // iOS Green
                        : const Color(0xFFFF3B30).withOpacity(0.15), // iOS Red
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (gameState.isLastActionCorrect ??
                              !gameState.strategyMessage!.contains('LOSS'))
                          ? const Color(0xFF34C759).withOpacity(0.3)
                          : const Color(0xFFFF3B30).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    gameState.strategyMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (gameState.isLastActionCorrect ??
                              !gameState.strategyMessage!.contains('LOSS'))
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF3B30),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              // 操作ボタン
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0, top: 2.0), // 8.0, 4.0 -> 4.0, 2.0
                child: ActionButtonsWidget(),
              ),
              const AdBannerWidget(),
            ],
          ),
          // シュー（カードケース）のビジュアル
          Positioned(top: 100, right: 10, child: _CardShoe()),
        ],
      ),
    ),
  );
}
}

class _ResultDisplay extends StatelessWidget {
  final GameResult? result;
  final String? message;

  const _ResultDisplay({this.result, this.message});

  @override
  Widget build(BuildContext context) {
    return _ResultDisplayInternal(result: result, message: message);
  }
}

class _ResultDisplayInternal extends ConsumerWidget {
  final GameResult? result;
  final String? message;
  const _ResultDisplayInternal({this.result, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations(settings.language);
    
    String text = message ?? '';
    Color color = Colors.white;

    if (result != null) {
      switch (result!) {
        case GameResult.win:
          text = l10n.get('win');
          color = const Color(0xFF00E676); // 鮮やかなグリーンに変更
          break;
        case GameResult.blackjack:
          text = l10n.get('blackjack');
          color = const Color(0xFFFFD700); // ゴールド
          break;
        case GameResult.loss:
          text = l10n.get('loss');
          color = const Color(0xFFFF3B30); // 鮮やかなレッド
          break;
        case GameResult.push:
          text = l10n.get('push');
          color = Colors.white;
          break;
      }
    } else if (message != null) {
      // Localize common messages if they match keys
      if (message == 'SURRENDERED') text = l10n.get('surrender');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(30), // 完全なピル型（カプセル状）
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), // 14 -> 10
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.4), // 引き締まったダークガラス
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: color.withOpacity(0.6), // 極細の発光ボーダー
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              color: Colors.white, // 文字は純白でソリッドに
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 6.0, // ゆったりとした文字間隔で高級感を
              fontStyle: FontStyle.italic, // スピード感・スタイリッシュさ
              shadows: [
                // 重ね掛けによるネオン発光エフェクト
                Shadow(color: color, blurRadius: 10),
                Shadow(color: color, blurRadius: 20),
                Shadow(color: color.withOpacity(0.5), blurRadius: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsDialog extends ConsumerStatefulWidget {
  const _SettingsDialog({Key? key}) : super(key: key);

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
  late TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    final balance = ref.read(settingsProvider).balance;
    _balanceController = TextEditingController(text: balance.toString());
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final gameState = ref.watch(gameStateProvider);
    final l10n = AppLocalizations(settings.language);

    return AlertDialog(
      backgroundColor: const Color(0xFFF1F8E9), // Very Light Green
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.settings, color: Colors.green),
          const SizedBox(width: 12),
          Text(l10n.get('settings'),
              style: const TextStyle(color: Colors.green)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!gameState.isPracticeMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  l10n.get('base_bet'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900),
                ),
              ),
              DropdownButtonFormField<int>(
                value: settings.baseBet,
                dropdownColor: Colors.white,
                items: [1, 5, 10, 25, 30, 50, 100].map((val) {
                  return DropdownMenuItem(
                    value: val,
                    child: Text('\$$val',
                        style: const TextStyle(color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateBaseBet(val);
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  l10n.get('bet_unit'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900),
                ),
              ),
              DropdownButtonFormField<int>(
                value: settings.betUnit,
                dropdownColor: Colors.white,
                items: [1, 5, 10, 25, 30, 50, 100].map((val) {
                  return DropdownMenuItem(
                    value: val,
                    child: Text('\$$val',
                        style: const TextStyle(color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateBetUnit(val);
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      l10n.get('betting_strategy'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline,
                        size: 20, color: Colors.green.shade700),
                    onPressed: () {
                      _showStrategyInfo(context, settings.strategy, l10n);
                    },
                  ),
                ],
              ),
              DropdownButtonFormField<BettingStrategy>(
                value: settings.strategy,
                dropdownColor: Colors.white,
                items: BettingStrategy.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateStrategy(val);
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  l10n.get('balance_mgmt'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900),
                ),
              ),
              TextField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: l10n.get('set_balance'),
                  labelStyle: TextStyle(color: Colors.green.shade700),
                  prefixText: '\$',
                  prefixStyle: const TextStyle(color: Colors.black87),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = int.tryParse(_balanceController.text);
                    if (amount != null && amount > 0) {
                      ref.read(settingsProvider.notifier).resetBalance(amount);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(l10n.get('balance_mgmt'))), // Simplify
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.get('update_reset')),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
            ],
            if (!gameState.isPracticeMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  l10n.get('max_bet'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900),
                ),
              ),
              DropdownButtonFormField<int>(
                value: settings.maxBet,
                dropdownColor: Colors.white,
                items: [100, 500, 1000, 5000].map((val) {
                  return DropdownMenuItem(
                    value: val,
                    child: Text('\$$val',
                        style: const TextStyle(color: Colors.black87)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateMaxBet(val);
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                l10n.get('language'),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900),
              ),
            ),
            DropdownButtonFormField<AppLanguage>(
              value: settings.language,
              dropdownColor: Colors.white,
              items: AppLanguage.values.map((l) {
                return DropdownMenuItem(
                  value: l,
                  child: Text(l == AppLanguage.en ? 'English' : '日本語',
                      style: const TextStyle(color: Colors.black87)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).updateLanguage(val);
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade200),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            SwitchListTile(
              activeColor: Colors.green,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.get('soft_hand_mode'),
                  style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold)),
              subtitle: Text(l10n.get('soft_hand_desc'),
                  style: TextStyle(color: Colors.grey.shade600)),
              value: settings.isSoftHandMode,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).toggleSoftHandMode(value);
              },
            ),
            SwitchListTile(
              activeColor: Colors.green,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.get('show_total'),
                  style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold)),
              subtitle: Text(l10n.get('show_total_desc'),
                  style: TextStyle(color: Colors.grey.shade600)),
              value: settings.isTotalVisible,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).toggleTotalVisible(value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('close')),
        ),
      ],
    );
  }
}

class _CardShoe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(8),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Stack(
        children: [
          // カードの端が見えている演出
          Positioned(
            top: 20,
            right: 10,
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white10),
                ),
              ),
            ),
          ),
          Positioned(
            top: 25,
            right: 5,
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[900],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white10),
                ),
              ),
            ),
          ),
          // シューの排出口
          Positioned(
            bottom: 10,
            left: 0,
            child: Container(
              width: 30,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
void _showStrategyInfo(
    BuildContext context, BettingStrategy strategy, AppLocalizations l10n) {
  final name = strategy.toString().split('.').last.toLowerCase();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strategy.toString().split('.').last.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.get('strategy_desc_$name'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.get('close'),
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    },
  );
}
