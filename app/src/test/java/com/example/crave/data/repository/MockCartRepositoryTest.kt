package com.example.crave.data.repository

import com.example.crave.data.local.MockFoodData
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MockCartRepositoryTest {
    @Test
    fun addAndChangeQuantity_updatesCartAndNeverLeavesZeroQuantity() {
        val cart = MockCartRepository()
        val food = MockFoodData.foods.first()

        cart.add(food)
        cart.add(food, amount = 2)
        assertEquals(3, cart.items.value.single().quantity)

        cart.changeQuantity(food.id, -2)
        assertEquals(1, cart.items.value.single().quantity)

        cart.changeQuantity(food.id, -1)
        assertTrue(cart.items.value.isEmpty())
    }

    @Test(expected = IllegalArgumentException::class)
    fun addRejectsNonPositiveQuantity() {
        MockCartRepository().add(MockFoodData.foods.first(), amount = 0)
    }
}
