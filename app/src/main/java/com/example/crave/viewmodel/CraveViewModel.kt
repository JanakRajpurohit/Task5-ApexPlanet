package com.example.crave.viewmodel

import androidx.lifecycle.ViewModel
import com.example.crave.data.model.CartItem
import com.example.crave.data.model.Food
import com.example.crave.data.model.Order
import com.example.crave.data.model.User
import com.example.crave.data.repository.FoodRepository
import com.example.crave.data.repository.CartRepository
import java.util.UUID
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class CraveViewModel(
    foodRepository: FoodRepository,
    private val cartRepository: CartRepository
) : ViewModel() {
    val foods: List<Food> = foodRepository.getFoods()
    val categories: List<String> = foodRepository.getCategories()
    val cartItems: StateFlow<List<CartItem>> = cartRepository.items

    private val mutableQuery = MutableStateFlow("")
    val query: StateFlow<String> = mutableQuery.asStateFlow()

    private val mutableCategory = MutableStateFlow("All")
    val selectedCategory: StateFlow<String> = mutableCategory.asStateFlow()

    private val mutableFavourites = MutableStateFlow<Set<String>>(emptySet())
    val favourites: StateFlow<Set<String>> = mutableFavourites.asStateFlow()

    private val mutableOrder = MutableStateFlow<Order?>(null)
    val order: StateFlow<Order?> = mutableOrder.asStateFlow()

    private val mutableProfile = MutableStateFlow(
        User(
        name = "Food Lover",
        email = "foodlover@example.com",
        phone = "+91 98765 43210"
        )
    )
    val profile: StateFlow<User> = mutableProfile.asStateFlow()

    val deliveryFee: Int = 30

    fun setQuery(value: String) {
        mutableQuery.value = value
    }

    fun setCategory(value: String) {
        mutableCategory.value = value
    }

    fun filteredFoods(): List<Food> {
        val normalizedQuery = mutableQuery.value.trim()
        return foods.filter { food ->
            val matchesCategory = mutableCategory.value == "All" || food.category == mutableCategory.value
            val matchesQuery = normalizedQuery.isBlank() ||
                food.name.contains(normalizedQuery, ignoreCase = true) ||
                food.category.contains(normalizedQuery, ignoreCase = true)
            matchesCategory && matchesQuery
        }
    }

    fun foodById(id: String): Food? = foods.firstOrNull { it.id == id }

    fun addToCart(food: Food, amount: Int = 1) = cartRepository.add(food, amount)

    fun changeQuantity(foodId: String, delta: Int) = cartRepository.changeQuantity(foodId, delta)

    fun removeFromCart(foodId: String) = cartRepository.remove(foodId)

    fun cartSubtotal(items: List<CartItem>): Int = items.sumOf { it.lineTotal }

    fun cartTotal(items: List<CartItem>): Int =
        if (items.isEmpty()) 0 else cartSubtotal(items) + deliveryFee

    fun toggleFavourite(foodId: String) {
        mutableFavourites.value = mutableFavourites.value.let { current ->
            if (foodId in current) current - foodId else current + foodId
        }
    }

    fun updateProfile(name: String, phone: String) {
        mutableProfile.value = mutableProfile.value.copy(name = name, phone = phone)
    }

    fun placeOrder(items: List<CartItem>): Order? {
        if (items.isEmpty()) return null
        val newOrder = Order(
            id = "CR${UUID.randomUUID().toString().take(8).uppercase()}",
            items = items.toList(),
            total = cartTotal(items),
            estimatedMinutes = 30
        )
        mutableOrder.value = newOrder
        cartRepository.clear()
        return newOrder
    }
}

data class AuthState(
    val name: String = "",
    val email: String = "",
    val phone: String = "",
    val password: String = "",
    val confirmPassword: String = "",
    val rememberMe: Boolean = false,
    val acceptedTerms: Boolean = false,
    val errors: Map<String, String> = emptyMap()
)

class AuthViewModel : ViewModel() {
    private val mutableState = MutableStateFlow(AuthState())
    val state: StateFlow<AuthState> = mutableState.asStateFlow()

    fun update(field: String, value: String) {
        val current = mutableState.value
        val errorsToClear = if (field == "password" || field == "confirmPassword") {
            setOf("password", "confirmPassword")
        } else {
            setOf(field)
        }
        mutableState.value = current.copy(
            name = if (field == "name") value else current.name,
            email = if (field == "email") value else current.email,
            phone = if (field == "phone") value else current.phone,
            password = if (field == "password") value else current.password,
            confirmPassword = if (field == "confirmPassword") value else current.confirmPassword,
            errors = current.errors - errorsToClear
        )
    }

    fun setRememberMe(value: Boolean) {
        mutableState.value = mutableState.value.copy(rememberMe = value)
    }

    fun setAcceptedTerms(value: Boolean) {
        val current = mutableState.value
        mutableState.value = current.copy(
            acceptedTerms = value,
            errors = current.errors - "terms"
        )
    }

    fun validateLogin(): Boolean {
        val current = mutableState.value
        val errors = buildMap {
            if (!current.email.isValidEmail()) put("email", "Enter a valid email address.")
            if (current.password.isBlank()) put("password", "Password cannot be empty.")
        }
        mutableState.value = current.copy(errors = errors)
        return errors.isEmpty()
    }

    fun validateSignup(): Boolean {
        val current = mutableState.value
        val errors = buildMap {
            if (current.name.isBlank()) put("name", "Enter your full name.")
            if (!current.email.isValidEmail()) put("email", "Enter a valid email address.")
            if (!current.phone.matches(Regex("^[+]?[0-9][0-9\\s-]{7,14}$"))) {
                put("phone", "Enter a valid phone number.")
            }
            if (current.password.length < 6) put("password", "Use at least 6 characters.")
            if (current.confirmPassword != current.password) put("confirmPassword", "Passwords do not match.")
            if (!current.acceptedTerms) put("terms", "Please accept the terms to continue.")
        }
        mutableState.value = current.copy(errors = errors)
        return errors.isEmpty()
    }

    private fun String.isValidEmail(): Boolean =
        Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$").matches(this.trim())
}
