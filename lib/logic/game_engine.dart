import '../models/hand.dart';
import '../models/playing_card.dart';
import 'deck.dart';
import 'betting_system.dart';

/// ゲームの進行状態。
enum GameStatus {
  betting,
  dealing,
  playerTurn,
  dealerTurn,
  calculatingResult,
  gameOver,
}

/// ブラックジャックのゲーム進行を管理するクラス。
/// デッキの管理、勝敗判定、ディーラーの自動アクションなどのロジックを持つ。
class GameEngine {
  late Deck _deck;

  /// デッキを初期化する。
  void initializeDeck({int deckCount = 1}) {
    _deck = Deck(deckCount: deckCount);
  }

  /// カードを1枚引く。
  PlayingCard drawCard() {
    return _deck.draw();
  }

  /// 指定したランクのカードを引く。
  PlayingCard drawRank(Rank rank) {
    return _deck.drawRank(rank);
  }

  /// ディーラーがカードを引くべきかどうかを判定する。
  bool shouldDealerHit(Hand dealerHand, {bool isSwitchMode = false}) {
    // スイッチモード等ではソフト17でもヒットする
    if (isSwitchMode && dealerHand.isSoftHand && dealerHand.totalScore == 17) {
      return true;
    }
    return dealerHand.totalScore < 17;
  }

  /// 残りのカード枚数を取得する。
  int get remainingCards => _deck.remainingCards;

  /// 勝敗結果を判定する。
  static GameResult determineResult(
    Hand playerHand,
    Hand dealerHand, {
    bool isSwitchMode = false,
    bool isFreeBetMode = false,
  }) {
    if (playerHand.isBust) return GameResult.loss;

    // スイッチモードまたはフリーベットモード特有のルール
    if (isSwitchMode || isFreeBetMode) {
      // ディーラーがブラックジャックの場合
      if (dealerHand.isBlackjack) {
        // スイッチモードでは、ナチュラルBJのみが引き分け、それ以外（スプリット後やスイッチ後の21）は負け
        if (isSwitchMode && playerHand.isNaturalBlackjack) {
          return GameResult.push;
        }
        // 通常のBJ同士も通常モードなら引き分けだが、スイッチモードでは上記の通り
        if (!isSwitchMode && playerHand.isBlackjack) {
          return GameResult.push;
        }
        return GameResult.loss;
      }

      // プレイヤーがブラックジャックなら勝ち（ディーラー22よりも優先）
      if (playerHand.isBlackjack) {
        // スイッチモードで厳密なルール：ナチュラルBJは勝ちだが、スイッチ後のBJはディーラー22に対しプッシュ
        if (isSwitchMode && !playerHand.isNaturalBlackjack && dealerHand.totalScore == 22) {
          return GameResult.push;
        }
        return GameResult.blackjack;
      }

      // ディーラーが22ならプッシュ（BJ以外のハンド）
      if (dealerHand.totalScore == 22) return GameResult.push;

      if (dealerHand.isBust) return GameResult.win;
    } else {
      // 通常モード
      if (playerHand.isBlackjack && dealerHand.isBlackjack)
        return GameResult.push;
      if (playerHand.isBlackjack) return GameResult.blackjack;
      if (dealerHand.isBlackjack) return GameResult.loss;
      if (dealerHand.isBust) return GameResult.win;
    }

    final pScore = playerHand.totalScore;
    final dScore = dealerHand.totalScore;

    if (pScore > dScore) {
      return GameResult.win;
    } else if (pScore < dScore) {
      return GameResult.loss;
    } else {
      return GameResult.push;
    }
  }

  /// スイッチモード等の特殊ルールにおける「22プッシュ」判定。
  bool isPushOn22(Hand dealerHand) {
    return dealerHand.totalScore == 22;
  }
}
