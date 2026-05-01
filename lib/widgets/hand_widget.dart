import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hand.dart';
import 'playing_card_widget.dart';
import '../providers/settings_provider.dart';
import '../logic/localization.dart';
import '../logic/betting_system.dart';
import '../providers/game_state_provider.dart';

/// プレイヤーまたはディーラーの手札をまとめて表示するウィジェット。
class HandWidget extends ConsumerWidget {
  final Hand hand;
  final String label;
  final bool isDealer;
  final bool showTotal;
  final bool hideSecondCard;
  final GameResult? result;
  final String? scoreOverride;

  const HandWidget({
    Key? key,
    required this.hand,
    required this.label,
    this.isDealer = false,
    this.showTotal = true,
    this.hideSecondCard = false,
    this.result,
    this.scoreOverride,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final gameState = ref.watch(gameStateProvider);
    final l10n = AppLocalizations(settings.language);

    String displayScore = scoreOverride ?? hand.scoreDisplay;
    if (displayScore == 'BJ') displayScore = l10n.get('blackjack');
    if (displayScore == 'BUST') displayScore = l10n.get('bust');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: gameState.isPracticeMode
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 2), // 4 -> 2
        SizedBox(
          height: 90, // 96 -> 90
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < hand.cards.length; i++)
                Transform.translate(
                  offset: Offset(
                    (i - (hand.cards.length - 1) / 2) * 24.0, // 少し広げる
                    0,
                  ),
                  child: PlayingCardWidget(
                    key: ValueKey(hand.cards[i].id),
                    card: hand.cards[i],
                    isHidden: isDealer && hideSecondCard && i == 1,
                  ),
                ),
            ],
          ),
        ),
        if (showTotal &&
            !(isDealer && hideSecondCard) &&
            hand.cards.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 2,
              ), // 12, 4 -> 10, 2
              decoration: BoxDecoration(
                color: hand.isBust
                    ? const Color(0xFFFF3B30).withOpacity(0.15)
                    : (gameState.isPracticeMode
                        ? const Color(0xFF1C1C1E) // 練習モードでは濃い色
                        : Colors.white.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: hand.isBust
                      ? const Color(0xFFFF3B30).withOpacity(0.5)
                      : (gameState.isPracticeMode
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2)),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hand.bet > 0) ...[
                    Text(
                      hand.isFreeHand || hand.isFreeDouble
                          ? 'FREE '
                          : '\$${hand.bet}${hand.isFreeDouble ? ' + FREE' : ''} ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    displayScore,
                    style: TextStyle(
                      color: hand.isBust ? const Color(0xFFFF3B30) : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getResultColor(result!).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getResultColor(result!).withOpacity(0.5)),
                      ),
                      child: Text(
                        _getResultText(result!, l10n),
                        style: TextStyle(
                          color: _getResultColor(result!),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getResultColor(GameResult result) {
    switch (result) {
      case GameResult.win:
        return const Color(0xFF00E676); // 鮮やかなグリーン
      case GameResult.blackjack:
        return const Color(0xFFFFD700); // ゴールド
      case GameResult.loss:
        return const Color(0xFFFF3B30); // 鮮やかなレッド
      case GameResult.push:
        return Colors.white;
    }
  }

  String _getResultText(GameResult result, AppLocalizations l10n) {
    switch (result) {
      case GameResult.win:
        return l10n.get('win');
      case GameResult.blackjack:
        return l10n.get('blackjack');
      case GameResult.loss:
        return l10n.get('loss');
      case GameResult.push:
        return l10n.get('push');
    }
  }
}
