import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_provider.dart';

/// Settings screen - volume control, language, credits
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _sfxVolume = 0.7;
  double _bgmVolume = 0.5;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.t('settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Audio section
                    _buildSectionHeader(s.t('audio')),
                    const SizedBox(height: 12),
                    _buildVolumeSlider(
                      label: s.t('sfx_volume'),
                      icon: Icons.volume_up,
                      value: _sfxVolume,
                      color: GameColors.accentCyan,
                      onChanged: (v) {
                        setState(() => _sfxVolume = v);
                        AudioManager.instance.setSfxVolume(v);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildVolumeSlider(
                      label: s.t('bgm_volume'),
                      icon: Icons.music_note,
                      value: _bgmVolume,
                      color: GameColors.accentGold,
                      onChanged: (v) {
                        setState(() => _bgmVolume = v);
                        AudioManager.instance.setBgmVolume(v);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Language section
                    _buildSectionHeader(s.t('language')),
                    const SizedBox(height: 12),
                    _buildLanguageSelector(ref, locale),
                    const SizedBox(height: 32),

                    // Credits section
                    _buildSectionHeader(s.t('credits')),
                    const SizedBox(height: 12),
                    _buildCreditsCard(),
                    const SizedBox(height: 32),

                    // Version
                    Center(
                      child: Text(
                        'v0.4.0 (Phase 4)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildVolumeSlider({
    required String label,
    required IconData icon,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.15),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.1),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${(value * 100).toInt()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(WidgetRef ref, Locale locale) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _buildLangOption(
            ref,
            locale,
            targetLocale: const Locale('en', 'US'),
            flag: '🇺🇸',
            name: 'English',
          ),
          _buildLangOption(
            ref,
            locale,
            targetLocale: const Locale('zh', 'TW'),
            flag: '🇹🇼',
            name: '繁體中文',
          ),
        ],
      ),
    );
  }

  Widget _buildLangOption(
    WidgetRef ref,
    Locale current, {
    required Locale targetLocale,
    required String flag,
    required String name,
  }) {
    final isSelected =
        current.languageCode == targetLocale.languageCode;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(localeProvider.notifier).setLocale(targetLocale),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? GameColors.accentGold.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: GameColors.accentGold.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? GameColors.accentGold : Colors.white54,
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Survival Roguelite',
            style: TextStyle(
              color: GameColors.accentGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Built with Flutter + Flame Engine',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          SizedBox(height: 4),
          Text(
            'State: Riverpod 3.x | Audio: flame_audio (pending)',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            'Network: WebSocket + UDP LAN Discovery',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
