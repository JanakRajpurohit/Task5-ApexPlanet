import 'package:crave/models/food.dart';
import 'package:crave/state/crave_store.dart';
import 'package:crave/state/seller_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/mock_food_data.dart';
import 'fixtures/test_stores.dart';

void main() {
  late CraveStore store;
  late SellerStore sellerStore;

  setUp(() {
    sellerStore = createSellerStore()..foods.clear();
    addTearDown(sellerStore.dispose);
    store = CraveStore(MockFoodData.foods, sellerStore: sellerStore);
    store.saveAddress(
      const DeliveryAddress(
        id: 'home',
        name: 'Test User',
        phone: '1234567890',
        house: 'Home',
        street: 'Main Road',
        city: 'Test City',
        state: 'Test State',
        pincode: '000000',
        type: 'Home',
        isDefault: true,
      ),
    );
    store.saveAddress(
      const DeliveryAddress(
        id: 'work',
        name: 'Test User',
        phone: '1234567890',
        house: 'Office',
        street: 'Work Road',
        city: 'Test City',
        state: 'Test State',
        pincode: '000000',
        type: 'Work',
      ),
    );
    addTearDown(store.dispose);
  });

  test('search and category filters match provided catalog data', () {
    store.setQuery('pizza');
    expect(store.filteredFoods.map((food) => food.id), ['margherita-pizza']);

    store.setQuery('');
    store.setCategory('Burgers');
    expect(store.filteredFoods, hasLength(2));
    expect(
      store.filteredFoods.every((food) => food.category == 'Burgers'),
      isTrue,
    );
  });

  test('customer store starts without seeded catalog or account data', () {
    final emptyStore = CraveStore(const []);
    addTearDown(emptyStore.dispose);

    expect(emptyStore.foods, isEmpty);
    expect(emptyStore.addresses, isEmpty);
    expect(emptyStore.orders, isEmpty);
    expect(emptyStore.profileName, isEmpty);
    expect(emptyStore.profileEmail, isEmpty);
  });

  test('cart quantity and totals stay correct through checkout', () {
    final sandwich = store.foodById('club-sandwich')!;
    store.addToCart(sandwich, quantity: 2);

    expect(store.cartSubtotal, 298);
    expect(store.cartTotal, 298);
    expect(store.cartItemCount, 2);

    store.changeQuantity(sandwich.id, -1);
    expect(store.cartItems.single.quantity, 1);
    store.changeQuantity(sandwich.id, -1);
    expect(store.cartItems, isEmpty);

    expect(store.placeOrder(), isNull);
    store.addToCart(sandwich, quantity: 2);
    final order = store.placeOrder();
    expect(order, isNotNull);
    expect(order!.total, 298);
    expect(store.cartItems, isEmpty);
    expect(store.lastOrder?.id, order.id);
  });

  test('placed orders retain selected delivery and payment details', () {
    final food = store.foods.first;
    store.addToCart(food);
    store.selectAddress('work');

    final order = store.placeOrder(
      paymentMethod: 'UPI (demo selection)',
      instructions: 'Call on arrival',
    )!;

    expect(order.paymentMethod, 'UPI (demo selection)');
    expect(order.deliveryAddress?.id, 'work');
    expect(order.deliveryInstructions, 'Call on arrival');
  });

  test('favourites can be added and removed', () {
    final food = store.foods.first;
    store.toggleFavourite(food.id);
    expect(store.favouriteFoods, [food]);
    store.toggleFavourite(food.id);
    expect(store.favouriteFoods, isEmpty);
  });

  test('cart rejects non-positive quantities', () {
    expect(
      () => store.addToCart(store.foods.first, quantity: 0),
      throwsArgumentError,
    );
  });

  test('search history, ingredient matching, and sort are consistent', () {
    store.recordSearch('  basil  ');
    store.recordSearch('BASIL');
    expect(store.recentSearches, ['BASIL']);

    store.setQuery('basil');
    expect(store.filteredFoods, isNotEmpty);
    store.setQuery('');
    store.setSort(FoodSort.priceLowToHigh);
    final prices = store.filteredFoods.map((food) => food.price).toList();
    expect(prices, [...prices]..sort());
  });

  test('Firestore food documents map into catalog items', () {
    final food = Food.fromFirestore('dish-1', {
      'name': 'Vegetable bowl',
      'category': 'Bowls',
      'price': 240,
      'rating': 4.5,
      'reviews': 12,
      'description': 'Fresh vegetables and rice.',
      'imageUrl': 'https://example.test/dish.jpg',
      'cuisine': 'Indian',
      'ingredients': ['Rice', 'Vegetables'],
      'preparationMinutes': 18,
      'isVegetarian': true,
      'isAvailable': true,
    });

    expect(food.id, 'dish-1');
    expect(food.name, 'Vegetable bowl');
    expect(food.ingredients, ['Rice', 'Vegetables']);
    expect(food.price, 240);
  });

  test('Firestore food mapping rejects invalid required fields', () {
    expect(
      () => Food.fromFirestore('invalid-dish', {'name': 'No price'}),
      throwsFormatException,
    );
  });

  test('customized cart lines keep options and totals separate', () {
    final food = store.foods.first;
    store.addToCart(food, customizations: ['Extra cheese'], extraEach: 20);
    store.addToCart(food, customizations: ['Extra cheese'], extraEach: 20);
    store.addToCart(food, customizations: ['No onions']);

    expect(store.cartItems, hasLength(2));
    expect(store.cartItems.first.quantity, 2);
    expect(store.cartItems.first.customizations, ['Extra cheese']);
    expect(store.cartSubtotal, (food.price + 20) * 2 + food.price);
    store.removeFromCart(store.cartItems.first.lineId);
    expect(store.cartItems, hasLength(1));
  });

  test(
    'address selection, default updates, and deletion preserve a valid address',
    () {
      store.selectAddress('work');
      expect(store.selectedAddress.id, 'work');

      final address = store.addresses.first;
      store.setDefaultAddress(address.id);
      expect(store.selectedAddress.id, address.id);
      expect(store.addresses.where((item) => item.isDefault), hasLength(1));

      store.deleteAddress(address.id);
      expect(store.addresses, hasLength(1));
      expect(store.selectedAddress.id, 'work');
    },
  );
}
