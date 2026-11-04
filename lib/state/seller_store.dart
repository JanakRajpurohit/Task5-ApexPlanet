import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/seller_firebase_service.dart';
import '../models/seller_models.dart';

class SellerStore extends ChangeNotifier {
  SellerStore({
    SellerAccount? account,
    SellerRestaurant? restaurant,
    List<SellerFood>? foods,
    List<SellerOrder>? orders,
    List<SellerOffer>? offers,
    List<SellerNotification>? notifications,
    List<SellerReview>? reviews,
    List<String>? categories,
    this.firebaseService,
  }) : account =
           account ??
           SellerAccount(
             sellerId: '',
             ownerName: '',
             email: '',
             phone: '',
             restaurantId: '',
             verificationStatus: 'Pending',
             createdAt: DateTime.fromMillisecondsSinceEpoch(0),
           ),
       restaurant =
           restaurant ??
           SellerRestaurant(
             restaurantId: '',
             sellerId: '',
             name: '',
             description: '',
             address: '',
             cuisine: '',
             openingTime: '',
             closingTime: '',
             isOpen: false,
             isApproved: false,
           ),
       foods = foods ?? [],
       orders = orders ?? [],
       offers = offers ?? [],
       notifications = notifications ?? [],
       reviews = reviews ?? [],
       categories = categories ?? [];

  final SellerFirebaseService? firebaseService;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Set<String> _pendingOrderUpdates = {};
  SellerAccount account;
  SellerRestaurant restaurant;
  final List<SellerFood> foods;
  final List<SellerOrder> orders;
  final List<SellerOffer> offers;
  final List<SellerNotification> notifications;
  final List<SellerReview> reviews;
  final List<String> categories;
  int _nextId = 1;
  bool orderNotifications = true;
  bool reviewNotifications = true;
  bool promotionalNotifications = true;
  String? operationError;
  final Set<String> workingDays = {};
  final List<DateTime> scheduledClosures = [];

  List<SellerFood> get restaurantFoods => foods
      .where((food) => food.restaurantId == restaurant.restaurantId)
      .toList();

  List<SellerOrder> get restaurantOrders => orders
      .where((order) => order.restaurantId == restaurant.restaurantId)
      .toList();

  List<SellerOffer> get restaurantOffers => offers
      .where((offer) => offer.restaurantId == restaurant.restaurantId)
      .toList();

  List<SellerNotification> get restaurantNotifications => notifications
      .where(
        (notification) =>
            notification.restaurantId == restaurant.restaurantId &&
            notification.sellerId == account.sellerId,
      )
      .toList();

  List<SellerReview> get restaurantReviews => reviews
      .where((review) => review.restaurantId == restaurant.restaurantId)
      .toList();

  int get unreadNotifications => restaurantNotifications
      .where((notification) => !notification.isRead)
      .length;

  bool isOrderUpdatePending(String orderId) =>
      _pendingOrderUpdates.contains(orderId);

  int get pendingOrders =>
      restaurantOrders.where((order) => order.orderStatus == 'New').length;

  int get completedOrders => restaurantOrders
      .where(
        (order) =>
            order.orderStatus == 'Completed' ||
            order.orderStatus == 'Delivered',
      )
      .length;

  int get todayOrders => restaurantOrders
      .where((order) => _sameDay(order.createdAt, DateTime.now()))
      .length;

  int get todayRevenue => restaurantOrders
      .where(
        (order) =>
            _sameDay(order.createdAt, DateTime.now()) &&
            (order.orderStatus == 'Completed' ||
                order.orderStatus == 'Delivered'),
      )
      .fold(0, (total, order) => total + order.totalAmount);

  double get averageRating {
    if (restaurantReviews.isEmpty) return 0;
    return restaurantReviews.fold<double>(
          0,
          (total, review) => total + review.rating,
        ) /
        restaurantReviews.length;
  }

  void startRealtime(String uid) {
    final service = firebaseService;
    if (service == null) return;
    _subscriptions.add(
      service
          .watchFoods(uid)
          .listen((items) => _replace(foods, items), onError: _recordError),
    );
    _subscriptions.add(
      service
          .watchOrders(uid)
          .listen((items) => _replace(orders, items), onError: _recordError),
    );
    _subscriptions.add(
      service
          .watchOffers(uid)
          .listen((items) => _replace(offers, items), onError: _recordError),
    );
    _subscriptions.add(
      service
          .watchNotifications(uid)
          .listen(
            (items) => _replace(notifications, items),
            onError: _recordError,
          ),
    );
    _subscriptions.add(
      service
          .watchReviews(uid)
          .listen((items) => _replace(reviews, items), onError: _recordError),
    );
    _subscriptions.add(
      service.watchRestaurant(uid).listen((data) {
        restaurant
          ..name = data['name'] as String? ?? restaurant.name
          ..description =
              data['description'] as String? ?? restaurant.description
          ..address = data['addressText'] as String? ?? restaurant.address
          ..cuisine = data['cuisine'] as String? ?? restaurant.cuisine
          ..openingTime =
              data['openingTime'] as String? ?? restaurant.openingTime
          ..closingTime =
              data['closingTime'] as String? ?? restaurant.closingTime
          ..isOpen = data['isOpen'] as bool? ?? restaurant.isOpen;
        account = SellerAccount(
          sellerId: account.sellerId,
          ownerName: account.ownerName,
          email: data['email'] as String? ?? account.email,
          phone: data['phone'] as String? ?? account.phone,
          restaurantId: account.restaurantId,
          verificationStatus: account.verificationStatus,
          createdAt: account.createdAt,
        );
        categories
          ..clear()
          ..addAll(_stringList(data['categories']));
        workingDays
          ..clear()
          ..addAll(_stringList(data['workingDays']));
        scheduledClosures
          ..clear()
          ..addAll(_dateList(data['scheduledClosures']));
        notifyListeners();
      }, onError: _recordError),
    );
  }

  void _replace<T>(List<T> target, List<T> values) {
    target
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  void _recordError(Object error) {
    operationError = error.toString();
    notifyListeners();
  }

  void clearOperationError() {
    operationError = null;
    notifyListeners();
  }

  void _persist(Future<void> Function() action) {
    if (firebaseService == null) return;
    operationError = null;
    unawaited(() async {
      try {
        await action();
      } on Object catch (error, stackTrace) {
        operationError = error.toString();
        debugPrint('Seller operation failed: $error\n$stackTrace');
        notifyListeners();
      }
    }());
  }

  List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  List<DateTime> _dateList(Object? value) => value is List
      ? value
            .map(
              (item) => item is Timestamp
                  ? item.toDate()
                  : item is DateTime
                  ? item
                  : null,
            )
            .whereType<DateTime>()
            .toList()
      : const [];

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  void setRestaurantOpen(bool value) {
    restaurant.isOpen = value;
    notifyListeners();
    _persist(() => firebaseService!.setRestaurantOpen(account.sellerId, value));
  }

  SellerOrder? orderById(String orderId) {
    for (final order in restaurantOrders) {
      if (order.orderId == orderId) return order;
    }
    return null;
  }

  Future<bool> updateOrderStatus(
    String orderId,
    String nextStatus, {
    String note = '',
  }) {
    final order = orderById(orderId);
    if (order == null) return Future.value(false);
    const transitions = <String, List<String>>{
      'New': ['Accepted', 'Rejected'],
      'Accepted': ['Preparing', 'Cancelled'],
      'Preparing': ['Ready for Pickup', 'Cancelled'],
      'Ready for Pickup': ['Picked Up', 'Cancelled'],
      'Picked Up': ['Delivered'],
    };
    if (!(transitions[order.orderStatus]?.contains(nextStatus) ?? false)) {
      return Future.value(false);
    }
    if (firebaseService != null) {
      if (!_pendingOrderUpdates.add(orderId)) return Future.value(false);
      notifyListeners();
      return _submitOrderStatus(orderId, order.orderStatus, nextStatus, note);
    }
    order.orderStatus = nextStatus;
    order.statusHistory.add(
      OrderStatusUpdate(
        status: nextStatus,
        updatedAt: DateTime.now(),
        note: note,
      ),
    );
    if (firebaseService == null) {
      _addNotification(
        title: 'Order $nextStatus',
        message: '${order.orderId} has been updated to $nextStatus.',
        type: 'Order Updates',
        orderId: orderId,
      );
    }
    notifyListeners();
    return Future.value(true);
  }

  Future<bool> _submitOrderStatus(
    String orderId,
    String previousStatus,
    String nextStatus,
    String note,
  ) async {
    try {
      await firebaseService!.updateOrderStatus(
        account.sellerId,
        orderId,
        nextStatus,
        note: note,
      );
      operationError = null;
      final order = orderById(orderId);
      if (order != null && order.orderStatus == previousStatus) {
        order.orderStatus = nextStatus;
        if (nextStatus == 'Delivered') order.paymentStatus = 'Paid';
        if (nextStatus == 'Rejected' || nextStatus == 'Cancelled') {
          order.paymentStatus = 'Not applicable';
        }
        order.statusHistory.add(
          OrderStatusUpdate(
            status: nextStatus,
            updatedAt: DateTime.now(),
            note: note.isEmpty
                ? 'Restaurant updated the order to $nextStatus.'
                : note,
          ),
        );
      }
      return true;
    } on Object catch (error, stackTrace) {
      operationError = error.toString();
      debugPrint('Seller operation failed: $error\n$stackTrace');
      return false;
    } finally {
      _pendingOrderUpdates.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> updatePreparationTime(String orderId, int minutes) async {
    final order = orderById(orderId);
    if (order == null || minutes < 5 || minutes > 180) return false;
    if (firebaseService != null) {
      try {
        await firebaseService!.updatePreparationTime(
          account.sellerId,
          orderId,
          minutes,
        );
        operationError = null;
      } on Object catch (error, stackTrace) {
        operationError = error.toString();
        debugPrint('Seller operation failed: $error\n$stackTrace');
        notifyListeners();
        return false;
      }
    }
    order.preparationMinutes = minutes;
    notifyListeners();
    return true;
  }

  void saveFood({
    String? foodId,
    required String name,
    required String description,
    required String imageUrl,
    required int price,
    required String category,
    required int preparationTime,
    int? discountedPrice,
    bool available = true,
    bool vegetarian = true,
    bool bestseller = false,
    bool featured = false,
    bool isDraft = false,
    int stock = 20,
  }) {
    final food = foodId == null
        ? SellerFood(
            foodId: firebaseService?.newFoodId() ?? 'food-${_nextId++}',
            restaurantId: restaurant.restaurantId,
            name: name,
            description: description,
            imageUrl: imageUrl,
            price: price,
            category: category,
            preparationTime: preparationTime,
            restaurantName: restaurant.name,
            cuisine: restaurant.cuisine,
            discountedPrice: discountedPrice,
            available: available,
            vegetarian: vegetarian,
            bestseller: bestseller,
            featured: featured,
            isDraft: isDraft,
            stock: stock,
          )
        : restaurantFoods.firstWhere((item) => item.foodId == foodId);
    if (foodId != null) {
      food
        ..name = name
        ..description = description
        ..imageUrl = imageUrl
        ..price = price
        ..category = category
        ..preparationTime = preparationTime
        ..restaurantName = restaurant.name
        ..cuisine = restaurant.cuisine
        ..discountedPrice = discountedPrice
        ..available = available
        ..vegetarian = vegetarian
        ..bestseller = bestseller
        ..featured = featured
        ..isDraft = isDraft
        ..stock = stock;
    } else {
      foods.add(food);
    }
    notifyListeners();
    _persist(() => firebaseService!.saveFood(food));
  }

  void deleteFood(String foodId) {
    foods.removeWhere(
      (food) =>
          food.foodId == foodId && food.restaurantId == restaurant.restaurantId,
    );
    notifyListeners();
    _persist(() => firebaseService!.deleteFood(foodId));
  }

  void saveCategory(String? previousName, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (previousName != null) {
      final index = categories.indexOf(previousName);
      if (index >= 0) categories[index] = trimmed;
      for (final food in restaurantFoods.where(
        (item) => item.category == previousName,
      )) {
        food.category = trimmed;
      }
    } else if (!categories.any(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    )) {
      categories.add(trimmed);
    }
    notifyListeners();
    _persist(
      () => firebaseService!.saveCategory(
        uid: account.sellerId,
        previousName: previousName,
        categories: categories,
        replacementCategory: previousName == null ? null : trimmed,
      ),
    );
  }

  void deleteCategory(String name) {
    if (categories.length <= 1) return;
    categories.remove(name);
    for (final food in restaurantFoods.where((item) => item.category == name)) {
      food.category = categories.first;
    }
    notifyListeners();
    _persist(
      () => firebaseService!.saveCategory(
        uid: account.sellerId,
        previousName: name,
        categories: categories,
        replacementCategory: categories.first,
      ),
    );
  }

  void setFoodAvailability(String foodId, bool value) {
    final food = restaurantFoods
        .where((item) => item.foodId == foodId)
        .firstOrNull;
    if (food == null) return;
    food.available = value && food.stock > 0;
    notifyListeners();
    _persist(
      () => firebaseService!.setFoodAvailability(foodId, food.available),
    );
  }

  void updateStock(String foodId, int value) {
    final food = restaurantFoods
        .where((item) => item.foodId == foodId)
        .firstOrNull;
    if (food == null || value < 0) return;
    food.stock = value;
    food.available = value > 0;
    notifyListeners();
    _persist(() => firebaseService!.updateStock(foodId, value));
  }

  void saveRestaurant({
    required String name,
    required String description,
    required String address,
    required String cuisine,
    required String phone,
    required String email,
  }) {
    restaurant
      ..name = name
      ..description = description
      ..address = address
      ..cuisine = cuisine;
    account = SellerAccount(
      sellerId: account.sellerId,
      ownerName: account.ownerName,
      email: email,
      phone: phone,
      restaurantId: account.restaurantId,
      verificationStatus: account.verificationStatus,
      createdAt: account.createdAt,
    );
    notifyListeners();
    _persist(
      () => firebaseService!.saveRestaurant(
        uid: account.sellerId,
        name: name,
        description: description,
        address: address,
        cuisine: cuisine,
        phone: phone,
        email: email,
      ),
    );
  }

  void saveHours(
    String opening,
    String closing, {
    required bool open,
    required Iterable<String> days,
    required Iterable<DateTime> closures,
  }) {
    restaurant
      ..openingTime = opening
      ..closingTime = closing
      ..isOpen = open;
    workingDays
      ..clear()
      ..addAll(days);
    scheduledClosures
      ..clear()
      ..addAll(closures);
    notifyListeners();
    _persist(
      () => firebaseService!.saveHours(
        uid: account.sellerId,
        opening: opening,
        closing: closing,
        open: open,
        days: days,
        closures: closures,
      ),
    );
  }

  void addOffer({
    required String name,
    required String description,
    required String type,
    required int value,
    required int minimumOrder,
    required int maximumDiscount,
    required DateTime startsAt,
    required DateTime expiresAt,
  }) {
    offers.insert(
      0,
      SellerOffer(
        offerId: firebaseService?.newOfferId() ?? 'offer-${_nextId++}',
        restaurantId: restaurant.restaurantId,
        name: name,
        description: description,
        type: type,
        value: value,
        minimumOrder: minimumOrder,
        maximumDiscount: maximumDiscount,
        startsAt: startsAt,
        expiresAt: expiresAt,
      ),
    );
    notifyListeners();
    _persist(() => firebaseService!.addOffer(offers.first));
  }

  void toggleOffer(String offerId) {
    final offer = restaurantOffers
        .where((item) => item.offerId == offerId)
        .firstOrNull;
    if (offer == null) return;
    offer.active = !offer.active;
    notifyListeners();
    _persist(() => firebaseService!.toggleOffer(offerId, offer.active));
  }

  void respondToReview(String reviewId, String response) {
    final review = restaurantReviews
        .where((item) => item.reviewId == reviewId)
        .firstOrNull;
    if (review == null) return;
    review.response = response;
    notifyListeners();
    _persist(() => firebaseService!.respondToReview(reviewId, response));
  }

  void markNotificationRead(String id) {
    final notification = restaurantNotifications
        .where((item) => item.notificationId == id)
        .firstOrNull;
    if (notification == null) return;
    notification.isRead = true;
    notifyListeners();
    _persist(() => firebaseService!.markNotificationRead(id));
  }

  void markAllNotificationsRead() {
    for (final notification in restaurantNotifications) {
      notification.isRead = true;
    }
    notifyListeners();
    _persist(() => firebaseService!.markAllNotificationsRead(account.sellerId));
  }

  void setNotificationPreference(String category, bool value) {
    switch (category) {
      case 'orders':
        orderNotifications = value;
      case 'reviews':
        reviewNotifications = value;
      case 'promotions':
        promotionalNotifications = value;
    }
    notifyListeners();
  }

  void _addNotification({
    required String title,
    required String message,
    required String type,
    String? orderId,
  }) {
    notifications.insert(
      0,
      SellerNotification(
        notificationId: 'notice-${_nextId++}',
        sellerId: account.sellerId,
        restaurantId: restaurant.restaurantId,
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        orderId: orderId,
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
