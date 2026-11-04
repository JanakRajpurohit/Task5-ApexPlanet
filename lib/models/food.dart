class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.imageUrl,
    this.cuisine = 'Continental',
    this.restaurantId = '',
    this.restaurantName = '',
    this.discountedPrice,
    this.ingredients = const [],
    this.preparationMinutes = 20,
    this.isVegetarian = true,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final double rating;
  final int reviews;
  final String description;
  final String imageUrl;
  final String cuisine;
  final String restaurantId;
  final String restaurantName;
  final int? discountedPrice;
  final List<String> ingredients;
  final int preparationMinutes;
  final bool isVegetarian;
  final bool isAvailable;

  int get effectivePrice =>
      discountedPrice != null && discountedPrice! > 0 && discountedPrice! < price
      ? discountedPrice!
      : price;

  factory Food.fromFirestore(String id, Map<String, dynamic> data) {
    String requiredString(String key) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Food "$id" has no valid "$key" field.');
      }
      return value;
    }

    int requiredInt(String key) {
      final value = data[key];
      if (value is! num || value < 0) {
        throw FormatException('Food "$id" has no valid "$key" field.');
      }
      return value.toInt();
    }

    final price = requiredInt('price');
    final ingredients = data['ingredients'];
    if (ingredients != null &&
        (ingredients is! List || ingredients.any((item) => item is! String))) {
      throw FormatException('Food "$id" has an invalid "ingredients" field.');
    }

    final rating = data['rating'];
    if (rating != null && rating is! num) {
      throw FormatException('Food "$id" has an invalid "rating" field.');
    }
    final reviews = data['reviews'];
    if (reviews != null && (reviews is! num || reviews < 0)) {
      throw FormatException('Food "$id" has an invalid "reviews" field.');
    }
    final vegetarian = data['isVegetarian'];
    if (vegetarian != null && vegetarian is! bool) {
      throw FormatException('Food "$id" has an invalid "isVegetarian" field.');
    }
    final available = data['isAvailable'];
    if (available != null && available is! bool) {
      throw FormatException('Food "$id" has an invalid "isAvailable" field.');
    }
    final discountedPrice = data['discountedPrice'];
    if (discountedPrice != null &&
        (discountedPrice is! num ||
            discountedPrice <= 0 ||
        discountedPrice >= price)) {
      throw FormatException(
        'Food "$id" has an invalid "discountedPrice" field.',
      );
    }

    return Food(
      id: id,
      name: requiredString('name'),
      category: requiredString('category'),
      price: price,
      rating: (rating as num?)?.toDouble() ?? 0,
      reviews: (reviews as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      cuisine: data['cuisine'] as String? ?? 'Other',
      restaurantId: data['restaurantId'] as String? ?? '',
      restaurantName: data['restaurantName'] as String? ?? '',
      discountedPrice: (discountedPrice as num?)?.toInt(),
      ingredients: List<String>.unmodifiable(
        (ingredients as List<dynamic>?)?.cast<String>() ?? const [],
      ),
      preparationMinutes: (data['preparationMinutes'] as num?)?.toInt() ?? 20,
      isVegetarian: vegetarian as bool? ?? true,
      isAvailable: available as bool? ?? true,
    );
  }
}

class CartLine {
  const CartLine({
    required this.food,
    required this.quantity,
    this.lineId = '',
    this.customizations = const [],
    this.extraEach = 0,
  });

  final Food food;
  final int quantity;
  final String lineId;
  final List<String> customizations;
  final int extraEach;

  int get unitPrice => food.effectivePrice + extraEach;

  int get total => unitPrice * quantity;
}

class CraveOrder {
  const CraveOrder({
    required this.id,
    required this.items,
    required this.total,
    required this.estimatedMinutes,
    this.restaurantId = '',
    this.createdAt,
    this.status = 'Active',
    this.paymentMethod = 'Cash on Delivery',
    this.deliveryAddress,
    this.deliveryInstructions = '',
  });

  final String id;
  final List<CartLine> items;
  final int total;
  final int estimatedMinutes;
  final String restaurantId;
  final DateTime? createdAt;
  final String status;
  final String paymentMethod;
  final DeliveryAddress? deliveryAddress;
  final String deliveryInstructions;
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.house,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    required this.type,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String phone;
  final String house;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String type;
  final bool isDefault;

  String get fullAddress => '$house, $street, $city, $state $pincode';

  DeliveryAddress copyWith({bool? isDefault}) => DeliveryAddress(
    id: id,
    name: name,
    phone: phone,
    house: house,
    street: street,
    city: city,
    state: state,
    pincode: pincode,
    type: type,
    isDefault: isDefault ?? this.isDefault,
  );
}

enum FoodSort { popular, priceLowToHigh, priceHighToLow, highestRated }
