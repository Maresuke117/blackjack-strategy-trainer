/// ベット手法の列挙型。
enum BettingStrategy { flat, martingale, parlay, goodman, dalembert, fibonacci }

/// ゲームの勝敗結果。
enum GameResult { win, loss, push, blackjack }

class BettingSystem {
  /// 現在のベット額。
  int _currentBet;

  /// ベースとなる賭け金。
  final int baseBet;

  /// ベットの最小単位。
  final int betUnit;

  /// 選択中のベット手法。
  final BettingStrategy strategy;

  /// マックスベット。
  final int maxBet;

  /// グッドマン法用の進行状況 (0, 1, 2, 4 * unit)。
  int _goodmanIndex = 0;
  static const _goodmanRelativeSequence = [0, 1, 2, 4];

  /// フィボナッチ法用のインデックス。
  int _fibonacciIndex = 0;
  static const _fibonacciSequence = [
    1,
    2,
    3,
    5,
    8,
    13,
    21,
    34,
    55,
    89,
    144,
  ];

  /// [baseBet], [betUnit], [strategy], [maxBet] を指定して初期化する。
  BettingSystem({
    required this.baseBet,
    required this.betUnit,
    required this.strategy,
    required this.maxBet,
  }) : _currentBet = baseBet;

  /// 現在のベット額を取得する。
  int get currentBet => _currentBet;

  /// ゲーム結果に基づいて次のベット額を計算し、更新する。
  /// [result] 前回のゲーム結果。
  void updateNextBet(GameResult result) {
    switch (strategy) {
      case BettingStrategy.flat:
        _calculateFlat(result);
        break;
      case BettingStrategy.martingale:
        _calculateMartingale(result);
        break;
      case BettingStrategy.parlay:
        _calculateParlay(result);
        break;
      case BettingStrategy.goodman:
        _calculateGoodman(result);
        break;
      case BettingStrategy.dalembert:
        _calculateDalembert(result);
        break;
      case BettingStrategy.fibonacci:
        _calculateFibonacci(result);
        break;
    }

    // マックスベットを適用
    if (_currentBet > maxBet) {
      _currentBet = maxBet;
    }
  }

  /// フラットベット（常に一定額）
  void _calculateFlat(GameResult result) {
    _currentBet = baseBet;
  }

  /// マーチンゲール法（負けたら倍、勝ったらリセット）
  void _calculateMartingale(GameResult result) {
    if (result == GameResult.loss) {
      _currentBet *= 2;
    } else if (result == GameResult.win || result == GameResult.blackjack) {
      _currentBet = baseBet;
    }
  }

  /// パーレー法（勝ったら倍、負けたらリセット）
  void _calculateParlay(GameResult result) {
    if (result == GameResult.win || result == GameResult.blackjack) {
      _currentBet *= 2;
    } else if (result == GameResult.loss) {
      _currentBet = baseBet;
    }
  }

  /// グッドマン法（1235法: 勝つごとにベースに 0, 1, 2, 4 ユニットを加算。負けたらリセット）
  /// $30スタートの場合：$30, $40, $50, $70
  void _calculateGoodman(GameResult result) {
    if (result == GameResult.win || result == GameResult.blackjack) {
      if (_goodmanIndex < _goodmanRelativeSequence.length - 1) {
        _goodmanIndex++;
      }
    } else if (result == GameResult.loss) {
      _goodmanIndex = 0;
    }
    _currentBet = baseBet + (betUnit * _goodmanRelativeSequence[_goodmanIndex]);
  }

  /// ダランベール法（負けたら+1ユニット、勝ったら-1ユニット。最小baseBet）
  void _calculateDalembert(GameResult result) {
    if (result == GameResult.loss) {
      _currentBet += betUnit;
    } else if (result == GameResult.win || result == GameResult.blackjack) {
      if (_currentBet > baseBet) {
        _currentBet -= betUnit;
      } else {
        _currentBet = baseBet;
      }
    }
  }

  /// フィボナッチ法（負けたら次へ、勝ったら2つ戻る。baseBetを基準にシーケンス倍）
  void _calculateFibonacci(GameResult result) {
    if (result == GameResult.loss) {
      if (_fibonacciIndex < _fibonacciSequence.length - 1) {
        _fibonacciIndex++;
      }
    } else if (result == GameResult.win || result == GameResult.blackjack) {
      _fibonacciIndex = (_fibonacciIndex - 2).clamp(0, _fibonacciSequence.length - 1);
    }
    _currentBet = baseBet * _fibonacciSequence[_fibonacciIndex];
  }

  /// ベット状態をリセットする。
  void reset() {
    _currentBet = baseBet;
    _goodmanIndex = 0;
    _fibonacciIndex = 0;
  }
}
