class PremiumApp {
  final String id;
  final String title;
  final String provider;
  final double originalPrice;
  final double discountPrice;
  final String description;
  final List<String> features;
  final String? imageUrl;
  final String category;
  final DateTime createdAt;

  PremiumApp({
    required this.id,
    required this.title,
    required this.provider,
    required this.originalPrice,
    required this.discountPrice,
    required this.description,
    required this.features,
    this.imageUrl,
    required this.category,
    required this.createdAt,
  });

  factory PremiumApp.fromJson(Map<String, dynamic> json) {
    return PremiumApp(
      id: json['id'],
      title: json['title'],
      provider: json['provider'],
      originalPrice: (json['original_price'] as num).toDouble(),
      discountPrice: (json['discount_price'] as num).toDouble(),
      description: json['description'],
      features: List<String>.from(json['features']),
      imageUrl: json['image_url'],
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
