class SellerAccount {
  const SellerAccount({
    required this.sellerId,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.restaurantId,
    required this.verificationStatus,
    required this.createdAt,
  });

  final String sellerId;
  final String ownerName;
  final String email;
  final String phone;
  final String restaurantId;
  final String verificationStatus;
  final DateTime createdAt;
}

class SellerRestaurant {
  SellerRestaurant({
    required this.restaurantId,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.address,
    required this.cuisine,
    required this.openingTime,
    required this.closingTime,
    this.logoUrl = '',
    this.coverImageUrl = '',
    this.isOpen = true,
    this.isApproved = true,
  });

  final String restaurantId;
  final String sellerId;
  String name;
  String description;
  String address;
  String cuisine;
  String openingTime;
  String closingTime;
  String logoUrl;
  String coverImageUrl;
  bool isOpen;
  bool isApproved;
}

class SellerFood {
  SellerFood({
    required this.foodId,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.preparationTime,
    this.restaurantName = '',
    this.cuisine = '',
    this.discountedPrice,
    this.available = true,
    this.vegetarian = true,
    this.bestseller = false,
    this.featured = false,
    this.isDraft = false,
    this.stock = 20,
    this.rating = 0,
    this.popularity = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String foodId;
  final String restaurantId;
  String name;
  String description;
  String imageUrl;
  int price;
  String category;
  int preparationTime;
  String restaurantName;
  String cuisine;
  int? discountedPrice;
  bool available;
  bool vegetarian;
  bool bestseller;
  bool featured;
  bool isDraft;
  int stock;
  double rating;
  int popularity;
  final DateTime createdAt;
}

class SellerOrderItem {
  const SellerOrderItem({
    this.foodId = '',
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.customizations = const [],
  });

  final String foodId;
  final String name;
  final int quantity;
  final int unitPrice;
  final List<String> customizations;

  int get total => quantity * unitPrice;
}

class OrderStatusUpdate {
  const OrderStatusUpdate({
    required this.status,
    required this.updatedAt,
    this.note = '',
  });

  final String status;
  final DateTime updatedAt;
  final String note;
}

class SellerOrder {
  SellerOrder({
    required this.orderId,
    required this.restaurantId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    this.instructions = '',
    this.preparationMinutes = 25,
    List<OrderStatusUpdate>? statusHistory,
  }) : statusHistory =
           statusHistory ??
           [OrderStatusUpdate(status: orderStatus, updatedAt: createdAt)];

  final String orderId;
  final String restaurantId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<SellerOrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int discount;
  final int totalAmount;
  final String paymentMethod;
  String paymentStatus;
  String orderStatus;
  final DateTime createdAt;
  String instructions;
  int preparationMinutes;
  final List<OrderStatusUpdate> statusHistory;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class SellerOffer {
  SellerOffer({
    required this.offerId,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.minimumOrder,
    required this.maximumDiscount,
    required this.startsAt,
    required this.expiresAt,
    this.active = true,
  });

  final String offerId;
  final String restaurantId;
  String name;
  String description;
  String type;
  int value;
  int minimumOrder;
  int maximumDiscount;
  DateTime startsAt;
  DateTime expiresAt;
  bool active;

  String get status {
    final now = DateTime.now();
    if (now.isBefore(startsAt)) return 'Scheduled';
    if (now.isAfter(expiresAt)) return 'Expired';
    return active ? 'Active' : 'Inactive';
  }
}

class SellerNotification {
  SellerNotification({
    required this.notificationId,
    required this.sellerId,
    required this.restaurantId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.orderId,
    this.isRead = false,
  });

  final String notificationId;
  final String sellerId;
  final String restaurantId;
  final String? orderId;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  bool isRead;
}

class SellerReview {
  SellerReview({
    required this.reviewId,
    required this.restaurantId,
    required this.customerName,
    required this.foodName,
    required this.rating,
    required this.review,
    required this.createdAt,
    this.response,
  });

  final String reviewId;
  final String restaurantId;
  final String customerName;
  final String foodName;
  final double rating;
  final String review;
  final DateTime createdAt;
  String? response;
}
