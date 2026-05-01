import '../models/hand.dart';
import '../models/playing_card.dart';

/// プレイヤーの推奨アクション。
enum BlackjackAction { hit, stand, doubleDown, split, surrender }

/// ベーシックストラテジーに基づき、正解のアクションを判定するクラス。
class StrategyEvaluator {
  /// プレイヤーの手札とディーラーのアップカードから推奨アクションを判定する。
  /// [playerHand] プレイヤーの手札。
  /// [dealerUpCard] ディーラーの見えている1枚のカード。
  static BlackjackAction getRecommendedAction(
    Hand playerHand,
    PlayingCard dealerUpCard,
  ) {
    final playerTotal = playerHand.totalScore;
    final dealerValue = dealerUpCard.value;

    // 1. サレンダーの判定（最初に2枚の時のみ）
    if (playerHand.cards.length == 2) {
      // 8,8 vs 9 はスプリット優先なのでここでは除外
      bool isPair8 =
          playerHand.canSplit && playerHand.cards[0].rank == Rank.eight;

      if (playerTotal == 16 && (dealerValue >= 9 && dealerValue <= 11)) {
        if (!(isPair8 && dealerValue == 9)) {
          return BlackjackAction.surrender;
        }
      }
      if (playerTotal == 15 && dealerValue == 10) {
        return BlackjackAction.surrender;
      }
    }

    // 2. ペア（スプリット）の判定
    if (playerHand.canSplit) {
      final pairRank = playerHand.cards[0].rank;
      // 5,5 はスプリットよりダブルダウン優先なのでここで判定せずハードハンドに任せる
      if (pairRank != Rank.five && _shouldSplit(pairRank, dealerValue)) {
        return BlackjackAction.split;
      }
    }

    // 3. ソフトハンド（Aを含む）の判定
    if (playerHand.isSoftHand) {
      return _getSoftHandAction(playerTotal, dealerValue);
    }

    // 4. ハードハンドの判定
    return _getHardHandAction(playerTotal, dealerValue);
  }

  /// スプリットすべきかどうかを判定する。
  static bool _shouldSplit(Rank pairRank, int dealerValue) {
    switch (pairRank) {
      case Rank.ace:
      case Rank.eight:
        return true; // Aと8は常にスプリット
      case Rank.two:
      case Rank.three:
      case Rank.seven:
        return dealerValue >= 2 && dealerValue <= 7;
      case Rank.four:
        return dealerValue == 5 || dealerValue == 6;
      case Rank.five:
        return false; // 5,5はダブルダウン
      case Rank.six:
        return dealerValue >= 2 && dealerValue <= 6;
      case Rank.nine:
        return (dealerValue >= 2 && dealerValue <= 6) ||
            (dealerValue >= 8 && dealerValue <= 9);
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
        return false; // 10のペアはステイ
    }
  }

  /// ソフトハンドの場合の推奨アクション。
  static BlackjackAction _getSoftHandAction(int playerTotal, int dealerValue) {
    // playerTotal は 13〜21 (Aを11として計算済み)
    if (playerTotal >= 19) return BlackjackAction.stand; // A,8 A,9
    if (playerTotal == 18) {
      // A,7
      if (dealerValue == 2) return BlackjackAction.stand;
      if (dealerValue >= 3 && dealerValue <= 6)
        return BlackjackAction.doubleDown;
      if (dealerValue == 7 || dealerValue == 8) return BlackjackAction.stand;
      return BlackjackAction.hit;
    }
    if (playerTotal == 17) {
      // A,6
      if (dealerValue >= 3 && dealerValue <= 6)
        return BlackjackAction.doubleDown;
      return BlackjackAction.hit;
    }
    if (playerTotal == 15 || playerTotal == 16) {
      // A,4 A,5
      if (dealerValue >= 4 && dealerValue <= 6)
        return BlackjackAction.doubleDown;
      return BlackjackAction.hit;
    }
    if (playerTotal == 13 || playerTotal == 14) {
      // A,2 A,3
      if (dealerValue == 5 || dealerValue == 6)
        return BlackjackAction.doubleDown;
      return BlackjackAction.hit;
    }
    return BlackjackAction.hit;
  }

  /// ハードハンドの場合の推奨アクション。
  static BlackjackAction _getHardHandAction(int playerTotal, int dealerValue) {
    if (playerTotal >= 17) return BlackjackAction.stand;
    if (playerTotal >= 13 && playerTotal <= 16) {
      if (dealerValue >= 2 && dealerValue <= 6) return BlackjackAction.stand;
      return BlackjackAction.hit;
    }
    if (playerTotal == 12) {
      if (dealerValue >= 4 && dealerValue <= 6) return BlackjackAction.stand;
      return BlackjackAction.hit;
    }
    if (playerTotal == 11) {
      if (dealerValue == 11) return BlackjackAction.hit; // A相手はHit
      return BlackjackAction.doubleDown;
    }
    if (playerTotal == 10) {
      if (dealerValue >= 2 && dealerValue <= 9)
        return BlackjackAction.doubleDown;
      return BlackjackAction.hit;
    }
    if (playerTotal == 9) {
      if (dealerValue >= 3 && dealerValue <= 6)
        return BlackjackAction.doubleDown;
      return BlackjackAction.hit;
    }
    return BlackjackAction.hit;
  }
}
