import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/auction.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  String baseUrl = AppConstants.defaultBaseUrl;
  String? _authToken;

  void setToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers({bool jsonContent = true}) {
    final headers = <String, String>{};
    if (jsonContent) {
      headers['Content-Type'] = 'application/json';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // 1. Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return {
          'token': body['token'],
          'user': AppUser.fromJson(body['user']),
        };
      } else {
        throw ApiException(body['message'] ?? 'Login failed', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: Unable to connect to server ($baseUrl)');
    }
  }

  // 2. Fetch current profile
  Future<AppUser> getMe() async {
    final url = Uri.parse('$baseUrl/api/auth/me');
    try {
      final response = await http.get(url, headers: _headers());
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return AppUser.fromJson(body['user']);
      } else {
        throw ApiException(body['message'] ?? 'Failed to fetch user', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: Unable to reach server');
    }
  }

  // 3. Get auctions with optional filters
  Future<List<Auction>> getAuctions({String? status, bool? myBids}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (myBids == true) queryParams['myBids'] = 'true';

    final uri = Uri.parse('$baseUrl/api/auctions').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    try {
      final response = await http.get(uri, headers: _headers());
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final List list = body['auctions'] ?? [];
        return list.map((item) => Auction.fromJson(item)).toList();
      } else {
        throw ApiException(body['message'] ?? 'Failed to load auctions', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: Unable to fetch auctions');
    }
  }

  // 4. Get single auction details
  Future<Auction> getAuctionById(String id) async {
    final url = Uri.parse('$baseUrl/api/auctions/$id');
    try {
      final response = await http.get(url, headers: _headers());
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return Auction.fromJson(body['auction']);
      } else {
        throw ApiException(body['message'] ?? 'Auction not found', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: Unable to fetch auction details');
    }
  }

  // 5. Place a bid
  Future<Auction> placeBid(String auctionId, num amount) async {
    final url = Uri.parse('$baseUrl/api/auctions/$auctionId/bid');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'amount': amount}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return Auction.fromJson(body['auction']);
      } else {
        throw ApiException(body['message'] ?? 'Bid was rejected', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: Failed to place bid');
    }
  }

  // 6. Create auction (Admin)
  Future<Auction> createAuction({
    required String title,
    required String description,
    required num startingPrice,
    required num minIncrement,
    required DateTime startTime,
    required DateTime endTime,
    List<int>? imageBytes,
    String? imageFileName,
    String? imageUrlFallback,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auctions');
    try {
      final request = http.MultipartRequest('POST', uri);
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['startingPrice'] = startingPrice.toString();
      request.fields['minIncrement'] = minIncrement.toString();
      request.fields['startTime'] = startTime.toUtc().toIso8601String();
      request.fields['endTime'] = endTime.toUtc().toIso8601String();

      if (imageBytes != null && imageBytes.isNotEmpty) {
        String fname = imageFileName ?? 'upload.jpg';
        if (!fname.contains('.')) {
          fname = '$fname.jpg';
        }
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fname,
        ));
      } else if (imageUrlFallback != null && imageUrlFallback.isNotEmpty) {
        request.fields['imageUrl'] = imageUrlFallback;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 201 && body['success'] == true) {
        return Auction.fromJson(body['auction']);
      } else {
        throw ApiException(body['message'] ?? 'Failed to create auction', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: Failed to create auction ($e)');
    }
  }

  // ping server health so render stays awake under 5 mins
  Future<bool> checkHealth() async {
    final url = Uri.parse('$baseUrl/health');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
