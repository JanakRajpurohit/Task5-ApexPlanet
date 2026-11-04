import 'package:crave/models/seller_models.dart';

abstract final class MockSellerData {
  static const restaurantId = 'rest-crave-demo';
  static const sellerId = 'seller-crave-demo';

  static SellerAccount get account => SellerAccount(
    sellerId: sellerId,
    ownerName: 'Aarav Sharma',
    email: 'partner@crave.demo',
    phone: '+91 98765 43210',
    restaurantId: restaurantId,
    verificationStatus: 'Approved',
    createdAt: DateTime(2025, 1, 10),
  );

  static SellerRestaurant get restaurant => SellerRestaurant(
    restaurantId: restaurantId,
    sellerId: sellerId,
    name: 'Crave Kitchen',
    description: 'Fresh comfort food, prepared with care.',
    address: '42, Sardarpura, Jodhpur, Rajasthan 342001',
    cuisine: 'American, Italian, Indian',
    openingTime: '10:00 AM',
    closingTime: '10:00 PM',
  );

  static List<SellerFood> get foods => [
    SellerFood(
      foodId: 'seller-burger',
      restaurantId: restaurantId,
      name: 'Classic Smash Burger',
      description: 'Smash patty, cheddar, lettuce and house sauce.',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=700',
      price: 249,
      category: 'Burgers',
      preparationTime: 20,
      bestseller: true,
      popularity: 96,
    ),
    SellerFood(
      foodId: 'seller-pizza',
      restaurantId: restaurantId,
      name: 'Garden Margherita',
      description: 'Tomato, mozzarella and fresh basil on a crisp crust.',
      imageUrl:
          'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=700',
      price: 329,
      category: 'Pizza',
      preparationTime: 25,
      popularity: 74,
    ),
    SellerFood(
      foodId: 'seller-fries',
      restaurantId: restaurantId,
      name: 'Loaded Masala Fries',
      description: 'Crispy fries tossed in house masala.',
      imageUrl:
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=700',
      price: 149,
      category: 'Fries',
      preparationTime: 12,
      stock: 5,
      popularity: 52,
    ),
  ];

  static List<SellerOrder> get orders {
    final now = DateTime.now();
    return [
      SellerOrder(
        orderId: 'CRV-8031',
        restaurantId: restaurantId,
        customerId: 'customer-102',
        customerName: 'Maya Patel',
        customerPhone: '+91 98765 12345',
        deliveryAddress: 'Shastri Nagar, Jodhpur, Rajasthan',
        items: const [
          SellerOrderItem(
            name: 'Classic Smash Burger',
            quantity: 2,
            unitPrice: 249,
          ),
          SellerOrderItem(
            name: 'Loaded Masala Fries',
            quantity: 1,
            unitPrice: 149,
          ),
        ],
        subtotal: 647,
        deliveryFee: 30,
        discount: 50,
        totalAmount: 627,
        paymentMethod: 'UPI',
        paymentStatus: 'Paid',
        orderStatus: 'New',
        createdAt: now.subtract(const Duration(minutes: 4)),
        instructions: 'Please pack the sauce separately.',
      ),
      SellerOrder(
        orderId: 'CRV-8028',
        restaurantId: restaurantId,
        customerId: 'customer-209',
        customerName: 'Rohan Mehta',
        customerPhone: '+91 98290 44556',
        deliveryAddress: 'Sardarpura, Jodhpur, Rajasthan',
        items: const [
          SellerOrderItem(
            name: 'Garden Margherita',
            quantity: 1,
            unitPrice: 329,
          ),
        ],
        subtotal: 329,
        deliveryFee: 30,
        discount: 0,
        totalAmount: 359,
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'Pending',
        orderStatus: 'Preparing',
        createdAt: now.subtract(const Duration(minutes: 22)),
        instructions: 'No chilli flakes.',
        statusHistory: [
          OrderStatusUpdate(
            status: 'New',
            updatedAt: now.subtract(const Duration(minutes: 22)),
          ),
          OrderStatusUpdate(
            status: 'Accepted',
            updatedAt: now.subtract(const Duration(minutes: 20)),
          ),
          OrderStatusUpdate(
            status: 'Preparing',
            updatedAt: now.subtract(const Duration(minutes: 15)),
          ),
        ],
      ),
      SellerOrder(
        orderId: 'CRV-8019',
        restaurantId: restaurantId,
        customerId: 'customer-188',
        customerName: 'Nisha Verma',
        customerPhone: '+91 94141 23456',
        deliveryAddress: 'Paota, Jodhpur, Rajasthan',
        items: const [
          SellerOrderItem(
            name: 'Classic Smash Burger',
            quantity: 1,
            unitPrice: 249,
          ),
        ],
        subtotal: 249,
        deliveryFee: 30,
        discount: 0,
        totalAmount: 279,
        paymentMethod: 'Card',
        paymentStatus: 'Paid',
        orderStatus: 'Completed',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  static List<SellerOffer> get offers => [
    SellerOffer(
      offerId: 'offer-welcome',
      restaurantId: restaurantId,
      name: 'Welcome treat',
      description: '15% off orders above ₹299',
      type: 'Percentage',
      value: 15,
      minimumOrder: 299,
      maximumDiscount: 100,
      startsAt: DateTime.now().subtract(const Duration(days: 3)),
      expiresAt: DateTime.now().add(const Duration(days: 14)),
    ),
  ];

  static List<SellerNotification> get notifications => [
    SellerNotification(
      notificationId: 'notice-8031',
      sellerId: sellerId,
      restaurantId: restaurantId,
      title: 'New order received',
      message: 'Order CRV-8031 is waiting for your response.',
      type: 'New Orders',
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      orderId: 'CRV-8031',
    ),
    SellerNotification(
      notificationId: 'notice-stock',
      sellerId: sellerId,
      restaurantId: restaurantId,
      title: 'Low stock alert',
      message: 'Loaded Masala Fries has only 5 portions left.',
      type: 'Inventory Alerts',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  static List<SellerReview> get reviews => [
    SellerReview(
      reviewId: 'review-1',
      restaurantId: restaurantId,
      customerName: 'Isha K.',
      foodName: 'Garden Margherita',
      rating: 5,
      review: 'Great crust and arrived hot. Will order again!',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SellerReview(
      reviewId: 'review-2',
      restaurantId: restaurantId,
      customerName: 'Dev P.',
      foodName: 'Classic Smash Burger',
      rating: 4,
      review: 'Really tasty and good portion size.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      response: 'Thanks for your kind words, Dev!',
    ),
  ];
}
