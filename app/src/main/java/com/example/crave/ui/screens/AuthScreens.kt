package com.example.crave.ui.screens

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.crave.data.local.MockFoodData
import com.example.crave.ui.components.CraveTextField
import com.example.crave.ui.components.CraveWordmark
import com.example.crave.ui.components.FoodImage
import com.example.crave.ui.components.OutlineButton
import com.example.crave.ui.components.PrimaryButton
import com.example.crave.ui.components.ScreenTitle
import com.example.crave.ui.theme.Coral
import com.example.crave.ui.theme.Cream
import com.example.crave.ui.theme.DarkTeal
import com.example.crave.ui.theme.Ink
import com.example.crave.ui.theme.Muted
import com.example.crave.viewmodel.AuthViewModel

@Composable
fun SplashScreen() {
    val transition = rememberInfiniteTransition(label = "splash")
    val scale by transition.animateFloat(
        initialValue = 0.88f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(850), RepeatMode.Reverse),
        label = "logo-pulse"
    )
    Column(
        modifier = Modifier.fillMaxSize().background(DarkTeal).padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            modifier = Modifier.size((94 * scale).dp).clip(RoundedCornerShape(32.dp)).background(Coral),
            contentAlignment = Alignment.Center
        ) {
            Text("C", color = Color.White, style = MaterialTheme.typography.displayMedium, fontWeight = FontWeight.ExtraBold)
        }
        Spacer(Modifier.height(18.dp))
        Text("crave", color = Color.White, style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.ExtraBold)
        Spacer(Modifier.height(8.dp))
        Text("Your favourite meals are just a tap away.", color = Color.White.copy(alpha = 0.82f), textAlign = TextAlign.Center)
        Spacer(Modifier.height(34.dp))
        CircularProgressIndicator(modifier = Modifier.size(26.dp), color = Color.White, strokeWidth = 2.dp)
    }
}

@Composable
fun WelcomeScreen(onLogin: () -> Unit, onSignUp: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().background(Cream).verticalScroll(rememberScrollState()).padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(16.dp))
        CraveWordmark()
        Spacer(Modifier.height(28.dp))
        FoodImage(
            food = MockFoodData.foods[2],
            modifier = Modifier.fillMaxWidth().height(315.dp)
        )
        Spacer(Modifier.height(28.dp))
        Text(
            "Good Food,\nGreat Mood!",
            style = MaterialTheme.typography.headlineLarge,
            color = Ink,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(10.dp))
        Text(
            "Discover delicious meals delivered right to your doorstep.",
            color = Muted,
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.bodyLarge
        )
        Spacer(Modifier.height(28.dp))
        PrimaryButton("Login", onLogin, Modifier.fillMaxWidth())
        Spacer(Modifier.height(12.dp))
        OutlineButton("Create an account", onSignUp, Modifier.fillMaxWidth())
        Spacer(Modifier.height(10.dp))
    }
}

@Composable
fun LoginScreen(
    viewModel: AuthViewModel,
    onBack: () -> Unit,
    onSignUp: () -> Unit,
    onSuccess: () -> Unit,
    showMessage: (String) -> Unit
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var passwordVisible by rememberSaveable { mutableStateOf(false) }
    var showForgotDialog by rememberSaveable { mutableStateOf(false) }
    Column(
        modifier = Modifier.fillMaxSize().background(Cream).verticalScroll(rememberScrollState())
            .imePadding().padding(horizontal = 24.dp, vertical = 16.dp)
    ) {
        IconButton(onClick = onBack, modifier = Modifier.align(Alignment.Start)) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
        }
        Spacer(Modifier.height(4.dp))
        CraveWordmark()
        Spacer(Modifier.height(30.dp))
        ScreenTitle("Welcome Back!", "Login to continue your food journey.")
        Spacer(Modifier.height(24.dp))
        CraveTextField(
            value = state.email,
            onValueChange = { viewModel.update("email", it) },
            label = "Email address",
            leading = { Icon(Icons.Default.Email, contentDescription = null) },
            isError = state.errors.containsKey("email"),
            supportingText = state.errors["email"],
            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Email)
        )
        Spacer(Modifier.height(10.dp))
        CraveTextField(
            value = state.password,
            onValueChange = { viewModel.update("password", it) },
            label = "Password",
            leading = { Icon(Icons.Default.Lock, contentDescription = null) },
            trailing = {
                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                    Icon(
                        if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                        contentDescription = if (passwordVisible) "Hide password" else "Show password"
                    )
                }
            },
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            isError = state.errors.containsKey("password"),
            supportingText = state.errors["password"]
        )
        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 2.dp, bottom = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(checked = state.rememberMe, onCheckedChange = viewModel::setRememberMe)
            Text("Remember me", color = Muted, modifier = Modifier.weight(1f))
            Text(
                "Forgot password?",
                color = Coral,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable { showForgotDialog = true }.padding(8.dp)
            )
        }
        PrimaryButton(
            "Login",
            onClick = {
                if (viewModel.validateLogin()) {
                    showMessage("Demo sign-in successful.")
                    onSuccess()
                }
            },
            Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(12.dp))
        OutlineButton(
            "Continue with Google",
            onClick = { showMessage("Google sign-in will be available when authentication is connected.") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(22.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Text("New to Crave? ", color = Muted)
            Text("Sign up", color = Coral, fontWeight = FontWeight.Bold, modifier = Modifier.clickable(onClick = onSignUp))
        }
        Spacer(Modifier.height(20.dp))
    }
    if (showForgotDialog) {
        AlertDialog(
            onDismissRequest = { showForgotDialog = false },
            title = { Text("Forgot password?") },
            text = { Text("Password recovery will be available when authentication is connected. You can try the demo login with any valid email and a non-empty password.") },
            confirmButton = {
                TextButton(onClick = { showForgotDialog = false }) { Text("Got it") }
            }
        )
    }
}

@Composable
fun SignUpScreen(
    viewModel: AuthViewModel,
    onBack: () -> Unit,
    onLogin: () -> Unit,
    onSuccess: () -> Unit
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var passwordVisible by rememberSaveable { mutableStateOf(false) }
    var confirmVisible by rememberSaveable { mutableStateOf(false) }
    Column(
        modifier = Modifier.fillMaxSize().background(Cream).verticalScroll(rememberScrollState())
            .imePadding().padding(horizontal = 24.dp, vertical = 16.dp)
    ) {
        IconButton(onClick = onBack, modifier = Modifier.align(Alignment.Start)) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
        }
        CraveWordmark()
        Spacer(Modifier.height(22.dp))
        ScreenTitle("Create Account", "Join Crave and find your new favourite.")
        Spacer(Modifier.height(18.dp))
        CraveTextField(
            state.name,
            { viewModel.update("name", it) },
            "Full name",
            leading = { Icon(Icons.Default.Person, contentDescription = null) },
            isError = state.errors.containsKey("name"),
            supportingText = state.errors["name"]
        )
        Spacer(Modifier.height(8.dp))
        CraveTextField(
            state.email,
            { viewModel.update("email", it) },
            "Email address",
            leading = { Icon(Icons.Default.Email, contentDescription = null) },
            isError = state.errors.containsKey("email"),
            supportingText = state.errors["email"],
            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Email)
        )
        Spacer(Modifier.height(8.dp))
        CraveTextField(
            state.phone,
            { viewModel.update("phone", it) },
            "Phone number",
            leading = { Icon(Icons.Default.Phone, contentDescription = null) },
            isError = state.errors.containsKey("phone"),
            supportingText = state.errors["phone"],
            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Phone)
        )
        Spacer(Modifier.height(8.dp))
        CraveTextField(
            state.password,
            { viewModel.update("password", it) },
            "Password",
            leading = { Icon(Icons.Default.Lock, contentDescription = null) },
            trailing = {
                IconButton(onClick = { passwordVisible = !passwordVisible }) {
                    Icon(if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility, contentDescription = "Toggle password visibility")
                }
            },
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            isError = state.errors.containsKey("password"),
            supportingText = state.errors["password"]
        )
        Spacer(Modifier.height(8.dp))
        CraveTextField(
            state.confirmPassword,
            { viewModel.update("confirmPassword", it) },
            "Confirm password",
            leading = { Icon(Icons.Default.Lock, contentDescription = null) },
            trailing = {
                IconButton(onClick = { confirmVisible = !confirmVisible }) {
                    Icon(if (confirmVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility, contentDescription = "Toggle password visibility")
                }
            },
            visualTransformation = if (confirmVisible) VisualTransformation.None else PasswordVisualTransformation(),
            isError = state.errors.containsKey("confirmPassword"),
            supportingText = state.errors["confirmPassword"]
        )
        Row(verticalAlignment = Alignment.CenterVertically) {
            Checkbox(checked = state.acceptedTerms, onCheckedChange = viewModel::setAcceptedTerms)
            Text("I agree to the Terms & Conditions", color = Muted, style = MaterialTheme.typography.bodySmall)
        }
        state.errors["terms"]?.let {
            Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall, modifier = Modifier.padding(start = 12.dp))
        }
        Spacer(Modifier.height(8.dp))
        PrimaryButton(
            "Create Account",
            onClick = { if (viewModel.validateSignup()) onSuccess() },
            Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(18.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            Text("Already have an account? ", color = Muted)
            Text("Login", color = Coral, fontWeight = FontWeight.Bold, modifier = Modifier.clickable(onClick = onLogin))
        }
        Spacer(Modifier.height(18.dp))
    }
}
