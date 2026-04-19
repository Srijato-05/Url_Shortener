class LinkModel {
  final int id;
  final String? title;
  final String originalUrl;
  final String shortCode;
  final String shortUrl;
  final DateTime createdAt;
  final DateTime? expiryTime;
  final String? customAlias;

  LinkModel({
    required this.id,
    this.title,
    required this.originalUrl,
    required this.shortCode,
    required this.shortUrl,
    required this.createdAt,
    this.expiryTime,
    this.customAlias,
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
    );
  }
}
