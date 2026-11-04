package com.example.crave.navigation

object Screen {
    const val Splash = "splash"
    const val Welcome = "welcome"
    const val Login = "login"
    const val SignUp = "signup"
    const val Home = "home"
    const val Search = "search"
    const val Cart = "cart"
    const val Favourites = "favourites"
    const val Profile = "profile"
    const val FoodDetails = "food/{foodId}"
    const val Checkout = "checkout"
    const val OrderSuccess = "order-success"

    fun foodDetails(foodId: String): String = "food/$foodId"
}
