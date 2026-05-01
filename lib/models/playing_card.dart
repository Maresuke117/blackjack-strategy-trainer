/// トランプのマーク（スート）を定義する列挙型。
enum Suit { spades, hearts, diamonds, clubs }

/// トランプのランク（数字・記号）を定義する列挙型。
enum Rank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
}

/// 1枚のトランプカードを管理するクラス。
/// カードのスート、ランク、およびブラックジャックにおける値を保持する。
class PlayingCard {
  /// カードの一意識別子（アニメーション用）
  final String id;

  /// カードのマーク
  final Suit suit;

  /// カードのランク
  final Rank rank;

  /// [suit] と [rank] を指定してカードを生成する。
  PlayingCard({required this.id, required this.suit, required this.rank});

  /// カードの値を計算する。
  /// Aはデフォルトで11として返すが、Handクラスで合計計算時に調整される。
  /// J, Q, Kは10として扱う。
  int get value {
    switch (rank) {
      case Rank.ace:
        return 11;
      case Rank.two:
        return 2;
      case Rank.three:
        return 3;
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
        return 10;
    }
  }

  /// デバッグ用または表示用の文字列表現を返す。
  @override
  String toString() => '${suit.name} ${rank.name}';
}
