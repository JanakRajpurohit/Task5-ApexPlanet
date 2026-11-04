package com.example.crave.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.PersonOutline
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
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
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.crave.ui.components.ScreenTitle
import com.example.crave.ui.theme.Coral
import com.example.crave.ui.theme.Cream
import com.example.crave.ui.theme.DarkTeal
import com.example.crave.ui.theme.Ink
import com.example.crave.ui.theme.Muted
import com.example.crave.viewmodel.CraveViewModel

@Composable
fun ProfileScreen(
    viewModel: CraveViewModel,
    onLogout: () -> Unit,
    onFavourites: () -> Unit,
    showMessage: (String) -> Unit
) {
    val user by viewModel.profile.collectAsStateWithLifecycle()
    val latestOrder by viewModel.order.collectAsStateWithLifecycle()
    var dialog by rememberSaveable { mutableStateOf<String?>(null) }
    var editName by rememberSaveable(user.name) { mutableStateOf(user.name) }
    var editPhone by rememberSaveable(user.phone) { mutableStateOf(user.phone) }
    var notifications by rememberSaveable { mutableStateOf(true) }
    var offers by rememberSaveable { mutableStateOf(true) }

    Column(modifier = Modifier.fillMaxSize().background(Cream).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp)) {
        Spacer(Modifier.height(22.dp))
        ScreenTitle("My Profile", "Your Crave account at a glance.")
        Spacer(Modifier.height(18.dp))
        Card(shape = RoundedCornerShape(22.dp), colors = CardDefaults.cardColors(containerColor = Color.White)) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(18.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = Modifier.size(64.dp).clip(CircleShape).background(Color(0xFFFFE4D9)),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(user.name.firstOrNull()?.uppercase() ?: "F", color = Coral, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                }
                Column(Modifier.weight(1f).padding(start = 14.dp)) {
                    Text(user.name, style = MaterialTheme.typography.titleLarge, color = Ink)
                    Text(user.email, color = Muted, style = MaterialTheme.typography.bodySmall)
                    Text(user.phone, color = Muted, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
        Spacer(Modifier.height(18.dp))
        ProfileOption("Edit Profile", "Update your name and phone number", Icons.Default.PersonOutline) { dialog = "edit" }
        ProfileOption("My Orders", "Check your recent orders", Icons.AutoMirrored.Filled.ReceiptLong) { dialog = "orders" }
        ProfileOption("Saved Addresses", "Manage your delivery locations", Icons.Default.LocationOn) { dialog = "addresses" }
        ProfileOption("Favourite Foods", "Your saved dishes", Icons.Default.FavoriteBorder, onClick = onFavourites)
        ProfileOption("Settings", "Notifications and preferences", Icons.Default.Settings) { dialog = "settings" }
        ProfileOption("Help & Support", "We're here to help", Icons.AutoMirrored.Filled.HelpOutline) { dialog = "help" }
        ProfileOption("Logout", "Sign out of this account", Icons.AutoMirrored.Filled.Logout, tint = Coral, onClick = { dialog = "logout" })
        Spacer(Modifier.height(18.dp))
    }

    when (dialog) {
        "edit" -> AlertDialog(
            onDismissRequest = { dialog = null },
            title = { Text("Edit profile") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(value = editName, onValueChange = { editName = it }, label = { Text("Full name") }, singleLine = true)
                    OutlinedTextField(value = editPhone, onValueChange = { editPhone = it }, label = { Text("Phone number") }, singleLine = true)
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    if (editName.isNotBlank() && editPhone.isNotBlank()) {
                        viewModel.updateProfile(editName.trim(), editPhone.trim())
                        dialog = null
                        showMessage("Profile updated")
                    } else {
                        showMessage("Name and phone number cannot be empty")
                    }
                }) { Text("Save", color = Coral) }
            },
            dismissButton = { TextButton(onClick = { dialog = null }) { Text("Cancel") } }
        )
        "orders" -> ProfileInfoDialog(
            title = "My Orders",
            message = latestOrder?.let {
                "Order ${it.id} · ₹${it.total}\n\nYour order is being prepared. Estimated delivery: ${it.estimatedMinutes} minutes."
            } ?: "You haven't placed an order from this account yet. Your next delicious meal will appear here.",
            onDismiss = { dialog = null }
        )
        "addresses" -> ProfileInfoDialog(
            title = "Saved Addresses",
            message = "Home · Jodhpur, Rajasthan 342001\n\nYou can choose this address during checkout.",
            onDismiss = { dialog = null }
        )
        "help" -> ProfileInfoDialog(
            title = "Help & Support",
            message = "Need a hand? Email us at hello@crave.example and our team will be happy to help.",
            onDismiss = { dialog = null }
        )
        "settings" -> AlertDialog(
            onDismissRequest = { dialog = null },
            title = { Text("Settings") },
            text = {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Order notifications", modifier = Modifier.weight(1f))
                        Switch(checked = notifications, onCheckedChange = { notifications = it })
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Offers & updates", modifier = Modifier.weight(1f))
                        Switch(checked = offers, onCheckedChange = { offers = it })
                    }
                }
            },
            confirmButton = { TextButton(onClick = { dialog = null }) { Text("Done", color = Coral) } }
        )
        "logout" -> AlertDialog(
            onDismissRequest = { dialog = null },
            title = { Text("Log out?") },
            text = { Text("You can sign in again any time.") },
            confirmButton = {
                TextButton(onClick = {
                    dialog = null
                    onLogout()
                }) { Text("Log out", color = Coral) }
            },
            dismissButton = { TextButton(onClick = { dialog = null }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun ProfileOption(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    tint: Color = DarkTeal,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(bottom = 9.dp).clickable(onClick = onClick),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 15.dp, vertical = 13.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(23.dp))
            Column(Modifier.weight(1f).padding(start = 13.dp)) {
                Text(title, color = Ink, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                Text(subtitle, color = Muted, style = MaterialTheme.typography.bodySmall)
            }
            Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Muted)
        }
    }
}

@Composable
private fun ProfileInfoDialog(title: String, message: String, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message, color = Muted) },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Done", color = Coral) } }
    )
}
