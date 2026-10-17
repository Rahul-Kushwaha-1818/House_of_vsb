import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/auction.dart';
import '../providers/auction_provider.dart';
import '../theme/app_theme.dart';

class QuickBidSheet extends StatefulWidget {
  final Auction auction;

  const QuickBidSheet({super.key, required this.auction});

  static Future<void> show(BuildContext context, Auction auction) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickBidSheet(auction: auction),
    );
  }

  @override
  State<QuickBidSheet> createState() => _QuickBidSheetState();
}

class _QuickBidSheetState extends State<QuickBidSheet> {
  late TextEditingController _amountController;
  late num _selectedAmount;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedAmount = widget.auction.minRequiredBid;
    _amountController = TextEditingController(text: _selectedAmount.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectPreset(num amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toString();
      _errorMessage = null;
    });
  }

  Future<void> _submitBid() async {
    final enteredText = _amountController.text.trim();
    final amount = num.tryParse(enteredText);

    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid bid amount';
      });
      return;
    }

    if (amount < widget.auction.minRequiredBid) {
      setState(() {
        _errorMessage =
            'Bid must be at least ₹${widget.auction.minRequiredBid}. (Increment: ₹${widget.auction.minIncrement})';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final provider = context.read<AuctionProvider>();
    final result = await provider.placeBid(amount);

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(result['message'] ?? 'Bid placed!')),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = result['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final minBid = widget.auction.minRequiredBid;
    final increment = widget.auction.minIncrement;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Place Your Bid',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text(
            widget.auction.hasBids
                ? 'Current highest bid: ${widget.auction.formattedCurrentBid}'
                : 'Starting price: ${widget.auction.formattedStartingPrice}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Preset Bid Chips
          const Text(
            'Quick Increments',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip('Next Min: ${currency.format(minBid)}', minBid),
                const SizedBox(width: 8),
                _buildPresetChip('+${currency.format(increment * 2)}: ${currency.format(minBid + increment)}', minBid + increment),
                const SizedBox(width: 8),
                _buildPresetChip('+${currency.format(increment * 5)}: ${currency.format(minBid + (increment * 4))}', minBid + (increment * 4)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom Input Field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
            decoration: InputDecoration(
              labelText: 'Bid Amount (₹)',
              prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.primary),
              helperText: 'Minimum required: ${currency.format(minBid)}',
            ),
            onChanged: (val) {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
          const SizedBox(height: 12),

          // Error Message Banner if rejected
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitBid,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Confirm Bid'),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, num amount) {
    final isSelected = num.tryParse(_amountController.text) == amount;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _selectPreset(amount),
      selectedColor: AppTheme.primary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : AppTheme.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? AppTheme.primary : Colors.grey.shade300,
        width: 1,
      ),
    );
  }
}
