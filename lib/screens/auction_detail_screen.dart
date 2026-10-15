import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/auction.dart';
import '../providers/auction_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/bid_history_tile.dart';
import '../widgets/quick_bid_sheet.dart';

class AuctionDetailScreen extends StatefulWidget {
  final String auctionId;

  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuctionProvider>().loadAuctionDetails(widget.auctionId);
    });
  }

  @override
  void dispose() {
    // Leave socket room when closing screen
    context.read<AuctionProvider>().leaveAuctionDetails();
    super.dispose();
  }

  Widget _buildOutcomeBanner(Auction auction, String currentUserId) {
    if (auction.userOutcome == null) return const SizedBox.shrink();

    Color bg;
    Color border;
    IconData icon;
    String title;
    String subtitle;

    switch (auction.userOutcome) {
      case 'won':
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFF59E0B);
        icon = Icons.emoji_events;
        title = 'Congratulations, You Won! 🏆';
        subtitle = 'You had the highest bid when the auction ended.';
        break;
      case 'winning':
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFF10B981);
        icon = Icons.verified;
        title = 'You are the highest bidder!';
        subtitle = 'Keep an eye on the countdown until the auction ends.';
        break;
      case 'outbid':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFEF4444);
        icon = Icons.warning_amber_rounded;
        title = 'You were outbid!';
        subtitle = 'Place a higher bid now to take back the lead.';
        break;
      case 'lost':
        bg = Colors.grey.shade100;
        border = Colors.grey.shade400;
        icon = Icons.info_outline;
        title = 'Auction Ended';
        subtitle = 'Another bidder placed a higher winning bid.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: border, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuctionProvider>();
    final auth = context.watch<AuthProvider>();
    final auction = provider.selectedAuction;
    final currentUserId = auth.user?.id ?? '';

    if (provider.isLoading && auction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.errorMessage != null && auction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(provider.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadAuctionDetails(widget.auctionId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (auction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction Details')),
        body: const Center(child: Text('Auction not found')),
      );
    }

    final isLeader = auction.currentHighestBidderId == currentUserId;
    final canBid = auction.isLive && !auth.isAdmin && !isLeader;

    return Scaffold(
      appBar: AppBar(
        title: Text(auction.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadAuctionDetails(widget.auctionId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                auction.displayImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey)),
                ),
              ),
            ),

            // Outcome Alert Banner (if user participated)
            _buildOutcomeBanner(auction, currentUserId),

            // Header Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Timer Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: auction.isLive
                              ? Colors.green.shade50
                              : (auction.isUpcoming ? Colors.orange.shade50 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: auction.isLive
                                ? Colors.green.shade600
                                : (auction.isUpcoming ? Colors.orange.shade600 : Colors.grey.shade400),
                          ),
                        ),
                        child: Text(
                          auction.isLive ? '● LIVE AUCTION' : (auction.isUpcoming ? 'UPCOMING' : 'AUCTION ENDED'),
                          style: TextStyle(
                            color: auction.isLive
                                ? Colors.green.shade700
                                : (auction.isUpcoming ? Colors.orange.shade800 : Colors.grey.shade700),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (auction.isLive)
                        CountdownTimerWidget(
                          targetTime: auction.endTime,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        )
                      else if (auction.isUpcoming)
                        CountdownTimerWidget(
                          targetTime: auction.startTime,
                          isStartTime: true,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    auction.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Current Highest Bid Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auction.hasBids ? 'Current Highest Bid' : 'Starting Price',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auction.formattedCurrentBid,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                            if (auction.currentHighestBidderName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                isLeader
                                    ? 'Leading bidder: You'
                                    : 'Leading bidder: ${auction.currentHighestBidderName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isLeader ? AppTheme.success : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Min Increment',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              auction.formattedMinIncrement,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Starting: ${auction.formattedStartingPrice}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Winner section if ended
                  if (auction.isEnded)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: auction.winnerName != null ? const Color(0xFFFEF3C7) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: auction.winnerName != null ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            auction.winnerName != null ? Icons.emoji_events : Icons.remove_circle_outline,
                            color: auction.winnerName != null ? const Color(0xFFB45309) : Colors.grey.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auction.winnerName != null ? 'Winning Bidder' : 'Auction Closed',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  auction.winnerName != null
                                      ? '${auction.winnerName} won with ${auction.formattedCurrentBid}'
                                      : 'No bids were placed. Item remained unsold.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Description
                  const Text(
                    'Item Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    auction.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // Dates Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Start Time:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            Text(
                              DateFormat('MMM d, y • h:mm a').format(auction.startTime),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('End Time:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            Text(
                              DateFormat('MMM d, y • h:mm a').format(auction.endTime),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bid History Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Live Bid History',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${auction.bids.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (auction.isLive)
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Real-time',
                              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bid History List
                  if (auction.bids.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.gavel_outlined, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No bids yet',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to bid at \$${auction.startingPrice}!',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  else
                    ...auction.sortedBids.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bid = entry.value;
                      return BidHistoryTile(
                        bid: bid,
                        isHighest: index == 0,
                        isCurrentUser: bid.bidderId == currentUserId,
                      );
                    }),

                  const SizedBox(height: 80), // Padding for bottom floating bar
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Sticky Bid Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.isLive ? 'Next Minimum Bid' : 'Auction Status',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      auction.isLive
                          ? NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(auction.minRequiredBid)
                          : (auction.isUpcoming ? 'Starts soon' : 'Finished'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (auth.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Admin (Viewing Mode)', style: TextStyle(fontWeight: FontWeight.w600)),
                )
              else if (isLeader)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text('You are leading', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: canBid ? () => QuickBidSheet.show(context, auction) : null,
                  icon: const Icon(Icons.gavel),
                  label: Text(auction.isLive ? 'Place Bid' : (auction.isUpcoming ? 'Upcoming' : 'Ended')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
