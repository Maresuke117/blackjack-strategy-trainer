import 'package:flutter/material.dart';
import '../logic/strategy_evaluator.dart';
import '../models/hand.dart';
import '../models/playing_card.dart';

/// ベーシックストラテジーの早見表を表示するウィジェット。
class StrategyChartWidget extends StatefulWidget {
  final Hand? playerHand;
  final PlayingCard? dealerUpCard;

  const StrategyChartWidget({Key? key, this.playerHand, this.dealerUpCard})
    : super(key: key);

  @override
  State<StrategyChartWidget> createState() => _StrategyChartWidgetState();
}

class _StrategyChartWidgetState extends State<StrategyChartWidget> {
  late int _initialIndex;

  @override
  void initState() {
    super.initState();
    _initialIndex = _getInitialTabIndex();
  }

  int _getInitialTabIndex() {
    if (widget.playerHand == null) return 0;
    if (widget.playerHand!.canSplit) return 2; // Pairs
    if (widget.playerHand!.isSoftHand) return 1; // Soft
    return 0; // Hard
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _initialIndex,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75, // 少し高さを広げる
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'HARD'),
                Tab(text: 'SOFT'),
                Tab(text: 'PAIRS'),
              ],
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white70,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _StrategyTable(
                    key: const ValueKey(_TableType.hard),
                    type: _TableType.hard,
                    playerHand: widget.playerHand,
                    dealerUpCard: widget.dealerUpCard,
                  ),
                  _StrategyTable(
                    key: const ValueKey(_TableType.soft),
                    type: _TableType.soft,
                    playerHand: widget.playerHand,
                    dealerUpCard: widget.dealerUpCard,
                  ),
                  _StrategyTable(
                    key: const ValueKey(_TableType.pairs),
                    type: _TableType.pairs,
                    playerHand: widget.playerHand,
                    dealerUpCard: widget.dealerUpCard,
                  ),
                ],
              ),
            ),
            _Legend(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

enum _TableType { hard, soft, pairs }

class _StrategyTable extends StatelessWidget {
  final _TableType type;
  final Hand? playerHand;
  final PlayingCard? dealerUpCard;

  const _StrategyTable({
    Key? key,
    required this.type,
    this.playerHand,
    this.dealerUpCard,
  }) : super(key: key);

  bool _isCurrentCell(dynamic playerVal, int dealerVal) {
    if (playerHand == null || dealerUpCard == null) return false;
    if (dealerUpCard!.value != dealerVal) return false;

    final total = playerHand!.totalScore;

    switch (type) {
      case _TableType.hard:
        if (playerHand!.isSoftHand || playerHand!.canSplit) return false;
        if (playerVal == 8) return total <= 8;
        if (playerVal == 17) return total >= 17;
        return total == playerVal;
      case _TableType.soft:
        return playerHand!.isSoftHand && total == playerVal;
      case _TableType.pairs:
        return playerHand!.canSplit &&
            playerHand!.cards[0].rank == _getRank(playerVal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dealerCards = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]; // 11 is Ace
    final rows = _getRows();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Table(
            // 全11列（ラベル+ディーラー10枚）の幅を固定してレイアウト崩れを防ぐ
            defaultColumnWidth: const FixedColumnWidth(40),
            columnWidths: const {0: FixedColumnWidth(70)},
            border: TableBorder.all(color: Colors.white10, width: 0.5),
            children: [
              // Header Row
              TableRow(
                children: [
                  _HeaderCell(''),
                  for (var d in dealerCards) _HeaderCell(d == 11 ? 'A' : '$d'),
                ],
              ),
              // Data Rows
              for (var row in rows)
                TableRow(
                  children: [
                    _RowLabelCell(row.label),
                    for (var d in dealerCards)
                      _ActionCell(
                        _getAction(row.value, d),
                        isCurrent: _isCurrentCell(row.value, d),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_RowData> _getRows() {
    switch (type) {
      case _TableType.hard:
        return [
          _RowData('8以下', 8),
          for (int i = 9; i <= 16; i++) _RowData('$i', i),
          _RowData('17以上', 17),
        ];
      case _TableType.soft:
        return [for (int i = 13; i <= 20; i++) _RowData('A,${i - 11}', i)];
      case _TableType.pairs:
        return [
          for (int i = 2; i <= 10; i++) _RowData('$i,$i', i),
          _RowData('A,A', 11),
        ];
    }
  }

  BlackjackAction _getAction(dynamic playerVal, int dealerVal) {
    final dCard = PlayingCard(
      id: 'mock_dealer',
      suit: Suit.spades,
      rank: _getRank(dealerVal),
    );

    if (type == _TableType.pairs) {
      final rank = _getRank(playerVal as int);
      final pHand = Hand(
        cards: [
          PlayingCard(id: 'mock_p1', suit: Suit.hearts, rank: rank),
          PlayingCard(id: 'mock_p2', suit: Suit.diamonds, rank: rank),
        ],
      );
      return StrategyEvaluator.getRecommendedAction(pHand, dCard);
    } else if (type == _TableType.soft) {
      final pHand = Hand(
        cards: [
          PlayingCard(id: 'mock_p1', suit: Suit.hearts, rank: Rank.ace),
          PlayingCard(
            id: 'mock_p2',
            suit: Suit.diamonds,
            rank: _getRank(playerVal - 11),
          ),
        ],
      );
      return StrategyEvaluator.getRecommendedAction(pHand, dCard);
    } else {
      // Hard
      int card1Val = (playerVal == 11)
          ? 9
          : (playerVal > 10 ? 10 : playerVal - 2);
      int card2Val = playerVal - card1Val;

      final pHand = Hand(
        cards: [
          PlayingCard(
            id: 'mock_p1',
            suit: Suit.hearts,
            rank: _getRank(card1Val),
          ),
          PlayingCard(
            id: 'mock_p2',
            suit: Suit.diamonds,
            rank: _getRank(card2Val),
          ),
        ],
      );
      return StrategyEvaluator.getRecommendedAction(pHand, dCard);
    }
  }

  Rank _getRank(int val) {
    if (val == 11 || val == 1) return Rank.ace;
    if (val == 10) return Rank.ten;
    if (val == 9) return Rank.nine;
    if (val == 8) return Rank.eight;
    if (val == 7) return Rank.seven;
    if (val == 6) return Rank.six;
    if (val == 5) return Rank.five;
    if (val == 4) return Rank.four;
    if (val == 3) return Rank.three;
    if (val == 2) return Rank.two;
    return Rank.ten;
  }
}

class _RowData {
  final String label;
  final int value;
  _RowData(this.label, this.value);
}

class _HeaderCell extends StatelessWidget {
  final String text;
  _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.black38,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RowLabelCell extends StatelessWidget {
  final String text;
  _RowLabelCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black26,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  final BlackjackAction action;
  final bool isCurrent;
  _ActionCell(this.action, {this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    String char;
    switch (action) {
      case BlackjackAction.hit:
        color = Colors.green[800]!;
        char = 'H';
        break;
      case BlackjackAction.stand:
        color = Colors.red[800]!;
        char = 'S';
        break;
      case BlackjackAction.doubleDown:
        color = Colors.blue[800]!;
        char = 'D';
        break;
      case BlackjackAction.split:
        color = Colors.orange[800]!;
        char = 'P';
        break;
      case BlackjackAction.surrender:
        color = Colors.grey[800]!;
        char = 'R';
        break;
    }

    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: color,
        border: isCurrent
            ? Border.all(color: Colors.yellowAccent, width: 3)
            : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: Colors.yellowAccent.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
          shadows: isCurrent
              ? [const Shadow(color: Colors.black, blurRadius: 2)]
              : null,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        children: [
          _LegendItem(color: Colors.green[800]!, label: 'H: Hit'),
          _LegendItem(color: Colors.red[800]!, label: 'S: Stand'),
          _LegendItem(color: Colors.blue[800]!, label: 'D: Double'),
          _LegendItem(color: Colors.orange[800]!, label: 'P: Split'),
          _LegendItem(color: Colors.grey[800]!, label: 'R: Surrender'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
