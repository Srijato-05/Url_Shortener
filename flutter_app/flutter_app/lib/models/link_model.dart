class LinkModel {
  final int id;
  final String? title;
  final String originalUrl;
  final String shortCode;
  final String shortUrl;
  final DateTime createdAt;
  final DateTime? expiryTime;
  final String? customAlias;

  final String? qrUrl;

  LinkModel({
    required this.id,
    this.title,
    required this.originalUrl,
    required this.shortCode,
    required this.shortUrl,
    required this.createdAt,
    this.expiryTime,
    this.customAlias,
    this.qrUrl,
  });

  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
      id: json['id'],
      title: json['title'],
      originalUrl: json['original_url'],
      shortCode: json['short_code'],
      shortUrl: json['short_url'],
      createdAt: DateTime.parse(json['created_at']),
      expiryTime: json['expiry_time'] != null ? DateTime.parse(json['expiry_time']) : null,
      customAlias: json['custom_alias'],
      qrUrl: json['qr_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'original_url': originalUrl,
      'short_code': shortCode,
      'short_url': shortUrl,
      'created_at': createdAt.toIso8601String(),
      'expiry_time': expiryTime?.toIso8601String(),
      'custom_alias': customAlias,
      'qr_url': qrUrl,
    };
  }
}
