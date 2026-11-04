import 'package:crave/state/seller_store.dart';

import 'mock_seller_data.dart';

SellerStore createSellerStore() => SellerStore(
  account: MockSellerData.account,
  restaurant: MockSellerData.restaurant,
  foods: MockSellerData.foods,
  orders: MockSellerData.orders,
  offers: MockSellerData.offers,
  notifications: MockSellerData.notifications,
  reviews: MockSellerData.reviews,
  categories: [
    'Burgers',
    'Pizza',
    'Sandwiches',
    'Fries',
    'Beverages',
    'Desserts',
    'Other',
  ],
);
