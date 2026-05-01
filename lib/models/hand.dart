import 'playing_card.dart';

/// プレイヤーまたはディーラーの手札を管理するクラス。
/// 合計値の計算（Aの調整含む）やバスト判定の責任を持つ。
class Hand {
  /// 手札にあるカードのリスト。
  final List<PlayingCard> cards;

  /// この手札に賭けられている金額。
  final int bet;

  /// スプリットによって作成された手札かどうか。
  final bool isFromSplit;

  /// フリーベットによって作成された手札か（分割後の2つ目の手札など）。
  final bool isFreeHand;

  /// フリーダブルダウンが行われた手札かどうか。
  final bool isFreeDouble;

  /// スイッチによってカードが交換された手札かどうか。
  final bool isSwitched;

  /// 初期状態の手札を作成する。
  Hand({
    List<PlayingCard>? cards,
    this.bet = 0,
    this.isFromSplit = false,
    this.isFreeHand = false,
    this.isFreeDouble = false,
    this.isSwitched = false,
  }) : cards = cards ?? [];

  /// 手札に新しいカードを追加した新しい [Hand] インスタンスを返す。
  Hand addCard(PlayingCard card) {
    return Hand(
      cards: [...cards, card],
      bet: bet,
      isFromSplit: isFromSplit,
      isFreeHand: isFreeHand,
      isFreeDouble: isFreeDouble,
      isSwitched: isSwitched,
    );
  }

  /// 賭け金を更新した新しい [Hand] インスタンスを返す。
  Hand copyWithBet(int newBet) {
    return Hand(
      cards: cards,
      bet: newBet,
      isFromSplit: isFromSplit,
      isFreeHand: isFreeHand,
      isFreeDouble: isFreeDouble,
      isSwitched: isSwitched,
    );
  }

  /// フラグを更新した新しい [Hand] インスタンスを返す。
  Hand copyWithFlags({bool? isFreeHand, bool? isFreeDouble}) {
    return Hand(
      cards: cards,
      bet: bet,
      isFromSplit: isFromSplit,
      isFreeHand: isFreeHand ?? this.isFreeHand,
      isFreeDouble: isFreeDouble ?? this.isFreeDouble,
      isSwitched: isSwitched,
    );
  }

  /// 手札の合計値を計算する。
  /// Aを11として計算し、合計が21を超えた場合は1として扱うように調整する。
  int get totalScore {
    int score = 0;
    int aceCount = 0;

    for (final card in cards) {
      score += card.value;
      if (card.rank == Rank.ace) {
        aceCount++;
      }
    }

    // バストしている場合、Aを11から1に変換（1枚につき-10）して調整する
    while (score > 21 && aceCount > 0) {
      score -= 10;
      aceCount--;
    }

    return score;
  }

  /// 表示用の合計値文字列を取得する。
  /// ソフトハンドの場合は「7 / 17」のように表示する。
  String get scoreDisplay {
    if (isBlackjack) return 'BJ';
    if (isBust) return 'BUST';

    if (isSoftHand) {
      int hardScore = totalScore - 10;
      return '$hardScore / $totalScore';
    }

    return totalScore.toString();
  }

  /// 手札が「バスト（21を超えた状態）」かどうかを判定する。
  bool get isBust => totalScore > 21;

  /// 手札が「ブラックジャック（最初の2枚で21点）」かどうかを判定する。
  /// スプリットされた手札の場合は、合計が21点でもブラックジャックとはみなさない。
  /// スイッチモードでは「ナチュラル」かどうかの判定に [isSwitched] を使用する。
  bool get isBlackjack => !isFromSplit && cards.length == 2 && totalScore == 21;

  /// 「ナチュラル・ブラックジャック」かどうかを判定する。
  bool get isNaturalBlackjack => isBlackjack && !isSwitched;

  /// ソフトハンド（Aを11として数えてもバストしていない状態）かどうかを判定する。
  bool get isSoftHand {
    int score = 0;
    int aceCount = 0;

    for (final card in cards) {
      score += card.value;
      if (card.rank == Rank.ace) {
        aceCount++;
      }
    }

    // Aが含まれており、かつ少なくとも1枚を11として数えても21以下である状態
    while (score > 21 && aceCount > 0) {
      score -= 10;
      aceCount--;
    }

    // まだ調整可能なAが残っている（つまり11として数えられているAがある）場合はソフトハンド
    return aceCount > 0;
  }

  /// スプリット可能かどうか（最初の2枚が同じランクかどうか）を判定する。
  bool get canSplit => cards.length == 2 && cards[0].rank == cards[1].rank;
}
