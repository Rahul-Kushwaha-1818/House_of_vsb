import 'package:flutter_test/flutter_test.dart';
import 'package:first_app/models/user.dart';
import 'package:first_app/models/bid.dart';
import 'package:first_app/models/auction.dart';
import 'package:first_app/models/app_notification.dart';

void main() {
  group('User Model Tests', () {
    test('Correctly deserializes user with admin role', () {
      final json = {
        '_id': '12345',
        'name': 'Auction Admin',
        'email': 'admin@auction.com',
        'role': 'admin',
      };
      final user = AppUser.fromJson(json);

      expect(user.id, '12345');
      expect(user.name, 'Auction Admin');
      expect(user.email, 'admin@auction.com');
      expect(user.isAdmin, isTrue);
    });

    test('Correctly deserializes user with regular user role', () {
      final json = {
        '_id': '67890',
        'name': 'Alice Walker',
        'email': 'alice@auction.com',
        'role': 'user',
      };
      final user = AppUser.fromJson(json);

      expect(user.isAdmin, isFalse);
    });
  });

  group('Auction Model Bidding Logic Tests', () {
    test('Requires starting price when no bids have been placed', () {
      final auction = Auction(
        id: 'auc1',
        title: 'Vintage Watch',
        description: 'Test watch',
        rawImageUrl: '',
        startingPrice: 500,
        minIncrement: 25,
        currentHighestBid: 0,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        status: 'live',
        createdById: 'admin1',
        createdByName: 'Admin',
        bids: [],
      );

      expect(auction.hasBids, isFalse);
      expect(auction.minRequiredBid, 500);
      expect(auction.isLive, isTrue);
      expect(auction.isEnded, isFalse);
    });

    test('Requires currentHighestBid + minIncrement when bids exist', () {
      final auction = Auction(
        id: 'auc2',
        title: 'Vintage Watch',
        description: 'Test watch',
        rawImageUrl: '',
        startingPrice: 500,
        minIncrement: 50,
        currentHighestBid: 600,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        status: 'live',
        createdById: 'admin1',
        createdByName: 'Admin',
        bids: [
          Bid(
            id: 'bid1',
            amount: 600,
            bidderId: 'user1',
            bidderName: 'Alice',
            bidderEmail: 'alice@test.com',
            createdAt: DateTime.now(),
          ),
        ],
      );

      expect(auction.hasBids, isTrue);
      expect(auction.minRequiredBid, 650); // 600 + 50
    });

    test('Bids are always sorted in decreasing order (highest first)', () {
      final json = {
        '_id': 'auc3',
        'title': 'Test Item',
        'description': 'Description',
        'startingPrice': 500,
        'minIncrement': 50,
        'currentHighestBid': 1011,
        'startTime': DateTime.now().toIso8601String(),
        'endTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'status': 'live',
        'bids': [
          {'amount': 850, 'bidder': {'name': 'Bob'}},
          {'amount': 911, 'bidder': {'name': 'Alice'}},
          {'amount': 961, 'bidder': {'name': 'Diana'}},
          {'amount': 1011, 'bidder': {'name': 'Ethan'}},
        ],
      };
      final auction = Auction.fromJson(json);

      expect(auction.sortedBids.length, 4);
      expect(auction.sortedBids[0].amount, 1011);
      expect(auction.sortedBids[0].bidderName, 'Ethan');
      expect(auction.sortedBids[1].amount, 961);
      expect(auction.sortedBids[2].amount, 911);
      expect(auction.sortedBids[3].amount, 850);
      expect(auction.sortedBids[3].bidderName, 'Bob');
    });

    test('Auction.fromJson maps UTC ISO strings to local DateTime without offset skew', () {
      final nowUtc = DateTime.now().toUtc();
      final json = {
        '_id': 'auc_tz',
        'title': 'Timezone Test Auction',
        'description': 'Testing UTC to local mapping',
        'startingPrice': 100,
        'minIncrement': 10,
        'currentHighestBid': 0,
        'startTime': nowUtc.toIso8601String(),
        'endTime': nowUtc.add(const Duration(hours: 2)).toIso8601String(),
        'status': 'live',
        'bids': [],
      };
      final auction = Auction.fromJson(json);

      expect(auction.startTime.isUtc, isFalse);
      expect(auction.endTime.isUtc, isFalse);
      // Difference between auction.startTime and local now should be within 2 seconds
      final diff = auction.startTime.difference(DateTime.now()).inSeconds.abs();
      expect(diff <= 2, isTrue);
    });
  });

  group('AppNotification Model Tests', () {
    test('Correctly deserializes outbid notification', () {
      final json = {
        '_id': 'notif1',
        'title': '⚠️ Outbid Alert!',
        'body': 'Someone placed a higher bid of \$750 on Vintage Watch.',
        'type': 'outbid',
        'auctionId': 'auc123',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif1');
      expect(notif.isOutbid, isTrue);
      expect(notif.isWon, isFalse);
      expect(notif.isRead, isFalse);
      expect(notif.auctionId, 'auc123');
      expect(notif.timeAgo, '5m ago');
    });

    test('Correctly deserializes won notification', () {
      final json = {
        '_id': 'notif2',
        'title': '🏆 You Won!',
        'body': 'Congratulations! You won the auction.',
        'type': 'won',
        'auctionId': 'auc456',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(seconds: 30)).toIso8601String(),
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.isWon, isTrue);
      expect(notif.isOutbid, isFalse);
      expect(notif.isRead, isTrue);
      expect(notif.timeAgo, 'Just now');
    });
  });
}
