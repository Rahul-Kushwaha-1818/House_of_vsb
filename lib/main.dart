import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/auction_provider.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final socketService = SocketService()..connect();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<SocketService>.value(value: socketService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(apiService)..tryAutoLogin(),
        ),
        ChangeNotifierProvider<AuctionProvider>(
          create: (_) => AuctionProvider(apiService, socketService),
        ),
      ],
      child: const AuctionApp(),
    ),
  );
}

class AuctionApp extends StatelessWidget {
  const AuctionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auction Hub',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}