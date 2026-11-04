package com.example.crave.data.local

import com.example.crave.data.model.Food

object MockFoodData {
    val foods = listOf(
        Food(
            id = "club-sandwich",
            name = "Grilled Club Sandwich",
            category = "Sandwiches",
            price = 149,
            rating = 4.7,
            reviewCount = 128,
            description = "Crispy grilled bread layered with fresh vegetables, creamy sauce and melted cheese. A satisfying classic, made fresh to order.",
            imageUrl = "https://images.unsplash.com/photo-1553909489-cd47e0ef937f?w=900&auto=format&fit=crop&q=85"
        ),
        Food(
            id = "french-fries",
            name = "Classic French Fries",
            category = "Fries",
            price = 99,
            rating = 4.8,
            reviewCount = 204,
            description = "Golden, crispy potato fries with a fluffy centre and just the right seasoning. Perfect for sharing — or keeping all to yourself.",
            imageUrl = "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=900&auto=format&fit=crop&q=85"
        ),
        Food(
            id = "cheese-burger",
            name = "Cheese Burger",
            category = "Burgers",
            price = 179,
            rating = 4.6,
            reviewCount = 186,
            description = "A juicy, seasoned patty with melted cheese, crisp lettuce and fresh vegetables in a toasted sesame bun.",
            imageUrl = "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900&auto=format&fit=crop&q=85"
        ),
        Food(
            id = "margherita-pizza",
            name = "Margherita Pizza",
            category = "Pizza",
            price = 199,
            rating = 4.9,
            reviewCount = 242,
            description = "A timeless favourite with a crisp crust, rich tomato sauce, bubbling mozzarella and fragrant basil.",
            imageUrl = "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=900&auto=format&fit=crop&q=85"
        ),
        Food(
            id = "cold-coffee",
            name = "Cold Coffee",
            category = "Drinks",
            price = 89,
            rating = 4.5,
            reviewCount = 97,
            description = "Smooth, refreshing chilled coffee blended with milk and a touch of sweetness. Your cool afternoon pick-me-up.",
            imageUrl = "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=900&auto=format&fit=crop&q=85"
        ),
        Food(
            id = "choco-brownie",
            name = "Chocolate Brownie",
            category = "Desserts",
            price = 119,
            rating = 4.8,
            reviewCount = 113,
            description = "A rich, fudgy chocolate brownie baked with a soft centre and a delicate crackly top.",
            imageUrl = "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=900&auto=format&fit=crop&q=85"
        ),
        Food(
            id = "veggie-burger",
            name = "Crispy Veggie Burger",
            category = "Burgers",
            price = 159,
            rating = 4.6,
            reviewCount = 89,
            description = "A crunchy vegetable patty topped with fresh lettuce, tangy sauce and tomato in a soft toasted bun.",
            imageUrl = "https://images.unsplash.com/photo-1520072959219-c595dc870360?w=900&auto=format&fit=crop&q=85"
        ),
        Food(
            id = "paneer-sandwich",
            name = "Paneer Tikka Sandwich",
            category = "Sandwiches",
            price = 169,
            rating = 4.7,
            reviewCount = 76,
            description = "Smoky paneer tikka, crunchy peppers and mint chutney tucked into golden toasted bread.",
            imageUrl = "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=900&auto=format&fit=crop&q=85"
        )
    )

    val categories = listOf("All", "Burgers", "Pizza", "Sandwiches", "Fries", "Drinks", "Desserts")
}
