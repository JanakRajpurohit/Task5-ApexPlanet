package com.example.crave.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.crave.data.model.CartItem
import com.example.crave.data.model.Order
import com.example.crave.ui.components.EmptyMessage
import com.example.crave.ui.components.FoodImage
import com.example.crave.ui.components.PrimaryButton
import com.example.crave.ui.components.ScreenTitle
import com.example.crave.ui.theme.Coral
import com.example.crave.ui.theme.Cream
import com.example.crave.ui.theme.DarkTeal
import com.example.crave.ui.theme.Ink
import com.example.crave.ui.theme.Muted
import com.example.crave.viewmodel.CraveViewModel

@Composable
fun CartScreen(
    viewModel: CraveViewModel,
    onContinueShopping: () -> Unit,
    onCheckout: () -> Unit
) {
    val items by viewModel.cartItems.collectAsStateWithLifecycle()
    Column(modifier = Modifier.fillMaxSize().background(Cream).padding(horizontal = 20.dp)) {
        Spacer(Modifier.height(20.dp))
        ScreenTitle("My Cart", "The good stuff is almost yours.")
        if (items.isEmpty()) {
            Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                EmptyMessage(
                    emoji = "🛍️",
                    title = "Your cart is hungry",
                    description = "Add something delicious and it will show up here.",
                    buttonText = "Explore food",
                    onButtonClick = onContinueShopping
                )
            }
        } else {
            Column(
                modifier = Modifier.weight(1f).fillMaxWidth().verticalScroll(rememberScrollState()).padding(top = 18.dp)
            ) {
                items.forEach { item ->
                    CartItemRow(
                        item = item,
                        onIncrease = { viewModel.changeQuantity(item.food.id, 1) },
                        onDecrease = { viewModel.changeQuantity(item.food.id, -1) },
                        onRemove = { viewModel.removeFromCart(item.food.id) }
                    )
                    Spacer(Modifier.height(12.dp))
                }
                Spacer(Modifier.height(6.dp))
                PriceSummary(
                    subtotal = viewModel.cartSubtotal(items),
                    deliveryFee = viewModel.deliveryFee,
                    total = viewModel.cartTotal(items)
                )
                Spacer(Modifier.height(18.dp))
            }
            PrimaryButton("Proceed to Checkout", onCheckout, Modifier.fillMaxWidth())
            Spacer(Modifier.height(14.dp))
        }
    }
}

@Composable
private fun CartItemRow(
    item: CartItem,
    onIncrease: () -> Unit,
    onDecrease: () -> Unit,
    onRemove: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            FoodImage(item.food, Modifier.size(88.dp))
            Column(Modifier.weight(1f).padding(horizontal = 12.dp)) {
                Text(item.food.name, style = MaterialTheme.typography.titleMedium, maxLines = 1)
                Text("₹${item.food.price} each", color = Muted, style = MaterialTheme.typography.bodySmall)
                Spacer(Modifier.height(6.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    QuantityButton("-", onDecrease, enabled = item.quantity > 1)
                    Text("${item.quantity}", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(horizontal = 10.dp))
                    QuantityButton("+", onIncrease)
                }
            }
            Column(horizontalAlignment = Alignment.End) {
                IconButton(onClick = onRemove, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Default.DeleteOutline, contentDescription = "Remove ${item.food.name}", tint = Muted)
                }
                Spacer(Modifier.height(8.dp))
                Text("₹${item.lineTotal}", color = DarkTeal, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun QuantityButton(label: String, onClick: () -> Unit, enabled: Boolean = true) {
    IconButton(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier.size(30.dp).background(if (enabled) Cream else Color(0xFFF4F1EE), CircleShape)
    ) {
        if (label == "+") {
            Icon(Icons.Default.Add, contentDescription = "Increase quantity", tint = Coral, modifier = Modifier.size(17.dp))
        } else {
            Icon(Icons.Default.Remove, contentDescription = "Decrease quantity", tint = if (enabled) Ink else Muted, modifier = Modifier.size(17.dp))
        }
    }
}

@Composable
private fun PriceSummary(subtotal: Int, deliveryFee: Int, total: Int) {
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(Color.White).padding(18.dp)
    ) {
        Text("Price Details", style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(12.dp))
        PriceLine("Subtotal", subtotal)
        Spacer(Modifier.height(8.dp))
        PriceLine("Delivery fee", deliveryFee)
        HorizontalDivider(Modifier.padding(vertical = 13.dp), color = Cream)
        PriceLine("Total amount", total, emphasize = true)
    }
}

@Composable
private fun PriceLine(label: String, amount: Int, emphasize: Boolean = false) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = if (emphasize) Ink else Muted, fontWeight = if (emphasize) FontWeight.Bold else FontWeight.Normal)
        Text("₹$amount", color = if (emphasize) DarkTeal else Ink, fontWeight = FontWeight.Bold)
    }
}

@Composable
fun CheckoutScreen(viewModel: CraveViewModel, onBack: () -> Unit, onOrderPlaced: () -> Unit) {
    val items by viewModel.cartItems.collectAsStateWithLifecycle()
    var payment by rememberSaveable { mutableStateOf("Cash on Delivery") }
    var address by rememberSaveable { mutableStateOf("Jodhpur, Rajasthan 342001") }
    var showAddressDialog by rememberSaveable { mutableStateOf(false) }
    Column(modifier = Modifier.fillMaxSize().background(Cream)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(start = 12.dp, end = 20.dp, top = 10.dp, bottom = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back") }
            ScreenTitle("Checkout")
        }
        if (items.isEmpty()) {
            Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                EmptyMessage("🛍️", "Nothing to checkout", "Add food to your cart before placing an order.", "Continue shopping", onBack)
            }
        } else {
            Column(
                modifier = Modifier.weight(1f).fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp)
            ) {
                CheckoutSectionTitle("Delivery address")
                Card(shape = RoundedCornerShape(18.dp), colors = CardDefaults.cardColors(containerColor = Color.White)) {
                    Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.LocationOn, contentDescription = null, tint = Coral)
                        Column(Modifier.weight(1f).padding(start = 12.dp)) {
                            Text("Home", fontWeight = FontWeight.Bold)
                            Text(address, color = Muted, style = MaterialTheme.typography.bodySmall)
                        }
                        TextButton(onClick = { showAddressDialog = true }) { Text("Change", color = Coral) }
                    }
                }
                Spacer(Modifier.height(20.dp))
                CheckoutSectionTitle("Order summary")
                items.forEach { item ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("${item.food.name} × ${item.quantity}", color = Muted)
                        Text("₹${item.lineTotal}", color = Ink, fontWeight = FontWeight.SemiBold)
                    }
                }
                HorizontalDivider(Modifier.padding(vertical = 12.dp), color = Color(0xFFE6DFD8))
                PriceLine("Subtotal", viewModel.cartSubtotal(items))
                Spacer(Modifier.height(8.dp))
                PriceLine("Delivery fee", viewModel.deliveryFee)
                Spacer(Modifier.height(8.dp))
                PriceLine("Total amount", viewModel.cartTotal(items), emphasize = true)
                Spacer(Modifier.height(20.dp))
                CheckoutSectionTitle("Payment method")
                listOf("Cash on Delivery", "Pay on delivery (UPI)").forEach { option ->
                    Card(
                        modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            RadioButton(selected = payment == option, onClick = { payment = option })
                            Text(option, modifier = Modifier.weight(1f), color = Ink)
                        }
                    }
                }
                Spacer(Modifier.height(10.dp))
            }
            PrimaryButton(
                "Place Order · ₹${viewModel.cartTotal(items)}",
                onClick = onOrderPlaced,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp)
            )
            Spacer(Modifier.height(14.dp))
        }
    }
    if (showAddressDialog) {
        AlertDialog(
            onDismissRequest = { showAddressDialog = false },
            title = { Text("Delivery address") },
            text = {
                OutlinedTextField(
                    value = address,
                    onValueChange = { address = it },
                    label = { Text("Address") },
                    singleLine = false,
                    isError = address.isBlank(),
                    supportingText = {
                        if (address.isBlank()) Text("Address cannot be empty.")
                    }
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        address = address.trim()
                        showAddressDialog = false
                    },
                    enabled = address.isNotBlank()
                ) { Text("Save", color = Coral) }
            },
            dismissButton = {
                TextButton(onClick = { showAddressDialog = false }) { Text("Cancel") }
            }
        )
    }
}

@Composable
private fun CheckoutSectionTitle(title: String) {
    Text(title, style = MaterialTheme.typography.titleLarge, modifier = Modifier.padding(bottom = 10.dp))
}

@Composable
fun OrderSuccessScreen(order: Order?, onHome: () -> Unit, onTrack: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().background(Cream).verticalScroll(rememberScrollState())
            .padding(horizontal = 26.dp, vertical = 30.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            modifier = Modifier.size(130.dp).background(Color(0xFFE2F2E9), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Default.Check, contentDescription = null, tint = DarkTeal, modifier = Modifier.size(72.dp))
        }
        Spacer(Modifier.height(25.dp))
        Text(
            "Order Placed\nSuccessfully!",
            style = MaterialTheme.typography.headlineLarge,
            color = Ink,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(10.dp))
        Text("Your delicious food is on its way.", color = Muted, textAlign = TextAlign.Center)
        Spacer(Modifier.height(24.dp))
        Card(shape = RoundedCornerShape(20.dp), colors = CardDefaults.cardColors(containerColor = Color.White)) {
            Column(Modifier.fillMaxWidth().padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("ORDER ID", color = Muted, style = MaterialTheme.typography.labelMedium)
                Text(order?.id ?: "CRAVE-READY", color = DarkTeal, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(14.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Timer, contentDescription = null, tint = Coral, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("${order?.estimatedMinutes ?: 30} min estimated delivery", color = Ink)
                }
                if (order != null) {
                    Spacer(Modifier.height(8.dp))
                    Text("Paid on delivery · ₹${order.total}", color = Muted, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
        Spacer(Modifier.height(28.dp))
        PrimaryButton("Track Order", onTrack, Modifier.fillMaxWidth())
        Spacer(Modifier.height(10.dp))
        TextButton(onClick = onHome, modifier = Modifier.fillMaxWidth()) {
            Text("Back to Home", color = Coral, fontWeight = FontWeight.Bold)
        }
    }
}
