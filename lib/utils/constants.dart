import 'package:flutter/foundation.dart';

class AppConstants {
  // Detect standard host based on platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    // Android emulator host loopback vs localhost
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  static String get defaultSocketUrl => defaultBaseUrl;

  // Demo accounts for quick review login
  static const List<Map<String, String>> demoAccounts = [
    {
      'role': 'Admin',
      'name': 'Auction Admin',
      'email': 'admin@auction.com',
      'password': 'admin123',
    },
    {
      'role': 'User',
      'name': 'Alice Walker',
      'email': 'alice@auction.com',
      'password': 'user123',
    },
    {
      'role': 'User',
      'name': 'Bob Martinez',
      'email': 'bob@auction.com',
      'password': 'user123',
    },
    {
      'role': 'User',
      'name': 'Charlie Chen',
      'email': 'charlie@auction.com',
      'password': 'user123',
    },
    {
      'role': 'User',
      'name': 'Diana Prince',
      'email': 'diana@auction.com',
      'password': 'user123',
    },
    {
      'role': 'User',
      'name': 'Ethan Hunt',
      'email': 'ethan@auction.com',
      'password': 'user123',
    },
  ];
}
