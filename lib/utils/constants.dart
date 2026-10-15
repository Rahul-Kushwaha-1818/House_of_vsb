class AppConstants {
  // Live deployed Render backend URL
  static const String liveServerUrl = 'https://house-of-vsb.onrender.com';

  static String get defaultBaseUrl => liveServerUrl;

  static String get defaultSocketUrl => liveServerUrl;

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
