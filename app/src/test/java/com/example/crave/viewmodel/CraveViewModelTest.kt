package com.example.crave.viewmodel

import com.example.crave.data.repository.MockCartRepository
import com.example.crave.data.repository.MockFoodRepository
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CraveViewModelTest {
    @Test
    fun searchAndCategoryFilteringReturnMatchingFoods() {
        val viewModel = CraveViewModel(MockFoodRepository(), MockCartRepository())

        viewModel.setQuery("pizza")
        assertEquals(listOf("margherita-pizza"), viewModel.filteredFoods().map { it.id })

        viewModel.setQuery("")
        viewModel.setCategory("Burgers")
        assertTrue(viewModel.filteredFoods().all { it.category == "Burgers" })
        assertEquals(2, viewModel.filteredFoods().size)
    }

    @Test
    fun placingOrderCalculatesTotalAndEmptiesCart() {
        val cart = MockCartRepository()
        val viewModel = CraveViewModel(MockFoodRepository(), cart)
        val sandwich = viewModel.foodById("club-sandwich")!!
        viewModel.addToCart(sandwich, amount = 2)
        val items = cart.items.value

        assertEquals(298, viewModel.cartSubtotal(items))
        assertEquals(328, viewModel.cartTotal(items))
        val order = viewModel.placeOrder(items)

        assertNotNull(order)
        assertEquals(328, order?.total)
        assertTrue(cart.items.value.isEmpty())
        assertNull(viewModel.placeOrder(emptyList()))
    }

    @Test
    fun authValidationReportsInvalidInputAndAcceptsValidSignup() {
        val auth = AuthViewModel()
        assertFalse(auth.validateLogin())
        assertTrue(auth.state.value.errors.containsKey("email"))
        assertTrue(auth.state.value.errors.containsKey("password"))

        auth.update("name", "Taylor Guest")
        auth.update("email", "taylor@example.com")
        auth.update("phone", "+91 98765 43210")
        auth.update("password", "crave123")
        auth.update("confirmPassword", "crave123")
        auth.setAcceptedTerms(true)
        assertTrue(auth.validateSignup())

        auth.update("confirmPassword", "different")
        assertFalse(auth.validateSignup())
        assertTrue(auth.state.value.errors.containsKey("confirmPassword"))
        auth.update("password", "different")
        assertFalse(auth.state.value.errors.containsKey("confirmPassword"))
        assertTrue(auth.validateSignup())
    }
}
