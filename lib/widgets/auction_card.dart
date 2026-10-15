import 'package:flutter/material.dart';
import '../models/auction.dart';
import '../theme/app_theme.dart';
import 'countdown_timer.dart';

class AuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback onTap;

  const AuctionCard({
    super.key,
    required this.auction,
    required this.onTap,
  });

  Widget _buildStatusBadge() {
    Color bg;
    Color fg;
    String text;

    if (auction.isLive) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      text = '● LIVE';
    } else if (auction.isUpcoming) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      text = 'UPCOMING';
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
      text = 'ENDED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget? _buildOutcomeBadge() {
    if (auction.userOutcome == null) return null;

    Color bg;
    Color fg;
    String text;

    switch (auction.userOutcome) {
      case 'won':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        text = '🏆 YOU WON';
        break;
      case 'winning':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        text = 'LEADING BID';
        break;
      case 'outbid':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        text = 'OUTBID';
        break;
      case 'lost':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        text = 'ENDED (LOST)';
        break;
      default:
        return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outcomeBadge = _buildOutcomeBadge();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    auction.displayImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey.shade400),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildStatusBadge(),
                ),
                if (outcomeBadge != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: outcomeBadge,
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bid info & Timer row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auction.hasBids ? 'Current Bid' : 'Starting Price',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auction.formattedCurrentBid,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),

                      // Time or Status Right Side
                      if (auction.isLive)
                        CountdownTimerWidget(
                          targetTime: auction.endTime,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        )
                      else if (auction.isUpcoming)
                        CountdownTimerWidget(
                          targetTime: auction.startTime,
                          isStartTime: true,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        )
                      else
                        Text(
                          auction.winnerName != null
                              ? 'Won by ${auction.winnerName}'
                              : 'No winner (Unsold)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Footer: Total bids count & Min increment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.gavel, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${auction.bids.length} ${auction.bids.length == 1 ? 'bid' : 'bids'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Min increment: ${auction.formattedMinIncrement}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
