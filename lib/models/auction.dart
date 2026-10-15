import 'package:intl/intl.dart';
import 'bid.dart';
import '../utils/constants.dart';

class Auction {
  final String id;
  final String title;
  final String description;
  final String rawImageUrl;
  final num startingPrice;
  final num minIncrement;
  num currentHighestBid;
  String? currentHighestBidderId;
  String? currentHighestBidderName;
  final DateTime startTime;
  final DateTime endTime;
  String status; // 'upcoming', 'live', 'ended'
  String? winnerId;
  String? winnerName;
  final String createdById;
  final String createdByName;
  List<Bid> bids;
  String? userOutcome; // 'won', 'lost', 'winning', 'outbid'

  Auction({
    required this.id,
    required this.title,
    required this.description,
    required this.rawImageUrl,
    required this.startingPrice,
    required this.minIncrement,
    required this.currentHighestBid,
    this.currentHighestBidderId,
    this.currentHighestBidderName,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.winnerId,
    this.winnerName,
    required this.createdById,
    required this.createdByName,
    required this.bids,
    this.userOutcome,
  });

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isEnded => status == 'ended';
  bool get hasBids => bids.isNotEmpty || currentHighestBid > 0;

  List<Bid> get sortedBids {
    final list = List<Bid>.from(bids);
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  num get minRequiredBid {
    if (!hasBids) {
      return startingPrice;
    }
    return currentHighestBid + minIncrement;
  }

  String get formattedCurrentBid {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(hasBids ? currentHighestBid : startingPrice);
  }

  String get formattedStartingPrice {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(startingPrice);
  }

  String get formattedMinIncrement {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatter.format(minIncrement);
  }

  // Resolves full image URL if local uploaded path
  String get displayImageUrl {
    if (rawImageUrl.isEmpty) {
      return 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800';
    }
    if (rawImageUrl.startsWith('/uploads')) {
      return '${AppConstants.defaultBaseUrl}$rawImageUrl';
    }
    return rawImageUrl;
  }

  factory Auction.fromJson(Map<String, dynamic> json) {
    String highestBidderId = '';
    String? highestBidderName;
    if (json['currentHighestBidder'] is Map) {
      highestBidderId = json['currentHighestBidder']['_id'] ?? json['currentHighestBidder']['id'] ?? '';
      highestBidderName = json['currentHighestBidder']['name'];
    } else if (json['currentHighestBidder'] is String) {
      highestBidderId = json['currentHighestBidder'];
    }

    String winnerId = '';
    String? winnerName;
    if (json['winner'] is Map) {
      winnerId = json['winner']['_id'] ?? json['winner']['id'] ?? '';
      winnerName = json['winner']['name'];
    } else if (json['winner'] is String) {
      winnerId = json['winner'];
    }

    String createdById = '';
    String createdByName = 'Admin';
    if (json['createdBy'] is Map) {
      createdById = json['createdBy']['_id'] ?? json['createdBy']['id'] ?? '';
      createdByName = json['createdBy']['name'] ?? 'Admin';
    } else if (json['createdBy'] is String) {
      createdById = json['createdBy'];
    }

    final rawBids = json['bids'];
    List<Bid> bidsList = [];
    if (rawBids is List) {
      bidsList = rawBids.map((b) => Bid.fromJson(b as Map<String, dynamic>)).toList();
      // Always sort bids in decreasing order (highest bid first)
      bidsList.sort((a, b) => b.amount.compareTo(a.amount));
    }

    return Auction(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      rawImageUrl: json['imageUrl'] ?? '',
      startingPrice: json['startingPrice'] ?? 0,
      minIncrement: json['minIncrement'] ?? 1,
      currentHighestBid: json['currentHighestBid'] ?? 0,
      currentHighestBidderId: highestBidderId.isNotEmpty ? highestBidderId : null,
      currentHighestBidderName: highestBidderName,
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      status: json['status'] ?? 'upcoming',
      winnerId: winnerId.isNotEmpty ? winnerId : null,
      winnerName: winnerName,
      createdById: createdById,
      createdByName: createdByName,
      bids: bidsList,
      userOutcome: json['userOutcome'],
    );
  }
}
