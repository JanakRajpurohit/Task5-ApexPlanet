import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/catalog_repository.dart';
import '../data/cod_order_repository.dart';
import '../models/food.dart';
import '../services/firebase_auth_service.dart';
import 'seller_store.dart';

class CraveStore extends ChangeNotifier {
  CraveStore(
    List<Food> initialFoods, {
    SellerStore? sellerStore,
    this.catalogRepository,
    this.codOrderRepository,
    this.authService,
  }) : foods = List.of(initialFoods),
       sellerStore = sellerStore ?? SellerStore() {
    this.sellerStore.addListener(_onSellerDataChanged);
  }

  final List<Food> foods;
  final SellerStore sellerStore;
  final CatalogRepository? catalogRepository;
  final CodOrderRepository? codOrderRepository;
  final FirebaseAuthService? authService;
  final Map<String, int> _cart = {};
  final Map<String, List<String>> _customizations = {};
  final Map<String, int> _extraEach = {};
  final Set<String> _favourites = {};
  final List<String> _recentSearches = [];
  final List<CraveOrder> _orders = [];
  final List<DeliveryAddress> addresses = [];
  StreamSubscription<List<Food>>? _catalogSubscription;
  StreamSubscription<List<CraveOrder>>? _ordersSubscription;
  String? _ordersUid;
  bool catalogLoading = false;
  Object? catalogError;
  Object? ordersError;
  String _query = '';
  String _category = 'All';
  FoodSort _sort = FoodSort.popular;
  String _selectedAddressId = '';
  String deliveryInstructions = '';
  CraveOrder? lastOrder;
  String profileName = '';
  String profileEmail = '';
  String profilePhone = '';
  bool darkMode = false;
  bool orderNotifications = true;
  bool promotionalNotifications = true;
  String language = 'English';

  List<String> get categories => [
    'All',
    ...foods.map((food) => food.category).toSet().toList()..sort(),
  ];
  String get query => _query;
  String get category => _category;
  FoodSort get sort => _sort;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  Set<String> get favourites => Set.unmodifiable(_favourites);
  List<CraveOrder> get orders => List.unmodifiable(_orders);
  DeliveryAddress get selectedAddress => addresses.firstWhere(
    (address) => address.id == _selectedAddressId,
    orElse: () => const DeliveryAddress(
      id: '',
      name: '',
      phone: '',
      house: '',
      street: '',
      city: '',
      state: '',
      pincode: '',
      type: 'Add address',
    ),
  );

  List<CartLine> get cartItems => [
    for (final entry in _cart.entries)
      CartLine(
        food: foodById(_foodIdFor(entry.key))!,
        quantity: entry.value,
        lineId: entry.key,
        customizations: _customizations[entry.key] ?? const [],
        extraEach: _extraEach[entry.key] ?? 0,
      ),
  ];

  int get cartItemCount =>
      _cart.values.fold(0, (total, count) => total + count);

  int get cartSubtotal =>
      cartItems.fold(0, (total, item) => total + item.total);

  int get cartTotal => _cart.isEmpty ? 0 : cartSubtotal;

  List<Food> get catalogFoods => List.unmodifiable(foods);

  void startCatalog() {
    final repository = catalogRepository;
    if (repository == null) return;
    unawaited(_catalogSubscription?.cancel());
    catalogLoading = true;
    catalogError = null;
    notifyListeners();
    _catalogSubscription = repository.watchFoods().listen(
      (items) {
        foods
          ..clear()
          ..addAll(items);
        final availableIds = items.map((food) => food.id).toSet();
        final removedLines = _cart.keys
            .where((lineId) => !availableIds.contains(_foodIdFor(lineId)))
            .toList();
        for (final lineId in removedLines) {
          _removeLine(lineId);
        }
        catalogLoading = false;
        catalogError = null;
        notifyListeners();
      },
      onError: (Object error) {
        catalogLoading = false;
        catalogError = error;
        notifyListeners();
      },
    );
  }

  void setProfile({
    required String name,
    required String email,
    required String phone,
  }) {
    if (profileName == name && profileEmail == email && profilePhone == phone) {
      return;
    }
    profileName = name;
    profileEmail = email;
    profilePhone = phone;
    notifyListeners();
  }

  void startCustomerOrders(String customerId) {
    final repository = codOrderRepository;
    if (repository == null || _ordersUid == customerId) return;
    unawaited(_ordersSubscription?.cancel());
    _ordersUid = customerId;
    ordersError = null;
    _ordersSubscription = repository
        .watchCustomerOrders(customerId)
        .listen(
          (items) {
            _orders
              ..clear()
              ..addAll(items);
            if (lastOrder != null) {
              lastOrder = items
                  .where((order) => order.id == lastOrder!.id)
                  .firstOrNull;
            }
            ordersError = null;
            notifyListeners();
          },
          onError: (Object error) {
            ordersError = error;
            notifyListeners();
          },
        );
  }

  void stopCustomerOrders() {
    if (_ordersSubscription == null &&
        _ordersUid == null &&
        _orders.isEmpty &&
        lastOrder == null &&
        ordersError == null) {
      return;
    }
    unawaited(_ordersSubscription?.cancel());
    _ordersSubscription = null;
    _ordersUid = null;
    _orders.clear();
    lastOrder = null;
    ordersError = null;
    notifyListeners();
  }

  List<Food> get filteredFoods {
    final normalizedQuery = _query.trim().toLowerCase();
    final results = catalogFoods.where((food) {
      final matchesCategory = _category == 'All' || food.category == _category;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          food.name.toLowerCase().contains(normalizedQuery) ||
          food.category.toLowerCase().contains(normalizedQuery) ||
          food.cuisine.toLowerCase().contains(normalizedQuery) ||
          food.ingredients.any(
            (ingredient) => ingredient.toLowerCase().contains(normalizedQuery),
          );
      return matchesCategory && matchesQuery;
    }).toList();
    switch (_sort) {
      case FoodSort.popular:
        results.sort((a, b) => b.reviews.compareTo(a.reviews));
      case FoodSort.priceLowToHigh:
        results.sort((a, b) => a.price.compareTo(b.price));
      case FoodSort.priceHighToLow:
        results.sort((a, b) => b.price.compareTo(a.price));
      case FoodSort.highestRated:
        results.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return results;
  }

  List<Food> get favouriteFoods =>
      catalogFoods.where((food) => _favourites.contains(food.id)).toList();

  Food? foodById(String id) {
    for (final food in catalogFoods) {
      if (food.id == id) return food;
    }
    return null;
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void addToCart(
    Food food, {
    int quantity = 1,
    List<String> customizations = const [],
    int extraEach = 0,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive.');
    }
    if (!food.isAvailable) {
      throw StateError('This food item is currently unavailable.');
    }
    if (food.restaurantId.isNotEmpty &&
        cartItems.any(
          (line) =>
              line.food.restaurantId.isNotEmpty &&
              line.food.restaurantId != food.restaurantId,
        )) {
      throw StateError('Place a separate order for each restaurant.');
    }
    final options = [...customizations]..sort();
    final lineId = options.isEmpty
        ? food.id
        : '${food.id}|${options.join('|')}';
    _customizations[lineId] = List.unmodifiable(options);
    _extraEach[lineId] = extraEach;
    _cart.update(
      lineId,
      (current) => current + quantity,
      ifAbsent: () => quantity,
    );
    notifyListeners();
  }

  void changeQuantity(String foodId, int delta) {
    final lineId = _resolveLineId(foodId);
    if (lineId == null) return;
    final current = _cart[lineId];
    if (current == null) return;
    final next = current + delta;
    if (next <= 0) {
      _removeLine(lineId);
    } else {
      _cart[lineId] = next;
    }
    notifyListeners();
  }

  void removeFromCart(String foodId) {
    final lineId = _resolveLineId(foodId);
    if (lineId != null) _removeLine(lineId);
    notifyListeners();
  }

  String _foodIdFor(String lineId) => lineId.split('|').first;

  String? _resolveLineId(String idOrFoodId) {
    if (_cart.containsKey(idOrFoodId)) return idOrFoodId;
    for (final id in _cart.keys) {
      if (_foodIdFor(id) == idOrFoodId) return id;
    }
    return null;
  }

  void _removeLine(String lineId) {
    _cart.remove(lineId);
    _customizations.remove(lineId);
    _extraEach.remove(lineId);
  }

  void _onSellerDataChanged() => notifyListeners();

  @override
  void dispose() {
    sellerStore.removeListener(_onSellerDataChanged);
    unawaited(_catalogSubscription?.cancel());
    unawaited(_ordersSubscription?.cancel());
    super.dispose();
  }

  void toggleFavourite(String foodId) {
    if (!_favourites.add(foodId)) _favourites.remove(foodId);
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String phone,
    String? email,
  }) {
    profileName = name;
    profilePhone = phone;
    if (email != null) profileEmail = email;
    final previousAddresses = List<DeliveryAddress>.of(addresses);
    addresses
      ..clear()
      ..addAll(
        previousAddresses.map(
          (address) => DeliveryAddress(
            id: address.id,
            name: name,
            phone: phone,
            house: address.house,
            street: address.street,
            city: address.city,
            state: address.state,
            pincode: address.pincode,
            type: address.type,
            isDefault: address.isDefault,
          ),
        ),
      );
    notifyListeners();
  }

  void recordSearch(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    _recentSearches
      ..removeWhere((item) => item.toLowerCase() == normalized.toLowerCase())
      ..insert(0, normalized);
    if (_recentSearches.length > 8) _recentSearches.removeLast();
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  void setSort(FoodSort value) {
    _sort = value;
    notifyListeners();
  }

  void selectAddress(String id) {
    if (!addresses.any((address) => address.id == id)) return;
    _selectedAddressId = id;
    notifyListeners();
  }

  void saveAddress(DeliveryAddress address) {
    if (addresses.any((item) => item.id == address.id)) {
      final index = addresses.indexWhere((item) => item.id == address.id);
      addresses[index] = address;
    } else {
      addresses.add(address);
    }
    if (address.isDefault || addresses.length == 1) {
      for (var index = 0; index < addresses.length; index++) {
        addresses[index] = addresses[index].copyWith(
          isDefault: addresses[index].id == address.id,
        );
      }
      _selectedAddressId = address.id;
    }
    notifyListeners();
  }

  void setDefaultAddress(String id) {
    if (!addresses.any((address) => address.id == id)) return;
    for (var index = 0; index < addresses.length; index++) {
      addresses[index] = addresses[index].copyWith(
        isDefault: addresses[index].id == id,
      );
    }
    _selectedAddressId = id;
    notifyListeners();
  }

  void deleteAddress(String id) {
    addresses.removeWhere((address) => address.id == id);
    if (_selectedAddressId == id) {
      if (addresses.isEmpty) {
        _selectedAddressId = '';
        notifyListeners();
      } else {
        setDefaultAddress(addresses.first.id);
      }
    } else {
      notifyListeners();
    }
  }

  void setDarkMode(bool value) {
    darkMode = value;
    notifyListeners();
  }

  void setOrderNotifications(bool value) {
    orderNotifications = value;
    notifyListeners();
  }

  void setPromotionalNotifications(bool value) {
    promotionalNotifications = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  CraveOrder? placeOrder({
    String paymentMethod = 'Cash on Delivery',
    DeliveryAddress? deliveryAddress,
    String? instructions,
  }) {
    final items = cartItems;
    if (items.isEmpty) return null;
    if (addresses.isEmpty) {
      throw StateError('Add a delivery address before placing an order.');
    }
    if (!sellerStore.restaurant.isApproved || !sellerStore.restaurant.isOpen) {
      throw StateError('The restaurant is not accepting orders.');
    }
    if (items.any((item) => !item.food.isAvailable)) {
      throw StateError('The cart contains an unavailable food item.');
    }
    final order = CraveOrder(
      id: 'CR${Random().nextInt(0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}',
      items: List.unmodifiable(items),
      total: cartTotal,
      estimatedMinutes: 30,
      createdAt: DateTime.now(),
      status: 'Active',
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress ?? selectedAddress,
      deliveryInstructions: instructions ?? deliveryInstructions,
    );
    lastOrder = order;
    _orders.insert(0, order);
    _cart.clear();
    notifyListeners();
    return order;
  }

  Future<CraveOrder> placeCashOnDeliveryOrder({String? instructions}) async {
    final repository = codOrderRepository;
    if (repository == null) {
      throw StateError('Cash-on-delivery orders are not configured.');
    }
    final items = cartItems;
    if (items.isEmpty) throw StateError('Your cart is empty.');
    if (items.any((item) => !item.food.isAvailable)) {
      throw StateError('The cart contains an unavailable food item.');
    }
    final restaurantIds = items.map((item) => item.food.restaurantId).toSet();
    if (restaurantIds.length != 1 || restaurantIds.single.isEmpty) {
      throw StateError(
        'Order items must belong to one restaurant with an active menu.',
      );
    }
    final address = selectedAddress;
    if (address.id.isEmpty) {
      throw StateError('Add a delivery address before placing an order.');
    }

    final order = await repository.createOrder(
      restaurantId: restaurantIds.single,
      items: items,
      address: address,
      instructions: instructions ?? deliveryInstructions,
    );
    lastOrder = order;
    _orders.insert(0, order);
    _cart.clear();
    notifyListeners();
    return order;
  }
}
