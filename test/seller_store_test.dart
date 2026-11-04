import 'package:crave/models/seller_models.dart';
import 'package:crave/state/crave_store.dart';
import 'package:crave/state/seller_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/test_stores.dart';

void main() {
  late SellerStore store;

  setUp(() {
    store = createSellerStore();
    addTearDown(store.dispose);
  });

  test('production seller store starts without seeded data', () {
    final emptyStore = SellerStore();
    addTearDown(emptyStore.dispose);

    expect(emptyStore.account.sellerId, isEmpty);
    expect(emptyStore.restaurant.restaurantId, isEmpty);
    expect(emptyStore.restaurant.isApproved, isFalse);
    expect(emptyStore.foods, isEmpty);
    expect(emptyStore.orders, isEmpty);
  });

  test(
    'orders only allow valid lifecycle transitions and retain history',
    () async {
      final order = store.orderById('CRV-8031')!;

      expect(
        await store.updateOrderStatus(order.orderId, 'Delivered'),
        isFalse,
      );
      expect(await store.updateOrderStatus(order.orderId, 'Accepted'), isTrue);
      expect(await store.updateOrderStatus(order.orderId, 'Preparing'), isTrue);
      expect(
        await store.updateOrderStatus(order.orderId, 'Ready for Pickup'),
        isTrue,
      );
      expect(await store.updateOrderStatus(order.orderId, 'Picked Up'), isTrue);
      expect(await store.updateOrderStatus(order.orderId, 'Delivered'), isTrue);
      expect(order.orderStatus, 'Delivered');
      expect(order.statusHistory.map((update) => update.status), [
        'New',
        'Accepted',
        'Preparing',
        'Ready for Pickup',
        'Picked Up',
        'Delivered',
      ]);
    },
  );

  test('seller menu queries and mutations remain restaurant-scoped', () {
    final otherRestaurantFood = SellerFood(
      foodId: 'other-food',
      restaurantId: 'another-restaurant',
      name: 'Private item',
      description: '',
      imageUrl: '',
      price: 99,
      category: 'Other',
      preparationTime: 10,
    );
    store.foods.add(otherRestaurantFood);

    expect(
      store.restaurantFoods.every(
        (food) => food.restaurantId == store.restaurant.restaurantId,
      ),
      isTrue,
    );
    store.deleteFood(otherRestaurantFood.foodId);
    expect(store.foods, contains(otherRestaurantFood));

    store.saveFood(
      name: 'Demo bowl',
      description: 'Rice bowl',
      imageUrl: '',
      price: 199,
      category: 'Other',
      preparationTime: 15,
    );
    expect(
      store.restaurantFoods.any((food) => food.name == 'Demo bowl'),
      isTrue,
    );
  });

  test('stock updates synchronize availability and low stock state', () {
    final food = store.restaurantFoods.first;
    store.updateStock(food.foodId, 0);
    expect(food.stock, 0);
    expect(food.available, isFalse);

    store.updateStock(food.foodId, 4);
    expect(food.stock, 4);
    expect(food.available, isTrue);

    store.setFoodAvailability(food.foodId, false);
    expect(food.available, isFalse);
  });

  test('seller menu data is not used as the customer catalog', () {
    store.saveFood(
      name: 'Seller menu item',
      description: 'Saved for seller tests only',
      imageUrl: '',
      price: 220,
      category: 'Other',
      preparationTime: 18,
    );
    final customerStore = CraveStore(const [], sellerStore: store);
    addTearDown(customerStore.dispose);

    expect(customerStore.catalogFoods, isEmpty);
  });
}
