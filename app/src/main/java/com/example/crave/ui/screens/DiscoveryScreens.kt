package com.example.crave.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.NotificationsNone
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.crave.data.model.Food
import com.example.crave.ui.components.CategoryChip
import com.example.crave.ui.components.CraveTextField
import com.example.crave.ui.components.EmptyMessage
import com.example.crave.ui.components.FoodCard
import com.example.crave.ui.components.FoodImage
import com.example.crave.ui.components.PrimaryButton
import com.example.crave.ui.components.ScreenTitle
import com.example.crave.ui.components.SectionTitle
import com.example.crave.ui.theme.Coral
import com.example.crave.ui.theme.Cream
import com.example.crave.ui.theme.DarkTeal
import com.example.crave.ui.theme.Ink
import com.example.crave.ui.theme.Muted
import com.example.crave.viewmodel.CraveViewModel

@Composable
fun HomeScreen(
    viewModel: CraveViewModel,
    onFoodClick: (String) -> Unit,
    onSearchClick: () -> Unit,
    onCartClick: () -> Unit,
    showMessage: (String) -> Unit
) {
    val selectedCategory by viewModel.selectedCategory.collectAsStateWithLifecycle()
    val favourites by viewModel.favourites.collectAsStateWithLifecycle()
    val cartItems by viewModel.cartItems.collectAsStateWithLifecycle()
    val popularFoods = viewModel.foods.take(5)
    var showNotifications by rememberSaveable { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxSize().background(Cream).verticalScroll(rememberScrollState())) {
        Column(Modifier.padding(horizontal = 20.dp)) {
            Spacer(Modifier.height(18.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Good Evening!", style = MaterialTheme.typography.titleMedium, color = Muted)
                    Text("Food Lover", style = MaterialTheme.typography.headlineMedium, color = Ink)
                }
                IconButton(onClick = onCartClick) {
                    Box {
                        Icon(Icons.Default.ShoppingBag, contentDescription = "Open cart", tint = DarkTeal)
                        if (cartItems.isNotEmpty()) {
                            Box(
                                Modifier.align(Alignment.TopEnd).size(9.dp).background(Coral, CircleShape)
                            )
                        }
                    }
                }
                IconButton(onClick = { showNotifications = true }) {
                    Icon(Icons.Default.NotificationsNone, contentDescription = "Notifications", tint = DarkTeal)
                }
            }
            Spacer(Modifier.height(12.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.LocationOn, contentDescription = null, tint = Coral, modifier = Modifier.size(19.dp))
                Text("Delivering to ", color = Muted, style = MaterialTheme.typography.bodyMedium)
                Text("Jodhpur", color = Ink, fontWeight = FontWeight.SemiBold)
                Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, tint = Muted, modifier = Modifier.padding(start = 4.dp).size(15.dp))
            }
            Spacer(Modifier.height(18.dp))
            CraveTextField(
                value = "",
                onValueChange = { },
                label = "Search for burgers, pizza, fries...",
                leading = { Icon(Icons.Default.Search, contentDescription = null) },
                trailing = {
                    IconButton(onClick = onSearchClick) {
                        Icon(Icons.Default.FilterList, contentDescription = "Open search and filters", tint = Coral)
                    }
                },
                modifier = Modifier.clickable(onClick = onSearchClick)
            )
            Spacer(Modifier.height(18.dp))
            PromoBanner(onClick = { onFoodClick(popularFoods.firstOrNull()?.id.orEmpty()) })
            Spacer(Modifier.height(24.dp))
            SectionTitle("Categories", action = "See all", onAction = onSearchClick)
            Spacer(Modifier.height(12.dp))
        }
        Row(
            modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = 20.dp),
            horizontalArrangement = Arrangement.spacedBy(9.dp)
        ) {
            viewModel.categories.forEach { category ->
                CategoryChip(category, selectedCategory == category) {
                    viewModel.setCategory(category)
                    viewModel.setQuery("")
                    onSearchClick()
                }
            }
        }
        Column(Modifier.padding(horizontal = 20.dp)) {
            Spacer(Modifier.height(24.dp))
            SectionTitle(
                if (selectedCategory == "All") "Popular Food" else selectedCategory,
                action = "See all",
                onAction = onSearchClick
            )
            Spacer(Modifier.height(14.dp))
            val visibleFoods = if (selectedCategory == "All") popularFoods else viewModel.foods.filter { it.category == selectedCategory }
            visibleFoods.forEach { food ->
                FoodCard(
                    food = food,
                    isFavourite = food.id in favourites,
                    onClick = { onFoodClick(food.id) },
                    onFavouriteClick = {
                        viewModel.toggleFavourite(food.id)
                        showMessage(if (food.id in favourites) "Removed from favourites" else "Added to favourites")
                    },
                    onAddClick = {
                        viewModel.addToCart(food)
                        showMessage("${food.name} added to cart")
                    },
                    modifier = Modifier.padding(bottom = 14.dp)
                )
            }
            Spacer(Modifier.height(12.dp))
        }
    }
    if (showNotifications) {
        AlertDialog(
            onDismissRequest = { showNotifications = false },
            title = { Text("You're all caught up!") },
            text = { Text("Order updates and special offers will show up here.") },
            confirmButton = { TextButton(onClick = { showNotifications = false }) { Text("Done") } }
        )
    }
}

@Composable
private fun PromoBanner(onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().height(178.dp).clip(RoundedCornerShape(24.dp)).background(Coral)
            .clickable(onClick = onClick).padding(start = 18.dp, end = 12.dp, top = 16.dp, bottom = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1.15f)) {
            Text("Hungry? We've\ngot you!", color = Color.White, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(5.dp))
            Text("Get up to 30% OFF on your first order.", color = Color.White.copy(alpha = 0.9f), style = MaterialTheme.typography.bodySmall)
            Spacer(Modifier.height(10.dp))
            Text("Order Now  →", color = Color.White, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.labelLarge)
        }
        FoodImage(
            food = com.example.crave.data.local.MockFoodData.foods[2],
            modifier = Modifier.weight(0.85f).height(140.dp)
        )
    }
}

@Composable
fun SearchScreen(
    viewModel: CraveViewModel,
    onFoodClick: (String) -> Unit,
    showMessage: (String) -> Unit
) {
    val query by viewModel.query.collectAsStateWithLifecycle()
    val selectedCategory by viewModel.selectedCategory.collectAsStateWithLifecycle()
    val favourites by viewModel.favourites.collectAsStateWithLifecycle()
    val filteredFoods = viewModel.filteredFoods()
    var showFilters by rememberSaveable { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxSize().background(Cream).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp)) {
        Spacer(Modifier.height(22.dp))
        ScreenTitle("Find your craving", "Fresh picks, just a search away.")
        Spacer(Modifier.height(18.dp))
        CraveTextField(
            value = query,
            onValueChange = viewModel::setQuery,
            label = "Search for burgers, pizza, fries...",
            leading = { Icon(Icons.Default.Search, contentDescription = null) },
            trailing = {
                IconButton(onClick = { showFilters = true }) {
                    Icon(Icons.Default.FilterList, contentDescription = "Filter by category", tint = Coral)
                }
            }
        )
        Spacer(Modifier.height(18.dp))
        Text("Popular searches", color = Muted, style = MaterialTheme.typography.labelLarge)
        Spacer(Modifier.height(10.dp))
        Row(
            modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            listOf("Burgers", "Pizza", "Sandwiches", "Cold coffee").forEach { suggestion ->
                CategoryChip(suggestion, selected = query.equals(suggestion, ignoreCase = true)) {
                    viewModel.setQuery(suggestion)
                    viewModel.setCategory("All")
                }
            }
        }
        Spacer(Modifier.height(22.dp))
        SectionTitle(if (query.isBlank()) "Popular Food" else "Search results")
        Spacer(Modifier.height(12.dp))
        if (filteredFoods.isEmpty()) {
            EmptyMessage(
                emoji = "🔎",
                title = "No dishes found",
                description = "Try another food or browse a different category.",
                buttonText = "Clear search",
                onButtonClick = {
                    viewModel.setQuery("")
                    viewModel.setCategory("All")
                }
            )
        } else {
            filteredFoods.forEach { food ->
                FoodCard(
                    food = food,
                    isFavourite = food.id in favourites,
                    onClick = { onFoodClick(food.id) },
                    onFavouriteClick = {
                        viewModel.toggleFavourite(food.id)
                        showMessage(if (food.id in favourites) "Removed from favourites" else "Added to favourites")
                    },
                    onAddClick = {
                        viewModel.addToCart(food)
                        showMessage("${food.name} added to cart")
                    },
                    modifier = Modifier.padding(bottom = 14.dp)
                )
            }
        }
        Spacer(Modifier.height(12.dp))
    }

    if (showFilters) {
        AlertDialog(
            onDismissRequest = { showFilters = false },
            title = { Text("Choose a category") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    viewModel.categories.forEach { category ->
                        TextButton(
                            onClick = {
                                viewModel.setCategory(category)
                                viewModel.setQuery("")
                                showFilters = false
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(category, modifier = Modifier.fillMaxWidth(), color = if (selectedCategory == category) Coral else Ink)
                        }
                    }
                }
            },
            confirmButton = { TextButton(onClick = { showFilters = false }) { Text("Close") } }
        )
    }
}

@Composable
fun FoodDetailsScreen(
    foodId: String,
    viewModel: CraveViewModel,
    onBack: () -> Unit,
    onCart: () -> Unit,
    showMessage: (String) -> Unit
) {
    val food = viewModel.foodById(foodId)
    val favourites by viewModel.favourites.collectAsStateWithLifecycle()
    var quantity by rememberSaveable(foodId) { mutableIntStateOf(1) }
    if (food == null) {
        EmptyMessage("🍽️", "Dish unavailable", "This item is no longer on the menu.", "Back to menu", onBack)
        return
    }
    Column(modifier = Modifier.fillMaxSize().background(Cream)) {
        Box {
            FoodImage(food = food, modifier = Modifier.fillMaxWidth().height(350.dp), contentScale = androidx.compose.ui.layout.ContentScale.Crop)
            IconButton(
                onClick = onBack,
                modifier = Modifier.align(Alignment.TopStart).padding(18.dp).background(Color.White, CircleShape)
            ) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Go back")
            }
            IconButton(
                onClick = { viewModel.toggleFavourite(food.id) },
                modifier = Modifier.align(Alignment.TopEnd).padding(18.dp).background(Color.White, CircleShape)
            ) {
                Icon(
                    if (food.id in favourites) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                    contentDescription = "Toggle favourite",
                    tint = if (food.id in favourites) Coral else Ink
                )
            }
        }
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(22.dp)) {
            Text(food.category.uppercase(), color = Coral, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(6.dp))
            Text(food.name, color = Ink, style = MaterialTheme.typography.headlineMedium)
            Spacer(Modifier.height(8.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Star, contentDescription = null, tint = Color(0xFFFFB300), modifier = Modifier.size(19.dp))
                Text("${food.rating}  ·  ${food.reviewCount} reviews", color = Muted, style = MaterialTheme.typography.bodyMedium)
            }
            Spacer(Modifier.height(20.dp))
            Text(food.description, color = Muted, style = MaterialTheme.typography.bodyLarge)
            Spacer(Modifier.height(22.dp))
            Row(
                modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Color.White).padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("Quantity", style = MaterialTheme.typography.titleMedium)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = { if (quantity > 1) quantity-- }, enabled = quantity > 1) {
                        Icon(Icons.Default.Remove, contentDescription = "Decrease quantity")
                    }
                    Text("$quantity", style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(horizontal = 8.dp))
                    IconButton(onClick = { quantity++ }) {
                        Icon(Icons.Default.Add, contentDescription = "Increase quantity", tint = Coral)
                    }
                }
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth().background(Color.White).padding(horizontal = 20.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(0.8f)) {
                Text("TOTAL", color = Muted, style = MaterialTheme.typography.labelSmall)
                Text("₹${food.price * quantity}", color = DarkTeal, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            }
            PrimaryButton(
                "Add to Cart",
                onClick = {
                    viewModel.addToCart(food, quantity)
                    showMessage("${food.name} added to cart")
                },
                modifier = Modifier.weight(1.2f)
            )
            Spacer(Modifier.width(6.dp))
            IconButton(onClick = onCart) {
                Icon(Icons.Default.ShoppingBag, contentDescription = "Go to cart", tint = DarkTeal)
            }
        }
    }
}

@Composable
fun FavouritesScreen(
    viewModel: CraveViewModel,
    onFoodClick: (String) -> Unit,
    onExplore: () -> Unit,
    showMessage: (String) -> Unit
) {
    val favourites by viewModel.favourites.collectAsStateWithLifecycle()
    val foods = viewModel.foods.filter { it.id in favourites }
    Column(modifier = Modifier.fillMaxSize().background(Cream).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp)) {
        Spacer(Modifier.height(22.dp))
        ScreenTitle("Your favourites", "The dishes you love, all in one place.")
        Spacer(Modifier.height(18.dp))
        if (foods.isEmpty()) {
            EmptyMessage("♡", "No favourites yet", "Tap the heart on a dish to save it for later.", "Explore food", onExplore)
        } else {
            foods.forEach { food ->
                FoodCard(
                    food,
                    isFavourite = true,
                    onClick = { onFoodClick(food.id) },
                    onFavouriteClick = {
                        viewModel.toggleFavourite(food.id)
                        showMessage("Removed from favourites")
                    },
                    onAddClick = {
                        viewModel.addToCart(food)
                        showMessage("${food.name} added to cart")
                    },
                    modifier = Modifier.padding(bottom = 14.dp)
                )
            }
        }
    }
}
