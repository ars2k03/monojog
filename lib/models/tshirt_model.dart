// T-shirt model for the merch store.

class TShirt {
  final String id;
  final String name;
  final String description;
  final String designEmoji; // emoji representation of the design
  final double price; // in INR, all within 500
  final List<String> sizes; // S, M, L, XL, XXL
  final List<String> colors; // available color names
  final String category; // 'classic', 'premium', 'limited'
  final bool isAvailable;

  const TShirt({
    required this.id,
    required this.name,
    required this.description,
    required this.designEmoji,
    required this.price,
    this.sizes = const ['S', 'M', 'L', 'XL', 'XXL'],
    this.colors = const ['Black', 'White'],
    this.category = 'classic',
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'designEmoji': designEmoji,
        'price': price,
        'sizes': sizes,
        'colors': colors,
        'category': category,
        'isAvailable': isAvailable,
      };

  factory TShirt.fromMap(Map<String, dynamic> map) => TShirt(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        designEmoji: map['designEmoji'] as String,
        price: (map['price'] as num).toDouble(),
        sizes: List<String>.from(map['sizes'] as List),
        colors: List<String>.from(map['colors'] as List),
        category: map['category'] as String? ?? 'classic',
        isAvailable: map['isAvailable'] as bool? ?? true,
      );

  TShirt copyWith({
    String? id,
    String? name,
    String? description,
    String? designEmoji,
    double? price,
    List<String>? sizes,
    List<String>? colors,
    String? category,
    bool? isAvailable,
  }) {
    return TShirt(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      designEmoji: designEmoji ?? this.designEmoji,
      price: price ?? this.price,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  /// All available t-shirt designs.
  static List<TShirt> get catalog => const [
        TShirt(
          id: 'tshirt_001',
          name: 'The Grind Never Stops',
          description: 'A minimal tee for those who show up every single day.',
          designEmoji: '🔥',
          price: 299,
          colors: ['Black', 'Charcoal', 'Navy'],
          category: 'classic',
        ),
        TShirt(
          id: 'tshirt_002',
          name: 'Pomodoro Warrior',
          description: 'Rep the tomato timer lifestyle. 25 on, 5 off.',
          designEmoji: '🍅',
          price: 299,
          colors: ['White', 'Red', 'Black'],
          category: 'classic',
        ),
        TShirt(
          id: 'tshirt_003',
          name: 'Deep Focus Mode',
          description: 'No notifications. No distractions. Just flow.',
          designEmoji: '🧠',
          price: 349,
          colors: ['Black', 'White', 'Slate Grey'],
          category: 'classic',
        ),
        TShirt(
          id: 'tshirt_004',
          name: 'Night Owl Scholar',
          description: 'For those who peak when the world sleeps.',
          designEmoji: '🦉',
          price: 399,
          colors: ['Black', 'Midnight Blue', 'Purple'],
          category: 'premium',
        ),
        TShirt(
          id: 'tshirt_005',
          name: 'Streak Machine',
          description: 'Keep the streak alive. Day after day after day.',
          designEmoji: '⚡',
          price: 399,
          colors: ['Yellow', 'Black', 'White'],
          category: 'premium',
        ),
        TShirt(
          id: 'tshirt_006',
          name: 'Zen & Steady',
          description: 'Calm mind, sharp focus. Balance is the real flex.',
          designEmoji: '🧘',
          price: 449,
          colors: ['White', 'Sage Green', 'Lavender'],
          category: 'premium',
        ),
        TShirt(
          id: 'tshirt_007',
          name: 'FIDE Master',
          description:
              'Limited drop for top-ranked grinders. Earned, not given.',
          designEmoji: '♟️',
          price: 499,
          colors: ['Black', 'Gold'],
          category: 'limited',
        ),
        TShirt(
          id: 'tshirt_008',
          name: 'Cosmic Learner',
          description: 'Knowledge is infinite. So is your potential.',
          designEmoji: '🚀',
          price: 499,
          colors: ['Black', 'Space Blue'],
          sizes: ['S', 'M', 'L', 'XL'],
          category: 'limited',
        ),
      ];
}

class TShirtOrder {
  final String id;
  final String tshirtId;
  final String tshirtName;
  final String userId;
  final String userEmail;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String size;
  final String color;
  final double price;
  final String paymentMethod; // 'bKash' | 'Nagad'
  final String merchantNumber; // fixed payment number for merchant account
  final String transactionId;
  final DateTime orderedAt;
  final String status; // 'pending', 'confirmed', 'shipped', 'delivered'

  TShirtOrder({
    required this.id,
    required this.tshirtId,
    required this.tshirtName,
    required this.userId,
    required this.userEmail,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.size,
    required this.color,
    required this.price,
    required this.paymentMethod,
    required this.merchantNumber,
    required this.transactionId,
    required this.orderedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'tshirtId': tshirtId,
        'tshirtName': tshirtName,
        'userId': userId,
        'userEmail': userEmail,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'size': size,
        'color': color,
        'price': price,
        'paymentMethod': paymentMethod,
        'merchantNumber': merchantNumber,
        'transactionId': transactionId,
        'orderedAt': orderedAt.millisecondsSinceEpoch,
        'status': status,
      };

  factory TShirtOrder.fromMap(Map<String, dynamic> map) => TShirtOrder(
        id: map['id'] as String,
        tshirtId: map['tshirtId'] as String,
        tshirtName: map['tshirtName'] as String,
        userId: map['userId'] as String,
        userEmail: map['userEmail'] as String? ?? '',
        customerName: map['customerName'] as String? ?? '',
        customerPhone: map['customerPhone'] as String? ?? '',
        deliveryAddress: map['deliveryAddress'] as String? ?? '',
        size: map['size'] as String,
        color: map['color'] as String,
        price: (map['price'] as num).toDouble(),
        paymentMethod: map['paymentMethod'] as String? ?? 'bKash',
        merchantNumber: map['merchantNumber'] as String? ?? '01797859806',
        transactionId: map['transactionId'] as String? ?? '',
        orderedAt: _readDate(map['orderedAt']),
        status: map['status'] as String? ?? 'pending',
      );

  static DateTime _readDate(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
