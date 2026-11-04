package com.example.crave.data.repository

import com.example.crave.data.local.MockFoodData
import com.example.crave.data.model.CartItem
import com.example.crave.data.model.Food
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

interface FoodRepository {
    fun getFoods(): List<Food>
    fun getCategories(): List<String>
}

class MockFoodRepository : FoodRepository {
    override fun getFoods(): List<Food> = MockFoodData.foods
    override fun getCategories(): List<String> = MockFoodData.categories
}

interface CartRepository {
    val items: StateFlow<List<CartItem>>
    fun add(food: Food, amount: Int = 1)
    fun changeQuantity(foodId: String, delta: Int)
    fun remove(foodId: String)
    fun clear()
}

class MockCartRepository : CartRepository {
    private val mutableItems = MutableStateFlow<List<CartItem>>(emptyList())
    override val items: StateFlow<List<CartItem>> = mutableItems.asStateFlow()

    override fun add(food: Food, amount: Int) {
        require(amount > 0) { "Amount must be greater than zero." }
        val current = mutableItems.value.toMutableList()
        val index = current.indexOfFirst { it.food.id == food.id }
        if (index >= 0) {
            current[index] = current[index].copy(quantity = current[index].quantity + amount)
        } else {
            current += CartItem(food, amount)
        }
        mutableItems.value = current
    }

    override fun changeQuantity(foodId: String, delta: Int) {
        val current = mutableItems.value.toMutableList()
        val index = current.indexOfFirst { it.food.id == foodId }
        if (index < 0) return
        val nextQuantity = current[index].quantity + delta
        if (nextQuantity <= 0) {
            current.removeAt(index)
        } else {
            current[index] = current[index].copy(quantity = nextQuantity)
        }
        mutableItems.value = current
    }

    override fun remove(foodId: String) {
        mutableItems.value = mutableItems.value.filterNot { it.food.id == foodId }
    }

    override fun clear() {
        mutableItems.value = emptyList()
    }
}
