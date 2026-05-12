import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// LAN discovery message types
enum LanMessageType {
  hostAnnounce,
  joinRequest,
  joinAccepted,
  joinRejected,
  gameState,
  playerInput,
  playerDisconnect,
}

/// LAN game message (serializable)
class LanMessage {
  final LanMessageType type;
  final String senderId;
  final Map<String, dynamic> payload;
  final int timestamp;

  LanMessage({
    required this.type,
    required this.senderId,
    this.payload = const {},
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'senderId': senderId,
        'payload': payload,
        'timestamp': timestamp,
      };

  factory LanMessage.fromJson(Map<String, dynamic> json) => LanMessage(
        type: LanMessageType.values[json['type'] as int],
        senderId: json['senderId'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
        timestamp: json['timestamp'] as int,
      );

  String encode() => jsonEncode(toJson());
  static LanMessage decode(String data) =>
      LanMessage.fromJson(jsonDecode(data) as Map<String, dynamic>);
}

/// LAN game session info (broadcast by host)
class LanGameSession {
  final String hostId;
  final String hostName;
  final InternetAddress hostAddress;
  final int port;
  final int currentPlayers;
  final int maxPlayers;
  final int waveNumber;

  const LanGameSession({
    required this.hostId,
    required this.hostName,
    required this.hostAddress,
    required this.port,
    this.currentPlayers = 1,
    this.maxPlayers = 4,
    this.waveNumber = 0,
  });
}

/// LAN Discovery Service
/// Uses UDP broadcast to find/announce game sessions on local network
class LanDiscoveryService {
  static const int discoveryPort = 48620;
  static const Duration broadcastInterval = Duration(seconds: 2);

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  final _sessionsController = StreamController<List<LanGameSession>>.broadcast();
  final _discoveredSessions = <String, LanGameSession>{};

  Stream<List<LanGameSession>> get sessions => _sessionsController.stream;

  /// Start listening for game session broadcasts
  Future<void> startDiscovery() async {
    _socket?.close();
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
    _socket!.broadcastEnabled = true;

    _socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram == null) return;

        try {
          final msg = LanMessage.decode(utf8.decode(datagram.data));
          if (msg.type == LanMessageType.hostAnnounce) {
            _handleHostAnnounce(msg, datagram.address);
          }
        } catch (_) {
          // Ignore malformed packets
        }
      }
    });

    // Clean stale sessions every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (_) => _cleanStaleSessions());
  }

  void _handleHostAnnounce(LanMessage msg, InternetAddress address) {
    final session = LanGameSession(
      hostId: msg.senderId,
      hostName: msg.payload['hostName'] as String? ?? 'Unknown',
      hostAddress: address,
      port: msg.payload['port'] as int? ?? 48621,
      currentPlayers: msg.payload['currentPlayers'] as int? ?? 1,
      maxPlayers: msg.payload['maxPlayers'] as int? ?? 4,
      waveNumber: msg.payload['waveNumber'] as int? ?? 0,
    );
    _discoveredSessions[msg.senderId] = session;
    _sessionsController.add(_discoveredSessions.values.toList());
  }

  void _cleanStaleSessions() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _discoveredSessions.removeWhere((_, session) {
      // Remove sessions not seen for 10 seconds
      return false; // Placeholder: need timestamp tracking
    });
    if (!_sessionsController.isClosed) {
      _sessionsController.add(_discoveredSessions.values.toList());
    }
    final _ = now; // Suppress unused warning
  }

  /// Start broadcasting as host
  Future<void> startHostBroadcast({
    required String hostId,
    required String hostName,
    required int gamePort,
    int currentPlayers = 1,
  }) async {
    _broadcastTimer?.cancel();

    final msg = LanMessage(
      type: LanMessageType.hostAnnounce,
      senderId: hostId,
      payload: {
        'hostName': hostName,
        'port': gamePort,
        'currentPlayers': currentPlayers,
        'maxPlayers': 4,
        'waveNumber': 0,
      },
    );

    _broadcastTimer = Timer.periodic(broadcastInterval, (_) {
      _socket?.send(
        utf8.encode(msg.encode()),
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );
    });
  }

  void stopBroadcast() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
  }

  Future<void> dispose() async {
    stopBroadcast();
    _socket?.close();
    await _sessionsController.close();
  }
}

/// LAN Game Host - manages WebSocket connections from clients
class LanGameHost {
  final String hostId;
  HttpServer? _server;
  final _clients = <String, WebSocket>{};
  final _messageController = StreamController<LanMessage>.broadcast();
  int _gamePort = 48621;

  LanGameHost({required this.hostId});

  Stream<LanMessage> get messages => _messageController.stream;
  int get connectedClients => _clients.length;
  int get gamePort => _gamePort;

  /// Start hosting a game
  Future<void> startHost({int port = 48621}) async {
    _gamePort = port;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    _server!.transform(WebSocketTransformer()).listen((ws) {
      _handleNewClient(ws);
    });
  }

  void _handleNewClient(WebSocket ws) {
    String? clientId;

    ws.listen(
      (data) {
        try {
          final msg = LanMessage.decode(data as String);
          clientId ??= msg.senderId;

          if (msg.type == LanMessageType.joinRequest) {
            _clients[msg.senderId] = ws;
            ws.add(LanMessage(
              type: LanMessageType.joinAccepted,
              senderId: hostId,
            ).encode());
          }

          _messageController.add(msg);
        } catch (_) {}
      },
      onDone: () {
        if (clientId != null) {
          _clients.remove(clientId);
          _messageController.add(LanMessage(
            type: LanMessageType.playerDisconnect,
            senderId: clientId!,
          ));
        }
      },
    );
  }

  /// Broadcast message to all connected clients
  void broadcast(LanMessage msg) {
    final encoded = msg.encode();
    for (final ws in _clients.values) {
      ws.add(encoded);
    }
  }

  /// Send to specific client
  void sendTo(String clientId, LanMessage msg) {
    _clients[clientId]?.add(msg.encode());
  }

  Future<void> dispose() async {
    for (final ws in _clients.values) {
      await ws.close();
    }
    _clients.clear();
    await _server?.close();
    await _messageController.close();
  }
}

/// LAN Game Client - connects to a host via WebSocket
class LanGameClient {
  final String clientId;
  WebSocket? _ws;
  final _messageController = StreamController<LanMessage>.broadcast();

  LanGameClient({required this.clientId});

  Stream<LanMessage> get messages => _messageController.stream;
  bool get isConnected => _ws != null;

  /// Connect to host
  Future<bool> connect(InternetAddress hostAddress, int port) async {
    try {
      _ws = await WebSocket.connect(
          'ws://${hostAddress.address}:$port');

      _ws!.listen(
        (data) {
          try {
            final msg = LanMessage.decode(data as String);
            _messageController.add(msg);
          } catch (_) {}
        },
        onDone: () {
          _ws = null;
        },
      );

      // Send join request
      _ws!.add(LanMessage(
        type: LanMessageType.joinRequest,
        senderId: clientId,
      ).encode());

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Send message to host
  void send(LanMessage msg) {
    _ws?.add(msg.encode());
  }

  /// Send player input
  void sendInput(Map<String, dynamic> inputData) {
    send(LanMessage(
      type: LanMessageType.playerInput,
      senderId: clientId,
      payload: inputData,
    ));
  }

  Future<void> dispose() async {
    await _ws?.close();
    await _messageController.close();
  }
}
