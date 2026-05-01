import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/settings_provider.dart';
import '../logic/betting_system.dart';
import '../logic/localization.dart';

/// 収支履歴をグラフ表示する画面。
class StatsScreen extends ConsumerWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations(settings.language);
    final history = settings.balanceHistory;
    final currentBalance = settings.balance;
    final initialBalance = history.isNotEmpty ? history.first : 1000;
    final profit = currentBalance - initialBalance;

    final accuracyHistory = settings.accuracyHistory;
    final totalMoves = accuracyHistory.length;
    final correctMoves = accuracyHistory.where((e) => e).length;
    final accuracyRate = totalMoves > 0
        ? (correctMoves / totalMoves * 100)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F4D19),
      appBar: AppBar(
        title: Text(l10n.get('statistics')), // I should add 'statistics' to l10n
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Stats',
            onPressed: () {
              // ... existing reset logic
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.get('reset_stats')),
                  content: Text(l10n.get('reset_desc')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.get('cancel')),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(settingsProvider.notifier).resetHistory();
                        Navigator.pop(context);
                      },
                      child: Text(
                        l10n.get('reset'),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _SummaryCards(
              initialBalance: initialBalance,
              currentBalance: currentBalance,
              profit: profit,
              accuracy: accuracyRate,
              l10n: l10n,
            ),
            const SizedBox(height: 24),

            _SectionTitle(
              title: l10n.get('profit_loss_trend'),
              icon: Icons.trending_up,
            ),
            _ChartContainer(
              child: history.length < 2
                  ? _EmptyPlaceholder()
                  : LineChart(_mainData(history)),
            ),

            const SizedBox(height: 24),
            _SectionTitle(title: l10n.get('strategy_perf'), icon: Icons.bar_chart),
            _StrategyPerformanceGrid(stats: settings.strategyStats),

            const SizedBox(height: 24),
            _SectionTitle(
              title: l10n.get('accuracy_trend'),
              icon: Icons.check_circle_outline,
            ),
            _ChartContainer(
              child: accuracyHistory.length < 5
                  ? _EmptyPlaceholder(
                      message: 'Keep playing to see accuracy trends!',
                    )
                  : LineChart(_accuracyData(accuracyHistory)),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  LineChartData _accuracyData(List<bool> history) {
    // 直近50件の移動平均を表示するなどの工夫もできるが、まずは単純にプロット
    List<FlSpot> spots = [];
    int windowSize = 10;
    for (int i = 0; i <= history.length - windowSize; i++) {
      int correct = history.sublist(i, i + windowSize).where((e) => e).length;
      spots.add(FlSpot(i.toDouble(), correct * 10.0)); // 0-100%
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (val, meta) => Text(
              '${val.toInt()}%',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.greenAccent,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.greenAccent.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  LineChartData _mainData(List<int> history) {
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i].toDouble()));
    }

    double minY = history.reduce((a, b) => a < b ? a : b).toDouble();
    double maxY = history.reduce((a, b) => a > b ? a : b).toDouble();

    // 上下に少し余裕を持たせる
    double padding = (maxY - minY) * 0.15;
    if (padding == 0) padding = 100;
    minY -= padding;
    maxY += padding;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Colors.white10, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (history.length / 5).clamp(1, double.infinity),
            getTitlesWidget: (value, meta) {
              return Text(
                'G${value.toInt()}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${(value / 1000).toStringAsFixed(1)}k',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (history.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.3),
                Colors.amber.withOpacity(0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final int initialBalance;
  final int currentBalance;
  final int profit;
  final double accuracy;
  final AppLocalizations l10n;

  const _SummaryCards({
    required this.initialBalance,
    required this.currentBalance,
    required this.profit,
    required this.accuracy,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: l10n.get('balance'),
                  value: '$currentBalance',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: l10n.get('profit'),
                  value: (profit >= 0 ? '+' : '') + '$profit',
                  color: profit >= 0 ? Colors.greenAccent : Colors.redAccent,
                  isHighlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            label: l10n.get('strategy_accuracy'),
            value: '${accuracy.toStringAsFixed(1)}%',
            color: Colors.amberAccent,
            isWide: true,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isHighlight;
  final bool isWide;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.isHighlight = false,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.white.withOpacity(0.1) : Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? color.withOpacity(0.5) : Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final Widget child;

  const _ChartContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final String message;

  const _EmptyPlaceholder({
    this.message = 'Not enough data to display graph. Play more!',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }
}

class _StrategyPerformanceGrid extends StatelessWidget {
  final Map<BettingStrategy, StrategyStats> stats;

  const _StrategyPerformanceGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.entries.map((entry) {
          final s = entry.key;
          final stat = entry.value;
          final winRate = stat.games > 0 ? (stat.wins / stat.games * 100) : 0.0;

          return Container(
            width: (MediaQuery.of(context).size.width - 44) / 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${winRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${stat.games}G',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: winRate / 100,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      winRate > 48 ? Colors.greenAccent : Colors.amberAccent,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
