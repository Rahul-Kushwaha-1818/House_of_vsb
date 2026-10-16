import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../utils/constants.dart';

typedef NewBidCallback = void Function(Map<String, dynamic> data);
typedef AuctionUpdatedCallback = void Function(Map<String, dynamic> data);
typedef AuctionEndedCallback = void Function(Map<String, dynamic> data);

class SocketService {
  socket_io.Socket? _socket;
  String _socketUrl = AppConstants.defaultSocketUrl;
  bool _isConnected = false;
  bool _hasLoggedConnectionError = false;

  bool get isConnected => _isConnected;

  // Callbacks
  final List<NewBidCallback> _newBidListeners = [];
  final List<AuctionUpdatedCallback> _auctionUpdatedListeners = [];
  final List<AuctionEndedCallback> _auctionEndedListeners = [];

  void setUrl(String url) {
    if (_socketUrl != url) {
      _socketUrl = url;
      disconnect();
      connect();
    }
  }

  void connect() {
    if (_socket != null && _socket!.connected) return;

    try {
      final builder = socket_io.OptionBuilder()
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(3000)
          .setReconnectionDelayMax(10000)
          .setReconnectionAttempts(10);

      // On Web, socket.io starts with polling and upgrades to websocket for reliable CORS handling
      if (kIsWeb) {
        builder.setTransports(['polling', 'websocket']);
      } else {
        builder.setTransports(['websocket', 'polling']);
      }

      _socket = socket_io.io(_socketUrl, builder.build());

      _socket!.onConnect((_) {
        _isConnected = true;
        _hasLoggedConnectionError = false;
        debugPrint('[Socket] Connected to $_socketUrl');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('[Socket] Disconnected');
      });

      _socket!.onConnectError((err) {
        _isConnected = false;
        if (!_hasLoggedConnectionError) {
          _hasLoggedConnectionError = true;
          debugPrint('[Socket] Backend server is currently not reachable at $_socketUrl. Retrying in background...');
        }
      });

      // Listen for events
      _socket!.on('new_bid', (data) {
        if (data is Map) {
          final mapped = Map<String, dynamic>.from(data);
          for (var listener in _newBidListeners) {
            listener(mapped);
          }
        }
      });

      _socket!.on('auction_updated', (data) {
        if (data is Map) {
          final mapped = Map<String, dynamic>.from(data);
          for (var listener in _auctionUpdatedListeners) {
            listener(mapped);
          }
        }
      });

      _socket!.on('auction_ended', (data) {
        if (data is Map) {
          final mapped = Map<String, dynamic>.from(data);
          for (var listener in _auctionEndedListeners) {
            listener(mapped);
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('[Socket] Init error: $e');
      }
    }
  }

  void joinAuction(String auctionId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_auction', auctionId);
    }
  }

  void leaveAuction(String auctionId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_auction', auctionId);
    }
  }

  void addNewBidListener(NewBidCallback listener) {
    _newBidListeners.add(listener);
  }

  void removeNewBidListener(NewBidCallback listener) {
    _newBidListeners.remove(listener);
  }

  void addAuctionUpdatedListener(AuctionUpdatedCallback listener) {
    _auctionUpdatedListeners.add(listener);
  }

  void removeAuctionUpdatedListener(AuctionUpdatedCallback listener) {
    _auctionUpdatedListeners.remove(listener);
  }

  void addAuctionEndedListener(AuctionEndedCallback listener) {
    _auctionEndedListeners.add(listener);
  }

  void removeAuctionEndedListener(AuctionEndedCallback listener) {
    _auctionEndedListeners.remove(listener);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
