import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/game_state_provider.dart';
import '../logic/localization.dart';

/// 画面上部に表示される所持金と現在のベット額のパネル。
class BalanceBoardWidget extends ConsumerWidget {
  const BalanceBoardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final gameState = ref.watch(gameStateProvider);
    final l10n = AppLocalizations(settings.language);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // 20 -> 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              label: l10n.get('balance'),
              value:
                  '\$${settings.balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.green.shade700,
            ),
          ),
          Container(
            height: 40,
            width: 1.5,
            color: Colors.grey.withOpacity(0.2),
          ),
          Expanded(
            child: _InfoItem(
              label: l10n.get('current_bet'),
              value: '\$${gameState.currentBet}',
              icon: Icons.monetization_on_rounded,
              isCenter: true,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isCenter;
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4), // 8 -> 4
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade900,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
