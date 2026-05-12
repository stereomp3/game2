import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/router/app_router.dart';

/// 開始畫面
/// 包含遊戲 Logo、模擬 Google 登入動畫、開始按鈕
/// 
/// 視覺設計：
/// - 深色漸層背景 + 粒子漂浮效果
/// - 遊戲標題帶有金色光暈
/// - Google 登入按鈕模擬真實 Google Sign-In UI
class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen>
    with TickerProviderStateMixin {
  // 登入狀態
  bool _isSigningIn = false;
  bool _isSignedIn = false;
  bool _showWelcome = false;

  // 動畫控制器
  late AnimationController _titleController;
  late AnimationController _pulseController;
  late Animation<double> _titleFade;
  late Animation<double> _titleSlide;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 標題進場動畫
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    _titleSlide = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );

    // 脈動光暈動畫
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 延遲啟動標題動畫
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _titleController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// 模擬 Google 登入流程
  Future<void> _simulateGoogleSignIn() async {
    setState(() => _isSigningIn = true);

    // 模擬登入延遲
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      _isSigningIn = false;
      _isSignedIn = true;
    });

    // 顯示歡迎訊息
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showWelcome = true);
  }

  /// 進入角色選擇
  void _goToCharacterSelect() {
    Navigator.pushNamed(context, AppRouter.characterSelect);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B2838),
              Color(0xFF0A0E1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 背景裝飾粒子
              ..._buildParticles(size),

              // 主要內容
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // 遊戲標題
                    _buildTitle(s),

                    const SizedBox(height: 12),

                    // 副標題
                    AnimatedBuilder(
                      animation: _titleFade,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _titleFade.value,
                          child: Text(
                            s.t('start_subtitle'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 3,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 2),

                    // Google 登入區域
                    if (!_isSignedIn) _buildGoogleSignIn(s),

                    // 歡迎訊息 + 開始按鈕
                    if (_isSignedIn) _buildWelcomeAndStart(s),

                    // 多人遊戲按鈕
                    if (_isSignedIn && _showWelcome)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.lanLobby),
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: GameColors.accentCyan
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lan,
                                      color: GameColors.accentCyan, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.t('multiplayer'),
                                    style: const TextStyle(
                                      color: GameColors.accentCyan,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    const Spacer(flex: 1),

                    // 語言切換 + 設定
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLanguageToggle(ref),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.achievements),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: GameColors.accentGold,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.settings),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: const Icon(
                              Icons.settings,
                              color: Colors.white38,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
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

  /// 建構遊戲標題
  Widget _buildTitle(S s) {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _titleSlide.value),
          child: Opacity(
            opacity: _titleFade.value,
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  GameColors.accentGold,
                  GameColors.accentGold.withValues(alpha: _pulseAnimation.value),
                  GameColors.accentGold,
                ],
              ).createShader(bounds),
              child: Text(
                // 【素材需求】: 此處需要遊戲 Logo 圖片替換文字
                // 素材路徑: assets/images/ui/game_logo.png
                'SURVIVAL\nROGUELITE',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 建構 Google 模擬登入按鈕
  Widget _buildGoogleSignIn(S s) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _isSigningIn
          ? _buildSigningInAnimation(s)
          : _buildGoogleButton(s),
    );
  }

  /// Google 登入按鈕（模擬真實 Google Sign-In UI）
  Widget _buildGoogleButton(S s) {
    return GestureDetector(
      onTap: _simulateGoogleSignIn,
      child: Container(
        key: const ValueKey('google_btn'),
        width: 280,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Logo（程式碼繪製）
            _buildGoogleLogo(),
            const SizedBox(width: 12),
            Text(
              s.t('google_sign_in'),
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Google Logo（程式碼繪製 4 色 G）
  /// 【素材需求】: 可替換為 assets/images/ui/google_logo.png
  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }

  /// 登入中動畫
  Widget _buildSigningInAnimation(S s) {
    return Container(
      key: const ValueKey('signing_in'),
      width: 280,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(GameColors.googleBlue),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.t('signing_in'),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 歡迎訊息與開始按鈕
  Widget _buildWelcomeAndStart(S s) {
    return AnimatedOpacity(
      opacity: _showWelcome ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          // 登入成功勾選動畫
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameColors.accentGreen.withValues(alpha: 0.2),
              border: Border.all(color: GameColors.accentGreen, width: 2),
            ),
            child: const Icon(
              Icons.check,
              color: GameColors.accentGreen,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.t('sign_in_success'),
            style: const TextStyle(
              color: GameColors.accentGreen,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.t('welcome_back'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // 開始遊戲按鈕
          GestureDetector(
            onTap: _goToCharacterSelect,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 240,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        GameColors.accentGold,
                        GameColors.accentGold.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: GameColors.accentGold
                            .withValues(alpha: _pulseAnimation.value * 0.5),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      s.t('start_game'),
                      style: const TextStyle(
                        color: GameColors.backgroundDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 語言切換按鈕
  Widget _buildLanguageToggle(WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isZh = locale.languageCode == 'zh';

    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text(
              isZh ? '繁體中文' : 'English',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// 背景裝飾粒子（程式碼生成）
  List<Widget> _buildParticles(Size size) {
    // 簡易靜態粒子裝飾
    return List.generate(15, (i) {
      final x = (i * 67.0 + 30) % size.width;
      final y = (i * 83.0 + 50) % size.height;
      final opacity = 0.05 + (i % 5) * 0.03;
      final radius = 2.0 + (i % 4) * 1.5;

      return Positioned(
        left: x,
        top: y,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GameColors.accentGold.withValues(alpha: opacity),
          ),
        ),
      );
    });
  }
}

/// Google Logo 繪製器
/// 【素材需求】: 此處使用程式碼繪製的簡化 Google G Logo
/// 可替換為: assets/images/ui/google_logo.png
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 簡化版 Google G — 用四色弧線表示
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // 藍色弧線（右側）
    paint.color = GameColors.googleBlue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -0.5, 1.8, false, paint,
    );

    // 紅色弧線（上方）
    paint.color = GameColors.googleRed;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      1.3, 1.2, false, paint,
    );

    // 黃色弧線（下方）
    paint.color = GameColors.googleYellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      2.5, 1.0, false, paint,
    );

    // 綠色弧線（左側）
    paint.color = GameColors.googleGreen;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      3.5, 1.2, false, paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
