import 'package:flutter/material.dart';
import '../models/playing_card.dart';

/// カード1枚を描画するウィジェット。
class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isHidden;

  const PlayingCardWidget({Key? key, required this.card, this.isHidden = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value * 300, value * -300),
          child: Transform.rotate(angle: value * 0.5, child: child),
        );
      },
      child: Container(
        width: 60,
        height: 90,
        decoration: BoxDecoration(
          color: isHidden ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
          border: isHidden
              ? Border.all(color: const Color(0xFF3A3A5C), width: 1.5)
              : Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isHidden ? _buildBackSide() : _buildFrontSide(),
        ),
      ),
    );
  }

  /// カード裏面：ダイヤモンドパターンで高級感を演出。
  Widget _buildBackSide() {
    return Stack(
      children: [
        // ダイヤモンドパターン背景
        CustomPaint(
          size: const Size(60, 90),
          painter: _DiamondPatternPainter(),
        ),
        // 中央のアクセント
        Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '♠',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrontSide() {
    final color = (card.suit == Suit.hearts || card.suit == Suit.diamonds)
        ? const Color(0xFFFF3B30) // iOS Red
        : const Color(0xFF1C1C1E); // iOS Dark

    return Stack(
      children: [
        Positioned(
          top: 6,
          left: 6,
          child: Column(
            children: [
              Text(
                _getRankString(card.rank),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1.0,
                ),
              ),
              Text(
                _getSuitSymbol(card.suit),
                style: TextStyle(color: color, fontSize: 12, height: 1.0),
              ),
            ],
          ),
        ),
        Center(
          child: Text(
            _getSuitSymbol(card.suit),
            style: TextStyle(color: color, fontSize: 40),
          ),
        ),
        // 光沢オーバーレイ
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.03),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRankString(Rank rank) {
    switch (rank) {
      case Rank.ace:
        return 'A';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      default:
        return (rank.index + 1).toString();
    }
  }

  String _getSuitSymbol(Suit suit) {
    switch (suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
    }
  }
}

/// カード裏面のダイヤモンド格子模様を描画するペインター。
class _DiamondPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A2A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 8.0;

    // 斜め線（右下方向）
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // 斜め線（左下方向）
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i + size.height, 0),
        Offset(i, size.height),
        paint,
      );
    }

    // 枠内のボーダー（マージン付き）
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      const Radius.circular(6),
    );
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
