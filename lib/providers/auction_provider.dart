import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuctionProvider extends ChangeNotifier {
  final ApiService _apiService;
  final SocketService _socketService;

  List<Auction> _auctions = [];
  Auction? _selectedAuction;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilter = 'live'; // 'live', 'upcoming', 'ended', 'my_bids'
  Timer? _keepAliveTimer;

  AuctionProvider(this._apiService, this._socketService) {
    _initSocketListeners();
    // ping backend every 4 minutes (under 5 mins) so render stays awake
    _startKeepAliveTimer();
  }

  List<Auction> get auctions => _auctions;
  Auction? get selectedAuction => _selectedAuction;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  void setFilter(String filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      fetchAuctions();
    }
  }

  void _initSocketListeners() {
    // 1. Real-time new bid
    _socketService.addNewBidListener((data) {
      final auctionId = data['auctionId'];
      final num highestBid = data['currentHighestBid'] ?? 0;
      final bidderName = data['currentHighestBidder']?['name'];
      final bidderId = data['currentHighestBidder']?['_id'];

      // Update in selected auction view
      if (_selectedAuction != null && _selectedAuction!.id == auctionId) {
        _selectedAuction!.currentHighestBid = highestBid;
        _selectedAuction!.currentHighestBidderName = bidderName;
        _selectedAuction!.currentHighestBidderId = bidderId;

        if (data['bid'] != null) {
          final newBid = Bid.fromJson(Map<String, dynamic>.from(data['bid']));
          // Prevent duplicate if already inserted
          if (!_selectedAuction!.bids.any((b) => b.id == newBid.id)) {
            _selectedAuction!.bids.insert(0, newBid);
            _selectedAuction!.bids.sort((a, b) => b.amount.compareTo(a.amount));
          }
        }
        notifyListeners();
      }

      // Update in listing
      final index = _auctions.indexWhere((a) => a.id == auctionId);
      if (index != -1) {
        _auctions[index].currentHighestBid = highestBid;
        _auctions[index].currentHighestBidderName = bidderName;
        _auctions[index].currentHighestBidderId = bidderId;
        notifyListeners();
      }
    });

    // 2. Real-time auction status updates / completion
    _socketService.addAuctionEndedListener((data) {
      final auctionId = data['auctionId'];
      final winner = data['winner'];

      if (_selectedAuction != null && _selectedAuction!.id == auctionId) {
        _selectedAuction!.status = 'ended';
        if (winner != null) {
          _selectedAuction!.winnerName = winner['name'];
          _selectedAuction!.winnerId = winner['id'];
        }
        notifyListeners();
      }

      final index = _auctions.indexWhere((a) => a.id == auctionId);
      if (index != -1) {
        _auctions[index].status = 'ended';
        if (winner != null) {
          _auctions[index].winnerName = winner['name'];
          _auctions[index].winnerId = winner['id'];
        }
        notifyListeners();
      }
    });
  }

  // Fetch auctions based on current active tab
  Future<void> fetchAuctions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_currentFilter == 'my_bids') {
        _auctions = await _apiService.getAuctions(myBids: true);
      } else {
        _auctions = await _apiService.getAuctions(status: _currentFilter);
      }
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load auctions. Check your connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load single auction for details screen
  Future<void> loadAuctionDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedAuction = await _apiService.getAuctionById(id);
      // Join socket room for this auction
      _socketService.joinAuction(id);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Could not load auction details.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void leaveAuctionDetails() {
    if (_selectedAuction != null) {
      _socketService.leaveAuction(_selectedAuction!.id);
      _selectedAuction = null;
    }
  }

  // Place a bid
  Future<Map<String, dynamic>> placeBid(num amount) async {
    if (_selectedAuction == null) {
      return {'success': false, 'message': 'No active auction selected'};
    }

    try {
      final updated = await _apiService.placeBid(_selectedAuction!.id, amount);
      _selectedAuction = updated;

      // Update listing
      final index = _auctions.indexWhere((a) => a.id == updated.id);
      if (index != -1) {
        _auctions[index] = updated;
      }

      notifyListeners();
      return {'success': true, 'message': 'Bid placed successfully!'};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Failed to place bid. Please try again.'};
    }
  }

  // Create auction (Admin)
  Future<Map<String, dynamic>> createAuction({
    required String title,
    required String description,
    required num startingPrice,
    required num minIncrement,
    required DateTime startTime,
    required DateTime endTime,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageUrlFallback,
  }) async {
    try {
      final created = await _apiService.createAuction(
        title: title,
        description: description,
        startingPrice: startingPrice,
        minIncrement: minIncrement,
        startTime: startTime,
        endTime: endTime,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
        imageUrlFallback: imageUrlFallback,
      );

      // Refresh list
      await fetchAuctions();
      return {'success': true, 'message': 'Auction created successfully!', 'auction': created};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create auction: $e'};
    }
  }

  // ping backend every 4 minutes (under 5 mins) so render stays awake
  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 4), (_) {
      _apiService.checkHealth();
    });
  }

  @override
  void dispose() {
    _keepAliveTimer?.cancel();
    super.dispose();
  }
}
