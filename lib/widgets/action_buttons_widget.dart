import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/ad_helper.dart';
import '../providers/game_state_provider.dart';
import '../models/playing_card.dart';
import '../logic/game_engine.dart';
import 'strategy_chart_widget.dart';
import '../providers/settings_provider.dart';
import '../logic/localization.dart';

/// プレイヤーのアクション（ヒット、スタンド等）を行うボタン群。
class ActionButtonsWidget extends ConsumerWidget {
  const ActionButtonsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations(settings.language);
    final isPlayerTurn = gameState.status == GameStatus.playerTurn;

    if (gameState.status == GameStatus.betting ||
        gameState.status == GameStatus.gameOver) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ElevatedButton(
          onPressed: () {
            if (gameState.status == GameStatus.gameOver) {
              // 20%の確率で広告を表示
              if (Random().nextInt(5) == 0) {
                AdHelper.showInterstitialAd(() {
                  ref.read(gameStateProvider.notifier).nextGame();
                });
              } else {
                ref.read(gameStateProvider.notifier).nextGame();
              }
            } else {
              ref.read(gameStateProvider.notifier).startDeal();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF007AFF).withOpacity(0.4),
          ),
          child: Text(
            gameState.status == GameStatus.gameOver ? l10n.get('next_game') : l10n.get('deal'),
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _ActionButton(
                label: l10n.get('hit'),
                onPressed: isPlayerTurn
                    ? () => ref.read(gameStateProvider.notifier).hit()
                    : null,
                color: const Color(0xFF34C759), // iOS Success Green
              ),
              _ActionButton(
                label: l10n.get('stand'),
                onPressed: isPlayerTurn
                    ? () => ref.read(gameStateProvider.notifier).stand()
                    : null,
                color: const Color(0xFFFF3B30), // iOS Destructive Red
              ),
              _ActionButton(
                label: (gameState.isFreeBetMode &&
                        !gameState.currentPlayerHand.isSoftHand &&
                        (gameState.currentPlayerHand.totalScore == 9 ||
                            gameState.currentPlayerHand.totalScore == 10 ||
                            gameState.currentPlayerHand.totalScore == 11))
                    ? 'FREE ${l10n.get('double')}'
                    : l10n.get('double'),
                onPressed: (isPlayerTurn &&
                        gameState.currentPlayerHand.cards.length == 2)
                    ? () => ref.read(gameStateProvider.notifier).doubleDown()
                    : null,
                color: const Color(0xFFFF9F0A), // iOS Amber/Gold
              ),
              _ActionButton(
                label: (gameState.isFreeBetMode &&
                        gameState.currentPlayerHand.canSplit &&
                        gameState.currentPlayerHand.cards[0].rank != Rank.ten &&
                        gameState.currentPlayerHand.cards[0].rank != Rank.jack &&
                        gameState.currentPlayerHand.cards[0].rank != Rank.queen &&
                        gameState.currentPlayerHand.cards[0].rank != Rank.king)
                    ? 'FREE ${l10n.get('split')}'
                    : l10n.get('split'),
                onPressed: (isPlayerTurn &&
                        gameState.currentPlayerHand.canSplit &&
                        (!gameState.isSwitchMode ||
                            !gameState.currentPlayerHand.isFromSplit))
                    ? () => ref.read(gameStateProvider.notifier).split()
                    : null,
                color: const Color(0xFF30D5C8), // Teal/Cyan
              ),
              if (gameState.isSwitchMode)
                _ActionButton(
                  label: l10n.get('switch'),
                  onPressed: (isPlayerTurn &&
                          !gameState.hasSwitched &&
                          gameState.playerHands.length == 2 &&
                          gameState.playerHands.every((h) => h.cards.length == 2))
                      ? () => ref.read(gameStateProvider.notifier).switchCards()
                      : null,
                  color: const Color(0xFF5856D6), // iOS Indigo
                ),
              if (!gameState.isSwitchMode)
                _ActionButton(
                  label: l10n.get('surrender'),
                  onPressed: (isPlayerTurn &&
                          gameState.playerHands.length == 1 &&
                          gameState.currentPlayerHand.cards.length == 2)
                      ? () => ref.read(gameStateProvider.notifier).surrender()
                      : null,
                  color: const Color(0xFF636366), // iOS System Grey
                ),
              _ActionButton(
                label: l10n.get('strategy'),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => StrategyChartWidget(
                      playerHand: gameState.currentPlayerHand,
                      dealerUpCard: gameState.dealerHand.cards.isNotEmpty
                          ? gameState.dealerHand.cards[0]
                          : null,
                    ),
                  );
                },
                color: const Color(0xFF8E8E93), // iOS Gray
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? const Color(0xFF2C2C2E)
              : color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2C2C2E),
          disabledForegroundColor: Colors.white30,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          elevation: onPressed == null ? 0 : 6,
          shadowColor: color?.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: onPressed == null
                ? BorderSide(color: Colors.grey.shade700, width: 0.5)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
