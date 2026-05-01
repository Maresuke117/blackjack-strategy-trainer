import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_screen.dart';
import '../providers/game_state_provider.dart';
import '../providers/settings_provider.dart';
import '../logic/localization.dart';

/// アプリのメインメニュー画面。
/// モード選択（練習、通常、スイッチ、フリーベット）を行う。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations(settings.language);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E9), // Soft Green
              Color(0xFFC8E6C9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Language Switcher
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: DropdownButton<AppLanguage>(
                        value: settings.language,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.language, color: Colors.green),
                        items: AppLanguage.values.map((l) {
                          return DropdownMenuItem(
                            value: l,
                            child: Text(
                              l == AppLanguage.en ? 'English' : '日本語',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateLanguage(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.casino,
                            size: 60,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'BLACKJACK',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        Text(
                          l10n.get('strategy').toUpperCase(),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 50),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _MenuButton(
                                  title: l10n.get('menu_practice_title'),
                                  subtitle: l10n.get('menu_practice_sub'),
                                  icon: Icons.school,
                                  color: const Color(0xFF78909C), // シルバー/ブルーグレー
                                  onTap: () {
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setPracticeMode(true);
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setSwitchMode(false);
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setFreeBetMode(false);
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .startDeal();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const GameScreen(title: 'Practice'),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _MenuButton(
                                  title: l10n.get('menu_standard_title'),
                                  subtitle: l10n.get('menu_standard_sub'),
                                  icon: Icons.play_arrow_rounded,
                                  color: const Color(0xFF2E7D32), // カジノグリーン
                                  onTap: () {
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setPracticeMode(false);
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setSwitchMode(false);
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setFreeBetMode(false);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const GameScreen(title: 'Standard'),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _MenuButton(
                                  title: l10n.get('menu_switch_title'),
                                  subtitle: l10n.get('menu_switch_sub'),
                                  icon: Icons.swap_horiz_rounded,
                                  color: const Color(0xFF6B0F1A), // リッチな高級ワインレッド
                                  onTap: () {
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setPracticeMode(false);
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setSwitchMode(true);
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setFreeBetMode(false);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const GameScreen(title: 'Switch'),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _MenuButton(
                                  title: l10n.get('menu_freebet_title'),
                                  subtitle: l10n.get('menu_freebet_sub'),
                                  icon: Icons.card_giftcard_rounded,
                                  color: const Color(0xFF1976D2), // ブルー
                                  onTap: () {
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setPracticeMode(false);
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setSwitchMode(false);
                                    ref
                                        .read(gameStateProvider.notifier)
                                        .setFreeBetMode(true);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const GameScreen(title: 'Free Bet'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: color.withOpacity(0.08),
            highlightColor: color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                // カラーアクセントバー
                Container(
                  width: 5,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, color.withOpacity(0.4)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withOpacity(0.15),
                                color.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: color.withOpacity(0.4),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
