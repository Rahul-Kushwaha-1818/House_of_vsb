import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:first_app/providers/auth_provider.dart';
import 'package:first_app/providers/auction_provider.dart';
import 'package:first_app/services/api_service.dart';
import 'package:first_app/services/socket_service.dart';
import 'package:first_app/providers/notification_provider.dart';
import 'package:first_app/screens/login_screen.dart';
import 'package:first_app/screens/splash_screen.dart';
import 'package:first_app/screens/signup_screen.dart';
import 'package:first_app/screens/forgot_password_screen.dart';
import 'package:first_app/screens/notifications_screen.dart';
import 'package:first_app/screens/auction_list_screen.dart';
import 'package:first_app/models/user.dart';
import 'package:first_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('SplashScreen displays branding and holds for 3 seconds', (WidgetTester tester) async {
    final apiService = ApiService();
    final socketService = SocketService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          Provider<SocketService>.value(value: socketService),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(apiService),
          ),
          ChangeNotifierProvider<AuctionProvider>(
            create: (_) => AuctionProvider(apiService, socketService),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );

    // Initial frame shows splash branding
    await tester.pump();
    expect(find.text('AUCTION HUB'), findsOneWidget);
    expect(find.text('Real-Time Live Bidding Marketplace'), findsOneWidget);

    // Advance 3 seconds for transition
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // After 3 seconds, navigates to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('LoginScreen smoke test and demo accounts check', (WidgetTester tester) async {
    final apiService = ApiService();
    final socketService = SocketService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          Provider<SocketService>.value(value: socketService),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(apiService),
          ),
          ChangeNotifierProvider<AuctionProvider>(
            create: (_) => AuctionProvider(apiService, socketService),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Login Screen Elements
    expect(find.text('Auction Hub'), findsOneWidget);
    expect(find.text('Welcome to Auction Hub'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('1-TAP DEMO ACCOUNTS'), findsOneWidget);
    expect(find.text('Auction Admin'), findsOneWidget);
    expect(find.text('Alice Walker'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('SignupScreen displays form fields and handles validation', (WidgetTester tester) async {
    final apiService = ApiService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(apiService),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SignupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsNWidgets(2)); // In AppBar and Button
    expect(find.text('Join Auction Hub'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);

    // Tap submit on empty form to trigger validation
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your full name'), findsOneWidget);
  });

  testWidgets('ForgotPasswordScreen displays email input in step 1', (WidgetTester tester) async {
    final apiService = ApiService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(apiService),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ForgotPasswordScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Password Recovery'), findsOneWidget);
    expect(find.text('Forgot Your Password?'), findsOneWidget);
    expect(find.text('Registered Email'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Send Verification Code'), findsOneWidget);
  });

  testWidgets('NotificationsScreen displays empty state when no notifications', (WidgetTester tester) async {
    final apiService = ApiService();
    final socketService = SocketService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          Provider<SocketService>.value(value: socketService),
          ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider(apiService, socketService),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No Notifications Yet'), findsOneWidget);
  });

  testWidgets('AuctionListScreen hides My Bids tab for Admin role', (WidgetTester tester) async {
    final apiService = ApiService();
    final socketService = SocketService();
    final authProvider = AuthProvider(apiService);
    final auctionProvider = AuctionProvider(apiService, socketService, startKeepAlive: false);
    final notifProvider = NotificationProvider(apiService, socketService);

    addTearDown(() {
      authProvider.dispose();
      auctionProvider.dispose();
      notifProvider.dispose();
    });

    // set admin user
    authProvider.setUserForTesting(const AppUser(
      id: 'admin_1',
      name: 'Auction Admin',
      email: 'admin@auction.com',
      role: 'admin',
    ));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          Provider<SocketService>.value(value: socketService),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AuctionProvider>.value(value: auctionProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuctionListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // admin sees Live, Upcoming, Ended
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Ended'), findsOneWidget);
    // My Bids tab must be completely removed for admin
    expect(find.text('My Bids'), findsNothing);
  });

  testWidgets('AuctionListScreen shows My Bids tab for regular User role', (WidgetTester tester) async {
    final apiService = ApiService();
    final socketService = SocketService();
    final authProvider = AuthProvider(apiService);
    final auctionProvider = AuctionProvider(apiService, socketService, startKeepAlive: false);
    final notifProvider = NotificationProvider(apiService, socketService);

    addTearDown(() {
      authProvider.dispose();
      auctionProvider.dispose();
      notifProvider.dispose();
    });

    // set regular user
    authProvider.setUserForTesting(const AppUser(
      id: 'user_1',
      name: 'Alice Walker',
      email: 'alice@auction.com',
      role: 'user',
    ));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          Provider<SocketService>.value(value: socketService),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AuctionProvider>.value(value: auctionProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuctionListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // user sees all 4 tabs including My Bids
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Ended'), findsOneWidget);
    expect(find.text('My Bids'), findsOneWidget);
  });
}
