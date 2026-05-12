import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/color_palette.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/locale_provider.dart';
import '../infrastructure/lan_service.dart';

/// LAN lobby screen - host or join local multiplayer sessions
class LanLobbyScreen extends ConsumerStatefulWidget {
  const LanLobbyScreen({super.key});

  @override
  ConsumerState<LanLobbyScreen> createState() => _LanLobbyScreenState();
}

class _LanLobbyScreenState extends ConsumerState<LanLobbyScreen> {
  final _discovery = LanDiscoveryService();
  final _playerId = 'player_${Random().nextInt(99999)}';
  List<LanGameSession> _sessions = [];
  bool _isSearching = false;
  bool _isHosting = false;
  StreamSubscription? _sessionSub;

  LanGameHost? _host;
  LanGameClient? _client;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _discovery.dispose();
    _host?.dispose();
    _client?.dispose();
    super.dispose();
  }

  Future<void> _startSearch() async {
    setState(() => _isSearching = true);
    await _discovery.startDiscovery();
    _sessionSub = _discovery.sessions.listen((sessions) {
      if (mounted) setState(() => _sessions = sessions);
    });
  }

  Future<void> _hostGame() async {
    setState(() => _isHosting = true);
    _host = LanGameHost(hostId: _playerId);
    await _host!.startHost();
    await _discovery.startDiscovery();
    await _discovery.startHostBroadcast(
      hostId: _playerId,
      hostName: 'Player',
      gamePort: _host!.gamePort,
    );
  }

  Future<void> _joinSession(LanGameSession session) async {
    _client = LanGameClient(clientId: _playerId);
    final success =
        await _client!.connect(session.hostAddress, session.port);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed')),
        );
      }
    }
  }

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
                      s.t('lan_lobby'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.wifi_tethering,
                        label: s.t('host_game'),
                        color: GameColors.accentGold,
                        onTap: _isHosting ? null : _hostGame,
                        isActive: _isHosting,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.search,
                        label: s.t('find_games'),
                        color: GameColors.accentCyan,
                        onTap: _isSearching ? null : _startSearch,
                        isActive: _isSearching,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Status
              if (_isHosting)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GameColors.accentGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: GameColors.accentGold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_tethering,
                          color: GameColors.accentGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${s.t("hosting")} - ${_host?.connectedClients ?? 0} ${s.t("players")}',
                        style: const TextStyle(
                          color: GameColors.accentGold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Session list
              Expanded(
                child: _sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSearching
                                  ? Icons.wifi_find
                                  : Icons.lan_outlined,
                              color: Colors.white24,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching
                                  ? s.t('searching')
                                  : s.t('lan_hint'),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) =>
                            _buildSessionCard(_sessions[index], s),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? color : Colors.white54, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(LanGameSession session, S s) {
    return GestureDetector(
      onTap: () => _joinSession(session),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GameColors.accentCyan.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.computer,
                color: GameColors.accentCyan, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.hostName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.currentPlayers}/${session.maxPlayers} ${s.t("players")}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GameColors.accentCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.t('join'),
                style: const TextStyle(
                  color: GameColors.accentCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
