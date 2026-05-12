import 'package:flutter/material.dart';
import '../../features/auth/presentation/start_screen.dart';
import '../../features/character_select/presentation/character_select_screen.dart';
import '../../features/gameplay/presentation/gameplay_screen.dart';
import '../../features/gameplay/presentation/augment_select_screen.dart';
import '../../features/gameplay/presentation/game_over_screen.dart';
import '../../features/multiplayer/presentation/lan_lobby_screen.dart';
import '../../features/progression/presentation/achievements_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shop/presentation/shop_screen.dart';

/// 場景路由管理器
/// 路由流程：Start → Character Select → Gameplay ↔ Shop (循環)
///
/// 設計決策：使用 onGenerateRoute 命名路由模式，
/// 相比 Navigator 2.0 更簡潔，且遊戲場景流程為線性，不需要複雜的深度連結
class AppRouter {
  AppRouter._();

  // ===== 路由名稱定義 =====
  static const String startScreen = '/';
  static const String characterSelect = '/character-select';
  static const String gameplay = '/gameplay';
  static const String shop = '/shop';
  static const String augmentSelect = '/augment-select';
  static const String gameOver = '/game-over';
  static const String lanLobby = '/lan-lobby';
  static const String settings = '/settings';
  static const String achievements = '/achievements';

  /// 路由生成器
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case startScreen:
        return _buildRoute(
          const StartScreen(),
          settings,
          transitionType: _TransitionType.fade,
        );

      case characterSelect:
        return _buildRoute(
          const CharacterSelectScreen(),
          settings,
          transitionType: _TransitionType.slideUp,
        );

      case gameplay:
        // 從 arguments 取得選中的角色 ID
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          GameplayScreen(
            characterId: args?['characterId'] as String? ?? 'novice',
            waveNumber: args?['waveNumber'] as int? ?? 1,
          ),
          settings,
          transitionType: _TransitionType.fade,
        );

      case shop:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ShopScreen(
            waveNumber: args?['waveNumber'] as int? ?? 1,
            goldAmount: args?['gold'] as int? ?? 0,
            characterId: args?['characterId'] as String? ?? 'novice',
          ),
          settings,
          transitionType: _TransitionType.slideUp,
        );

      case augmentSelect:
        return _buildRoute(
          const AugmentSelectScreen(),
          settings,
          transitionType: _TransitionType.fade,
        );

      case gameOver:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          GameOverScreen(
            waveReached: args?['waveReached'] as int? ?? 1,
            totalKills: args?['totalKills'] as int? ?? 0,
            levelReached: args?['levelReached'] as int? ?? 1,
          ),
          settings,
          transitionType: _TransitionType.fade,
        );

      case lanLobby:
        return _buildRoute(
          const LanLobbyScreen(),
          settings,
          transitionType: _TransitionType.slideUp,
        );

      case AppRouter.settings:
        return _buildRoute(
          const SettingsScreen(),
          settings,
          transitionType: _TransitionType.slideUp,
        );

      case AppRouter.achievements:
        return _buildRoute(
          const AchievementsScreen(),
          settings,
          transitionType: _TransitionType.slideUp,
        );

      default:
        return _buildRoute(
          const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
          settings,
        );
    }
  }

  /// 建構帶有過渡動畫的路由
  static Route<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings, {
    _TransitionType transitionType = _TransitionType.fade,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (transitionType) {
          case _TransitionType.fade:
            return FadeTransition(opacity: animation, child: child);

          case _TransitionType.slideUp:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );

          case _TransitionType.slideRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
        }
      },
    );
  }
}

/// 路由過渡動畫類型
enum _TransitionType {
  fade,
  slideUp,
  slideRight,
}
