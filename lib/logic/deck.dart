import 'dart:math';
import '../models/playing_card.dart';

/// トランプの山札（デッキ）を管理するクラス。
/// カードのシャッフルや、カードを引く処理を担当する。
class Deck {
  /// 山札にあるカードのリスト。
  final List<PlayingCard> _cards = [];

  /// [deckCount] で指定した個数のデッキ（1デッキ52枚）を使用して初期化する。
  /// 通常、カジノでは6〜8デッキが使用される。
  Deck({int deckCount = 1}) {
    for (int i = 0; i < deckCount; i++) {
      for (var suit in Suit.values) {
        for (var rank in Rank.values) {
          final id = '${suit.name}_${rank.name}_$i';
          _cards.add(PlayingCard(id: id, suit: suit, rank: rank));
        }
      }
    }
    shuffle();
  }

  /// 山札をシャッフルする。
  void shuffle() {
    _cards.shuffle(Random());
  }

  /// 山札からカードを1枚引く。
  /// 山札が空の場合は null を返すか、あるいは例外を投げる設計にする。
  PlayingCard draw() {
    if (_cards.isEmpty) {
      throw Exception('デッキにカードがありません。');
    }
    return _cards.removeLast();
  }

  /// 指定したランクのカードを1枚探し、山札から取り出して返す。
  /// 特殊モード（ソフトハンド練習等）で使用する。
  PlayingCard drawRank(Rank rank) {
    final index = _cards.indexWhere((c) => c.rank == rank);
    if (index == -1) {
      // 山札にない場合は新しく生成して返す（シミュレーションの厳密性より練習効率を優先）
      return PlayingCard(
        id: 'extra_${DateTime.now().microsecondsSinceEpoch}',
        suit: Suit.spades,
        rank: rank,
      );
    }
    return _cards.removeAt(index);
  }

  /// 残りのカード枚数を返す。
  int get remainingCards => _cards.length;
}
