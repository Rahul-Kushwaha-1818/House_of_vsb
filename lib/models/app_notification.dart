class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? auctionId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.auctionId,
    required this.isRead,
    required this.createdAt,
  });

  bool get isOutbid => type == 'outbid';
  bool get isWon => type == 'won';
  bool get isLost => type == 'lost';
  bool get isLive => type == 'live';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? 'Auction Notification',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      auctionId: json['auctionId'] is Map
          ? json['auctionId']['_id']?.toString()
          : json['auctionId']?.toString(),
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'body': body,
      'type': type,
      'auctionId': auctionId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? auctionId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      auctionId: auctionId ?? this.auctionId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
