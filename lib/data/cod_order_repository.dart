import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food.dart';

class CodOrderRepository {
  CodOrderRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<CraveOrder>> watchCustomerOrders(String customerId) => _firestore
      .collection('orders')
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map((snapshot) {
        final orders = snapshot.docs
            .map((document) => _order(document.id, document.data()))
            .toList();
        orders.sort(
          (first, second) =>
              (second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                    first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                  ),
        );
        return orders;
      });

  Future<CraveOrder> createOrder({
    required String restaurantId,
    required List<CartLine> items,
    required DeliveryAddress address,
    required String instructions,
  }) async {
    if (items.isEmpty || items.length > 5) {
      throw StateError('An order must contain between 1 and 5 menu lines.');
    }
    if (restaurantId.isEmpty ||
        instructions.length > 500 ||
        [
          address.name,
          address.phone,
          address.house,
          address.street,
          address.city,
          address.state,
          address.pincode,
        ].any((value) => value.trim().isEmpty)) {
      throw StateError('Add valid delivery details before placing your order.');
    }
    if (items.any(
      (item) =>
          item.quantity < 1 ||
          item.quantity > 20 ||
          item.customizations.length > 10 ||
          item.customizations.any((value) => value.length > 500),
    )) {
      throw StateError(
        'The order contains invalid item quantities or options.',
      );
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in before placing an order.');
    final userRef = _firestore.collection('users').doc(uid);
    final orderRef = _firestore.collection('orders').doc();
    final restaurantRef = _firestore
        .collection('restaurants')
        .doc(restaurantId);
    final foodRefs = <String, DocumentReference<Map<String, dynamic>>>{
      for (final item in items)
        item.food.id: _firestore.collection('foods').doc(item.food.id),
    };
    if (foodRefs.keys.any((foodId) => foodId.isEmpty)) {
      throw StateError('The order contains invalid menu items.');
    }
    final notificationRef = _firestore.collection('notifications').doc();

    final orderData = await _firestore.runTransaction((transaction) async {
      final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      final userSnapshot = await transaction.get(userRef);
      final restaurantSnapshot = await transaction.get(restaurantRef);
      for (final entry in foodRefs.entries) {
        snapshots[entry.key] = await transaction.get(entry.value);
      }

      final customer = userSnapshot.data();
      final restaurant = restaurantSnapshot.data();
      if (customer?['role'] != 'customer') {
        throw StateError('Only customer accounts can place orders.');
      }
      if (restaurant == null ||
          restaurant['ownerId'] != restaurantId ||
          restaurant['isOpen'] != true) {
        throw StateError('This restaurant is not accepting orders.');
      }

      final orderItems = <Map<String, Object?>>[];
      final stockChanges = <String, int>{};
      var totalAmount = 0;
      for (final item in items) {
        final snapshot = snapshots[item.food.id]!;
        final food = snapshot.data();
        if (food == null ||
            food['restaurantId'] != restaurantId ||
            food['isPublished'] != true ||
            food['isAvailable'] != true) {
          throw StateError('${item.food.name} is no longer available.');
        }
        final quantity = stockChanges.update(
          item.food.id,
          (current) => current + item.quantity,
          ifAbsent: () => item.quantity,
        );
        if (quantity > 20) {
          throw StateError('You can order up to 20 portions of each item.');
        }
        final stock = food['stock'];
        if (stock is! int || stock < quantity) {
          throw StateError('${item.food.name} does not have enough stock.');
        }
        final price = food['price'];
        final discountedPrice = food['discountedPrice'];
        final unitPrice =
            discountedPrice is int &&
                discountedPrice > 0 &&
                price is int &&
                discountedPrice < price
            ? discountedPrice
            : price;
        if (unitPrice is! int || unitPrice < 1) {
          throw StateError('${item.food.name} has an invalid price.');
        }
        final lineTotal = unitPrice * item.quantity;
        totalAmount += lineTotal;
        orderItems.add({
          'foodId': item.food.id,
          'name': food['name'] as String? ?? item.food.name,
          'category': food['category'] as String? ?? 'Other',
          'description': food['description'] as String? ?? '',
          'imageUrl': food['imageUrl'] as String? ?? '',
          'cuisine':
              food['cuisine'] as String? ??
              restaurant['cuisine'] as String? ??
              'Other',
          'preparationMinutes': food['preparationMinutes'] as int? ?? 20,
          'isVegetarian': food['isVegetarian'] as bool? ?? false,
          'customizations': item.customizations,
          'quantity': item.quantity,
          'unitPrice': unitPrice,
          'lineTotal': lineTotal,
        });
      }
      final minimumOrder = restaurant['minimumOrderAmount'];
      if (minimumOrder is int && totalAmount < minimumOrder) {
        throw StateError('The minimum order amount is ₹$minimumOrder.');
      }

      final createdAt = Timestamp.now();
      final order = <String, Object?>{
        'orderId': orderRef.id,
        'restaurantId': restaurantId,
        'restaurantName': restaurant['name'] as String? ?? '',
        'sellerId': restaurantId,
        'customerId': uid,
        'customerName': customer?['name'] as String? ?? '',
        'customerPhone': customer?['phone'] as String? ?? address.phone,
        'items': orderItems,
        'foodIds': stockChanges.keys.toList(),
        'inventoryChanges': stockChanges,
        'subtotal': totalAmount,
        'deliveryFee': 0,
        'discount': 0,
        'totalAmount': totalAmount,
        'paymentMethod': 'Cash on Delivery',
        'paymentStatus': 'Pending',
        'orderStatus': 'New',
        'deliveryAddress': {
          'name': address.name,
          'phone': address.phone,
          'house': address.house,
          'street': address.street,
          'city': address.city,
          'state': address.state,
          'pincode': address.pincode,
        },
        'instructions': instructions,
        'preparationMinutes': restaurant['preparationMinutes'] as int? ?? 25,
        'statusHistory': [
          {
            'status': 'New',
            'updatedAt': createdAt,
            'note': 'Customer placed a cash-on-delivery order.',
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      };

      transaction.set(orderRef, order);
      for (final entry in stockChanges.entries) {
        final food = snapshots[entry.key]!.data()!;
        final remainingStock = (food['stock'] as int) - entry.value;
        transaction.update(foodRefs[entry.key]!, {
          'stock': remainingStock,
          'isAvailable': remainingStock > 0,
          'lastOrderId': orderRef.id,
        });
      }
      transaction.set(notificationRef, {
        'sellerId': restaurantId,
        'customerId': uid,
        'restaurantId': restaurantId,
        'orderId': orderRef.id,
        'title': 'New order received',
        'message': 'Order ${orderRef.id} is waiting for a response.',
        'type': 'New Orders',
        'status': 'New',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return {...order, 'createdAt': createdAt};
    });
    return _order(orderRef.id, orderData);
  }

  CraveOrder _order(String id, Map<String, dynamic> data) {
    final rawAddress = data['deliveryAddress'];
    final address = rawAddress is Map
        ? DeliveryAddress(
            id: 'order-address',
            name: rawAddress['name'] as String? ?? '',
            phone: rawAddress['phone'] as String? ?? '',
            house: rawAddress['house'] as String? ?? '',
            street: rawAddress['street'] as String? ?? '',
            city: rawAddress['city'] as String? ?? '',
            state: rawAddress['state'] as String? ?? '',
            pincode: rawAddress['pincode'] as String? ?? '',
            type: 'Delivery',
          )
        : null;
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    final items = <CartLine>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final food = Food(
        id: raw['foodId'] as String? ?? '',
        name: raw['name'] as String? ?? '',
        category: raw['category'] as String? ?? 'Other',
        price: (raw['unitPrice'] as num?)?.toInt() ?? 0,
        rating: 0,
        reviews: 0,
        description: raw['description'] as String? ?? '',
        imageUrl: raw['imageUrl'] as String? ?? '',
        cuisine: raw['cuisine'] as String? ?? 'Other',
        preparationMinutes: (raw['preparationMinutes'] as num?)?.toInt() ?? 20,
        isVegetarian: raw['isVegetarian'] as bool? ?? false,
      );
      items.add(
        CartLine(
          food: food,
          quantity: (raw['quantity'] as num?)?.toInt() ?? 0,
          customizations:
              (raw['customizations'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList() ??
              const [],
        ),
      );
    }

    final createdAt = data['createdAt'];
    return CraveOrder(
      id: id,
      items: List.unmodifiable(items),
      total: (data['totalAmount'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (data['preparationMinutes'] as num?)?.toInt() ?? 30,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      status: data['orderStatus'] as String? ?? 'New',
      paymentMethod: data['paymentMethod'] as String? ?? 'Cash on Delivery',
      deliveryAddress: address,
      deliveryInstructions: data['instructions'] as String? ?? '',
      restaurantId: data['restaurantId'] as String? ?? '',
    );
  }
}
