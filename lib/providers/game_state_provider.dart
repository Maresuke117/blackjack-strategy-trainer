import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/game_engine.dart';
import '../logic/localization.dart';
import '../logic/betting_system.dart';
import '../models/hand.dart';
import '../models/playing_card.dart';
import '../logic/strategy_evaluator.dart';
import 'settings_provider.dart';

/// 現在のゲームセッションの状態を保持するクラス。
class GameSessionState {
  final GameStatus status;
  final List<Hand> playerHands;
  final int currentHandIndex;
  final Hand dealerHand;
  final int currentBet;
  final String? message;
  final String? strategyMessage;
  final bool? isLastActionCorrect;
  final int correctMoves;
  final int totalMoves;
  final GameResult? lastResult;
  final bool isPracticeMode;
  final bool isSwitchMode;
  final bool isFreeBetMode;
  final bool hasSwitched;
  final int winStreak;
  final int lossStreak;

  GameSessionState({
    required this.status,
    required this.playerHands,
    this.currentHandIndex = 0,
    required this.dealerHand,
    required this.currentBet,
    this.message,
    this.strategyMessage,
    this.isLastActionCorrect,
    this.correctMoves = 0,
    this.totalMoves = 0,
    this.lastResult,
    this.isPracticeMode = false,
    this.isSwitchMode = false,
    this.isFreeBetMode = false,
    this.hasSwitched = false,
    this.winStreak = 0,
    this.lossStreak = 0,
  });

  Hand get currentPlayerHand => playerHands[currentHandIndex];
  double get accuracy =>
      totalMoves == 0 ? 100.0 : (correctMoves / totalMoves) * 100.0;

  GameSessionState copyWith({
    GameStatus? status,
    List<Hand>? playerHands,
    int? currentHandIndex,
    Hand? dealerHand,
    int? currentBet,
    String? message,
    String? strategyMessage,
    bool? isLastActionCorrect,
    int? correctMoves,
    int? totalMoves,
    GameResult? lastResult,
    bool? isPracticeMode,
    bool? isSwitchMode,
    bool? isFreeBetMode,
    bool? hasSwitched,
    int? winStreak,
    int? lossStreak,
  }) {
    return GameSessionState(
      status: status ?? this.status,
      playerHands: playerHands ?? this.playerHands,
      currentHandIndex: currentHandIndex ?? this.currentHandIndex,
      dealerHand: dealerHand ?? this.dealerHand,
      currentBet: currentBet ?? this.currentBet,
      message: message,
      strategyMessage: strategyMessage ?? this.strategyMessage,
      isLastActionCorrect: isLastActionCorrect,
      correctMoves: correctMoves ?? this.correctMoves,
      totalMoves: totalMoves ?? this.totalMoves,
      lastResult: lastResult ?? this.lastResult,
      isPracticeMode: isPracticeMode ?? this.isPracticeMode,
      isSwitchMode: isSwitchMode ?? this.isSwitchMode,
      isFreeBetMode: isFreeBetMode ?? this.isFreeBetMode,
      hasSwitched: hasSwitched ?? this.hasSwitched,
      winStreak: winStreak ?? this.winStreak,
      lossStreak: lossStreak ?? this.lossStreak,
    );
  }
}

/// ゲームの進行を管理し、UIに状態を通知するNotifier。
class GameStateNotifier extends StateNotifier<GameSessionState> {
  final Ref _ref;
  final GameEngine _engine = GameEngine();
  late BettingSystem _bettingSystem;

  GameStateNotifier(this._ref)
    : super(
        GameSessionState(
          status: GameStatus.betting,
          playerHands: [Hand()],
          dealerHand: Hand(),
          currentBet: 0,
        ),
      ) {
    _initBettingSystem();
    _engine.initializeDeck(deckCount: 6);
  }

  void _initBettingSystem() {
    final settings = _ref.read(settingsProvider);
    _bettingSystem = BettingSystem(
      baseBet: settings.baseBet,
      betUnit: settings.betUnit,
      strategy: settings.strategy,
      maxBet: settings.maxBet,
    );
    state = state.copyWith(currentBet: _bettingSystem.currentBet);
  }

  void setPracticeMode(bool isPractice) {
    resetSession();
    state = state.copyWith(isPracticeMode: isPractice);
  }

  void setSwitchMode(bool isSwitch) {
    resetSession();
    state = state.copyWith(isSwitchMode: isSwitch);
  }

  void setFreeBetMode(bool isFree) {
    resetSession();
    state = state.copyWith(isFreeBetMode: isFree);
  }

  /// セッション状態を完全にリセットする。
  void resetSession() {
    _engine.initializeDeck(deckCount: 6);
    state = GameSessionState(
      status: GameStatus.gameOver, // 最初はディール待ち状態
      playerHands: [],
      dealerHand: Hand(),
      currentBet: _bettingSystem.currentBet,
      isPracticeMode: state.isPracticeMode,
      isSwitchMode: state.isSwitchMode,
      isFreeBetMode: state.isFreeBetMode,
      winStreak: 0,
      lossStreak: 0,
    );
  }

  /// ゲームを開始する（カードを配る）。
  void startDeal() {
    final settings = _ref.read(settingsProvider);

    // ベットシステムの同期（設定変更を反映）
    // 戦略やベースベットが変わった時だけ新しく作り直す（それ以外は進行状態を維持）
    if (_bettingSystem.baseBet != settings.baseBet ||
        _bettingSystem.strategy != settings.strategy ||
        _bettingSystem.betUnit != settings.betUnit ||
        _bettingSystem.maxBet != settings.maxBet) {
      _bettingSystem = BettingSystem(
        baseBet: settings.baseBet,
        betUnit: settings.betUnit,
        strategy: settings.strategy,
        maxBet: settings.maxBet,
      );
      state = state.copyWith(currentBet: _bettingSystem.currentBet);
    } else {
      // 既存の進行状態から最新のベット額を取得
      state = state.copyWith(currentBet: _bettingSystem.currentBet);
    }

    // 練習モード以外では資金チェックと減算を行う
    if (!state.isPracticeMode) {
      final multiplier = state.isSwitchMode ? 2 : 1;
      final requiredBet = _bettingSystem.currentBet * multiplier;

      if (settings.balance < requiredBet) {
        final l10n = AppLocalizations(settings.language);
        state = state.copyWith(message: l10n.get('no_funds'));
        return;
      }
    // 資金の減算
      _ref
          .read(settingsProvider.notifier)
          .updateBalance(settings.balance - requiredBet);
    }

    // デッキの残量が少なくなったらリセット（フリーズ防止策）
    if (_engine.remainingCards < 52) {
      _engine.initializeDeck(deckCount: 6);
    }

    state = state.copyWith(
      status: GameStatus.dealing,
      playerHands: [Hand()],
      dealerHand: Hand(),
    );

    // 初期カードの配布
    Future.delayed(const Duration(milliseconds: 500), () {
      _dealInitialCards();
    });
  }

  void _dealInitialCards() {
    final settings = _ref.read(settingsProvider);
    var dHand = Hand();

    if (state.isSwitchMode) {
      var pHand1 = Hand(bet: _bettingSystem.currentBet);
      var pHand2 = Hand(bet: _bettingSystem.currentBet);

      // スイッチモードの配布：プレイヤー1→プレイヤー2→ディーラー→プレイヤー1→プレイヤー2→ディーラー
      pHand1 = pHand1.addCard(_engine.drawCard());
      pHand2 = pHand2.addCard(_engine.drawCard());
      dHand = dHand.addCard(_engine.drawCard());
      pHand1 = pHand1.addCard(_engine.drawCard());
      pHand2 = pHand2.addCard(_engine.drawCard());
      dHand = dHand.addCard(_engine.drawCard());

      state = state.copyWith(
        playerHands: [pHand1, pHand2],
        dealerHand: dHand,
        status: dHand.isBlackjack
            ? GameStatus.calculatingResult
            : GameStatus.playerTurn,
        currentHandIndex: 0,
      );

      if (dHand.isBlackjack) {
        _finishGame();
      }
    } else {
      var pHand = Hand(bet: _bettingSystem.currentBet);
      // 通常モードの配布
      if (settings.isSoftHandMode) {
        pHand = pHand.addCard(_engine.drawRank(Rank.ace));
      } else {
        pHand = pHand.addCard(_engine.drawCard());
      }

      dHand = dHand.addCard(_engine.drawCard());
      pHand = pHand.addCard(_engine.drawCard());
      dHand = dHand.addCard(_engine.drawCard());

      state = state.copyWith(
        playerHands: [pHand],
        dealerHand: dHand,
        status: pHand.isBlackjack
            ? GameStatus.calculatingResult
            : GameStatus.playerTurn,
      );

      if (pHand.isBlackjack) {
        _finishGame();
      }
    }
  }

  /// プレイヤーのアクション：ヒット
  void hit() {
    _checkStrategy(BlackjackAction.hit);
    final newHand = state.currentPlayerHand.addCard(_engine.drawCard());
    final newHands = [...state.playerHands];
    newHands[state.currentHandIndex] = newHand;

    state = state.copyWith(playerHands: newHands);

    if (newHand.isBust || newHand.totalScore == 21) {
      _advanceHand();
    }
  }

  /// 次の手札へ進む、またはディーラーのターンへ
  void _advanceHand() {
    if (state.currentHandIndex < state.playerHands.length - 1) {
      final nextIndex = state.currentHandIndex + 1;
      state = state.copyWith(currentHandIndex: nextIndex);

      // 新しい手札が既に21点（スプリット後の配布などで）の場合は、プレイヤーが操作する間もなく次へ進む
      if (state.playerHands[nextIndex].totalScore == 21) {
        _advanceHand();
      }
    } else {
      _finishPlayerTurn();
    }
  }

  void _finishPlayerTurn() {
    // 全ての手札が終了した
    if (state.playerHands.every((h) => h.isBust)) {
      state = state.copyWith(status: GameStatus.calculatingResult);
      _finishGame();
    } else {
      state = state.copyWith(status: GameStatus.dealerTurn);
      _dealerPlay();
    }
  }

  /// プレイヤーのアクション：スタンド
  void stand() {
    _checkStrategy(BlackjackAction.stand);
    _advanceHand();
  }

  /// プレイヤーのアクション：ダブルダウン
  void doubleDown() {
    _checkStrategy(BlackjackAction.doubleDown);
    final settings = _ref.read(settingsProvider);
    final currentHand = state.currentPlayerHand;

    bool isFree = false;
    if (state.isFreeBetMode) {
      // ハードの9, 10, 11ならフリーダブル
      if (!currentHand.isSoftHand &&
          (currentHand.totalScore == 9 ||
              currentHand.totalScore == 10 ||
              currentHand.totalScore == 11)) {
        isFree = true;
      }
    }

    if (!isFree) {
      if (settings.balance < currentHand.bet) {
        final l10n = AppLocalizations(settings.language);
        state = state.copyWith(message: l10n.get('no_funds_double'));
        return;
      }
      _ref
          .read(settingsProvider.notifier)
          .updateBalance(settings.balance - currentHand.bet);
    }

    // このハンドのベット額を倍にする（フリーの場合はフラグを立てる）
    final newHand = currentHand
        .copyWithBet(currentHand.bet * 2)
        .copyWithFlags(isFreeDouble: isFree)
        .addCard(_engine.drawCard());
    final newHands = [...state.playerHands];
    newHands[state.currentHandIndex] = newHand;

    state = state.copyWith(playerHands: newHands);

    _advanceHand();
  }

  /// プレイヤーのアクション：スプリット
  void split() {
    _checkStrategy(BlackjackAction.split);
    final settings = _ref.read(settingsProvider);
    final currentHand = state.currentPlayerHand;

    if (!currentHand.canSplit) return;

    // スイッチモードでは再スプリット禁止
    if (state.isSwitchMode && currentHand.isFromSplit) {
      final l10n = AppLocalizations(settings.language);
      state = state.copyWith(message: l10n.get('cant_resplit'));
      return;
    }

    bool isFree = false;
    if (state.isFreeBetMode) {
      // 10以外のペアならフリースプリット
      final rank = currentHand.cards[0].rank;
      if (rank != Rank.ten &&
          rank != Rank.jack &&
          rank != Rank.queen &&
          rank != Rank.king) {
        isFree = true;
      }
    }

    if (!isFree) {
      if (settings.balance < currentHand.bet) {
        final l10n = AppLocalizations(settings.language);
        state = state.copyWith(message: l10n.get('no_funds_split'));
        return;
      }
      _ref
          .read(settingsProvider.notifier)
          .updateBalance(settings.balance - currentHand.bet);
    }

    final card1 = currentHand.cards[0];
    final card2 = currentHand.cards[1];

    // スプリットされた手札としてフラグを立て、ベット額を引き継ぐ
    // 2枚目はフリー判定を適用
    final hand1 = Hand(
      cards: [card1],
      bet: currentHand.bet,
      isFromSplit: true,
      isFreeHand: currentHand.isFreeHand,
    ).addCard(_engine.drawCard());
    final hand2 = Hand(
      cards: [card2],
      bet: currentHand.bet,
      isFromSplit: true,
      isFreeHand: isFree || currentHand.isFreeHand,
    ).addCard(_engine.drawCard());

    final newHands = [...state.playerHands];
    newHands.removeAt(state.currentHandIndex);
    newHands.insert(state.currentHandIndex, hand2);
    newHands.insert(state.currentHandIndex, hand1);

    state = state.copyWith(
      playerHands: newHands,
      currentHandIndex: state.currentHandIndex,
    );

    // Aのスプリットは1枚のみ
    if (card1.rank == Rank.ace) {
      _advanceHand();
      return;
    }

    if (hand1.totalScore == 21) {
      _advanceHand();
    }
  }

  /// スイッチモード専用：カードの入れ替え
  void switchCards() {
    if (!state.isSwitchMode || state.hasSwitched) return;
    if (state.playerHands.length != 2) return;

    // 両方の手札がまだ2枚かつ、ヒット等のアクションを行っていないことを確認
    // （厳密には currentHandIndex が 0 の時のみ許可するのが一般的）
    if (state.playerHands[0].cards.length != 2 ||
        state.playerHands[1].cards.length != 2)
      return;

    final hand1Cards = [...state.playerHands[0].cards];
    final hand2Cards = [...state.playerHands[1].cards];

    // 2枚目のカードを交換
    final cardToSwap1 = hand1Cards.removeAt(1);
    final cardToSwap2 = hand2Cards.removeAt(1);

    hand1Cards.add(cardToSwap2);
    hand2Cards.add(cardToSwap1);

    final newHand1 = Hand(
      cards: hand1Cards,
      bet: state.playerHands[0].bet,
      isFromSplit: false,
      isSwitched: true,
    );
    final newHand2 = Hand(
      cards: hand2Cards,
      bet: state.playerHands[1].bet,
      isFromSplit: false,
      isSwitched: true,
    );

    final settings = _ref.read(settingsProvider);
    state = state.copyWith(
      playerHands: [newHand1, newHand2],
      hasSwitched: true,
      strategyMessage: AppLocalizations(settings.language).get('switched'),
    );
  }

  /// プレイヤーのアクション：サレンダー
  void surrender() {
    final settings = _ref.read(settingsProvider);
    if (state.isSwitchMode) {
      final l10n = AppLocalizations(settings.language);
      state = state.copyWith(message: l10n.get('cant_surrender'));
      return;
    }
    _checkStrategy(BlackjackAction.surrender);
    final currentHand = state.currentPlayerHand;
    // 半額を返還
    _ref
        .read(settingsProvider.notifier)
        .updateBalance(settings.balance + (currentHand.bet / 2).floor());

    state = state.copyWith(status: GameStatus.calculatingResult);
    _finishGameSurrender();
  }

  void _finishGameSurrender() {
    _bettingSystem.updateNextBet(GameResult.loss);
    state = state.copyWith(
      status: GameStatus.gameOver,
      lastResult: GameResult.loss,
      currentBet: _bettingSystem.currentBet,
      message: AppLocalizations(_ref.read(settingsProvider).language).get('surrender'),
    );
    _ref.read(settingsProvider.notifier).recordHistory();
  }

  /// ディーラーのターン
  Future<void> _dealerPlay() async {
    var dHand = state.dealerHand;
    while (_engine.shouldDealerHit(dHand, isSwitchMode: state.isSwitchMode)) {
      await Future.delayed(const Duration(milliseconds: 600));
      dHand = dHand.addCard(_engine.drawCard());
      state = state.copyWith(dealerHand: dHand);
    }

    state = state.copyWith(status: GameStatus.calculatingResult);
    _finishGame();
  }

  /// ゲーム終了と結果処理
  void _finishGame() {
    int totalPayout = 0;
    GameResult? lastRes;

    for (final hand in state.playerHands) {
      final result = GameEngine.determineResult(
        hand,
        state.dealerHand,
        isSwitchMode: state.isSwitchMode,
        isFreeBetMode: state.isFreeBetMode,
      );
      lastRes = result; // 簡易的に最後の手札の結果を保持

      int payout = 0;
      if (result == GameResult.win) {
        if (hand.isFreeHand) {
          // フリーハンド勝利：利益のみ（元のベットは0として扱う）
          payout = hand.bet;
        } else if (hand.isFreeDouble) {
          // フリーダブル勝利：元のベット($10)の3倍($30)が返ってくる（元本$10 + 利益$10 + フリー分$10）
          payout = (hand.bet * 1.5).toInt();
        } else {
          payout = hand.bet * 2;
        }
      } else if (result == GameResult.blackjack) {
        // スイッチモードではブラックジャックも 1:1 配当
        if (state.isSwitchMode) {
          payout = hand.bet * 2;
        } else {
          payout = (hand.bet * 2.5).toInt();
        }
      } else if (result == GameResult.push) {
        if (hand.isFreeHand) {
          payout = 0; // フリーハンドはプッシュでも何も返らない（元本がないため）
        } else {
          payout = hand.bet;
        }
      }
      totalPayout += payout;
    }

    if (totalPayout > 0 && !state.isPracticeMode) {
      // 常に最新の残高を取得して更新する
      final latestBalance = _ref.read(settingsProvider).balance;
      _ref
          .read(settingsProvider.notifier)
          .updateBalance(latestBalance + totalPayout);
    }

    final settings = _ref.read(settingsProvider);
    if (lastRes != null) {
      _bettingSystem.updateNextBet(lastRes);
      // 戦略ごとの統計を記録
      _ref
          .read(settingsProvider.notifier)
          .recordStrategyResult(settings.strategy, lastRes);
    }

    // 連勝・連敗の計算
    int newWinStreak = state.winStreak;
    int newLossStreak = state.lossStreak;
    String? streakMsg;

    if (lastRes == GameResult.win || lastRes == GameResult.blackjack) {
      newWinStreak++;
      newLossStreak = 0;
      if (newWinStreak >= 3) {
        streakMsg = '$newWinStreak ${AppLocalizations(settings.language).get('streak_wins')}';
      }
    } else if (lastRes == GameResult.loss) {
      newLossStreak++;
      newWinStreak = 0;
      if (newLossStreak >= 3) {
        streakMsg = '$newLossStreak ${AppLocalizations(settings.language).get('streak_losses')}';
      }
    } else if (lastRes == GameResult.push) {
      // プッシュは継続？リセット？一般的にはリセットしないことが多いが、ここでは何もしない
    }

    state = state.copyWith(
      status: GameStatus.gameOver,
      lastResult: lastRes,
      currentBet: _bettingSystem.currentBet,
      winStreak: newWinStreak,
      lossStreak: newLossStreak,
      strategyMessage: streakMsg, // 戦略メッセージの代わりに連勝メッセージを表示
    );

    if (!state.isPracticeMode) {
      _ref.read(settingsProvider.notifier).recordHistory();
    }
  }

  /// 次のゲームへ（ベット画面に戻る）
  void nextGame() {
    state = state.copyWith(
      status: GameStatus.betting,
      playerHands: [Hand()],
      dealerHand: Hand(),
      currentHandIndex: 0,
      message: null,
      strategyMessage: '',
      lastResult: null,
      isLastActionCorrect: null,
      hasSwitched: false,
    );

    // 練習モードなら自動でディール開始
    if (state.isPracticeMode) {
      startDeal();
    }
  }

  /// ストラテジーの正誤判定を行う
  void _checkStrategy(BlackjackAction action) {
    if (!state.isPracticeMode) return; // 練習モード以外では表示しない
    if (state.dealerHand.cards.isEmpty) return;

    final recommendation = StrategyEvaluator.getRecommendedAction(
      state.currentPlayerHand,
      state.dealerHand.cards[0],
    );

    final settings = _ref.read(settingsProvider);
    final l10n = AppLocalizations(settings.language);

    if (action == recommendation) {
      state = state.copyWith(
        strategyMessage: l10n.get('perfect'),
        isLastActionCorrect: true,
        correctMoves: state.correctMoves + 1,
        totalMoves: state.totalMoves + 1,
      );
      _ref.read(settingsProvider.notifier).recordAccuracy(true);
    } else {
      String recStr = recommendation.toString().split('.').last.toUpperCase();
      state = state.copyWith(
        strategyMessage: '${l10n.get('mistake')}$recStr 💡',
        isLastActionCorrect: false,
        totalMoves: state.totalMoves + 1,
      );
      _ref.read(settingsProvider.notifier).recordAccuracy(false);
    }
  }
}

/// GameStateNotifier を提供するプロバイダー。
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameSessionState>((ref) {
      return GameStateNotifier(ref);
    });
