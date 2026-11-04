import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/seller_models.dart';

class SellerBootstrap {
  const SellerBootstrap({
    required this.account,
    required this.restaurant,
    required this.foods,
    required this.orders,
    required this.offers,
    required this.notifications,
    required this.reviews,
    required this.categories,
    required this.workingDays,
    required this.scheduledClosures,
  });

  final SellerAccount account;
  final SellerRestaurant restaurant;
  final List<SellerFood> foods;
  final List<SellerOrder> orders;
  final List<SellerOffer> offers;
  final List<SellerNotification> notifications;
  final List<SellerReview> reviews;
  final List<String> categories;
  final List<String> workingDays;
  final List<DateTime> scheduledClosures;
}

String _string(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

bool _canTransitionOrder(String current, String next) {
  const transitions = <String, List<String>>{
    'New': ['Accepted', 'Rejected'],
    'Accepted': ['Preparing', 'Cancelled'],
    'Preparing': ['Ready for Pickup', 'Cancelled'],
    'Ready for Pickup': ['Picked Up', 'Cancelled'],
    'Picked Up': ['Delivered'],
  };
  return transitions[current]?.contains(next) ?? false;
}

class SellerFirebaseService {
  SellerFirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<SellerBootstrap> loadSeller(String uid) async {
    final userSnapshot = await _firestore.collection('users').doc(uid).get();
    if (userSnapshot.data()?['role'] != 'seller') {
      throw StateError('This account is not registered as a restaurant.');
    }

    final restaurantRef = _firestore.collection('restaurants').doc(uid);
    var restaurantSnapshot = await restaurantRef.get();
    if (!restaurantSnapshot.exists) {
      final applicationSnapshot = await _firestore
          .collection('sellerApplications')
          .doc(uid)
          .get();
      final application = applicationSnapshot.data();
      if (application == null) {
        throw StateError('Restaurant profile not found for this account.');
      }
      final address = application['address'];
      final restaurantName = _string(application['restaurantName']);
      final phone = _string(application['restaurantPhone']);
      final email = _string(application['restaurantEmail']);
      final cuisine = _string(application['cuisine'], fallback: 'Other');
      final migrated = <String, Object?>{
        'ownerId': uid,
        'restaurantName': restaurantName,
        'name': restaurantName,
        'description': _string(application['description']),
        'restaurantPhone': phone,
        'restaurantEmail': email,
        'phone': phone,
        'email': email,
        'address': address,
        'addressText': _addressText(address),
        'cuisine': cuisine,
        'openingTime': _string(application['openingTime']),
        'closingTime': _string(application['closingTime']),
        'workingDays': _stringList(application['workingDays']),
        'preparationMinutes': application['preparationMinutes'] ?? 25,
        'minimumOrderAmount': application['minimumOrderAmount'] ?? 0,
        'categories': [cuisine],
        'isOpen': true,
        'isApproved': true,
        'logoUrl': '',
        'coverImageUrl': '',
        'scheduledClosures': const <String>[],
        'createdAt': application['createdAt'] ?? FieldValue.serverTimestamp(),
      };
      await restaurantRef.set(migrated);
      restaurantSnapshot = await restaurantRef.get();
    }

    final user = userSnapshot.data()!;
    final restaurant = restaurantSnapshot.data()!;
    final List<QuerySnapshot<Map<String, dynamic>>> results = await Future.wait(
      [
        _firestore.collection('foods').where('ownerId', isEqualTo: uid).get(),
        _firestore.collection('orders').where('sellerId', isEqualTo: uid).get(),
        _firestore.collection('offers').where('sellerId', isEqualTo: uid).get(),
        _firestore
            .collection('notifications')
            .where('sellerId', isEqualTo: uid)
            .get(),
        _firestore.collection('reviews').where('ownerId', isEqualTo: uid).get(),
      ],
    );

    return SellerBootstrap(
      account: SellerAccount(
        sellerId: uid,
        ownerName: _string(user['name']),
        email: _string(restaurant['email'], fallback: _string(user['email'])),
        phone: _string(restaurant['phone'], fallback: _string(user['phone'])),
        restaurantId: uid,
        verificationStatus: 'Active',
        createdAt: _date(user['createdAt']),
      ),
      restaurant: _restaurant(uid, restaurant),
      foods: _foods(results[0], uid),
      orders: _orders(results[1]),
      offers: _offers(results[2]),
      notifications: _notifications(results[3]),
      reviews: _reviews(results[4]),
      categories: _stringList(restaurant['categories']),
      workingDays: _stringList(restaurant['workingDays']),
      scheduledClosures: _dateList(restaurant['scheduledClosures']),
    );
  }

  Stream<List<SellerFood>> watchFoods(String uid) => _firestore
      .collection('foods')
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) => _foods(snapshot, uid));

  Stream<List<SellerOrder>> watchOrders(String uid) => _firestore
      .collection('orders')
      .where('sellerId', isEqualTo: uid)
      .snapshots()
      .map(_orders);

  Stream<List<SellerOffer>> watchOffers(String uid) => _firestore
      .collection('offers')
      .where('sellerId', isEqualTo: uid)
      .snapshots()
      .map(_offers);

  Stream<List<SellerNotification>> watchNotifications(String uid) => _firestore
      .collection('notifications')
      .where('sellerId', isEqualTo: uid)
      .snapshots()
      .map(_notifications);

  Stream<List<SellerReview>> watchReviews(String uid) => _firestore
      .collection('reviews')
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map(_reviews);

  Stream<Map<String, dynamic>> watchRestaurant(String uid) =>
      _firestore.collection('restaurants').doc(uid).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (data == null) throw StateError('Restaurant profile was deleted.');
        return data;
      });

  String newFoodId() => _firestore.collection('foods').doc().id;
  String newOfferId() => _firestore.collection('offers').doc().id;

  Future<void> saveFood(SellerFood food) => _firestore
      .collection('foods')
      .doc(food.foodId)
      .set(_foodData(food), SetOptions(merge: true));

  Future<void> deleteFood(String foodId) =>
      _firestore.collection('foods').doc(foodId).delete();

  Future<void> setFoodAvailability(String foodId, bool value) =>
      _firestore.collection('foods').doc(foodId).update({'isAvailable': value});

  Future<void> updateStock(String foodId, int value) => _firestore
      .collection('foods')
      .doc(foodId)
      .update({'stock': value, 'isAvailable': value > 0});

  Future<void> saveRestaurant({
    required String uid,
    required String name,
    required String description,
    required String address,
    required String cuisine,
    required String phone,
    required String email,
  }) async {
    final batch = _firestore.batch();
    final restaurantRef = _firestore.collection('restaurants').doc(uid);
    batch.update(restaurantRef, {
      'name': name,
      'restaurantName': name,
      'description': description,
      'addressText': address,
      'cuisine': cuisine,
      'phone': phone,
      'restaurantPhone': phone,
      'email': email,
      'restaurantEmail': email,
    });
    final foodSnapshot = await _firestore
        .collection('foods')
        .where('ownerId', isEqualTo: uid)
        .get();
    for (final document in foodSnapshot.docs) {
      batch.update(document.reference, {
        'restaurantName': name,
        'cuisine': cuisine,
      });
    }
    batch.update(_firestore.collection('users').doc(uid), {'phone': phone});
    await batch.commit();
  }

  Future<void> setRestaurantOpen(String uid, bool value) =>
      _firestore.collection('restaurants').doc(uid).update({'isOpen': value});

  Future<void> saveHours({
    required String uid,
    required String opening,
    required String closing,
    required bool open,
    required Iterable<String> days,
    required Iterable<DateTime> closures,
  }) => _firestore.collection('restaurants').doc(uid).update({
    'openingTime': opening,
    'closingTime': closing,
    'isOpen': open,
    'workingDays': days.toList(),
    'scheduledClosures': closures.map(Timestamp.fromDate).toList(),
  });

  Future<void> saveCategory({
    required String uid,
    required String? previousName,
    required List<String> categories,
    required String? replacementCategory,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('restaurants').doc(uid), {
      'categories': categories,
    });
    if (previousName != null) {
      final foods = await _firestore
          .collection('foods')
          .where('ownerId', isEqualTo: uid)
          .get();
      for (final food in foods.docs.where(
        (document) => document.data()['category'] == previousName,
      )) {
        batch.update(food.reference, {'category': replacementCategory});
      }
    }
    await batch.commit();
  }

  Future<void> addOffer(SellerOffer offer) =>
      _firestore.collection('offers').doc(offer.offerId).set({
        'sellerId': offer.restaurantId,
        'restaurantId': offer.restaurantId,
        'name': offer.name,
        'description': offer.description,
        'type': offer.type,
        'value': offer.value,
        'minimumOrder': offer.minimumOrder,
        'maximumDiscount': offer.maximumDiscount,
        'startsAt': Timestamp.fromDate(offer.startsAt),
        'expiresAt': Timestamp.fromDate(offer.expiresAt),
        'active': offer.active,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> toggleOffer(String offerId, bool active) =>
      _firestore.collection('offers').doc(offerId).update({'active': active});

  Future<void> respondToReview(String reviewId, String response) => _firestore
      .collection('reviews')
      .doc(reviewId)
      .update({'response': response});

  Future<void> markNotificationRead(String id) =>
      _firestore.collection('notifications').doc(id).update({'isRead': true});

  Future<void> markAllNotificationsRead(String uid) async {
    final notifications = await _firestore
        .collection('notifications')
        .where('sellerId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final notification in notifications.docs) {
      batch.update(notification.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> updateOrderStatus(
    String sellerId,
    String orderId,
    String status, {
    String note = '',
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    final notificationRef = _firestore.collection('notifications').doc();
    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final order = orderSnapshot.data();
      if (order == null || order['sellerId'] != sellerId) {
        throw StateError('This order does not belong to this restaurant.');
      }
      final currentStatus = order['orderStatus'] as String? ?? '';
      if (!_canTransitionOrder(currentStatus, status)) {
        throw StateError(
          'Cannot change an order from $currentStatus to $status.',
        );
      }

      final stockChanges = <String, int>{};
      if (status == 'Rejected' || status == 'Cancelled') {
        for (final raw in order['items'] as List<dynamic>? ?? const []) {
          if (raw is! Map) continue;
          final foodId = raw['foodId'];
          final quantity = raw['quantity'];
          if (foodId is String && quantity is int) {
            stockChanges.update(
              foodId,
              (current) => current + quantity,
              ifAbsent: () => quantity,
            );
          }
        }
      }
      final foodRefs = {
        for (final foodId in stockChanges.keys)
          foodId: _firestore.collection('foods').doc(foodId),
      };
      final foodSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final entry in foodRefs.entries) {
        foodSnapshots[entry.key] = await transaction.get(entry.value);
      }

      transaction.update(orderRef, {
        'orderStatus': status,
        if (status == 'Delivered') 'paymentStatus': 'Paid',
        if (status == 'Rejected' || status == 'Cancelled')
          'paymentStatus': 'Not applicable',
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': status,
            'updatedAt': Timestamp.now(),
            'note': note.isEmpty
                ? 'Restaurant updated the order to $status.'
                : note,
          },
        ]),
      });
      for (final entry in foodSnapshots.entries) {
        final food = entry.value.data();
        if (food == null) continue;
        final stock = (food['stock'] as int? ?? 0) + stockChanges[entry.key]!;
        transaction.update(foodRefs[entry.key]!, {
          'stock': stock,
          'isAvailable': stock > 0,
        });
      }
      transaction.set(notificationRef, {
        'sellerId': order['sellerId'],
        'customerId': order['customerId'],
        'restaurantId': order['restaurantId'],
        'orderId': orderId,
        'title': 'Order $status',
        'message': 'Your order $orderId is now $status.',
        'type': 'Order Updates',
        'status': status,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updatePreparationTime(
    String sellerId,
    String orderId,
    int minutes,
  ) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final order = orderSnapshot.data();
      if (order == null ||
          order['sellerId'] != sellerId ||
          !['Accepted', 'Preparing'].contains(order['orderStatus'])) {
        throw StateError(
          'Preparation time can only be changed for active restaurant orders.',
        );
      }
      transaction.update(orderRef, {'preparationMinutes': minutes});
    });
  }

  SellerRestaurant _restaurant(String uid, Map<String, dynamic> data) =>
      SellerRestaurant(
        restaurantId: uid,
        sellerId: uid,
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        address:
            data['addressText'] as String? ?? _addressText(data['address']),
        cuisine: data['cuisine'] as String? ?? '',
        openingTime: data['openingTime'] as String? ?? '',
        closingTime: data['closingTime'] as String? ?? '',
        logoUrl: data['logoUrl'] as String? ?? '',
        coverImageUrl: data['coverImageUrl'] as String? ?? '',
        isOpen: data['isOpen'] as bool? ?? false,
        isApproved: data['isApproved'] as bool? ?? false,
      );

  List<SellerFood> _foods(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String uid,
  ) => [
    for (final document in snapshot.docs)
      _food(document.id, document.data(), uid),
  ];

  SellerFood _food(String id, Map<String, dynamic> data, String uid) =>
      SellerFood(
        foodId: id,
        restaurantId: uid,
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        imageUrl: data['imageUrl'] as String? ?? '',
        price: (data['price'] as num?)?.toInt() ?? 0,
        category: data['category'] as String? ?? 'Other',
        preparationTime: (data['preparationMinutes'] as num?)?.toInt() ?? 20,
        restaurantName: data['restaurantName'] as String? ?? '',
        cuisine: data['cuisine'] as String? ?? '',
        discountedPrice: (data['discountedPrice'] as num?)?.toInt(),
        available: data['isAvailable'] as bool? ?? false,
        vegetarian: data['isVegetarian'] as bool? ?? true,
        bestseller: data['bestseller'] as bool? ?? false,
        featured: data['featured'] as bool? ?? false,
        isDraft: data['isPublished'] != true,
        stock: (data['stock'] as num?)?.toInt() ?? 0,
        rating: (data['rating'] as num?)?.toDouble() ?? 0,
        popularity: (data['popularity'] as num?)?.toInt() ?? 0,
        createdAt: _date(data['createdAt']),
      );

  List<SellerOrder> _orders(QuerySnapshot<Map<String, dynamic>> snapshot) => [
    for (final document in snapshot.docs) _order(document.id, document.data()),
  ];

  SellerOrder _order(String id, Map<String, dynamic> data) {
    final address = data['deliveryAddress'];
    final statusHistory = data['statusHistory'];
    return SellerOrder(
      orderId: id,
      restaurantId: data['restaurantId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      deliveryAddress: address is Map
          ? [
              address['house'],
              address['street'],
              address['city'],
              address['state'],
              address['pincode'],
            ].whereType<String>().where((part) => part.isNotEmpty).join(', ')
          : '',
      items: [
        for (final raw in (data['items'] as List<dynamic>? ?? const []))
          if (raw is Map)
            SellerOrderItem(
              foodId: raw['foodId'] as String? ?? '',
              name: raw['name'] as String? ?? '',
              quantity: (raw['quantity'] as num?)?.toInt() ?? 0,
              unitPrice: (raw['unitPrice'] as num?)?.toInt() ?? 0,
              customizations:
                  (raw['customizations'] as List<dynamic>?)
                      ?.whereType<String>()
                      .toList() ??
                  const [],
            ),
      ],
      subtotal: (data['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toInt() ?? 0,
      discount: (data['discount'] as num?)?.toInt() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? 'Cash on Delivery',
      paymentStatus: data['paymentStatus'] as String? ?? 'Pending',
      orderStatus: data['orderStatus'] as String? ?? 'New',
      createdAt: _date(data['createdAt']),
      instructions: data['instructions'] as String? ?? '',
      preparationMinutes: (data['preparationMinutes'] as num?)?.toInt() ?? 25,
      statusHistory: statusHistory is List
          ? [
              for (final raw in statusHistory)
                if (raw is Map)
                  OrderStatusUpdate(
                    status: raw['status'] as String? ?? '',
                    updatedAt: _date(raw['updatedAt']),
                    note: raw['note'] as String? ?? '',
                  ),
            ]
          : null,
    );
  }

  List<SellerOffer> _offers(QuerySnapshot<Map<String, dynamic>> snapshot) => [
    for (final document in snapshot.docs) _offer(document.id, document.data()),
  ];

  SellerOffer _offer(String id, Map<String, dynamic> data) => SellerOffer(
    offerId: id,
    restaurantId: data['restaurantId'] as String? ?? '',
    name: data['name'] as String? ?? '',
    description: data['description'] as String? ?? '',
    type: data['type'] as String? ?? '',
    value: (data['value'] as num?)?.toInt() ?? 0,
    minimumOrder: (data['minimumOrder'] as num?)?.toInt() ?? 0,
    maximumDiscount: (data['maximumDiscount'] as num?)?.toInt() ?? 0,
    startsAt: _date(data['startsAt']),
    expiresAt: _date(data['expiresAt']),
    active: data['active'] as bool? ?? false,
  );

  List<SellerNotification> _notifications(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => [
    for (final document in snapshot.docs)
      _notification(document.id, document.data()),
  ];

  SellerNotification _notification(String id, Map<String, dynamic> data) =>
      SellerNotification(
        notificationId: id,
        sellerId: data['sellerId'] as String? ?? '',
        restaurantId: data['restaurantId'] as String? ?? '',
        orderId: data['orderId'] as String?,
        title: data['title'] as String? ?? '',
        message: data['message'] as String? ?? '',
        type: data['type'] as String? ?? '',
        createdAt: _date(data['createdAt']),
        isRead: data['isRead'] as bool? ?? false,
      );

  List<SellerReview> _reviews(QuerySnapshot<Map<String, dynamic>> snapshot) => [
    for (final document in snapshot.docs) _review(document.id, document.data()),
  ];

  SellerReview _review(String id, Map<String, dynamic> data) => SellerReview(
    reviewId: id,
    restaurantId: data['restaurantId'] as String? ?? '',
    customerName: data['customerName'] as String? ?? 'Customer',
    foodName: data['foodName'] as String? ?? '',
    rating: (data['rating'] as num?)?.toDouble() ?? 0,
    review: data['review'] as String? ?? '',
    createdAt: _date(data['createdAt']),
    response: data['response'] as String?,
  );

  Map<String, Object?> _foodData(SellerFood food) => {
    'ownerId': food.restaurantId,
    'restaurantId': food.restaurantId,
    'restaurantName': food.restaurantName,
    'name': food.name,
    'category': food.category,
    'price': food.price,
    'discountedPrice': food.discountedPrice,
    'description': food.description,
    'imageUrl': food.imageUrl,
    'cuisine': food.cuisine,
    'preparationMinutes': food.preparationTime,
    'stock': food.stock,
    'isAvailable': food.available && food.stock > 0,
    'isPublished': !food.isDraft,
    'isVegetarian': food.vegetarian,
    'bestseller': food.bestseller,
    'featured': food.featured,
    'rating': food.rating,
    'reviews': 0,
    'popularity': food.popularity,
    'createdAt': Timestamp.fromDate(food.createdAt),
  };

  String _addressText(Object? value) {
    if (value is! Map) return '';
    return [
      value['street'],
      value['area'],
      value['city'],
      value['state'],
      value['pincode'],
      value['country'],
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
  }

  List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  List<DateTime> _dateList(Object? value) =>
      value is List ? value.map(_date).toList() : const [];

  DateTime _date(Object? value) => value is Timestamp
      ? value.toDate()
      : DateTime.fromMillisecondsSinceEpoch(0);
}
