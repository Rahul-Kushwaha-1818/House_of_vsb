import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auction_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auction_card.dart';
import 'auction_detail_screen.dart';
import 'create_auction_screen.dart';
import 'login_screen.dart';

class AuctionListScreen extends StatefulWidget {
  const AuctionListScreen({super.key});

  @override
  State<AuctionListScreen> createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends State<AuctionListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Map<String, String>> _tabs;
  bool? _lastIsAdmin;

  // show my bids tab only for normal users, remove it for admin
  List<Map<String, String>> _getTabsForRole(bool isAdmin) {
    if (isAdmin) {
      // admin cannot bid so no my bids tab
      return const [
        {'key': 'live', 'label': 'Live'},
        {'key': 'upcoming', 'label': 'Upcoming'},
        {'key': 'ended', 'label': 'Ended'},
      ];
    }
    // normal users can bid so show my bids
    return const [
      {'key': 'live', 'label': 'Live'},
      {'key': 'upcoming', 'label': 'Upcoming'},
      {'key': 'ended', 'label': 'Ended'},
      {'key': 'my_bids', 'label': 'My Bids'},
    ];
  }

  @override
  void initState() {
    super.initState();
    final isAdmin = context.read<AuthProvider>().isAdmin;
    _lastIsAdmin = isAdmin;
    _tabs = _getTabsForRole(isAdmin);
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuctionProvider>().fetchAuctions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    if (_lastIsAdmin != isAdmin) {
      _lastIsAdmin = isAdmin;
      _tabs = _getTabsForRole(isAdmin);
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      _tabController = TabController(length: _tabs.length, vsync: this);
      _tabController.addListener(_onTabChanged);

      // if admin was on my bids reset back to live tab
      if (isAdmin && context.read<AuctionProvider>().currentFilter == 'my_bids') {
        context.read<AuctionProvider>().setFilter('live');
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final selectedKey = _tabs[_tabController.index]['key']!;
      context.read<AuctionProvider>().setFilter(selectedKey);
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Widget _buildEmptyState(String filter) {
    IconData icon;
    String title;
    String subtitle;

    switch (filter) {
      case 'live':
        icon = Icons.hourglass_empty;
        title = 'No live auctions';
        subtitle = 'Check upcoming auctions or check back shortly.';
        break;
      case 'upcoming':
        icon = Icons.calendar_today_outlined;
        title = 'No upcoming auctions';
        subtitle = 'New auctions will appear here when scheduled.';
        break;
      case 'ended':
        icon = Icons.history;
        title = 'No ended auctions';
        subtitle = 'Completed auctions and their results will show here.';
        break;
      case 'my_bids':
        icon = Icons.gavel_outlined;
        title = 'You haven’t bid on anything yet';
        subtitle = 'Browse live auctions and place your first bid!';
        break;
      default:
        icon = Icons.inbox_outlined;
        title = 'No auctions found';
        subtitle = 'Try switching tabs or refreshing.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final auctionProv = context.watch<AuctionProvider>();
    final user = auth.user;
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Auctions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (user != null)
              Row(
                children: [
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isAdmin ? AppTheme.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAdmin ? 'ADMIN' : 'USER',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => auctionProv.fetchAuctions(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => auctionProv.fetchAuctions(),
              child: auctionProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : auctionProv.errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  auctionProv.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => auctionProv.fetchAuctions(),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : auctionProv.auctions.isEmpty
                          ? _buildEmptyState(auctionProv.currentFilter)
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: auctionProv.auctions.length,
                              itemBuilder: (context, index) {
                                final auction = auctionProv.auctions[index];
                                return AuctionCard(
                                  auction: auction,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AuctionDetailScreen(auctionId: auction.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ),
        ],
      ),

      // Admin Floating Action Button
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAuctionScreen()),
                );
              },
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Auction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
