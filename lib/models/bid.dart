class Bid {
  final String id;
  final num amount;
  final String bidderId;
  final String bidderName;
  final String bidderEmail;
  final DateTime createdAt;

  const Bid({
    required this.id,
    required this.amount,
    required this.bidderId,
    required this.bidderName,
    required this.bidderEmail,
    required this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    String bidderId = '';
    String bidderName = 'Anonymous';
    String bidderEmail = '';

    if (json['bidder'] is Map) {
      bidderId = json['bidder']['_id'] ?? json['bidder']['id'] ?? '';
      bidderName = json['bidder']['name'] ?? 'Bidder';
      bidderEmail = json['bidder']['email'] ?? '';
    } else if (json['bidder'] is String) {
      bidderId = json['bidder'];
    }

    DateTime parsedDate = DateTime.now();
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now();
    }

    return Bid(
      id: json['_id'] ?? json['id'] ?? '',
      amount: json['amount'] ?? 0,
      bidderId: bidderId,
      bidderName: bidderName,
      bidderEmail: bidderEmail,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'amount': amount,
      'bidder': {
        '_id': bidderId,
        'name': bidderName,
        'email': bidderEmail,
      },
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
