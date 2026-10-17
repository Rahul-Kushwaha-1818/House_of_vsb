import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bid.dart';
import '../theme/app_theme.dart';

class BidHistoryTile extends StatelessWidget {
  final Bid bid;
  final bool isHighest;
  final bool isCurrentUser;

  const BidHistoryTile({
    super.key,
    required this.bid,
    this.isHighest = false,
    this.isCurrentUser = false,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(bid.amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isHighest ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighest ? AppTheme.primaryLight.withValues(alpha: 0.4) : Colors.grey.shade200,
          width: isHighest ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isHighest ? AppTheme.primary : Colors.grey.shade200,
            child: Text(
              bid.bidderName.isNotEmpty ? bid.bidderName[0].toUpperCase() : '?',
              style: TextStyle(
                color: isHighest ? Colors.white : AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isCurrentUser ? '${bid.bidderName} (You)' : bid.bidderName,
                      style: TextStyle(
                        fontWeight: isHighest ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (isHighest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIGHEST',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _formatTime(bid.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isHighest ? AppTheme.primary : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
