package com.example.crave.data.model

data class Food(
    val id: String,
    val name: String,
    val category: String,
    val price: Int,
    val rating: Double,
    val reviewCount: Int,
    val description: String,
    val imageUrl: String
)

data class CartItem(
    val food: Food,
    val quantity: Int
) {
    val lineTotal: Int
        get() = food.price * quantity
}

data class User(
    val name: String,
    val email: String,
    val phone: String
)

data class Order(
    val id: String,
    val items: List<CartItem>,
    val total: Int,
    val estimatedMinutes: Int
)
